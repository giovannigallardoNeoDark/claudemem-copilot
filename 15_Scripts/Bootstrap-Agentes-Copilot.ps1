# ==========================================
# Bootstrap Agentes Copilot
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "      Bootstrap Agentes Copilot"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function New-AgentFile {

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

"03_Conocimiento\17_Agentes",

"03_Conocimiento\17_Agentes\00_Coordinador",
"03_Conocimiento\17_Agentes\01_Memoria",
"03_Conocimiento\17_Agentes\02_Investigacion",
"03_Conocimiento\17_Agentes\03_Documentacion",
"03_Conocimiento\17_Agentes\04_Programacion",
"03_Conocimiento\17_Agentes\05_Seguridad",
"03_Conocimiento\17_Agentes\06_Conocimiento",
"03_Conocimiento\17_Agentes\07_Normativas",
"03_Conocimiento\17_Agentes\08_Automatizacion",
"03_Conocimiento\17_Agentes\09_Marketing",
"03_Conocimiento\17_Agentes\10_Creatividad",
"03_Conocimiento\17_Agentes\11_Observador"
)

foreach($Folder in $Folders)
{
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $Base $Folder) `
        -Force | Out-Null
}

# ==================================================
# REGLAS GENERALES
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\REGLAS_AGENTES.md" `
@"
# Reglas de Agentes

1. Ningun agente modifica la estrategia.

2. Todo agente debe fortalecer el Copilot Empresarial.

3. Ningun agente puede priorizar un proyecto especifico.

4. Todas las recomendaciones deben documentarse.

5. Todo conocimiento reutilizable debe registrarse.

6. El Agente Observador puede proponer mejoras pero no implementarlas automaticamente.
"@

# ==================================================
# COORDINADOR
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\00_Coordinador\AGENTE_COORDINADOR.md" `
@"
# Agente Coordinador

Responsabilidades:

- Orquestar agentes.
- Priorizar iniciativas.
- Validar alineacion estrategica.
- Resolver conflictos.

Regla Principal:

Todo debe alinearse con la estrategia del Copilot Empresarial.
"@

# ==================================================
# MEMORIA
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\01_Memoria\AGENTE_MEMORIA.md" `
@"
# Agente Memoria

Funciones:

- Detectar conocimiento reutilizable.
- Registrar lecciones aprendidas.
- Registrar decisiones tecnicas.
- Gestionar contexto.

Objetivo futuro:

Integracion con Claude-Mem.
"@

# ==================================================
# INVESTIGACION
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\02_Investigacion\AGENTE_INVESTIGACION.md" `
@"
# Agente Investigacion

Funciones:

- Buscar fuentes.
- Comparar fuentes.
- Validar informacion.
- Consolidar conocimiento.

Conectores futuros:

- Tavily
- Exa
- Perplexity
- Jina
"@

# ==================================================
# DOCUMENTACION
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\03_Documentacion\AGENTE_DOCUMENTACION.md" `
@"
# Agente Documentacion

Funciones:

- Revisar documentacion.
- Detectar vacios.
- Detectar inconsistencias.
- Proponer mejoras.

Objetivo:

Mantener una documentacion uniforme.
"@

# ==================================================
# PROGRAMACION
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\04_Programacion\AGENTE_PROGRAMACION.md" `
@"
# Agente Programacion

Funciones:

- Revisar codigo.
- Detectar deuda tecnica.
- Detectar duplicaciones.
- Recomendar mejoras.

Herramientas relacionadas:

- Copilot
- Semgrep
- CodeQL
- SonarQube
- Snyk
"@

# ==================================================
# SEGURIDAD
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\05_Seguridad\AGENTE_SEGURIDAD.md" `
@"
# Agente Seguridad

Funciones:

- Revisar riesgos.
- Detectar vulnerabilidades.
- Revisar dependencias.
- Generar auditorias.

Objetivo:

Mejorar seguridad del ecosistema.
"@

# ==================================================
# CONOCIMIENTO
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\06_Conocimiento\AGENTE_CONOCIMIENTO.md" `
@"
# Agente Conocimiento

Funciones:

- Gestionar biblioteca.
- Relacionar informacion.
- Detectar duplicidades.
- Identificar conocimiento faltante.

Objetivo:

Incrementar el valor de la base de conocimiento.
"@

# ==================================================
# NORMATIVAS
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\07_Normativas\AGENTE_NORMATIVAS.md" `
@"
# Agente Normativas

Funciones:

- Clasificar normas.
- Mantener indices.
- Mantener matrices de aplicabilidad.
- Gestionar glosarios.

Objetivo:

Conservar trazabilidad normativa.
"@

# ==================================================
# AUTOMATIZACION
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\08_Automatizacion\AGENTE_AUTOMATIZACION.md" `
@"
# Agente Automatizacion

Funciones:

- Detectar tareas repetitivas.
- Proponer flujos.
- Diseñar automatizaciones.

Herramientas futuras:

- Power Automate
- n8n
- GitHub Actions
"@

# ==================================================
# MARKETING
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\09_Marketing\AGENTE_MARKETING.md" `
@"
# Agente Marketing

Funciones:

- Generar propuestas.
- Mejorar comunicacion.
- Mantener lineamientos corporativos.

Objetivo:

Apoyar difusion y posicionamiento.
"@

# ==================================================
# CREATIVIDAD
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\10_Creatividad\AGENTE_CREATIVIDAD.md" `
@"
# Agente Creatividad

Funciones:

- Proponer diagramas.
- Proponer infografias.
- Diseñar activos visuales.

Herramientas futuras:

- Copilot Image Creator
- Midjourney
- Ideogram
"@

# ==================================================
# OBSERVADOR
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\11_Observador\AGENTE_OBSERVADOR.md" `
@"
# Agente Observador

Funciones:

- Analizar patrones de trabajo.
- Detectar desperdicio.
- Detectar conocimiento faltante.
- Recomendar nuevos skills.
- Recomendar procedimientos.
- Recomendar automatizaciones.

Inspiracion:

Task Observer.
"@

# ==================================================
# MAPA DE AGENTES
# ==================================================

New-AgentFile `
"03_Conocimiento\17_Agentes\MAPA_AGENTES.md" `
@"
# Mapa de Agentes

Coordinador
│
├── Memoria
├── Investigacion
├── Documentacion
├── Programacion
├── Seguridad
├── Conocimiento
├── Normativas
├── Automatizacion
├── Marketing
├── Creatividad
└── Observador
"@

Write-Host ""
Write-Host "Bootstrap Agentes Copilot completado." `
-ForegroundColor Cyan
Write-Host ""