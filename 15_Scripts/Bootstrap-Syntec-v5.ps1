# ===========================================
# Bootstrap Syntec v5
# Gobierno + GitHub + Knowledge Base
# ===========================================

Clear-Host

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "       Bootstrap Syntec v5" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$Base = Split-Path $PSScriptRoot -Parent

# ------------------------------------------------
# FUNCION CREAR ARCHIVO
# ------------------------------------------------

function New-SyntecFile {
    param(
        [string]$File,
        [string]$Content
    )

    $FilePath = Join-Path $Base $File
    $Folder = Split-Path $FilePath -Parent

    if (!(Test-Path $Folder))
    {
        New-Item -ItemType Directory `
                 -Path $Folder `
                 -Force | Out-Null
    }

    if (!(Test-Path $FilePath))
    {
        $Content | Set-Content `
            $FilePath `
            -Encoding UTF8

        Write-Host "[ARCHIVO] $File" `
            -ForegroundColor Green
    }
}

# ------------------------------------------------
# WIKI
# ------------------------------------------------

New-SyntecFile `
"00_Admin\Wiki\HOME.md" `
@"
# Wiki Syntec

## Sistemas

- FIOS
- NeoDark

## Biblioteca

- Normativas
- Procedimientos
- Informes

"@

# ------------------------------------------------
# DASHBOARD
# ------------------------------------------------

New-SyntecFile `
"00_Admin\Dashboards\ESTADO_GENERAL.md" `
@"
# Estado General

| Proyecto | Estado |
|-----------|-----------|
| FIOS | Planificación |
| NeoDark | Desarrollo |
| Base Conocimiento | Construcción |

"@

# ------------------------------------------------
# GOBIERNO
# ------------------------------------------------

New-SyntecFile `
"00_Admin\Gobierno\REGLAS_REPOSITORIO.md" `
@"
# Reglas

## Commits

Formato:

TIPO: descripción

Ejemplo:

FEAT: nuevo módulo
FIX: corrección cálculo

"@

# ------------------------------------------------
# GITIGNORE FIOS
# ------------------------------------------------

New-SyntecFile `
"01_FIOS\.gitignore" `
@"
__pycache__/
*.pyc
.env
.vscode/
dist/
build/
"@

# ------------------------------------------------
# GITIGNORE NEODARK
# ------------------------------------------------

New-SyntecFile `
"02_NeoDark\.gitignore" `
@"
__pycache__/
*.pyc
.env
.vscode/
dist/
build/
"@

# ------------------------------------------------
# ISSUE TEMPLATE
# ------------------------------------------------

New-SyntecFile `
".github\ISSUE_TEMPLATE\BUG_REPORT.md" `
@"
---
name: Bug report
about: Reportar error
---

## Descripción

## Pasos para reproducir

## Resultado esperado

## Resultado obtenido

"@

# ------------------------------------------------
# FEATURE TEMPLATE
# ------------------------------------------------

New-SyntecFile `
".github\ISSUE_TEMPLATE\FEATURE_REQUEST.md" `
@"
---
name: Feature Request
about: Solicitud de mejora
---

## Objetivo

## Beneficio

## Prioridad

"@

# ------------------------------------------------
# PULL REQUEST TEMPLATE
# ------------------------------------------------

New-SyntecFile `
".github\PULL_REQUEST_TEMPLATE.md" `
@"
# Pull Request

## Descripción

## Cambios realizados

## Riesgos

## Verificación

- [ ] Probado
- [ ] Documentado
- [ ] Revisado

"@

# ------------------------------------------------
# KNOWLEDGE BASE
# ------------------------------------------------

New-SyntecFile `
"03_Conocimiento\FAQ\README.md" `
@"
# FAQ

Preguntas frecuentes.

"@

New-SyntecFile `
"03_Conocimiento\REFERENCIAS.md" `
@"
# Referencias

Listado maestro de fuentes técnicas.

"@

# ------------------------------------------------
# CHANGELOG GENERAL
# ------------------------------------------------

New-SyntecFile `
"00_Admin\CHANGELOG_GENERAL.md" `
@"
# Changelog General

## v5

- Integración GitHub
- Wiki local
- Templates
- Dashboard
- Gobierno

"@

Write-Host ""
Write-Host "Bootstrap Syntec v5 completado correctamente." `
-ForegroundColor Cyan
Write-Host ""