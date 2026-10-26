#Requires -Version 5.1

<#
.SYNOPSIS
    Gestiona la papelera individual de registros de ClaudeMem.

.DESCRIPTION
    Permite listar, enviar, restaurar y auditar registros eliminados de forma
    logica. Nunca elimina definitivamente durante Enviar o Restaurar.

    Modos:
      -Listar
      -Enviar -Id <ID> -Motivo <texto>
      -Restaurar -Id <ID>
      -Auditar
      -PruebaControlada

.VERSION
    1.1.0
#>

[CmdletBinding(DefaultParameterSetName = "Listar")]
param(
    [Parameter(ParameterSetName = "Listar")]
    [switch]$Listar,

    [Parameter(ParameterSetName = "Enviar", Mandatory = $true)]
    [switch]$Enviar,

    [Parameter(ParameterSetName = "Restaurar", Mandatory = $true)]
    [switch]$Restaurar,

    [Parameter(ParameterSetName = "Auditar", Mandatory = $true)]
    [switch]$Auditar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada,

    [Parameter(ParameterSetName = "Enviar", Mandatory = $true)]
    [Parameter(ParameterSetName = "Restaurar", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Id,

    [Parameter(ParameterSetName = "Enviar", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Motivo
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$PapeleraFolder = Join-Path $DataFolder "papelera"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$IndexFile = Join-Path $ClaudeMemRoot "index\index.json"
$RelacionesFile = Join-Path $DataFolder "relaciones.json"
$ReconstruirIndiceScript = Join-Path $PSScriptRoot "Reconstruir-Indice-ClaudeMem.ps1"
$AuditoriaSaludScript = Join-Path $PSScriptRoot "Auditoria-ClaudeMem-Salud.ps1"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$script:Resultados = @()

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
    Add-Content -LiteralPath $LogFile -Value "$Fecha - PAPELERA: $Mensaje" -Encoding UTF8
}

function Agregar-Resultado {
    param(
        [Parameter(Mandatory = $true)][string]$Prueba,
        [Parameter(Mandatory = $true)][bool]$Aprobada,
        [Parameter(Mandatory = $true)][string]$Detalle
    )
    $script:Resultados += [PSCustomObject]@{
        Estado = $(if ($Aprobada) { "PASS" } else { "FAIL" })
        Prueba = $Prueba
        Detalle = $Detalle
    }
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
    $Texto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if ($null -eq $Texto -or $Texto.Trim().Length -eq 0) { return @() }
    $Objeto = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    return (Convertir-ALista -Valor $Objeto)
}

function Leer-JsonObjeto {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    $Texto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    return ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
}

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][array]$Datos
    )
    $Temporal = "$Ruta.tmp"
    $Json = ConvertTo-Json -InputObject ([object[]]$Datos) -Depth 40
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $Validacion = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    if ((Convertir-ALista -Valor $Validacion).Count -ne $Datos.Count) {
        Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
        throw "La cantidad escrita no coincide con la entrada para '$Ruta'."
    }
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Guardar-JsonObjeto {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Datos
    )
    $Temporal = "$Ruta.tmp"
    $Json = ConvertTo-Json -InputObject $Datos -Depth 40
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $null = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Buscar-RegistroActivo {
    param([Parameter(Mandatory = $true)][string]$RegistroId)
    $Coincidencias = @()
    foreach ($Fuente in $Fuentes) {
        $Registros = @(Leer-JsonArray -Ruta $Fuente.Ruta)
        foreach ($Registro in $Registros) {
            if ([string]$Registro.id -eq $RegistroId) {
                $Coincidencias += [PSCustomObject]@{
                    Tipo = $Fuente.Tipo
                    Ruta = $Fuente.Ruta
                    Registro = $Registro
                    Todos = $Registros
                }
            }
        }
    }
    return $Coincidencias
}

function Buscar-EntradaPapelera {
    param([Parameter(Mandatory = $true)][string]$RegistroId)
    $Archivos = @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "*.json" -ErrorAction SilentlyContinue)
    $Coincidencias = @()
    foreach ($Archivo in $Archivos) {
        try {
            $Entrada = Leer-JsonObjeto -Ruta $Archivo.FullName
            if ([string]$Entrada.id -eq $RegistroId -and [string]$Entrada.estadoPapelera -eq "EN_PAPELERA") {
                $Coincidencias += [PSCustomObject]@{ Ruta = $Archivo.FullName; Entrada = $Entrada }
            }
        }
        catch {
            Escribir-Log "ARCHIVO PAPELERA INVALIDO: $($Archivo.FullName); $($_.Exception.Message)"
        }
    }
    return $Coincidencias
}

function Crear-BackupOperacion {
    param([Parameter(Mandatory = $true)][string]$Nombre)
    Crear-Carpeta -Ruta $BackupsFolder
    $Ruta = Join-Path $BackupsFolder "$Nombre-$MarcaTiempo.zip"
    $Elementos = @()
    foreach ($Fuente in $Fuentes) {
        if (Test-Path -LiteralPath $Fuente.Ruta -PathType Leaf) { $Elementos += $Fuente.Ruta }
    }
    foreach ($Extra in @($RelacionesFile, $IndexFile)) {
        if (Test-Path -LiteralPath $Extra -PathType Leaf) { $Elementos += $Extra }
    }
    if ($Elementos.Count -eq 0) { throw "No existen archivos para respaldar." }
    Compress-Archive -LiteralPath $Elementos -DestinationPath $Ruta -CompressionLevel Optimal -Force
    if ((Get-Item -LiteralPath $Ruta).Length -le 0) { throw "El respaldo quedo vacio." }
    return $Ruta
}

function Actualizar-Indice {
    if (-not (Test-Path -LiteralPath $ReconstruirIndiceScript -PathType Leaf)) {
        throw "No existe Reconstruir-Indice-ClaudeMem.ps1."
    }
    & $ReconstruirIndiceScript | Out-Host
    if (-not $?) { throw "Fallo la reconstruccion del indice." }
}

function Enviar-A-Papelera {
    param(
        [Parameter(Mandatory = $true)][string]$RegistroId,
        [Parameter(Mandatory = $true)][string]$Razon
    )

    $Activos = @(Buscar-RegistroActivo -RegistroId $RegistroId)
    if ($Activos.Count -eq 0) { throw "No existe un registro activo con ID '$RegistroId'." }
    if ($Activos.Count -gt 1) { throw "El ID '$RegistroId' aparece en mas de una fuente activa." }

    $YaEliminado = @(Buscar-EntradaPapelera -RegistroId $RegistroId)
    if ($YaEliminado.Count -gt 0) { throw "El ID '$RegistroId' ya existe en papelera." }

    $Encontrado = $Activos[0]
    $Backup = Crear-BackupOperacion -Nombre "pre-papelera-$RegistroId"
    $PapeleraFile = Join-Path $PapeleraFolder "$RegistroId-$MarcaTiempo.json"

    $Entrada = [PSCustomObject][ordered]@{
        id = $RegistroId
        tipo = $Encontrado.Tipo
        fechaEliminacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        motivo = $Razon
        estadoPapelera = "EN_PAPELERA"
        archivoOrigen = $Encontrado.Ruta
        backup = $Backup
        registro = $Encontrado.Registro
    }
    Guardar-JsonObjeto -Ruta $PapeleraFile -Datos $Entrada

    $Restantes = @($Encontrado.Todos | Where-Object { [string]$_.id -ne $RegistroId })
    Guardar-JsonArray -Ruta $Encontrado.Ruta -Datos $Restantes
    Actualizar-Indice

    if (@(Buscar-RegistroActivo -RegistroId $RegistroId).Count -ne 0) {
        throw "El registro sigue activo despues de enviarlo a papelera."
    }

    Escribir-Log "ENVIADO: id=$RegistroId; tipo=$($Encontrado.Tipo); motivo=$Razon; archivo=$PapeleraFile"
    return [PSCustomObject]@{ Papelera = $PapeleraFile; Backup = $Backup; Tipo = $Encontrado.Tipo }
}

function Restaurar-Desde-Papelera {
    param([Parameter(Mandatory = $true)][string]$RegistroId)

    if (@(Buscar-RegistroActivo -RegistroId $RegistroId).Count -gt 0) {
        throw "No se puede restaurar '$RegistroId': ya existe un registro activo con ese ID."
    }

    $Entradas = @(Buscar-EntradaPapelera -RegistroId $RegistroId)
    if ($Entradas.Count -eq 0) { throw "No existe '$RegistroId' en papelera activa." }
    if ($Entradas.Count -gt 1) { throw "Existen multiples entradas activas de papelera para '$RegistroId'."
    }

    $Seleccion = $Entradas[0]
    $Entrada = $Seleccion.Entrada
    $Fuente = @($Fuentes | Where-Object { $_.Tipo -eq [string]$Entrada.tipo })
    if ($Fuente.Count -ne 1) { throw "Tipo de registro no reconocido: $($Entrada.tipo)" }

    $Backup = Crear-BackupOperacion -Nombre "pre-restaurar-papelera-$RegistroId"
    $Registros = @(Leer-JsonArray -Ruta $Fuente[0].Ruta)
    $Registros += $Entrada.registro
    Guardar-JsonArray -Ruta $Fuente[0].Ruta -Datos $Registros

    $Entrada.estadoPapelera = "RESTAURADO"

    # Windows PowerShell 5.1 con Set-StrictMode no permite asignar
    # directamente una propiedad que todavia no existe en PSCustomObject.
    $Entrada | Add-Member `
        -NotePropertyName "fechaRestauracion" `
        -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") `
        -Force

    $Entrada | Add-Member `
        -NotePropertyName "backupRestauracion" `
        -NotePropertyValue $Backup `
        -Force

    Guardar-JsonObjeto -Ruta $Seleccion.Ruta -Datos $Entrada
    Actualizar-Indice

    if (@(Buscar-RegistroActivo -RegistroId $RegistroId).Count -ne 1) {
        throw "La restauracion no produjo exactamente un registro activo."
    }

    Escribir-Log "RESTAURADO: id=$RegistroId; tipo=$($Entrada.tipo); archivo=$($Seleccion.Ruta)"
    return [PSCustomObject]@{ Archivo = $Seleccion.Ruta; Backup = $Backup; Tipo = [string]$Entrada.tipo }
}

function Listar-Papelera {
    $Filas = @()
    foreach ($Archivo in @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
        try {
            $Entrada = Leer-JsonObjeto -Ruta $Archivo.FullName
            if ($Entrada.PSObject.Properties.Name -contains "registro") {
                $Filas += [PSCustomObject]@{
                    id = [string]$Entrada.id
                    tipo = [string]$Entrada.tipo
                    estado = [string]$Entrada.estadoPapelera
                    fechaEliminacion = [string]$Entrada.fechaEliminacion
                    motivo = [string]$Entrada.motivo
                    archivo = $Archivo.Name
                }
            }
        }
        catch { }
    }

    Write-Host ""
    Write-Host "PAPELERA CLAUDEMEM" -ForegroundColor Cyan
    Write-Host ""
    if ($Filas.Count -eq 0) {
        Write-Host "No existen entradas de papelera." -ForegroundColor Yellow
    }
    else {
        $Filas | Sort-Object fechaEliminacion -Descending | Format-Table -AutoSize
    }
}

function Auditar-Papelera {
    $Errores = @()
    $ActivosIds = @()
    foreach ($Fuente in $Fuentes) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $ActivosIds += [string]$Registro.id
        }
    }

    foreach ($Archivo in @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
        try {
            $Entrada = Leer-JsonObjeto -Ruta $Archivo.FullName
            foreach ($Propiedad in @("id", "tipo", "estadoPapelera", "registro")) {
                if ($Entrada.PSObject.Properties.Name -notcontains $Propiedad) {
                    $Errores += "$($Archivo.Name): falta $Propiedad"
                }
            }
            if ([string]$Entrada.estadoPapelera -eq "EN_PAPELERA" -and $ActivosIds -contains [string]$Entrada.id) {
                $Errores += "$($Archivo.Name): ID activo y en papelera simultaneamente"
            }
        }
        catch {
            $Errores += "$($Archivo.Name): JSON invalido"
        }
    }

    $DuplicadosActivos = @($ActivosIds | Group-Object | Where-Object Count -gt 1)
    foreach ($Duplicado in $DuplicadosActivos) {
        $Errores += "ID activo duplicado: $($Duplicado.Name)"
    }

    Write-Host ""
    Write-Host "AUDITORIA PAPELERA CLAUDEMEM" -ForegroundColor Cyan
    if ($Errores.Count -eq 0) {
        Write-Host "AUDITORIA APROBADA" -ForegroundColor Green
        Write-Host "Errores: 0"
        return $true
    }

    Write-Host "AUDITORIA NO APROBADA" -ForegroundColor Red
    $Errores | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    return $false
}

function Ejecutar-PruebaControlada {
    $PruebaId = "HALLAZGO-PAPELERA-TEST-$MarcaTiempo"
    $HallazgosFile = @($Fuentes | Where-Object Tipo -eq "hallazgo")[0].Ruta

    # Recuperar automaticamente pruebas anteriores que quedaron a medio ciclo.
    $EntradasPendientes = @()
    foreach ($Archivo in @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "HALLAZGO-PAPELERA-TEST-*.json" -ErrorAction SilentlyContinue)) {
        try {
            $EntradaPendiente = Leer-JsonObjeto -Ruta $Archivo.FullName
            if ([string]$EntradaPendiente.estadoPapelera -eq "EN_PAPELERA") {
                $EntradasPendientes += [PSCustomObject]@{
                    Id = [string]$EntradaPendiente.id
                    Ruta = $Archivo.FullName
                }
            }
        }
        catch {
            Escribir-Log "NO SE PUDO LEER PRUEBA PENDIENTE: $($Archivo.FullName)"
        }
    }

    foreach ($Pendiente in $EntradasPendientes) {
        try {
            $null = Restaurar-Desde-Papelera -RegistroId $Pendiente.Id
            $SinPruebaAnterior = @(
                Leer-JsonArray -Ruta $HallazgosFile |
                    Where-Object { [string]$_.id -ne $Pendiente.Id }
            )
            Guardar-JsonArray -Ruta $HallazgosFile -Datos $SinPruebaAnterior
            Escribir-Log "PRUEBA PENDIENTE RECUPERADA Y LIMPIADA: $($Pendiente.Id)"
        }
        catch {
            throw "No se pudo recuperar la prueba pendiente '$($Pendiente.Id)': $($_.Exception.Message)"
        }
    }

    if ($EntradasPendientes.Count -gt 0) {
        Actualizar-Indice
    }

    $Originales = @(Leer-JsonArray -Ruta $HallazgosFile)

    try {
        $RegistroPrueba = [PSCustomObject][ordered]@{
            id = $PruebaId
            tipo = "hallazgo"
            titulo = "Prueba controlada de papelera"
            descripcion = "Registro temporal para validar eliminacion y restauracion individual."
            fecha = Get-Date -Format "yyyy-MM-dd"
            estado = "Abierto"
            tags = @("ClaudeMem", "Papelera", "Prueba")
            relacionados = @()
            origen = "Gestionar-Papelera-ClaudeMem.ps1"
        }

        $ConPrueba = @($Originales) + $RegistroPrueba
        Guardar-JsonArray -Ruta $HallazgosFile -Datos $ConPrueba
        Actualizar-Indice
        Agregar-Resultado -Prueba "Crear registro temporal" -Aprobada (@(Buscar-RegistroActivo -RegistroId $PruebaId).Count -eq 1) -Detalle $PruebaId

        $Envio = Enviar-A-Papelera -RegistroId $PruebaId -Razon "Prueba automatica controlada"
        Agregar-Resultado -Prueba "Enviar a papelera" -Aprobada (@(Buscar-EntradaPapelera -RegistroId $PruebaId).Count -eq 1) -Detalle $Envio.Papelera
        Agregar-Resultado -Prueba "Retirar del origen" -Aprobada (@(Buscar-RegistroActivo -RegistroId $PruebaId).Count -eq 0) -Detalle $HallazgosFile

        $Restauracion = Restaurar-Desde-Papelera -RegistroId $PruebaId
        Agregar-Resultado -Prueba "Restaurar desde papelera" -Aprobada (@(Buscar-RegistroActivo -RegistroId $PruebaId).Count -eq 1) -Detalle $Restauracion.Archivo
        Agregar-Resultado -Prueba "Evitar papelera activa residual" -Aprobada (@(Buscar-EntradaPapelera -RegistroId $PruebaId).Count -eq 0) -Detalle $PruebaId

        $ActivosFinales = @(Leer-JsonArray -Ruta $HallazgosFile | Where-Object { [string]$_.id -ne $PruebaId })
        Guardar-JsonArray -Ruta $HallazgosFile -Datos $ActivosFinales
        Actualizar-Indice
        Agregar-Resultado -Prueba "Limpiar registro temporal" -Aprobada (@(Buscar-RegistroActivo -RegistroId $PruebaId).Count -eq 0) -Detalle $PruebaId

        $AuditoriaOk = Auditar-Papelera
        Agregar-Resultado -Prueba "Auditoria posterior" -Aprobada $AuditoriaOk -Detalle "Consistencia de papelera"

        if (Test-Path -LiteralPath $AuditoriaSaludScript -PathType Leaf) {
            & $AuditoriaSaludScript | Out-Host
            Agregar-Resultado -Prueba "Salud posterior" -Aprobada $? -Detalle "Auditoria de salud ejecutada"
        }
    }
    catch {
        Guardar-JsonArray -Ruta $HallazgosFile -Datos $Originales
        try { Actualizar-Indice } catch { }
        Agregar-Resultado -Prueba "Ejecucion general" -Aprobada $false -Detalle $_.Exception.Message
    }

    $Total = $script:Resultados.Count
    $Aprobadas = @($script:Resultados | Where-Object Estado -eq "PASS").Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = if ($Total -gt 0) { [math]::Round(($Aprobadas / $Total) * 100, 2) } else { 0 }
    $EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }
    $Informe = Join-Path $ReportsFolder "Reporte-Prueba-Papelera-ClaudeMem-$MarcaTiempo.txt"

    @(
        "REPORTE DE PRUEBA DE PAPELERA CLAUDEMEM"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Estado: $EstadoFinal"
        "Aprobadas: $Aprobadas"
        "Fallidas: $Fallidas"
        "Resultado: $Porcentaje %"
        ""
    ) | Set-Content -LiteralPath $Informe -Encoding UTF8
    $script:Resultados | Format-Table Estado, Prueba, Detalle -AutoSize |
        Out-String | Add-Content -LiteralPath $Informe -Encoding UTF8

    Write-Host ""
    Write-Host "RESULTADO PRUEBA DE PAPELERA" -ForegroundColor Cyan
    $script:Resultados | Format-Table Estado, Prueba, Detalle -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $EstadoFinal"
    Write-Host "Informe: $Informe"

    if ($Fallidas -gt 0) { exit 1 }
}

Crear-Carpeta -Ruta $PapeleraFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

try {
    switch ($PSCmdlet.ParameterSetName) {
        "Enviar" {
            $Resultado = Enviar-A-Papelera -RegistroId $Id.Trim().ToUpperInvariant() -Razon $Motivo.Trim()
            Write-Host "Registro enviado a papelera." -ForegroundColor Green
            $Resultado | Format-List
        }
        "Restaurar" {
            $Resultado = Restaurar-Desde-Papelera -RegistroId $Id.Trim().ToUpperInvariant()
            Write-Host "Registro restaurado." -ForegroundColor Green
            $Resultado | Format-List
        }
        "Auditar" {
            $Ok = Auditar-Papelera
            if (-not $Ok) { exit 1 }
        }
        "Prueba" {
            Ejecutar-PruebaControlada
        }
        default {
            Listar-Papelera
        }
    }
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR DE PAPELERA" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
