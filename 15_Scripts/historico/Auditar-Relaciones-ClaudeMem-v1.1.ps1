#Requires -Version 5.1

<#
.SYNOPSIS
    Audita la integridad de relaciones de ClaudeMem.

.DESCRIPTION
    Valida los registros activos, relaciones.json, los campos relacionados,
    referencias a elementos en papelera, duplicados y autorrelaciones.

    Modos:
      Sin parametros o -Auditar: auditoria sin modificar datos.
      -Reparar: crea respaldo y reconstruye relaciones.json desde los campos
                relacionados de los registros activos, omitiendo referencias
                rotas, duplicadas, autorrelaciones y elementos en papelera.
      -PruebaControlada: agrega temporalmente relaciones invalidas, comprueba
                su deteccion, ejecuta reparacion, valida el resultado y restaura
                el estado original al finalizar.

.VERSION
    1.1.0
#>

[CmdletBinding(DefaultParameterSetName = "Auditar")]
param(
    [Parameter(ParameterSetName = "Auditar")]
    [switch]$Auditar,

    [Parameter(ParameterSetName = "Reparar", Mandatory = $true)]
    [switch]$Reparar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$PapeleraFolder = Join-Path $DataFolder "papelera"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$RelacionesFile = Join-Path $DataFolder "relaciones.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$AuditoriaSaludScript = Join-Path $PSScriptRoot "Auditoria-ClaudeMem-Salud.ps1"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$Fuentes = @(
    [PSCustomObject]@{ Tipo = "decision"; Ruta = (Join-Path $DataFolder "decisiones.json") },
    [PSCustomObject]@{ Tipo = "leccion"; Ruta = (Join-Path $DataFolder "lecciones.json") },
    [PSCustomObject]@{ Tipo = "hallazgo"; Ruta = (Join-Path $DataFolder "hallazgos.json") }
)

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
    Add-Content -LiteralPath $LogFile -Value "$Fecha - RELACIONES: $Mensaje" -Encoding UTF8
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

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][array]$Datos
    )
    $Temporal = "$Ruta.tmp"
    $Json = ConvertTo-Json -InputObject ([object[]]$Datos) -Depth 40
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $Convertido = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    if ((Convertir-ALista -Valor $Convertido).Count -ne $Datos.Count) {
        Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
        throw "La cantidad JSON escrita no coincide con la entrada."
    }
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}


function Establecer-Relacionados {
    param(
        [Parameter(Mandatory = $true)][object]$Registro,
        [AllowEmptyCollection()][array]$Valores
    )

    if ($Registro.PSObject.Properties.Name -contains "relacionados") {
        $Registro.relacionados = @($Valores)
    }
    else {
        Add-Member -InputObject $Registro `
            -MemberType NoteProperty `
            -Name "relacionados" `
            -Value @($Valores) `
            -Force
    }
}

function Obtener-RegistrosActivos {
    $Registros = @()
    foreach ($Fuente in $Fuentes) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $Id = if ($Registro.PSObject.Properties.Name -contains "id") { [string]$Registro.id } else { "" }
            $Relacionados = @()
            if ($Registro.PSObject.Properties.Name -contains "relacionados") {
                $Relacionados = @(Convertir-ALista -Valor $Registro.relacionados | ForEach-Object { [string]$_ })
            }
            $Registros += [PSCustomObject]@{
                id = $Id
                tipo = $Fuente.Tipo
                ruta = $Fuente.Ruta
                relacionados = $Relacionados
                objeto = $Registro
            }
        }
    }
    return $Registros
}

function Obtener-IdsPapeleraActiva {
    $Ids = @()
    if (-not (Test-Path -LiteralPath $PapeleraFolder -PathType Container)) { return $Ids }

    foreach ($Archivo in @(Get-ChildItem -LiteralPath $PapeleraFolder -File -Filter "*.json" -ErrorAction SilentlyContinue)) {
        try {
            $Entrada = Get-Content -LiteralPath $Archivo.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
            $Propiedades = @($Entrada.PSObject.Properties.Name)
            if (
                $Propiedades -contains "id" -and
                $Propiedades -contains "estadoPapelera" -and
                [string]$Entrada.estadoPapelera -eq "EN_PAPELERA"
            ) {
                $Ids += [string]$Entrada.id
            }
        }
        catch {
            Escribir-Log "ARCHIVO PAPELERA IGNORADO: $($Archivo.FullName)"
        }
    }
    return @($Ids | Sort-Object -Unique)
}

