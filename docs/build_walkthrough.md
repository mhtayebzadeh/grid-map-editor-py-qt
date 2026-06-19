# Building the Linux Binary

I have prepared the project for packaging by:
1.  Updating `main.py` with a `get_resource_path` helper to find QML and images when bundled.
2.  Creating a `OccupancyGridMapEditor.spec` file that includes all necessary assets.

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
Once the build completes, you will find the standalone executable in the `dist/` directory:
```bash
./dist/OccupancyGridMapEditor
```

---

### Tips for a better build:
*   **One-File vs One-Dir**: The current spec file is configured for **One-File** mode (a single binary). If you prefer a faster startup and don't mind a folder, you can change the spec file or use `pyinstaller --onedir main.py`.
*   **UPX Compression**: If you have `upx` installed on your system, PyInstaller will use it to compress the binary further.
*   **ROS2 Dependencies**: If you encounter errors related to `rclpy` during the build, you may need to exclude it in the spec file (`excludes=['rclpy']`) and ensure the user has ROS2 installed on their system to run those features.
