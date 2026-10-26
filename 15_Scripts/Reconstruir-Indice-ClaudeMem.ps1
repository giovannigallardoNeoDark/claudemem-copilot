#Requires -Version 5.1

<#
.SYNOPSIS
    Reconstruye el indice principal de ClaudeMem.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMem = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"

$DataFolder = Join-Path $ClaudeMem "data"
$IndexFolder = Join-Path $ClaudeMem "index"
$LogsFolder = Join-Path $ClaudeMem "logs"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"

$IndexFile = Join-Path $IndexFolder "index.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"

function Crear-Carpeta {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Leer-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw

    if ([string]::IsNullOrWhiteSpace($Contenido)) {
        return @()
    }

    return @($Contenido | ConvertFrom-Json)
}

function Escribir-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje
    )

    $Linea = "{0} - {1}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), `
        $Mensaje

    Add-Content `
        -LiteralPath $LogFile `
        -Value $Linea `
        -Encoding UTF8
}

Crear-Carpeta -Ruta $IndexFolder
Crear-Carpeta -Ruta $LogsFolder

if (-not (Test-Path -LiteralPath $LogFile)) {
    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force |
    Out-Null
}

$Indice = [ordered]@{}

$Fuentes = @(
    @{
        Ruta = $DecisionesFile
        Tipo = "decision"
    },
    @{
        Ruta = $LeccionesFile
        Tipo = "leccion"
    },
    @{
        Ruta = $HallazgosFile
        Tipo = "hallazgo"
    }
)

try {
    foreach ($Fuente in $Fuentes) {
        $Registros = @(Leer-JsonArray -Ruta $Fuente.Ruta)

        foreach ($Registro in $Registros) {
            if ($Registro.id) {
                $Id = [string]$Registro.id

                if ($Indice.Contains($Id)) {
                    throw "ID duplicado detectado: $Id"
                }

                $Indice[$Id] = $Fuente.Tipo
            }
        }
    }

    $Temporal = "$IndexFile.tmp"

    $Indice |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $IndexFile `
        -Force

    Escribir-Log "INDICE RECONSTRUIDO: $($Indice.Count) entradas"

    Write-Host ""
    Write-Host "Indice reconstruido correctamente." -ForegroundColor Green
    Write-Host "Entradas: $($Indice.Count)"
    Write-Host "Archivo: $IndexFile"
    Write-Host ""

    Get-Content `
        -LiteralPath $IndexFile `
        -Raw
}
catch {
    Escribir-Log "ERROR INDICE: $($_.Exception.Message)"

    Write-Host ""
    Write-Host "No se pudo reconstruir el indice." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}
