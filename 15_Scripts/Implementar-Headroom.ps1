# ==========================================
# Implementar Headroom
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Node =
"$Base\11_Herramientas\Node JS\node-v24.22.1-win-x64\npm.cmd"

Write-Host ""
Write-Host "Headroom - Instalacion"
Write-Host ""

& $Node view headroom-ai version

Write-Host ""
Write-Host "Si la version aparece correctamente,"
Write-Host "Headroom esta disponible en npm."
Write-Host ""

Write-Host "Comando sugerido:"
Write-Host ""

Write-Host 'npm install headroom-ai' `
-ForegroundColor Yellow
