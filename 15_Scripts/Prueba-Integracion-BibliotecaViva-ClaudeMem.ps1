#Requires -Version 5.1

<#
.SYNOPSIS
    Ejecuta una prueba real de integracion entre Biblioteca Viva
    y ClaudeMem.

.DESCRIPTION
    Crea tres documentos Markdown controlados:

    - DECISION-INTEGRACION-001.md
    - LECCION-INTEGRACION-001.md
    - HALLAZGO-INTEGRACION-001.md

    Luego:
    - ejecuta la sincronizacion;
    - reconstruye el indice;
    - valida los JSON;
    - valida index.json;
    - genera un informe PASS/FAIL.

.VERSION
    1.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot

$ClaudeMemRoot = Join-Path `
    $CopilotRoot `
    "11_Herramientas\ClaudeMem"

$ConocimientoRoot = Join-Path `
    $CopilotRoot `
    "03_Conocimiento"

$DecisionesFolder = Join-Path `
    $ConocimientoRoot `
    "01_Decisiones"

$LeccionesFolder = Join-Path `
    $ConocimientoRoot `
    "02_Lecciones_Aprendidas"

$BaseVivaFolder = Join-Path `
    $ConocimientoRoot `
    "24_Base_Conocimiento_Viva"

$DataFolder = Join-Path `
    $ClaudeMemRoot `
    "data"

$BackupsFolder = Join-Path `
    $ClaudeMemRoot `
    "backups"

$LogsFolder = Join-Path `
    $ClaudeMemRoot `
    "logs"

$ReportsFolder = Join-Path `
    $ClaudeMemRoot `
    "reports"

$DecisionesJson = Join-Path `
    $DataFolder `
    "decisiones.json"

$LeccionesJson = Join-Path `
    $DataFolder `
    "lecciones.json"

$HallazgosJson = Join-Path `
    $DataFolder `
    "hallazgos.json"

$IndexJson = Join-Path `
    $ClaudeMemRoot `
    "index\index.json"

$LogFile = Join-Path `
    $LogsFolder `
    "claudemem.log"

$SincronizadorScript = Join-Path `
    $PSScriptRoot `
    "Sincronizar-BibliotecaViva-ClaudeMem.ps1"

$ReconstruirIndiceScript = Join-Path `
    $PSScriptRoot `
    "Reconstruir-Indice-ClaudeMem.ps1"

$DecisionMarkdown = Join-Path `
    $DecisionesFolder `
    "DECISION-INTEGRACION-001.md"

$LeccionMarkdown = Join-Path `
    $LeccionesFolder `
    "LECCION-INTEGRACION-001.md"

$HallazgoMarkdown = Join-Path `
    $BaseVivaFolder `
    "HALLAZGO-INTEGRACION-001.md"

$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupFile = Join-Path `
    $BackupsFolder `
    "pre-prueba-integracion-$MarcaTiempo.zip"

$ReportFile = Join-Path `
    $ReportsFolder `
    "Reporte-Integracion-BibliotecaViva-$MarcaTiempo.txt"

# ============================================================
# RESULTADOS
# ============================================================

$script:Resultados = @()

function Agregar-Resultado {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [string]$Prueba,

        [Parameter(Mandatory)]
        [bool]$Aprobada,

        [Parameter(Mandatory)]
        [string]$Detalle
    )

    $script:Resultados += [PSCustomObject]@{
        ID = $Id
        Prueba = $Prueba
        Estado = if ($Aprobada) {
            "PASS"
        }
        else {
            "FAIL"
        }
        Detalle = $Detalle
    }
}

# ============================================================
# FUNCIONES GENERALES
# ============================================================

