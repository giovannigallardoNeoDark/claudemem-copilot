# ==================================================
# Bootstrap Syntec v2
# ==================================================

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Bootstrap Syntec v2" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------
# Funciones
# --------------------------------------------------

function New-SyntecFolder {
    param($Path)

    $FullPath = Join-Path $Base $Path

    if (!(Test-Path $FullPath))
    {
        New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
        Write-Host "[CREADA] $Path" -ForegroundColor Green
    }

    # README
    $Readme = Join-Path $FullPath "README.md"

    if (!(Test-Path $Readme))
    {
@"
# $Path

Documentación del módulo.

## Objetivo

Completar posteriormente.

"@ | Set-Content $Readme -Encoding UTF8
    }

    # .gitkeep
    $Gitkeep = Join-Path $FullPath ".gitkeep"

    if (!(Test-Path $Gitkeep))
    {
        New-Item `
            -ItemType File `
            -Path $Gitkeep `
            -Force | Out-Null
    }
}

# --------------------------------------------------
# ESTRUCTURA
# --------------------------------------------------

$Folders = @(

# ADMIN
"00_Admin\Arquitectura",
"00_Admin\Configuracion",
"00_Admin\Inventario",
"00_Admin\Procedimientos",
"00_Admin\Roadmap",
"00_Admin\Reuniones",

# FIOS
"01_FIOS\01_Codigo",
"01_FIOS\02_Modulos",
"01_FIOS\03_Pruebas",
"01_FIOS\04_Informes",
"01_FIOS\05_Documentacion",
"01_FIOS\06_Normativas",
"01_FIOS\07_Datos",
"01_FIOS\08_Releases",
"01_FIOS\09_Historico",

# NEODARK
"02_NeoDark\01_Codigo",
"02_NeoDark\02_Datasets",
"02_NeoDark\03_Entrenamiento",
"02_NeoDark\04_Informes",
"02_NeoDark\05_Automatizaciones",
"02_NeoDark\06_Documentacion",
"02_NeoDark\07_Releases",
"02_NeoDark\08_Historico",

# CONOCIMIENTO
"03_Conocimiento\Lecciones_Aprendidas",
"03_Conocimiento\Problemas_Resueltos",
"03_Conocimiento\Mejores_Practicas",
"03_Conocimiento\Decisiones_Tecnicas",
"03_Conocimiento\FAQ",
"03_Conocimiento\Checklists",
"03_Conocimiento\Casos_Reales",

# NORMATIVAS
"04_Normativas\AISC",
"04_Normativas\ASME",
"04_Normativas\AWS",
"04_Normativas\ISO",
"04_Normativas\ANSI",
"04_Normativas\NCh",
"04_Normativas\API",
"04_Normativas\Otros",

# PLANTILLAS
"05_Plantillas\Ingenieria",
"05_Plantillas\Programacion",
"05_Plantillas\Seguridad",
"05_Plantillas\Comercial",
"05_Plantillas\Marketing",
"05_Plantillas\Investigacion",

# PROMPTS
"06_Prompts\FIOS",
"06_Prompts\NeoDark",
"06_Prompts\Ingenieria",
"06_Prompts\Programacion",
"06_Prompts\Marketing",
"06_Prompts\Investigacion",

# SEGURIDAD
"07_Seguridad\Semgrep",
"07_Seguridad\CodeQL",
"07_Seguridad\SonarQube",
"07_Seguridad\Auditorias",
"07_Seguridad\Vulnerabilidades",
"07_Seguridad\Incidentes"
)

foreach($Folder in $Folders)
{
    New-SyntecFolder $Folder
}

# --------------------------------------------------
# ARCHIVOS MAESTROS
# --------------------------------------------------

$Arquitectura = Join-Path `
$Base `
"00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md"

if (!(Test-Path $Arquitectura))
{
@"
# Arquitectura General

## Objetivo

Copilot Empresarial de:

- Ingeniería
- Desarrollo
- Investigación
- Gestión del Conocimiento

## Sistemas

- FIOS
- NeoDark

## Seguridad

- Semgrep
- CodeQL
- SonarQube

"@ | Set-Content $Arquitectura -Encoding UTF8
}

$Roadmap = Join-Path `
$Base `
"00_Admin\Roadmap\ROADMAP_GENERAL.md"

if (!(Test-Path $Roadmap))
{
@"
# Roadmap General

## Fase 1
Estructura

## Fase 2
GitHub

## Fase 3
Base de conocimiento

## Fase 4
Seguridad

## Fase 5
Automatización

"@ | Set-Content $Roadmap -Encoding UTF8
}

$Inventario = Join-Path `
$Base `
"00_Admin\Inventario\INVENTARIO_HERRAMIENTAS.md"

if (!(Test-Path $Inventario))
{
@"
# Inventario de Herramientas

## Instaladas

- VS Code
- Git
- GitHub Copilot
- NodeJS
- Python
- Semgrep

"@ | Set-Content $Inventario -Encoding UTF8
}

Write-Host ""
Write-Host "Bootstrap Syntec v2 completado." -ForegroundColor Cyan
Write-Host ""