# ==========================================
# Copilot Empresarial v3.1
# Despliegue Operacional
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-DeployFile {

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

    $Content |
    Set-Content `
        $FullPath `
        -Encoding UTF8

    Write-Host "[OK] $RelativePath" `
        -ForegroundColor Green
}

# ==========================================
# CHECKLIST M365
# ==========================================

New-DeployFile `
"03_Conocimiento\27_M365_Copilot\CHECKLIST_M365.md" `
@"
# Checklist Microsoft 365

## SharePoint

[ ] Biblioteca Lecciones Aprendidas

[ ] Biblioteca Decisiones Tecnicas

[ ] Biblioteca Procedimientos

[ ] Biblioteca Informes

[ ] Biblioteca Normativas

[ ] Biblioteca Plantillas

## Teams

[ ] Canal Hallazgos

[ ] Canal Mejoras

[ ] Canal Prioridades

[ ] Canal Operacion

[ ] Canal Seguridad

## Outlook

[ ] Plantilla Informe Ejecutivo

[ ] Plantilla Hallazgo

[ ] Plantilla Decision Tecnica

[ ] Plantilla Resumen Semanal

## OneDrive

[ ] Politica definida

[ ] Estructura definida
"@

# ==========================================
# SPRINT INICIAL
# ==========================================

New-DeployFile `
"03_Conocimiento\27_M365_Copilot\SPRINT_001.md" `
@"
# Sprint 001

## Objetivo

Desplegar Microsoft 365 Operativo.

## Tareas

1. SharePoint

2. Teams

3. Outlook

4. OneDrive

## Resultado Esperado

Infraestructura M365 lista.

## Estado

Pendiente
"@

# ==========================================
# CRITERIOS EXITO
# ==========================================

New-DeployFile `
"03_Conocimiento\27_M365_Copilot\CRITERIOS_EXITO.md" `
@"
# Criterios de Exito

## SharePoint

PASS:

Bibliotecas creadas

## Teams

PASS:

Canales creados

## Outlook

PASS:

Plantillas creadas

## OneDrive

PASS:

Politica creada

## Resultado

100% PASS
=
Microsoft 365 Operativo
"@

# ==========================================
# SEGURIDAD OPERATIVA
# ==========================================

New-DeployFile `
"07_Seguridad\CHECKLIST_SEGURIDAD_V31.md" `
@"
# Checklist Seguridad

## CodeQL

[ ] Workflow generado

[ ] Primer analisis

[ ] Resultado registrado

## SonarQube

[ ] Proyecto creado

[ ] Dashboard validado

## Snyk

[ ] Escaneo ejecutado

[ ] Vulnerabilidades registradas
"@

# ==========================================
# ESTADO DESPLIEGUE
# ==========================================

New-DeployFile `
"00_Admin\Dashboards\ESTADO_DESPLIEGUE_V31.md" `
@"
# Estado Despliegue v3.1

Microsoft 365 .... Preparado

Seguridad ........ Preparada

OmniRoute ........ Investigación

Claude-Mem ....... Operativo

Headroom ......... Operativo

Observador ....... Operativo

Estado General:

Listo para despliegue
"@

# ==========================================
# REGISTRO
# ==========================================

New-DeployFile `
"03_Conocimiento\22_Operacion\REGISTRO_V31.md" `
@"
# Registro v3.1

Fecha:

$(Get-Date)

Objetivo:

Microsoft 365 Operativo
Seguridad Operativa

Estado:

Preparado
"@

Write-Host ""
Write-Host "========================================="
Write-Host " DESPLIEGUE V3.1 PREPARADO"
Write-Host "========================================="
Write-Host ""