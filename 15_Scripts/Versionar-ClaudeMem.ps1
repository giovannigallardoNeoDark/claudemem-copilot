#Requires -Version 5.1

<#
.SYNOPSIS
    Versionado y restauracion controlada de ClaudeMem.

.DESCRIPTION
    Usa los manifest.json fisicos como fuente primaria.
    historial.json es un indice derivado que se reconstruye automaticamente.

    Sin parametros crea una nueva version.
    -ListarVersiones lista manifiestos validos.
    -RestaurarVersion restaura una version despues de crear un respaldo.

.VERSION
    2.0.0
#>

[CmdletBinding(DefaultParameterSetName = "Crear")]
param(
    [Parameter(ParameterSetName = "Restaurar", Mandatory = $true)]
    [ValidatePattern('^VER-\d{8}-\d{6}$')]
    [string]$RestaurarVersion,

    [Parameter(ParameterSetName = "Listar", Mandatory = $true)]
    [switch]$ListarVersiones
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$VersionsFolder = Join-Path $ClaudeMemRoot "versions"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$HistorialFile = Join-Path $VersionsFolder "historial.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$ArchivosObjetivo = @(
    [PSCustomObject]@{ Relativa = "data\decisiones.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "data\lecciones.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "data\hallazgos.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "data\tags.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "data\relaciones.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "index\index.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "config\config.json"; Critico = $true },
    [PSCustomObject]@{ Relativa = "estado.json"; Critico = $true }
)

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Escribir-Log {
    param([Parameter(Mandatory = $true)][string]$Mensaje)
    Crear-Carpeta -Ruta $LogsFolder
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
    }
    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - VERSIONADO V2: $Mensaje" -Encoding UTF8
}

