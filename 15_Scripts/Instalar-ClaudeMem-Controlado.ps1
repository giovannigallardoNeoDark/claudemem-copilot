# ==========================================
# Instalar Claude-Mem Controlado
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$NodePath = Join-Path `
$Base `
"11_Herramientas\Node JS\node-v24.22.1-win-x64"

$ClaudeMemPath = Join-Path `
$Base `
"11_Herramientas\ClaudeMem"

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " Instalacion Claude-Mem"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

if (!(Test-Path $ClaudeMemPath)) {

    New-Item `
    -ItemType Directory `
    -Path $ClaudeMemPath `
    -Force | Out-Null
}

Write-Host "Node detectado." -ForegroundColor Green

& "$NodePath\node.exe" --version
& "$NodePath\npm.cmd" --version

Write-Host ""
Write-Host "Directorio preparado:"
Write-Host $ClaudeMemPath -ForegroundColor Yellow

Write-Host ""
Write-Host "Listo para clonar e instalar Claude-Mem."
Write-Host ""