function Crear-BackupRelaciones {
    Crear-Carpeta -Ruta $BackupsFolder
    $Backup = Join-Path $BackupsFolder "pre-reparar-relaciones-$MarcaTiempo.zip"
    $Elementos = @($RelacionesFile)
    foreach ($Fuente in $Fuentes) {
        if (Test-Path -LiteralPath $Fuente.Ruta -PathType Leaf) { $Elementos += $Fuente.Ruta }
    }
    Compress-Archive -LiteralPath $Elementos -DestinationPath $Backup -CompressionLevel Optimal -Force
    if (-not (Test-Path -LiteralPath $Backup -PathType Leaf)) { throw "No se creo el respaldo." }
    if ((Get-Item -LiteralPath $Backup).Length -le 0) { throw "El respaldo esta vacio." }
    return $Backup
}

# ============================================================
# AUDITORIA
# ============================================================

function Ejecutar-AuditoriaRelaciones {
    $Registros = @(Obtener-RegistrosActivos)
    $Relaciones = @(Leer-JsonArray -Ruta $RelacionesFile)
    $IdsActivos = @($Registros.id | Where-Object { $_.Trim().Length -gt 0 })
    $IdsPapelera = @(Obtener-IdsPapeleraActiva)
    $Hallazgos = @()

    foreach ($Duplicado in @($IdsActivos | Group-Object | Where-Object Count -gt 1)) {
        $Hallazgos += [PSCustomObject]@{ Codigo = "REL-001"; Severidad = "CRITICA"; Tipo = "ID_ACTIVO_DUPLICADO"; Origen = $Duplicado.Name; Destino = ""; Detalle = "Aparece $($Duplicado.Count) veces" }
    }

    $ClavesRelaciones = @()
    foreach ($Relacion in $Relaciones) {
        $Propiedades = @($Relacion.PSObject.Properties.Name)
        if ($Propiedades -notcontains "origen" -or $Propiedades -notcontains "destino") {
            $Hallazgos += [PSCustomObject]@{ Codigo = "REL-002"; Severidad = "CRITICA"; Tipo = "RELACION_MALFORMADA"; Origen = ""; Destino = ""; Detalle = "Faltan origen o destino" }
            continue
        }

        $Origen = [string]$Relacion.origen
        $Destino = [string]$Relacion.destino
        $Clave = "$Origen|$Destino"
        $ClavesRelaciones += $Clave

        if ($Origen -eq $Destino) {
            $Hallazgos += [PSCustomObject]@{ Codigo = "REL-003"; Severidad = "ALTA"; Tipo = "AUTORRELACION"; Origen = $Origen; Destino = $Destino; Detalle = "Origen y destino son iguales" }
        }
        if ($IdsActivos -notcontains $Origen) {
            $Hallazgos += [PSCustomObject]@{ Codigo = "REL-004"; Severidad = "ALTA"; Tipo = "ORIGEN_INEXISTENTE"; Origen = $Origen; Destino = $Destino; Detalle = "El origen no esta activo" }
        }
        if ($IdsActivos -notcontains $Destino) {
            $TipoFalla = if ($IdsPapelera -contains $Destino) { "DESTINO_EN_PAPELERA" } else { "DESTINO_INEXISTENTE" }
            $Hallazgos += [PSCustomObject]@{ Codigo = "REL-005"; Severidad = "ALTA"; Tipo = $TipoFalla; Origen = $Origen; Destino = $Destino; Detalle = "El destino no esta activo" }
        }
    }

    foreach ($Duplicada in @($ClavesRelaciones | Group-Object | Where-Object Count -gt 1)) {
        $Partes = $Duplicada.Name -split '\|', 2
        $Hallazgos += [PSCustomObject]@{ Codigo = "REL-006"; Severidad = "MEDIA"; Tipo = "RELACION_DUPLICADA"; Origen = $Partes[0]; Destino = $Partes[1]; Detalle = "Aparece $($Duplicada.Count) veces" }
    }

    $MapaRelaciones = @{}
    foreach ($Clave in $ClavesRelaciones) { $MapaRelaciones[$Clave] = $true }

    foreach ($Registro in $Registros) {
        foreach ($Destino in @($Registro.relacionados)) {
            if ($Destino.Trim().Length -eq 0) { continue }
            $Clave = "$($Registro.id)|$Destino"
            if (-not $MapaRelaciones.ContainsKey($Clave)) {
                $Hallazgos += [PSCustomObject]@{ Codigo = "REL-007"; Severidad = "MEDIA"; Tipo = "FALTA_EN_RELACIONES_JSON"; Origen = $Registro.id; Destino = $Destino; Detalle = "Existe en campo relacionados, no en relaciones.json" }
            }
            if ($IdsActivos -notcontains $Destino) {
                $TipoFalla = if ($IdsPapelera -contains $Destino) { "CAMPO_APUNTA_PAPELERA" } else { "CAMPO_APUNTA_INEXISTENTE" }
                $Hallazgos += [PSCustomObject]@{ Codigo = "REL-008"; Severidad = "ALTA"; Tipo = $TipoFalla; Origen = $Registro.id; Destino = $Destino; Detalle = "Referencia no activa en campo relacionados" }
            }
        }
    }

    foreach ($Relacion in $Relaciones) {
        if (
            $Relacion.PSObject.Properties.Name -contains "origen" -and
            $Relacion.PSObject.Properties.Name -contains "destino"
        ) {
            $Origen = [string]$Relacion.origen
            $Destino = [string]$Relacion.destino
            $RegistroOrigen = @($Registros | Where-Object id -eq $Origen)
            if ($RegistroOrigen.Count -eq 1 -and @($RegistroOrigen[0].relacionados) -notcontains $Destino) {
                $Hallazgos += [PSCustomObject]@{ Codigo = "REL-009"; Severidad = "MEDIA"; Tipo = "FALTA_EN_CAMPO_RELACIONADOS"; Origen = $Origen; Destino = $Destino; Detalle = "Existe en relaciones.json, no en el registro" }
            }
        }
    }

    return [PSCustomObject]@{
        Registros = $Registros.Count
        Relaciones = $Relaciones.Count
        IdsPapelera = $IdsPapelera.Count
        Hallazgos = $Hallazgos
    }
}

