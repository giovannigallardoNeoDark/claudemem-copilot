#Requires -Version 5.1

<#+
.SYNOPSIS
    Versiona y restaura de forma controlada los datos de ClaudeMem.

.DESCRIPTION
    Sin parametros crea una instantanea versionada de los archivos criticos,
    calcula SHA-256, compara con la version anterior, genera manifiesto,
    actualiza historial.json y produce un informe PASS/FAIL.

    Con -ListarVersiones muestra el historial disponible.

    Con -RestaurarVersion <ID> crea primero un respaldo de seguridad y luego
    restaura los archivos incluidos en la version solicitada.

.EXAMPLE
    .\Versionar-ClaudeMem.ps1

.EXAMPLE
    .\Versionar-ClaudeMem.ps1 -ListarVersiones

.EXAMPLE
    .\Versionar-ClaudeMem.ps1 -RestaurarVersion "VER-20261021-210000"

.VERSION
    1.1.0
#>

[CmdletBinding(DefaultParameterSetName = "Crear")]
param(
    [Parameter(ParameterSetName = "Restaurar", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$RestaurarVersion,

    [Parameter(ParameterSetName = "Listar", Mandatory = $true)]
    [switch]$ListarVersiones
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$ConfigFolder = Join-Path $ClaudeMemRoot "config"
$IndexFolder = Join-Path $ClaudeMemRoot "index"
$VersionsFolder = Join-Path $ClaudeMemRoot "versions"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"

$HistorialFile = Join-Path $VersionsFolder "historial.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$VersionId = "VER-$MarcaTiempo"
$VersionFolder = Join-Path $VersionsFolder $VersionId
$SnapshotFolder = Join-Path $VersionFolder "snapshot"
$ManifestFile = Join-Path $VersionFolder "manifest.json"
$ReportFile = Join-Path $ReportsFolder "Reporte-Versionado-ClaudeMem-$MarcaTiempo.txt"

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

$script:Resultados = @()

# ============================================================
# FUNCIONES GENERALES
# ============================================================

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Agregar-Resultado {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Prueba,
        [Parameter(Mandatory = $true)][bool]$Aprobada,
        [Parameter(Mandatory = $true)][string]$Detalle
    )

    $script:Resultados += [PSCustomObject]@{
        ID = $Id
        Estado = $(if ($Aprobada) { "PASS" } else { "FAIL" })
        Prueba = $Prueba
        Detalle = $Detalle
    }
}

function Escribir-Log {
    param([Parameter(Mandatory = $true)][string]$Mensaje)

    Crear-Carpeta -Ruta $LogsFolder
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        New-Item -ItemType File -Path $LogFile -Force | Out-Null
    }

    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - VERSIONADO: $Mensaje" -Encoding UTF8
}

function Convertir-AListaPlana {
    param([AllowNull()][object]$Valor)

    $Salida = @()
    if ($null -eq $Valor) {
        return $Salida
    }

    if ($Valor -is [System.Array]) {
        foreach ($Elemento in $Valor) {
            if ($null -ne $Elemento) {
                $Salida += $Elemento
            }
        }
    }
    else {
        $Salida += $Valor
    }

    return $Salida
}

function Leer-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        return @()
    }

    $Contenido = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if ($null -eq $Contenido -or $Contenido.Trim().Length -eq 0) {
        return @()
    }

    try {
        $Convertido = ConvertFrom-Json -InputObject $Contenido -ErrorAction Stop
        return (Convertir-AListaPlana -Valor $Convertido)
    }
    catch {
        throw "JSON invalido en '$Ruta': $($_.Exception.Message)"
    }
}

