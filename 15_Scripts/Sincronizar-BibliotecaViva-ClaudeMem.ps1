#Requires -Version 5.1

<#
.SYNOPSIS
    Sincroniza documentos Markdown de Biblioteca Viva con ClaudeMem.

.DESCRIPTION
    Detecta carpetas de decisiones, lecciones y hallazgos
    dentro de 03_Conocimiento.

    Fusiona los registros importados con los registros existentes.
    No elimina los registros creados desde ClaudeMem-Core.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot

$ClaudeMem = Join-Path `
    $CopilotRoot `
    "11_Herramientas\ClaudeMem"

$ConocimientoRoot = Join-Path `
    $CopilotRoot `
    "03_Conocimiento"

$DataFolder = Join-Path $ClaudeMem "data"
$LogsFolder = Join-Path $ClaudeMem "logs"
$IndexFolder = Join-Path $ClaudeMem "index"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"
$TagsFile = Join-Path $DataFolder "tags.json"

$LogFile = Join-Path $LogsFolder "claudemem.log"

$ReconstruirIndiceScript = Join-Path `
    $PSScriptRoot `
    "Reconstruir-Indice-ClaudeMem.ps1"

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

function Escribir-Log {
    param(
        [Parameter(Mandatory)]
        [string       -Value $Linea `
        -Encoding UTF8
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

    if (:IsNullOrWhiteSpace($Contenido)) {
        return @()
    }

    return @($Contenido | ConvertFrom-Json)
}

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Datos
    )

    $Temporal = "$Ruta.tmp"

    @($Datos) |
        ConvertTo-Json -Depth 30 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $Ruta `
        -Force
}

function Obtener-TituloMarkdown {
    param(
        [Parameter(Mandatory)]
        [string]$Contenido,

        [Parameter(Mandatory)]
        [string]$TituloAlternativo
    )

    $Coincidencia = :Match(
        $Contenido,
        "(?m)^\s*#\s+(.+?)\s*$"
    )

    if ($Coincidencia.Success) {
        return $Coincidencia.Groups[1].Value.Trim()
    }

    return $TituloAlternativo
}

function Obtener-ResumenMarkdown {
    param(
        [Parameter(Mandatory)]
        [string]$Contenido
    )

    $Lineas = @(
        $Contenido -split "`r?`n" |
        ForEach-Object {
            $_.Trim()
        } |
        Where-Object {
            -not :IsNullOrWhiteSpace($_) -and
            $_ -notmatch "^\s*#"
        }
    )

    $Resumen = ($Lineas -join " ").Trim()

    if ($Resumen.Length -gt 500) {
        $Resumen = $Resumen.Substring(0, 500)
    }

    return $Resumen
}

function Buscar-CarpetaTipo {
    param(
        [Parameter(Mandatory)]
        [string[]]$Patrones
    )

    $Carpetas = @(
        Get-ChildItem `
            -LiteralPath $ConocimientoRoot `
            -Directory `
            -Recurse `
            -ErrorAction SilentlyContinue
    )

    foreach ($Patron in $Patrones) {
        $Encontrada = $Carpetas |
            Where-Object {
                $_.Name -match $Patron
            } |
            Sort-Object FullName |
            Select-Object -First 1

        if ($Encontrada) {
            return $Encontrada.FullName
        }
    }

    return $null
}

function Fusionar-Markdown {
    param(
        [Parameter(Mandatory)]
        [string]$Tipo,

        [Parameter(Mandatory)]
        [string]$Prefijo,

        [Parameter(Mandatory)]
        [string[]]$PatronesCarpeta,

        [Parameter(Mandatory)]
        [string]$DestinoJson
    )

    $CarpetaOrigen = Buscar-CarpetaTipo `
        -Patrones $PatronesCarpeta

    if (-not $CarpetaOrigen) {
        Write-Host "No se encontro carpeta para $Tipo." -ForegroundColor Yellow
        Escribir-Log "SINCRONIZACION $Tipo: carpeta no encontrada"
        return 0
    }

    Write-Host ""
    Write-Host "$Tipo origen:" -ForegroundColor Cyan
    Write-Host $CarpetaOrigen

    $Archivos = @(
        Get-ChildItem `
            -LiteralPath $CarpetaOrigen `
            -Filter "$Prefijo-*.md" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue
    )

    if ($Archivos.Count -eq 0) {
        Write-Host "No existen archivos $Prefijo-*.md." -ForegroundColor Yellow
        Escribir-Log "SINCRONIZACION $Tipo: cero archivos"
        return 0
    }

    $Existentes = @(Leer-JsonArray -Ruta $DestinoJson)
    $Mapa = @{}

    foreach ($Registro in $Existentes) {
        if ($Registro.id) {
            $Mapa[[string]$Registro.id] = $Registro
        }
    }

    foreach ($Archivo in $Archivos) {
        $Contenido = Get-Content `
            -LiteralPath $Archivo.FullName `
            -Raw

        $Id = $Archivo.BaseName
        $Titulo = Obtener-TituloMarkdown `
            -Contenido $Contenido `
            -TituloAlternativo $Id

        $Resumen = Obtener-ResumenMarkdown `
            -Contenido $Contenido

        if ($Tipo -eq "decision") {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "decision"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Decision")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        elseif ($Tipo -eq "leccion") {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "leccion"
                problema = $Titulo
                solucion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Leccion")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        else {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "hallazgo"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Hallazgo")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }

        $Mapa[$Id] = $Registro
    }

    $Finales = @(
        $Mapa.Values |
        Sort-Object id
    )

    Guardar-JsonArray `
        -Ruta $DestinoJson `
        -Datos $Finales

    Write-Host "Procesados: $($Archivos.Count)" -ForegroundColor Green
    Escribir-Log "SINCRONIZACION $Tipo: $($Archivos.Count) archivos"

    return $Archivos.Count
}

