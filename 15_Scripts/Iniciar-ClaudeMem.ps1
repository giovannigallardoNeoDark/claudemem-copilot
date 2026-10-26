# ==========================================
# Iniciar Implementacion Claude-Mem
# ==========================================

Clear-Host

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " Inicio Implementacion Claude-Mem"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Validando entorno..."

git --version

& "..\11_Herramientas\Node JS\node-v24.22.1-win-x64\node.exe" --version

& "..\11_Herramientas\Node JS\node-v24.22.1-win-x64\npm.cmd" --version

Write-Host ""
Write-Host "Entorno validado." -ForegroundColor Green

Write-Host ""
Write-Host "Actualizar documentación:"
Write-Host ""

Write-Host "REGISTRO_IMPLEMENTACIONES.md"
Write-Host "EJECUCION_INSTALACION.md"

Write-Host ""
Write-Host "Claude-Mem listo para instalación."
Write-Host ""
