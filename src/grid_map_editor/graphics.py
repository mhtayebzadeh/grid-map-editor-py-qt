"""
Graphics backend selection with automatic fallback for PCs without a usable GPU
(no/old driver, virtual machines, Remote Desktop).

Modes, in fallback order:
  hardware  Qt default: Direct3D 11 on Windows, OpenGL on Linux (GPU)
  cpu       Same API rendered on the CPU: Direct3D WARP (Windows) / Mesa llvmpipe (Linux)
  basic     Qt Quick software renderer, no graphics API at all (last resort)

"auto" (default) starts with the last mode that worked. The app runs under a small
supervisor process: if the scene graph fails to initialize, or the app dies before its
first frame (e.g. a driver crash), it is restarted right away in the next mode. The
working mode is remembered, so the fallback happens only once per PC.

Force a mode with:  --renderer hardware|cpu|basic   (or GRID_MAP_EDITOR_RENDERER)
"""

import json
import os
import subprocess
import sys
from pathlib import Path

from PySide6.QtCore import QCoreApplication, QProcess
from PySide6.QtQuick import QQuickWindow, QSGRendererInterface

MODES = ["hardware", "cpu", "basic"]

_SUPERVISED_ENV = "GRID_MAP_EDITOR_SUPERVISED"
_RESTART_EXIT_CODE = 75


def state_dir() -> Path:
    if sys.platform == "win32":
        base = Path(os.environ.get("LOCALAPPDATA") or Path.home() / "AppData" / "Local")
        path = base / "GridMapEditor"
    else:
        base = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state")
        path = base / "grid_map_editor"
    path.mkdir(parents=True, exist_ok=True)
    return path


_STATE_FILE = "graphics.json"
_PENDING_FILE = "graphics_pending"


def _next_mode(mode: str):
    index = MODES.index(mode)
    return MODES[index + 1] if index + 1 < len(MODES) else None


def _read_saved_mode() -> str:
    try:
        mode = json.loads((state_dir() / _STATE_FILE).read_text()).get("mode")
        return mode if mode in MODES else "hardware"
    except (OSError, ValueError):
        return "hardware"


def _save_mode(mode: str):
    try:
        (state_dir() / _STATE_FILE).write_text(json.dumps({"mode": mode}))
    except OSError:
        pass


def is_auto(requested: str) -> bool:
    requested = (requested or os.environ.get("GRID_MAP_EDITOR_RENDERER") or "auto").lower()
    return requested not in MODES


def _app_command():
    if getattr(sys, "frozen", False):
        return [sys.executable] + sys.argv[1:]
    utf8 = ["-X", "utf8"] if sys.flags.utf8_mode else []
    return [sys.executable] + utf8 + ["-m", "grid_map_editor"] + sys.argv[1:]


def needs_supervisor(requested: str) -> bool:
    return is_auto(requested) and os.environ.get(_SUPERVISED_ENV) != "1"


def run_supervised() -> int:
    """Run the app as a child process and restart it in the next graphics mode if it
    fails before showing its first frame. Returns the app's exit code."""
    env = dict(os.environ, **{_SUPERVISED_ENV: "1"})
    code = 0
    for _ in range(len(MODES) + 1):
        code = subprocess.call(_app_command(), env=env)
        crashed_before_first_frame = (state_dir() / _PENDING_FILE).exists()
        if code == _RESTART_EXIT_CODE or (code != 0 and crashed_before_first_frame):
            print(f"Graphics: app exited with code {code} before showing a window, restarting")
            continue
        return code
    return code


class GraphicsSelector:
    def __init__(self, requested: str):
        self.auto = is_auto(requested)
        requested = (requested or os.environ.get("GRID_MAP_EDITOR_RENDERER") or "auto").lower()
        self.mode = requested if not self.auto else self._choose_auto_mode()
        self._frame_seen = False

    def _choose_auto_mode(self) -> str:
        mode = _read_saved_mode()
        pending = state_dir() / _PENDING_FILE
        if pending.exists():
            crashed_mode = pending.read_text().strip()
            pending.unlink(missing_ok=True)
            if crashed_mode == mode and _next_mode(mode):
                print(f"Graphics: previous start in '{mode}' mode did not show a window, "
                      f"falling back to '{_next_mode(mode)}'")
                mode = _next_mode(mode)
                _save_mode(mode)
        return mode

    def apply(self):
        """Must run before QGuiApplication is created"""
        if self.mode == "cpu":
            os.environ["QSG_RHI_PREFER_SOFTWARE_RENDERER"] = "1"  # Direct3D WARP
            if sys.platform != "win32":
                os.environ["LIBGL_ALWAYS_SOFTWARE"] = "1"  # Mesa llvmpipe
        elif self.mode == "basic":
            QQuickWindow.setGraphicsApi(QSGRendererInterface.GraphicsApi.Software)
        if self.auto:
            (state_dir() / _PENDING_FILE).write_text(self.mode)
        print(f"Graphics mode: {self.mode}{' (auto)' if self.auto else ''}")

    def watch(self, window: QQuickWindow):
        """Detect render failures on the main window"""
        window.sceneGraphError.connect(self._on_scene_graph_error)
        window.frameSwapped.connect(self._on_first_frame)

    def _on_first_frame(self):
        if self._frame_seen:
            return
        self._frame_seen = True
        if self.auto:
            (state_dir() / _PENDING_FILE).unlink(missing_ok=True)
            _save_mode(self.mode)

    def _on_scene_graph_error(self, error, message):
        print(f"Graphics: scene graph error in '{self.mode}' mode: {message}")
        next_mode = _next_mode(self.mode)
        if self.auto and next_mode:
            (state_dir() / _PENDING_FILE).unlink(missing_ok=True)
            _save_mode(next_mode)
            print(f"Graphics: restarting in '{next_mode}' mode")
            if os.environ.get(_SUPERVISED_ENV) == "1":
                QCoreApplication.exit(_RESTART_EXIT_CODE)
            else:
                restart_application()
        else:
            print("Graphics: no fallback left, start with --renderer basic")
            QCoreApplication.exit(1)


def restart_application():
    """Start a fresh copy of this application with the same arguments, then quit"""
    command = _app_command()
    QProcess.startDetached(command[0], command[1:])
    QCoreApplication.exit(0)
