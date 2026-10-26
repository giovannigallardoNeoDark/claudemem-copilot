# ===========================================
# Bootstrap Syntec v6
# Governance + Engineering
# ===========================================

Clear-Host

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "         Bootstrap Syntec v6" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$Base = Split-Path $PSScriptRoot -Parent

# ==================================================
# FUNCION CREAR ARCHIVO
# ==================================================

function New-SyntecFile {
    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FilePath = Join-Path $Base $RelativePath
    $Folder = Split-Path $FilePath -Parent

    if (!(Test-Path $Folder)) {
        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    if (!(Test-Path $FilePath)) {

        $Content | Set-Content `
            -Path $FilePath `
            -Encoding UTF8

        Write-Host "[ARCHIVO] $RelativePath" `
            -ForegroundColor Green
    }
}

# ==================================================
# GITIGNORE CORPORATIVO
# ==================================================

$GitIgnore = @"
# Python
__pycache__/
*.pyc
*.pyo

# VS Code
.vscode/

# Environment
.env
.venv
env/

# Build
dist/
build/

# Logs
*.log

# Windows
Thumbs.db
Desktop.ini

# Temporary
*.tmp
*.bak

"@

New-SyntecFile `
"00_Admin\Plantillas\.gitignore_corporativo" `
$GitIgnore

# ==================================================
# ADR
# ==================================================

New-SyntecFile `
"00_Admin\Arquitectura\ADR\ADR_TEMPLATE.md" `
@"
# ADR

## ID

ADR-0001

## Título

## Estado

Propuesto

## Contexto

## Alternativas

## Decisión

## Consecuencias

"@

# ==================================================
# REGISTRO DE RIESGOS
# ==================================================

New-SyntecFile `
"00_Admin\Gobierno\REGISTRO_RIESGOS.md" `
@"
# Registro de Riesgos

| ID | Riesgo | Impacto | Probabilidad | Mitigación |
|----|---------|---------|------------|------------|

"@

# ==================================================
# BACKLOG GENERAL
# ==================================================

New-SyntecFile `
"00_Admin\Roadmap\BACKLOG_GENERAL.md" `
@"
# Backlog General

## Pendiente

- [ ] GitHub
- [ ] CodeQL
- [ ] SharePoint
- [ ] Biblioteca normativa

## En Progreso

## Finalizado

"@

# ==================================================
# MATRIZ DE DECISIONES
# ==================================================

New-SyntecFile `
"03_Conocimiento\Decisiones_Tecnicas\MATRIZ_DECISIONES.md" `
@"
# Matriz de Decisiones

| Fecha | Proyecto | Decisión | Responsable |
|---------|---------|---------|---------|

"@

# ==================================================
# CODE REVIEW
# ==================================================

New-SyntecFile `
"07_Seguridad\CodeReview\CHECKLIST_CODE_REVIEW.md" `
@"
# Checklist Code Review

## Calidad

- [ ] Código legible
- [ ] Comentarios adecuados
- [ ] Sin duplicidad

## Seguridad

- [ ] Credenciales expuestas
- [ ] Secretos hardcodeados
- [ ] Entradas validadas

## Pruebas

- [ ] Validado
- [ ] Documentado
- [ ] Versionado

"@

# ==================================================
# SECURITY REVIEW
# ==================================================

New-SyntecFile `
"07_Seguridad\SecurityReview\CHECKLIST_SECURITY_REVIEW.md" `
@"
# Checklist Security Review

- [ ] OWASP
- [ ] Dependencias
- [ ] Secretos
- [ ] Permisos
- [ ] Registros
- [ ] Auditoría

"@

# ==================================================
# SEMGREP
# ==================================================

New-SyntecFile `
"07_Seguridad\Semgrep\README.md" `
@"
# Semgrep

Escaneos de seguridad.

## Comando

semgrep scan .

"@

# ==================================================
# CODEQL
# ==================================================

New-SyntecFile `
"07_Seguridad\CodeQL\README.md" `
@"
# CodeQL

Análisis estático de código.

Repositorio GitHub:

Security -> Code Scanning

"@

# ==================================================
# DASHBOARD FIOS
# ==================================================

New-SyntecFile `
"01_FIOS\DASHBOARD.md" `
@"
# Dashboard FIOS

## Estado General

### Módulos

### Pruebas

### Incidencias

### Releases

"@

# ==================================================
# DASHBOARD NEODARK
# ==================================================

New-SyntecFile `
"02_NeoDark\DASHBOARD.md" `
@"
# Dashboard NeoDark

## Estado General

### Automatizaciones

### Dataset

### Entrenamiento

### Releases

"@

# ==================================================
# REGISTRO DE LECCIONES
# ==================================================

New-SyntecFile `
"03_Conocimiento\Lecciones_Aprendidas\HISTORIAL_LECCIONES.md" `
@"
# Historial de Lecciones

| Fecha | Proyecto | Tema | Referencia |
|---------|---------|---------|---------|

"@

# ==================================================
# INICIALIZAR GIT
# ==================================================

if (Test-Path (Join-Path $Base ".git")) {

    Write-Host ""
    Write-Host "[INFO] Repositorio Git ya existe." `
        -ForegroundColor Yellow
}
else {

    Write-Host ""
    Write-Host "[INFO] Inicializando Git..." `
        -ForegroundColor Cyan

    try {

        Push-Location $Base

        git init

        Pop-Location

        Write-Host "[OK] Git inicializado." `
            -ForegroundColor Green
    }
    catch {

        Write-Host "[ERROR] No fue posible inicializar Git." `
            -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Bootstrap Syntec v6 completado correctamente." `
    -ForegroundColor Cyan
Write-Host ""