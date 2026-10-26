# ==========================================
# Snapshot Ecosistema
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Destino = Join-Path `
$Base `
("10_Respaldos\Snapshot_Ecosistema_" +
(Get-Date -Format "yyyyMMdd_HHmmss"))

New-Item `
-ItemType Directory `
-Path $Destino `
-Force | Out-Null

Copy-Item `
"$Base\03_Conocimiento" `
$Destino `
-Recurse `
-Force

Copy-Item `
"$Base\00_Admin" `
$Destino `
-Recurse `
-Force

Write-Host ""
Write-Host "Snapshot generado." `
-ForegroundColor Green

Write-Host $Destino `
-ForegroundColor Yellow

Write-Host ""