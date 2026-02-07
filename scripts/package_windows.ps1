param(
    [switch]$SkipInstall,
    [string]$Version,
    [string]$PortableOutput
)

$ErrorActionPreference = "Stop"

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command not found: $Name"
    }
}

Write-Host "[1/6] Checking prerequisites..."
Assert-Command "npm"
Assert-Command "cargo"

if (-not (Test-Path "package.json")) {
    throw "package.json not found. Run this script from repository root."
}

$pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
$resolvedVersion = if ($Version) {
    $Version.Trim()
} elseif ($env:RELEASE_VERSION) {
    $env:RELEASE_VERSION.Trim()
} else {
    [string]$pkg.version
}
if (-not $resolvedVersion) {
    throw "Unable to resolve version. Provide -Version or set RELEASE_VERSION."
}

$releaseNamedDir = "src-tauri/target/release/bundle/release-named"
if (-not $PortableOutput) {
    $PortableOutput = Join-Path $releaseNamedDir "Antigravity-Manager-$resolvedVersion-windows-x64-portable.zip"
}
$canonicalExeOutput = Join-Path $releaseNamedDir "Antigravity-Manager-$resolvedVersion-windows-x64.exe"

Write-Host "[2/6] Building frontend + Tauri app..."
if (-not $SkipInstall) {
    npm ci
}
npm run tauri build

Write-Host "[3/6] Locating Windows executable..."
$exe = Get-ChildItem -Path "src-tauri/target" -Filter "antigravity_tools.exe" -Recurse |
    Where-Object { $_.FullName -match "\\release\\" } |
    Select-Object -First 1
if (-not $exe) {
    throw "antigravity_tools.exe not found under src-tauri/target/**/release"
}

Write-Host "[4/6] Locating NSIS installer..."
$nsisInstaller = Get-ChildItem -Path "src-tauri/target" -Filter "*.exe" -Recurse |
    Where-Object { $_.FullName -match "\\bundle\\nsis\\" } |
    Sort-Object Length -Descending |
    Select-Object -First 1
if (-not $nsisInstaller) {
    throw "NSIS installer not found under src-tauri/target/**/bundle/nsis"
}
if (-not (Test-Path $releaseNamedDir)) {
    New-Item -ItemType Directory -Path $releaseNamedDir -Force | Out-Null
}
Copy-Item -Path $nsisInstaller.FullName -Destination $canonicalExeOutput -Force

Write-Host "[5/6] Creating portable zip..."
$portableDir = Split-Path -Parent $PortableOutput
if (-not (Test-Path $portableDir)) {
    New-Item -ItemType Directory -Path $portableDir -Force | Out-Null
}
if (Test-Path $PortableOutput) {
    Remove-Item $PortableOutput -Force
}

$zipInputs = @($exe.FullName)
if (Test-Path "README_EN.md") { $zipInputs += "README_EN.md" }
if (Test-Path "LICENSE") { $zipInputs += "LICENSE" }
Compress-Archive -Path $zipInputs -DestinationPath $PortableOutput -Force

Write-Host "[6/6] Build outputs"
Get-ChildItem -Path "src-tauri/target" -Recurse -Include *.msi,*.exe,*.zip |
    Where-Object { $_.FullName -match "\\bundle\\" } |
    Select-Object FullName

Write-Host ""
Write-Host "Done."
Write-Host "Canonical installer: $canonicalExeOutput"
Write-Host "Portable package: $PortableOutput"
