# Windows Packaging

## Prerequisites

- Node.js 20+
- Rust toolchain (`cargo`)  
- Visual Studio Build Tools (C++ workload) for Tauri on Windows

## Build installer + portable package

From repository root:

```powershell
npm run package:windows
```

This runs:

1. `npm ci` (unless `-SkipInstall` is used)
2. `npm run tauri build`
3. creates canonical named files:
   - `src-tauri/target/release/bundle/release-named/Antigravity-Manager-<version>-windows-x64.exe`
   - `src-tauri/target/release/bundle/release-named/Antigravity-Manager-<version>-windows-x64-portable.zip`

## Expected outputs

- MSI installer: `src-tauri/target/**/release/bundle/msi/*.msi`
- NSIS installer: `src-tauri/target/**/release/bundle/nsis/*.exe`
- Canonical files: `src-tauri/target/release/bundle/release-named/*`

## Optional flags

Run script directly:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1 -SkipInstall
```

Set specific version in output filename (example `0.6.0`):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package_windows.ps1 -SkipInstall -Version 0.6.0
```
