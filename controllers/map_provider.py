import sys
import yaml
import json
import base64
import cv2
import time
from pathlib import Path
from PIL import Image
import numpy as np

from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl
from PySide6.QtGui import QImage, QColor
from PySide6.QtQml import QQmlImageProviderBase
from PySide6.QtQuick import QQuickImageProvider

class MapImageProvider(QQuickImageProvider):
    def __init__(self):
        super().__init__(QQuickImageProvider.Image)
        self.image = QImage()

    def set_image(self, img: QImage):
        self.image = img

    def requestImage(self, id, size, requestedSize):
        # Handle layer requests: layer?path=/path/to/file.pgm
        if id.startswith("layer?"):
            try:
                import urllib.parse
                params = urllib.parse.parse_qs(id.split("?")[1])
                path = params.get("path", [""])[0]
                if path and Path(path).exists():
                    with Image.open(path) as img:
                        img = img.convert("RGBA")
                        # Process transparency: white (>253) -> transparent
                        data = np.array(img)
                        # Identify white pixels (R, G, B > 253)
                        mask = (data[:, :, 0] > 253) & (data[:, :, 1] > 253) & (data[:, :, 2] > 253)
                        data[mask, 3] = 0
                        
                        # Convert back to QImage
                        height, width, channels = data.shape
                        bytes_per_line = channels * width
                        qimg = QImage(data.data, width, height, bytes_per_line, QImage.Format_RGBA8888).copy()
                        if requestedSize.isValid():
                            qimg = qimg.scaled(requestedSize)
                        return qimg
            except Exception as e:
                print(f"Error serving layer image: {e}")
            return QImage()

        # Default map behavior
        res = self.image
        if not self.image.isNull() and requestedSize.isValid():
            res = self.image.scaled(requestedSize)
        return res

