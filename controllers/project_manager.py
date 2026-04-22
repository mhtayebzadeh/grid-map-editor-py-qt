import json
import os
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property

class ProjectManager(QObject):
    projectLoaded = Signal()
    projectSaved = Signal()
    errorOccurred = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        self._project_name = ""
        self._project_path = ""
        self._map_file = ""
        self._yaml_file = ""
        self._resolution = 0.05
        self._is_loaded = False
        self._layers = []
        self._edited_overlay = ""
        self._robot_topic = "/pose"
        self._map_topic = "/map"
        self._scan_topic = "/scan"
        self._mapping_param = "/slam_toolbox/mapping_enabled"

    @Property(str, notify=projectLoaded)
    def projectName(self):
        return self._project_name
        
    @Property(str, notify=projectLoaded)
    def projectPath(self):
        return self._project_path

    @Property(str, notify=projectLoaded)
    def robotTopic(self): return self._robot_topic

    @Property(str, notify=projectLoaded)
    def mapTopic(self): return self._map_topic

    @Property(str, notify=projectLoaded)
    def scanTopic(self): return self._scan_topic

    @Property(str, notify=projectLoaded)
    def mappingEnabledParam(self): return self._mapping_param

    @Property(bool, notify=projectLoaded)
    def isLoaded(self):
        return self._is_loaded

    def _uri_to_path(self, uri: str) -> str:
        if uri.startswith("file://"):
            return uri[7:]
        return uri

    @Slot(str, str, str, str, str, str, str, str, str, result=bool)
    def createProject(self, name, folder_uri, map_uri, yaml_uri, resolution_str, robot_topic="/pose", map_topic="/map", scan_topic="/scan", mapping_param=""):
        import shutil
        try:
            folder_path = self._uri_to_path(folder_uri)
            map_path = self._uri_to_path(map_uri)
            yaml_path = self._uri_to_path(yaml_uri)
            
            if not name or not map_path or not folder_path:
                self.errorOccurred.emit("Project name, map file, and folder path are required.")
                return False

            map_path_obj = Path(map_path)
            if not map_path_obj.exists():
                self.errorOccurred.emit("Original map file does not exist.")
                return False

            project_dir = Path(folder_path) / name
            mepro_path = project_dir / f"{name}.mepro"
            
            if mepro_path.exists():
                self.errorOccurred.emit("Project already exists or .mepro file found in the target directory.")
                return False
                
            project_dir.mkdir(parents=True, exist_ok=True)
            
            # Copy map and yaml to project directory
            new_map_path = project_dir / "original_map.pgm"
            shutil.copy(map_path_obj, new_map_path)
            
            new_yaml_path = None
            if yaml_path and Path(yaml_path).exists():
                yaml_path_obj = Path(yaml_path)
                new_yaml_path = project_dir / "original_map.yaml"
                shutil.copy(yaml_path_obj, new_yaml_path)
                
                # Update YAML content to point to the renamed PGM
                try:
                    import yaml
                    with open(new_yaml_path, 'r') as f:
                        yaml_data = yaml.safe_load(f)
                    if yaml_data and isinstance(yaml_data, dict):
                        yaml_data["image"] = "original_map.pgm"
                        with open(new_yaml_path, 'w') as f:
                            yaml.dump(yaml_data, f, default_flow_style=False)
                except Exception as e:
                    print(f"Warning: Failed to update image field in YAML: {e}")
                
            res = float(resolution_str) if resolution_str else 0.05
            
            data = {
                "project_name": name,
                "original_map": str(new_map_path),
                "original_yaml": str(new_yaml_path) if new_yaml_path else "",
                "resolution": res,
                "edited_overlay": "",
                "merged_map": "",
                "robot_topic": robot_topic,
                "map_topic": map_topic,
                "scan_topic": scan_topic,
                "mapping_param": mapping_param
            }
            
            with open(mepro_path, 'w') as f:
                json.dump(data, f, indent=4)
                
            self._project_name = name
            self._project_path = str(project_dir)
            self._map_file = str(new_map_path)
            self._yaml_file = str(new_yaml_path) if new_yaml_path else ""
            self._resolution = res
            self._robot_topic = robot_topic
            self._map_topic = map_topic
            self._scan_topic = scan_topic
            self._mapping_param = mapping_param
            self._is_loaded = True
            
            self.projectLoaded.emit()
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Failed to create project: {e}")
            return False

    @Slot(str, result=bool)
    def openProject(self, mepro_uri):
        try:
            mepro_path = Path(self._uri_to_path(mepro_uri))
            if not mepro_path.exists():
                self.errorOccurred.emit("Project file not found.")
                return False
                
            with open(mepro_path, 'r') as f:
                data = json.load(f)
                
            self._project_name = data.get("project_name", mepro_path.stem)
            self._project_path = str(mepro_path.parent)
            self._map_file = data.get("original_map", "")
            self._yaml_file = data.get("original_yaml", "")
            self._resolution = data.get("resolution", 0.05)
            self._layers = data.get("layers", [])
            self._edited_overlay = data.get("edited_overlay", "")
            self._robot_topic = data.get("robot_topic", "/pose")
            self._map_topic = data.get("map_topic", "/map")
            self._scan_topic = data.get("scan_topic", "/scan")
            self._mapping_param = data.get("mapping_param", "")
            
            self._is_loaded = True
            
            self.projectLoaded.emit()
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Failed to open project: {e}")
            return False

    @Slot(result='QVariantList')
    def getLayers(self):
        return self._layers
        
    @Slot(result=str)
    def getEditedOverlay(self):
        return self._edited_overlay

    @Slot(result=str)
    def getOriginalMap(self):
        return self._map_file

    @Slot(result=str)
    def getOriginalYaml(self):
        return self._yaml_file

    @Slot(result=float)
    def getResolution(self):
        return self._resolution

    def updateMeproLayers(self, layers_meta):
        import datetime
        try:
            if not self._project_name or not self._project_path:
                return
            mepro_path = Path(self._project_path) / f"{self._project_name}.mepro"
            if not mepro_path.exists():
                return
            
            with open(mepro_path, 'r') as f:
                data = json.load(f)
                
            data["layers"] = layers_meta
            now_iso = datetime.datetime.now().isoformat()
            if "createdAt" not in data:
                data["createdAt"] = now_iso
            data["updatedAt"] = now_iso
            data["lastSavedAt"] = now_iso
            
            with open(mepro_path, 'w') as f:
                json.dump(data, f, indent=4)
                
            print(f"Updated mepro with layers and timestamp at {mepro_path}")
        except Exception as e:
            print(f"Failed to update mepro layers: {e}")

