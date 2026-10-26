#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6C
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$RutaPaquete,[switch]$Aplicar)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $RutaPaquete -PathType Container)){throw 'RutaPaquete inexistente.'}
$Origen=Join-Path $RutaPaquete 'ClaudeMem-Copilot-Panel-v2.0.ps1';if(-not(Test-Path $Origen)){throw 'Falta panel v2.0.'}
$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($Origen,[ref]$T,[ref]$E);if(@($E).Count){throw 'Panel v2.0 tiene errores de sintaxis.'}
$Destino=Join-Path $PSScriptRoot 'ClaudeMem-Copilot-Panel.ps1';$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem';$Backup=Join-Path (Join-Path $CM 'backups') ("panel-pre-6C-{0}.ps1"-f(Get-Date -Format 'yyyyMMdd-HHmmss'))
Write-Host "Origen: $Origen";Write-Host "Destino: $Destino";Write-Host "Backup: $Backup"
if(-not$Aplicar){Write-Host 'SIMULACION APROBADA. Use -Aplicar para instalar.' -ForegroundColor Yellow;return}
Copy-Item -LiteralPath $Destino -Destination $Backup -Force;Copy-Item -LiteralPath $Origen -Destination $Destino -Force
Write-Host 'PANEL 6C INSTALADO' -ForegroundColor Green
