# ==========================================
# Completar M365 Operativo
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-M365File {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath

    if (!(Test-Path $FullPath))
    {
        $Content | Set-Content `
        $FullPath `
        -Encoding UTF8
    }
}

New-M365File `
"03_Conocimiento\27_M365_Copilot\ARQUITECTURA_M365.md" `
@"
# Arquitectura Microsoft 365

Copilot Empresarial
│
├─ Claude-Mem
├─ SharePoint
├─ Teams
├─ Outlook
├─ OneDrive
└─ Copilot M365

Objetivo:

Centralizar conocimiento corporativo.
"@

New-M365File `
"03_Conocimiento\27_M365_Copilot\MAPA_INTEGRACIONES.md" `
@"
# Mapa Integraciones

SharePoint
→ Documentación oficial

Teams
→ Colaboración

Outlook
→ Comunicaciones

OneDrive
→ Archivos personales

Copilot
→ Consumo de conocimiento
"@

New-M365File `
"03_Conocimiento\27_M365_Copilot\ROADMAP_M365.md" `
@"
# Roadmap M365

Fase 1
SharePoint

Fase 2
Teams

Fase 3
Outlook

Fase 4
OneDrive

Fase 5
Copilot M365
"@

Write-Host ""
Write-Host "M365 Operativo completado."