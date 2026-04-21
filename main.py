import sys
from pathlib import Path

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from controllers.map_provider import MapImageProvider, MapController
from controllers.robot_handler import RobotHandler
from controllers.project_manager import ProjectManager

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    
    # 1. Register Image Provider
    map_image_provider = MapImageProvider()
    engine.addImageProvider("map_provider", map_image_provider)
    
    # 2. Setup Controllers Context Properties
    project_manager = ProjectManager()
    map_controller = MapController(map_image_provider, project_manager)
    robot_handler = RobotHandler()
    
    context = engine.rootContext()
    context.setContextProperty("projectManager", project_manager)
    context.setContextProperty("mapController", map_controller)
    context.setContextProperty("robotHandler", robot_handler)
    
    # Load the QML file
    qml_file = Path(__file__).resolve().parent / "qml" / "main.qml"
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())
