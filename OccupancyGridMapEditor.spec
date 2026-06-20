# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

# List of data files to include: (source_path, destination_folder)
# We copy src/grid_map_editor/resources to grid_map_editor/resources inside the bundle
# so that dynamic relative path resolution inside app.py works seamlessly.
added_files = [
    ('src/grid_map_editor/resources', 'grid_map_editor/resources'),
]

a = Analysis(
    ['src/grid_map_editor/app.py'],
    pathex=[],
    binaries=[],
    datas=added_files,
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)
pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='OccupancyGridMapEditor',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon='src/grid_map_editor/resources/images/app_icon.ico'
)
