@echo off
rem Windows equivalent of install.sh: install Grid Map Editor from the source tree.
rem Creates .venv, installs the package and adds Start menu + desktop shortcuts.
rem (For PCs without Python, use the GridMapEditor-Setup installer from GitHub Releases.)
setlocal EnableExtensions
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "ICON_PATH=%SCRIPT_DIR%src\grid_map_editor\resources\images\app_icon.ico"
set "VENV_PATH=%SCRIPT_DIR%.venv"

rem --- Find Python 3.10+ (the py launcher first; "python" may be the Microsoft Store stub) ---
rem Checked by the printed answer, not the exit code: the Store stub and missing commands
rem can't print "OK".
set "PY="
for /f %%v in ('py -3 -c "import sys; print('OK' if sys.version_info >= (3, 10) else 'OLD')" 2^>nul') do (
    if "%%v"=="OK" set "PY=py -3"
)
if not defined PY (
    for /f %%v in ('python -c "import sys; print('OK' if sys.version_info >= (3, 10) else 'OLD')" 2^>nul') do (
        if "%%v"=="OK" set "PY=python"
    )
)
if not defined PY (
    echo Python 3.10 or newer was not found.
    where winget >nul 2>nul
    if errorlevel 1 (
        echo Install Python from https://www.python.org/downloads/ ^(check "Add python.exe to PATH"^),
        echo then run install.bat again.
        goto :fail
    )
    echo Installing Python 3.12 with winget...
    winget install -e --id Python.Python.3.12 --scope user
    if errorlevel 1 (
        echo Install Python from https://www.python.org/downloads/ ^(check "Add python.exe to PATH"^),
        echo then run install.bat again.
        goto :fail
    )
    echo.
    echo Python installed. Close this window and run install.bat again.
    pause
    exit /b 0
)
echo Using Python: %PY%

rem --- Virtual environment ---
if exist "%VENV_PATH%\Scripts\python.exe" (
    echo Existing virtual environment found at %VENV_PATH%
) else (
    echo Creating virtual environment at %VENV_PATH%...
    %PY% -m venv "%VENV_PATH%"
    if errorlevel 1 goto :fail
)

echo Upgrading pip in virtual environment...
"%VENV_PATH%\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 goto :fail

echo Installing Grid Map Editor package...
"%VENV_PATH%\Scripts\python.exe" -m pip install -e "%SCRIPT_DIR%."
if errorlevel 1 goto :fail

rem --- Shortcuts (pythonw: no console window; -X utf8 as in run.bat) ---
echo Creating Start menu and desktop shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$shell = New-Object -ComObject WScript.Shell;" ^
    "foreach ($dir in @([Environment]::GetFolderPath('Programs'), [Environment]::GetFolderPath('Desktop'))) {" ^
    "  $lnk = $shell.CreateShortcut((Join-Path $dir 'Grid Map Editor (source).lnk'));" ^
    "  $lnk.TargetPath = '%VENV_PATH%\Scripts\pythonw.exe';" ^
    "  $lnk.Arguments = '-X utf8 -m grid_map_editor';" ^
    "  $lnk.WorkingDirectory = '%SCRIPT_DIR%';" ^
    "  $lnk.IconLocation = '%ICON_PATH%';" ^
    "  $lnk.Description = 'Interactive Occupancy Grid Map Editor';" ^
    "  $lnk.Save() }"
if errorlevel 1 echo Warning: could not create shortcuts.

echo ==========================================
echo Grid Map Editor installed successfully!
echo Virtual environment: %VENV_PATH%
echo Shortcut: "Grid Map Editor (source)" in Start menu and on the desktop
echo You can also run:  %SCRIPT_DIR%run.bat
echo ==========================================
pause
exit /b 0

:fail
echo.
echo Installation FAILED.
pause
exit /b 1
