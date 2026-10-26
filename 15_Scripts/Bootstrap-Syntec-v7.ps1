# ==========================================
# Bootstrap Syntec v7
# Governance + PMO + Ingeniería
# ==========================================

Clear-Host

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "       Bootstrap Syntec v7"
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$Base = Split-Path $PSScriptRoot -Parent

function New-SyntecFile
{
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath
    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder))
    {
        New-Item -ItemType Directory `
                 -Path $Folder `
                 -Force | Out-Null
    }

    $Content | Set-Content `
        -Path $FullPath `
        -Encoding UTF8

    Write-Host "[OK] $RelativePath" `
        -ForegroundColor Green
}

# ==========================================
# GITIGNORE RAIZ
# ==========================================

New-SyntecFile `
".gitignore" `
@"
# Python
__pycache__/
*.pyc

# VS Code
.vscode/

# Entornos
.env
.venv/

# Logs
*.log

# Build
dist/
build/

# Windows
Thumbs.db
Desktop.ini

# Temporales
*.tmp
*.bak
"@

# ==========================================
# ADR
# ==========================================

New-SyntecFile `
"00_Admin\Arquitectura\ADR\ADR-0000-TEMPLATE.md" `
@"
# ADR

## ID

ADR-0000

## Fecha

## Estado

Propuesto

## Contexto

## Alternativas

## Decisión

## Consecuencias

"@

# ==========================================
# REGISTRO DE RIESGOS
# ==========================================

New-SyntecFile `
"00_Admin\Gobierno\REGISTRO_RIESGOS.md" `
@"
# Registro de Riesgos

| ID | Riesgo | Impacto | Probabilidad | Mitigación | Estado |
|----|---------|---------|---------|---------|---------|

"@

# ==========================================
# BITÁCORA GENERAL
# ==========================================

New-SyntecFile `
"00_Admin\BITACORA_GENERAL.md" `
@"
# Bitácora General

## Fecha

### Actividad

### Resultado

### Observaciones

"@

# ==========================================
# BACKLOG
# ==========================================

New-SyntecFile `
"00_Admin\Roadmap\BACKLOG_GENERAL.md" `
@"
# Backlog General

## Pendiente

- [ ] Configurar GitHub
- [ ] Habilitar CodeQL
- [ ] Crear Wiki
- [ ] Integrar SharePoint

## En Progreso

## Completado

"@

# ==========================================
# DASHBOARD DEL ECOSISTEMA
# ==========================================

New-SyntecFile `
"00_Admin\Dashboards\ESTADO_ECOSISTEMA.md" `
@"
# Estado Ecosistema

| Componente | Estado |
|-----------|---------|
| VS Code | OK |
| Git | OK |
| GitHub Copilot | OK |
| NodeJS | OK |
| Python | OK |
| Semgrep | OK |
| CodeQL | Pendiente |
| GitHub | Pendiente |
| SharePoint | Pendiente |

"@

# ==========================================
# FIOS
# ==========================================

New-SyntecFile `
"01_FIOS\DOCUMENTACION\REQUISITOS.md" `
@"
# Requisitos FIOS

## Funcionales

## No Funcionales

## Normativas

"@

New-SyntecFile `
"01_FIOS\DOCUMENTACION\MODULOS.md" `
@"
# Módulos FIOS

## Biblioteca

## Cálculos

## Informes

## Historial

"@

# ==========================================
# NEODARK
# ==========================================

New-SyntecFile `
"02_NeoDark\DOCUMENTACION\REQUISITOS.md" `
@"
# Requisitos NeoDark

## Dataset Builder

## Históricos

## Automatización

"@

# ==========================================
# CODE REVIEW
# ==========================================

New-SyntecFile `
"07_Seguridad\CodeReview\CODE_REVIEW_TEMPLATE.md" `
@"
# Code Review

## Alcance

## Hallazgos

## Riesgos

## Recomendaciones

## Aprobación

"@

# ==========================================
# SECURITY REVIEW
# ==========================================

New-SyntecFile `
"07_Seguridad\SecurityReview\SECURITY_REVIEW_TEMPLATE.md" `
@"
# Security Review

## Vulnerabilidades

## Riesgos

## Mitigaciones

## Estado

"@

# ==========================================
# LECCIONES APRENDIDAS
# ==========================================

New-SyntecFile `
"03_Conocimiento\Lecciones_Aprendidas\REGISTRO_LECCIONES.md" `
@"
# Registro de Lecciones Aprendidas

| Fecha | Proyecto | Lección |
|---------|---------|---------|

"@

# ==========================================
# GIT
# ==========================================

if (!(Test-Path (Join-Path $Base ".git")))
{
    Write-Host ""
    Write-Host "Inicializando Git..." -ForegroundColor Yellow

    Push-Location $Base
    git init
    Pop-Location

    Write-Host "Git inicializado." -ForegroundColor Green
}

Write-Host ""
Write-Host "Bootstrap Syntec v7 finalizado." `
-ForegroundColor Cyan

Write-Host ""