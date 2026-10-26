#Requires -Version 5.1
# VERSION 1.0.0
[CmdletBinding()]
param(
    [switch]$Reparar,
    [switch]$Auditar
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$RutaSesiones = Join-Path $ClaudeMemRoot 'episodios\sesiones.json'
$Backups = Join-Path $ClaudeMemRoot 'backups'

function Expandir-Sesiones {
    param([AllowNull()][object]$Nodo)
    $Resultado = @()
    if ($null -eq $Nodo) { return $Resultado }

    if ($Nodo -is [System.Array]) {
        foreach ($Elemento in $Nodo) {
            $Resultado += @(Expandir-Sesiones -Nodo $Elemento)
        }
        return $Resultado
    }

    $Propiedades = @($Nodo.PSObject.Properties.Name)
    if ($Propiedades -contains 'sesionId') {
        $Id = [string]$Nodo.sesionId
        if (-not [string]::IsNullOrWhiteSpace($Id)) {
            $Resultado += $Nodo
        }
        return $Resultado
    }

    if ($Propiedades -contains 'value') {
        $Resultado += @(Expandir-Sesiones -Nodo $Nodo.value)
    }
    return $Resultado
}

function Leer-SesionesRecuperadas {
    $Texto = Get-Content -LiteralPath $RutaSesiones -Raw -ErrorAction Stop
    $Datos = ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    $Todas = @(Expandir-Sesiones -Nodo $Datos)
    return @(
        $Todas |
        Group-Object { [string]$_.sesionId } |
        ForEach-Object { $_.Group | Select-Object -First 1 }
    )
}

function Auditar-Sesiones {
    $Sesiones = @(Leer-SesionesRecuperadas)
    $Errores = @()
    $Ids = @()
    foreach ($Sesion in $Sesiones) {
        $P = @($Sesion.PSObject.Properties.Name)
        foreach ($Campo in @('sesionId','inicio','objetivo','estado')) {
            if (-not ($P -contains $Campo) -or [string]::IsNullOrWhiteSpace([string]$Sesion.$Campo)) {
                $Errores += "$([string]$Sesion.sesionId): falta $Campo"
            }
        }
        if ([string]$Sesion.estado -notin @('ACTIVA','CERRADA')) {
            $Errores += "$([string]$Sesion.sesionId): estado invalido"
        }
        $Ids += [string]$Sesion.sesionId
    }
    $Duplicados = @($Ids | Group-Object | Where-Object Count -gt 1)
    if ($Duplicados.Count -gt 0) { $Errores += "IDs duplicados: $($Duplicados.Name -join ', ')" }

    [PSCustomObject]@{
        Sesiones = $Sesiones
        Cantidad = $Sesiones.Count
        Errores = $Errores
        Valido = ($Errores.Count -eq 0)
    }
}

if (-not (Test-Path -LiteralPath $RutaSesiones -PathType Leaf)) {
    throw "No existe sesiones.json: $RutaSesiones"
}

if ($Reparar) {
    New-Item -ItemType Directory -Path $Backups -Force | Out-Null
    $Backup = Join-Path $Backups ("sesiones-pre-reparacion-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $RutaSesiones -Destination $Backup -Force

    $Resultado = Auditar-Sesiones
    if ($Resultado.Cantidad -eq 0) { throw 'No se recuperaron sesiones validas. No se modifico el original.' }

    $Temporal = "$RutaSesiones.tmp"
    $Json = ConvertTo-Json -InputObject ([object[]]$Resultado.Sesiones) -Depth 30
    [System.IO.File]::WriteAllText($Temporal, $Json, [System.Text.UTF8Encoding]::new($true))
    $null = Get-Content -LiteralPath $Temporal -Raw | ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $RutaSesiones -Force

    Write-Host 'Almacen de sesiones reparado.' -ForegroundColor Green
    Write-Host "Backup: $Backup"
}

$Final = Auditar-Sesiones
$Final.Sesiones | Select-Object sesionId,inicio,fin,objetivo,estado | Format-Table -AutoSize
Write-Host "Sesiones validas: $($Final.Cantidad)"
Write-Host "Errores de esquema: $($Final.Errores.Count)"
if (-not $Final.Valido) {
    $Final.Errores | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}
Write-Host 'AUDITORIA DE SESIONES APROBADA' -ForegroundColor Green
