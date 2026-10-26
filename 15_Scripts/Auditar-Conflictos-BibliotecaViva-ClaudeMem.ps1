#Requires -Version 5.1

<#
.SYNOPSIS
    Audita conflictos entre Biblioteca Viva y ClaudeMem sin modificar datos.

.DESCRIPTION
    Compara documentos Markdown DECISION-*.md, LECCION-*.md y HALLAZGO-*.md
    con decisiones.json, lecciones.json y hallazgos.json.

    Detecta:
    - IDs duplicados en Markdown o JSON.
    - Registros presentes solo en Markdown o solo en JSON.
    - Conflictos de tipo.
    - Diferencias de titulo y contenido.
    - Cambios con fechas incompatibles.
    - Registros sin origen o sin fecha.
    - Conflictos sin una base comun verificable.

    Este script es de solo lectura sobre los datos. Solo escribe informes,
    exportaciones de auditoria y logs.

.VERSION
    1.1.0
#>

[CmdletBinding(DefaultParameterSetName = "Auditar")]
param(
    [Parameter(ParameterSetName = "Auditar")]
    [switch]$Auditar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada,

    [Parameter(ParameterSetName = "Auditar")]
    [switch]$IncluirCoincidencias
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$ConocimientoRoot = Join-Path $CopilotRoot "03_Conocimiento"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$ExportsFolder = Join-Path $ClaudeMemRoot "exports\conflictos"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$FuentesJson = @(
    [PSCustomObject]@{ Tipo = "decision"; Ruta = (Join-Path $DataFolder "decisiones.json") },
    [PSCustomObject]@{ Tipo = "leccion"; Ruta = (Join-Path $DataFolder "lecciones.json") },
    [PSCustomObject]@{ Tipo = "hallazgo"; Ruta = (Join-Path $DataFolder "hallazgos.json") }
)

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Escribir-Log {
    param([Parameter(Mandatory = $true)][string]$Mensaje)
    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - CONFLICTOS: $Mensaje" -Encoding UTF8
}

function Convertir-ALista {
    param([AllowNull()][object]$Valor)
    $Salida = @()
    if ($null -eq $Valor) { return $Salida }
    if ($Valor -is [System.Array]) {
        foreach ($Elemento in $Valor) {
            if ($null -ne $Elemento) { $Salida += $Elemento }
        }
    }
    else { $Salida += $Valor }
    return $Salida
}

function Leer-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        throw "No existe el archivo requerido: $Ruta"
    }
    $Texto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if ($null -eq $Texto -or $Texto.Trim().Length -eq 0) { return @() }
    $Objeto = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    return (Convertir-ALista -Valor $Objeto)
}

function Obtener-TextoPropiedad {
    param(
        [Parameter(Mandatory = $true)][object]$Objeto,
        [Parameter(Mandatory = $true)][string]$Nombre,
        [string]$Predeterminado = ""
    )
    if ($Objeto.PSObject.Properties.Name -contains $Nombre) {
        $Valor = $Objeto.$Nombre
        if ($null -ne $Valor) { return [string]$Valor }
    }
    return $Predeterminado
}

function Normalizar-Texto {
    param([AllowNull()][AllowEmptyString()][string]$Texto)
    if ($null -eq $Texto) { return "" }
    $Limpio = $Texto.ToLowerInvariant()
    $Limpio = [regex]::Replace($Limpio, '\s+', ' ')
    $Limpio = [regex]::Replace($Limpio, '[^\p{L}\p{Nd}\s-]', '')
    return $Limpio.Trim()
}

function Obtener-FechaSegura {
    param([AllowNull()][AllowEmptyString()][string]$Valor)
    if ($null -eq $Valor -or $Valor.Trim().Length -eq 0) { return $null }
    $Fecha = [datetime]::MinValue
    if ([datetime]::TryParse($Valor, [ref]$Fecha)) { return $Fecha }
    return $null
}

function Obtener-TipoDesdeId {
    param([Parameter(Mandatory = $true)][string]$Id)
    if ($Id -match '^DECISION-') { return "decision" }
    if ($Id -match '^LECCION-') { return "leccion" }
    if ($Id -match '^HALLAZGO-') { return "hallazgo" }
    return "desconocido"
}

