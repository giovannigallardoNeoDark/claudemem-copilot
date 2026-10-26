#Requires -Version 5.1
# VERSION 1.0.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SesionId,
    [Parameter(Mandatory = $true)][ValidateSet('evento','observacion')][string]$TipoRegistro,
    [Parameter(Mandatory = $true)][string]$Contenido,
    [string]$TipoEvento = 'actividad',
    [string]$RutaOrigen = '',
    [ValidateSet('PUBLICO','INTERNO','CONFIDENCIAL','RESTRINGIDO','NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')]
    [string]$Clasificacion = 'INTERNO'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Filtro = Join-Path $PSScriptRoot 'Filtrar-Contenido-Sensible-ClaudeMem.ps1'
$Gestor = Join-Path $PSScriptRoot 'Gestionar-Sesiones-ClaudeMem.ps1'
if (-not (Test-Path -LiteralPath $Filtro -PathType Leaf)) { throw "Falta filtro: $Filtro" }
if (-not (Test-Path -LiteralPath $Gestor -PathType Leaf)) { throw "Falta gestor: $Gestor" }

$Evaluacion = & $Filtro -Contenido $Contenido -RutaOrigen $RutaOrigen -Clasificacion $Clasificacion
if (-not [bool]$Evaluacion.permitido) {
    [PSCustomObject]@{ estado='BLOQUEADO'; accion=$Evaluacion.accion; razones=@($Evaluacion.razones) }
    exit 2
}

if ($TipoRegistro -eq 'evento') {
    $Salida = & $Gestor -RegistrarEvento -SesionId $SesionId -TipoEvento $TipoEvento -Contenido ([string]$Evaluacion.contenidoProcesado)
}
else {
    if ($Evaluacion.accion -eq 'REQUIERE_REVISION') {
        $ContenidoFinal = "[REQUIERE_REVISION][$Clasificacion] $([string]$Evaluacion.contenidoProcesado)"
    }
    else { $ContenidoFinal = [string]$Evaluacion.contenidoProcesado }
    $Salida = & $Gestor -RegistrarObservacion -SesionId $SesionId -Contenido $ContenidoFinal -Clasificacion $Clasificacion
}

[PSCustomObject]@{
    estado = 'REGISTRADO'
    accion = [string]$Evaluacion.accion
    salida = @($Salida) -join ' '
    clasificacion = $Clasificacion
}
