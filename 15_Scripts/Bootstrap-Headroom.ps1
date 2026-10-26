# ==========================================
# Bootstrap Headroom
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-HFile {

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
        $Content | Set-Content $FullPath -Encoding UTF8
        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

New-HFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\README.md" `
"# Headroom"

New-HFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\INSTALACION_REAL.md" `
"# Instalacion Real Headroom"

New-HFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_PRUEBAS.md" `
"# Plan Pruebas Headroom"

New-HFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\RESULTADOS_PRUEBAS.md" `
"# Resultados Headroom"

New-HFile `
"03_Conocimiento\23_Integraciones_Activas\Headroom\PLAN_ROLLBACK.md" `
"# Rollback Headroom"

Write-Host ""
Write-Host "Bootstrap Headroom completado."
