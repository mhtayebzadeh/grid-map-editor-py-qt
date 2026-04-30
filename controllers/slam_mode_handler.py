"""
SLAM Mode Handler — Orchestrates switching slam_toolbox between
mapping and localization via ROS 2 Lifecycle service calls.

Architecture assumption:
    A separate bringup process has launched two Lifecycle nodes:
        /slam_toolbox_mapping        (starts Active)
        /slam_toolbox_localization   (starts Unconfigured)

This handler is a *remote control* that transitions their states.

Integration:
    from controllers.slam_mode_handler import SlamModeHandler

    # In your main.py, after rclpy.init():
    handler = SlamModeHandler()
    context.setContextProperty("slamModeHandler", handler)

    # From QML or Python, connect a toggle button to:
    handler.requestSwitch("localization")   # or "mapping"
"""

import threading
import traceback
import time
import subprocess
from enum import Enum
from typing import Optional

from PySide6.QtCore import QObject, Signal, Slot, Property

try:
    import rclpy
    from rclpy.node import Node
    from rclpy.executors import SingleThreadedExecutor
    from rclpy.callback_groups import ReentrantCallbackGroup
    from lifecycle_msgs.srv import ChangeState, GetState
    from lifecycle_msgs.msg import Transition
    HAS_ROS2 = True
except ImportError:
    HAS_ROS2 = False
    rclpy = None
    Node = None
    SingleThreadedExecutor = None
    ChangeState = None
    GetState = None
    Transition = None

try:
    from slam_toolbox.srv import SerializePoseGraph
    HAS_SLAM_TOOLBOX = True
except ImportError:
    HAS_SLAM_TOOLBOX = False
    SerializePoseGraph = None


class SlamMode(Enum):
    MAPPING = "mapping"
    LOCALIZATION = "localization"


# ── Lifecycle helpers ────────────────────────────────────────────
# These mirror the lifecycle_msgs/msg/Transition constants.
_TRANSITION = {
    "configure":   Transition.TRANSITION_CONFIGURE    if HAS_ROS2 else 1,
    "activate":    Transition.TRANSITION_ACTIVATE      if HAS_ROS2 else 3,
    "deactivate":  Transition.TRANSITION_DEACTIVATE    if HAS_ROS2 else 4,
    "cleanup":     Transition.TRANSITION_CLEANUP       if HAS_ROS2 else 2,
    "shutdown":    Transition.TRANSITION_UNCONFIGURED_SHUTDOWN if HAS_ROS2 else 5,
}