function Obtener-Hash {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    return (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Validar-Json {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if ([System.IO.Path]::GetExtension($Ruta) -eq ".json") {
        $Texto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
        $null = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    }
}

function Escribir-JsonSeguro {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Datos,
        [switch]$ComoArreglo
    )

    $Temporal = "$Ruta.tmp"
    if ($ComoArreglo) {
        $Json = ConvertTo-Json -InputObject ([object[]]@($Datos)) -Depth 40
    }
    else {
        $Json = ConvertTo-Json -InputObject $Datos -Depth 40
    }

    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $Prueba = [System.IO.File]::ReadAllText($Temporal)
    $null = ConvertFrom-Json -InputObject $Prueba -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Obtener-ManifiestosValidos {
    $Salida = @()
    if (-not (Test-Path -LiteralPath $VersionsFolder -PathType Container)) {
        return $Salida
    }

    $Carpetas = @(Get-ChildItem -LiteralPath $VersionsFolder -Directory -Filter "VER-*" -ErrorAction SilentlyContinue)
    foreach ($Carpeta in $Carpetas) {
        $RutaManifest = Join-Path $Carpeta.FullName "manifest.json"
        if (-not (Test-Path -LiteralPath $RutaManifest -PathType Leaf)) { continue }

        try {
            $Texto = Get-Content -LiteralPath $RutaManifest -Raw -ErrorAction Stop
            $Manifest = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
            if ([string]$Manifest.id -ne $Carpeta.Name) { continue }
            if ([string]$Manifest.estado -ne "VALIDA") { continue }
            $Archivos = @($Manifest.archivos)
            if ($Archivos.Count -eq 0) { continue }

            $Integridad = $true
            foreach ($Archivo in $Archivos) {
                $Snapshot = Join-Path $Carpeta.FullName ("snapshot\" + [string]$Archivo.rutaRelativa)
                if (-not (Test-Path -LiteralPath $Snapshot -PathType Leaf)) {
                    $Integridad = $false
                    break
                }
                if ((Obtener-Hash -Ruta $Snapshot) -ne [string]$Archivo.sha256) {
                    $Integridad = $false
                    break
                }
            }
            if (-not $Integridad) { continue }

            $Salida += [PSCustomObject]@{
                Carpeta = $Carpeta.FullName
                Manifest = $Manifest
            }
        }
        catch {
            Escribir-Log "MANIFIESTO IGNORADO: $RutaManifest; $($_.Exception.Message)"
        }
    }

    return @($Salida | Sort-Object { [string]$_.Manifest.fechaCreacion })
}

function Reconstruir-HistorialDerivado {
    param([Parameter(Mandatory = $true)][array]$Manifiestos)

    $Registros = @()
    foreach ($Entrada in $Manifiestos) {
        $M = $Entrada.Manifest
        $Archivos = @($M.archivos)
        $Registros += [PSCustomObject][ordered]@{
            id = [string]$M.id
            fechaCreacion = [string]$M.fechaCreacion
            versionAnterior = $M.versionAnterior
            archivos = $Archivos.Count
            modificados = [int]$M.resumen.modificados
            nuevos = [int]$M.resumen.nuevos
            sinCambios = [int]$M.resumen.sinCambios
            estado = [string]$M.estado
            manifest = "$([string]$M.id)\manifest.json"
        }
    }

    Escribir-JsonSeguro -Ruta $HistorialFile -Datos $Registros -ComoArreglo
    return $Registros
}

function Mostrar-Versiones {
    $Manifiestos = @(Obtener-ManifiestosValidos)
    $Historial = @(Reconstruir-HistorialDerivado -Manifiestos $Manifiestos)

    Write-Host ""
    Write-Host "VERSIONES CLAUDEMEM" -ForegroundColor Cyan
    Write-Host ""
    if ($Historial.Count -eq 0) {
        Write-Host "No existen versiones validas." -ForegroundColor Yellow
        return
    }

    $Historial | Sort-Object fechaCreacion -Descending |
        Format-Table id, fechaCreacion, archivos, modificados, nuevos, sinCambios, estado -AutoSize
}

function Crear-RespaldoPreRestauracion {
    param([Parameter(Mandatory = $true)][string]$IdVersion)

    Crear-Carpeta -Ruta $BackupsFolder
    $Backup = Join-Path $BackupsFolder "pre-restauracion-$IdVersion-$MarcaTiempo.zip"
    $Elementos = @()
    foreach ($Objetivo in $ArchivosObjetivo) {
        $Ruta = Join-Path $ClaudeMemRoot $Objetivo.Relativa
        if (Test-Path -LiteralPath $Ruta -PathType Leaf) { $Elementos += $Ruta }
    }
    if ($Elementos.Count -eq 0) { throw "No existen archivos actuales para respaldar." }

    Compress-Archive -LiteralPath $Elementos -DestinationPath $Backup -CompressionLevel Optimal -Force
    if (-not (Test-Path -LiteralPath $Backup -PathType Leaf)) { throw "No se creo el respaldo previo." }
    if ((Get-Item -LiteralPath $Backup).Length -le 0) { throw "El respaldo previo esta vacio." }
    return $Backup
}

function Restaurar-Version {
    param([Parameter(Mandatory = $true)][string]$IdVersion)

    $Manifiestos = @(Obtener-ManifiestosValidos)
    $Coincidencias = @($Manifiestos | Where-Object { [string]$_.Manifest.id -eq $IdVersion })
    if ($Coincidencias.Count -ne 1) { throw "La version '$IdVersion' no existe o no es valida." }

    $Entrada = $Coincidencias[0]
    $Manifest = $Entrada.Manifest
    $Backup = Crear-RespaldoPreRestauracion -IdVersion $IdVersion

    Write-Host ""
    Write-Host "Respaldo previo creado:" -ForegroundColor Green
    Write-Host $Backup
    Write-Host ""

    $Restaurados = 0
    foreach ($Archivo in @($Manifest.archivos)) {
        $Relativa = [string]$Archivo.rutaRelativa
        $Origen = Join-Path $Entrada.Carpeta ("snapshot\" + $Relativa)
        $Destino = Join-Path $ClaudeMemRoot $Relativa
        Validar-Json -Ruta $Origen
        Crear-Carpeta -Ruta (Split-Path -Parent $Destino)
        Copy-Item -LiteralPath $Origen -Destination $Destino -Force
        if ((Obtener-Hash -Ruta $Destino) -ne [string]$Archivo.sha256) {
            throw "Fallo la verificacion posterior para '$Relativa'."
        }
        $Restaurados++
    }

    Escribir-Log "VERSION RESTAURADA: $IdVersion; archivos=$Restaurados; backup=$Backup"
    Write-Host "Restauracion completada correctamente." -ForegroundColor Green
    Write-Host "Archivos restaurados: $Restaurados"
}

function Crear-Version {
    Crear-Carpeta -Ruta $VersionsFolder
    Crear-Carpeta -Ruta $ReportsFolder
    Crear-Carpeta -Ruta $LogsFolder

    $VersionId = "VER-$MarcaTiempo"
    $VersionFolder = Join-Path $VersionsFolder $VersionId
    $SnapshotFolder = Join-Path $VersionFolder "snapshot"
    $ManifestFile = Join-Path $VersionFolder "manifest.json"
    $ReportFile = Join-Path $ReportsFolder "Reporte-Versionado-ClaudeMem-$MarcaTiempo.txt"
    Crear-Carpeta -Ruta $SnapshotFolder

    $Anteriores = @(Obtener-ManifiestosValidos)
    $Anterior = $null
    $MapaAnterior = @{}
    if ($Anteriores.Count -gt 0) {
        $Anterior = $Anteriores[-1].Manifest
        foreach ($Archivo in @($Anterior.archivos)) {
            $MapaAnterior[[string]$Archivo.rutaRelativa] = [string]$Archivo.sha256
        }
    }

    $ArchivosManifest = @()
    $Nuevos = 0
    $Modificados = 0
    $SinCambios = 0

    foreach ($Objetivo in $ArchivosObjetivo) {
        $Relativa = [string]$Objetivo.Relativa
        $Origen = Join-Path $ClaudeMemRoot $Relativa
        if (-not (Test-Path -LiteralPath $Origen -PathType Leaf)) {
            if ([bool]$Objetivo.Critico) { throw "Falta archivo critico: $Relativa" }
            continue
        }

        Validar-Json -Ruta $Origen
        $Hash = Obtener-Hash -Ruta $Origen
        $Destino = Join-Path $SnapshotFolder $Relativa
        Crear-Carpeta -Ruta (Split-Path -Parent $Destino)
        Copy-Item -LiteralPath $Origen -Destination $Destino -Force
        if ((Obtener-Hash -Ruta $Destino) -ne $Hash) { throw "La copia no coincide: $Relativa" }

        $Cambio = "Nuevo"
        if ($MapaAnterior.ContainsKey($Relativa)) {
            if ($MapaAnterior[$Relativa] -eq $Hash) {
                $Cambio = "SinCambio"
                $SinCambios++
            }
            else {
                $Cambio = "Modificado"
                $Modificados++
            }
        }
        else { $Nuevos++ }

        $ArchivosManifest += [PSCustomObject][ordered]@{
            rutaRelativa = $Relativa
            sha256 = $Hash
            tamanoBytes = (Get-Item -LiteralPath $Origen).Length
            cambio = $Cambio
        }
    }

    $Manifest = [PSCustomObject][ordered]@{
        id = $VersionId
        fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        versionAnterior = $(if ($null -eq $Anterior) { $null } else { [string]$Anterior.id })
        algoritmoHash = "SHA256"
        archivos = @($ArchivosManifest)
        resumen = [PSCustomObject][ordered]@{
            total = $ArchivosManifest.Count
            nuevos = $Nuevos
            modificados = $Modificados
            sinCambios = $SinCambios
        }
        estado = "VALIDA"
    }

    Escribir-JsonSeguro -Ruta $ManifestFile -Datos $Manifest
    $Actualizados = @(Obtener-ManifiestosValidos)
    $Historial = @(Reconstruir-HistorialDerivado -Manifiestos $Actualizados)
    $Registrada = @($Historial | Where-Object { [string]$_.id -eq $VersionId }).Count -eq 1
    if (-not $Registrada) { throw "La version no quedo registrada en el historial derivado." }

    $Lineas = @(
        "REPORTE DE VERSIONADO CLAUDEMEM V2"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Version: $VersionId"
        "Archivos: $($ArchivosManifest.Count)"
        "Nuevos: $Nuevos"
        "Modificados: $Modificados"
        "Sin cambios: $SinCambios"
        "Estado: APROBADO"
    )
    $Lineas | Set-Content -LiteralPath $ReportFile -Encoding UTF8
    Escribir-Log "VERSION CREADA: $VersionId; nuevos=$Nuevos; modificados=$Modificados; sinCambios=$SinCambios"

    Write-Host ""
    Write-Host "VERSION CREADA" -ForegroundColor Green
    Write-Host "Version: $VersionId"
    Write-Host "Archivos: $($ArchivosManifest.Count)"
    Write-Host "Nuevos: $Nuevos"
    Write-Host "Modificados: $Modificados"
    Write-Host "Sin cambios: $SinCambios"
    Write-Host "Estado: APROBADO"
    Write-Host ""
    Write-Host "Version guardada en:"
    Write-Host $VersionFolder
    Write-Host "Informe:"
    Write-Host $ReportFile
}

Crear-Carpeta -Ruta $VersionsFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder

try {
    switch ($PSCmdlet.ParameterSetName) {
        "Listar" { Mostrar-Versiones }
        "Restaurar" { Restaurar-Version -IdVersion $RestaurarVersion }
        default { Crear-Version }
    }
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "ERROR DE VERSIONADO" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