function Obtener-TituloMarkdown {
    param(
        [Parameter(Mandatory = $true)][string]$Contenido,
        [Parameter(Mandatory = $true)][string]$Alternativo
    )
    foreach ($Linea in @($Contenido -split "`r?`n")) {
        if ($Linea -match '^\s*#\s+(.+?)\s*$') { return $Matches[1].Trim() }
    }
    return $Alternativo
}

function Obtener-ResumenMarkdown {
    param([Parameter(Mandatory = $true)][string]$Contenido)

    $Lineas = @($Contenido -split "`r?`n")
    $IndiceContenido = -1

    for ($Indice = 0; $Indice -lt $Lineas.Count; $Indice++) {
        if ($Lineas[$Indice] -match '^\s*##\s+Contenido\s*$') {
            $IndiceContenido = $Indice
            break
        }
    }

    if ($IndiceContenido -ge 0) {
        $Seleccionadas = @()
        for ($Indice = $IndiceContenido + 1; $Indice -lt $Lineas.Count; $Indice++) {
            $Linea = $Lineas[$Indice]
            if ($Linea -match '^\s*#{1,6}\s+') { break }
            $TextoLinea = $Linea.Trim()
            if ($TextoLinea.Length -gt 0) { $Seleccionadas += $TextoLinea }
        }
        return ($Seleccionadas -join ' ').Trim()
    }

    $Resultado = @()
    $OmitirSiguienteValor = $false

    foreach ($Linea in $Lineas) {
        $TextoLinea = $Linea.Trim()

        if ($TextoLinea -match '^\s*##\s+ID\s*$') {
            $OmitirSiguienteValor = $true
            continue
        }
        if ($TextoLinea -match '^\s*#{1,6}\s+') {
            $OmitirSiguienteValor = $false
            continue
        }
        if ($TextoLinea -match '^\s*Fecha\s*:') { continue }
        if ($TextoLinea.Length -eq 0) { continue }
        if ($OmitirSiguienteValor) {
            $OmitirSiguienteValor = $false
            continue
        }
        $Resultado += $TextoLinea
    }

    return ($Resultado -join ' ').Trim()
}

function Obtener-FechaMarkdown {
    param(
        [Parameter(Mandatory = $true)][string]$Contenido,
        [Parameter(Mandatory = $true)][datetime]$FechaArchivo
    )
    foreach ($Linea in @($Contenido -split "`r?`n")) {
        if ($Linea -match '^\s*Fecha\s*:\s*(.+?)\s*$') {
            $Fecha = Obtener-FechaSegura -Valor $Matches[1]
            if ($null -ne $Fecha) { return $Fecha }
        }
    }
    return $FechaArchivo
}

function Obtener-RegistrosMarkdown {
    $Registros = @()
    if (-not (Test-Path -LiteralPath $ConocimientoRoot -PathType Container)) {
        return $Registros
    }

    $Archivos = @(
        Get-ChildItem -LiteralPath $ConocimientoRoot -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^(DECISION|LECCION|HALLAZGO)-.*\.md$' }
    )

    foreach ($Archivo in $Archivos) {
        $Contenido = Get-Content -LiteralPath $Archivo.FullName -Raw -ErrorAction Stop
        if ($null -eq $Contenido) { $Contenido = "" }
        $Id = $Archivo.BaseName
        $Tipo = Obtener-TipoDesdeId -Id $Id
        $Titulo = Obtener-TituloMarkdown -Contenido $Contenido -Alternativo $Id
        $Resumen = Obtener-ResumenMarkdown -Contenido $Contenido
        $Fecha = Obtener-FechaMarkdown -Contenido $Contenido -FechaArchivo $Archivo.LastWriteTime

        $Registros += [PSCustomObject]@{
            id = $Id
            tipo = $Tipo
            titulo = $Titulo
            contenido = $Resumen
            fecha = $Fecha
            fechaTexto = $Fecha.ToString('yyyy-MM-dd HH:mm:ss')
            origen = $Archivo.FullName
            lado = "Markdown"
            objeto = $null
        }
    }
    return $Registros
}