class SlamModeHandler(QObject):
    """
    Qt-friendly ROS 2 client for toggling slam_toolbox between
    mapping and localization modes.

    Signals (for QML / Python UI binding):
        modeChanged(str)      — emitted with "mapping" or "localization"
        statusMessage(str)    — human-readable progress messages
        switchStarted()       — emitted when a switch begins
        switchFinished(bool)  — emitted when a switch completes (True = success)
    """

    modeChanged = Signal(str)
    statusMessage = Signal(str, str)   # message, level ("info"/"warning"/"error"/"success")
    switchStarted = Signal()
    switchFinished = Signal(bool)
    switchingChanged = Signal()

    # ── Node names matching wheelchair_navigation slam_launch.py ─
    MAPPING_NODE = "/slam_toolbox_mapping"
    LOCALIZATION_NODE = "/slam_toolbox_localization"
    SERIALIZE_SERVICE = "/slam_toolbox_mapping/serialize_map"

    # Default path (no extension — slam_toolbox appends .posegraph / .data)
    DEFAULT_MAP_PATH = "/tmp/slam_toolbox_map"

    def __init__(
        self,
        project_manager=None,
        mapping_node: str = MAPPING_NODE,
        localization_node: str = LOCALIZATION_NODE,
        serialize_service: str = SERIALIZE_SERVICE,
        default_map_path: str = DEFAULT_MAP_PATH,
        parent=None,
    ):
        super().__init__(parent)
        self._project_manager = project_manager
        self._mapping_node = mapping_node
        self._localization_node = localization_node
        self._serialize_service = serialize_service
        self._default_map_path = default_map_path

        self._current_mode = SlamMode.MAPPING
        self._switching = False
        self._node: Optional[Node] = None
        self._lifecycle_clients = {}
        self._serialize_client = None
        self._map_server_process = None
        self._yaml_path = None
        self._lock = threading.Lock()

        # Sync initial state in background so we don't block GUI
        threading.Thread(target=self._sync_initial_state, daemon=True).start()

    # ── Qt Properties ───────────────────────────────────────────

    @Property(str, notify=modeChanged)
    def currentMode(self) -> str:
        return self._current_mode.value

    @Property(bool, notify=switchingChanged)
    def isSwitching(self) -> bool:
        return self._switching

    # ── Public API (callable from QML via @Slot) ────────────────

    @Slot(str)
    def requestSwitch(self, target_mode: str):
        """
        Request a mode switch.  ``target_mode`` is "mapping" or "localization".
        The heavy lifting runs in a background thread so the GUI stays responsive.
        """
        try:
            target = SlamMode(target_mode)
        except ValueError:
            self.statusMessage.emit(f"Unknown mode: {target_mode}", "error")
            return

        if target == self._current_mode:
            self.statusMessage.emit(f"Already in {target.value} mode.", "warning")
            return

        if self._switching:
            self.statusMessage.emit("A switch is already in progress.", "warning")
            return

        self._switching = True
        self.switchingChanged.emit()
        self.switchStarted.emit()
        threading.Thread(
            target=self._do_switch, args=(target,), daemon=True
        ).start()

    @Slot(str)
    def setMapPath(self, path: str):
        """Override the file path used when serialising the pose graph."""
        self._default_map_path = path
        self.statusMessage.emit(f"Map save path set to: {path}", "info")

    @Slot(str)
    def setYamlPath(self, path: str):
        """Override the yaml file path used when serving the map locally."""
        self._yaml_path = path
        self.statusMessage.emit(f"Map YAML path set to: {path}", "info")

    @Slot()
    def shutdown(self):
        """Destroy the internal ROS node and processes (call on app exit)."""
        self._stop_local_map_server()
        if self._node is not None:
            try:
                self._node.destroy_node()
            except Exception:
                pass
            self._node = None

    # ── Internal ────────────────────────────────────────────────

    def _sync_initial_state(self):
        """Query ROS lifecycle nodes in the background to sync initial GUI state."""
        try:
            self._ensure_node()
            map_state = self._get_lifecycle_state(self._mapping_node, timeout_sec=5.0)
            loc_state = self._get_lifecycle_state(self._localization_node, timeout_sec=5.0)
            
            if map_state is None and loc_state is None:
                self.statusMessage.emit("Warning: Could not sync with ROS nodes. They may be hanging.", "warning")
            elif loc_state == "active":
                self._current_mode = SlamMode.LOCALIZATION
                self.modeChanged.emit(self._current_mode.value)
        except Exception as e:
            print(f"[SlamModeHandler] Could not sync initial state: {e}")

    def _get_lifecycle_state(self, node_name: str, timeout_sec: float = 2.0) -> Optional[str]:
        """Fetch current state of a lifecycle node."""
        service_name = f"{node_name}/get_state"
        client = self._node.create_client(GetState, service_name)
        if not client.wait_for_service(timeout_sec=timeout_sec):
            self._node.destroy_client(client)
            return None
            
        request = GetState.Request()
        future = client.call_async(request)
        self._spin_until_future_complete(future, timeout_sec=timeout_sec)
        
        self._node.destroy_client(client)
        result = future.result()
        if result is not None:
            return result.current_state.label
        return None

    def _ensure_node(self):
        """Create or reuse a lightweight ROS 2 node for service calls."""
        if not HAS_ROS2:
            raise RuntimeError("ROS 2 (rclpy) is not available in this environment.")

        if self._node is None:
            if not rclpy.ok():
                rclpy.init()
            self._node = Node("slam_mode_handler")

    def _do_switch(self, target: SlamMode):
        """Background worker — performs the full transition sequence."""
        try:
            self._ensure_node()

            if target == SlamMode.LOCALIZATION:
                self._switch_to_localization()
            else:
                self._switch_to_mapping()

            self._current_mode = target
            self.modeChanged.emit(target.value)
            self.statusMessage.emit(
                f"Switched to {target.value} mode.", "success"
            )
            self.switchFinished.emit(True)

        except Exception as exc:
            tb = traceback.format_exc()
            self.statusMessage.emit(f"Switch failed: {exc}", "error")
            print(f"[SlamModeHandler] Switch failed:\n{tb}")
            self.switchFinished.emit(False)
        finally:
            self._switching = False
            self.switchingChanged.emit()

    # ── Transition sequences ────────────────────────────────────

    def _switch_to_localization(self):
        """Mapping → Localization (save map first)."""
        self.statusMessage.emit("Saving map (SerializePoseGraph)…", "info")
        self._serialize_map()

        self.statusMessage.emit("Deactivating mapping node…", "info")
        self._lifecycle_transition(self._mapping_node, "deactivate")
        self._lifecycle_transition(self._mapping_node, "cleanup")

        self.statusMessage.emit("Activating localization node & local map server…", "info")
        self._start_local_map_server()
        self._lifecycle_transition(self._localization_node, "configure")
        self._lifecycle_transition(self._localization_node, "activate")

    def _switch_to_mapping(self):
        """Localization → Mapping."""
        self.statusMessage.emit("Deactivating localization node & local map server…", "info")
        self._stop_local_map_server()
        self._lifecycle_transition(self._localization_node, "deactivate")
        self._lifecycle_transition(self._localization_node, "cleanup")

        self.statusMessage.emit("Activating mapping node…", "info")
        # After cleanup the mapping node is in 'unconfigured' state,
        # so we must configure it before activating.
        self._lifecycle_transition(self._mapping_node, "configure")
        self._lifecycle_transition(self._mapping_node, "activate")

    # ── Local Map Server Management ─────────────────────────────

    def _start_local_map_server(self):
        if self._map_server_process is not None:
            self._stop_local_map_server()
            
        import os
        yaml_file = None
        
        # 1. Automagically extract project path from the project manager
        if self._project_manager and hasattr(self._project_manager, 'projectPath'):
            project_dir = getattr(self._project_manager, 'projectPath')
            if project_dir and os.path.exists(project_dir):
                merged_yaml = os.path.join(project_dir, "merged_map.yaml")
                if os.path.exists(merged_yaml):
                    yaml_file = merged_yaml
                else:
                    original_yaml = os.path.join(project_dir, "original_map.yaml")
                    if os.path.exists(original_yaml):
                        yaml_file = original_yaml
        
        # 2. Fallbacks
        if not yaml_file:
            yaml_file = self._yaml_path if self._yaml_path else f"{self._default_map_path}.yaml"

        if not os.path.exists(yaml_file):
            raise RuntimeError(f"Map YAML file not found locally: {yaml_file}")

        cmd = [
            "ros2", "run", "nav2_map_server", "map_server",
            "--ros-args", 
            "-p", f"yaml_filename:={yaml_file}",
            "-p", "use_lifecycle_mgr:=false",
            "-r", "__node:=map_server_local_gui"
        ]
        self.statusMessage.emit(f"Spawning local map server for {yaml_file}", "info")
        # Removing DEVNULL so that any internal C++ crashes are printed exactly in the user's terminal
        self._map_server_process = subprocess.Popen(cmd)
        
        # Give the OS a moment to load the C++ node payload
        time.sleep(1.0)
        if self._map_server_process.poll() is not None:
            raise RuntimeError("map_server local subprocess crashed instantly upon launch.")
        
        # Configure and activate the newly spawned lifecycle node
        self._lifecycle_transition("map_server_local_gui", "configure", timeout_sec=15.0)
        self._lifecycle_transition("map_server_local_gui", "activate", timeout_sec=5.0)

    def _stop_local_map_server(self):
        if self._map_server_process is not None:
            self._map_server_process.terminate()
            try:
                self._map_server_process.wait(timeout=2.0)
            except subprocess.TimeoutExpired:
                self._map_server_process.kill()
            self._map_server_process = None

    # ── Lifecycle service call ──────────────────────────────────

    def _spin_until_future_complete(self, future, timeout_sec: float):
        """Safely spin until future complete while yielding the Python GIL to prevent Qt GUI freezes."""
        executor = SingleThreadedExecutor()
        executor.add_node(self._node)
        try:
            start_time = time.time()
            while rclpy.ok() and not future.done() and (time.time() - start_time) < timeout_sec:
                executor.spin_once(timeout_sec=0.01)
                time.sleep(0.01)  # VITAL: Releases GIL back to QML GUI thread
        finally:
            executor.remove_node(self._node)

    def _lifecycle_transition(self, node_name: str, transition_label: str, timeout_sec: float = 10.0):
        """
        Call /<node_name>/change_state with the requested transition.
        Blocks until the response arrives or *timeout_sec* expires.
        """
        current_state = self._get_lifecycle_state(node_name, timeout_sec=timeout_sec)
        
        if current_state is None:
            raise RuntimeError(f"Unable to query state for {node_name}. The node might be hanging due to time jumps.")

        # Skip redundant transitions to prevent Lifecycle errors
        if current_state == "unconfigured" and transition_label in ["deactivate", "cleanup", "shutdown"]:
            self.statusMessage.emit(f"  ✓ {node_name} already unconfigured, skipping {transition_label}", "info")
            return
        elif current_state == "inactive" and transition_label == "deactivate":
            self.statusMessage.emit(f"  ✓ {node_name} already inactive, skipping {transition_label}", "info")
            return
        elif current_state == "active" and transition_label in ["configure", "activate"]:
            self.statusMessage.emit(f"  ✓ {node_name} already active, skipping {transition_label}", "info")
            return

        service_name = f"{node_name}/change_state"
        
        # Cache and reuse clients to avoid wait set corruption
        if node_name not in self._lifecycle_clients:
            self._lifecycle_clients[node_name] = self._node.create_client(ChangeState, service_name)
        client = self._lifecycle_clients[node_name]

        if not client.wait_for_service(timeout_sec=timeout_sec):
            services = self._node.get_service_names_and_types()
            known = [s[0] for s in services if 'change_state' in s[0].lower()]
            print(f"[SlamModeHandler] ERROR: Lifecycle service {service_name} not available.")
            print(f"[SlamModeHandler] Known 'change_state' services: {known}")
            raise RuntimeError(
                f"Service {service_name} not available after {timeout_sec}s. "
                "Ensure GUI and nodes share the same ROS_DOMAIN_ID/network."
            )

        request = ChangeState.Request()
        request.transition.id = _TRANSITION[transition_label]

        future = client.call_async(request)
        self._spin_until_future_complete(future, timeout_sec=timeout_sec)

        if future.result() is None:
            raise RuntimeError(
                f"Lifecycle transition '{transition_label}' on {node_name} timed out"
            )
        if not future.result().success:
            raise RuntimeError(
                f"Lifecycle transition '{transition_label}' on {node_name} failed"
            )

        # Removed destroy_client to prevent wait set index errors
        self.statusMessage.emit(
            f"  ✓ {node_name}: {transition_label}", "info"
        )

    # ── Serialize map ───────────────────────────────────────────

    def _serialize_map(self, timeout_sec: float = 15.0):
        """
        Call SerializePoseGraph on the mapping node to persist
        the current map to disk before deactivating it.
        """
        if not HAS_SLAM_TOOLBOX:
            raise RuntimeError(
                "slam_toolbox.srv.SerializePoseGraph is not available. "
                "Ensure slam_toolbox is installed and sourced."
            )

        # If we already discovered and cached the correct client, reuse it
        if self._serialize_client is not None:
            active_client = self._serialize_client
        else:
            # Check common names since namespace='' often makes it /serialize_map
            candidates = [
                self._serialize_service, 
                "/serialize_map", 
                "/slam_toolbox/serialize_map"
            ]
            
            clients = {
                name: self._node.create_client(SerializePoseGraph, name)
                for name in candidates
            }

            start_time = time.time()
            active_client = None
            
            while time.time() - start_time < timeout_sec:
                for name, client in clients.items():
                    if client.service_is_ready():
                        active_client = client
                        self._serialize_service = name # Cache for next time
                        self._serialize_client = client
                        break
                if active_client is not None:
                    break
                time.sleep(0.1)

        if active_client is None:
            # Gather debug info for the user
            services = self._node.get_service_names_and_types()
            known = [s[0] for s in services if 'serialize' in s[0].lower()]
            print(f"[SlamModeHandler] ERROR: Could not find SerializePoseGraph service.")
            print(f"[SlamModeHandler] Known 'serialize' services in graph: {known}")
            
            # Clean up clients
            for client in clients.values():
                self._node.destroy_client(client)
                
            raise RuntimeError(
                f"SerializePoseGraph service not available after {timeout_sec}s. "
                "Are the GUI and ROS nodes on the same ROS_DOMAIN_ID/network?"
            )

        request = SerializePoseGraph.Request()
        request.filename = self._default_map_path

        future = active_client.call_async(request)
        self._spin_until_future_complete(future, timeout_sec=timeout_sec)

        if future.result() is None:
            raise RuntimeError("SerializePoseGraph call timed out")

        # slam_toolbox's SerializePoseGraph returns a result field
        result = future.result()
        
        # Removed destroy_client calls to prevent wait set index errors
        self.statusMessage.emit(
            f"  ✓ Map saved to {self._default_map_path}", "success"
        )
        return result
