#Requires -Version 5.1

<#
.SYNOPSIS
    Prueba controlada de versionado y restauracion de ClaudeMem.

.DESCRIPTION
    Audita y aparta versiones de prueba contaminadas, selecciona una version
    base cuyo snapshot de estado.json no contenga propiedades temporales,
    aplica una propiedad unica, verifica 1 archivo modificado y 7 sin cambios,
    restaura la base, valida SHA-256, backup, indice y salud, y finalmente
    retira la version temporal de prueba del conjunto operativo.

.VERSION
    2.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$VersionsFolder = Join-Path $ClaudeMemRoot "versions"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$EstadoFile = Join-Path $ClaudeMemRoot "estado.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$VersionarScript = Join-Path $PSScriptRoot "Versionar-ClaudeMem.ps1"
$ReconstruirIndiceScript = Join-Path $PSScriptRoot "Reconstruir-Indice-ClaudeMem.ps1"
$AuditoriaSaludScript = Join-Path $PSScriptRoot "Auditoria-ClaudeMem-Salud.ps1"

$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$PropiedadTemporal = "pruebaRestauracion_$MarcaTiempo"
$ValorTemporal = "PRUEBA-$MarcaTiempo"
$RespaldoEmergencia = Join-Path $BackupsFolder "estado-antes-prueba-restauracion-$MarcaTiempo.json"
$VersionesPruebaFolder = Join-Path $BackupsFolder "versiones-prueba"
$VersionesContaminadasFolder = Join-Path $BackupsFolder "versiones-prueba-contaminadas"
$ReportFile = Join-Path $ReportsFolder "Reporte-Prueba-Restauracion-ClaudeMem-$MarcaTiempo.txt"
$script:Resultados = @()
$script:RestauracionConfirmada = $false
$script:VersionTemporalId = $null

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
    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - PRUEBA RESTAURACION V2: $Mensaje" -Encoding UTF8
}

function Leer-Json {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    $Texto = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    return ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
}

