#Requires -Version 5.1

<#
.SYNOPSIS
    Corrige el uso incompatible de HasValue en Buscar-ClaudeMem-Avanzado.ps1.

.DESCRIPTION
    Crea respaldo, reemplaza las cinco referencias HasValue incompatibles con
    Windows PowerShell 5.1, actualiza la version a 1.1.0, valida sintaxis y
    comprueba que la palabra HasValue haya desaparecido del archivo operativo.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Buscador = Join-Path $PSScriptRoot "Buscar-ClaudeMem-Avanzado.ps1"
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups\scripts-corregidos"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $BackupsFolder "Buscar-ClaudeMem-Avanzado-$MarcaTiempo.ps1"
$Temporal = "$Buscador.tmp"

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Obtener-ErroresSintaxis {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    $Tokens = $null
    $Errores = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Ruta,
        [ref]$Tokens,
        [ref]$Errores
    )
    return @($Errores)
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " REPARAR BUSCADOR AVANZADO CLAUDEMEM" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $Buscador -PathType Leaf)) {
    throw "No existe el buscador operativo: $Buscador"
}

Crear-Carpeta -Ruta $BackupsFolder
Copy-Item -LiteralPath $Buscador -Destination $Backup -Force
Write-Host "[OK] Respaldo creado:" -ForegroundColor Green
Write-Host $Backup
Write-Host ""

$Contenido = Get-Content -LiteralPath $Buscador -Raw -ErrorAction Stop
$CoincidenciasAntes = @([regex]::Matches($Contenido, 'HasValue')).Count

Write-Host "Referencias HasValue detectadas: $CoincidenciasAntes"

if ($CoincidenciasAntes -eq 0) {
    Write-Host "El archivo ya no contiene HasValue." -ForegroundColor Yellow
}
else {
    $Contenido = $Contenido.Replace(
        'if ($FechaDesde.HasValue) {',
        'if ($null -ne $FechaDesde) {'
    )
    $Contenido = $Contenido.Replace(
        '$_.fechaOrden -ge $FechaDesde.Value.Date',
        '$_.fechaOrden -ge ([datetime]$FechaDesde).Date'
    )
    $Contenido = $Contenido.Replace(
        'if ($FechaHasta.HasValue) {',
        'if ($null -ne $FechaHasta) {'
    )
    $Contenido = $Contenido.Replace(
        '$FechaHasta.Value.Date.AddDays(1).AddTicks(-1)',
        '([datetime]$FechaHasta).Date.AddDays(1).AddTicks(-1)'
    )
    $Contenido = $Contenido.Replace(
        'if ($Desde.HasValue -and $Hasta.HasValue -and $Desde.Value.Date -gt $Hasta.Value.Date) {',
        'if ($null -ne $Desde -and $null -ne $Hasta -and ([datetime]$Desde).Date -gt ([datetime]$Hasta).Date) {'
    )
    $Contenido = $Contenido.Replace(
        'Desde = $(if ($Desde.HasValue) { $Desde.Value.ToString("yyyy-MM-dd") } else { "" })',
        'Desde = $(if ($null -ne $Desde) { ([datetime]$Desde).ToString("yyyy-MM-dd") } else { "" })'
    )
    $Contenido = $Contenido.Replace(
        'Hasta = $(if ($Hasta.HasValue) { $Hasta.Value.ToString("yyyy-MM-dd") } else { "" })',
        'Hasta = $(if ($null -ne $Hasta) { ([datetime]$Hasta).ToString("yyyy-MM-dd") } else { "" })'
    )
}

$Contenido = [regex]::Replace(
    $Contenido,
    '(?m)^(\s*)1\.0\.0\s*$',
    '${1}1.1.0',
    1
)

Set-Content -LiteralPath $Temporal -Value $Contenido -Encoding UTF8

$Errores = @(Obtener-ErroresSintaxis -Ruta $Temporal)
if ($Errores.Count -gt 0) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    Write-Host "[ERROR] La copia corregida tiene errores de sintaxis." -ForegroundColor Red
    foreach ($ErrorSintaxis in $Errores) {
        Write-Host ("Linea {0}: {1}" -f $ErrorSintaxis.Extent.StartLineNumber, $ErrorSintaxis.Message) -ForegroundColor Red
    }
    throw "Correccion cancelada. El buscador original no fue modificado."
}

$ContenidoTemporal = Get-Content -LiteralPath $Temporal -Raw
$CoincidenciasDespues = @([regex]::Matches($ContenidoTemporal, 'HasValue')).Count

if ($CoincidenciasDespues -ne 0) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    throw "Persisten $CoincidenciasDespues referencias HasValue. No se reemplazo el buscador."
}

if ($ContenidoTemporal -notmatch '(?m)^\s*1\.1\.0\s*$') {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    throw "No se pudo actualizar el marcador de version a 1.1.0."
}

Move-Item -LiteralPath $Temporal -Destination $Buscador -Force

$ErroresFinales = @(Obtener-ErroresSintaxis -Ruta $Buscador)
if ($ErroresFinales.Count -gt 0) {
    Copy-Item -LiteralPath $Backup -Destination $Buscador -Force
    throw "La validacion final fallo. Se restauro el respaldo."
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host " REPARACION COMPLETADA" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Sintaxis valida" -ForegroundColor Green
Write-Host "[OK] Version 1.1.0 instalada" -ForegroundColor Green
Write-Host "[OK] Referencias HasValue eliminadas" -ForegroundColor Green
Write-Host ""
Write-Host "Siguiente comando:" -ForegroundColor Cyan
Write-Host '.\Buscar-ClaudeMem-Avanzado.ps1 -PruebaControlada'
Write-Host ""
