@echo off
echo Removing Equus wallpaper task...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall-Task.ps1"
echo.
pause