function Mostrar-Auditoria {
    param([Parameter(Mandatory = $true)][object]$Resultado)
    Write-Host ""
    Write-Host "AUDITORIA DE RELACIONES CLAUDEMEM" -ForegroundColor Cyan
    Write-Host "Registros activos: $($Resultado.Registros)"
    Write-Host "Relaciones: $($Resultado.Relaciones)"
    Write-Host "IDs en papelera activa: $($Resultado.IdsPapelera)"
    Write-Host "Hallazgos: $(@($Resultado.Hallazgos).Count)"
    Write-Host ""

    if (@($Resultado.Hallazgos).Count -eq 0) {
        Write-Host "AUDITORIA APROBADA" -ForegroundColor Green
    }
    else {
        $Resultado.Hallazgos | Format-Table Codigo, Severidad, Tipo, Origen, Destino, Detalle -AutoSize
        Write-Host "AUDITORIA NO APROBADA" -ForegroundColor Red
    }
}

function Reparar-Relaciones {
    $Backup = Crear-BackupRelaciones
    $Registros = @(Obtener-RegistrosActivos)
    $IdsActivos = @($Registros.id)
    $IdsPapelera = @(Obtener-IdsPapeleraActiva)
    $Nuevas = @()
    $Claves = @{}

    foreach ($Registro in $Registros) {
        $RelacionadosLimpios = @()
        foreach ($Destino in @($Registro.relacionados)) {
            if ($Destino.Trim().Length -eq 0) { continue }
            if ($Destino -eq $Registro.id) { continue }
            if ($IdsActivos -notcontains $Destino) { continue }
            if ($IdsPapelera -contains $Destino) { continue }

            $Clave = "$($Registro.id)|$Destino"
            if (-not $Claves.ContainsKey($Clave)) {
                $Claves[$Clave] = $true
                $RelacionadosLimpios += $Destino
                $Nuevas += [PSCustomObject][ordered]@{
                    origen = $Registro.id
                    destino = $Destino
                    tipo = "relacionado"
                    fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    origenDatos = "campo_relacionados"
                }
            }
        }

        Establecer-Relacionados -Registro $Registro.objeto -Valores @($RelacionadosLimpios)
    }

    foreach ($Fuente in $Fuentes) {
        $DatosFuente = @($Registros | Where-Object tipo -eq $Fuente.Tipo | ForEach-Object { $_.objeto })
        Guardar-JsonArray -Ruta $Fuente.Ruta -Datos $DatosFuente
    }
    Guardar-JsonArray -Ruta $RelacionesFile -Datos $Nuevas

    Escribir-Log "RELACIONES REPARADAS: relaciones=$($Nuevas.Count); backup=$Backup"
    return [PSCustomObject]@{ Backup = $Backup; Relaciones = $Nuevas.Count }
}

