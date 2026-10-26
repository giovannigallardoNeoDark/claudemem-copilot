# ==========================================
# Auditoria Mejora Continua
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Hallazgos =
Join-Path `
$Base `
"03_Conocimiento\24_Base_Conocimiento_Viva\HALLAZGOS.md"

$Mejoras =
Join-Path `
$Base `
"03_Conocimiento\24_Base_Conocimiento_Viva\MEJORAS_PROPUESTAS.md"

$CountHallazgos = 0
$CountMejoras = 0

if(Test-Path $Hallazgos)
{
    $CountHallazgos =
    (Get-Content $Hallazgos |
     Select-String "HALLAZGO").Count
}

if(Test-Path $Mejoras)
{
    $CountMejoras =
    (Get-Content $Mejoras |
     Select-String "MEJORA").Count
}

Write-Host ""
Write-Host "Hallazgos: $CountHallazgos"
Write-Host "Mejoras : $CountMejoras"
Write-Host ""