function Crear-Carpeta {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Escribir-LogPrueba {
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje
    )

    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Add-Content `
        -LiteralPath $LogFile `
        -Value "$Fecha - PRUEBA INTEGRACION: $Mensaje" `
        -Encoding UTF8
}

function Leer-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw `
        -ErrorAction Stop

    if ($null -eq $Contenido -or $Contenido.Trim().Length -eq 0) {
        return @()
    }

    try {
        $Datos = $Contenido |
            ConvertFrom-Json `
                -ErrorAction Stop
    }
    catch {
        throw "JSON invalido en '$Ruta': $($_.Exception.Message)"
    }

    return @($Datos)
}

function Buscar-Registro {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta,

        [Parameter(Mandatory)]
        [string]$Id
    )

    $Registros = @(
        Leer-JsonArray `
            -Ruta $Ruta
    )

    $Coincidencias = @(
        $Registros |
        Where-Object {
            $null -ne $_.id -and
            [string]$_.id -eq $Id
        }
    )

    return $Coincidencias
}

function Crear-RespaldoPrueba {
    $Elementos = @()

    foreach ($Elemento in @(
        $DataFolder,
        (Join-Path $ClaudeMemRoot "index"),
        $DecisionesFolder,
        $LeccionesFolder,
        $BaseVivaFolder
    )) {
        if (Test-Path -LiteralPath $Elemento) {
            $Elementos += $Elemento
        }
    }

    $Elementos = @($Elementos)

    if ($Elementos.Count -eq 0) {
        throw "No existen elementos para respaldar."
    }

    Compress-Archive `
        -LiteralPath $Elementos `
        -DestinationPath $BackupFile `
        -CompressionLevel Optimal `
        -Force

    if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) {
        throw "No fue posible crear el respaldo."
    }

    $Tamano = (
        Get-Item `
            -LiteralPath $BackupFile `
            -ErrorAction Stop
    ).Length

    if ($Tamano -le 0) {
        throw "El respaldo fue creado sin contenido."
    }

    return $Tamano
}

# ============================================================
# VALIDACIONES PREVIAS
# ============================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host " PRUEBA DE INTEGRACION BIBLIOTECA VIVA - CLAUDEMEM" `
    -ForegroundColor Cyan
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host ""

Crear-Carpeta -Ruta $ClaudeMemRoot
Crear-Carpeta -Ruta $ConocimientoRoot
Crear-Carpeta -Ruta $DecisionesFolder
Crear-Carpeta -Ruta $LeccionesFolder
Crear-Carpeta -Ruta $BaseVivaFolder
Crear-Carpeta -Ruta $DataFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $LogsFolder
Crear-Carpeta -Ruta $ReportsFolder

if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force |
    Out-Null
}

$ExisteSincronizador = Test-Path `
    -LiteralPath $SincronizadorScript `
    -PathType Leaf

Agregar-Resultado `
    -Id "INT-001" `
    -Prueba "Existe sincronizador" `
    -Aprobada $ExisteSincronizador `
    -Detalle $SincronizadorScript

if (-not $ExisteSincronizador) {
    throw "No existe el sincronizador: $SincronizadorScript"
}

$ExisteReconstruidor = Test-Path `
    -LiteralPath $ReconstruirIndiceScript `
    -PathType Leaf

Agregar-Resultado `
    -Id "INT-002" `
    -Prueba "Existe reconstruidor de indice" `
    -Aprobada $ExisteReconstruidor `
    -Detalle $ReconstruirIndiceScript

if (-not $ExisteReconstruidor) {
    throw "No existe el reconstruidor: $ReconstruirIndiceScript"
}

# ============================================================
# RESPALDO PREVIO
# ============================================================

