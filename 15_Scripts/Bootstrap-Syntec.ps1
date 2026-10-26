# ==========================================
# Bootstrap Syntec AI
# Crea estructura corporativa base
# ==========================================

$Base = "$PSScriptRoot\..\"

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
"06_Prompts\Ingenieria",
"06_Prompts\FIOS",
"06_Prompts\NeoDark",
"06_Prompts\Programacion",
"06_Prompts\Marketing",
"06_Prompts\Investigacion",

# SEGURIDAD
"07_Seguridad\Semgrep",
"07_Seguridad\CodeQL",
"07_Seguridad\SonarQube",
"07_Seguridad\Auditorias",
"07_Seguridad\Vulnerabilidades",
"07_Seguridad\Incidentes",

# RESTO
"08_Autenticacion",
"09_Investigacion",
"10_Respaldos",
"11_Herramientas",
"12_IA",
"13_Informes",
"14_Pruebas",
"15_Scripts",
"16_Marketing",
"99_Temp"
)

foreach ($Folder in $Folders)
{
    $FullPath = Join-Path $Base $Folder

    if (!(Test-Path $FullPath))
    {
        New-Item `
            -ItemType Directory `
            -Path $FullPath `
            -Force | Out-Null

        Write-Host "[CREADA] $Folder" -ForegroundColor Green
    }
}

# Archivo maestro

$Arquitectura = Join-Path $Base "00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md"

if (!(Test-Path $Arquitectura))
{
@"
# Arquitectura General

Proyecto:
Copilot Empresarial de Ingeniería,
Desarrollo, Investigación y Gestión del Conocimiento.

## Objetivos

- FIOS
- NeoDark
- Biblioteca de conocimiento
- Seguridad
- Automatización
- IA

"@ | Out-File $Arquitectura -Encoding UTF8
}

Write-Host ""
Write-Host "Bootstrap Syntec completado correctamente." -ForegroundColor Cyan