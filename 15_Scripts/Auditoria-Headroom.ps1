# ==========================================
# Auditoria Headroom
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=========================="
Write-Host " Auditoria Headroom"
Write-Host "=========================="
Write-Host ""

$NodeModules =
Test-Path "$Base\node_modules\headroom-ai"

$PackageJson =
Test-Path "$Base\node_modules\headroom-ai\package.json"

$BinFolder =
Test-Path "$Base\node_modules\.bin"

Write-Host ""

Write-Host ("Headroom instalado : " + $NodeModules)

Write-Host ("Package.json      : " + $PackageJson)

Write-Host ("Bin disponible    : " + $BinFolder)

Write-Host ""

if($NodeModules -and $PackageJson)
{
    Write-Host "ESTADO: INSTALADO" -ForegroundColor Green
}
else
{
    Write-Host "ESTADO: NO INSTALADO" -ForegroundColor Red
}

Write-Host ""