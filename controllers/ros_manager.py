import threading
import math
import random
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
        self._is_connected = False
        self._use_simulation = True
        self._sim_angle = 0.0
        self._scan_angle_min = -math.pi # Default -180
        self._scan_angle_increment = (2 * math.pi) / 360 # Default 1 deg
        
        self.node = None
        self.thread = None
        self.active = False
        
        # Activity Tracking
        import time
        self._last_map_time = 0
        self._last_scan_time = 0
        self._last_tf_time = 0
        
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
        import time
        return (time.time() - self._last_map_time) < 5.0 if self.active else False

    @Property(bool, notify=statusChanged)
    def isScanActive(self):
        import time
        return (time.time() - self._last_scan_time) < 2.0 if self.active else False

    @Property(bool, notify=statusChanged)
    def isTfActive(self):
        import time
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

    @Slot(str, str, str, str)
    def start_ros(self, scan_topic="/scan", map_topic="/map", tf_topic="/tf", robot_frame="base_link"):
        if not HAS_ROS2:
            print("ROS2 not available, staying in simulation mode.")
            return

        if self.active:
            self.stop_ros()

        print(f"Starting ROS2 connection. Scan: {scan_topic}, Map: {map_topic}, Robot Frame: {robot_frame}")
        self.logMessage.emit(f"Connecting to ROS topics... Scan: {scan_topic}", "info")
        self.active = True
        self.thread = threading.Thread(target=self._ros_thread, args=(scan_topic, map_topic, tf_topic, robot_frame), daemon=True)
        self.thread.start()

    @Slot()
    def stop_ros(self):
        self.active = False
        if self.thread and self.thread.is_alive():
            # Wait briefly for thread to exit
            self.thread.join(timeout=0.2)

    def _ros_thread(self, scan_topic, map_topic, tf_topic, robot_frame):
        node = None
        try:
            if not rclpy.ok():
                rclpy.init()
            node = Node('grid_map_editor_node', parameter_overrides=[
                rclpy.parameter.Parameter('use_sim_time', rclpy.Parameter.Type.BOOL, True)
            ])
            
            # TF Listener
            tf_buffer = tf2_ros.Buffer()
            tf_listener = tf2_ros.TransformListener(tf_buffer, node)
            
            # Subscriptions
            node.create_subscription(LaserScan, scan_topic, self._scan_callback, 10)
            node.create_subscription(OccupancyGrid, map_topic, self._map_callback, 10)
            
            self._is_connected = True
            self.statusChanged.emit()
            
            last_tf_update = 0
            while self.active and rclpy.ok():
                rclpy.spin_once(node, timeout_sec=0.05)
                
                # Periodically look up TF if robot_frame is provided
                import time
                now = time.time()
                if now - last_tf_update > 0.1: # 10Hz
                    try:
                        # Try to get transform from map to robot_frame
                        t = tf_buffer.lookup_transform('map', robot_frame, rclpy.time.Time())
                        self._x = t.transform.translation.x
                        self._y = t.transform.translation.y
                        self._theta = self._quat_to_yaw(t.transform.rotation)
                        self._last_tf_time = now
                        self.poseChanged.emit()
                    except (tf2_ros.LookupException, tf2_ros.ConnectivityException, tf2_ros.ExtrapolationException):
                        pass # Frame not available yet
                    last_tf_update = now
                    # Periodically emit statusChanged to update activity indicators in UI
                    self.statusChanged.emit()
        except Exception as e:
            print(f"ROS2 Thread Error: {e}")
        finally:
            self._is_connected = False
            self.statusChanged.emit()
            # Safely destroy node
            if node:
                try:
                    node.destroy_node()
                except:
                    pass
            # We don't shutdown rclpy globally here as other parts might use it,
            # but if it was the only node, we could. For now, let's just exit.



    def _scan_callback(self, msg):
        import time
        self._last_scan_time = time.time()
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
        import time
        self._last_map_time = time.time()
        self._use_simulation = False
        # We pass the message object to be processed by MapController
        self.mapReceived.emit(msg)



    def _quat_to_yaw(self, q):
        siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        return math.atan2(siny_cosp, cosy_cosp)
