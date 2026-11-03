import argparse
import os
import sys
import ctypes
import time
from pathlib import Path

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Slot

from grid_map_editor import __version__
from grid_map_editor.graphics import MODES, GraphicsSelector, needs_supervisor, run_supervised, state_dir
from grid_map_editor.paths import PathHelper
from grid_map_editor.controllers.map_provider import MapImageProvider, MapController
from grid_map_editor.controllers.ros_manager import ROSManager
from grid_map_editor.controllers.project_manager import ProjectManager

class ClipboardHelper(QObject):
    def __init__(self):
        super().__init__()

    @Slot(str)
    def copyText(self, text):
        QGuiApplication.clipboard().setText(text)

def setup_logging():
    """Windowed builds (PyInstaller, pythonw) have no console: write output to a log file"""
    if sys.stdout is not None and sys.stderr is not None:
        return
    log_dir = state_dir() / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "app.log"
    if log_file.exists() and log_file.stat().st_size > 5 * 1024 * 1024:
        log_file.replace(log_dir / "app.log.1")
    stream = open(log_file, "a", encoding="utf-8", errors="replace", buffering=1)
    sys.stdout = stream
    sys.stderr = stream
    # Qt/QML warnings (e.g. graphics errors) are written by C++ to stderr: point it at the log.
    # A Python qInstallMessageHandler would be called from Qt's render thread and can deadlock.
    os.environ["QT_FORCE_STDERR_LOGGING"] = "1"
    try:
        os.dup2(stream.fileno(), 2)
    except OSError:
        pass
    print(f"\n===== Grid Map Editor {__version__} started {time.strftime('%Y-%m-%d %H:%M:%S')} =====")

def main():
    parser = argparse.ArgumentParser(description="Occupancy Grid Map Editor")
    parser.add_argument("--renderer", choices=["auto"] + MODES, default=None,
                        help="Graphics mode: auto (default), hardware (GPU), cpu (no GPU), basic (safe mode)")
    args, qt_args = parser.parse_known_args()

    setup_logging()

    # Auto graphics mode: a supervisor restarts the app in CPU mode if the GPU path crashes
    if needs_supervisor(args.renderer):
        sys.exit(run_supervised())

    if sys.platform == 'win32':
        myappid = u'AAW.GridMapEditor'  # Groups the taskbar icon with the app's shortcut
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)

    # Graphics backend must be chosen before the application object exists
    graphics = GraphicsSelector(args.renderer)
    graphics.apply()

    app = QGuiApplication([sys.argv[0]] + qt_args)
    app.setOrganizationName("MapEditorOrg")
    app.setOrganizationDomain("mapeditor.org")
    app.setApplicationName("OccupancyGridMapEditor")
    app.setApplicationVersion(__version__)
    # Links the window to grid-map-editor.desktop (dock icon on GNOME/Wayland)
    app.setDesktopFileName("grid-map-editor")

    # Resolve resource paths relative to the package installation directory
    package_dir = Path(__file__).resolve().parent
    icon_path = package_dir / "resources" / "images" / "app_icon.ico"
    app.setWindowIcon(QIcon(str(icon_path)))

    engine = QQmlApplicationEngine()

    # 1. Register Image Provider
    map_image_provider = MapImageProvider()
    engine.addImageProvider("map_provider", map_image_provider)

    # 2. Setup Controllers Context Properties
    project_manager = ProjectManager()
    map_controller = MapController(map_image_provider, project_manager)
    robot_handler = ROSManager()
    clipboard_helper = ClipboardHelper()
    path_helper = PathHelper()

    context = engine.rootContext()
    context.setContextProperty("projectManager", project_manager)
    context.setContextProperty("mapController", map_controller)
    context.setContextProperty("robotHandler", robot_handler)
    context.setContextProperty("clipboardHelper", clipboard_helper)
    context.setContextProperty("pathHelper", path_helper)

    # 3. Connect Signals
    robot_handler.mapReceived.connect(map_controller.handleRosMap)

    # Load the QML file relative to the package resources
    qml_file = package_dir / "resources" / "qml" / "main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    graphics.watch(engine.rootObjects()[0])

    # Cleanup on exit
    app.aboutToQuit.connect(robot_handler.stop_ros)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
