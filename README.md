# Occupancy Grid Map Editor (PySide6 & ROS2)

An interactive, high-performance desktop application for viewing, annotating, and editing robotic occupancy grid maps (PGM/YAML format). The application supports live mapping via ROS 2 SLAM (slamtoolbox) and offline manual map corrections and annotations.

---

## Features
- **Map Editing Tools**: edit ocuppancy grid map (overwrite `Obstacle`, `Free` and `Unknown` area).
- **Overlay Opacity Slider**: Adjust edit transparency on-the-fly without corrupting the raw data output.
- **ROS 2 Integration**: Subscribes to laser scans, robot transformations, and occupancy grid map.
- **Layer System**: Work on multiple semantic overlay layers (Keepout layer, ...).

---

## Installation & Setup

### Prerequisites
Make sure you have Python 3.8+ installed. You can install all requirements using pip:
```bash
pip install -r requirements.txt
```

---

## How to Run

### Method 1: Running without Installation (In-place)
You can run the application directly from the cloned repository without installing it to your system paths. Use the bundled runner script:
```bash
./run.sh
```
*(This automatically configures the `PYTHONPATH` context to locate the package internally).*

### Method 2: Installing as a Python Package
To install the application directly into your local python environment:

```bash
# Install in editable/development mode
pip install -e .

# Or install normally
pip install .
```
After installation, you can launch the app from any directory by typing:
```bash
grid-map-editor
```

---

## Standalone Binary Compilation (PyInstaller)
If you want to package the application as a standalone executable (distributable without requiring Python to be installed on the host machine):

1. Install PyInstaller:
   ```bash
   pip install pyinstaller
   ```
2. Build the executable using the spec file:
   ```bash
   pyinstaller OccupancyGridMapEditor.spec
   ```
3. The standalone binary will be generated inside the `dist/` directory.

---
