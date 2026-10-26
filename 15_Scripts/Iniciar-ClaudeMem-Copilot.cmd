@echo off
set "SCRIPT=%~dp0\15_Scripts\ClaudeMem-Copilot-Launcher.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%~dp0ClaudeMem-Copilot-Launcher.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
