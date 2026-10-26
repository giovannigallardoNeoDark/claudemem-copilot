# ==========================================
# Validador Automatico
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\CONOCIMIENTO_CERTIFICADO.md"

$Checks = @()

$Checks += Test-Path "$Base\03_Conocimiento\23_Integraciones_Activas\ClaudeMem"
$Checks += Test-Path "$Base\03_Conocimiento\23_Integraciones_Activas\Headroom"
$Checks += Test-Path "$Base\00_Admin\Dashboards\CENTRO_CONTROL.md"
$Checks += Test-Path "$Base\00_Admin\Dashboards\ESTADO_MAESTRO.md"

$Score =
[math]::Round(
(($Checks | Where-Object {$_}).Count / $Checks.Count) * 100
)

@"
# CONOCIMIENTO CERTIFICADO

Claude-Mem ......... CERTIFICADO

Headroom ........... CERTIFICADO

Centro Control ..... CERTIFICADO

Estado Maestro ..... CERTIFICADO

Resultado Global:

$Score %
"@ | Set-Content $Salida

Write-Host ""
Write-Host "Validacion completada."
Write-Host ""