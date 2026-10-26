#Requires -Version 5.1

<#
.SYNOPSIS
    Sincronizacion bidireccional controlada entre Biblioteca Viva y ClaudeMem.

.DESCRIPTION
    Mantiene un manifiesto base por ID con hashes semanticos de Markdown y JSON.
    Solo sincroniza cambios unilaterales. Si ambos lados cambiaron, registra un
    conflicto y no sobrescribe ninguna fuente.

    Modos:
      -Inicializar        Crea la linea base cuando la auditoria tiene 0 conflictos.
      -Auditar            Clasifica cada ID sin modificar datos.
      -Sincronizar        Aplica solo cambios unilaterales, con respaldo.
      -PruebaControlada   Prueba la logica con hashes sinteticos, sin tocar datos.

.VERSION
    1.4.0
#>

[CmdletBinding(DefaultParameterSetName = "Auditar")]
param(
    [Parameter(ParameterSetName = "Inicializar", Mandatory = $true)]
    [switch]$Inicializar,

    [Parameter(ParameterSetName = "Auditar")]
    [switch]$Auditar,

    [Parameter(ParameterSetName = "Sincronizar", Mandatory = $true)]
    [switch]$Sincronizar,

    [Parameter(ParameterSetName = "Sincronizar", Mandatory = $true)]
    [ValidateSet("SINCRONIZAR")]
    [string]$Confirmar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$ConocimientoRoot = Join-Path $CopilotRoot "03_Conocimiento"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$SyncFolder = Join-Path $ClaudeMemRoot "sync"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$ManifestFile = Join-Path $SyncFolder "manifiesto-bidireccional.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$AuditorConflictos = Join-Path $PSScriptRoot "Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1"
$ReconstruirIndice = Join-Path $PSScriptRoot "Reconstruir-Indice-ClaudeMem.ps1"
$AuditorRelaciones = Join-Path $PSScriptRoot "Auditar-Relaciones-ClaudeMem.ps1"
$AuditoriaSalud = Join-Path $PSScriptRoot "Auditoria-ClaudeMem-Salud.ps1"
$Versionador = Join-Path $PSScriptRoot "Versionar-ClaudeMem.ps1"

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
    Add-Content -LiteralPath $LogFile -Value "$Fecha - SYNC BIDIRECCIONAL: $Mensaje" -Encoding UTF8
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

function Leer-Json {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    return (Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
}

function Leer-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { return @() }
    return (Convertir-ALista -Valor (Leer-Json -Ruta $Ruta))
}

function Guardar-JsonSeguro {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Datos,
        [switch]$Arreglo
    )
    $Temporal = "$Ruta.tmp"
    $Json = if ($Arreglo) {
        ConvertTo-Json -InputObject ([object[]]@($Datos)) -Depth 50
    }
    else {
        ConvertTo-Json -InputObject $Datos -Depth 50
    }
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $null = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Normalizar-Texto {
    param([AllowNull()][AllowEmptyString()][string]$Texto)
    if ($null -eq $Texto) { return "" }
    $Valor = $Texto.ToLowerInvariant()
    $Valor = [regex]::Replace($Valor, '\s+', ' ')
    $Valor = [regex]::Replace($Valor, '[^\p{L}\p{Nd}\s*._-]', '')
    return $Valor.Trim()
}

function Hash-Texto {
    param([AllowNull()][AllowEmptyString()][string]$Texto)
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes((Normalizar-Texto -Texto $Texto))
    $Sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($Sha.ComputeHash($Bytes))).Replace('-', '')
    }
    finally { $Sha.Dispose() }
}

function Obtener-TipoDesdeId {
    param([string]$Id)
    if ($Id -match '^DECISION-') { return 'decision' }
    if ($Id -match '^LECCION-') { return 'leccion' }
    if ($Id -match '^HALLAZGO-') { return 'hallazgo' }
    return 'desconocido'
}

function Obtener-MarkdownPorId {
    param([string]$Id)
    return @(Get-ChildItem -LiteralPath $ConocimientoRoot -Recurse -File -Filter "$Id.md" -ErrorAction SilentlyContinue)
}

