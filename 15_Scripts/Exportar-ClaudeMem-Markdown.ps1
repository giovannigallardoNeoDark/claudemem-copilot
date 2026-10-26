#Requires -Version 5.1

<#
.SYNOPSIS
    Exporta ClaudeMem a documentos Markdown legibles y trazables.

.DESCRIPTION
    Lee decisiones.json, lecciones.json y hallazgos.json.
    Valida los archivos antes de exportar, respalda exportaciones anteriores,
    genera cinco documentos Markdown y un informe PASS/FAIL.

.VERSION
    1.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$ExportsFolder = Join-Path $ClaudeMemRoot "exports"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"
$EstadoFile = Join-Path $ClaudeMemRoot "estado.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"

$CompletoFile = Join-Path $ExportsFolder "ClaudeMem-Completo.md"
$DecisionesExport = Join-Path $ExportsFolder "ClaudeMem-Decisiones.md"
$LeccionesExport = Join-Path $ExportsFolder "ClaudeMem-Lecciones.md"
$HallazgosExport = Join-Path $ExportsFolder "ClaudeMem-Hallazgos.md"
$ResumenFile = Join-Path $ExportsFolder "ClaudeMem-Resumen.md"

$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupExportaciones = Join-Path $BackupsFolder "exportaciones-$MarcaTiempo.zip"
$ReportFile = Join-Path $ReportsFolder "Reporte-Exportacion-ClaudeMem-$MarcaTiempo.txt"

# ============================================================
# RESULTADOS
# ============================================================

$script:Resultados = @()

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

# ============================================================
# FUNCIONES GENERALES
# ============================================================

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Escribir-Log {
    param([Parameter(Mandatory = $true)][string]$Mensaje)

    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - EXPORTACION: $Mensaje" -Encoding UTF8
}

function Leer-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Ruta)

    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        throw "No existe el archivo requerido: $Ruta"
    }

    $Contenido = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if ($null -eq $Contenido -or $Contenido.Trim().Length -eq 0) {
        return @()
    }

    try {
        $Datos = $Contenido | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "JSON invalido en '$Ruta': $($_.Exception.Message)"
    }

    $Salida = @()
    foreach ($Elemento in @($Datos)) {
        if ($null -ne $Elemento) {
            $Salida += $Elemento
        }
    }
    return $Salida
}

function Obtener-PropiedadTexto {
    param(
        [Parameter(Mandatory = $true)][object]$Registro,
        [Parameter(Mandatory = $true)][string]$Nombre,
        [string]$Predeterminado = "No informado"
    )

    if ($Registro.PSObject.Properties.Name -contains $Nombre) {
        $Valor = $Registro.$Nombre
        if ($null -ne $Valor -and ([string]$Valor).Trim().Length -gt 0) {
            return [string]$Valor
        }
    }
    return $Predeterminado
}

function Obtener-ListaMarkdown {
    param(
        [Parameter(Mandatory = $true)][object]$Registro,
        [Parameter(Mandatory = $true)][string]$Nombre
    )

    if ($Registro.PSObject.Properties.Name -notcontains $Nombre) {
        return "Ninguno"
    }

    $Valores = @($Registro.$Nombre) | Where-Object {
        $null -ne $_ -and ([string]$_).Trim().Length -gt 0
    }

    if (@($Valores).Count -eq 0) {
        return "Ninguno"
    }

    return (($Valores | ForEach-Object { [string]$_ }) -join ", ")
}

function Escapar-Markdown {
    param([AllowNull()][AllowEmptyString()][string]$Texto)

    if ($null -eq $Texto) { return "" }
    return ($Texto -replace '\|', '\|')
}

