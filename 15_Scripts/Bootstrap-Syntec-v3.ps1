# =====================================
# Bootstrap Syntec v3
# =====================================

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Bootstrap Syntec v3" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$Base = Split-Path $PSScriptRoot -Parent

# -------------------------------------
# Archivos maestros
# -------------------------------------

$MasterFiles = @{

"00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md" = @"
# Arquitectura General

## Objetivo

Copilot Empresarial de Ingeniería,
Desarrollo, Investigación y Gestión
del Conocimiento.

## Sistemas

- FIOS
- NeoDark

"@

"00_Admin\Roadmap\ROADMAP_GENERAL.md" = @"
# Roadmap General

## Fase 1
✅ Estructura

## Fase 2
⬜ GitHub

## Fase 3
⬜ Base Conocimiento

## Fase 4
⬜ Seguridad

## Fase 5
⬜ Automatización

"@

"00_Admin\Inventario\INVENTARIO_HERRAMIENTAS.md" = @"
# Inventario

## Instaladas

- VS Code
- Git
- GitHub Copilot
- Node.js
- Python
- Semgrep

"@

"00_Admin\CHANGELOG.md" = @"
# Changelog

## Versión 1.0

- Estructura inicial creada.

"@
}

foreach ($File in $MasterFiles.Keys)
{
    $FullPath = Join-Path $Base $File

    if (!(Test-Path $FullPath))
    {
        $MasterFiles[$File] |
            Set-Content `
            $FullPath `
            -Encoding UTF8

        Write-Host "[ARCHIVO] $File" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Bootstrap Syntec v3 completado." -ForegroundColor Cyan