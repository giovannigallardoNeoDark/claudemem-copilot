Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-Doc {
    param(
        [string]$Ruta,
        [string]$Contenido
    )

    $Full = Join-Path $Base $Ruta

    $Dir = Split-Path $Full -Parent

    if(!(Test-Path $Dir))
    {
        New-Item `
            -ItemType Directory `
            -Path $Dir `
            -Force | Out-Null
    }

    $Contenido |
    Set-Content `
        $Full `
        -Encoding UTF8

    Write-Host "[OK] $Ruta"
}

New-Doc `
"03_Conocimiento\21_Evaluacion\CRITERIOS_APROBACION_FINAL.md" `
"# Criterios de Aprobacion Final"

New-Doc `
"03_Conocimiento\22_Operacion\PLAN_TRANSICION_OPERACIONES.md" `
"# Plan Transicion Operaciones"

New-Doc `
"03_Conocimiento\25_Gestion_Evolucion\CICLO_MEJORA_CONTINUA.md" `
"# Ciclo Mejora Continua"

Write-Host ""
Write-Host "CIERRE OPERACIONAL COMPLETADO"
Write-Host ""