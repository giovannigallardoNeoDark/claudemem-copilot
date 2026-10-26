# ==========================================
# Estado Claude-Mem
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivos = @(
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\INSTALACION_REAL.md",
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_PRUEBAS.md",
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\RESULTADOS_PRUEBAS.md",
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_ROLLBACK.md"
)

Write-Host ""
Write-Host "=========================" -ForegroundColor Cyan
Write-Host " Estado Claude-Mem"
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

foreach($A in $Archivos)
{
    $Ruta = Join-Path $Base $A

    if(Test-Path $Ruta)
    {
        Write-Host "[OK] $A" -ForegroundColor Green
    }
    else
    {
        Write-Host "[FALTA] $A" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Claude-Mem listo para implementacion." `
-ForegroundColor Cyan
Write-Host ""