#Requires -Version 5.1

<#
.SYNOPSIS
    Inicializa memorias separadas por proyecto para ClaudeMem.

.DESCRIPTION
    Crea la estructura controlada de FIOS y NeoDark, manifiestos, perfiles,
    archivos de conocimiento y un registro central de proyectos.

    La operacion es idempotente: no sobrescribe documentos existentes con
    contenido. Antes de modificar archivos existentes crea un respaldo.

    Modos:
      -Inicializar       Crea o completa la estructura.
      -Auditar           Verifica integridad sin modificar.
      -PruebaControlada  Ejecuta inicializacion y auditoria idempotente.

.VERSION
    1.0.0
#>

[CmdletBinding(DefaultParameterSetName = "Auditar")]
param(
    [Parameter(ParameterSetName = "Inicializar", Mandatory = $true)]
    [switch]$Inicializar,

    [Parameter(ParameterSetName = "Auditar")]
    [switch]$Auditar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$ConocimientoRoot = Join-Path $CopilotRoot "03_Conocimiento"
$ProyectosRoot = Join-Path $ConocimientoRoot "25_Proyectos"
$ConfigFolder = Join-Path $ClaudeMemRoot "config"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$RegistroProyectos = Join-Path $ConfigFolder "proyectos.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportFile = Join-Path $ReportsFolder "Reporte-Memorias-Proyecto-ClaudeMem-$MarcaTiempo.txt"

$Proyectos = @(
    [PSCustomObject][ordered]@{
        id = "FIOS"
        nombre = "FIOS"
        descripcion = "Aplicacion ejecutable de ingenieria con biblioteca de calculos, trazabilidad, factores de seguridad, cumplimiento, historial e informes."
        estado = "ACTIVO"
        etiquetas = @("Ingenieria", "Calculos", "Normativa", "Trazabilidad")
        reglas = @(
            "Usar unidades tecnicas pertinentes, incluyendo toneladas, Newton y MPa.",
            "Incluir verificacion cumple/no cumple y factores de seguridad.",
            "Mostrar formulas, variables, fuentes y trazabilidad.",
            "Mantener modulos en espanol con nombre en ingles entre parentesis."
        )
    },
    [PSCustomObject][ordered]@{
        id = "NeoDark"
        nombre = "NeoDark"
        descripcion = "Proyecto de aplicacion con iteraciones controladas, ejecutable visible, gestion segura de credenciales TESTNET y revision integral previa."
        estado = "ACTIVO"
        etiquetas = @("Aplicacion", "Iteraciones", "Seguridad", "TESTNET")
        reglas = @(
            "Revisar integralmente datos, scripts, versiones, dependencias, estados y resultados antes de cada iteracion.",
            "Mantener ejecutable y archivos principales visibles en la raiz del paquete.",
            "Solicitar contrasena para eliminar credenciales TESTNET mediante un campo oculto.",
            "Evitar repetir errores e iteraciones innecesarias."
        )
    }
)

$ArchivosProyecto = @(
    "PERFIL.md",
    "DECISIONES.md",
    "LECCIONES.md",
    "HALLAZGOS.md",
    "REFERENCIAS.md",
    "MANIFIESTO.json"
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
    Add-Content -LiteralPath $LogFile -Value "$Fecha - MEMORIAS PROYECTO: $Mensaje" -Encoding UTF8
}

function Leer-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { return @() }
    $Objeto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    $Salida = @()
    if ($null -eq $Objeto) { return $Salida }
    if ($Objeto -is [System.Array]) {
        foreach ($Elemento in $Objeto) { if ($null -ne $Elemento) { $Salida += $Elemento } }
    }
    else { $Salida += $Objeto }
    return $Salida
}

function Guardar-JsonSeguro {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Datos,
        [switch]$Arreglo
    )
    $Temporal = "$Ruta.tmp"
    $Json = if ($Arreglo) {
        ConvertTo-Json -InputObject ([object[]]@($Datos)) -Depth 40
    }
    else {
        ConvertTo-Json -InputObject $Datos -Depth 40
    }
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $null = Get-Content -LiteralPath $Temporal -Raw | ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Crear-BackupConfiguracion {
    $Elementos = @()
    if (Test-Path -LiteralPath $RegistroProyectos -PathType Leaf) { $Elementos += $RegistroProyectos }
    if (Test-Path -LiteralPath $ProyectosRoot -PathType Container) {
        $Elementos += @(Get-ChildItem -LiteralPath $ProyectosRoot -Recurse -File | Select-Object -ExpandProperty FullName)
    }
    if ($Elementos.Count -eq 0) { return "" }
    $Ruta = Join-Path $BackupsFolder "pre-memorias-proyecto-$MarcaTiempo.zip"
    Compress-Archive -LiteralPath $Elementos -DestinationPath $Ruta -CompressionLevel Optimal -Force
    if ((Get-Item -LiteralPath $Ruta).Length -le 0) { throw "El respaldo de proyectos quedo vacio." }
    return $Ruta
}