function Obtener-SeccionMarkdown {
    param([string]$Contenido, [string]$Nombre)
    $Lineas = @($Contenido -split "`r?`n")
    $IndiceInicio = -1
    for ($i = 0; $i -lt $Lineas.Count; $i++) {
        if ($Lineas[$i] -match ('^\s*##\s+' + [regex]::Escape($Nombre) + '\s*$')) {
            $IndiceInicio = $i
            break
        }
    }
    if ($IndiceInicio -lt 0) { return "" }
    $Salida = @()
    for ($i = $IndiceInicio + 1; $i -lt $Lineas.Count; $i++) {
        if ($Lineas[$i] -match '^\s*#{1,6}\s+') { break }
        $Linea = $Lineas[$i].Trim()
        if ($Linea.Length -gt 0) { $Salida += $Linea }
    }
    return ($Salida -join ' ').Trim()
}

function Obtener-ResumenMarkdownSemantico {
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
            if ($Lineas[$Indice] -match '^\s*#{1,6}\s+') { break }
            $TextoLinea = $Lineas[$Indice].Trim()
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

function Obtener-DatosMarkdown {
    param([string]$Ruta, [string]$Id, [string]$Tipo)

    $Contenido = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    $Titulo = $Id

    foreach ($Linea in @($Contenido -split "`r?`n")) {
        if ($Linea -match '^\s*#\s+(.+?)\s*$') {
            $Titulo = $Matches[1].Trim()
            break
        }
    }

    $Resumen = Obtener-ResumenMarkdownSemantico -Contenido $Contenido

    return [PSCustomObject]@{
        id = $Id
        tipo = $Tipo
        titulo = $Titulo
        contenido = $Resumen
        contenidoCompleto = "$Titulo $Resumen"
        ruta = $Ruta
    }
}

function Obtener-DatosJson {
    $Salida = @()
    foreach ($Fuente in $Fuentes) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $Id = [string]$Registro.id
            $Tipo = $Fuente.Tipo
            if ($Tipo -eq 'leccion') {
                $Problema = if ($Registro.PSObject.Properties.Name -contains 'problema') { [string]$Registro.problema } else { $Id }
                $Solucion = if ($Registro.PSObject.Properties.Name -contains 'solucion') { [string]$Registro.solucion } else { "" }
                $Salida += [PSCustomObject]@{
                    id = $Id; tipo = $Tipo; titulo = $Problema
                    contenido = $Solucion; contenidoCompleto = "$Problema $Solucion"
                    objeto = $Registro; ruta = $Fuente.Ruta
                }
            }
            else {
                $Titulo = if ($Registro.PSObject.Properties.Name -contains 'titulo') { [string]$Registro.titulo } else { $Id }
                $Descripcion = if ($Registro.PSObject.Properties.Name -contains 'descripcion') { [string]$Registro.descripcion } else { "" }
                $Salida += [PSCustomObject]@{
                    id = $Id; tipo = $Tipo; titulo = $Titulo
                    contenido = $Descripcion; contenidoCompleto = "$Titulo $Descripcion"
                    objeto = $Registro; ruta = $Fuente.Ruta
                }
            }
        }
    }
    return $Salida
}

function Obtener-EstadoActual {
    $Json = @(Obtener-DatosJson)
    $Ids = @($Json.id | Sort-Object -Unique)
    $Estado = @()

    foreach ($Id in $Ids) {
        $J = @($Json | Where-Object { [string]$_.id -eq [string]$Id })
        $MFiles = @(Obtener-MarkdownPorId -Id $Id)
        if ($J.Count -ne 1 -or $MFiles.Count -ne 1) {
            $Estado += [PSCustomObject]@{
                id = $Id; tipo = Obtener-TipoDesdeId -Id $Id
                estado = 'ESTRUCTURA_INVALIDA'; hashJson = ''; hashMarkdown = ''
                rutaJson = $(if ($J.Count -eq 1) { $J[0].ruta } else { '' })
                rutaMarkdown = $(if ($MFiles.Count -eq 1) { $MFiles[0].FullName } else { '' })
            }
            continue
        }
        $M = Obtener-DatosMarkdown -Ruta $MFiles[0].FullName -Id $Id -Tipo $J[0].tipo
        $Estado += [PSCustomObject]@{
            id = $Id; tipo = $J[0].tipo; estado = 'DISPONIBLE'
            hashJson = Hash-Texto -Texto $J[0].contenidoCompleto
            hashMarkdown = Hash-Texto -Texto $M.contenidoCompleto
            rutaJson = $J[0].ruta; rutaMarkdown = $M.ruta
        }
    }
    return $Estado
}

