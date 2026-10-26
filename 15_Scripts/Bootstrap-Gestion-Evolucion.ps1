# ==========================================
# Bootstrap Gestion Evolucion
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-EvolutionFile {

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
        $Content | Set-Content $FullPath -Encoding UTF8
        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\README.md" `
"# Gestion Evolucion Ecosistema"

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\ROADMAP_ECOSISTEMA.md" `
@"
# Roadmap Ecosistema

Fase Actual

✅ Arquitectura
✅ Gobierno
✅ Operacion

Proximas Fases

1. Claude-Mem
2. Headroom
3. OmniRoute
4. Task Observer
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\BACKLOG_ECOSISTEMA.md" `
@"
# Backlog Ecosistema

Alta

- Claude-Mem
- Headroom

Media

- OmniRoute

Baja

- SharePoint
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\REGISTRO_PRIORIDADES.md" `
@"
# Registro Prioridades

| Fecha | Elemento | Prioridad |
|--------|-----------|-----------|
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\REGISTRO_DEUDA_TECNICA.md" `
@"
# Deuda Tecnica

## Pendiente

Registrar hallazgos futuros.
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\REGISTRO_CAPACIDADES.md" `
@"
# Capacidades

Disponibles

✅ Conocimiento
✅ Agentes
✅ Conectores
✅ Gobierno
✅ Arquitectura

Pendientes

⬜ Memoria Persistente
⬜ Multi-modelo
⬜ Autoaprendizaje
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\REGISTRO_HABILIDADES.md" `
@"
# Habilidades Ecosistema

## Skills Implementadas

## Skills Futuras

## Skills Obsoletas
"@

New-EvolutionFile `
"03_Conocimiento\25_Gestion_Evolucion\PLAN_MEJORA_CONTINUA.md" `
@"
# Mejora Continua

Proceso

1. Auditoria
2. Analisis
3. Priorizacion
4. Implementacion
5. Validacion
6. Registro
"@

Write-Host ""
Write-Host "Bootstrap Gestion Evolucion completado."
Write-Host ""