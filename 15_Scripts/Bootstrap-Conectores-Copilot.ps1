# ==========================================
# Bootstrap Conectores Copilot
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Bootstrap Conectores Copilot"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

function New-ConectorFile {

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

        $Content |
        Set-Content `
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

# ==================================================
# ESTRUCTURA
# ==================================================

$Folders = @(

"03_Conocimiento\16_Conectores",

"03_Conocimiento\16_Conectores\GitHub",
"03_Conocimiento\16_Conectores\SharePoint",
"03_Conocimiento\16_Conectores\OneDrive",
"03_Conocimiento\16_Conectores\Teams",
"03_Conocimiento\16_Conectores\Outlook",

"03_Conocimiento\16_Conectores\ClaudeMem",
"03_Conocimiento\16_Conectores\Headroom",
"03_Conocimiento\16_Conectores\OmniRoute",
"03_Conocimiento\16_Conectores\TaskObserver",

"03_Conocimiento\16_Conectores\Tavily",
"03_Conocimiento\16_Conectores\Exa",
"03_Conocimiento\16_Conectores\Perplexity",
"03_Conocimiento\16_Conectores\Jina",

"03_Conocimiento\16_Conectores\Semgrep",
"03_Conocimiento\16_Conectores\CodeQL",
"03_Conocimiento\16_Conectores\SonarQube",
"03_Conocimiento\16_Conectores\Snyk",

"03_Conocimiento\16_Conectores\PowerAutomate",
"03_Conocimiento\16_Conectores\n8n"
)

foreach($Folder in $Folders)
{
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $Base $Folder) `
        -Force | Out-Null
}

# ==================================================
# README GENERAL
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\README.md" `
@"
# Biblioteca de Conectores

Objetivo:

Documentar conectores e integraciones
utilizadas por el Copilot Empresarial.

Categorias:

- Estrategicos
- Investigacion
- Seguridad
- Automatizacion
"@

# ==================================================
# ESTRATEGICOS
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\GitHub\GITHUB_CONECTOR.md" `
@"
# GitHub

Prioridad: Alta

Funciones:

- Control de versiones
- Repositorios
- Wiki
- Issues
- Projects

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\ClaudeMem\CLAUDEMEM_CONECTOR.md" `
@"
# Claude-Mem

Prioridad: Alta

Funciones:

- Memoria persistente
- Recuperacion de contexto
- Historial
- Resumenes

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\Headroom\HEADROOM_CONECTOR.md" `
@"
# Headroom

Prioridad: Alta

Funciones:

- Compresion de contexto
- Reduccion de tokens
- Contexto ampliado

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\OmniRoute\OMNIROUTE_CONECTOR.md" `
@"
# OmniRoute

Prioridad: Alta

Funciones:

- Gateway multi-modelo

Modelos:

- GPT
- Claude
- Gemini
- DeepSeek
- Qwen

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\TaskObserver\TASKOBSERVER_CONECTOR.md" `
@"
# Task Observer

Prioridad: Alta

Funciones:

- Analisis de patrones
- Recomendaciones
- Automatizacion futura

Estado:

Planificado
"@

# ==================================================
# INVESTIGACION
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\Tavily\TAVILY_CONECTOR.md" `
@"
# Tavily

Categoria:

Investigacion

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\Exa\EXA_CONECTOR.md" `
@"
# Exa

Categoria:

Investigacion

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\Perplexity\PERPLEXITY_CONECTOR.md" `
@"
# Perplexity

Categoria:

Investigacion

Estado:

Planificado
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\Jina\JINA_CONECTOR.md" `
@"
# Jina Reader

Categoria:

Investigacion

Estado:

Planificado
"@

# ==================================================
# SEGURIDAD
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\Semgrep\SEMGREP_CONECTOR.md" `
@"
# Semgrep

Categoria:

Seguridad

Estado:

Operativo
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\CodeQL\CODEQL_CONECTOR.md" `
@"
# CodeQL

Categoria:

Seguridad

Estado:

Pendiente
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\SonarQube\SONARQUBE_CONECTOR.md" `
@"
# SonarQube

Categoria:

Seguridad

Estado:

Pendiente
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\Snyk\SNYK_CONECTOR.md" `
@"
# Snyk

Categoria:

Seguridad

Estado:

Pendiente
"@

# ==================================================
# AUTOMATIZACION
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\PowerAutomate\POWERAUTOMATE_CONECTOR.md" `
@"
# Power Automate

Categoria:

Automatizacion

Estado:

Pendiente
"@

New-ConectorFile `
"03_Conocimiento\16_Conectores\n8n\N8N_CONECTOR.md" `
@"
# n8n

Categoria:

Automatizacion

Estado:

Pendiente
"@

# ==================================================
# MAPA GENERAL
# ==================================================

New-ConectorFile `
"03_Conocimiento\16_Conectores\MAPA_CONECTORES.md" `
@"
# Mapa de Conectores

Nivel 1

- GitHub
- ClaudeMem
- Headroom
- OmniRoute
- TaskObserver

Nivel 2

- Tavily
- Exa
- Perplexity
- Jina

Nivel 3

- Semgrep
- CodeQL
- SonarQube
- Snyk

Nivel 4

- Power Automate
- n8n

Nivel 5

- SharePoint
- Teams
- Outlook
- OneDrive
"@

Write-Host ""
Write-Host "Bootstrap Conectores Copilot completado." `
-ForegroundColor Cyan
Write-Host ""