# ============================================================
# EJECUCION
# ============================================================

Crear-Carpeta -Ruta $DataFolder
Crear-Carpeta -Ruta $LogsFolder
Crear-Carpeta -Ruta $IndexFolder

if (-not (Test-Path -LiteralPath $LogFile)) {
    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force |
    Out-Null
}

foreach ($ArchivoJson in @(
    $DecisionesFile,
    $LeccionesFile,
    $HallazgosFile,
    $TagsFile
)) {
    if (-not (Test-Path -LiteralPath $ArchivoJson)) {
        Set-Content `
            -LiteralPath $ArchivoJson `
            -Value "[]" `
            -Encoding UTF8
    }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " SINCRONIZAR BIBLIOTECA VIVA CON CLAUDEMEM" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $ConocimientoRoot)) {
    Write-Host "No existe la raiz de conocimiento:" -ForegroundColor Red
    Write-Host $ConocimientoRoot
    Escribir-Log "SINCRONIZACION FALLIDA: 03_Conocimiento no existe"
    exit 1
}

try {
    $TotalDecisiones = Fusionar-Markdown `
        -Tipo "decision" `
        -Prefijo "DECISION" `
        -PatronesCarpeta @(
            "^01_Decisiones$",
            "Decisiones"
        ) `
        -DestinoJson $DecisionesFile

    $TotalLecciones = Fusionar-Markdown `
        -Tipo "leccion" `
        -Prefijo "LECCION" `
        -PatronesCarpeta @(
            "^02_Lecciones_Aprendidas$",
            "Lecciones"
        ) `
        -DestinoJson $LeccionesFile

    $TotalHallazgos = Fusionar-Markdown `
        -Tipo "hallazgo" `
        -Prefijo "HALLAZGO" `
        -PatronesCarpeta @(
            "24_Base_Conocimiento_Viva",
            "Hallazgos",
            "Base_Conocimiento"
        ) `
        -DestinoJson $HallazgosFile

    $Total = $TotalDecisiones + $TotalLecciones + $TotalHallazgos

    if (Test-Path -LiteralPath $ReconstruirIndiceScript) {
        & $ReconstruirIndiceScript

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "La reconstruccion del indice termino con error."
        }
    }
    else {
        Write-Host ""
        Write-Host "Advertencia: no existe el reconstruidor de indice." -ForegroundColor Yellow
    }

    Escribir-Log "SINCRONIZACION COMPLETADA: $Total archivos"

    Write-Host ""
    Write-Host "Sincronizacion completada." -ForegroundColor Green
    Write-Host "Decisiones: $TotalDecisiones"
    Write-Host "Lecciones:  $TotalLecciones"
    Write-Host "Hallazgos:  $TotalHallazgos"
    Write-Host "Total:      $Total"
    Write-Host ""
}
catch {
    Escribir-Log "ERROR SINCRONIZACION: $($_.Exception.Message)"

    Write-Host ""
    Write-Host "La sincronizacion no pudo completarse." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}
