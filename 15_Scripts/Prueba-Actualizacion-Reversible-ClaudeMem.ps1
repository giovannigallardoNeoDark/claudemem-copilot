#Requires -Version 5.1
# VERSION 1.1.0 - FASE 5A
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$BackupsRoot = Join-Path $ClaudeMemRoot 'backups'
$Temp = Join-Path $env:TEMP ('ClaudeMem-Paquete-' + [guid]::NewGuid().ToString('N'))
$Origen = Join-Path $PSScriptRoot 'Invocar-ClaudeMem-Copilot.ps1'
$Actualizador = Join-Path $PSScriptRoot 'Actualizar-ClaudeMem-Potenciado.ps1'

$Resultados = @()
$HashAntes = (Get-FileHash -LiteralPath $Origen -Algorithm SHA256).Hash
$BackupsAntes = @(
    Get-ChildItem -LiteralPath $BackupsRoot -Directory -Filter 'actualizacion-*' -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
)

try {
    New-Item -ItemType Directory -Path $Temp -Force | Out-Null
    Copy-Item -LiteralPath $Origen -Destination $Temp -Force

    # 6>&1 incorpora Write-Host al flujo capturado en Windows PowerShell 5.1.
    $Salida = @(& $Actualizador -RutaPaquete $Temp 6>&1 2>&1)
    $TextoSalida = ($Salida | ForEach-Object { [string]$_ }) -join [Environment]::NewLine

    $BackupsDespues = @(
        Get-ChildItem -LiteralPath $BackupsRoot -Directory -Filter 'actualizacion-*' -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
    )
    $NuevosBackups = @($BackupsDespues | Where-Object { $_ -notin $BackupsAntes })

    $HashDespues = (Get-FileHash -LiteralPath $Origen -Algorithm SHA256).Hash
    $HashPaquete = (Get-FileHash -LiteralPath (Join-Path $Temp 'Invocar-ClaudeMem-Copilot.ps1') -Algorithm SHA256).Hash

    $Resultados += [PSCustomObject]@{
        Estado = $(if ($NuevosBackups.Count -gt 0) { 'PASS' } else { 'FAIL' })
        Prueba = 'Backup creado'
        Detalle = $(if ($NuevosBackups.Count -gt 0) { $NuevosBackups[-1] } else { 'No detectado' })
    }
    $Resultados += [PSCustomObject]@{
        Estado = $(if ($TextoSalida -match 'Simulacion aprobada') { 'PASS' } else { 'FAIL' })
        Prueba = 'Simulacion'
        Detalle = $(if ($TextoSalida -match 'Simulacion aprobada') { 'Mensaje detectado' } else { 'Mensaje no detectado' })
    }
    $Resultados += [PSCustomObject]@{
        Estado = $(if (($HashAntes -eq $HashDespues) -and ($HashDespues -eq $HashPaquete)) { 'PASS' } else { 'FAIL' })
        Prueba = 'Original intacto'
        Detalle = $(if ($HashAntes -eq $HashDespues) { 'SHA-256 sin cambios' } else { 'SHA-256 modificado' })
    }
}
finally {
    Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue
}

$Resultados | Format-Table -AutoSize
$Aprobadas = @($Resultados | Where-Object { [string]$_.Estado -eq 'PASS' }).Count
Write-Host "Aprobadas: $Aprobadas / $($Resultados.Count)"
if ($Aprobadas -ne $Resultados.Count) { exit 1 }
Write-Host 'PRUEBA DE ACTUALIZACION REVERSIBLE APROBADA' -ForegroundColor Green
