# ==========================================
# Bootstrap Copilot Empresarial
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host " Copilot Empresarial Bootstrap"
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

function New-CopilotFile {

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
}

# ==========================================
# ESTRUCTURA
# ==========================================

$Bibliotecas = @(

"03_Conocimiento\00_Estrategia_Copilot",
"03_Conocimiento\01_Memoria",
"03_Conocimiento\02_Investigacion",
"03_Conocimiento\03_Informes",
"03_Conocimiento\04_Programacion",
"03_Conocimiento\05_Seguridad",
"03_Conocimiento\06_Automatizacion",
"03_Conocimiento\07_Creatividad",
"03_Conocimiento\08_Marketing",
"03_Conocimiento\09_Normativas",
"03_Conocimiento\10_Prompts",
"03_Conocimiento\11_Skills",
"03_Conocimiento\12_Procedimientos",
"03_Conocimiento\13_Lecciones_Aprendidas",
"03_Conocimiento\14_Decisiones_Tecnicas",
"03_Conocimiento\15_Casos_Reales"

)

foreach ($B in $Bibliotecas)
{
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $Base $B) `
        -Force | Out-Null
}

# ==========================================
# ESTRATEGIA
# ==========================================

New-CopilotFile `
"03_Conocimiento\00_Estrategia_Copilot\VISION_GENERAL.md" `
@"
# Vision General

Construir un Copilot Empresarial para:

- Ingenieria
- Desarrollo
- Investigacion
- Gestion del Conocimiento
- Seguridad
- Automatizacion
- Informes
- Marketing

La plataforma es independiente de cualquier proyecto.
"@

New-CopilotFile `
"03_Conocimiento\00_Estrategia_Copilot\OBJETIVOS.md" `
@"
# Objetivos

## Nivel 1

- Memoria
- Conocimiento
- Prompts
- Procedimientos

## Nivel 2

- Investigacion
- Informes
- Seguridad

## Nivel 3

- Automatizacion
- Multi Modelo
- Aprendizaje Continuo
"@

New-CopilotFile `
"03_Conocimiento\00_Estrategia_Copilot\ALCANCE.md" `
@"
# Alcance

Incluye:

- Ingenieria
- Desarrollo
- Investigacion
- Seguridad
- Documentacion
- Informes

No incluye proyectos especificos.
"@

New-CopilotFile `
"03_Conocimiento\00_Estrategia_Copilot\REGLAS_ARQUITECTURA.md" `
@"
# Reglas

1. La plataforma es prioritaria.
2. Todo debe fortalecer Copilot.
3. Evitar funcionalidades especificas de proyectos.
4. Toda decision importante debe documentarse.
"@

# ==========================================
# MEMORIA
# ==========================================

New-CopilotFile `
"03_Conocimiento\01_Memoria\ESTRATEGIA_MEMORIA.md" `
@"
# Estrategia Memoria

Recordar:

- Decisiones tecnicas
- Procedimientos
- Prompts
- Lecciones aprendidas
- Investigaciones

Preparado para Claude-Mem.
"@

New-CopilotFile `
"03_Conocimiento\01_Memoria\MAPA_CONTEXTO.md" `
@"
# Mapa de Contexto

Fuentes:

- Conocimiento
- Informes
- Procedimientos
- Prompts
- Investigaciones
"@

# ==========================================
# INVESTIGACION
# ==========================================

New-CopilotFile `
"03_Conocimiento\02_Investigacion\METODOLOGIA_INVESTIGACION.md" `
@"
# Metodologia

1. Definir objetivo.
2. Buscar fuentes.
3. Validar fuentes.
4. Consolidar hallazgos.
5. Documentar conclusiones.
"@

New-CopilotFile `
"03_Conocimiento\02_Investigacion\VALIDACION_FUENTES.md" `
@"
# Validacion de Fuentes

Alta:
- Normas
- Fabricantes
- Organismos

Media:
- Papers

Baja:
- Blogs
- Opiniones
"@

# ==========================================
# INFORMES
# ==========================================

New-CopilotFile `
"03_Conocimiento\03_Informes\CATALOGO_INFORMES.md" `
@"
# Catalogo Informes

- Ingenieria
- Ejecutivo
- Seguridad
- Auditoria
- Comercial
"@

# ==========================================
# PROGRAMACION
# ==========================================

New-CopilotFile `
"03_Conocimiento\04_Programacion\ESTANDARES_CODIGO.md" `
@"
# Estandares Codigo

- Legibilidad
- Seguridad
- Reutilizacion
- Documentacion
"@

# ==========================================
# SEGURIDAD
# ==========================================

New-CopilotFile `
"03_Conocimiento\05_Seguridad\POLITICA_SEGURIDAD.md" `
@"
# Politica Seguridad

Todo contenido debe ser:

- Trazable
- Verificable
- Documentado
"@

# ==========================================
# PROMPTS
# ==========================================

New-CopilotFile `
"03_Conocimiento\10_Prompts\PROMPT_INVESTIGACION.md" `
@"
Objetivo:
Generar investigaciones verificables.

Requisitos:

- Fuentes
- Citas
- Validacion
"@

New-CopilotFile `
"03_Conocimiento\10_Prompts\PROMPT_PROGRAMACION.md" `
@"
Objetivo:
Generar codigo mantenible y seguro.
"@

New-CopilotFile `
"03_Conocimiento\10_Prompts\PROMPT_INFORMES.md" `
@"
Objetivo:
Generar informes profesionales.
"@

# ==========================================
# SKILLS
# ==========================================

New-CopilotFile `
"03_Conocimiento\11_Skills\SKILL_INVESTIGACION.md" `
@"
Entrada:
Pregunta

Proceso:
Buscar
Validar
Comparar

Salida:
Informe
"@

New-CopilotFile `
"03_Conocimiento\11_Skills\SKILL_GENERACION_INFORMES.md" `
@"
Entrada:
Datos

Salida:
Informe estructurado
"@

# ==========================================
# PROCEDIMIENTOS
# ==========================================

New-CopilotFile `
"03_Conocimiento\12_Procedimientos\PROCEDIMIENTO_DOCUMENTACION.md" `
@"
1. Crear documento.
2. Asignar version.
3. Revisar.
4. Publicar.
"@

New-CopilotFile `
"03_Conocimiento\12_Procedimientos\PROCEDIMIENTO_INVESTIGACION.md" `
@"
1. Definir alcance.
2. Buscar.
3. Verificar.
4. Documentar.
"@

# ==========================================

Write-Host ""
Write-Host "Bootstrap Copilot Empresarial completado." `
-ForegroundColor Cyan
Write-Host ""