# ==========================================
# Bootstrap Arquitectura Operacional
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-ArchFile {

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

        $Content |
        Set-Content $FullPath -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

# ==========================================
# DOCUMENTOS
# ==========================================

$Files = @{

"03_Conocimiento\19_Arquitectura_Operacional\README.md" = @"
# Arquitectura Operacional

Describe cómo interactúan todos los componentes del ecosistema.
"@

"03_Conocimiento\19_Arquitectura_Operacional\MAPA_ECOSISTEMA.md" = @"
# Mapa Ecosistema

Copilot Empresarial

├─ Memoria
├─ Conocimiento
├─ Investigación
├─ Seguridad
├─ Conectores
├─ Agentes
└─ Automatización
"@

"03_Conocimiento\19_Arquitectura_Operacional\MAPA_DEPENDENCIAS.md" = @"
# Dependencias

Copilot
│
├─ Conectores
├─ Agentes
├─ Memoria
└─ Gobierno IA
"@

"03_Conocimiento\19_Arquitectura_Operacional\ROADMAP_IMPLEMENTACION.md" = @"
# Roadmap Implementación

Fase 1
✅ Arquitectura

Fase 2
✅ Gobierno IA

Fase 3
⬜ Claude-Mem

Fase 4
⬜ Headroom

Fase 5
⬜ OmniRoute

Fase 6
⬜ Task Observer
"@

"03_Conocimiento\19_Arquitectura_Operacional\CAPAS_ARQUITECTURA.md" = @"
# Capas Arquitectura

Capa 1
Infraestructura

Capa 2
Conocimiento

Capa 3
Conectores

Capa 4
Agentes

Capa 5
Memoria

Capa 6
Multi Modelo
"@

"03_Conocimiento\19_Arquitectura_Operacional\DIAGRAMA_COMPONENTES.md" = @"
# Componentes

Copilot
↓
Conocimiento
↓
Conectores
↓
Agentes
↓
Memoria
↓
Automatización
"@

"03_Conocimiento\19_Arquitectura_Operacional\MAPA_INTEGRACIONES.md" = @"
# Integraciones Futuras

Nivel 1

- Claude-Mem
- Headroom
- OmniRoute

Nivel 2

- Task Observer

Nivel 3

- GitHub
- SharePoint
- Teams
- Outlook

Nivel 4

- Tavily
- Exa
- Perplexity
- Jina
"@
}

foreach($File in $Files.Keys)
{
    New-ArchFile $File $Files[$File]
}

Write-Host ""
Write-Host "Bootstrap Arquitectura Operacional completado."
Write-Host ""