# ==========================================
# Preparar Task Observer
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Folder = "$Base\03_Conocimiento\23_Integraciones_Activas\TaskObserver"

New-Item -ItemType Directory -Path $Folder -Force | Out-Null

@(
"README.md",
"INSTALACION_REAL.md",
"PLAN_PRUEBAS.md",
"RESULTADOS_PRUEBAS.md",
"PLAN_ROLLBACK.md",
"TASKOBSERVER_READY.md"
) | ForEach-Object {

    $File = Join-Path $Folder $_

    if(!(Test-Path $File))
    {
        New-Item -ItemType File `
            -Path $File `
            -Force | Out-Null
    }
}

Write-Host ""
Write-Host "Task Observer preparado." `
-ForegroundColor Green
Write-Host ""