function Crear-RespaldoExportaciones {
    $ArchivosPrevios = @(
        Get-ChildItem -LiteralPath $ExportsFolder -File -ErrorAction SilentlyContinue
    )

    if ($ArchivosPrevios.Count -eq 0) {
        return "Sin exportaciones anteriores"
    }

    Compress-Archive -LiteralPath $ArchivosPrevios.FullName `
        -DestinationPath $BackupExportaciones -CompressionLevel Optimal -Force

    if (-not (Test-Path -LiteralPath $BackupExportaciones -PathType Leaf)) {
        throw "No se pudo crear el respaldo de exportaciones."
    }

    $Tamano = (Get-Item -LiteralPath $BackupExportaciones).Length
    if ($Tamano -le 0) {
        throw "El respaldo de exportaciones fue creado sin contenido."
    }

    return "$BackupExportaciones - $Tamano bytes"
}

# ============================================================
# GENERADORES MARKDOWN
# ============================================================

function Convertir-DecisionMarkdown {
    param([Parameter(Mandatory = $true)][object]$Registro)

    $Id = Obtener-PropiedadTexto -Registro $Registro -Nombre "id"
    $Titulo = Obtener-PropiedadTexto -Registro $Registro -Nombre "titulo" -Predeterminado $Id
    $Descripcion = Obtener-PropiedadTexto -Registro $Registro -Nombre "descripcion"
    $Fecha = Obtener-PropiedadTexto -Registro $Registro -Nombre "fecha"
    $Estado = Obtener-PropiedadTexto -Registro $Registro -Nombre "estado"
    $Origen = Obtener-PropiedadTexto -Registro $Registro -Nombre "origen" -Predeterminado "ClaudeMem"
    $Tags = Obtener-ListaMarkdown -Registro $Registro -Nombre "tags"
    $Relacionados = Obtener-ListaMarkdown -Registro $Registro -Nombre "relacionados"

    return @"
## $Id - $Titulo

- **Tipo:** Decision
- **Fecha:** $Fecha
- **Estado:** $Estado
- **Tags:** $Tags
- **Relacionados:** $Relacionados
- **Origen:** $Origen

### Descripcion

$Descripcion

---
"@
}

function Convertir-LeccionMarkdown {
    param([Parameter(Mandatory = $true)][object]$Registro)

    $Id = Obtener-PropiedadTexto -Registro $Registro -Nombre "id"
    $Problema = Obtener-PropiedadTexto -Registro $Registro -Nombre "problema"
    $Solucion = Obtener-PropiedadTexto -Registro $Registro -Nombre "solucion"
    $Fecha = Obtener-PropiedadTexto -Registro $Registro -Nombre "fecha"
    $Estado = Obtener-PropiedadTexto -Registro $Registro -Nombre "estado" -Predeterminado "Activa"
    $Origen = Obtener-PropiedadTexto -Registro $Registro -Nombre "origen" -Predeterminado "ClaudeMem"
    $Tags = Obtener-ListaMarkdown -Registro $Registro -Nombre "tags"
    $Relacionados = Obtener-ListaMarkdown -Registro $Registro -Nombre "relacionados"

    return @"
## $Id

- **Tipo:** Leccion
- **Fecha:** $Fecha
- **Estado:** $Estado
- **Tags:** $Tags
- **Relacionados:** $Relacionados
- **Origen:** $Origen

### Problema

$Problema

### Solucion

$Solucion

---
"@
}

function Convertir-HallazgoMarkdown {
    param([Parameter(Mandatory = $true)][object]$Registro)

    $Id = Obtener-PropiedadTexto -Registro $Registro -Nombre "id"
    $Titulo = Obtener-PropiedadTexto -Registro $Registro -Nombre "titulo" -Predeterminado $Id
    $Descripcion = Obtener-PropiedadTexto -Registro $Registro -Nombre "descripcion"
    $Fecha = Obtener-PropiedadTexto -Registro $Registro -Nombre "fecha"
    $Estado = Obtener-PropiedadTexto -Registro $Registro -Nombre "estado" -Predeterminado "Abierto"
    $Origen = Obtener-PropiedadTexto -Registro $Registro -Nombre "origen" -Predeterminado "ClaudeMem"
    $Tags = Obtener-ListaMarkdown -Registro $Registro -Nombre "tags"
    $Relacionados = Obtener-ListaMarkdown -Registro $Registro -Nombre "relacionados"

    return @"
## $Id - $Titulo

- **Tipo:** Hallazgo
- **Fecha:** $Fecha
- **Estado:** $Estado
- **Tags:** $Tags
- **Relacionados:** $Relacionados
- **Origen:** $Origen

### Descripcion

$Descripcion

---
"@
}

function Guardar-Markdown {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][string]$Contenido
    )

    $Temporal = "$Ruta.tmp"
    Set-Content -LiteralPath $Temporal -Value $Contenido -Encoding UTF8

    if (-not (Test-Path -LiteralPath $Temporal -PathType Leaf)) {
        throw "No se genero el archivo temporal: $Temporal"
    }

    if ((Get-Item -LiteralPath $Temporal).Length -le 0) {
        throw "El archivo temporal quedo vacio: $Temporal"
    }

    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

# ============================================================
# INICIO
# ============================================================

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " EXPORTAR CLAUDEMEM A MARKDOWN" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

Crear-Carpeta -Ruta $ExportsFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder

if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

try {
    # --------------------------------------------------------
    # Leer y validar datos
    # --------------------------------------------------------

    $Decisiones = @(Leer-JsonArray -Ruta $DecisionesFile)
    $Lecciones = @(Leer-JsonArray -Ruta $LeccionesFile)
    $Hallazgos = @(Leer-JsonArray -Ruta $HallazgosFile)

    Agregar-Resultado -Id "EXP-001" -Prueba "Validar decisiones.json" `
        -Aprobada $true -Detalle "Registros: $($Decisiones.Count)"
    Agregar-Resultado -Id "EXP-002" -Prueba "Validar lecciones.json" `
        -Aprobada $true -Detalle "Registros: $($Lecciones.Count)"
    Agregar-Resultado -Id "EXP-003" -Prueba "Validar hallazgos.json" `
        -Aprobada $true -Detalle "Registros: $($Hallazgos.Count)"

    $TotalRegistros = $Decisiones.Count + $Lecciones.Count + $Hallazgos.Count

    # --------------------------------------------------------
    # Respaldo de exportaciones anteriores
    # --------------------------------------------------------

    $DetalleBackup = Crear-RespaldoExportaciones
    Agregar-Resultado -Id "EXP-004" -Prueba "Respaldar exportaciones anteriores" `
        -Aprobada $true -Detalle $DetalleBackup

    # --------------------------------------------------------
    # Construir documentos
    # --------------------------------------------------------

    $FechaExportacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $DocumentoDecisiones = "# ClaudeMem - Decisiones`r`n`r`n"
    $DocumentoDecisiones += "Exportado: $FechaExportacion`r`n`r`n"
    $DocumentoDecisiones += "Registros: $($Decisiones.Count)`r`n`r`n---`r`n"
    foreach ($Registro in $Decisiones) {
        $DocumentoDecisiones += Convertir-DecisionMarkdown -Registro $Registro
    }

    $DocumentoLecciones = "# ClaudeMem - Lecciones aprendidas`r`n`r`n"
    $DocumentoLecciones += "Exportado: $FechaExportacion`r`n`r`n"
    $DocumentoLecciones += "Registros: $($Lecciones.Count)`r`n`r`n---`r`n"
    foreach ($Registro in $Lecciones) {
        $DocumentoLecciones += Convertir-LeccionMarkdown -Registro $Registro
    }

    $DocumentoHallazgos = "# ClaudeMem - Hallazgos`r`n`r`n"
    $DocumentoHallazgos += "Exportado: $FechaExportacion`r`n`r`n"
    $DocumentoHallazgos += "Registros: $($Hallazgos.Count)`r`n`r`n---`r`n"
    foreach ($Registro in $Hallazgos) {
        $DocumentoHallazgos += Convertir-HallazgoMarkdown -Registro $Registro
    }

    $DocumentoResumen = @"
# ClaudeMem - Resumen

- **Fecha de exportacion:** $FechaExportacion
- **Decisiones:** $($Decisiones.Count)
- **Lecciones:** $($Lecciones.Count)
- **Hallazgos:** $($Hallazgos.Count)
- **Total de registros:** $TotalRegistros

## Archivos exportados

- ClaudeMem-Decisiones.md
- ClaudeMem-Lecciones.md
- ClaudeMem-Hallazgos.md
- ClaudeMem-Completo.md

## Trazabilidad

Origen: `$ClaudeMemRoot  
Exportador: Exportar-ClaudeMem-Markdown.ps1  
Formato de salida: Markdown UTF-8
"@

    $DocumentoCompleto = @"
# ClaudeMem - Exportacion completa

- **Fecha de exportacion:** $FechaExportacion
- **Total de registros:** $TotalRegistros

---

# Decisiones

$DocumentoDecisiones

# Lecciones aprendidas

$DocumentoLecciones

# Hallazgos

$DocumentoHallazgos
"@

    # --------------------------------------------------------
    # Guardar documentos
    # --------------------------------------------------------

    Guardar-Markdown -Ruta $DecisionesExport -Contenido $DocumentoDecisiones
    Guardar-Markdown -Ruta $LeccionesExport -Contenido $DocumentoLecciones
    Guardar-Markdown -Ruta $HallazgosExport -Contenido $DocumentoHallazgos
    Guardar-Markdown -Ruta $ResumenFile -Contenido $DocumentoResumen
    Guardar-Markdown -Ruta $CompletoFile -Contenido $DocumentoCompleto

    $Exportaciones = @(
        $CompletoFile,
        $DecisionesExport,
        $LeccionesExport,
        $HallazgosExport,
        $ResumenFile
    )

    foreach ($Archivo in $Exportaciones) {
        $Valido = (
            (Test-Path -LiteralPath $Archivo -PathType Leaf) -and
            ((Get-Item -LiteralPath $Archivo).Length -gt 0)
        )

        Agregar-Resultado -Id "EXP-005" -Prueba "Archivo Markdown generado" `
            -Aprobada $Valido -Detalle $Archivo
    }

    # --------------------------------------------------------
    # Validar cobertura de IDs
    # --------------------------------------------------------

    $ContenidoCompleto = Get-Content -LiteralPath $CompletoFile -Raw
    $Ids = @(
        @($Decisiones) + @($Lecciones) + @($Hallazgos) |
        ForEach-Object { [string]$_.id } |
        Where-Object { $null -ne $_ -and $_.Trim().Length -gt 0 }
    )

    $IdsFaltantes = @(
        $Ids | Where-Object {
            $ContenidoCompleto -notmatch [System.Text.RegularExpressions.Regex]::Escape($_)
        }
    )

    $CoberturaCorrecta = ($IdsFaltantes.Count -eq 0 -and $Ids.Count -eq $TotalRegistros)
    $DetalleCobertura = if ($CoberturaCorrecta) {
        "$($Ids.Count) de $TotalRegistros IDs exportados"
    }
    else {
        "IDs faltantes: $($IdsFaltantes -join ', ')"
    }

    Agregar-Resultado -Id "EXP-006" -Prueba "Cobertura total de registros" `
        -Aprobada $CoberturaCorrecta -Detalle $DetalleCobertura

    Escribir-Log "EXPORTACION COMPLETADA: $TotalRegistros registros"
}
catch {
    $Mensaje = $_.Exception.Message
    Agregar-Resultado -Id "EXP-ERR" -Prueba "Ejecucion general" `
        -Aprobada $false -Detalle $Mensaje
    Escribir-Log "ERROR: $Mensaje"
}

# ============================================================
# INFORME FINAL
# ============================================================

$TotalPruebas = $script:Resultados.Count
$Aprobadas = @($script:Resultados | Where-Object { $_.Estado -eq "PASS" }).Count
$Fallidas = $TotalPruebas - $Aprobadas

if ($TotalPruebas -gt 0) {
    $Porcentaje = [math]::Round(($Aprobadas / $TotalPruebas) * 100, 2)
}
else {
    $Porcentaje = 0
}

$EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }

$Cabecera = @(
    "===================================================="
    "REPORTE DE EXPORTACION CLAUDEMEM A MARKDOWN"
    "===================================================="
    ""
    "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Estado: $EstadoFinal"
    "Aprobadas: $Aprobadas"
    "Fallidas: $Fallidas"
    "Total: $TotalPruebas"
    "Resultado: $Porcentaje %"
    ""
)

$Cabecera | Set-Content -LiteralPath $ReportFile -Encoding UTF8
$script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize |
    Out-String | Add-Content -LiteralPath $ReportFile -Encoding UTF8

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " RESULTADO DE EXPORTACION" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize

Write-Host ""
Write-Host "Aprobadas: $Aprobadas / $TotalPruebas"
Write-Host "Resultado: $Porcentaje %"
Write-Host "Estado: $EstadoFinal"
Write-Host ""
Write-Host "Exportaciones:"
Write-Host $ExportsFolder
Write-Host ""
Write-Host "Informe:"
Write-Host $ReportFile
Write-Host ""

if ($Fallidas -gt 0) {
    exit 1
}