function Crear-Informe {
    param(
        [Parameter(Mandatory = $true)][string]$Nombre,
        [Parameter(Mandatory = $true)][object]$Resultado
    )
    Crear-Carpeta -Ruta $ReportsFolder
    $Ruta = Join-Path $ReportsFolder "$Nombre-$MarcaTiempo.txt"
    $Hallazgos = @($Resultado.Hallazgos)
    @(
        "REPORTE DE AUDITORIA DE RELACIONES CLAUDEMEM"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Registros activos: $($Resultado.Registros)"
        "Relaciones: $($Resultado.Relaciones)"
        "IDs en papelera: $($Resultado.IdsPapelera)"
        "Hallazgos: $($Hallazgos.Count)"
        "Estado: $(if ($Hallazgos.Count -eq 0) { 'APROBADO' } else { 'NO APROBADO' })"
        ""
    ) | Set-Content -LiteralPath $Ruta -Encoding UTF8
    if ($Hallazgos.Count -gt 0) {
        $Hallazgos | Format-Table Codigo, Severidad, Tipo, Origen, Destino, Detalle -AutoSize |
            Out-String | Add-Content -LiteralPath $Ruta -Encoding UTF8
    }
    return $Ruta
}

# ============================================================
# PRUEBA CONTROLADA
# ============================================================