function Obtener-RegistrosJson {
    $Registros = @()
    foreach ($Fuente in $FuentesJson) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $Id = Obtener-TextoPropiedad -Objeto $Registro -Nombre "id"
            $Tipo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "tipo" -Predeterminado $Fuente.Tipo
            $Titulo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "titulo"
            if ($Titulo.Length -eq 0) { $Titulo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "problema" }
            if ($Titulo.Length -eq 0) { $Titulo = $Id }

            $Contenido = Obtener-TextoPropiedad -Objeto $Registro -Nombre "descripcion"
            if ($Contenido.Length -eq 0) { $Contenido = Obtener-TextoPropiedad -Objeto $Registro -Nombre "solucion" }

            $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fecha"
            if ($FechaTexto.Length -eq 0) { $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fechaSincronizacion" }
            if ($FechaTexto.Length -eq 0) { $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fechaCreacion" }
            $Fecha = Obtener-FechaSegura -Valor $FechaTexto

            $Origen = Obtener-TextoPropiedad -Objeto $Registro -Nombre "origen" -Predeterminado $Fuente.Ruta

            $Registros += [PSCustomObject]@{
                id = $Id
                tipo = $Tipo
                titulo = $Titulo
                contenido = $Contenido
                fecha = $Fecha
                fechaTexto = $FechaTexto
                origen = $Origen
                lado = "JSON"
                objeto = $Registro
            }
        }
    }
    return $Registros
}

function Crear-Hallazgo {
    param(
        [Parameter(Mandatory = $true)][string]$Codigo,
        [Parameter(Mandatory = $true)][string]$Severidad,
        [Parameter(Mandatory = $true)][string]$Tipo,
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Detalle,
        [Parameter(Mandatory = $true)][string]$Recomendacion
    )
    return [PSCustomObject]@{
        codigo = $Codigo
        severidad = $Severidad
        tipo = $Tipo
        id = $Id
        detalle = $Detalle
        recomendacion = $Recomendacion
    }
}

