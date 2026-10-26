# ==========================================
# Auditar Headroom
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @()

$Checks += Test-Path "$Base\03_Conocimiento\23_Integraciones_Activas\Headroom\INSTALACION_REAL.md"
$Checks += Test-Path "$Base\03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_PRUEBAS.md"
$Checks += Test-Path "$Base\03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_ROLLBACK.md"

$Checks += [bool](Get-Command git -ErrorAction SilentlyContinue)
$Checks += Test-Path "$Base\11_Herramientas\Node JS\node-v24.22.1-win-x64\node.exe"
$Checks += Test-Path "$Base\11_Herramientas\Node JS\node-v24.22.1-win-x64\npm.cmd"

$OK = ($Checks | Where-Object {$_}).Count
$Total = $Checks.Count

$Porcentaje = [math]::Round(($OK / $Total)*100)

$Estado = if($Porcentaje -eq 100){
    "LISTO"
}
elseif($Porcentaje -ge 75){
    "PARCIAL"
}
else{
    "NO LISTO"
}

Write-Host ""
Write-Host "Preparacion Headroom: $Porcentaje%"
Write-Host "Estado: $Estado"
Write-Host ""

@"
# HEADROOM READY

Preparacion:

$Porcentaje%

Estado:

$Estado
"@ | Set-Content `
"$Base\03_Conocimiento\23_Integraciones_Activas\Headroom\HEADROOM_READY.md"