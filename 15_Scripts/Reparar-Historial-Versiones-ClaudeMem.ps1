#Requires -Version 5.1

<#
.SYNOPSIS
    Reconstruye versions\historial.json desde los manifest.json existentes.

.DESCRIPTION
    Compatible con Windows PowerShell 5.1. Respalda el historial actual,
    valida cada carpeta VER-* y su manifest.json, reconstruye un registro por
    version y comprueba IDs, cantidad de versiones y propiedades obligatorias.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$VersionsFolder = Join-Path $ClaudeMemRoot "versions"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$HistorialFile = Join-Path $VersionsFolder "historial.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupFile = Join-Path $BackupsFolder "historial-antes-reconstruccion-$MarcaTiempo.json"

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Escribir-Log {
    param([Parameter(Mandatory = $true)][string]$Mensaje)
    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - HISTORIAL: $Mensaje" -Encoding UTF8
}

function Convertir-AListaPlana {
    param([AllowNull()][object]$Valor)

    $Salida = @()
    if ($null -eq $Valor) { return $Salida }

    if ($Valor -is [System.Array]) {
        foreach ($Elemento in $Valor) {
            if ($null -ne $Elemento) { $Salida += $Elemento }
        }
    }
    else {
        $Salida += $Valor
    }

    return $Salida
}

function Guardar-HistorialSeguro {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][array]$Registros
    )

    $Temporal = "$Ruta.tmp"
    $Json = [System.Management.Automation.PSSerializer]::Serialize($Registros)
    $null = $Json

    # InputObject conserva el arreglo JSON sin canalizar sus elementos por separado.
    ConvertTo-Json -InputObject ([object[]]$Registros) -Depth 30 |
        Set-Content -LiteralPath $Temporal -Encoding UTF8

    $Texto = Get-Content -LiteralPath $Temporal -Raw -ErrorAction Stop
    $Convertido = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    $Validado = Convertir-AListaPlana -Valor $Convertido

    if ($Validado.Count -ne $Registros.Count) {
        Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
        throw "El archivo temporal contiene $($Validado.Count) registros; se esperaban $($Registros.Count)."
    }

    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " RECONSTRUIR HISTORIAL DE VERSIONES CLAUDEMEM" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

Crear-Carpeta -Ruta $VersionsFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $LogsFolder

if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

if (Test-Path -LiteralPath $HistorialFile -PathType Leaf) {
    Copy-Item -LiteralPath $HistorialFile -Destination $BackupFile -Force
    Write-Host "Respaldo creado:" -ForegroundColor Green
    Write-Host $BackupFile
    Write-Host ""
}

try {
    $CarpetasVersion = @(
        Get-ChildItem -LiteralPath $VersionsFolder -Directory -Filter "VER-*" |
            Sort-Object Name
    )

    if ($CarpetasVersion.Count -eq 0) {
        throw "No se encontraron carpetas VER-* en $VersionsFolder"
    }

    $Registros = @()

    foreach ($Carpeta in $CarpetasVersion) {
        $ManifestFile = Join-Path $Carpeta.FullName "manifest.json"
        if (-not (Test-Path -LiteralPath $ManifestFile -PathType Leaf)) {
            throw "Falta manifest.json en $($Carpeta.Name)"
        }

        $ManifestTexto = Get-Content -LiteralPath $ManifestFile -Raw -ErrorAction Stop
        $Manifest = ConvertFrom-Json -InputObject $ManifestTexto -ErrorAction Stop

        if ([string]$Manifest.id -ne $Carpeta.Name) {
            throw "El ID del manifiesto no coincide con la carpeta: $($Carpeta.Name)"
        }

        $Archivos = Convertir-AListaPlana -Valor $Manifest.archivos
        $Resumen = $Manifest.resumen

        $Registros += [PSCustomObject][ordered]@{
            id = [string]$Manifest.id
            fechaCreacion = [string]$Manifest.fechaCreacion
            versionAnterior = $Manifest.versionAnterior
            archivos = [int]$Archivos.Count
            modificados = [int]$Resumen.modificados
            nuevos = [int]$Resumen.nuevos
            sinCambios = [int]$Resumen.sinCambios
            estado = [string]$Manifest.estado
            manifest = "$($Carpeta.Name)\manifest.json"
        }
    }

    $Duplicados = @($Registros | Group-Object id | Where-Object Count -gt 1)
    if ($Duplicados.Count -gt 0) {
        throw "Se detectaron IDs duplicados en los manifiestos."
    }

    $RegistrosOrdenados = @($Registros | Sort-Object fechaCreacion)
    Guardar-HistorialSeguro -Ruta $HistorialFile -Registros $RegistrosOrdenados

    $TextoFinal = Get-Content -LiteralPath $HistorialFile -Raw -ErrorAction Stop
    $ObjetoFinal = ConvertFrom-Json -InputObject $TextoFinal -ErrorAction Stop
    $Validacion = Convertir-AListaPlana -Valor $ObjetoFinal

    $IdsVacios = @($Validacion | Where-Object {
        $null -eq $_.id -or ([string]$_.id).Trim().Length -eq 0
    })

    if ($Validacion.Count -ne $CarpetasVersion.Count -or $IdsVacios.Count -gt 0) {
        throw "La validacion final no coincide con las carpetas de versiones."
    }

    Escribir-Log "HISTORIAL RECONSTRUIDO: $($Validacion.Count) versiones"

    Write-Host "HISTORIAL RECONSTRUIDO" -ForegroundColor Green
    Write-Host "Versiones registradas: $($Validacion.Count)"
    Write-Host ""

    $Validacion |
        Sort-Object fechaCreacion -Descending |
        Select-Object id, fechaCreacion, archivos, modificados, nuevos, sinCambios, estado |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "VERIFICACION APROBADA" -ForegroundColor Green
    Write-Host "Historial: $HistorialFile"
    Write-Host ""
}
catch {
    if (Test-Path -LiteralPath $BackupFile -PathType Leaf) {
        Copy-Item -LiteralPath $BackupFile -Destination $HistorialFile -Force
        Write-Host "Se restauro el historial anterior." -ForegroundColor Yellow
    }

    Escribir-Log "ERROR AL RECONSTRUIR: $($_.Exception.Message)"
    Write-Host "La reconstruccion fallo:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
