#!/bin/bash
# Set PYTHONPATH to include the src folder so we can import grid_map_editor
export PYTHONPATH=src

# Run the grid_map_editor package as a module, passing along any arguments
python3 -m grid_map_editor "$@"