function Verificar-CeroConflictos {
    if (-not (Test-Path -LiteralPath $AuditorConflictos -PathType Leaf)) {
        throw "No existe el auditor de conflictos."
    }
    & $AuditorConflictos -Auditar | Out-Host
    if (-not $?) { throw "Fallo tecnico en la auditoria de conflictos." }
    $Informe = @(Get-ChildItem -LiteralPath (Join-Path $ClaudeMemRoot 'exports\conflictos') -File -Filter 'Reporte-Conflictos-BibliotecaViva-ClaudeMem-*.json' | Sort-Object LastWriteTime -Descending)[0]
    $Resultado = Leer-Json -Ruta $Informe.FullName
    if (@(Convertir-ALista -Valor $Resultado.hallazgos).Count -ne 0) {
        throw "Existen conflictos activos. La sincronizacion queda bloqueada."
    }
}

function Inicializar-Manifiesto {
    Verificar-CeroConflictos
    $Estado = @(Obtener-EstadoActual)
    if (@($Estado | Where-Object { [string]$_.estado -ne 'DISPONIBLE' }).Count -gt 0) {
        throw "La estructura actual no permite crear una linea base completa."
    }
    foreach ($Item in $Estado) {
        if ($Item.hashJson -ne $Item.hashMarkdown) {
            throw "El ID '$($Item.id)' no es semanticamente coincidente."
        }
    }
    $Manifest = [PSCustomObject][ordered]@{
        version = '1.0'
        fechaInicializacion = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ultimaSincronizacion = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        registros = @($Estado | ForEach-Object {
            [PSCustomObject][ordered]@{
                id = $_.id; tipo = $_.tipo
                hashBase = $_.hashJson; hashJson = $_.hashJson; hashMarkdown = $_.hashMarkdown
                rutaJson = $_.rutaJson; rutaMarkdown = $_.rutaMarkdown
                ultimaAccion = 'LINEA_BASE'
            }
        })
    }
    Guardar-JsonSeguro -Ruta $ManifestFile -Datos $Manifest
    Escribir-Log "LINEA BASE CREADA: registros=$($Estado.Count)"
    Write-Host "Linea base bidireccional creada." -ForegroundColor Green
    Write-Host "Registros: $($Estado.Count)"
    Write-Host "Manifiesto: $ManifestFile"
}

function Clasificar-Cambio {
    param([string]$Base, [string]$Json, [string]$Markdown)
    $CambioJson = ($Json -ne $Base)
    $CambioMarkdown = ($Markdown -ne $Base)
    if (-not $CambioJson -and -not $CambioMarkdown) { return 'SIN_CAMBIOS' }
    if ($CambioJson -and -not $CambioMarkdown) { return 'JSON_A_MARKDOWN' }
    if (-not $CambioJson -and $CambioMarkdown) { return 'MARKDOWN_A_JSON' }
    if ($Json -eq $Markdown) { return 'AMBOS_IGUALES' }
    return 'CONFLICTO_DOBLE_CAMBIO'
}

