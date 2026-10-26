# ==========================================
# Respaldo ClaudeMem
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Fecha = Get-Date -Format "yyyyMMdd_HHmmss"

$Destino =
Join-Path `
$Base `
"10_Respaldos\ClaudeMem_$Fecha"

New-Item `
-ItemType Directory `
-Path $Destino `
-Force | Out-Null

Copy-Item `
"$Base\03_Conocimiento" `
$Destino `
-Recurse `
-Force

Write-Host ""
Write-Host "Respaldo completado."
Write-Host $Destino -ForegroundColor Green
Write-Host ""