# Building the Binary (Linux / Windows)

`OccupancyGridMapEditor.spec` bundles the `grid_map_editor` package (entry: `src/grid_map_editor/__main__.py`)
with its QML and image resources at `grid_map_editor/resources`, where `app.py` looks them up.
For the Windows installer see `windows/build.bat` and the README.

Follow these steps to generate the executable:

### 1. Setup Environment
Ensure you have the required tools installed in your Python environment:
```bash
pip install pyinstaller
pip install -r requirements.txt
```

### 2. Build the Executable
Run PyInstaller using the provided spec file:
```bash
pyinstaller OccupancyGridMapEditor.spec
```

### 3. Locate the Binary
Once the build completes, you will find the application folder in the `dist/` directory:
```bash
./dist/GridMapEditor/GridMapEditor
```

---

### Tips for a better build:
*   **One-Dir**: The spec builds a folder instead of a single file: a one-file build unpacks ~150 MB of Qt on every start.
*   **ROS2**: `rclpy` is excluded from the bundle; ROS 2 features need a ROS 2 installation and are disabled otherwise.
*   **Unused Qt modules** (WebEngine, 3D, Multimedia, ...) are excluded in the spec to keep the bundle small.
