# ==========================================
# Auditoria Ecosistema Copilot Empresarial
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte =
Join-Path `
$Base `
"00_Admin\Dashboards\MADUREZ_ECOSISTEMA.md"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Auditoria Ecosistema"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# FUNCIONES
# ==========================================

function Test-EcoFile {
    param([string]$RelativePath)

    $Path = Join-Path $Base $RelativePath

    return (Test-Path $Path)
}

function Get-Score {

    param(
        [int]$Current,
        [int]$Total
    )

    if ($Total -eq 0) {
        return 0
    }

    return [math]::Round(($Current / $Total) * 100)
}

# ==========================================
# DEFINICION DE AREAS
# ==========================================

$Areas = @{}

# INFRAESTRUCTURA

$Areas["Infraestructura"] = @(
"15_Scripts\Auditoria-Syntec.ps1",
"15_Scripts\Auditoria-Madurez.ps1",
"15_Scripts\Auditoria-Copilot-Empresarial.ps1",
"15_Scripts\Bootstrap-Copilot-Empresarial.ps1",
"15_Scripts\Bootstrap-Conectores-Copilot.ps1",
"15_Scripts\Bootstrap-Agentes-Copilot.ps1"
)

# COPILOT EMPRESARIAL

$Areas["Copilot"] = @(
"03_Conocimiento\00_Estrategia_Copilot\VISION_GENERAL.md",
"03_Conocimiento\01_Memoria\ESTRATEGIA_MEMORIA.md",
"03_Conocimiento\02_Investigacion\METODOLOGIA_INVESTIGACION.md",
"03_Conocimiento\03_Informes\CATALOGO_INFORMES.md",
"03_Conocimiento\04_Programacion\ESTANDARES_CODIGO.md",
"03_Conocimiento\05_Seguridad\POLITICA_SEGURIDAD.md"
)

# CONECTORES

$Areas["Conectores"] = @(
"03_Conocimiento\16_Conectores\GitHub\GITHUB_CONECTOR.md",
"03_Conocimiento\16_Conectores\ClaudeMem\CLAUDEMEM_CONECTOR.md",
"03_Conocimiento\16_Conectores\Headroom\HEADROOM_CONECTOR.md",
"03_Conocimiento\16_Conectores\OmniRoute\OMNIROUTE_CONECTOR.md",
"03_Conocimiento\16_Conectores\TaskObserver\TASKOBSERVER_CONECTOR.md"
)

# AGENTES

$Areas["Agentes"] = @(
"03_Conocimiento\17_Agentes\00_Coordinador\AGENTE_COORDINADOR.md",
"03_Conocimiento\17_Agentes\01_Memoria\AGENTE_MEMORIA.md",
"03_Conocimiento\17_Agentes\02_Investigacion\AGENTE_INVESTIGACION.md",
"03_Conocimiento\17_Agentes\03_Documentacion\AGENTE_DOCUMENTACION.md",
"03_Conocimiento\17_Agentes\11_Observador\AGENTE_OBSERVADOR.md"
)

# SEGURIDAD

$Areas["Seguridad"] = @(
"07_Seguridad\PLAN_SEGURIDAD.md",
"03_Conocimiento\05_Seguridad\POLITICA_SEGURIDAD.md",
"03_Conocimiento\16_Conectores\Semgrep\SEMGREP_CONECTOR.md",
"03_Conocimiento\16_Conectores\CodeQL\CODEQL_CONECTOR.md"
)

# AUTOMATIZACION

$Areas["Automatizacion"] = @(
"03_Conocimiento\06_Automatizacion\README.md",
"03_Conocimiento\06_Automatizacion\ESTRATEGIA_AUTOMATIZACION.md",
"03_Conocimiento\06_Automatizacion\FLUJOS.md",
"03_Conocimiento\06_Automatizacion\INTEGRACIONES.md"
)

# GOBIERNO

$Areas["Gobierno"] = @(
"03_Conocimiento\00_Estrategia_Copilot\REGLAS_ARQUITECTURA.md",
"03_Conocimiento\17_Agentes\REGLAS_AGENTES.md",
"00_Admin\Gobierno\CHECKLIST_DECISIONES.md"
)

# NORMATIVAS

$Areas["Normativas"] = @(
"03_Conocimiento\09_Normativas\README.md",
"03_Conocimiento\09_Normativas\INDICE_NORMATIVAS.md",
"03_Conocimiento\09_Normativas\MATRIZ_APLICABILIDAD.md",
"03_Conocimiento\09_Normativas\GLOSARIO_NORMATIVO.md"
)

# CONOCIMIENTO

$Areas["Conocimiento"] = @(
"03_Conocimiento\13_Lecciones_Aprendidas\README.md",
"03_Conocimiento\14_Decisiones_Tecnicas\README.md",
"03_Conocimiento\15_Casos_Reales\README.md"
)

# ==========================================
# EVALUACION
# ==========================================

$Resultados = @()

$SumaGlobal = 0

$Riesgos = @()

foreach($Area in $Areas.Keys)
{
    $Total = $Areas[$Area].Count
    $OK = 0

    foreach($Item in $Areas[$Area])
    {
        if(Test-EcoFile $Item)
        {
            $OK++
        }
        else
        {
            $Riesgos += "$Area -> Falta: $Item"
        }
    }

    $Score = Get-Score $OK $Total

    $Resultados += [PSCustomObject]@{
        Area = $Area
        Score = $Score
    }

    $SumaGlobal += $Score
}

$MadurezGlobal =
[math]::Round(
    $SumaGlobal / $Resultados.Count
)

# ==========================================
# REPORTE
# ==========================================

$Out = @()

$Out += "# MADUREZ ECOSISTEMA"
$Out += ""
$Out += "Fecha: $(Get-Date)"
$Out += ""

foreach($R in $Resultados)
{
    $Out += "## $($R.Area)"
    $Out += "$($R.Score)%"
    $Out += ""
}

$Out += "# MADUREZ GLOBAL"
$Out += ""
$Out += "$MadurezGlobal%"
$Out += ""

$Out += "# RIESGOS DETECTADOS"
$Out += ""

if($Riesgos.Count -eq 0)
{
    $Out += "Sin riesgos detectados."
}
else
{
    foreach($R in $Riesgos)
    {
        $Out += "- $R"
    }
}

$Out += ""
$Out += "# PROXIMAS ACCIONES"
$Out += ""

if($MadurezGlobal -lt 70)
{
    $Out += "- Completar bibliotecas faltantes."
}

if($MadurezGlobal -ge 70 -and $MadurezGlobal -lt 90)
{
    $Out += "- Consolidar conectores y agentes."
}

if($MadurezGlobal -ge 90)
{
    $Out += "- Preparar integraciones reales (Claude-Mem, Headroom, OmniRoute)."
}

$Out |
Set-Content `
$Reporte `
-Encoding UTF8

# ==========================================
# CONSOLA
# ==========================================

Write-Host ""

foreach($R in $Resultados)
{
    Write-Host ($R.Area.PadRight(20) + ": " + $R.Score + "%")
}

Write-Host ""
Write-Host "MADUREZ GLOBAL: $MadurezGlobal%" `
-ForegroundColor Cyan

Write-Host ""
Write-Host $Reporte `
-ForegroundColor Yellow

Write-Host ""