function Ejecutar-AuditoriaConflictos {
    param(
        [Parameter(Mandatory = $true)][array]$Markdown,
        [Parameter(Mandatory = $true)][array]$Json
    )

    $Hallazgos = @()

    foreach ($Grupo in @($Markdown | Group-Object id | Where-Object Count -gt 1)) {
        $Hallazgos += Crear-Hallazgo -Codigo "CON-001" -Severidad "CRITICA" -Tipo "ID_DUPLICADO_MARKDOWN" -Id $Grupo.Name -Detalle "Existen $($Grupo.Count) documentos Markdown con el mismo ID." -Recomendacion "Conservar un solo documento fuente y archivar los duplicados."
    }
    foreach ($Grupo in @($Json | Group-Object id | Where-Object Count -gt 1)) {
        $Hallazgos += Crear-Hallazgo -Codigo "CON-002" -Severidad "CRITICA" -Tipo "ID_DUPLICADO_JSON" -Id $Grupo.Name -Detalle "Existen $($Grupo.Count) registros JSON con el mismo ID." -Recomendacion "Revisar manualmente y conservar un unico registro valido."
    }

    $IdsMarkdown = @($Markdown.id | Sort-Object -Unique)
    $IdsJson = @($Json.id | Sort-Object -Unique)
    $TodosIds = @(($IdsMarkdown + $IdsJson) | Sort-Object -Unique)
    $Coincidencias = @()

    foreach ($RegistroId in $TodosIds) {
        $M = @($Markdown | Where-Object id -eq $RegistroId)
        $J = @($Json | Where-Object id -eq $RegistroId)

        if ($M.Count -eq 1 -and $J.Count -eq 0) {
            $Hallazgos += Crear-Hallazgo -Codigo "CON-003" -Severidad "MEDIA" -Tipo "SOLO_MARKDOWN" -Id $RegistroId -Detalle "El ID existe en Biblioteca Viva, pero no en ClaudeMem JSON." -Recomendacion "Importar despues de revisar que el documento sea vigente."
            continue
        }
        if ($M.Count -eq 0 -and $J.Count -eq 1) {
            $Hallazgos += Crear-Hallazgo -Codigo "CON-004" -Severidad "BAJA" -Tipo "SOLO_JSON" -Id $RegistroId -Detalle "El ID existe en ClaudeMem JSON, pero no tiene documento Markdown equivalente." -Recomendacion "Decidir si debe exportarse a Biblioteca Viva o conservarse solo en ClaudeMem."
            continue
        }
        if ($M.Count -ne 1 -or $J.Count -ne 1) { continue }

        $MarkdownRegistro = $M[0]
        $JsonRegistro = $J[0]
        $RegistroCoincide = $true

        if ($MarkdownRegistro.tipo -ne $JsonRegistro.tipo) {
            $RegistroCoincide = $false
            $Hallazgos += Crear-Hallazgo -Codigo "CON-005" -Severidad "ALTA" -Tipo "TIPO_DIFERENTE" -Id $RegistroId -Detalle "Markdown=$($MarkdownRegistro.tipo); JSON=$($JsonRegistro.tipo)." -Recomendacion "Corregir el tipo antes de cualquier sincronizacion."
        }

        $TituloM = Normalizar-Texto -Texto $MarkdownRegistro.titulo
        $TituloJ = Normalizar-Texto -Texto $JsonRegistro.titulo
        if ($TituloM -ne $TituloJ) {
            $RegistroCoincide = $false
            $Hallazgos += Crear-Hallazgo -Codigo "CON-006" -Severidad "MEDIA" -Tipo "TITULO_DIFERENTE" -Id $RegistroId -Detalle "Los titulos normalizados son diferentes." -Recomendacion "Revisar ambos titulos y elegir la formulacion vigente."
        }

        $ContenidoM = Normalizar-Texto -Texto $MarkdownRegistro.contenido
        $ContenidoJ = Normalizar-Texto -Texto $JsonRegistro.contenido
        if ($ContenidoM -ne $ContenidoJ) {
            $RegistroCoincide = $false
            $FechaM = $MarkdownRegistro.fecha
            $FechaJ = $JsonRegistro.fecha
            $DetalleFecha = "No hay fechas comparables."
            $Recomendacion = "Revisar manualmente; no sobrescribir automaticamente."

            if ($null -ne $FechaM -and $null -ne $FechaJ) {
                if ($FechaM -gt $FechaJ) {
                    $DetalleFecha = "Markdown parece mas reciente ($($FechaM.ToString('yyyy-MM-dd HH:mm:ss'))) que JSON ($($FechaJ.ToString('yyyy-MM-dd HH:mm:ss')))."
                    $Recomendacion = "Revisar el cambio Markdown y aprobar una importacion controlada."
                }
                elseif ($FechaJ -gt $FechaM) {
                    $DetalleFecha = "JSON parece mas reciente ($($FechaJ.ToString('yyyy-MM-dd HH:mm:ss'))) que Markdown ($($FechaM.ToString('yyyy-MM-dd HH:mm:ss')))."
                    $Recomendacion = "Revisar el cambio JSON y aprobar una exportacion controlada."
                }
                else {
                    $DetalleFecha = "Ambos lados tienen la misma fecha, pero contenido diferente."
                    $Recomendacion = "Conflicto ambiguo: resolver manualmente."
                }
            }

            $Hallazgos += Crear-Hallazgo -Codigo "CON-007" -Severidad "ALTA" -Tipo "CONTENIDO_DIFERENTE" -Id $RegistroId -Detalle $DetalleFecha -Recomendacion $Recomendacion
        }

        if ($JsonRegistro.origen.Trim().Length -eq 0) {
            $Hallazgos += Crear-Hallazgo -Codigo "CON-008" -Severidad "BAJA" -Tipo "ORIGEN_JSON_VACIO" -Id $RegistroId -Detalle "El registro JSON no contiene origen verificable." -Recomendacion "Registrar origen antes de sincronizar bidireccionalmente."
        }

        if ($RegistroCoincide) {
            $Coincidencias += $RegistroId
        }
    }

    return [PSCustomObject]@{
        markdown = $Markdown.Count
        json = $Json.Count
        coincidencias = $Coincidencias
        hallazgos = $Hallazgos
    }
}