function Obtener-ContenidoPerfil {
    param([Parameter(Mandatory = $true)][object]$Proyecto)
    $Lineas = @(
        "# Proyecto $($Proyecto.nombre)",
        "",
        "## Identidad",
        "",
        "- **ID:** $($Proyecto.id)",
        "- **Estado:** $($Proyecto.estado)",
        "- **Descripcion:** $($Proyecto.descripcion)",
        "",
        "## Etiquetas",
        ""
    )
    foreach ($Etiqueta in @($Proyecto.etiquetas)) { $Lineas += "- $Etiqueta" }
    $Lineas += ""
    $Lineas += "## Reglas prioritarias"
    $Lineas += ""
    foreach ($Regla in @($Proyecto.reglas)) { $Lineas += "- $Regla" }
    $Lineas += ""
    $Lineas += "## Separacion de memoria"
    $Lineas += ""
    $Lineas += "Los registros especificos de este proyecto deben usar el campo `proyecto` con valor `$($Proyecto.id)`."
    $Lineas += "La informacion transversal permanece en ClaudeMem central y se referencia, no se duplica."
    $Lineas += ""
    return $Lineas
}

function Obtener-PlantillaMarkdown {
    param([string]$Titulo, [string]$ProyectoId)
    return @(
        "# $Titulo de $ProyectoId",
        "",
        "Este archivo contiene referencias y resúmenes controlados del proyecto $ProyectoId.",
        "Los registros persistentes deben mantenerse en ClaudeMem con el campo `proyecto`: `$ProyectoId`.",
        "",
        "## Registros",
        "",
        "Sin registros específicos incorporados.",
        ""
    )
}

function Inicializar-Estructura {
    Crear-Carpeta -Ruta $ProyectosRoot
    Crear-Carpeta -Ruta $ConfigFolder
    Crear-Carpeta -Ruta $BackupsFolder
    Crear-Carpeta -Ruta $ReportsFolder
    Crear-Carpeta -Ruta $LogsFolder
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) { New-Item -ItemType File -Path $LogFile -Force | Out-Null }

    $Backup = Crear-BackupConfiguracion
    $Registro = @()

    foreach ($Proyecto in $Proyectos) {
        $CarpetaProyecto = Join-Path $ProyectosRoot $Proyecto.id
        Crear-Carpeta -Ruta $CarpetaProyecto

        $Perfil = Join-Path $CarpetaProyecto "PERFIL.md"
        if (-not (Test-Path -LiteralPath $Perfil -PathType Leaf)) {
            Obtener-ContenidoPerfil -Proyecto $Proyecto | Set-Content -LiteralPath $Perfil -Encoding UTF8
        }

        $Plantillas = @{
            "DECISIONES.md" = "Decisiones"
            "LECCIONES.md" = "Lecciones"
            "HALLAZGOS.md" = "Hallazgos"
            "REFERENCIAS.md" = "Referencias"
        }
        foreach ($Nombre in $Plantillas.Keys) {
            $Ruta = Join-Path $CarpetaProyecto $Nombre
            if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
                Obtener-PlantillaMarkdown -Titulo $Plantillas[$Nombre] -ProyectoId $Proyecto.id |
                    Set-Content -LiteralPath $Ruta -Encoding UTF8
            }
        }

        $Manifest = [PSCustomObject][ordered]@{
            id = $Proyecto.id
            nombre = $Proyecto.nombre
            estado = $Proyecto.estado
            carpeta = $CarpetaProyecto
            archivos = @($ArchivosProyecto | Where-Object { $_ -ne "MANIFIESTO.json" })
            campoClasificacion = "proyecto"
            valorClasificacion = $Proyecto.id
            fechaInicializacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            version = "1.0"
        }
        Guardar-JsonSeguro -Ruta (Join-Path $CarpetaProyecto "MANIFIESTO.json") -Datos $Manifest

        $Registro += [PSCustomObject][ordered]@{
            id = $Proyecto.id
            nombre = $Proyecto.nombre
            estado = $Proyecto.estado
            carpeta = $CarpetaProyecto
            campo = "proyecto"
            valor = $Proyecto.id
            etiquetas = @($Proyecto.etiquetas)
        }
    }

    Guardar-JsonSeguro -Ruta $RegistroProyectos -Datos $Registro -Arreglo
    Escribir-Log "INICIALIZACION COMPLETADA: proyectos=$($Registro.Count); backup=$Backup"
    return [PSCustomObject]@{ Proyectos = $Registro.Count; Backup = $Backup }
}

