# ==========================================
# Bootstrap Integraciones Activas
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Bootstrap Integraciones Activas"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function New-KBFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath
    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder)) {
        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    if (!(Test-Path $FullPath)) {

        $Content | Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
    else {

        Write-Host "[EXISTE] $RelativePath" `
            -ForegroundColor Yellow
    }
}

# ==========================================
# 23 INTEGRACIONES ACTIVAS
# ==========================================

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\README.md" `
@"
# Integraciones Activas

Control de estado de las integraciones
del Copilot Empresarial.
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\CLAUDEMEM.md" `
@"
# Claude-Mem

Estado:
No Implementado

Preparacion:
Completa

Prioridad:
Alta

Objetivo:
Memoria persistente.
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\HEADROOM.md" `
@"
# Headroom

Estado:
No Implementado

Preparacion:
Completa

Objetivo:
Optimizar contexto.
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\OMNIROUTE.md" `
@"
# OmniRoute

Estado:
No Implementado

Preparacion:
Completa

Objetivo:
Gateway multi-modelo.
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\TASKOBSERVER.md" `
@"
# Task Observer

Estado:
No Implementado

Preparacion:
Completa

Objetivo:
Aprendizaje y mejora continua.
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\GITHUB.md" `
@"
# GitHub

Estado:
Preparado

Capacidades:

- Repositorios
- Wiki
- Issues
- Projects
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\SHAREPOINT.md" `
@"
# SharePoint

Estado:
Preparado

Capacidades:

- Informes
- Procedimientos
- Normativas
- Documentacion
"@

New-KBFile `
"03_Conocimiento\23_Integraciones_Activas\ESTADO_INTEGRACIONES.md" `
@"
# Estado Integraciones

| Integracion | Estado |
|-------------|---------|
| Claude-Mem | Preparado |
| Headroom | Preparado |
| OmniRoute | Preparado |
| Task Observer | Preparado |
| GitHub | Preparado |
| SharePoint | Preparado |
"@

# ==========================================
# 24 BASE CONOCIMIENTO VIVA
# ==========================================

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\README.md" `
@"
# Base de Conocimiento Viva

Repositorio de conocimiento generado
por la operacion real del ecosistema.
"@

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\INDEX.md" `
@"
# Indice

- Hallazgos
- Patrones
- Recomendaciones
- Mejoras
"@

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\HALLAZGOS.md" `
@"
# Hallazgos

Registrar descubrimientos relevantes
obtenidos de investigaciones,
auditorias e implementaciones.
"@

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\PATRONES.md" `
@"
# Patrones

Registrar patrones repetitivos
detectados por agentes,
auditorias o experiencia operacional.
"@

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\RECOMENDACIONES.md" `
@"
# Recomendaciones

Mejoras sugeridas para el ecosistema.
"@

New-KBFile `
"03_Conocimiento\24_Base_Conocimiento_Viva\MEJORAS_PROPUESTAS.md" `
@"
# Mejoras Propuestas

| Fecha | Mejora | Estado |
|--------|---------|---------|
"@

Write-Host ""
Write-Host "Bootstrap Integraciones Activas completado." `
-ForegroundColor Cyan
Write-Host ""