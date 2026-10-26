# ==========================================
# Bootstrap ClaudeMem Operacion
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-Doc {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $Path = Join-Path $Base $RelativePath
    $Folder = Split-Path $Path -Parent

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

    if (!(Test-Path $Path)) {
        $Content | Set-Content $Path -Encoding UTF8
        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\EJECUCION_INSTALACION.md" `
@"
# Ejecucion Instalacion Claude-Mem

Fecha:

## Estado Inicial

Preparacion validada al 100%.

## Requisitos

✅ Git
✅ NodeJS
✅ npm

## Objetivo

Activar memoria persistente.

## Resultado

Pendiente

## Observaciones

Pendiente
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\COMANDOS_INSTALACION.md" `
@"
# Comandos Instalacion

Registrar aqui los comandos reales utilizados.

Estado:

Pendiente
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\RESULTADOS_PRUEBAS.md" `
@"
# Resultados Pruebas

Prueba 1:

Resultado:

Prueba 2:

Resultado:

Prueba 3:

Resultado:
"@

Write-Host ""
Write-Host "Bootstrap ClaudeMem Operacion completado."
Write-Host ""