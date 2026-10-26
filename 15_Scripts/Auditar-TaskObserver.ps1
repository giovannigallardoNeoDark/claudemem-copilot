# ==========================================
# Auditar Task Observer
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @()

$Checks += Test-Path "$Base\03_Conocimiento\17_Agentes\11_Observador\AGENTE_OBSERVADOR.md"

$Checks += Test-Path "$Base\03_Conocimiento\11_Skills\SKILL_INVESTIGACION.md"

$Checks += Test-Path "$Base\03_Conocimiento\12_Procedimientos\PROCEDIMIENTO_INVESTIGACION.md"

$Checks += Test-Path "$Base\03_Conocimiento\13_Lecciones_Aprendidas"

$Checks += Test-Path "$Base\03_Conocimiento\14_Decisiones_Tecnicas"

$OK = ($Checks | Where-Object {$_}).Count

$Total = $Checks.Count

$Score = [math]::Round(($OK/$Total)*100)

if($Score -eq 100)
{
    $Estado = "LISTO"
}
elseif($Score -ge 75)
{
    $Estado = "PARCIAL"
}
else
{
    $Estado = "NO LISTO"
}

Write-Host ""
Write-Host "Preparacion: $Score%"
Write-Host "Estado: $Estado"
Write-Host ""

@"
# TASK OBSERVER READY

Preparacion:
$Score%

Estado:
$Estado
"@ | Set-Content `
"$Base\03_Conocimiento\23_Integraciones_Activas\TaskObserver\TASKOBSERVER_READY.md"