class MapController(QObject):
    mapLoaded = Signal()
    resolutionChanged = Signal()
    originChanged = Signal()
    logMessage = Signal(str, str) # message, type
    
    def __init__(self, provider: MapImageProvider, project_manager, parent=None):
        super().__init__(parent)
        self._provider = provider
        self._project_manager = project_manager
        self._resolution = 0.05
        self._origin = [0.0, 0.0, 0.0]
        self._width = 0
        self._height = 0
        self._image_path = ""
        self._last_map_update_time = 0
        self._is_slam_mode = False
        
    @Property(bool)
    def isSlamMode(self):
        return self._is_slam_mode
        
    @isSlamMode.setter
    def isSlamMode(self, val):
        self._is_slam_mode = val
        
    @Property(float, notify=resolutionChanged)
    def resolution(self):
        return self._resolution
        
    @Property(list, notify=originChanged)
    def origin(self):
        return self._origin
        
    @Property(int, notify=mapLoaded)
    def mapWidth(self):
        return self._width
        
    @Property(int, notify=mapLoaded)
    def mapHeight(self):
        return self._height

    @Slot(str, str, float)
    def loadMap(self, yaml_uri, pgm_uri, default_resolution):
        # Convert QML file URI to local path
        def _uri_to_path(uri):
            if uri.startswith("file://"):
                return uri[7:]
            return uri
            
        yaml_path = _uri_to_path(yaml_uri)
        pgm_path = _uri_to_path(pgm_uri)
        
        self._resolution = default_resolution
        
        # 1. Parse YAML if available
        if yaml_path and Path(yaml_path).exists():
            try:
                with open(yaml_path, 'r') as f:
                    data = yaml.safe_load(f)
                    self._resolution = float(data.get('resolution', self._resolution))
                    self._origin = data.get('origin', [0.0, 0.0, 0.0])
                    
                    # If pgm_path is empty, infer from yaml
                    if not pgm_path and 'image' in data:
                        image_name = data['image']
                        pgm_path = str(Path(yaml_path).parent / image_name)
                        
            except Exception as e:
                print(f"Error reading YAML: {e}")
                
        self.resolutionChanged.emit()
        self.originChanged.emit()
        
        # 2. Load PGM Image (Pillow handles P2/P5 automatically)
        if pgm_path and Path(pgm_path).exists():
            try:
                with Image.open(pgm_path) as img:
                    img = img.convert("L") # Ensure grayscale
                    # Convert PIL Image to QImage
                    data = img.tobytes("raw", "L")
                    qimg = QImage(data, img.width, img.height, img.width, QImage.Format_Grayscale8)
                    
                    # Store a copy because python garbage collection would destroy the raw bytes
                    self._provider.set_image(qimg.copy())
                    self._width = img.width
                    self._height = img.height
                    
                    # Force QML to reload the image by emitting mapLoaded
                    self.mapLoaded.emit()
                    print(f"Map loaded: {self._width}x{self._height} at res {self._resolution}")
                    
            except Exception as e:
                print(f"Error reading PGM: {e}")
                
    @Slot(object)
    def handleRosMap(self, msg):
        """Processes a nav_msgs/OccupancyGrid message."""
        if not self._is_slam_mode:
            return

        now = time.time()
        if now - self._last_map_update_time < 3.0:
            return
            
        self._last_map_update_time = now
        
        try:
            info = msg.info
            width = info.width
            height = info.height
            resolution = info.resolution
            
            # Convert OccupancyGrid data (-1 to 100) to grayscale (0 to 255)
            # ROS convention: 0=free, 100=occupied, -1=unknown
            # We want: 255=free, 0=occupied, 127=unknown
            data = np.array(msg.data, dtype=np.int8).reshape((height, width))
            
            grayscale = np.zeros((height, width), dtype=np.uint8)
            grayscale[data == 0] = 255
            grayscale[data == 100] = 0
            grayscale[data == -1] = 127
            
            # For values between 0 and 100 that are not exactly 0 or 100
            mask = (data > 0) & (data < 100)
            grayscale[mask] = (255 - (data[mask] * 2.55)).astype(np.uint8)
            
            # Flip vertically because ROS map origin is bottom-left, QImage is top-left
            grayscale = np.flipud(grayscale)
            grayscale = np.ascontiguousarray(grayscale)
            
            # Convert to QImage
            qimg = QImage(grayscale.data, width, height, width, QImage.Format_Grayscale8)
            
            self._provider.set_image(qimg.copy())
            self._width = width
            self._height = height
            self._resolution = resolution
            self._origin = [info.origin.position.x, info.origin.position.y, info.origin.position.z]
            
            self.resolutionChanged.emit()
            self.originChanged.emit()
            self.mapLoaded.emit()
            
            print(f"ROS Map updated: {width}x{height} at resolution {resolution}")
            
        except Exception as e:
            print(f"Error processing ROS map: {e}")

    @Slot(str)
    def saveMergedMap(self, base64_image_data):
        try:
            # 1. Decode base64 image coming from QML Canvas
            if "," not in base64_image_data:
                print(f"Error saving merged map: Invalid base64 data received")
                return

            header, encoded = base64_image_data.split(",", 1)
            if not encoded:
                print("Error saving merged map: Received empty image data")
                return
            image_bytes = base64.b64decode(encoded)
            
            overlay_arr = np.frombuffer(image_bytes, dtype=np.uint8)
            overlay_img = cv2.imdecode(overlay_arr, cv2.IMREAD_UNCHANGED) # Should be BGRA/RGBA
            
            if overlay_img is None:
                print(f"Error saving merged map: Failed to decode image")
                return
            
            project_dir = Path(self._project_manager.projectPath)
            edit_layer_path = project_dir / "edit_layer.png"
            merged_path = project_dir / "merged_map.pgm"
            yaml_path = project_dir / "merged_map.yaml"
            
            # Save edit layer (PNG to preserve transparency)
            cv2.imwrite(str(edit_layer_path), overlay_img)
            
            # For merging, we still need a grayscale version where alpha=0 is neutral(127)
            if len(overlay_img.shape) == 3 and overlay_img.shape[2] == 4:
                r, g, b, a = cv2.split(overlay_img)
                gray_for_merge = cv2.cvtColor(overlay_img[:, :, :3], cv2.COLOR_BGR2GRAY)
                gray_for_merge[a == 0] = 127
            else:
                gray_for_merge = cv2.cvtColor(overlay_img[:, :, :3], cv2.COLOR_BGR2GRAY) if len(overlay_img.shape) == 3 and overlay_img.shape[2] >= 3 else overlay_img
            
            # 2. Merge with original PGM map
            original_pgm_path = self._project_manager.getOriginalMap()
            project_dir = Path(self._project_manager.projectPath)
            
            # If this is a SLAM project starting from scratch, original_map might be empty in mepro
            if not original_pgm_path:
                original_pgm_path = str(project_dir / "original_map.pgm")
                print(f"Creating initial original map for SLAM project: {original_pgm_path}")

            # Save the current main map (which may have been updated from ROS) as the original map
            # This is CRITICAL for SLAM mode so we have a base to merge onto.
            if not self._provider.image.isNull():
                self._provider.image.save(original_pgm_path)
                print(f"Saved current ROS map to {original_pgm_path}")
                
            if not Path(original_pgm_path).exists():
                print("Error: original map path invalid or could not be created:", original_pgm_path)
                return
                
            orig_map = cv2.imread(original_pgm_path, cv2.IMREAD_GRAYSCALE)
            if orig_map is None:
                print(f"Error: Could not read original map at {original_pgm_path}")
                return

            # Ensure gray_for_merge matches original map size
            if gray_for_merge.shape[0] != orig_map.shape[0] or gray_for_merge.shape[1] != orig_map.shape[1]:
                gray_for_merge = cv2.resize(gray_for_merge, (orig_map.shape[1], orig_map.shape[0]), interpolation=cv2.INTER_NEAREST)

            # 3. Apply overlay (anything not 127 is a change)
            mask = (gray_for_merge != 127)
            orig_map[mask] = gray_for_merge[mask]
            
            # 4. Save merged map
            cv2.imwrite(str(merged_path), orig_map)
            print(f"Saved merged map to: {merged_path}")
            
            # 3. Create/update YAML metadata
            yaml_data = {
                "image": "merged_map.pgm",
                "resolution": self._resolution,
                "origin": self._origin if self._origin else [0.0, 0.0, 0.0],
                "negate": 0,
                "occupied_thresh": 0.65,
                "free_thresh": 0.196
            }
            
            with open(yaml_path, 'w') as f:
                yaml.dump(yaml_data, f, default_flow_style=False)
            print(f"Saved merged YAML to: {yaml_path}")
            
            # 3b. Create/Update original_map.yaml
            original_yaml_path = project_dir / "original_map.yaml"
            orig_yaml_data = {
                "image": "original_map.pgm",
                "resolution": self._resolution,
                "origin": self._origin if self._origin else [0.0, 0.0, 0.0],
                "negate": 0,
                "occupied_thresh": 0.65,
                "free_thresh": 0.196
            }
            with open(original_yaml_path, 'w') as f:
                yaml.dump(orig_yaml_data, f, default_flow_style=False)
            print(f"Saved/Updated original YAML at: {original_yaml_path}")
            
            # 4. Update the mepro project file
            mepro_path = project_dir / f"{self._project_manager.projectName}.mepro"
            if mepro_path.exists():
                with open(mepro_path, 'r') as f:
                    mepro_data = json.load(f)
                
                mepro_data["original_map"] = "original_map.pgm"
                mepro_data["original_yaml"] = "original_map.yaml"
                mepro_data["edited_overlay"] = edit_layer_path.name
                mepro_data["merged_map"] = merged_path.name
                mepro_data["resolution"] = self._resolution
                
                # Sync topics from project manager
                mepro_data["map_topic"] = self._project_manager.mapTopic
                mepro_data["scan_topic"] = self._project_manager.scanTopic
                mepro_data["tf_topic"] = self._project_manager.tfTopic
                mepro_data["robot_frame"] = self._project_manager.robotFrame
                
                with open(mepro_path, 'w') as f:
                    json.dump(mepro_data, f, indent=4)
                print(f"Updated mepro file at {mepro_path}")
            self.logMessage.emit("Project map layers merged and saved.", "success")
                    
        except Exception as e:
            print(f"Error saving merged map: {e}")
            self.logMessage.emit(f"Error saving map: {e}", "error")

    @Slot('QVariantList')
    def saveProjectFull(self, layersArray):
        import base64
        import io
        import os
        from PIL import Image
        from datetime import datetime
        
        project_dir = Path(self._project_manager.projectPath)
        if not project_dir.exists():
            print("Project dir does not exist.")
            return

        saved_layers_meta = []

        for layer_data in layersArray:
            layerId = layer_data.get('layerId', '')
            name = layer_data.get('name', 'Layer')
            b64 = layer_data.get('b64', '')
            
            # Record metadata
            layer_meta = {
                "layerId": layerId,
                "name": name,
                "colorStr": layer_data.get('colorStr', ''),
                "opacity": layer_data.get('opacity', 1.0),
                "visible": layer_data.get('visible', True),
                "file": ""
            }
            
            if b64 and layerId:
                try:
                    if "," not in b64:
                        print(f"Failed to save layer {layerId}: Invalid base64 data")
                        continue

                    header, encoded = b64.split(",", 1)
                    img_data = base64.b64decode(encoded)
                    
                    # Open with PIL
                    overlay_img = Image.open(io.BytesIO(img_data)).convert('RGBA')
                    
                    # Convert to numpy to handle alpha correctly
                    img_np = np.array(overlay_img)
                    r = img_np[:, :, 0]
                    a = img_np[:, :, 3]
                    
                    # Create grayscale map where alpha=0 is white(255)
                    # For Keepout, black is drawn where zone is.
                    gray_np = r.copy()
                    gray_np[a == 0] = 255
                    
                    l_img = Image.fromarray(gray_np)
                    
                    # Use name as filename, sanitized
                    safe_name = "".join([c for c in name if c.isalnum() or c in (' ', '.', '_')]).strip().replace(' ', '_')
                    out_path = project_dir / f"{safe_name}.pgm"
                    l_img.save(str(out_path))
                    layer_meta["file"] = out_path.name
                    print(f"Saved layer '{name}' to {out_path}")
                except Exception as e:
                    print(f"Failed to save layer {layerId}: {e}")
            
            saved_layers_meta.append(layer_meta)
            
        # Cleanup: Delete any .pgm files that are no longer in the layers list
        # (Excluding special files: original_map.pgm, merged_map.pgm)
        try:
            active_filenames = [Path(m["file"]).name for m in saved_layers_meta if m.get("file")]
            special_files = ["original_map.pgm", "merged_map.pgm"]
            
            for pgm_file in project_dir.glob("*.pgm"):
                if pgm_file.name not in active_filenames and pgm_file.name not in special_files:
                    print(f"Deleting removed layer file: {pgm_file}")
                    pgm_file.unlink()
        except Exception as e:
            print(f"Error during layer file cleanup: {e}")
            
        # Tell project manager to update mepro with layers and timestamps
        self._project_manager.updateMeproLayers(saved_layers_meta)
        self.logMessage.emit("Project saved successfully.", "success")
