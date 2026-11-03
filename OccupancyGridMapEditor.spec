# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec for Linux and Windows:  pyinstaller OccupancyGridMapEditor.spec
# Output (one folder, fast startup): dist/GridMapEditor/GridMapEditor[.exe]
# The Windows installer (windows/installer.iss) packages this folder.

from pathlib import Path

ROOT = Path(SPECPATH)
SRC = ROOT / "src"

# Qt modules the app does not use. PySide6 hooks would otherwise bundle their
# libraries and QML plugins (hundreds of MB).
UNUSED_QT = [
    "Qt3D", "QtQuick3D", "QtWebEngine", "QtWebView", "QtWebChannel", "QtWebSockets",
    "QtMultimedia", "QtCharts", "QtGraphs", "QtDataVisualization", "QtLocation",
    "QtPositioning", "QtSensors", "QtBluetooth", "QtNfc", "QtSerialPort", "QtSerialBus",
    "QtRemoteObjects", "QtScxml", "QtStateMachine", "QtTextToSpeech", "QtVirtualKeyboard",
    "QtPdf", "QtSpatialAudio", "QtHttpServer", "QtDesigner", "QtUiTools", "QtTest",
    "QtSql", "QtHelp", "QtNetworkAuth", "QtScxml", "QtQuickTest",
]

a = Analysis(
    # Entry is the package's __main__ so "grid_map_editor" imports work in the bundle
    [str(SRC / "grid_map_editor" / "__main__.py")],
    pathex=[str(SRC)],
    binaries=[],
    # Resources keep their package-relative location: app.py resolves them from __file__
    datas=[(str(SRC / "grid_map_editor" / "resources"), "grid_map_editor/resources")],
    hiddenimports=["grid_map_editor.app"],
    excludes=["tkinter", "rclpy", "matplotlib", "IPython"]
    + [f"PySide6.{name}" for name in UNUSED_QT],
    noarchive=False,
)


def is_unused_qt(dest: str) -> bool:
    parts = dest.replace("\\", "/").split("/")
    return any(part.startswith(name) or part.startswith(f"Qt6{name[2:]}") or part.startswith(f"libQt6{name[2:]}")
               for part in parts for name in UNUSED_QT)


a.binaries = [entry for entry in a.binaries if not is_unused_qt(entry[0])]
a.datas = [entry for entry in a.datas if not is_unused_qt(entry[0])]

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    # UTF-8 mode: project/YAML files with Persian names work regardless of Windows locale
    [("X utf8_mode=1", None, "OPTION")],
    exclude_binaries=True,
    name="GridMapEditor",
    console=False,
    icon=str(SRC / "grid_map_editor" / "resources" / "images" / "app_icon.ico"),
    upx=False,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    name="GridMapEditor",
    upx=False,
)
