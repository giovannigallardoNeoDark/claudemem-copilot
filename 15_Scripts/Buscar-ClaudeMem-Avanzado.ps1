#Requires -Version 5.1

<#
.SYNOPSIS
    Busqueda avanzada y exportable de ClaudeMem.

.DESCRIPTION
    Permite combinar filtros por texto, tipo, ID, tag, estado, fecha,
    origen/proyecto y papelera. Puede ordenar y exportar resultados a
    Markdown y JSON. Incluye una prueba controlada que no modifica datos.

.EXAMPLE
    .\Buscar-ClaudeMem-Avanzado.ps1 -Texto "Biblioteca"

.EXAMPLE
    .\Buscar-ClaudeMem-Avanzado.ps1 -Tipo decision -Tag ClaudeMem

.EXAMPLE
    .\Buscar-ClaudeMem-Avanzado.ps1 -Desde 2026-10-01 -Hasta 2026-10-31 -Exportar Ambos

.EXAMPLE
    .\Buscar-ClaudeMem-Avanzado.ps1 -IncluirPapelera -Estado EN_PAPELERA

.EXAMPLE
    .\Buscar-ClaudeMem-Avanzado.ps1 -PruebaControlada

.VERSION
    1.1.0
#>

[CmdletBinding(DefaultParameterSetName = "Buscar")]
param(
    [Parameter(ParameterSetName = "Buscar")]
    [AllowEmptyString()]
    [string]$Texto,

    [Parameter(ParameterSetName = "Buscar")]
    [ValidateSet("todos", "decision", "leccion", "hallazgo")]
    [string]$Tipo = "todos",

    [Parameter(ParameterSetName = "Buscar")]
    [AllowEmptyString()]
    [string]$Id,

    [Parameter(ParameterSetName = "Buscar")]
    [AllowEmptyString()]
    [string]$Tag,

    [Parameter(ParameterSetName = "Buscar")]
    [AllowEmptyString()]
    [string]$Estado,

    [Parameter(ParameterSetName = "Buscar")]
    [Nullable[datetime]]$Desde,

    [Parameter(ParameterSetName = "Buscar")]
    [Nullable[datetime]]$Hasta,

    [Parameter(ParameterSetName = "Buscar")]
    [AllowEmptyString()]
    [string]$Origen,

    [Parameter(ParameterSetName = "Buscar")]
    [switch]$IncluirPapelera,

    [Parameter(ParameterSetName = "Buscar")]
    [ValidateSet("fecha_desc", "fecha_asc", "id", "tipo")]
    [string]$Orden = "fecha_desc",

    [Parameter(ParameterSetName = "Buscar")]
    [ValidateSet("Ninguno", "Markdown", "JSON", "Ambos")]
    [string]$Exportar = "Ninguno",

    [Parameter(ParameterSetName = "Buscar")]
    [ValidateRange(1, 10000)]
    [int]$Limite = 500,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$PapeleraFolder = Join-Path $DataFolder "papelera"
$ExportsFolder = Join-Path $ClaudeMemRoot "exports\busquedas"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$Fuentes = @(
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
    Add-Content -LiteralPath $LogFile -Value "$Fecha - BUSQUEDA AVANZADA: $Mensaje" -Encoding UTF8
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
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { return @() }
    $TextoJson = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if ($null -eq $TextoJson -or $TextoJson.Trim().Length -eq 0) { return @() }
    $Objeto = ConvertFrom-Json -InputObject $TextoJson -ErrorAction Stop
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

function Obtener-ListaPropiedad {
    param(
        [Parameter(Mandatory = $true)][object]$Objeto,
        [Parameter(Mandatory = $true)][string]$Nombre
    )
    if ($Objeto.PSObject.Properties.Name -contains $Nombre) {
        return @(Convertir-ALista -Valor $Objeto.$Nombre | ForEach-Object { [string]$_ })
    }
    return @()
}

function Convertir-FechaSegura {
    param([AllowNull()][AllowEmptyString()][string]$Valor)
    if ($null -eq $Valor -or $Valor.Trim().Length -eq 0) { return $null }
    $Fecha = [datetime]::MinValue
    if ([datetime]::TryParse($Valor, [ref]$Fecha)) { return $Fecha }
    return $null
}

function Crear-RegistroBusqueda {
    param(
        [Parameter(Mandatory = $true)][object]$Registro,
        [Parameter(Mandatory = $true)][string]$TipoRegistro,
        [Parameter(Mandatory = $true)][string]$Ubicacion,
        [Parameter(Mandatory = $true)][string]$FuenteArchivo
    )

    $IdRegistro = Obtener-TextoPropiedad -Objeto $Registro -Nombre "id"
    $Titulo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "titulo"
    if ($Titulo.Length -eq 0) { $Titulo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "problema" }
    if ($Titulo.Length -eq 0) { $Titulo = Obtener-TextoPropiedad -Objeto $Registro -Nombre "descripcion" }
    if ($Titulo.Length -eq 0) { $Titulo = $IdRegistro }

    $Descripcion = Obtener-TextoPropiedad -Objeto $Registro -Nombre "descripcion"
    if ($Descripcion.Length -eq 0) { $Descripcion = Obtener-TextoPropiedad -Objeto $Registro -Nombre "solucion" }

    $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fecha"
    if ($FechaTexto.Length -eq 0) { $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fechaCreacion" }
    if ($FechaTexto.Length -eq 0) { $FechaTexto = Obtener-TextoPropiedad -Objeto $Registro -Nombre "fechaEliminacion" }

    $Tags = Obtener-ListaPropiedad -Objeto $Registro -Nombre "tags"
    $Relacionados = Obtener-ListaPropiedad -Objeto $Registro -Nombre "relacionados"
    $EstadoRegistro = Obtener-TextoPropiedad -Objeto $Registro -Nombre "estado"
    if ($EstadoRegistro.Length -eq 0) { $EstadoRegistro = Obtener-TextoPropiedad -Objeto $Registro -Nombre "estadoPapelera" }
    $OrigenRegistro = Obtener-TextoPropiedad -Objeto $Registro -Nombre "origen"
    if ($OrigenRegistro.Length -eq 0) { $OrigenRegistro = Obtener-TextoPropiedad -Objeto $Registro -Nombre "archivoOrigen" }

    $TextoCompleto = $Registro | ConvertTo-Json -Depth 40 -Compress

    return [PSCustomObject]@{
        id = $IdRegistro
        tipo = $TipoRegistro
        titulo = $Titulo
        descripcion = $Descripcion
        fecha = $FechaTexto
        fechaOrden = Convertir-FechaSegura -Valor $FechaTexto
        estado = $EstadoRegistro
        tags = @($Tags)
        tagsTexto = ($Tags -join ", ")
        relacionados = @($Relacionados)
        origen = $OrigenRegistro
        ubicacion = $Ubicacion
        fuente = $FuenteArchivo
        textoCompleto = $TextoCompleto
    }
}

function Obtener-TodosLosRegistros {
    param([switch]$ConPapelera)

    $Salida = @()
    foreach ($Fuente in $Fuentes) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $Salida += Crear-RegistroBusqueda `
                -Registro $Registro `
                -TipoRegistro $Fuente.Tipo `
                -Ubicacion "activo" `
                -FuenteArchivo $Fuente.Ruta
        }
    }

    if ($ConPapelera -and (Test-Path -LiteralPath $PapeleraFolder -PathType Container)) {
        foreach ($Archivo in @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
            try {
                $Entrada = Get-Content -LiteralPath $Archivo.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                $Propiedades = @($Entrada.PSObject.Properties.Name)
                if ($Propiedades -contains "registro" -and $Propiedades -contains "estadoPapelera") {
                    $RegistroInterno = $Entrada.registro
                    $TipoPapelera = Obtener-TextoPropiedad -Objeto $Entrada -Nombre "tipo" -Predeterminado "desconocido"
                    $Resultado = Crear-RegistroBusqueda `
                        -Registro $RegistroInterno `
                        -TipoRegistro $TipoPapelera `
                        -Ubicacion ([string]$Entrada.estadoPapelera) `
                        -FuenteArchivo $Archivo.FullName

                    if ($Entrada.PSObject.Properties.Name -contains "fechaEliminacion") {
                        $Resultado.fecha = [string]$Entrada.fechaEliminacion
                        $Resultado.fechaOrden = Convertir-FechaSegura -Valor $Resultado.fecha
                    }
                    if ($Entrada.PSObject.Properties.Name -contains "motivo") {
                        $Resultado.descripcion = "Motivo: $([string]$Entrada.motivo). $($Resultado.descripcion)"
                    }
                    $Salida += $Resultado
                }
            }
            catch {
                Escribir-Log "PAPELERA IGNORADA: $($Archivo.FullName); $($_.Exception.Message)"
            }
        }
    }

    return $Salida
}

function Aplicar-Filtros {
    param(
        [Parameter(Mandatory = $true)][array]$Registros,
        [AllowEmptyString()][string]$FiltroTexto,
        [string]$FiltroTipo,
        [AllowEmptyString()][string]$FiltroId,
        [AllowEmptyString()][string]$FiltroTag,
        [AllowEmptyString()][string]$FiltroEstado,
        [Nullable[datetime]]$FechaDesde,
        [Nullable[datetime]]$FechaHasta,
        [AllowEmptyString()][string]$FiltroOrigen
    )

    $Resultado = @($Registros)

    if ($null -ne $FiltroTexto -and $FiltroTexto.Trim().Length -gt 0) {
        $Patron = [regex]::Escape($FiltroTexto.Trim())
        $Resultado = @($Resultado | Where-Object { $_.textoCompleto -match $Patron })
    }
    if ($FiltroTipo -ne "todos") {
        $Resultado = @($Resultado | Where-Object { $_.tipo -eq $FiltroTipo })
    }
    if ($null -ne $FiltroId -and $FiltroId.Trim().Length -gt 0) {
        $PatronId = [regex]::Escape($FiltroId.Trim())
        $Resultado = @($Resultado | Where-Object { $_.id -match $PatronId })
    }
    if ($null -ne $FiltroTag -and $FiltroTag.Trim().Length -gt 0) {
        $PatronTag = [regex]::Escape($FiltroTag.Trim())
        $Resultado = @($Resultado | Where-Object { $_.tagsTexto -match $PatronTag })
    }
    if ($null -ne $FiltroEstado -and $FiltroEstado.Trim().Length -gt 0) {
        $PatronEstado = [regex]::Escape($FiltroEstado.Trim())
        $Resultado = @($Resultado | Where-Object { $_.estado -match $PatronEstado -or $_.ubicacion -match $PatronEstado })
    }
    if ($null -ne $FechaDesde) {
        $Resultado = @($Resultado | Where-Object { $null -ne $_.fechaOrden -and $_.fechaOrden -ge ([datetime]$FechaDesde).Date })
    }
    if ($null -ne $FechaHasta) {
        $FinDia = ([datetime]$FechaHasta).Date.AddDays(1).AddTicks(-1)
        $Resultado = @($Resultado | Where-Object { $null -ne $_.fechaOrden -and $_.fechaOrden -le $FinDia })
    }
    if ($null -ne $FiltroOrigen -and $FiltroOrigen.Trim().Length -gt 0) {
        $PatronOrigen = [regex]::Escape($FiltroOrigen.Trim())
        $Resultado = @($Resultado | Where-Object { $_.origen -match $PatronOrigen -or $_.fuente -match $PatronOrigen })
    }

    return $Resultado
}

function Ordenar-Resultados {
    param(
        [Parameter(Mandatory = $true)][array]$Resultados,
        [Parameter(Mandatory = $true)][string]$Criterio
    )
    switch ($Criterio) {
        "fecha_asc" { return @($Resultados | Sort-Object fechaOrden, id) }
        "id" { return @($Resultados | Sort-Object id) }
        "tipo" { return @($Resultados | Sort-Object tipo, id) }
        default { return @($Resultados | Sort-Object fechaOrden, id -Descending) }
    }
}

function Exportar-Resultados {
    param(
        [Parameter(Mandatory = $true)][array]$Resultados,
        [Parameter(Mandatory = $true)][string]$Formato,
        [Parameter(Mandatory = $true)][hashtable]$Filtros
    )

    Crear-Carpeta -Ruta $ExportsFolder
    $Base = Join-Path $ExportsFolder "Busqueda-ClaudeMem-$MarcaTiempo"
    $Archivos = @()

    if ($Formato -eq "JSON" -or $Formato -eq "Ambos") {
        $JsonFile = "$Base.json"
        $SalidaJson = @($Resultados | Select-Object id, tipo, titulo, descripcion, fecha, estado, tags, relacionados, origen, ubicacion, fuente)
        ConvertTo-Json -InputObject ([object[]]$SalidaJson) -Depth 30 |
            Set-Content -LiteralPath $JsonFile -Encoding UTF8
        $null = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json -ErrorAction Stop
        $Archivos += $JsonFile
    }

    if ($Formato -eq "Markdown" -or $Formato -eq "Ambos") {
        $MdFile = "$Base.md"
        $Lineas = @(
            "# Resultados de busqueda ClaudeMem"
            ""
            "- Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            "- Resultados: $($Resultados.Count)"
            "- Filtros: $($Filtros | ConvertTo-Json -Compress)"
            ""
        )
        foreach ($Registro in $Resultados) {
            $Lineas += "## $($Registro.id) - $($Registro.titulo)"
            $Lineas += ""
            $Lineas += "- **Tipo:** $($Registro.tipo)"
            $Lineas += "- **Fecha:** $($Registro.fecha)"
            $Lineas += "- **Estado:** $($Registro.estado)"
            $Lineas += "- **Tags:** $($Registro.tagsTexto)"
            $Lineas += "- **Ubicacion:** $($Registro.ubicacion)"
            $Lineas += "- **Origen:** $($Registro.origen)"
            $Lineas += ""
            $Lineas += $Registro.descripcion
            $Lineas += ""
            $Lineas += "---"
            $Lineas += ""
        }
        $Lineas | Set-Content -LiteralPath $MdFile -Encoding UTF8
        $Archivos += $MdFile
    }

    return $Archivos
}

function Ejecutar-Busqueda {
    param(
        [AllowEmptyString()][string]$FiltroTexto,
        [string]$FiltroTipo,
        [AllowEmptyString()][string]$FiltroId,
        [AllowEmptyString()][string]$FiltroTag,
        [AllowEmptyString()][string]$FiltroEstado,
        [Nullable[datetime]]$FechaDesde,
        [Nullable[datetime]]$FechaHasta,
        [AllowEmptyString()][string]$FiltroOrigen,
        [switch]$ConPapelera,
        [string]$CriterioOrden,
        [int]$Maximo
    )

    $Todos = @(Obtener-TodosLosRegistros -ConPapelera:$ConPapelera)
    $Filtrados = @(Aplicar-Filtros `
        -Registros $Todos `
        -FiltroTexto $FiltroTexto `
        -FiltroTipo $FiltroTipo `
        -FiltroId $FiltroId `
        -FiltroTag $FiltroTag `
        -FiltroEstado $FiltroEstado `
        -FechaDesde $FechaDesde `
        -FechaHasta $FechaHasta `
        -FiltroOrigen $FiltroOrigen)
    $Ordenados = @(Ordenar-Resultados -Resultados $Filtrados -Criterio $CriterioOrden)
    return @($Ordenados | Select-Object -First $Maximo)
}

function Mostrar-Resultados {
    param([Parameter(Mandatory = $true)][array]$Resultados)
    Write-Host ""
    Write-Host "BUSQUEDA AVANZADA CLAUDEMEM" -ForegroundColor Cyan
    Write-Host "Resultados: $($Resultados.Count)"
    Write-Host ""
    if ($Resultados.Count -eq 0) {
        Write-Host "No se encontraron coincidencias." -ForegroundColor Yellow
        return
    }
    $Resultados | Select-Object id, tipo, fecha, estado, tagsTexto, ubicacion, titulo |
        Format-Table -AutoSize
}

function Ejecutar-PruebaControlada {
    $Pruebas = @()

    $Todos = @(Ejecutar-Busqueda -FiltroTexto "" -FiltroTipo "todos" -FiltroId "" -FiltroTag "" -FiltroEstado "" -FechaDesde $null -FechaHasta $null -FiltroOrigen "" -CriterioOrden "id" -Maximo 500)
    $Pruebas += [PSCustomObject]@{ Estado = $(if ($Todos.Count -eq 7) { "PASS" } else { "FAIL" }); Prueba = "Recuperar siete registros activos"; Detalle = "Resultados=$($Todos.Count)" }

    $Decision = @(Ejecutar-Busqueda -FiltroTexto "" -FiltroTipo "decision" -FiltroId "DECISION-001" -FiltroTag "" -FiltroEstado "" -FechaDesde $null -FechaHasta $null -FiltroOrigen "" -CriterioOrden "id" -Maximo 500)
    $Pruebas += [PSCustomObject]@{ Estado = $(if ($Decision.Count -eq 1) { "PASS" } else { "FAIL" }); Prueba = "Filtrar por tipo e ID"; Detalle = "Resultados=$($Decision.Count)" }

    $TextoLibre = @(Ejecutar-Busqueda -FiltroTexto "Biblioteca Viva" -FiltroTipo "todos" -FiltroId "" -FiltroTag "" -FiltroEstado "" -FechaDesde $null -FechaHasta $null -FiltroOrigen "" -CriterioOrden "id" -Maximo 500)
    $Pruebas += [PSCustomObject]@{ Estado = $(if (@($TextoLibre | Where-Object id -eq "DECISION-002").Count -eq 1) { "PASS" } else { "FAIL" }); Prueba = "Buscar texto libre"; Detalle = "Resultados=$($TextoLibre.Count)" }

    $PorTag = @(Ejecutar-Busqueda -FiltroTexto "" -FiltroTipo "todos" -FiltroId "" -FiltroTag "BibliotecaViva" -FiltroEstado "" -FechaDesde $null -FechaHasta $null -FiltroOrigen "" -CriterioOrden "id" -Maximo 500)
    $Pruebas += [PSCustomObject]@{ Estado = $(if ($PorTag.Count -ge 1) { "PASS" } else { "FAIL" }); Prueba = "Filtrar por tag"; Detalle = "Resultados=$($PorTag.Count)" }

    $PorFecha = @(Ejecutar-Busqueda -FiltroTexto "" -FiltroTipo "todos" -FiltroId "" -FiltroTag "" -FiltroEstado "" -FechaDesde ([datetime]"2026-10-21") -FechaHasta ([datetime]"2026-10-21") -FiltroOrigen "" -CriterioOrden "fecha_asc" -Maximo 500)
    $Pruebas += [PSCustomObject]@{ Estado = $(if ($PorFecha.Count -ge 1) { "PASS" } else { "FAIL" }); Prueba = "Filtrar por fecha"; Detalle = "Resultados=$($PorFecha.Count)" }

    $FiltrosExportacion = @{ Prueba = $true; Tipo = "todos" }
    $Archivos = @(Exportar-Resultados -Resultados $Todos -Formato "Ambos" -Filtros $FiltrosExportacion)
    $ExportacionOk = ($Archivos.Count -eq 2 -and @($Archivos | Where-Object { (Get-Item -LiteralPath $_).Length -gt 0 }).Count -eq 2)
    $Pruebas += [PSCustomObject]@{ Estado = $(if ($ExportacionOk) { "PASS" } else { "FAIL" }); Prueba = "Exportar Markdown y JSON"; Detalle = ($Archivos -join "; ") }

    $Total = $Pruebas.Count
    $Aprobadas = @($Pruebas | Where-Object Estado -eq "PASS").Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = [math]::Round(($Aprobadas / $Total) * 100, 2)
    $EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }
    $Informe = Join-Path $ReportsFolder "Reporte-Prueba-Busqueda-Avanzada-ClaudeMem-$MarcaTiempo.txt"

    @(
        "REPORTE PRUEBA BUSQUEDA AVANZADA CLAUDEMEM"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Estado: $EstadoFinal"
        "Aprobadas: $Aprobadas"
        "Fallidas: $Fallidas"
        "Resultado: $Porcentaje %"
        ""
    ) | Set-Content -LiteralPath $Informe -Encoding UTF8
    $Pruebas | Format-Table Estado, Prueba, Detalle -AutoSize |
        Out-String | Add-Content -LiteralPath $Informe -Encoding UTF8

    Write-Host ""
    Write-Host "RESULTADO PRUEBA BUSQUEDA AVANZADA" -ForegroundColor Cyan
    $Pruebas | Format-Table Estado, Prueba, Detalle -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $EstadoFinal"
    Write-Host "Informe: $Informe"

    Escribir-Log "PRUEBA: aprobadas=$Aprobadas; total=$Total; estado=$EstadoFinal"
    if ($Fallidas -gt 0) { exit 1 }
}

Crear-Carpeta -Ruta $ExportsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

try {
    if ($PSCmdlet.ParameterSetName -eq "Prueba") {
        Ejecutar-PruebaControlada
        exit 0
    }

    if ($null -ne $Desde -and $null -ne $Hasta -and ([datetime]$Desde).Date -gt ([datetime]$Hasta).Date) {
        throw "La fecha Desde no puede ser posterior a Hasta."
    }

    $Resultados = @(Ejecutar-Busqueda `
        -FiltroTexto $Texto `
        -FiltroTipo $Tipo `
        -FiltroId $Id `
        -FiltroTag $Tag `
        -FiltroEstado $Estado `
        -FechaDesde $Desde `
        -FechaHasta $Hasta `
        -FiltroOrigen $Origen `
        -ConPapelera:$IncluirPapelera `
        -CriterioOrden $Orden `
        -Maximo $Limite)

    Mostrar-Resultados -Resultados $Resultados

    $Filtros = @{
        Texto = $Texto
        Tipo = $Tipo
        Id = $Id
        Tag = $Tag
        Estado = $Estado
        Desde = $(if ($null -ne $Desde) { ([datetime]$Desde).ToString("yyyy-MM-dd") } else { "" })
        Hasta = $(if ($null -ne $Hasta) { ([datetime]$Hasta).ToString("yyyy-MM-dd") } else { "" })
        Origen = $Origen
        IncluirPapelera = [bool]$IncluirPapelera
        Orden = $Orden
        Limite = $Limite
    }

    if ($Exportar -ne "Ninguno") {
        $ArchivosExportados = @(Exportar-Resultados -Resultados $Resultados -Formato $Exportar -Filtros $Filtros)
        Write-Host ""
        Write-Host "Archivos exportados:" -ForegroundColor Green
        $ArchivosExportados | ForEach-Object { Write-Host $_ }
    }

    Escribir-Log "BUSQUEDA: resultados=$($Resultados.Count); filtros=$($Filtros | ConvertTo-Json -Compress)"
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN BUSQUEDA AVANZADA" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

