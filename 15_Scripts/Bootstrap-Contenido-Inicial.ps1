# ==========================================
# Bootstrap Contenido Inicial Syntec
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Bootstrap Contenido Inicial Syntec"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

function New-SyntecDoc
{
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath

    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder))
    {
        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    if (!(Test-Path $FullPath))
    {
        $Content |
        Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
    else
    {
        Write-Host "[EXISTE] $RelativePath" `
            -ForegroundColor Yellow
    }
}

# ==================================================
# KPI
# ==================================================

New-SyntecDoc `
"00_Admin\Dashboards\KPIS.md" `
@"
# KPI Ecosistema Syntec

## Infraestructura

- VS Code ✅
- Git ✅
- GitHub Copilot ✅
- Python ✅
- NodeJS ✅
- Semgrep ✅

## Arquitectura

- Carpetas ........ 100%
- Subcarpetas ..... 100%
- README .......... 100%

## Proyectos

- FIOS ............ 20%
- NeoDark ......... 15%

## Seguridad

- Semgrep ......... 100%
- CodeQL .......... 0%
- SonarQube ....... 0%

## Conocimiento

- Lecciones ....... 5%
- Problemas ....... 0%
- Decisiones ...... 5%

## Madurez Global

60%
"@

# ==================================================
# FIOS
# ==================================================

New-SyntecDoc `
"01_FIOS\DOCUMENTACION\ARQUITECTURA.md" `
@"
# Arquitectura FIOS

## Objetivo

FIOS será una plataforma de ingeniería para:

- Cálculos estructurales
- Cálculos mecánicos
- Informes automáticos
- Gestión de proyectos
- Historial de análisis

## Componentes

- Biblioteca de materiales
- Biblioteca de perfiles
- Motor de cálculo
- Motor de informes
- Historial
- Validación
"@

New-SyntecDoc `
"01_FIOS\DOCUMENTACION\REQUISITOS.md" `
@"
# Requisitos FIOS

## Funcionales

- Crear proyectos
- Guardar proyectos
- Abrir proyectos
- Realizar cálculos
- Generar informes

## No Funcionales

- Español
- Trazabilidad
- Historial
- Verificabilidad
"@

New-SyntecDoc `
"01_FIOS\DOCUMENTACION\MODULOS.md" `
@"
# Módulos FIOS

## Biblioteca de Materiales

Estado: Planificado

## Biblioteca de Perfiles

Estado: Planificado

## Cálculos Estructurales

Estado: Planificado

## Cálculos Mecánicos

Estado: Planificado

## Izaje

Estado: Planificado

## Informes

Estado: Planificado

## Historial

Estado: Planificado
"@

New-SyntecDoc `
"01_FIOS\DOCUMENTACION\BACKLOG.md" `
@"
# Backlog FIOS

## Alta Prioridad

- Biblioteca materiales
- Biblioteca perfiles
- Informes

## Media Prioridad

- Historial
- Dashboard

## Baja Prioridad

- Integraciones externas
"@

# ==================================================
# NEODARK
# ==================================================

New-SyntecDoc `
"02_NeoDark\DOCUMENTACION\ARQUITECTURA.md" `
@"
# Arquitectura NeoDark

## Objetivo

Automatizar análisis,
históricos y construcción
de datasets.

## Componentes

- Dataset Builder
- Historial
- Automatización
- Validaciones
- Reportes
"@

New-SyntecDoc `
"02_NeoDark\DOCUMENTACION\REQUISITOS.md" `
@"
# Requisitos NeoDark

## Funcionales

- Crear datasets
- Actualizar datasets
- Validar información
- Generar reportes

## No Funcionales

- Escalabilidad
- Auditoría
- Trazabilidad
"@

New-SyntecDoc `
"02_NeoDark\DOCUMENTACION\DATASET_BUILDER.md" `
@"
# Dataset Builder

## Objetivo

Construir datasets enriquecidos a partir de:

- Historiales
- Informes
- Bases de datos
- Documentación

## Capacidades

- Normalización
- Validación
- Consolidación
- Eliminación de duplicados
"@

New-SyntecDoc `
"02_NeoDark\DOCUMENTACION\BACKLOG.md" `
@"
# Backlog NeoDark

## Pendiente

- Historial enriquecido
- Dataset Builder
- Validación

## Futuro

- Dashboard
- IA asistida
"@

# ==================================================
# CONOCIMIENTO
# ==================================================

New-SyntecDoc `
"03_Conocimiento\Lecciones_Aprendidas\LA-0001-NODE-PORTABLE.md" `
@"
# LA-0001

## Problema

No existían permisos administrativos.

## Solución

Uso de NodeJS Portable.

## Resultado

Node, npm y npx operativos.

## Reutilización

Utilizable en futuros entornos corporativos.
"@

New-SyntecDoc `
"03_Conocimiento\Decisiones_Tecnicas\DT-0001-ESTRUCTURA-SYNTEC.md" `
@"
# DT-0001

## Decisión

Centralizar el ecosistema completo
en la carpeta Copilot.

## Justificación

- Auditoría
- Respaldos
- Automatización
- Gestión documental

## Estado

Aprobada

## Fecha

2026-10-21
"@

# ==================================================

Write-Host ""
Write-Host "Contenido inicial generado correctamente." `
-ForegroundColor Cyan

Write-Host ""