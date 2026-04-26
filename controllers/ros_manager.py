import threading
import math
import random
import time
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

try:
    import rclpy
    from rclpy.node import Node
    from geometry_msgs.msg import PoseWithCovarianceStamped, PoseStamped
    from nav_msgs.msg import Odometry, OccupancyGrid
    from sensor_msgs.msg import LaserScan
    import tf2_ros
    HAS_ROS2 = True
except ImportError:
    HAS_ROS2 = False

# DEVELOPMENT FLAG: Set to True to generate fake jumpy data for scan and position
# When True, real ROS data is ignored and fake data is generated at 2Hz.
TEST_MODE = False

class ROSManager(QObject):
    poseChanged = Signal()
    scanChanged = Signal()
    mapReceived = Signal(object) # Emit the OccupancyGrid message or processed data
    statusChanged = Signal()
    logMessage = Signal(str, str) # message, type

    def __init__(self):
        super().__init__()
        self._x = 0.0
        self._y = 0.0
        self._theta = 0.0
        self._scan_data = [0.0] * 360
        self.init_pose_topic = "/initialpose"
        self._is_connected = False
        self.node = None
        self._init_uncertainty = 1.5
        self._use_simulation = True
        self._sim_angle = 0.0
        self._scan_angle_min = -math.pi # Default -180
        self._scan_angle_increment = (2 * math.pi) / 360 # Default 1 deg
        
        self.node = None
        self.thread = None
        self.active = False
        
        # Activity Tracking
        self._last_map_time = 0
        self._last_scan_time = 0
        self._last_tf_time = 0
        self._last_msg_stamp_ns = 0
        
        # Sim Timer (Higher frequency for smooth movement)
        self.sim_timer = QTimer()
        self.sim_timer.timeout.connect(self._update_sim)

        # Specific Fake Data Generator (0.5s interval)
        self.fake_data_timer = QTimer()
        self.fake_data_timer.timeout.connect(self.generateFakeData)
        
        if TEST_MODE:
            self.sim_timer.start(200) # 5Hz
            self.fake_data_timer.start(500) 
        else:
            self._use_simulation = False
    @Property(float, notify=poseChanged)
    def x(self): return self._x
    
    @Property(float, notify=poseChanged)
    def y(self): return self._y
    
    @Property(float, notify=poseChanged)
    def theta(self): return self._theta

    @Property(list, notify=scanChanged)
    def scanData(self): return self._scan_data

    @Property(bool, notify=statusChanged)
    def isConnected(self): return self._is_connected

    @Property(float, notify=scanChanged)
    def scanAngleMin(self): return self._scan_angle_min

    @Property(float, notify=scanChanged)
    def scanAngleIncrement(self): return self._scan_angle_increment

    @Property(bool, notify=statusChanged)
    def isMapActive(self):
        return (time.time() - self._last_map_time) < 5.0 if self.active else False

    @Property(bool, notify=statusChanged)
    def isScanActive(self):
        return (time.time() - self._last_scan_time) < 2.0 if self.active else False

    @Property(bool, notify=statusChanged)
    def isTfActive(self):
        return (time.time() - self._last_tf_time) < 2.0 if self.active else False

    def _update_sim(self):
        # Only run smooth sim if not in test mode and not connected to ROS
        if self._use_simulation and not TEST_MODE:
            # Smooth movement pattern (Infinity loop)
            self._sim_angle += 0.015
            scale = 15.0
            t = self._sim_angle
            denom = 1 + math.sin(t)**2
            self._x = (scale * math.cos(t)) / denom
            self._y = (scale * math.sin(t) * math.cos(t)) / denom
            
            dx = -scale * math.sin(t) * (1 + math.sin(t)**2 + 2*math.sin(t)**2) / (denom**2)
            dy = scale * (math.cos(t)**2 - math.sin(t)**2)
            self._theta = math.atan2(dy, dx)
            
            # Generate fake scan data (simulating walls around the robot)
            self._generate_sim_scan()
            
            self.poseChanged.emit()
            self.scanChanged.emit()

    def _generate_sim_scan(self):
        # Simulate some obstacles at different distances
        self._scan_data = []
        for i in range(360):
            angle = math.radians(i)
            # Distance varies with angle to create a "room" effect
            dist = 5.0 + 2.0 * math.sin(angle * 3) + 1.0 * math.cos(angle * 5)
            # Add a bit of noise
            dist += random.uniform(-0.1, 0.1)
            self._scan_data.append(dist)

    @Slot()
    def generateFakeData(self):
        """Generates random jumpy data every 0.5s as requested for testing."""
        # When this runs, we disable other simulation types
        self._use_simulation = False 
        self._x += random.uniform(-1.0, 1.0)
        self._y += random.uniform(-1.0, 1.0)
        self._theta += random.uniform(-0.5, 0.5)
        
        # Jumpy scan data
        self._scan_data = [random.uniform(1.0, 10.0) for _ in range(360)]
        
        self.poseChanged.emit()
        self.scanChanged.emit()

    @Property(float, notify=statusChanged)
    def initialUncertainty(self): return self._init_uncertainty
    @initialUncertainty.setter
    def initialUncertainty(self, val): 
        self._init_uncertainty = val
        self.statusChanged.emit()

    @Slot(str, str, str, str, str, bool)
    def start_ros(self, scan_topic="/scan", map_topic="/map", tf_topic="/tf", robot_frame="base_link", init_pose_topic="/initialpose", use_sim_time=False):
        if not HAS_ROS2:
            print("ROS2 not available, staying in simulation mode.")
            return

        if self.active:
            self.stop_ros()

        self.init_pose_topic = init_pose_topic
        print(f"Starting ROS2 connection. Scan: {scan_topic}, Map: {map_topic}, Robot Frame: {robot_frame}, Init Pose: {init_pose_topic}, SimTime: {use_sim_time}")
        self.logMessage.emit(f"Connecting to ROS topics... Scan: {scan_topic}", "info")
        self.active = True
        self.thread = threading.Thread(target=self._ros_thread, args=(scan_topic, map_topic, tf_topic, robot_frame, use_sim_time), daemon=True)
        self.thread.start()

    @Slot()
    def stop_ros(self):
        self.active = False
        if self.thread and self.thread.is_alive():
            # Wait longer for thread to exit to avoid duplicate nodes
            self.thread.join(timeout=1.0)
            self.thread = None
        self.node = None
        self._is_connected = False
        self.statusChanged.emit()

    def _ros_thread(self, scan_topic, map_topic, tf_topic, robot_frame, use_sim_time):
        node = None
        try:
            if not rclpy.ok():
                rclpy.init()
            
            # Use sim time if specified (important for bags/simulators)
            node = Node('grid_map_editor_node', parameter_overrides=[
                rclpy.parameter.Parameter('use_sim_time', rclpy.parameter.Type.BOOL, use_sim_time)
            ]) 
            
            # Suppress warnings (like TF_OLD_DATA) to keep terminal clean
            # especially useful during rosbag loops
            from rclpy.logging import LoggingSeverity
            node.get_logger().set_level(LoggingSeverity.ERROR)
            
            self.node = node
            
            # TF Listener setup
            def create_tf_listener():
                # Large cache time to handle jitter (60s)
                buf = tf2_ros.Buffer(cache_time=rclpy.duration.Duration(seconds=60))
                lst = tf2_ros.TransformListener(buf, node)
                return buf, lst
                
            tf_buffer, tf_listener = create_tf_listener()
            self._force_tf_reset = False
            
            # Subscriptions
            node.create_subscription(LaserScan, scan_topic, self._scan_callback, 10)
            node.create_subscription(OccupancyGrid, map_topic, self._map_callback, 10)
            
            # Publishers
            self.init_pose_pub = node.create_publisher(PoseWithCovarianceStamped, self.init_pose_topic, 10)
            
            self._is_connected = True
            self.statusChanged.emit()
            
            last_tf_update = 0
            tf_fail_count = 0
            
            while self.active and rclpy.ok():
                rclpy.spin_once(node, timeout_sec=0.1)
                now_mono = time.time()
                
                # Robustness: If TF has been stuck for too long (e.g. 5s) but ROS is active,
                # try to reset the listener to clear any "poisoned" buffer state.
                if self.active and (self._force_tf_reset or (now_mono - self._last_tf_time > 5.0 and now_mono - last_tf_update > 5.0)):
                    print("Resetting TF buffer...")
                    tf_buffer, tf_listener = create_tf_listener()
                    self._force_tf_reset = False
                    last_tf_update = now_mono 

                if now_mono - last_tf_update > 0.1: # 10Hz
                    try:
                        # Try to get transform from map to robot_frame
                        t = tf_buffer.lookup_transform('map', robot_frame, rclpy.time.Time(), 
                                                     timeout=rclpy.duration.Duration(seconds=0.05))
                        self._x = t.transform.translation.x
                        self._y = t.transform.translation.y
                        self._theta = self._quat_to_yaw(t.transform.rotation)
                        self._last_tf_time = now_mono
                        self.poseChanged.emit()
                        tf_fail_count = 0 # Success, reset count
                    except (tf2_ros.LookupException, tf2_ros.ConnectivityException, tf2_ros.ExtrapolationException) as e:
                        tf_fail_count += 1
                        
                        # TRICK: If TF is stuck for ~5 seconds (50 attempts at 10Hz),
                        # and we are in ROS mode, trigger a "soft restart" of the listener.
                        # If it's been 15 seconds, trigger a log warning.
                        if tf_fail_count == 50:
                            print("TF stuck for 5s, attempt buffer clear...")
                            tf_buffer, tf_listener = create_tf_listener()
                        
                        if tf_fail_count > 150: # 15 seconds
                            self.logMessage.emit("Robot position frozen! Please check ROS clock/TF. Resetting ROS connection...", "warning")
                            tf_fail_count = 0 
                            tf_buffer, tf_listener = create_tf_listener()
                    
                    last_tf_update = now_mono
                    self.statusChanged.emit()
        except Exception as e:
            print(f"ROS2 Thread Error: {e}")
            self.logMessage.emit(f"ROS Error: {str(e)}", "error")
        finally:
            self._is_connected = False
            if node:
                try:
                    node.destroy_node()
                except:
                    pass
            self.node = None
            self.statusChanged.emit()



    def _scan_callback(self, msg):
        self._last_scan_time = time.time()
        
        # Clock Jump Detection (for rosbag loops)
        current_stamp_ns = msg.header.stamp.sec * 1_000_000_000 + msg.header.stamp.nanosec
        if self._last_msg_stamp_ns > 0 and (current_stamp_ns < self._last_msg_stamp_ns - 1_000_000_000):
            print("Detected backwards clock jump! Resetting TF buffer.")
            self._force_tf_reset = True
        self._last_msg_stamp_ns = current_stamp_ns

        self._use_simulation = False
        # Normalize to 360 points if possible, or just use as is
        # ROS LaserScan often has many more points (e.g. 720 or 1080)
        # For simplicity in UI, we'll downsample to 360 or just expose the raw data
        # Let's just pass it through as a list
        self._scan_data = list(msg.ranges)
        self._scan_angle_min = msg.angle_min
        self._scan_angle_increment = msg.angle_increment
        self.scanChanged.emit()

    def _map_callback(self, msg):
        self._last_map_time = time.time()
        
        # Clock Jump Detection (for rosbag loops)
        current_stamp_ns = msg.header.stamp.sec * 1_000_000_000 + msg.header.stamp.nanosec
        if self._last_msg_stamp_ns > 0 and (current_stamp_ns < self._last_msg_stamp_ns - 1_000_000_000):
            print("Detected backwards clock jump! Resetting TF buffer.")
            self._force_tf_reset = True
        self._last_msg_stamp_ns = current_stamp_ns

        self._use_simulation = False
        # We pass the message object to be processed by MapController
        self.mapReceived.emit(msg)

    @Slot(float, float, float)
    def publish_initial_pose(self, x, y, theta=0.0):
        if not self.active or not HAS_ROS2 or self.node is None:
            return
            
        msg = PoseWithCovarianceStamped()
        msg.header.stamp = self.node.get_clock().now().to_msg()
        msg.header.frame_id = "map"
        msg.pose.pose.position.x = x
        msg.pose.pose.position.y = y
        msg.pose.pose.position.z = 0.0
        
        q = self._yaw_to_quat(theta)
        msg.pose.pose.orientation = q
        
        # Covariance based on uncertainty (m)
        # Indicies: 0=x, 7=y, 35=yaw
        var_xy = self._init_uncertainty * self._init_uncertainty
        msg.pose.covariance = [0.0] * 36
        msg.pose.covariance[0] = var_xy
        msg.pose.covariance[7] = var_xy
        # Heading uncertainty 360 deg -> variance approx (2*pi)^2
        # User suggested 1000 deg for high uncertainty
        msg.pose.covariance[35] = (1000.0 * math.pi / 180.0) ** 2
        
        self.init_pose_pub.publish(msg)
        self.logMessage.emit(f"Published initial pose: x={x:.2f}, y={y:.2f}", "success")

    def _yaw_to_quat(self, yaw):
        from geometry_msgs.msg import Quaternion
        q = Quaternion()
        q.x = 0.0
        q.y = 0.0
        q.z = math.sin(yaw / 2.0)
        q.w = math.cos(yaw / 2.0)
        return q



    def _quat_to_yaw(self, q):
        siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        return math.atan2(siny_cosp, cosy_cosp)
