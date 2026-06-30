import json
import os
from pathlib import Path
from PySide6.QtCore import QObject, Signal, Slot, Property

class ProjectManager(QObject):
    projectLoaded = Signal()
    projectSaved = Signal()
    rosConfigChanged = Signal()
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
        self._map_topic = "/map"
        self._scan_topic = "/scan"
        self._tf_topic = "/tf"
        self._robot_frame = "base_link"
        self._init_pose_topic = "/initialpose"
        self._use_sim_time = False
        self._init_uncertainty = 1.5
        
        # New slam_toolbox service settings
        self._reset_map_service_name = "/slam_toolbox/reset"
        self._reset_map_service_type = "slam_toolbox/srv/Reset"
        self._pause_mapping_service_name = "/slam_toolbox/pause_new_measurements"
        self._pause_mapping_service_type = "slam_toolbox/srv/Pause"

    @Property(str, notify=rosConfigChanged)
    def initialPoseTopic(self): return self._init_pose_topic
    @initialPoseTopic.setter
    def initialPoseTopic(self, val): 
        self._init_pose_topic = val
        self.rosConfigChanged.emit()
        
    @Property(bool, notify=rosConfigChanged)
    def useSimTime(self): return self._use_sim_time
    @useSimTime.setter
    def useSimTime(self, val): 
        self._use_sim_time = val
        self.rosConfigChanged.emit()

    @Property(float, notify=rosConfigChanged)
    def initialUncertainty(self): return self._init_uncertainty
    @initialUncertainty.setter
    def initialUncertainty(self, val): 
        self._init_uncertainty = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def resetMapServiceName(self): return self._reset_map_service_name
    @resetMapServiceName.setter
    def resetMapServiceName(self, val):
        self._reset_map_service_name = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def resetMapServiceType(self): return self._reset_map_service_type
    @resetMapServiceType.setter
    def resetMapServiceType(self, val):
        self._reset_map_service_type = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def pauseMappingServiceName(self): return self._pause_mapping_service_name
    @pauseMappingServiceName.setter
    def pauseMappingServiceName(self, val):
        self._pause_mapping_service_name = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def pauseMappingServiceType(self): return self._pause_mapping_service_type
    @pauseMappingServiceType.setter
    def pauseMappingServiceType(self, val):
        self._pause_mapping_service_type = val
        self.rosConfigChanged.emit()

    @Property(str, notify=projectLoaded)
    def projectName(self):
        return self._project_name
        
    @Property(str, notify=projectLoaded)
    def projectPath(self):
        return self._project_path

    @Property(str, notify=rosConfigChanged)
    def mapTopic(self): return self._map_topic
    @mapTopic.setter
    def mapTopic(self, val): 
        self._map_topic = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def scanTopic(self): return self._scan_topic
    @scanTopic.setter
    def scanTopic(self, val): 
        self._scan_topic = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def tfTopic(self): return self._tf_topic
    @tfTopic.setter
    def tfTopic(self, val): 
        self._tf_topic = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def robotFrame(self): return self._robot_frame
    @robotFrame.setter
    def robotFrame(self, val): 
        self._robot_frame = val
        self.rosConfigChanged.emit()

    @Property(str, notify=rosConfigChanged)
    def initialPoseTopic(self): return self._init_pose_topic
    @initialPoseTopic.setter
    def initialPoseTopic(self, val): 
        self._init_pose_topic = val
        self.rosConfigChanged.emit()

    @Property(bool, notify=projectLoaded)
    def isLoaded(self):
        return self._is_loaded

    def _uri_to_path(self, uri: str) -> str:
        if uri.startswith("file://"):
            return uri[7:]
        return uri

    @Slot(str, str, str, str, str, str, str, str, str, result=bool)
    def createProject(self, name, folder_uri, map_uri, yaml_uri, resolution_str, map_topic="/map", scan_topic="/scan", tf_topic="/tf", robot_frame="base_link"):
        import shutil
        try:
            folder_path = self._uri_to_path(folder_uri)
            map_path = self._uri_to_path(map_uri)
            yaml_path = self._uri_to_path(yaml_uri)
            
            if not name or not folder_path:
                self.errorOccurred.emit("Project name and folder path are required.")
                return False

            new_map_path = None
            if map_path:
                map_path_obj = Path(map_path)
                if not map_path_obj.exists():
                    self.errorOccurred.emit("Original map file does not exist.")
                    return False
                
                project_dir = Path(folder_path) / name
                project_dir.mkdir(parents=True, exist_ok=True)
                
                new_map_path = project_dir / "original_map.pgm"
                shutil.copy(map_path_obj, new_map_path)
            else:
                project_dir = Path(folder_path) / name
                project_dir.mkdir(parents=True, exist_ok=True)

            mepro_path = project_dir / f"{name}.mepro"
            if mepro_path.exists():
                self.errorOccurred.emit("Project already exists or .mepro file found in the target directory.")
                return False
            
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
                "original_map": new_map_path.name if new_map_path else "",
                "original_yaml": new_yaml_path.name if new_yaml_path else "",
                "resolution": res,
                "edited_overlay": "",
                "merged_map": "",
                "map_topic": map_topic,
                "scan_topic": scan_topic,
                "tf_topic": tf_topic,
                "robot_frame": robot_frame,
                "initial_pose_topic": self._init_pose_topic,
                "use_sim_time": self._use_sim_time,
                "initial_uncertainty": self._init_uncertainty,
                "reset_map_service_name": self._reset_map_service_name,
                "reset_map_service_type": self._reset_map_service_type,
                "pause_mapping_service_name": self._pause_mapping_service_name,
                "pause_mapping_service_type": self._pause_mapping_service_type,
                "gates_yaml": "gates_list.yaml"
            }
            
            with open(mepro_path, 'w') as f:
                json.dump(data, f, indent=4)
                
            self._project_name = name
            self._project_path = str(project_dir)
            self._map_file = str(new_map_path) if new_map_path else ""
            self._yaml_file = str(new_yaml_path) if new_yaml_path else ""
            self._resolution = res
            self._map_topic = map_topic
            self._scan_topic = scan_topic
            self._tf_topic = tf_topic
            self._robot_frame = robot_frame
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
            self._map_topic = data.get("map_topic", "/map")
            self._scan_topic = data.get("scan_topic", "/scan")
            self._tf_topic = data.get("tf_topic", "/tf")
            self._robot_frame = data.get("robot_frame", "base_link")
            self._init_pose_topic = data.get("initial_pose_topic", "/initialpose")
            self._use_sim_time = data.get("use_sim_time", False)
            self._init_uncertainty = data.get("initial_uncertainty", 1.5)
            self._reset_map_service_name = data.get("reset_map_service_name", "/slam_toolbox/reset")
            self._reset_map_service_type = data.get("reset_map_service_type", "slam_toolbox/srv/Reset")
            self._pause_mapping_service_name = data.get("pause_mapping_service_name", "/slam_toolbox/pause_new_measurements")
            self._pause_mapping_service_type = data.get("pause_mapping_service_type", "slam_toolbox/srv/Pause")
            self._gates_yaml = data.get("gates_yaml", "gates_list.yaml")
            
            self._is_loaded = True
            
            self.projectLoaded.emit()
            return True
        except Exception as e:
            self.errorOccurred.emit(f"Failed to open project: {e}")
            return False

    @Slot(result='QVariantList')
    def getLayers(self):
        resolved = []
        for layer in self._layers:
            l = dict(layer)
            if l.get("file"):
                p = Path(l["file"])
                if not p.is_absolute():
                    l["file"] = str(Path(self._project_path) / p)
            if l.get("yaml"):
                p = Path(l["yaml"])
                if not p.is_absolute():
                    l["yaml"] = str(Path(self._project_path) / p)
            resolved.append(l)
        return resolved
        
    @Slot(result=str)
    def getEditedOverlay(self):
        if not self._edited_overlay: return ""
        p = Path(self._edited_overlay)
        if p.is_absolute(): return str(p)
        return str(Path(self._project_path) / p)

    @Slot(result=str)
    def getOriginalMap(self):
        if not self._map_file: return ""
        p = Path(self._map_file)
        if p.is_absolute(): return str(p)
        return str(Path(self._project_path) / p)

    @Slot(result=str)
    def getOriginalYaml(self):
        if not self._yaml_file: return ""
        p = Path(self._yaml_file)
        if p.is_absolute(): return str(p)
        return str(Path(self._project_path) / p)

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
            
            # Persist current ROS topics as well
            data["map_topic"] = self._map_topic
            data["scan_topic"] = self._scan_topic
            data["tf_topic"] = self._tf_topic
            data["robot_frame"] = self._robot_frame
            data["initial_pose_topic"] = self._init_pose_topic
            data["use_sim_time"] = self._use_sim_time
            data["initial_uncertainty"] = self._init_uncertainty
            data["reset_map_service_name"] = self._reset_map_service_name
            data["reset_map_service_type"] = self._reset_map_service_type
            data["pause_mapping_service_name"] = self._pause_mapping_service_name
            data["pause_mapping_service_type"] = self._pause_mapping_service_type

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

    @Slot(str, str, str, str, str, result=str)
    def copyGateImage(self, source_uri, category_id, gate_name, gate_id, old_rel_path=""):
        try:
            if not self._project_path:
                return source_uri
            
            raw_source = self._uri_to_path(source_uri)
            source_path = Path(raw_source)
            if not source_path.is_absolute():
                source_path = Path(self._project_path) / source_path
            
            if old_rel_path:
                old_path = Path(self._project_path) / old_rel_path
                if old_path.exists() and old_path.resolve() != source_path.resolve():
                    try:
                        old_path.unlink()
                    except Exception as e:
                        print(f"Warning: Failed to delete old image {old_path}: {e}")
            
            if not source_path.exists():
                return source_uri
                
            import shutil
            import re
            
            safe_gate_name = re.sub(r'[^A-Za-z0-9_]', '', gate_name.replace(' ', '_'))
            ext = source_path.suffix
            
            dest_dir = Path(self._project_path) / "gate_images" / category_id
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            new_filename = f"{safe_gate_name}_{gate_id}{ext}"
            dest_path = dest_dir / new_filename
            
            if source_path.resolve() != dest_path.resolve():
                shutil.copy(source_path, dest_path)
            
            # Return relative path using POSIX format
            return dest_path.relative_to(self._project_path).as_posix()
        except Exception as e:
            print(f"Failed to copy gate image: {e}")
            return source_uri

    @Slot(str)
    def deleteGateImage(self, rel_path):
        try:
            if not self._project_path or not rel_path:
                return
            path_to_delete = Path(self._project_path) / rel_path
            if path_to_delete.exists():
                path_to_delete.unlink()
        except Exception as e:
            print(f"Failed to delete gate image {rel_path}: {e}")

    @Slot('QVariantList', 'QVariantList', 'QVariantList', result=bool)
    def saveGates(self, standard_gates, home_gates, charge_stations):
        import yaml
        try:
            if not self._project_path:
                return False
                
            gates_yaml_path = Path(self._project_path) / getattr(self, '_gates_yaml', 'gates_list.yaml')
            
            def map_gate(g):
                img = g.get("imageFile", "")
                prefix = "gate_images/"
                if img.startswith(prefix):
                    img = img[len(prefix):]
                
                return {
                    "id": int(g.get("gateId", 0)),
                    "name": g.get("name", ""),
                    "description": g.get("description", ""),
                    "image_name": img,
                    "position": {
                        "x": float(g.get("xPos", 0.0)),
                        "y": float(g.get("yPos", 0.0)),
                        "theta": 0.0 # Placeholder since UI doesn't have theta yet
                    }
                }
            
            yaml_data = {
                "config": {
                    "images_directory": "gate_images",
                    "map_frame": "map",
                    "map_name": self._project_name,
                    "description": "",
                    "default_approach_distance": 1.0
                },
                "home_gates": [map_gate(g) for g in home_gates] if home_gates else [],
                "charge_stations": [map_gate(g) for g in charge_stations] if charge_stations else [],
                "gates": [map_gate(g) for g in standard_gates] if standard_gates else []
            }
            
            with open(gates_yaml_path, 'w', encoding='utf-8') as f:
                yaml.dump(yaml_data, f, allow_unicode=True, sort_keys=False)
            
            return True
        except Exception as e:
            print(f"Failed to save gates_list.yaml: {e}")
            return False

    @Slot(result='QVariantMap')
    def loadGates(self):
        import yaml
        try:
            if not self._project_path:
                return {}
            
            gates_yaml_path = Path(self._project_path) / getattr(self, '_gates_yaml', 'gates_list.yaml')
            if not gates_yaml_path.exists():
                return {}
                
            with open(gates_yaml_path, 'r', encoding='utf-8') as f:
                yaml_data = yaml.safe_load(f)
                
            if not yaml_data:
                return {}
                
            images_dir = yaml_data.get("config", {}).get("images_directory", "gate_images")
            if not images_dir.endswith("/"):
                images_dir += "/"

            def unmap_gate(g):
                img = g.get("image_name", "")
                if img and not img.startswith("/") and not img.startswith("http") and not img.startswith(images_dir):
                    img = images_dir + img
                    
                return {
                    "gateId": str(g.get("id", "")),
                    "name": g.get("name", ""),
                    "description": g.get("description", ""),
                    "imageFile": img,
                    "xPos": g.get("position", {}).get("x", 0.0),
                    "yPos": g.get("position", {}).get("y", 0.0),
                    "expanded": False
                }
                
            return {
                "home_gates": [unmap_gate(g) for g in yaml_data.get("home_gates", [])],
                "charge_stations": [unmap_gate(g) for g in yaml_data.get("charge_stations", [])],
                "standard_gates": [unmap_gate(g) for g in yaml_data.get("gates", [])]
            }
        except Exception as e:
            print(f"Failed to load gates_list.yaml: {e}")
            return {}

