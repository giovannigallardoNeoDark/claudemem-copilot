#Requires -Version 5.1
# VERSION 1.1.0 - FASE 8A
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RutaPaquete,
    [switch]$Aplicar
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Nombres = @(
    'Analizar-Calidad-ClaudeMem.ps1',
    'Auditar-Analitica-Calidad-ClaudeMem.ps1',
    'Prueba-Analitica-Calidad-ClaudeMem.ps1'
)

$RutaPaqueteResuelta = (Resolve-Path -LiteralPath $RutaPaquete -ErrorAction Stop).Path
$Orquestador = Join-Path $PSScriptRoot 'Ejecutar-Ciclo-Automatico-ClaudeMem.ps1'
if (-not (Test-Path -LiteralPath $Orquestador -PathType Leaf)) {
    throw "Falta el orquestador activo: $Orquestador"
}

# Validacion integral previa de los componentes de la fase.
foreach ($Nombre in $Nombres) {
    $Origen = Join-Path $RutaPaqueteResuelta $Nombre
    if (-not (Test-Path -LiteralPath $Origen -PathType Leaf)) {
        throw "Falta el componente: $Nombre"
    }

    $Tokens = $null
    $Errores = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Origen,
        [ref]$Tokens,
        [ref]$Errores
    )
    if (@($Errores).Count -gt 0) {
        throw "Sintaxis invalida en $Nombre. Errores: $(@($Errores).Count)"
    }
}

$TextoOrquestador = Get-Content -LiteralPath $Orquestador -Raw -ErrorAction Stop
$EtapaAnalitica = "    @('Analitica de calidad','Auditar-Analitica-Calidad-ClaudeMem.ps1',@(),`$false),"
$PuntoIntegracion = "    @('Diagnostico general','Diagnosticar-ClaudeMem-Potenciado.ps1',@('-GenerarInforme'),`$false)"
$RequiereIntegracion = $TextoOrquestador -notmatch [regex]::Escape("@('Analitica de calidad'")

if ($RequiereIntegracion) {
    if (-not $TextoOrquestador.Contains($PuntoIntegracion)) {
        throw 'No se encontro el punto seguro de integracion en el orquestador.'
    }
    $TextoOrquestadorNuevo = $TextoOrquestador.Replace(
        $PuntoIntegracion,
        "$EtapaAnalitica`r`n$PuntoIntegracion"
    )
}
else {
    $TextoOrquestadorNuevo = $TextoOrquestador
}

$Plan = @()
foreach ($Nombre in $Nombres) {
    $Origen = Join-Path $RutaPaqueteResuelta $Nombre
    $Destino = Join-Path $PSScriptRoot $Nombre
    $MismoArchivo = [string]::Equals(
        [IO.Path]::GetFullPath($Origen),
        [IO.Path]::GetFullPath($Destino),
        [StringComparison]::OrdinalIgnoreCase
    )
    $Plan += [pscustomobject]@{
        componente = $Nombre
        origen = $Origen
        destino = $Destino
        accion = $(if ($MismoArchivo) { 'CONSERVAR_Y_VALIDAR' } else { 'COPIAR' })
    }
}

$Plan | Format-Table componente,accion -AutoSize
Write-Host "Integrar etapa analitica: $RequiereIntegracion"
Write-Host 'Simulacion Fase 8A aprobada.' -ForegroundColor Yellow

if (-not $Aplicar) {
    return
}

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$BackupsRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem\backups'
New-Item -ItemType Directory -Path $BackupsRoot -Force | Out-Null
$Sello = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupOrquestador = Join-Path $BackupsRoot "orquestador-pre-8A-$Sello.ps1"
Copy-Item -LiteralPath $Orquestador -Destination $BackupOrquestador -Force

foreach ($Elemento in $Plan) {
    if ($Elemento.accion -eq 'COPIAR') {
        if (Test-Path -LiteralPath $Elemento.destino -PathType Leaf) {
            $BackupComponente = Join-Path $BackupsRoot ("{0}-pre-8A-{1}.ps1" -f ([IO.Path]::GetFileNameWithoutExtension($Elemento.componente)),$Sello)
            Copy-Item -LiteralPath $Elemento.destino -Destination $BackupComponente -Force
        }
        Copy-Item -LiteralPath $Elemento.origen -Destination $Elemento.destino -Force
    }
}

if ($RequiereIntegracion) {
    [IO.File]::WriteAllText(
        $Orquestador,
        $TextoOrquestadorNuevo,
        [Text.UTF8Encoding]::new($true)
    )
}

# Confirmacion automatica posterior.
$TokensFinal = $null
$ErroresFinal = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $Orquestador,
    [ref]$TokensFinal,
    [ref]$ErroresFinal
)
if (@($ErroresFinal).Count -gt 0) {
    Copy-Item -LiteralPath $BackupOrquestador -Destination $Orquestador -Force
    throw 'La validacion posterior fallo. Orquestador restaurado automaticamente.'
}

$TextoFinal = Get-Content -LiteralPath $Orquestador -Raw
if ($TextoFinal -notmatch [regex]::Escape("@('Analitica de calidad'")) {
    Copy-Item -LiteralPath $BackupOrquestador -Destination $Orquestador -Force
    throw 'La etapa Analitica de calidad no quedo integrada. Orquestador restaurado.'
}

Write-Host "Backup del orquestador: $BackupOrquestador"
Write-Host 'FASE 8A INSTALADA Y CONFIRMADA' -ForegroundColor Green