function Auditar-Estructura {
    $Resultados = @()
    $Registro = @(Leer-JsonArray -Ruta $RegistroProyectos)

    foreach ($Proyecto in $Proyectos) {
        $Carpeta = Join-Path $ProyectosRoot $Proyecto.id
        $Resultados += [PSCustomObject]@{
            Estado = $(if (Test-Path -LiteralPath $Carpeta -PathType Container) { "PASS" } else { "FAIL" })
            Prueba = "Carpeta $($Proyecto.id)"
            Detalle = $Carpeta
        }
        foreach ($Archivo in $ArchivosProyecto) {
            $Ruta = Join-Path $Carpeta $Archivo
            $Existe = Test-Path -LiteralPath $Ruta -PathType Leaf
            $Valido = $Existe
            if ($Existe -and $Archivo -like "*.json") {
                try { $null = Get-Content -LiteralPath $Ruta -Raw | ConvertFrom-Json -ErrorAction Stop }
                catch { $Valido = $false }
            }
            $Resultados += [PSCustomObject]@{
                Estado = $(if ($Valido) { "PASS" } else { "FAIL" })
                Prueba = "$($Proyecto.id) / $Archivo"
                Detalle = $Ruta
            }
        }
        $Registrado = @($Registro | Where-Object { [string]$_.id -eq [string]$Proyecto.id }).Count -eq 1
        $Resultados += [PSCustomObject]@{
            Estado = $(if ($Registrado) { "PASS" } else { "FAIL" })
            Prueba = "Registro central $($Proyecto.id)"
            Detalle = $RegistroProyectos
        }
    }

    $Duplicados = @($Registro.id | Group-Object | Where-Object Count -gt 1)
    $Resultados += [PSCustomObject]@{
        Estado = $(if ($Duplicados.Count -eq 0) { "PASS" } else { "FAIL" })
        Prueba = "IDs de proyecto unicos"
        Detalle = "Duplicados=$($Duplicados.Count)"
    }

    return $Resultados
}

function Mostrar-Resultado {
    param([Parameter(Mandatory = $true)][array]$Resultados)
    $Total = $Resultados.Count
    $Aprobadas = @($Resultados | Where-Object { $_.Estado -eq "PASS" }).Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = if ($Total -gt 0) { [math]::Round(($Aprobadas / $Total) * 100, 2) } else { 0 }
    $EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }

    @(
        "REPORTE MEMORIAS POR PROYECTO CLAUDEMEM",
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "Estado: $EstadoFinal",
        "Aprobadas: $Aprobadas",
        "Fallidas: $Fallidas",
        "Resultado: $Porcentaje %",
        ""
    ) | Set-Content -LiteralPath $ReportFile -Encoding UTF8
    $Resultados | Format-Table Estado, Prueba, Detalle -AutoSize |
        Out-String | Add-Content -LiteralPath $ReportFile -Encoding UTF8

    Write-Host ""
    Write-Host "AUDITORIA MEMORIAS POR PROYECTO" -ForegroundColor Cyan
    $Resultados | Format-Table Estado, Prueba, Detalle -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $EstadoFinal"
    Write-Host "Informe: $ReportFile"
    if ($Fallidas -gt 0) { exit 1 }
}

try {
    Crear-Carpeta -Ruta $ReportsFolder
    Crear-Carpeta -Ruta $LogsFolder
    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) { New-Item -ItemType File -Path $LogFile -Force | Out-Null }

    switch ($PSCmdlet.ParameterSetName) {
        "Inicializar" {
            $Resultado = Inicializar-Estructura
            Write-Host "Memorias por proyecto inicializadas." -ForegroundColor Green
            Write-Host "Proyectos: $($Resultado.Proyectos)"
            if ([string]$Resultado.Backup -ne "") { Write-Host "Backup: $($Resultado.Backup)" }
            Mostrar-Resultado -Resultados @(Auditar-Estructura)
        }
        "Prueba" {
            $Primera = Inicializar-Estructura
            $Auditoria1 = @(Auditar-Estructura)
            $Segunda = Inicializar-Estructura
            $Auditoria2 = @(Auditar-Estructura)
            $Combinada = @($Auditoria1 + $Auditoria2)
            $Combinada += [PSCustomObject]@{
                Estado = $(if ($Primera.Proyectos -eq 2 -and $Segunda.Proyectos -eq 2) { "PASS" } else { "FAIL" })
                Prueba = "Idempotencia de inicializacion"
                Detalle = "Primera=$($Primera.Proyectos); Segunda=$($Segunda.Proyectos)"
            }
            Mostrar-Resultado -Resultados $Combinada
        }
        default {
            Mostrar-Resultado -Resultados @(Auditar-Estructura)
        }
    }
}
catch {
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN MEMORIAS POR PROYECTO" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
