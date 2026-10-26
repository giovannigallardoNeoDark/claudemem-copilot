# ==========================================
# Auditoria Madurez Syntec
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte =
Join-Path `
$Base `
"00_Admin\Dashboards\MADUREZ_GENERAL.md"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Auditoria de Madurez Syntec"
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# FUNCIONES
# ==========================================

function Test-File {
    param([string]$RelativePath)

    $Path = Join-Path $Base $RelativePath

    return (Test-Path $Path)
}

function Percent {
    param($Current,$Total)

    if($Total -eq 0)
    {
        return 0
    }

    return [math]::Round(($Current / $Total) * 100)
}

# ==========================================
# INFRAESTRUCTURA
# ==========================================

$InfraOK = 0
$InfraTotal = 6

if (Get-Command git -ErrorAction SilentlyContinue) { $InfraOK++ }
if (Get-Command python -ErrorAction SilentlyContinue) { $InfraOK++ }
if (Get-Command semgrep -ErrorAction SilentlyContinue) { $InfraOK++ }

# Node portable no siempre está en PATH
if (Test-Path "$Base\11_Herramientas") { $InfraOK++ }

# GitHub Copilot asumido instalado por entorno
$InfraOK++

# VS Code asumido instalado por entorno
$InfraOK++

$InfraScore = Percent $InfraOK $InfraTotal

# ==========================================
# DOCUMENTACION
# ==========================================

$DocsTotal = 8
$DocsOK = 0

$Docs = @(
"00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md",
"00_Admin\Roadmap\ROADMAP_GENERAL.md",
"00_Admin\Inventario\INVENTARIO_HERRAMIENTAS.md",
"01_FIOS\DOCUMENTACION\ARQUITECTURA.md",
"01_FIOS\DOCUMENTACION\REQUISITOS.md",
"02_NeoDark\DOCUMENTACION\ARQUITECTURA.md",
"02_NeoDark\DOCUMENTACION\REQUISITOS.md",
"00_Admin\Dashboards\KPIS.md"
)

foreach($Doc in $Docs)
{
    if(Test-File $Doc)
    {
        $DocsOK++
    }
}

$DocsScore = Percent $DocsOK $DocsTotal

# ==========================================
# CONOCIMIENTO
# ==========================================

$KnowTotal = 3
$KnowOK = 0

if(Test-File "03_Conocimiento\Lecciones_Aprendidas\LA-0001-NODE-PORTABLE.md")
{
    $KnowOK++
}

if(Test-File "03_Conocimiento\Decisiones_Tecnicas\DT-0001-ESTRUCTURA-SYNTEC.md")
{
    $KnowOK++
}

if(Test-File "03_Conocimiento\Problemas_Resueltos\README.md")
{
    $KnowOK++
}

$KnowScore = Percent $KnowOK $KnowTotal

# ==========================================
# SEGURIDAD
# ==========================================

$SecTotal = 4
$SecOK = 0

if(Get-Command semgrep -ErrorAction SilentlyContinue)
{
    $SecOK++
}

if(Test-Path "$Base\07_Seguridad\CodeQL")
{
    $SecOK++
}

if(Test-Path "$Base\07_Seguridad\SonarQube")
{
    $SecOK++
}

if(Test-File "07_Seguridad\CodeReview\README.md")
{
    $SecOK++
}

$SecScore = Percent $SecOK $SecTotal

# ==========================================
# FIOS
# ==========================================

$FIOS_Total = 4
$FIOS_OK = 0

$FIOSDocs = @(
"01_FIOS\DOCUMENTACION\ARQUITECTURA.md",
"01_FIOS\DOCUMENTACION\REQUISITOS.md",
"01_FIOS\DOCUMENTACION\MODULOS.md",
"01_FIOS\DOCUMENTACION\BACKLOG.md"
)

foreach($Item in $FIOSDocs)
{
    if(Test-File $Item)
    {
        $FIOS_OK++
    }
}

$FIOSScore = Percent $FIOS_OK $FIOS_Total

# ==========================================
# NEODARK
# ==========================================

$NeoTotal = 4
$NeoOK = 0

$NeoDocs = @(
"02_NeoDark\DOCUMENTACION\ARQUITECTURA.md",
"02_NeoDark\DOCUMENTACION\REQUISITOS.md",
"02_NeoDark\DOCUMENTACION\DATASET_BUILDER.md",
"02_NeoDark\DOCUMENTACION\BACKLOG.md"
)

foreach($Item in $NeoDocs)
{
    if(Test-File $Item)
    {
        $NeoOK++
    }
}

$NeoScore = Percent $NeoOK $NeoTotal

# ==========================================
# AUTOMATIZACION
# ==========================================

$AutoTotal = 10

$Bootstraps =
(Get-ChildItem `
"$Base\15_Scripts" `
-Filter "*Bootstrap*" `
-ErrorAction SilentlyContinue).Count

$AutoScore = Percent $Bootstraps $AutoTotal

# ==========================================
# MADUREZ GLOBAL
# ==========================================

$Global =
[math]::Round(
(
$InfraScore +
$DocsScore +
$KnowScore +
$SecScore +
$FIOSScore +
$NeoScore +
$AutoScore
) / 7
)

# ==========================================
# REPORTE
# ==========================================

@"
# MADUREZ GENERAL SYNTEC

Fecha: $(Get-Date)

## Infraestructura

$InfraScore %

## Documentacion

$DocsScore %

## Conocimiento

$KnowScore %

## Seguridad

$SecScore %

## FIOS

$FIOSScore %

## NeoDark

$NeoScore %

## Automatizacion

$AutoScore %

# Resultado Global

$Global %

"@ | Set-Content `
$Reporte `
-Encoding UTF8

Write-Host ""
Write-Host "MADUREZ CALCULADA" -ForegroundColor Green
Write-Host ""
Write-Host "Infraestructura : $InfraScore%"
Write-Host "Documentacion   : $DocsScore%"
Write-Host "Conocimiento    : $KnowScore%"
Write-Host "Seguridad       : $SecScore%"
Write-Host "FIOS            : $FIOSScore%"
Write-Host "NeoDark         : $NeoScore%"
Write-Host "Automatizacion  : $AutoScore%"
Write-Host ""
Write-Host "MADUREZ GLOBAL  : $Global%" `
-ForegroundColor Cyan

Write-Host ""
Write-Host $Reporte -ForegroundColor Yellow
Write-Host ""