#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ICON_PATH="$SCRIPT_DIR/src/grid_map_editor/resources/images/icon_sq1.png"

if [ ! -f "$ICON_PATH" ]; then
    echo "Warning: Icon not found at $ICON_PATH"
fi

# Detect virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
    echo "Active virtual environment detected: $VIRTUAL_ENV"
    VENV_PATH="$VIRTUAL_ENV"
elif [ -d "$SCRIPT_DIR/.venv" ]; then
    echo "Existing virtual environment found at $SCRIPT_DIR/.venv"
    VENV_PATH="$SCRIPT_DIR/.venv"
else
    echo "No virtual environment active. Creating virtual environment at $SCRIPT_DIR/.venv..."
    python3 -m venv "$SCRIPT_DIR/.venv"
    VENV_PATH="$SCRIPT_DIR/.venv"
fi

PYTHON_BIN="$VENV_PATH/bin/python3"
PIP_BIN="$VENV_PATH/bin/pip"

if [ ! -f "$PIP_BIN" ]; then
    echo "Error: pip not found in $VENV_PATH"
    exit 1
fi

echo "Upgrading pip in virtual environment..."
"$PIP_BIN" install --upgrade pip

echo "Installing Grid Map Editor package..."
"$PIP_BIN" install -e "$SCRIPT_DIR"

# Ensure run.sh is executable
chmod +x "$SCRIPT_DIR/run.sh"

# Create application menu entry (.desktop)
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$DESKTOP_DIR"

DESKTOP_FILE="$DESKTOP_DIR/grid-map-editor.desktop"

echo "Creating application menu entry at $DESKTOP_FILE..."

cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Grid Map Editor
Comment=Interactive Occupancy Grid Map Editor
Exec=$SCRIPT_DIR/run.sh
Path=$SCRIPT_DIR
Icon=$ICON_PATH
Terminal=false
Categories=Utility;Development;
StartupWMClass=grid_map_editor
EOF

chmod +x "$DESKTOP_FILE"

# Update desktop database if available
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo "=========================================="
echo "Grid Map Editor installed successfully!"
echo "Virtual environment: $VENV_PATH"
echo "Desktop entry: $DESKTOP_FILE"
echo "Icon: $ICON_PATH"
echo "You can launch the app from App Menu or run:"
echo "  $SCRIPT_DIR/run.sh"
echo "=========================================="