function Guardar-JsonSeguro {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Datos,
        [int]$Profundidad = 30
    )

    $Temporal = "$Ruta.tmp"

    if ($Datos -is [System.Array]) {
        ConvertTo-Json -InputObject ([object[]]$Datos) -Depth $Profundidad |
            Set-Content -LiteralPath $Temporal -Encoding UTF8
    }
    else {
        ConvertTo-Json -InputObject $Datos -Depth $Profundidad |
            Set-Content -LiteralPath $Temporal -Encoding UTF8
    }

    try {
        $Prueba = Get-Content -LiteralPath $Temporal -Raw -ErrorAction Stop
        $Convertido = ConvertFrom-Json -InputObject $Prueba -ErrorAction Stop
        if ($Datos -is [System.Array]) {
            $ListaValidada = Convertir-AListaPlana -Valor $Convertido
            if ($ListaValidada.Count -ne @($Datos).Count) {
                throw "La cantidad de registros JSON no coincide con la entrada."
            }
        }
    }
    catch {
        Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
        throw "No se genero JSON valido para '$Ruta'."
    }

    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Obtener-HashArchivo {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    return (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Validar-JsonSiCorresponde {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    if ([System.IO.Path]::GetExtension($Ruta) -ne ".json") {
        return
    }

    $Contenido = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    $null = ConvertFrom-Json -InputObject $Contenido -ErrorAction Stop
}

function Obtener-UltimaVersion {
    $Historial = @(Leer-JsonArray -Ruta $HistorialFile)
    if ($Historial.Count -eq 0) {
        return $null
    }

    return @($Historial | Sort-Object fechaCreacion -Descending)[0]
}

function Obtener-MapaManifest {
    param([AllowNull()][object]$VersionAnterior)

    $Mapa = @{}
    if ($null -eq $VersionAnterior) {
        return $Mapa
    }

    $RutaManifest = Join-Path $VersionsFolder ([string]$VersionAnterior.id + "\manifest.json")
    if (-not (Test-Path -LiteralPath $RutaManifest -PathType Leaf)) {
        return $Mapa
    }

    $Manifest = Get-Content -LiteralPath $RutaManifest -Raw | ConvertFrom-Json -ErrorAction Stop
    foreach ($Archivo in @($Manifest.archivos)) {
        $Mapa[[string]$Archivo.rutaRelativa] = [string]$Archivo.sha256
    }

    return $Mapa
}

function Crear-RespaldoPreRestauracion {
    param([Parameter(Mandatory = $true)][string]$VersionSolicitada)

    Crear-Carpeta -Ruta $BackupsFolder
    $RutaBackup = Join-Path $BackupsFolder "pre-restauracion-$VersionSolicitada-$MarcaTiempo.zip"
    $Elementos = @()

    foreach ($Objetivo in $ArchivosObjetivo) {
        $Origen = Join-Path $ClaudeMemRoot $Objetivo.Relativa
        if (Test-Path -LiteralPath $Origen -PathType Leaf) {
            $Elementos += $Origen
        }
    }

    if ($Elementos.Count -eq 0) {
        throw "No existen archivos actuales para respaldar antes de restaurar."
    }

    Compress-Archive -LiteralPath $Elementos -DestinationPath $RutaBackup `
        -CompressionLevel Optimal -Force

    if (-not (Test-Path -LiteralPath $RutaBackup -PathType Leaf)) {
        throw "No se creo el respaldo previo a la restauracion."
    }

    if ((Get-Item -LiteralPath $RutaBackup).Length -le 0) {
        throw "El respaldo previo a la restauracion esta vacio."
    }

    return $RutaBackup
}

# ============================================================
# LISTAR VERSIONES
# ============================================================

function Mostrar-Versiones {
    Crear-Carpeta -Ruta $VersionsFolder
    $Historial = @(Leer-JsonArray -Ruta $HistorialFile)

    Write-Host ""
    Write-Host "VERSIONES CLAUDEMEM" -ForegroundColor Cyan
    Write-Host ""

    if ($Historial.Count -eq 0) {
        Write-Host "No existen versiones registradas." -ForegroundColor Yellow
        return
    }

    $Historial |
        Sort-Object fechaCreacion -Descending |
        Select-Object id, fechaCreacion, archivos, modificados, nuevos, sinCambios, estado |
        Format-Table -AutoSize
}

# ============================================================
# RESTAURAR VERSION
# ============================================================

function Restaurar-VersionClaudeMem {
    param([Parameter(Mandatory = $true)][string]$IdVersion)

    $CarpetaVersion = Join-Path $VersionsFolder $IdVersion
    $CarpetaSnapshot = Join-Path $CarpetaVersion "snapshot"
    $RutaManifest = Join-Path $CarpetaVersion "manifest.json"

    Write-Host ""
    Write-Host "RESTAURAR VERSION CLAUDEMEM" -ForegroundColor Cyan
    Write-Host "Version: $IdVersion"
    Write-Host ""

    if (-not (Test-Path -LiteralPath $RutaManifest -PathType Leaf)) {
        throw "No existe el manifiesto de la version '$IdVersion'."
    }

    if (-not (Test-Path -LiteralPath $CarpetaSnapshot -PathType Container)) {
        throw "No existe el snapshot de la version '$IdVersion'."
    }

    $Manifest = Get-Content -LiteralPath $RutaManifest -Raw | ConvertFrom-Json -ErrorAction Stop
    $Backup = Crear-RespaldoPreRestauracion -VersionSolicitada $IdVersion
    Write-Host "Respaldo previo creado:" -ForegroundColor Green
    Write-Host $Backup
    Write-Host ""

    $Restaurados = 0
    foreach ($Archivo in @($Manifest.archivos)) {
        $Relativa = [string]$Archivo.rutaRelativa
        $Origen = Join-Path $CarpetaSnapshot $Relativa
        $Destino = Join-Path $ClaudeMemRoot $Relativa

        if (-not (Test-Path -LiteralPath $Origen -PathType Leaf)) {
            throw "Falta archivo en snapshot: $Relativa"
        }

        $HashOrigen = Obtener-HashArchivo -Ruta $Origen
        if ($HashOrigen -ne [string]$Archivo.sha256) {
            throw "Hash invalido en snapshot: $Relativa"
        }

        Validar-JsonSiCorresponde -Ruta $Origen
        Crear-Carpeta -Ruta (Split-Path -Parent $Destino)
        Copy-Item -LiteralPath $Origen -Destination $Destino -Force

        $HashDestino = Obtener-HashArchivo -Ruta $Destino
        if ($HashDestino -ne $HashOrigen) {
            throw "La verificacion posterior fallo para: $Relativa"
        }

        $Restaurados++
    }

    Escribir-Log "VERSION RESTAURADA: $IdVersion; archivos=$Restaurados; backup=$Backup"

    Write-Host "Restauracion completada correctamente." -ForegroundColor Green
    Write-Host "Archivos restaurados: $Restaurados"
    Write-Host ""
}

# ============================================================
# CREAR VERSION
# ============================================================

function Crear-VersionClaudeMem {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " VERSIONAR CLAUDEMEM" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""

    Crear-Carpeta -Ruta $VersionsFolder
    Crear-Carpeta -Ruta $BackupsFolder
    Crear-Carpeta -Ruta $ReportsFolder
    Crear-Carpeta -Ruta $LogsFolder
    Crear-Carpeta -Ruta $VersionFolder
    Crear-Carpeta -Ruta $SnapshotFolder

    $VersionAnterior = Obtener-UltimaVersion
    $MapaAnterior = Obtener-MapaManifest -VersionAnterior $VersionAnterior
    $ArchivosManifest = @()
    $Nuevos = 0
    $Modificados = 0
    $SinCambios = 0

    try {
        foreach ($Objetivo in $ArchivosObjetivo) {
            $Relativa = [string]$Objetivo.Relativa
            $Origen = Join-Path $ClaudeMemRoot $Relativa

            if (-not (Test-Path -LiteralPath $Origen -PathType Leaf)) {
                if ([bool]$Objetivo.Critico) {
                    throw "Falta archivo critico: $Relativa"
                }
                continue
            }

            Validar-JsonSiCorresponde -Ruta $Origen
            $Hash = Obtener-HashArchivo -Ruta $Origen
            $Tamano = (Get-Item -LiteralPath $Origen).Length
            $Destino = Join-Path $SnapshotFolder $Relativa
            Crear-Carpeta -Ruta (Split-Path -Parent $Destino)
            Copy-Item -LiteralPath $Origen -Destination $Destino -Force

            $HashCopia = Obtener-HashArchivo -Ruta $Destino
            if ($HashCopia -ne $Hash) {
                throw "La copia no coincide con el original: $Relativa"
            }

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
            else {
                $Nuevos++
            }

            $ArchivosManifest += [PSCustomObject][ordered]@{
                rutaRelativa = $Relativa
                sha256 = $Hash
                tamanoBytes = $Tamano
                cambio = $Cambio
            }
        }

        Agregar-Resultado -Id "VER-001" -Prueba "Validar archivos criticos" `
            -Aprobada $true -Detalle "Archivos: $($ArchivosManifest.Count)"
        Agregar-Resultado -Id "VER-002" -Prueba "Crear snapshot" `
            -Aprobada $true -Detalle $SnapshotFolder
        Agregar-Resultado -Id "VER-003" -Prueba "Validar hashes SHA-256" `
            -Aprobada $true -Detalle "$($ArchivosManifest.Count) hashes verificados"

        $Manifest = [PSCustomObject][ordered]@{
            id = $VersionId
            fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            versionAnterior = $(if ($null -eq $VersionAnterior) { $null } else { [string]$VersionAnterior.id })
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

        Guardar-JsonSeguro -Ruta $ManifestFile -Datos $Manifest
        Agregar-Resultado -Id "VER-004" -Prueba "Generar manifiesto" `
            -Aprobada $true -Detalle $ManifestFile

        $Historial = @(Leer-JsonArray -Ruta $HistorialFile)
        $Historial += [PSCustomObject][ordered]@{
            id = $VersionId
            fechaCreacion = $Manifest.fechaCreacion
            versionAnterior = $Manifest.versionAnterior
            archivos = $ArchivosManifest.Count
            nuevos = $Nuevos
            modificados = $Modificados
            sinCambios = $SinCambios
            estado = "VALIDA"
            manifest = "${VersionId}\manifest.json"
        }

        Guardar-JsonSeguro -Ruta $HistorialFile -Datos @($Historial | Sort-Object fechaCreacion)
        Agregar-Resultado -Id "VER-005" -Prueba "Actualizar historial" `
            -Aprobada $true -Detalle $HistorialFile

        $HistorialValidado = @(Leer-JsonArray -Ruta $HistorialFile)
        $RegistroActual = @($HistorialValidado | Where-Object { $_.id -eq $VersionId })
        $HistorialOk = ($RegistroActual.Count -eq 1)
        Agregar-Resultado -Id "VER-006" -Prueba "Verificar version registrada" `
            -Aprobada $HistorialOk -Detalle "Coincidencias: $($RegistroActual.Count)"

        Escribir-Log "VERSION CREADA: $VersionId; archivos=$($ArchivosManifest.Count); nuevos=$Nuevos; modificados=$Modificados; sinCambios=$SinCambios"
    }
    catch {
        Agregar-Resultado -Id "VER-ERR" -Prueba "Ejecucion general" `
            -Aprobada $false -Detalle $_.Exception.Message
        Escribir-Log "ERROR: $($_.Exception.Message)"
    }

    $TotalPruebas = $script:Resultados.Count
    $Aprobadas = @($script:Resultados | Where-Object { $_.Estado -eq "PASS" }).Count
    $Fallidas = $TotalPruebas - $Aprobadas
    $Porcentaje = if ($TotalPruebas -gt 0) {
        [math]::Round(($Aprobadas / $TotalPruebas) * 100, 2)
    }
    else { 0 }
    $EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }

    $Cabecera = @(
        "===================================================="
        "REPORTE DE VERSIONADO CLAUDEMEM"
        "===================================================="
        ""
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Version: $VersionId"
        "Estado: $EstadoFinal"
        "Aprobadas: $Aprobadas"
        "Fallidas: $Fallidas"
        "Resultado: $Porcentaje %"
        ""
    )

    $Cabecera | Set-Content -LiteralPath $ReportFile -Encoding UTF8
    $script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize |
        Out-String | Add-Content -LiteralPath $ReportFile -Encoding UTF8

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " RESULTADO DE VERSIONADO" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    $script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize
    Write-Host ""
    Write-Host "Version: $VersionId"
    Write-Host "Archivos: $($ArchivosManifest.Count)"
    Write-Host "Nuevos: $Nuevos"
    Write-Host "Modificados: $Modificados"
    Write-Host "Sin cambios: $SinCambios"
    Write-Host "Aprobadas: $Aprobadas / $TotalPruebas"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $EstadoFinal"
    Write-Host ""
    Write-Host "Version guardada en:"
    Write-Host $VersionFolder
    Write-Host ""
    Write-Host "Informe:"
    Write-Host $ReportFile
    Write-Host ""

    if ($Fallidas -gt 0) {
        exit 1
    }
}

# ============================================================
# EJECUCION
# ============================================================

Crear-Carpeta -Ruta $VersionsFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder

switch ($PSCmdlet.ParameterSetName) {
    "Listar" {
        Mostrar-Versiones
    }
    "Restaurar" {
        Restaurar-VersionClaudeMem -IdVersion $RestaurarVersion
    }
    default {
        Crear-VersionClaudeMem
    }
}
