@echo off
rem Windows equivalent of run.sh: run Grid Map Editor from the source tree.
rem Extra arguments are passed to the app, e.g.  run.bat --renderer cpu
setlocal
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

if defined VIRTUAL_ENV (
    set "PYTHON_EXEC=%VIRTUAL_ENV%\Scripts\python.exe"
) else if exist "%SCRIPT_DIR%.venv\Scripts\python.exe" (
    set "PYTHON_EXEC=%SCRIPT_DIR%.venv\Scripts\python.exe"
) else (
    set "PYTHON_EXEC=python"
)

set "PYTHONPATH=%SCRIPT_DIR%src;%PYTHONPATH%"
rem -X utf8: read/write project files as UTF-8 (Persian names) regardless of Windows locale
"%PYTHON_EXEC%" -X utf8 -m grid_map_editor %*
