# ==========================================
# Auditoria Copilot Empresarial
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte = Join-Path `
$Base `
"00_Admin\Dashboards\MADUREZ_COPILOT_EMPRESARIAL.md"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Auditoria Copilot Empresarial"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# FUNCIONES
# ==========================================

function Test-SyntecFile {
    param([string]$RelativePath)

    $Path = Join-Path $Base $RelativePath

    return (Test-Path $Path)
}

function Score {
    param(
        [int]$Current,
        [int]$Total
    )

    if($Total -eq 0) {
        return 0
    }

    return [math]::Round(($Current / $Total) * 100)
}

# ==========================================
# DEFINICION MODULOS
# ==========================================

$Areas = @{}

$Areas["Estrategia"] = @(
"03_Conocimiento\00_Estrategia_Copilot\VISION_GENERAL.md",
"03_Conocimiento\00_Estrategia_Copilot\OBJETIVOS.md",
"03_Conocimiento\00_Estrategia_Copilot\ALCANCE.md",
"03_Conocimiento\00_Estrategia_Copilot\REGLAS_ARQUITECTURA.md"
)

$Areas["Memoria"] = @(
"03_Conocimiento\01_Memoria\ESTRATEGIA_MEMORIA.md",
"03_Conocimiento\01_Memoria\MAPA_CONTEXTO.md"
)

$Areas["Investigacion"] = @(
"03_Conocimiento\02_Investigacion\METODOLOGIA_INVESTIGACION.md",
"03_Conocimiento\02_Investigacion\VALIDACION_FUENTES.md"
)

$Areas["Informes"] = @(
"03_Conocimiento\03_Informes\CATALOGO_INFORMES.md"
)

$Areas["Programacion"] = @(
"03_Conocimiento\04_Programacion\ESTANDARES_CODIGO.md"
)

$Areas["Seguridad"] = @(
"03_Conocimiento\05_Seguridad\POLITICA_SEGURIDAD.md"
)

$Areas["Automatizacion"] = @(
"03_Conocimiento\06_Automatizacion\README.md"
)

$Areas["Creatividad"] = @(
"03_Conocimiento\07_Creatividad\README.md"
)

$Areas["Marketing"] = @(
"03_Conocimiento\08_Marketing\README.md"
)

$Areas["Normativas"] = @(
"03_Conocimiento\09_Normativas\README.md"
)

$Areas["Prompts"] = @(
"03_Conocimiento\10_Prompts\PROMPT_INVESTIGACION.md",
"03_Conocimiento\10_Prompts\PROMPT_PROGRAMACION.md",
"03_Conocimiento\10_Prompts\PROMPT_INFORMES.md"
)

$Areas["Skills"] = @(
"03_Conocimiento\11_Skills\SKILL_INVESTIGACION.md",
"03_Conocimiento\11_Skills\SKILL_GENERACION_INFORMES.md"
)

$Areas["Procedimientos"] = @(
"03_Conocimiento\12_Procedimientos\PROCEDIMIENTO_DOCUMENTACION.md",
"03_Conocimiento\12_Procedimientos\PROCEDIMIENTO_INVESTIGACION.md"
)

$Areas["Lecciones"] = @(
"03_Conocimiento\13_Lecciones_Aprendidas\README.md"
)

$Areas["Decisiones"] = @(
"03_Conocimiento\14_Decisiones_Tecnicas\README.md"
)

$Areas["CasosReales"] = @(
"03_Conocimiento\15_Casos_Reales\README.md"
)

# ==========================================
# EVALUAR
# ==========================================

$Resultados = @()
$TotalGeneral = 0

foreach($Area in $Areas.Keys)
{
    $Total = $Areas[$Area].Count
    $OK = 0

    foreach($File in $Areas[$Area])
    {
        if(Test-SyntecFile $File)
        {
            $OK++
        }
    }

    $ScoreArea = Score $OK $Total

    $Resultados += [PSCustomObject]@{
        Area = $Area
        Porcentaje = $ScoreArea
    }

    $TotalGeneral += $ScoreArea
}

$MadurezGlobal =
[math]::Round(
$TotalGeneral / $Resultados.Count
)

# ==========================================
# REPORTE
# ==========================================

$Contenido = @()

$Contenido += "# MADUREZ COPILOT EMPRESARIAL"
$Contenido += ""
$Contenido += "Fecha: $(Get-Date)"
$Contenido += ""

foreach($Item in $Resultados)
{
    $Contenido += "## $($Item.Area)"
    $Contenido += ""
    $Contenido += "$($Item.Porcentaje)%"
    $Contenido += ""
}

$Contenido += "# MADUREZ GLOBAL"
$Contenido += ""
$Contenido += "$MadurezGlobal%"
$Contenido += ""

$Contenido |
Set-Content `
$Reporte `
-Encoding UTF8

# ==========================================
# CONSOLA
# ==========================================

Write-Host ""

foreach($Item in $Resultados)
{
    Write-Host `
    ($Item.Area.PadRight(20) + ": " + $Item.Porcentaje + "%")
}

Write-Host ""
Write-Host "MADUREZ GLOBAL: $MadurezGlobal%" `
-ForegroundColor Cyan
Write-Host ""

Write-Host $Reporte `
-ForegroundColor Yellow