function Auditar-EstadoSync {
    if (-not (Test-Path -LiteralPath $ManifestFile -PathType Leaf)) {
        throw "No existe linea base. Ejecute -Inicializar."
    }
    $Manifest = Leer-Json -Ruta $ManifestFile
    $Base = @(Convertir-ALista -Valor $Manifest.registros)
    $Actual = @(Obtener-EstadoActual)
    $Resultados = @()

    foreach ($RegistroBase in $Base) {
        $A = @($Actual | Where-Object { [string]$_.id -eq [string]$RegistroBase.id })
        if ($A.Count -ne 1) {
            $Resultados += [PSCustomObject]@{ id=$RegistroBase.id; tipo=$RegistroBase.tipo; clasificacion='ESTRUCTURA_INVALIDA'; detalle="Coincidencias actuales=$($A.Count)" }
            continue
        }
        $Clase = Clasificar-Cambio -Base ([string]$RegistroBase.hashBase) -Json ([string]$A[0].hashJson) -Markdown ([string]$A[0].hashMarkdown)
        $Resultados += [PSCustomObject]@{
            id = $RegistroBase.id; tipo = $RegistroBase.tipo
            clasificacion = $Clase; detalle = ''
            hashBase = $RegistroBase.hashBase
            hashJson = $A[0].hashJson; hashMarkdown = $A[0].hashMarkdown
            rutaJson = $A[0].rutaJson; rutaMarkdown = $A[0].rutaMarkdown
        }
    }
    return [PSCustomObject]@{ Manifest=$Manifest; Resultados=$Resultados }
}

function Mostrar-AuditoriaSync {
    param([object]$AuditoriaSync)
    $Resultados = @($AuditoriaSync.Resultados)
    Write-Host ""
    Write-Host "AUDITORIA SINCRONIZACION BIDIRECCIONAL" -ForegroundColor Cyan
    $Resultados | Select-Object id, tipo, clasificacion, detalle | Format-Table -AutoSize
    Write-Host ""
    foreach ($Clase in @('SIN_CAMBIOS','JSON_A_MARKDOWN','MARKDOWN_A_JSON','AMBOS_IGUALES','CONFLICTO_DOBLE_CAMBIO','ESTRUCTURA_INVALIDA')) {
        Write-Host "$Clase`: $(@($Resultados | Where-Object { [string]$_.clasificacion -eq [string]$Clase }).Count)"
    }
}

function Crear-BackupSync {
    $Backup = Join-Path $BackupsFolder "pre-sync-bidireccional-$MarcaTiempo.zip"
    $Elementos = @()
    foreach ($Fuente in $Fuentes) { if (Test-Path -LiteralPath $Fuente.Ruta) { $Elementos += $Fuente.Ruta } }
    $Elementos += @(Get-ChildItem -LiteralPath $ConocimientoRoot -Recurse -File -Filter '*.md' | Select-Object -ExpandProperty FullName)
    $Elementos += $ManifestFile
    Compress-Archive -LiteralPath $Elementos -DestinationPath $Backup -CompressionLevel Optimal -Force
    if ((Get-Item -LiteralPath $Backup).Length -le 0) { throw "El respaldo quedo vacio." }
    return $Backup
}

function Registro-A-Markdown {
    param([object]$Registro, [string]$Tipo)
    $Id = [string]$Registro.id
    if ($Tipo -eq 'leccion') {
        return "# $Id`r`n`r`nFecha: $(Get-Date -Format 'yyyy-MM-dd')`r`n`r`n## Problema`r`n`r`n$([string]$Registro.problema)`r`n`r`n## Solucion`r`n`r`n$([string]$Registro.solucion)`r`n"
    }
    $Titulo = if ($Registro.PSObject.Properties.Name -contains 'titulo') { [string]$Registro.titulo } else { $Id }
    $Descripcion = if ($Registro.PSObject.Properties.Name -contains 'descripcion') { [string]$Registro.descripcion } else { '' }
    $Seccion = if ($Tipo -eq 'decision') { 'Decision' } else { 'Hallazgo' }
    return "# $Titulo`r`n`r`nFecha: $(Get-Date -Format 'yyyy-MM-dd')`r`n`r`n## $Seccion`r`n`r`n$Descripcion`r`n"
}

