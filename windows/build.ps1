# Builds the Windows installer for Grid Map Editor.
#
# Requirements (build machine only, NOT the target PC):
#   - Python 3.10-3.13 (on PATH)
#   - Inno Setup 6.3+  (https://jrsoftware.org/isdl.php)
#
# Usage:  powershell -ExecutionPolicy Bypass -File windows\build.ps1 [-Version 0.1.0]
#         (default version: __version__ in src\grid_map_editor\__init__.py)
# Output: dist-installer\GridMapEditor-Setup-<version>.exe

param(
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

$WindowsDir = $PSScriptRoot
$Root = Split-Path -Parent $WindowsDir          # repository root
$Build = Join-Path $Root "build"
$Venv = Join-Path $Build "venv"

if (-not $Version) {
    $Init = Get-Content (Join-Path $Root "src\grid_map_editor\__init__.py") -Raw
    if ($Init -notmatch '__version__\s*=\s*"([^"]+)"') { throw "__version__ not found in __init__.py" }
    $Version = $Matches[1]
}

function Invoke-Step([string]$Title, [scriptblock]$Command) {
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
    & $Command
    if ($LASTEXITCODE -ne 0) { throw "$Title failed (exit code $LASTEXITCODE)" }
}

# Locate Inno Setup compiler
$Iscc = (Get-Command iscc.exe -ErrorAction SilentlyContinue).Source
if (-not $Iscc) {
    foreach ($Base in @(${env:ProgramFiles(x86)}, $env:ProgramFiles, "$env:LOCALAPPDATA\Programs")) {
        $Candidate = Join-Path $Base "Inno Setup 6\ISCC.exe"
        if ($Base -and (Test-Path $Candidate)) { $Iscc = $Candidate; break }
    }
}
if (-not $Iscc) { throw "Inno Setup 6 not found. Install it from https://jrsoftware.org/isdl.php" }

Invoke-Step "1/3 Preparing Python build environment" {
    if (-not (Test-Path (Join-Path $Venv "Scripts\python.exe"))) { python -m venv $Venv }
    if ($LASTEXITCODE -eq 0) {
        & "$Venv\Scripts\python.exe" -m pip install --upgrade pip
        & "$Venv\Scripts\python.exe" -m pip install -r (Join-Path $WindowsDir "requirements-windows.txt")
    }
}

Invoke-Step "2/3 Bundling GridMapEditor.exe (PyInstaller)" {
    & "$Venv\Scripts\python.exe" -m PyInstaller (Join-Path $Root "OccupancyGridMapEditor.spec") `
        --noconfirm --clean `
        --distpath (Join-Path $Build "pyinstaller\dist") `
        --workpath (Join-Path $Build "pyinstaller\work")
}

Invoke-Step "3/3 Creating installer (Inno Setup)" {
    & $Iscc "/DMyAppVersion=$Version" (Join-Path $WindowsDir "installer.iss")
}

Write-Host ""
Write-Host "Done: $(Join-Path $Root "dist-installer\GridMapEditor-Setup-$Version.exe")" -ForegroundColor Green