function Exportar-Auditoria {
    param(
        [Parameter(Mandatory = $true)][object]$Resultado,
        [Parameter(Mandatory = $true)][string]$NombreBase
    )

    Crear-Carpeta -Ruta $ReportsFolder
    Crear-Carpeta -Ruta $ExportsFolder

    $TxtFile = Join-Path $ReportsFolder "$NombreBase-$MarcaTiempo.txt"
    $JsonFile = Join-Path $ExportsFolder "$NombreBase-$MarcaTiempo.json"
    $Hallazgos = @($Resultado.hallazgos)

    @(
        "REPORTE DE CONFLICTOS BIBLIOTECA VIVA - CLAUDEMEM"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Documentos Markdown: $($Resultado.markdown)"
        "Registros JSON: $($Resultado.json)"
        "Coincidencias exactas: $(@($Resultado.coincidencias).Count)"
        "Hallazgos: $($Hallazgos.Count)"
        "Estado: $(if ($Hallazgos.Count -eq 0) { 'APROBADO' } else { 'REQUIERE REVISION' })"
        ""
    ) | Set-Content -LiteralPath $TxtFile -Encoding UTF8

    if ($Hallazgos.Count -gt 0) {
        $Hallazgos | Format-Table codigo, severidad, tipo, id, detalle, recomendacion -AutoSize |
            Out-String | Add-Content -LiteralPath $TxtFile -Encoding UTF8
    }

    $SalidaJson = [PSCustomObject][ordered]@{
        fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        markdown = $Resultado.markdown
        json = $Resultado.json
        coincidencias = @($Resultado.coincidencias)
        hallazgos = @($Hallazgos)
    }
    $SalidaJson | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $JsonFile -Encoding UTF8
    $null = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json -ErrorAction Stop

    return @($TxtFile, $JsonFile)
}

function Mostrar-Resultado {
    param(
        [Parameter(Mandatory = $true)][object]$Resultado,
        [switch]$MostrarCoincidencias
    )

    $Hallazgos = @($Resultado.hallazgos)
    Write-Host ""
    Write-Host "AUDITORIA CONFLICTOS BIBLIOTECA VIVA - CLAUDEMEM" -ForegroundColor Cyan
    Write-Host "Documentos Markdown: $($Resultado.markdown)"
    Write-Host "Registros JSON: $($Resultado.json)"
    Write-Host "Coincidencias exactas: $(@($Resultado.coincidencias).Count)"
    Write-Host "Hallazgos: $($Hallazgos.Count)"
    Write-Host ""

    if ($MostrarCoincidencias -and @($Resultado.coincidencias).Count -gt 0) {
        Write-Host "Coincidencias:" -ForegroundColor Green
        $Resultado.coincidencias | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
    }

    if ($Hallazgos.Count -eq 0) {
        Write-Host "AUDITORIA APROBADA" -ForegroundColor Green
    }
    else {
        $Hallazgos | Format-Table codigo, severidad, tipo, id, detalle -AutoSize
        Write-Host "REQUIERE REVISION MANUAL" -ForegroundColor Yellow
    }
}

