@echo off
rem Double-click to build dist-installer\GridMapEditor-Setup-<version>.exe (see build.ps1)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build.ps1" %*
if errorlevel 1 (
    echo.
    echo Build FAILED.
) else (
    echo.
    echo Build finished.
)
pause
