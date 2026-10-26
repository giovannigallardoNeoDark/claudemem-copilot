#Requires -Version 5.1
# VERSION 1.2.0 - VALIDACION PAQUETE CLAUDEMEM COPILOT
[CmdletBinding()]
param(
    [string]$RutaRaiz
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RutaRaiz)) {
    $RutaScript = $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($RutaScript)) {
        throw 'No se pudo determinar la ruta del validador.'
    }
    $RutaScripts = Split-Path -Parent $RutaScript
    $RutaRaiz = Split-Path -Parent $RutaScripts
}

$RutaRaiz = (Resolve-Path -LiteralPath $RutaRaiz -ErrorAction Stop).Path
$RutaDist = Join-Path $RutaRaiz 'dist\appPackage'
$Resultados = @()

function Agregar-Resultado {
    param(
        [string]$Prueba,
        [ValidateSet('PASS','FAIL','PENDIENTE')]
        [string]$Estado,
        [string]$Detalle = ''
    )

    $script:Resultados += [pscustomobject][ordered]@{
        Estado = $Estado
        Prueba = $Prueba
        Detalle = $Detalle
    }
}

foreach ($Nombre in @('manifest.json','declarativeAgent.json','instructions.txt')) {
    $Ruta = Join-Path $RutaDist $Nombre
    Agregar-Resultado `
        -Prueba "Existe $Nombre" `
        -Estado $(if (Test-Path -LiteralPath $Ruta -PathType Leaf) { 'PASS' } else { 'FAIL' }) `
        -Detalle $Ruta
}

foreach ($Nombre in @('manifest.json','declarativeAgent.json')) {
    $Ruta = Join-Path $RutaDist $Nombre

    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        Agregar-Resultado -Prueba "JSON valido $Nombre" -Estado 'FAIL' -Detalle 'Archivo inexistente'
        continue
    }

    try {
        $null = Get-Content -LiteralPath $Ruta -Raw | ConvertFrom-Json -ErrorAction Stop
        Agregar-Resultado -Prueba "JSON valido $Nombre" -Estado 'PASS'
    }
    catch {
        Agregar-Resultado -Prueba "JSON valido $Nombre" -Estado 'FAIL' -Detalle $_.Exception.Message
    }
}

$ArchivosTexto = @(
    Get-ChildItem -LiteralPath $RutaRaiz -Recurse -File -ErrorAction Stop |
    Where-Object {
        $_.FullName -notmatch '[\\/]config\.local\.json$' -and
        $_.Extension -in @('.json','.txt','.md','.ps1','.yml','.yaml')
    }
)

$ContenidoProyecto = @(
    foreach ($Archivo in $ArchivosTexto) {
        try {
            Get-Content -LiteralPath $Archivo.FullName -Raw -ErrorAction Stop
        }
        catch { }
    }
) -join "`n"

$SecretoDetectado = $ContenidoProyecto -match 'CLAUDEMEM_API_KEY\s*=\s*[A-Za-z0-9+/=]{40,}'
Agregar-Resultado `
    -Prueba 'Sin clave API incrustada' `
    -Estado $(if ($SecretoDetectado) { 'FAIL' } else { 'PASS' })

$RutaManifest = Join-Path $RutaDist 'manifest.json'
$UrlMcpConfigurada = $false
$MarcadoresPendientes = $false

if (Test-Path -LiteralPath $RutaManifest -PathType Leaf) {
    $ManifestTexto = Get-Content -LiteralPath $RutaManifest -Raw
    $UrlMcpConfigurada = $ManifestTexto -match 'https://[^"\s]+/mcp'
    $MarcadoresPendientes = $ManifestTexto -match '\{\{[^}]+\}\}'
}

Agregar-Resultado `
    -Prueba 'URL MCP configurada' `
    -Estado $(if ($UrlMcpConfigurada) { 'PASS' } else { 'FAIL' })

Agregar-Resultado `
    -Prueba 'Sin marcadores de plantilla' `
    -Estado $(if ($MarcadoresPendientes) { 'FAIL' } else { 'PASS' })

foreach ($Icono in @('color.png','outline.png')) {
    $RutaIcono = Join-Path $RutaDist $Icono
    Agregar-Resultado `
        -Prueba "Icono $Icono" `
        -Estado $(if (Test-Path -LiteralPath $RutaIcono -PathType Leaf) { 'PASS' } else { 'PENDIENTE' }) `
        -Detalle $RutaIcono
}

$Resultados | Format-Table Estado, Prueba, Detalle -AutoSize

$Fallidas = @($Resultados | Where-Object { $_.Estado -eq 'FAIL' }).Count
$Pendientes = @($Resultados | Where-Object { $_.Estado -eq 'PENDIENTE' }).Count
$Aprobadas = @($Resultados | Where-Object { $_.Estado -eq 'PASS' }).Count

Write-Host "Aprobadas: $Aprobadas | Pendientes: $Pendientes | Fallidas: $Fallidas"

if ($Fallidas -gt 0) {
    Write-Host 'VALIDACION ESTRUCTURAL BLOQUEADA' -ForegroundColor Red
    exit 1
}

Write-Host 'VALIDACION ESTRUCTURAL APROBADA' -ForegroundColor Green
if ($Pendientes -gt 0) {
    Write-Warning 'El paquete aun no esta listo para ZIP final: faltan uno o mas iconos.'
}