function Guardar-Json {
    param(
        [Parameter(Mandatory = $true)][string]$Ruta,
        [Parameter(Mandatory = $true)][object]$Objeto
    )
    $Temporal = "$Ruta.tmp"
    $Json = ConvertTo-Json -InputObject $Objeto -Depth 30
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $null = ConvertFrom-Json -InputObject ([System.IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Obtener-Hash {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    return (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256 -ErrorAction Stop).Hash
}

function Obtener-PropiedadesTemporales {
    param([Parameter(Mandatory = $true)][object]$Estado)
    return @($Estado.PSObject.Properties.Name | Where-Object { $_ -like "pruebaRestauracion*" })
}

function Obtener-VersionesFisicas {
    return @(Get-ChildItem -LiteralPath $VersionsFolder -Directory -Filter "VER-*" -ErrorAction Stop | Sort-Object Name)
}

function Apartar-VersionesContaminadas {
    Crear-Carpeta -Ruta $VersionesContaminadasFolder
    $Movidas = @()

    foreach ($Carpeta in @(Obtener-VersionesFisicas)) {
        $SnapshotEstado = Join-Path $Carpeta.FullName "snapshot\estado.json"
        if (-not (Test-Path -LiteralPath $SnapshotEstado -PathType Leaf)) { continue }

        try {
            $Estado = Leer-Json -Ruta $SnapshotEstado
            $Temporales = @(Obtener-PropiedadesTemporales -Estado $Estado)
            if ($Temporales.Count -gt 0) {
                $Destino = Join-Path $VersionesContaminadasFolder $Carpeta.Name
                if (Test-Path -LiteralPath $Destino) {
                    $Destino = Join-Path $VersionesContaminadasFolder ($Carpeta.Name + "-$MarcaTiempo")
                }
                Move-Item -LiteralPath $Carpeta.FullName -Destination $Destino -Force
                $Movidas += $Carpeta.Name
            }
        }
        catch {
            Escribir-Log "NO SE PUDO AUDITAR $($Carpeta.Name): $($_.Exception.Message)"
        }
    }

    return $Movidas
}

function Obtener-VersionBaseLimpia {
    $Candidatas = @(Obtener-VersionesFisicas | Sort-Object Name -Descending)
    foreach ($Carpeta in $Candidatas) {
        $ManifestFile = Join-Path $Carpeta.FullName "manifest.json"
        $SnapshotEstado = Join-Path $Carpeta.FullName "snapshot\estado.json"
        if (-not (Test-Path -LiteralPath $ManifestFile -PathType Leaf)) { continue }
        if (-not (Test-Path -LiteralPath $SnapshotEstado -PathType Leaf)) { continue }

        try {
            $Manifest = Leer-Json -Ruta $ManifestFile
            $Estado = Leer-Json -Ruta $SnapshotEstado
            if ([string]$Manifest.estado -ne "VALIDA") { continue }
            if (@(Obtener-PropiedadesTemporales -Estado $Estado).Count -gt 0) { continue }

            $EntradaEstado = @($Manifest.archivos | Where-Object { [string]$_.rutaRelativa -eq "estado.json" })
            if ($EntradaEstado.Count -ne 1) { continue }
            $HashSnapshot = Obtener-Hash -Ruta $SnapshotEstado
            if ($HashSnapshot -ne [string]$EntradaEstado[0].sha256) { continue }

            return [PSCustomObject]@{
                Id = [string]$Manifest.id
                Carpeta = $Carpeta.FullName
                HashEstado = $HashSnapshot
            }
        }
        catch { continue }
    }
    throw "No se encontro una version base limpia y valida."
}

function Obtener-VersionMasRecienteId {
    $Carpetas = @(Obtener-VersionesFisicas | Sort-Object Name -Descending)
    if ($Carpetas.Count -eq 0) { throw "No existen versiones fisicas." }
    return $Carpetas[0].Name
}

function Obtener-Manifest {
    param([Parameter(Mandatory = $true)][string]$VersionId)
    return Leer-Json -Ruta (Join-Path $VersionsFolder "$VersionId\manifest.json")
}

function Escribir-Informe {
    $Total = $script:Resultados.Count
    $Aprobadas = @($script:Resultados | Where-Object Estado -eq "PASS").Count
    $Fallidas = $Total - $Aprobadas
    $Porcentaje = if ($Total -gt 0) { [math]::Round(($Aprobadas / $Total) * 100, 2) } else { 0 }
    $EstadoFinal = if ($Fallidas -eq 0) { "APROBADO" } else { "NO APROBADO" }

    @(
        "REPORTE DE PRUEBA DE RESTAURACION CLAUDEMEM V2"
        "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "Estado: $EstadoFinal"
        "Aprobadas: $Aprobadas"
        "Fallidas: $Fallidas"
        "Total: $Total"
        "Resultado: $Porcentaje %"
        ""
    ) | Set-Content -LiteralPath $ReportFile -Encoding UTF8

    $script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize |
        Out-String | Add-Content -LiteralPath $ReportFile -Encoding UTF8

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " RESULTADO DE PRUEBA DE RESTAURACION V2" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    $script:Resultados | Format-Table ID, Estado, Prueba, Detalle -AutoSize
    Write-Host ""
    Write-Host "Aprobadas: $Aprobadas / $Total"
    Write-Host "Resultado: $Porcentaje %"
    Write-Host "Estado: $EstadoFinal"
    Write-Host "Informe: $ReportFile"
    Write-Host ""
    return $(if ($Fallidas -eq 0) { 0 } else { 1 })
}

Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $ReportsFolder
Crear-Carpeta -Ruta $LogsFolder
Crear-Carpeta -Ruta $VersionesPruebaFolder
if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " PRUEBA CONTROLADA DE RESTAURACION CLAUDEMEM V2" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

try {
    $Requisitos = @($VersionarScript, $ReconstruirIndiceScript, $AuditoriaSaludScript, $EstadoFile)
    $Faltantes = @($Requisitos | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
    if ($Faltantes.Count -gt 0) { throw "Faltan requisitos: $($Faltantes -join '; ')" }
    Agregar-Resultado -Id "RST2-001" -Prueba "Validar requisitos" -Aprobada $true -Detalle "4 requisitos disponibles"

    $Contaminadas = @(Apartar-VersionesContaminadas)
    & $VersionarScript -ListarVersiones | Out-Host
    Agregar-Resultado -Id "RST2-002" -Prueba "Auditar versiones contaminadas" -Aprobada $true -Detalle "Apartadas: $($Contaminadas.Count)"

    $Base = Obtener-VersionBaseLimpia
    Agregar-Resultado -Id "RST2-003" -Prueba "Seleccionar version base limpia" -Aprobada $true -Detalle $Base.Id

    Copy-Item -LiteralPath $EstadoFile -Destination $RespaldoEmergencia -Force
    Agregar-Resultado -Id "RST2-004" -Prueba "Crear respaldo de emergencia" -Aprobada $true -Detalle $RespaldoEmergencia

    $EstadoActual = Leer-Json -Ruta $EstadoFile
    $EstadoActual | Add-Member -NotePropertyName $PropiedadTemporal -NotePropertyValue $ValorTemporal -Force
    Guardar-Json -Ruta $EstadoFile -Objeto $EstadoActual
    $EstadoModificado = Leer-Json -Ruta $EstadoFile
    $CambioAplicado = $EstadoModificado.PSObject.Properties.Name -contains $PropiedadTemporal
    if (-not $CambioAplicado) { throw "No se aplico el cambio temporal unico." }
    Agregar-Resultado -Id "RST2-005" -Prueba "Aplicar cambio temporal unico" -Aprobada $true -Detalle $PropiedadTemporal

    & $VersionarScript | Out-Host
    if (-not $?) { throw "El versionador informo error al crear la version temporal." }
    $script:VersionTemporalId = Obtener-VersionMasRecienteId
    $ManifestTemporal = Obtener-Manifest -VersionId $script:VersionTemporalId
    $Deteccion = (
        [int]$ManifestTemporal.resumen.modificados -eq 1 -and
        [int]$ManifestTemporal.resumen.nuevos -eq 0 -and
        [int]$ManifestTemporal.resumen.sinCambios -eq 7
    )
    Agregar-Resultado -Id "RST2-006" -Prueba "Detectar 1 modificado y 7 iguales" -Aprobada $Deteccion -Detalle $script:VersionTemporalId
    if (-not $Deteccion) { throw "Clasificacion de cambios inesperada." }

    $BackupsAntes = @(Get-ChildItem -LiteralPath $BackupsFolder -File -Filter "pre-restauracion-$($Base.Id)-*.zip" -ErrorAction SilentlyContinue).Count
    & $VersionarScript -RestaurarVersion $Base.Id | Out-Host
    if (-not $?) { throw "La restauracion informo error." }

    $HashRestaurado = Obtener-Hash -Ruta $EstadoFile
    $script:RestauracionConfirmada = ($HashRestaurado -eq $Base.HashEstado)
    Agregar-Resultado -Id "RST2-007" -Prueba "Validar SHA-256 restaurado" -Aprobada $script:RestauracionConfirmada -Detalle $HashRestaurado
    if (-not $script:RestauracionConfirmada) { throw "El hash restaurado no coincide con la base." }

    $EstadoRestaurado = Leer-Json -Ruta $EstadoFile
    $TemporalesRestantes = @(Obtener-PropiedadesTemporales -Estado $EstadoRestaurado)
    $CambioEliminado = ($TemporalesRestantes.Count -eq 0)
    Agregar-Resultado -Id "RST2-008" -Prueba "Eliminar propiedades temporales" -Aprobada $CambioEliminado -Detalle "Restantes: $($TemporalesRestantes.Count)"
    if (-not $CambioEliminado) { throw "Persisten propiedades temporales despues de restaurar." }

    $BackupsDespues = @(Get-ChildItem -LiteralPath $BackupsFolder -File -Filter "pre-restauracion-$($Base.Id)-*.zip" -ErrorAction SilentlyContinue)
    $BackupOk = ($BackupsDespues.Count -gt $BackupsAntes -and @($BackupsDespues | Where-Object Length -gt 0).Count -gt 0)
    Agregar-Resultado -Id "RST2-009" -Prueba "Validar backup pre-restauracion" -Aprobada $BackupOk -Detalle "Antes=$BackupsAntes; despues=$($BackupsDespues.Count)"

    & $ReconstruirIndiceScript | Out-Host
    $IndiceOk = $?
    Agregar-Resultado -Id "RST2-010" -Prueba "Reconstruir indice" -Aprobada $IndiceOk -Detalle "Ejecucion completada"

    & $AuditoriaSaludScript | Out-Host
    $SaludOk = $?
    Agregar-Resultado -Id "RST2-011" -Prueba "Auditoria de salud" -Aprobada $SaludOk -Detalle "Ejecucion completada"

    $CarpetaTemporal = Join-Path $VersionsFolder $script:VersionTemporalId
    if (Test-Path -LiteralPath $CarpetaTemporal -PathType Container) {
        $DestinoTemporal = Join-Path $VersionesPruebaFolder $script:VersionTemporalId
        if (Test-Path -LiteralPath $DestinoTemporal) {
            $DestinoTemporal = Join-Path $VersionesPruebaFolder ($script:VersionTemporalId + "-$MarcaTiempo")
        }
        Move-Item -LiteralPath $CarpetaTemporal -Destination $DestinoTemporal -Force
    }
    & $VersionarScript -ListarVersiones | Out-Host
    $Retirada = -not (Test-Path -LiteralPath $CarpetaTemporal -PathType Container)
    Agregar-Resultado -Id "RST2-012" -Prueba "Retirar version temporal" -Aprobada $Retirada -Detalle $script:VersionTemporalId

    Escribir-Log "PRUEBA APROBADA: base=$($Base.Id); temporal=$($script:VersionTemporalId)"
}
catch {
    $Mensaje = $_.Exception.Message
    Agregar-Resultado -Id "RST2-ERR" -Prueba "Ejecucion general" -Aprobada $false -Detalle $Mensaje
    Escribir-Log "ERROR: $Mensaje"

    if (-not $script:RestauracionConfirmada -and (Test-Path -LiteralPath $RespaldoEmergencia -PathType Leaf)) {
        try {
            Copy-Item -LiteralPath $RespaldoEmergencia -Destination $EstadoFile -Force
            Agregar-Resultado -Id "RST2-REC" -Prueba "Recuperacion de emergencia" -Aprobada $true -Detalle $RespaldoEmergencia
        }
        catch {
            Agregar-Resultado -Id "RST2-REC" -Prueba "Recuperacion de emergencia" -Aprobada $false -Detalle $_.Exception.Message
        }
    }
}

$Codigo = Escribir-Informe
exit $Codigo
