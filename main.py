import sys
import ctypes
from pathlib import Path

from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from controllers.map_provider import MapImageProvider, MapController
from controllers.ros_manager import ROSManager
from controllers.project_manager import ProjectManager

if __name__ == "__main__":

    if sys.platform == 'win32':
        myappid = u'mycompany.myproduct.subproduct.version' # arbitrary string
        ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)

    app = QGuiApplication(sys.argv)
    app.setOrganizationName("MapEditorOrg")
    app.setOrganizationDomain("mapeditor.org")
    app.setApplicationName("OccupancyGridMapEditor")
    app.setWindowIcon(QIcon("resources/images/app_icon.ico"))

    engine = QQmlApplicationEngine()
    
    # 1. Register Image Provider
    map_image_provider = MapImageProvider()
    engine.addImageProvider("map_provider", map_image_provider)
    
    # 2. Setup Controllers Context Properties
    project_manager = ProjectManager()
    map_controller = MapController(map_image_provider, project_manager)
    robot_handler = ROSManager()
    
    context = engine.rootContext()
    context.setContextProperty("projectManager", project_manager)
    context.setContextProperty("mapController", map_controller)
    context.setContextProperty("robotHandler", robot_handler)
    
    # Load the QML file
    qml_file = Path(__file__).resolve().parent / "qml" / "main.qml"
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    # Cleanup on exit
    app.aboutToQuit.connect(robot_handler.stop_ros)
    
    sys.exit(app.exec())
