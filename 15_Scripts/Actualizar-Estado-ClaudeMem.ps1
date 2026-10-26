Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$File =
Join-Path `
$Base `
"03_Conocimiento\22_Operacion\ESTADO_COMPONENTES.md"

$Contenido = Get-Content $File

$Contenido =
$Contenido -replace `
"Claude-Mem \| .*",
"Claude-Mem | Listo para implementacion"

$Contenido |
Set-Content `
$File `
-Encoding UTF8

Write-Host ""
Write-Host "Estado actualizado."
Write-Host ""