try {
    $TamanoBackup = Crear-RespaldoPrueba

    Agregar-Resultado `
        -Id "INT-003" `
        -Prueba "Respaldo previo" `
        -Aprobada $true `
        -Detalle "$BackupFile - $TamanoBackup bytes"

    Write-Host "[OK] Respaldo previo creado." `
        -ForegroundColor Green
    Write-Host $BackupFile
}
catch {
    Agregar-Resultado `
        -Id "INT-003" `
        -Prueba "Respaldo previo" `
        -Aprobada $false `
        -Detalle $_.Exception.Message

    throw
}

# ============================================================
# CREAR DOCUMENTOS MARKDOWN
# ============================================================

$ContenidoDecision = @'
# DECISION-INTEGRACION-001

Fecha: 2026-10-21

## Titulo

Integracion real entre Biblioteca Viva y ClaudeMem.

## Decision

Los documentos Markdown controlados se sincronizaran con la
memoria persistente de ClaudeMem.

## Estado

Validado.
'@

$ContenidoLeccion = @'
# LECCION-INTEGRACION-001

Fecha: 2026-10-21

## Problema

La sincronizacion inicial procesaba cero documentos porque no
existian archivos Markdown con los patrones requeridos.

## Solucion

Crear documentos DECISION-*.md, LECCION-*.md y HALLAZGO-*.md
en la estructura de 03_Conocimiento y validar su importacion.
'@

$ContenidoHallazgo = @'
# HALLAZGO-INTEGRACION-001

Fecha: 2026-10-21

## Hallazgo

ClaudeMem puede conservar sus registros existentes y agregar
documentos procedentes de Biblioteca Viva mediante sincronizacion.

## Estado

Abierto para validacion funcional.
'@

Set-Content `
    -LiteralPath $DecisionMarkdown `
    -Value $ContenidoDecision `
    -Encoding UTF8

Set-Content `
    -LiteralPath $LeccionMarkdown `
    -Value $ContenidoLeccion `
    -Encoding UTF8

Set-Content `
    -LiteralPath $HallazgoMarkdown `
    -Value $ContenidoHallazgo `
    -Encoding UTF8

$MarkdownCreados = @(
    $DecisionMarkdown,
    $LeccionMarkdown,
    $HallazgoMarkdown
)

foreach ($Markdown in $MarkdownCreados) {
    $Existe = Test-Path `
        -LiteralPath $Markdown `
        -PathType Leaf

    Agregar-Resultado `
        -Id "INT-004" `
        -Prueba "Documento Markdown creado" `
        -Aprobada $Existe `
        -Detalle $Markdown
}

Write-Host ""
Write-Host "[OK] Documentos Markdown creados." `
    -ForegroundColor Green

# ============================================================
# EJECUTAR SINCRONIZACION
# ============================================================

Write-Host ""
Write-Host "Ejecutando sincronizacion..." `
    -ForegroundColor Cyan
Write-Host ""

try {
    & $SincronizadorScript
    $SincronizacionCorrecta = $?

    if (-not $SincronizacionCorrecta) {
        throw "El sincronizador informo un error."
    }

    Agregar-Resultado `
        -Id "INT-005" `
        -Prueba "Ejecucion del sincronizador" `
        -Aprobada $true `
        -Detalle "Sincronizacion completada"
}
catch {
    Agregar-Resultado `
        -Id "INT-005" `
        -Prueba "Ejecucion del sincronizador" `
        -Aprobada $false `
        -Detalle $_.Exception.Message
}

# ============================================================
# RECONSTRUIR INDICE
# ============================================================

Write-Host ""
Write-Host "Reconstruyendo indice..." `
    -ForegroundColor Cyan
Write-Host ""

try {
    & $ReconstruirIndiceScript
    $IndiceCorrecto = $?

    if (-not $IndiceCorrecto) {
        throw "El reconstruidor informo un error."
    }

    Agregar-Resultado `
        -Id "INT-006" `
        -Prueba "Reconstruccion de indice" `
        -Aprobada $true `
        -Detalle "Indice reconstruido"
}
catch {
    Agregar-Resultado `
        -Id "INT-006" `
        -Prueba "Reconstruccion de indice" `
        -Aprobada $false `
        -Detalle $_.Exception.Message
}

# ============================================================
# VALIDAR IMPORTACIONES
# ============================================================

$DecisionImportada = @(
    Buscar-Registro `
        -Ruta $DecisionesJson `
        -Id "DECISION-INTEGRACION-001"
)

$LeccionImportada = @(
    Buscar-Registro `
        -Ruta $LeccionesJson `
        -Id "LECCION-INTEGRACION-001"
)

$HallazgoImportado = @(
    Buscar-Registro `
        -Ruta $HallazgosJson `
        -Id "HALLAZGO-INTEGRACION-001"
)

Agregar-Resultado `
    -Id "INT-007" `
    -Prueba "Decision importada" `
    -Aprobada ($DecisionImportada.Count -eq 1) `
    -Detalle "Coincidencias: $($DecisionImportada.Count)"

Agregar-Resultado `
    -Id "INT-008" `
    -Prueba "Leccion importada" `
    -Aprobada ($LeccionImportada.Count -eq 1) `
    -Detalle "Coincidencias: $($LeccionImportada.Count)"

Agregar-Resultado `
    -Id "INT-009" `
    -Prueba "Hallazgo importado" `
    -Aprobada ($HallazgoImportado.Count -eq 1) `
    -Detalle "Coincidencias: $($HallazgoImportado.Count)"

# ============================================================
# VALIDAR INDICE
# ============================================================

$IndiceValido = $false
$EntradasIndice = 0

try {
    $Indice = Get-Content `
        -LiteralPath $IndexJson `
        -Raw `
        -ErrorAction Stop |
    ConvertFrom-Json `
        -ErrorAction Stop

    $PropiedadesIndice = @(
        $Indice.PSObject.Properties
    )

    $EntradasIndice = $PropiedadesIndice.Count

    $IdsIndice = @(
        $PropiedadesIndice.Name
    )

    $IndiceValido = (
        $IdsIndice -contains "DECISION-INTEGRACION-001" -and
        $IdsIndice -contains "LECCION-INTEGRACION-001" -and
        $IdsIndice -contains "HALLAZGO-INTEGRACION-001"
    )
}
catch {
    $IndiceValido = $false
}

Agregar-Resultado `
    -Id "INT-010" `
    -Prueba "Registros presentes en index.json" `
    -Aprobada $IndiceValido `
    -Detalle "Entradas actuales: $EntradasIndice"

# ============================================================
# INFORME FINAL
# ============================================================

$TotalPruebas = $script:Resultados.Count

$PruebasAprobadas = @(
    $script:Resultados |
    Where-Object {
        $_.Estado -eq "PASS"
    }
).Count

$PruebasFallidas = $TotalPruebas - $PruebasAprobadas

if ($TotalPruebas -gt 0) {
    $Porcentaje = [Math]::Round(
        ($PruebasAprobadas / $TotalPruebas) * 100,
        2
    )
}
else {
    $Porcentaje = 0
}

$EstadoFinal = if ($PruebasFallidas -eq 0) {
    "APROBADO"
}
else {
    "NO APROBADO"
}

$EncabezadoInforme = @(
    "===================================================="
    "PRUEBA DE INTEGRACION BIBLIOTECA VIVA - CLAUDEMEM"
    "===================================================="
    ""
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Estado: $EstadoFinal"
    "Aprobadas: $PruebasAprobadas"
    "Fallidas: $PruebasFallidas"
    "Total: $TotalPruebas"
    "Resultado: $Porcentaje %"
    ""
)

$EncabezadoInforme |
    Set-Content `
        -LiteralPath $ReportFile `
        -Encoding UTF8

$script:Resultados |
    Format-Table `
        ID,
   tado,
        Prueba,
        Detalle `
        -AutoSize |
    Out-String |
    Add-Content `
        -LiteralPath $ReportFile `
        -Encoding UTF8

Escribir-LogPrueba `
    "Estado=$EstadoFinal; Aprobadas=$PruebasAprobadas; Fallidas=$PruebasFallidas"

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host " RESULTADO DE INTEGRACION" `
    -ForegroundColor Cyan
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host ""

$script:Resultados |
    Format-Table `
        ID,
        Estado,
        Prueba,
        Detalle `
        -AutoSize

Write-Host ""
Write-Host "Aprobadas: $PruebasAprobadas / $TotalPruebas"
Write-Host "Resultado: $Porcentaje %"
Write-Host "Estado: $EstadoFinal"
Write-Host ""
Write-Host "Informe:"
Write-Host $ReportFile
Write-Host ""

if ($PruebasFallidas -gt 0) {
    exit 1
}