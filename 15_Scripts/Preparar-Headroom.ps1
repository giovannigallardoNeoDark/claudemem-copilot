# ==========================================
# Preparar Headroom
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-HRFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath

    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

    if (!(Test-Path $FullPath)) {

        $Content | Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
}

New-HRFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\README.md" `
"# Headroom"

New-HRFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\INSTALACION_REAL.md" `
"# Instalacion Real Headroom"

New-HRFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_PRUEBAS.md" `
@"
HEADROOM-001
Compresion Texto

HEADROOM-002
Compresion Documentacion

HEADROOM-003
Compresion Claude-Mem

HEADROOM-004
Latencia

HEADROOM-005
Consistencia
"@

New-HRFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\RESULTADOS_PRUEBAS.md" `
"# Resultados Headroom"

New-HRFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_ROLLBACK.md" `
"# Rollback Headroom"

Write-Host ""
Write-Host "Headroom preparado."