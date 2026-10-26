# ==========================================
# Bootstrap Implementacion Copilot
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-ImplFile {

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

        $Content | Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
}

# ==========================================
# IMPLEMENTACION
# ==========================================

New-ImplFile `
"03_Conocimiento\20_Implementacion\README.md" `
"# Implementacion Copilot Empresarial"

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_CLAUDEMEM.md" `
@"
# Claude-Mem

Estado: Pendiente

Objetivo:
Memoria persistente.

Beneficios:
- Historial
- Contexto
- Resumenes

Prioridad:
Alta
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_HEADROOM.md" `
@"
# Headroom

Estado: Pendiente

Objetivo:
Optimizar contexto.

Beneficios:
- Compresion
- Menos tokens
- Mayor contexto
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_OMNIROUTE.md" `
@"
# OmniRoute

Estado: Pendiente

Objetivo:
Gateway multi-modelo.

Modelos:
- GPT
- Claude
- Gemini
- DeepSeek
- Qwen
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_TASKOBSERVER.md" `
@"
# Task Observer

Estado: Pendiente

Objetivo:
Detectar patrones.

Beneficios:
- Nuevos skills
- Automatizacion
- Mejora continua
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_GITHUB.md" `
@"
# GitHub

Estado: Parcial

Capacidades:
- Issues
- Wiki
- Proyectos
- Versionado
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\PLAN_SHAREPOINT.md" `
@"
# SharePoint

Estado: Pendiente

Capacidades:
- Biblioteca documental
- Informes
- Procedimientos
- Normativas
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\MATRIZ_PRIORIDADES.md" `
@"
# Prioridades

1. Claude-Mem
2. Headroom
3. OmniRoute
4. Task Observer
5. SharePoint
"@

New-ImplFile `
"03_Conocimiento\20_Implementacion\ESTADO_IMPLEMENTACION.md" `
@"
# Estado

Pendiente
Evaluacion
Prueba
Implementado
Validado
"@

Write-Host ""
Write-Host "Bootstrap Implementacion completado"
Write-Host ""