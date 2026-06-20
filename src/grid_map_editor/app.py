import sys
import ctypes
from pathlib import Path

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Slot

from grid_map_editor.controllers.map_provider import MapImageProvider, MapController
from grid_map_editor.controllers.ros_manager import ROSManager
from grid_map_editor.controllers.project_manager import ProjectManager

class ClipboardHelper(QObject):
    def __init__(self):
        super().__init__()

    @Slot(str)
    def copyText(self, text):
        QGuiApplication.clipboard().setText(text)

def main():
    if sys.platform == 'win32':
        myappid = u'mycompany.myproduct.subproduct.version' # arbitrary string
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)

    app = QGuiApplication(sys.argv)
    app.setOrganizationName("MapEditorOrg")
    app.setOrganizationDomain("mapeditor.org")
    app.setApplicationName("OccupancyGridMapEditor")

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
    
    context = engine.rootContext()
    context.setContextProperty("projectManager", project_manager)
    context.setContextProperty("mapController", map_controller)
    context.setContextProperty("robotHandler", robot_handler)
    context.setContextProperty("clipboardHelper", clipboard_helper)
    
    # 3. Connect Signals
    robot_handler.mapReceived.connect(map_controller.handleRosMap)
    
    # Load the QML file relative to the package resources
    qml_file = package_dir / "resources" / "qml" / "main.qml"
    engine.load(str(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    # Cleanup on exit
    app.aboutToQuit.connect(robot_handler.stop_ros)
    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