function Aplicar-MarkdownAJson {
    param([object]$Item)
    $Tipo = [string]$Item.tipo
    $Fuente = @($Fuentes | Where-Object { [string]$_.Tipo -eq [string]$Tipo })[0]
    $Datos = @(Leer-JsonArray -Ruta $Fuente.Ruta)
    $M = Obtener-DatosMarkdown -Ruta $Item.rutaMarkdown -Id $Item.id -Tipo $Tipo
    $Anterior = @($Datos | Where-Object { [string]$_.id -eq [string]$Item.id })[0]
    $Nuevo = [ordered]@{
        id=$Item.id; tipo=$Tipo; fecha=Get-Date -Format 'yyyy-MM-dd'; estado='Sincronizado'
        tags=$(if($Anterior.PSObject.Properties.Name -contains 'tags'){@($Anterior.tags)}else{@('BibliotecaViva')})
        relacionados=$(if($Anterior.PSObject.Properties.Name -contains 'relacionados'){@($Anterior.relacionados)}else{@()})
        origen=$Item.rutaMarkdown; fechaSincronizacion=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    if ($Tipo -eq 'leccion') { $Nuevo.problema=$M.problema; $Nuevo.solucion=$M.solucion }
    else { $Nuevo.titulo=$M.titulo; $Nuevo.descripcion=$M.contenido }
    $Final = @($Datos | Where-Object { [string]$_.id -ne [string]$Item.id }) + [PSCustomObject]$Nuevo
    Guardar-JsonSeguro -Ruta $Fuente.Ruta -Datos $Final -Arreglo
}

function Aplicar-JsonAMarkdown {
    param([object]$Item)
    $Fuente = @($Fuentes | Where-Object { [string]$_.Tipo -eq [string]$Item.tipo })[0]
    $Registro = @(Leer-JsonArray -Ruta $Fuente.Ruta | Where-Object { [string]$_.id -eq [string]$Item.id })[0]
    $Contenido = Registro-A-Markdown -Registro $Registro -Tipo $Item.tipo
    Set-Content -LiteralPath $Item.rutaMarkdown -Value $Contenido -Encoding UTF8
}

function Ejecutar-Sincronizacion {
    # La linea base es la autoridad para distinguir cambios unilaterales de
    # conflictos dobles. Una auditoria Markdown/JSON previa marcaria cualquier
    # cambio unilateral como diferencia y bloquearia una sincronizacion valida.
    $AuditoriaSync = Auditar-EstadoSync
    $Resultados = @($AuditoriaSync.Resultados)
    $Bloqueos = @($Resultados | Where-Object { $_.clasificacion -in @('CONFLICTO_DOBLE_CAMBIO','ESTRUCTURA_INVALIDA') })
    if ($Bloqueos.Count -gt 0) {
        Mostrar-AuditoriaSync -AuditoriaSync $AuditoriaSync
        throw "Existen $($Bloqueos.Count) bloqueos. No se aplicaron cambios."
    }

    if (Test-Path -LiteralPath $Versionador) { & $Versionador | Out-Host; if (-not $?) { throw "Fallo el versionado previo." } }
    $Backup = Crear-BackupSync

    foreach ($Item in $Resultados) {
        if ($Item.clasificacion -eq 'JSON_A_MARKDOWN') { Aplicar-JsonAMarkdown -Item $Item }
        elseif ($Item.clasificacion -eq 'MARKDOWN_A_JSON') { Aplicar-MarkdownAJson -Item $Item }
    }

    if (Test-Path -LiteralPath $ReconstruirIndice) { & $ReconstruirIndice | Out-Host }
    if (Test-Path -LiteralPath $AuditorRelaciones) { & $AuditorRelaciones -Auditar | Out-Host }
    Verificar-CeroConflictos

    $EstadoFinal = @(Obtener-EstadoActual)
    foreach ($Item in $EstadoFinal) {
        if ($Item.hashJson -ne $Item.hashMarkdown) { throw "El ID '$($Item.id)' no quedo alineado." }
    }

    $ManifestNuevo = [PSCustomObject][ordered]@{
        version='1.0'; fechaInicializacion=$AuditoriaSync.Manifest.fechaInicializacion
        ultimaSincronizacion=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ultimoBackup=$Backup
        registros=@($EstadoFinal | ForEach-Object {
            $ItemActual = $_
            $Clase = @(
                $Resultados | Where-Object {
                    [string]$_.id -eq [string]$ItemActual.id
                }
            )[0].clasificacion

            [PSCustomObject][ordered]@{
                id=$ItemActual.id;tipo=$ItemActual.tipo
                hashBase=$ItemActual.hashJson;hashJson=$ItemActual.hashJson;hashMarkdown=$ItemActual.hashMarkdown
                rutaJson=$ItemActual.rutaJson;rutaMarkdown=$ItemActual.rutaMarkdown;ultimaAccion=$Clase
            }
        })
    }
    Guardar-JsonSeguro -Ruta $ManifestFile -Datos $ManifestNuevo
    if (Test-Path -LiteralPath $AuditoriaSalud) { & $AuditoriaSalud | Out-Host }
    Escribir-Log "SINCRONIZACION COMPLETADA: backup=$Backup"
    Write-Host "Sincronizacion bidireccional completada." -ForegroundColor Green
    Write-Host "Backup: $Backup"
}

function Ejecutar-Prueba {
    $Base = 'AAA'
    $Otro = 'BBB'
    $Tercero = 'CCC'

    $Pruebas = @()

    $Resultado = Clasificar-Cambio -Base $Base -Json $Base -Markdown $Base
    $Pruebas += [PSCustomObject]@{
        Estado = $(if ($Resultado -eq 'SIN_CAMBIOS') { 'PASS' } else { 'FAIL' })
        Prueba = 'Sin cambios'
        Obtenido = $Resultado
    }

    $Resultado = Clasificar-Cambio -Base $Base -Json $Otro -Markdown $Base
    $Pruebas += [PSCustomObject]@{
        Estado = $(if ($Resultado -eq 'JSON_A_MARKDOWN') { 'PASS' } else { 'FAIL' })
        Prueba = 'Cambio solo JSON'
        Obtenido = $Resultado
    }

    $Resultado = Clasificar-Cambio -Base $Base -Json $Base -Markdown $Otro
    $Pruebas += [PSCustomObject]@{
        Estado = $(if ($Resultado -eq 'MARKDOWN_A_JSON') { 'PASS' } else { 'FAIL' })
        Prueba = 'Cambio solo Markdown'
        Obtenido = $Resultado
    }

    $Resultado = Clasificar-Cambio -Base $Base -Json $Otro -Markdown $Otro
    $Pruebas += [PSCustomObject]@{
        Estado = $(if ($Resultado -eq 'AMBOS_IGUALES') { 'PASS' } else { 'FAIL' })
        Prueba = 'Ambos iguales'
        Obtenido = $Resultado
    }

    $Resultado = Clasificar-Cambio -Base $Base -Json $Otro -Markdown $Tercero
    $Pruebas += [PSCustomObject]@{
        Estado = $(if ($Resultado -eq 'CONFLICTO_DOBLE_CAMBIO') { 'PASS' } else { 'FAIL' })
        Prueba = 'Bloquear doble cambio'
        Obtenido = $Resultado
    }

    $Aprobadas = @(
        $Pruebas | Where-Object { $_.Estado -eq 'PASS' }
    ).Count

    $Pruebas | Format-Table Estado, Prueba, Obtenido -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $($Pruebas.Count)"

    $EstadoFinal = if ($Aprobadas -eq $Pruebas.Count) {
        'APROBADO'
    }
    else {
        'NO APROBADO'
    }

    Write-Host "Estado: $EstadoFinal"

    if ($Aprobadas -ne $Pruebas.Count) {
        exit 1
    }
}

Crear-Carpeta -Ruta $SyncFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder
if(-not(Test-Path -LiteralPath $LogFile)){New-Item -ItemType File -Path $LogFile -Force|Out-Null}

try {
    switch ($PSCmdlet.ParameterSetName) {
        'Inicializar' { Inicializar-Manifiesto }
        'Sincronizar' { Ejecutar-Sincronizacion }
        'Prueba' { Ejecutar-Prueba }
        default { $Resultado=Auditar-EstadoSync; Mostrar-AuditoriaSync -AuditoriaSync $Resultado }
    }
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN SINCRONIZACION BIDIRECCIONAL" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