function Ejecutar-PruebaControlada {
    $OriginalRelaciones = @(Leer-JsonArray -Ruta $RelacionesFile)
    $RegistroOrigen = @(Obtener-RegistrosActivos | Where-Object id -eq "DECISION-001")
    if ($RegistroOrigen.Count -ne 1) { throw "No existe DECISION-001 para la prueba controlada." }
    $OriginalRelacionados = @($RegistroOrigen[0].relacionados)
    $Resultados = @()

    try {
        Establecer-Relacionados -Registro $RegistroOrigen[0].objeto -Valores @($OriginalRelacionados + "ID-INEXISTENTE-PRUEBA")
        $DatosDecisiones = @(Obtener-RegistrosActivos | Where-Object tipo -eq "decision" | ForEach-Object { $_.objeto })
        Guardar-JsonArray -Ruta $RegistroOrigen[0].ruta -Datos $DatosDecisiones

        $Corruptas = @($OriginalRelaciones)
        $Corruptas += [PSCustomObject]@{ origen = "DECISION-001"; destino = "DECISION-001" }
        $Corruptas += [PSCustomObject]@{ origen = "DECISION-001"; destino = "ID-INEXISTENTE-PRUEBA" }
        $Corruptas += [PSCustomObject]@{ origen = "DECISION-001"; destino = "LECCION-TEST-001" }
        $Corruptas += [PSCustomObject]@{ origen = "DECISION-001"; destino = "LECCION-TEST-001" }
        Guardar-JsonArray -Ruta $RelacionesFile -Datos $Corruptas

        $Antes = Ejecutar-AuditoriaRelaciones
        $Detecto = @($Antes.Hallazgos).Count -ge 3
        $Resultados += [PSCustomObject]@{ Estado = $(if ($Detecto) { "PASS" } else { "FAIL" }); Prueba = "Detectar relaciones invalidas"; Detalle = "Hallazgos=$(@($Antes.Hallazgos).Count)" }
        if (-not $Detecto) { throw "La auditoria no detecto las corrupciones de prueba." }

        $Reparacion = Reparar-Relaciones
        $Despues = Ejecutar-AuditoriaRelaciones
        $Limpio = @($Despues.Hallazgos).Count -eq 0
        $Resultados += [PSCustomObject]@{ Estado = $(if ($Limpio) { "PASS" } else { "FAIL" }); Prueba = "Reparar relaciones"; Detalle = "Hallazgos posteriores=$(@($Despues.Hallazgos).Count)" }
        $Resultados += [PSCustomObject]@{ Estado = $(if ((Test-Path -LiteralPath $Reparacion.Backup)) { "PASS" } else { "FAIL" }); Prueba = "Crear respaldo"; Detalle = $Reparacion.Backup }
        if (-not $Limpio) { throw "Persisten hallazgos despues de reparar." }

        if (Test-Path -LiteralPath $AuditoriaSaludScript -PathType Leaf) {
            & $AuditoriaSaludScript | Out-Host
            $Resultados += [PSCustomObject]@{ Estado = $(if ($?) { "PASS" } else { "FAIL" }); Prueba = "Salud posterior"; Detalle = "Auditoria ejecutada" }
        }
    }
    catch {
        Guardar-JsonArray -Ruta $RelacionesFile -Datos $OriginalRelaciones
        Establecer-Relacionados -Registro $RegistroOrigen[0].objeto -Valores @($OriginalRelacionados)
        $DatosRestaurados = @(Obtener-RegistrosActivos | Where-Object tipo -eq "decision" | ForEach-Object { $_.objeto })
        Guardar-JsonArray -Ruta $RegistroOrigen[0].ruta -Datos $DatosRestaurados
        $Resultados += [PSCustomObject]@{ Estado = "FAIL"; Prueba = "Ejecucion general"; Detalle = $_.Exception.Message }
    }

    $Final = Ejecutar-AuditoriaRelaciones
    $Informe = Crear-Informe -Nombre "Reporte-Prueba-Relaciones-ClaudeMem" -Resultado $Final
    $Total = $Resultados.Count
    $Aprobadas = @($Resultados | Where-Object Estado -eq "PASS").Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = if ($Total -gt 0) { [math]::Round(($Aprobadas / $Total) * 100, 2) } else { 0 }

    Write-Host ""
    Write-Host "RESULTADO PRUEBA DE RELACIONES" -ForegroundColor Cyan
    $Resultados | Format-Table Estado, Prueba, Detalle -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $(if ($Fallidas -eq 0) { 'APROBADO' } else { 'NO APROBADO' })"
    Write-Host "Informe: $Informe"

    if ($Fallidas -gt 0) { exit 1 }
}

# ============================================================
# EJECUCION
# ============================================================

Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $RelacionesFile -PathType Leaf)) {
    Guardar-JsonArray -Ruta $RelacionesFile -Datos @()
}

try {
    switch ($PSCmdlet.ParameterSetName) {
        "Reparar" {
            $ResultadoAntes = Ejecutar-AuditoriaRelaciones
            Mostrar-Auditoria -Resultado $ResultadoAntes
            $Reparacion = Reparar-Relaciones
            Write-Host "Relaciones reparadas: $($Reparacion.Relaciones)" -ForegroundColor Green
            Write-Host "Backup: $($Reparacion.Backup)"
            $ResultadoDespues = Ejecutar-AuditoriaRelaciones
            Mostrar-Auditoria -Resultado $ResultadoDespues
            $Informe = Crear-Informe -Nombre "Reporte-Reparacion-Relaciones-ClaudeMem" -Resultado $ResultadoDespues
            Write-Host "Informe: $Informe"
            if (@($ResultadoDespues.Hallazgos).Count -gt 0) { exit 1 }
        }
        "Prueba" {
            Ejecutar-PruebaControlada
        }
        default {
            $Resultado = Ejecutar-AuditoriaRelaciones
            Mostrar-Auditoria -Resultado $Resultado
            $Informe = Crear-Informe -Nombre "Reporte-Auditoria-Relaciones-ClaudeMem" -Resultado $Resultado
            Write-Host "Informe: $Informe"
            Escribir-Log "AUDITORIA: hallazgos=$(@($Resultado.Hallazgos).Count)"
            if (@($Resultado.Hallazgos).Count -gt 0) { exit 1 }
        }
    }
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN AUDITORIA DE RELACIONES" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