function Ejecutar-PruebaControlada {
    $MarkdownPrueba = @(
        [PSCustomObject]@{ id="DECISION-PRUEBA-001"; tipo="decision"; titulo="Titulo comun"; contenido="Contenido A"; fecha=[datetime]"2026-10-21 10:00"; fechaTexto="2026-10-21 10:00"; origen="prueba.md"; lado="Markdown"; objeto=$null },
        [PSCustomObject]@{ id="LECCION-SOLO-MD"; tipo="leccion"; titulo="Solo MD"; contenido="Contenido"; fecha=[datetime]"2026-10-21"; fechaTexto="2026-10-21"; origen="prueba2.md"; lado="Markdown"; objeto=$null }
    )
    $JsonPrueba = @(
        [PSCustomObject]@{ id="DECISION-PRUEBA-001"; tipo="decision"; titulo="Titulo comun"; contenido="Contenido B"; fecha=[datetime]"2026-10-21 09:00"; fechaTexto="2026-10-21 09:00"; origen="ClaudeMem"; lado="JSON"; objeto=$null },
        [PSCustomObject]@{ id="HALLAZGO-SOLO-JSON"; tipo="hallazgo"; titulo="Solo JSON"; contenido="Contenido"; fecha=[datetime]"2026-10-21"; fechaTexto="2026-10-21"; origen="ClaudeMem"; lado="JSON"; objeto=$null }
    )

    $Resultado = Ejecutar-AuditoriaConflictos -Markdown $MarkdownPrueba -Json $JsonPrueba
    $Hallazgos = @($Resultado.hallazgos)
    $Pruebas = @(
        [PSCustomObject]@{ Estado=$(if (@($Hallazgos | Where-Object tipo -eq "CONTENIDO_DIFERENTE").Count -eq 1) {"PASS"} else {"FAIL"}); Prueba="Detectar contenido diferente" },
        [PSCustomObject]@{ Estado=$(if (@($Hallazgos | Where-Object tipo -eq "SOLO_MARKDOWN").Count -eq 1) {"PASS"} else {"FAIL"}); Prueba="Detectar solo Markdown" },
        [PSCustomObject]@{ Estado=$(if (@($Hallazgos | Where-Object tipo -eq "SOLO_JSON").Count -eq 1) {"PASS"} else {"FAIL"}); Prueba="Detectar solo JSON" },
        [PSCustomObject]@{ Estado=$(if (@($Hallazgos | Where-Object { $_.recomendacion -match "importacion controlada" }).Count -ge 1) {"PASS"} else {"FAIL"}); Prueba="Recomendar resolucion sin sobrescribir" }
    )

    $Archivos = @(Exportar-Auditoria -Resultado $Resultado -NombreBase "Reporte-Prueba-Conflictos-ClaudeMem")
    $ExportacionOk = ($Archivos.Count -eq 2 -and @($Archivos | Where-Object { (Get-Item -LiteralPath $_).Length -gt 0 }).Count -eq 2)
    $Pruebas += [PSCustomObject]@{ Estado=$(if ($ExportacionOk) {"PASS"} else {"FAIL"}); Prueba="Generar informes TXT y JSON" }

    $Aprobadas = @($Pruebas | Where-Object Estado -eq "PASS").Count
    $Total = $Pruebas.Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = [math]::Round(($Aprobadas / $Total) * 100, 2)

    Write-Host ""
    Write-Host "RESULTADO PRUEBA DE CONFLICTOS" -ForegroundColor Cyan
    $Pruebas | Format-Table -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $(if ($Fallidas -eq 0) {'APROBADO'} else {'NO APROBADO'})"
    Write-Host "Informes:"
    $Archivos | ForEach-Object { Write-Host $_ }

    if ($Fallidas -gt 0) { exit 1 }
}

Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $ExportsFolder
Crear-Carpeta -Ruta $LogsFolder
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

try {
    if ($PSCmdlet.ParameterSetName -eq "Prueba") {
        Ejecutar-PruebaControlada
        exit 0
    }

    $Markdown = @(Obtener-RegistrosMarkdown)
    $Json = @(Obtener-RegistrosJson)
    $Resultado = Ejecutar-AuditoriaConflictos -Markdown $Markdown -Json $Json
    Mostrar-Resultado -Resultado $Resultado -MostrarCoincidencias:$IncluirCoincidencias
    $Archivos = @(Exportar-Auditoria -Resultado $Resultado -NombreBase "Reporte-Conflictos-BibliotecaViva-ClaudeMem")

    Write-Host ""
    Write-Host "Informes generados:"
    $Archivos | ForEach-Object { Write-Host $_ }

    Escribir-Log "AUDITORIA: markdown=$($Markdown.Count); json=$($Json.Count); hallazgos=$(@($Resultado.hallazgos).Count)"

    # Los conflictos esperados no producen exit 1. Solo los errores tecnicos.
    # El informe es la entrada para el siguiente hito de resolucion controlada.
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN AUDITORIA DE CONFLICTOS" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
