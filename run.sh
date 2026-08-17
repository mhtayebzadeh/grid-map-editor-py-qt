#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -n "$VIRTUAL_ENV" ]; then
    PYTHON_EXEC="$VIRTUAL_ENV/bin/python3"
elif [ -f "$SCRIPT_DIR/.venv/bin/python3" ]; then
    PYTHON_EXEC="$SCRIPT_DIR/.venv/bin/python3"
else
    PYTHON_EXEC="python3"
fi

export PYTHONPATH="$SCRIPT_DIR/src:$PYTHONPATH"
exec "$PYTHON_EXEC" -m grid_map_editor "$@"
