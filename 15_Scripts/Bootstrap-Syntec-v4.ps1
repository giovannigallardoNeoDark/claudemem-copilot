# ==========================================
# Bootstrap Syntec v4
# ==========================================

Clear-Host

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "     Bootstrap Syntec v4" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$Base = Split-Path $PSScriptRoot -Parent

# ==========================================
# FUNCIONES
# ==========================================

function New-SyntecFile {
    param(
        [string]$File,
        [string]$Content
    )

    $Path = Join-Path $Base $File

    if (!(Test-Path $Path))
    {
        $Content | Set-Content $Path -Encoding UTF8
        Write-Host "[ARCHIVO] $File" -ForegroundColor Green
    }
}

function New-SyntecFolderFiles {
    param(
        [string]$Folder
    )

    $FullFolder = Join-Path $Base $Folder

    if (Test-Path $FullFolder)
    {
        $ReadMe = Join-Path $FullFolder "README.md"

        if (!(Test-Path $ReadMe))
        {
@"
# $Folder

Documentacion del modulo.

## Objetivo

Pendiente completar.

"@ | Set-Content $ReadMe -Encoding UTF8
        }

        $GitKeep = Join-Path $FullFolder ".gitkeep"

        if (!(Test-Path $GitKeep))
        {
            New-Item `
                -ItemType File `
                -Path $GitKeep `
                -Force | Out-Null
        }
    }
}

# ==========================================
# README EN TODAS LAS CARPETAS
# ==========================================

Get-ChildItem $Base -Directory -Recurse |
ForEach-Object {
    $Relative = $_.FullName.Replace($Base + "\", "")
    New-SyntecFolderFiles $Relative
}

# ==========================================
# ARCHITECTURA GENERAL
# ==========================================

New-SyntecFile `
"00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md" `
@"

# Arquitectura General

## Objetivo

Copilot Empresarial de:

- Ingeniería
- Desarrollo
- Investigación
- Gestión del Conocimiento

## Plataformas

- GitHub Copilot
- Git
- Python
- NodeJS

## Sistemas Principales

- FIOS
- NeoDark

## Seguridad

- Semgrep
- CodeQL
- SonarQube

## Futuro

- SharePoint
- Qdrant
- Automatización
- Memoria Persistente

"@

# ==========================================
# ROADMAP
# ==========================================

New-SyntecFile `
"00_Admin\Roadmap\ROADMAP_GENERAL.md" `
@"

# Roadmap General

## Fase 1
[X] Estructura

## Fase 2
[ ] GitHub

## Fase 3
[ ] Base de Conocimiento

## Fase 4
[ ] Seguridad

## Fase 5
[ ] Informes

## Fase 6
[ ] Automatización

## Fase 7
[ ] IA Avanzada

"@

# ==========================================
# INVENTARIO
# ==========================================

New-SyntecFile `
"00_Admin\Inventario\INVENTARIO_HERRAMIENTAS.md" `
@"

# Inventario

## Instaladas

- VS Code
- Git
- GitHub Copilot
- NodeJS
- Python
- Semgrep

## Pendientes

- CodeQL
- SharePoint
- Qdrant

"@

# ==========================================
# CHANGELOG
# ==========================================

New-SyntecFile `
"00_Admin\CHANGELOG.md" `
@"

# Changelog

## 2026-10-21

- Bootstrap v1
- Bootstrap v2
- Bootstrap v3
- Bootstrap v4

"@

# ==========================================
# PLANTILLAS DE CONOCIMIENTO
# ==========================================

New-SyntecFile `
"03_Conocimiento\Lecciones_Aprendidas\PLANTILLA_LECCION_APRENDIDA.md" `
@"

# Lección Aprendida

## Fecha

## Proyecto

## Problema

## Solución

## Resultado

## Recomendaciones

"@

New-SyntecFile `
"03_Conocimiento\Problemas_Resueltos\PLANTILLA_PROBLEMA_RESUELTO.md" `
@"

# Problema Resuelto

## Situación

## Causa

## Solución

## Resultado

## Referencias

"@

New-SyntecFile `
"03_Conocimiento\Decisiones_Tecnicas\PLANTILLA_DECISION_TECNICA.md" `
@"

# Decisión Técnica

## Contexto

## Alternativas

## Decisión

## Justificación

## Riesgos

"@

# ==========================================
# PLANTILLAS DE INFORMES
# ==========================================

New-SyntecFile `
"05_Plantillas\Ingenieria\Informe_Estructural.md" `
"# Informe Estructural"

New-SyntecFile `
"05_Plantillas\Ingenieria\Memoria_Calculo.md" `
"# Memoria de Calculo"

New-SyntecFile `
"05_Plantillas\Programacion\Code_Review.md" `
"# Code Review"

New-SyntecFile `
"05_Plantillas\Seguridad\Security_Review.md" `
"# Security Review"

New-SyntecFile `
"05_Plantillas\Seguridad\RCA.md" `
"# RCA"

# ==========================================
# FIOS
# ==========================================

New-SyntecFile `
"01_FIOS\ROADMAP.md" `
"# Roadmap FIOS"

New-SyntecFile `
"01_FIOS\CHANGELOG.md" `
"# Changelog FIOS"

# ==========================================
# NEODARK
# ==========================================

New-SyntecFile `
"02_NeoDark\ROADMAP.md" `
"# Roadmap NeoDark"

New-SyntecFile `
"02_NeoDark\CHANGELOG.md" `
"# Changelog NeoDark"

Write-Host ""
Write-Host "Bootstrap Syntec v4 completado correctamente." `
-ForegroundColor Cyan

Write-Host ""