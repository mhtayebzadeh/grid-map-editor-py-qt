import threading
import math
import random
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

try:
    import rclpy
    from rclpy.node import Node
    from geometry_msgs.msg import PoseWithCovarianceStamped, PoseStamped
    from nav_msgs.msg import Odometry
    from sensor_msgs.msg import LaserScan
    HAS_ROS2 = True
except ImportError:
    HAS_ROS2 = False

class ROSManager(QObject):
    poseChanged = Signal()
    scanChanged = Signal()
    statusChanged = Signal()

    def __init__(self):
        super().__init__()
        self._x = 0.0
        self._y = 0.0
        self._theta = 0.0
        self._scan_data = [0.0] * 360
        self._is_connected = False
        self._use_simulation = True
        self._sim_angle = 0.0
        
        self.node = None
        self.thread = None
        self.active = False
        
        # RELEASE/TEST MODE TOGGLE
        # Set to True to enable the jumpy fake data generator (0.5s interval)
        self.test_mode = False 
        
        # Sim Timer (Higher frequency for smooth movement)
        self.sim_timer = QTimer()
        self.sim_timer.timeout.connect(self._update_sim)
        self.sim_timer.start(50) # 20Hz

        # Specific Fake Data Generator (0.5s interval)
        self.fake_data_timer = QTimer()
        self.fake_data_timer.timeout.connect(self.generateFakeData)
        
        if self.test_mode:
            self.fake_data_timer.start(500) 

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

    def _update_sim(self):
        # Only run smooth sim if not in test mode and not connected to ROS
        if self._use_simulation and not self.test_mode:
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

    @Slot(str)
    def start_ros(self, pose_topic="/pose", scan_topic="/scan"):
        if not HAS_ROS2:
            print("ROS2 not available, staying in simulation mode.")
            return

        if self.active:
            self.stop_ros()

        print(f"Starting ROS2 connection on topic: {pose_topic}")
        self.active = True
        self.thread = threading.Thread(target=self._ros_thread, args=(pose_topic, scan_topic), daemon=True)
        self.thread.start()

    @Slot()
    def stop_ros(self):
        self.active = False
        if self.thread and self.thread.is_alive():
            # Wait briefly for thread to exit
            self.thread.join(timeout=0.2)

    def _ros_thread(self, pose_topic, scan_topic):
        node = None
        try:
            if not rclpy.ok():
                rclpy.init()
            node = Node('grid_map_editor_node')
            
            # Pose subscription
            node.create_subscription(PoseWithCovarianceStamped, pose_topic, self._pose_callback, 10)
            
            # Scan subscription
            node.create_subscription(LaserScan, scan_topic, self._scan_callback, 10)
            
            self._is_connected = True
            self.statusChanged.emit()
            while self.active and rclpy.ok():
                rclpy.spin_once(node, timeout_sec=0.1)
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

    def _pose_callback(self, msg):
        self._use_simulation = False
        self._x = msg.pose.pose.position.x
        self._y = msg.pose.pose.position.y
        self._theta = self._quat_to_yaw(msg.pose.pose.orientation)
        self.poseChanged.emit()

    def _scan_callback(self, msg):
        self._use_simulation = False
        # Normalize to 360 points if possible, or just use as is
        # ROS LaserScan often has many more points (e.g. 720 or 1080)
        # For simplicity in UI, we'll downsample to 360 or just expose the raw data
        # Let's just pass it through as a list
        self._scan_data = list(msg.ranges)
        self.scanChanged.emit()

    def _pose_stamped_callback(self, msg):
        self._use_simulation = False
        self._x = msg.pose.position.x
        self._y = msg.pose.position.y
        self._theta = self._quat_to_yaw(msg.pose.orientation)
        self.poseChanged.emit()

    def _quat_to_yaw(self, q):
        siny_cosp = 2 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
        return math.atan2(siny_cosp, cosy_cosp)
