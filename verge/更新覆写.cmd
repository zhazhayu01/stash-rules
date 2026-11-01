@echo off
setlocal
where pwsh.exe >nul 2>nul
if errorlevel 1 (
  powershell.exe -NoProfile -File "%~dp0Sync-Verge.ps1"
) else (
  pwsh.exe -NoProfile -File "%~dp0Sync-Verge.ps1"
)
set "sync_result=%errorlevel%"
pause
exit /b %sync_result%
