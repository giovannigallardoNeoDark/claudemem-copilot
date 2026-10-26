#Requires -Version 5.1
# VERSION 1.1.0
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Contenido,
    [string]$RutaOrigen = '',
    [ValidateSet('PUBLICO','INTERNO','CONFIDENCIAL','RESTRINGIDO','NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')]
    [string]$Clasificacion = 'INTERNO',
    [switch]$ComoJson
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$ConfigRoot = Join-Path $ClaudeMemRoot 'config'


function Expandir-ValoresTexto {
    param([AllowNull()][object]$Nodo)
    $Salida = @()
    if ($null -eq $Nodo) { return $Salida }
    if ($Nodo -is [string]) {
        if (-not [string]::IsNullOrWhiteSpace($Nodo)) { $Salida += $Nodo }
        return $Salida
    }
    if ($Nodo -is [System.Array]) {
        foreach ($Elemento in $Nodo) { $Salida += @(Expandir-ValoresTexto -Nodo $Elemento) }
        return $Salida
    }
    $Nombres = @($Nodo.PSObject.Properties.Name)
    if ($Nombres -contains 'value') {
        $Salida += @(Expandir-ValoresTexto -Nodo $Nodo.value)
    }
    return $Salida
}

function Leer-JsonConfiguracion {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) { throw "Falta configuracion: $Ruta" }
    return Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}

$Politicas = Leer-JsonConfiguracion -Ruta (Join-Path $ConfigRoot 'politicas-captura.json')
$RutasRaw = Leer-JsonConfiguracion -Ruta (Join-Path $ConfigRoot 'rutas-excluidas.json')
$PatronesRaw = Leer-JsonConfiguracion -Ruta (Join-Path $ConfigRoot 'patrones-secretos.json')
$RutasExcluidas = @(Expandir-ValoresTexto -Nodo $RutasRaw)
$PatronesSecretos = @(Expandir-ValoresTexto -Nodo $PatronesRaw)
if ($RutasExcluidas.Count -eq 0) { throw 'La configuracion de rutas excluidas no contiene patrones validos.' }
if ($PatronesSecretos.Count -eq 0) { throw 'La configuracion de secretos no contiene patrones validos.' }

$Razones = @()
$Accion = 'CAPTURAR'
$ContenidoProcesado = $Contenido

if ($Clasificacion -eq 'NO_CAPTURAR') {
    $Accion = 'RECHAZAR'
    $Razones += 'Clasificacion NO_CAPTURAR'
}

if (-not [string]::IsNullOrWhiteSpace($RutaOrigen)) {
    foreach ($PatronRuta in $RutasExcluidas) {
        if ($RutaOrigen -like [string]$PatronRuta) {
            $Accion = 'RECHAZAR'
            $Razones += "Ruta excluida: $PatronRuta"
            break
        }
    }
}

if ($Accion -ne 'RECHAZAR' -and [bool]$Politicas.excluirSecretos) {
    foreach ($Patron in $PatronesSecretos) {
        try {
            if ([regex]::IsMatch($ContenidoProcesado, [string]$Patron, [Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
                $Accion = 'RECHAZAR'
                $Razones += "Patron sensible detectado: $Patron"
            }
        }
        catch {
            throw "Patron regex invalido '$Patron': $($_.Exception.Message)"
        }
    }
}

if ($Accion -eq 'CAPTURAR') {
    if ($Clasificacion -eq 'NO_INDEXAR') { $Accion = 'CAPTURAR_NO_INDEXAR' }
    elseif ($Clasificacion -eq 'NO_COMPARTIR') { $Accion = 'CAPTURAR_NO_COMPARTIR' }
    elseif ($Clasificacion -in @('CONFIDENCIAL','RESTRINGIDO')) { $Accion = 'REQUIERE_REVISION' }
}

$Resultado = [PSCustomObject][ordered]@{
    permitido = ($Accion -ne 'RECHAZAR')
    accion = $Accion
    clasificacion = $Clasificacion
    rutaOrigen = $RutaOrigen
    contenidoProcesado = $(if ($Accion -eq 'RECHAZAR') { '' } else { $ContenidoProcesado })
    razones = @($Razones)
    fechaEvaluacion = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
}

if ($ComoJson) { $Resultado | ConvertTo-Json -Depth 10 } else { $Resultado }
