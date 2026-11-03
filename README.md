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

## Windows

### Installer (recommended, nothing else needed)
Download `GridMapEditor-Setup-<version>.exe` from the repository's **Releases** page and run it. No Python or admin rights are needed (it installs for the current user; "all users" can be chosen in the installer). It adds **Grid Map Editor** to the Start menu and desktop.

The installer is not code-signed, so Windows SmartScreen may show "Windows protected your PC": click **More info → Run anyway**.

### From source
```bat
install.bat   :: creates .venv, installs the package, adds a "Grid Map Editor (source)" shortcut
run.bat       :: runs the app from the source tree
```
`install.bat` installs Python 3.12 with `winget` if no Python 3.10+ is found.

ROS 2 features (SLAM mode, live robot pose/scan) need ROS 2 and are disabled on Windows; map editing works fully.

---

## Graphics (GPU and no-GPU PCs)
The app picks the graphics backend automatically:

| Mode | Renderer | Used when |
|------|----------|-----------|
| `hardware` | GPU (Direct3D 11 on Windows, OpenGL on Linux) | Default |
| `cpu` | Same API on the CPU (Direct3D WARP / Mesa llvmpipe) | GPU fails or crashes |
| `basic` | Qt Quick software renderer | Last resort |

If the GPU path fails to start (missing driver, VM, Remote Desktop), the app restarts itself in the next mode within the same launch and remembers the working mode. To force a mode: `--renderer hardware|cpu|basic` (or the **Grid Map Editor (Safe graphics mode)** Start menu shortcut, which uses `cpu`). To retry the GPU after a driver update, delete `graphics.json` from `%LOCALAPPDATA%\GridMapEditor` (Linux: `~/.local/state/grid_map_editor`). Logs of the installed app: `%LOCALAPPDATA%\GridMapEditor\logs\app.log`.

---

## Standalone Binary Compilation (PyInstaller)
Linux or Windows:
```bash
pip install pyinstaller -r requirements.txt
pyinstaller OccupancyGridMapEditor.spec
```
Output: `dist/GridMapEditor/` (run `GridMapEditor` / `GridMapEditor.exe` inside it).

### Windows installer
- **GitHub Actions:** `.github/workflows/windows-installer.yml` builds the installer on every push to `main` (download it from the run's *Artifacts*). To release, bump `__version__` in `src/grid_map_editor/__init__.py`, commit, and push a matching tag such as `v0.1.0`; the installer is then published as a GitHub Release.
- **Locally:** install Python 3.10–3.13 and [Inno Setup 6.3+](https://jrsoftware.org/isdl.php), then double-click `windows\build.bat`. Output: `dist-installer\GridMapEditor-Setup-<version>.exe`.

---
