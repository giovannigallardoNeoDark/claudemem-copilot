#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5A
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RutaBackup)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $RutaBackup -PathType Container)){throw "Backup inexistente: $RutaBackup"}
$Origen=Join-Path $RutaBackup '15_Scripts'
if(-not(Test-Path -LiteralPath $Origen -PathType Container)){throw 'El backup no contiene 15_Scripts.'}
Copy-Item -LiteralPath (Join-Path $Origen '*') -Destination $PSScriptRoot -Recurse -Force
$Lanzador=Join-Path $RutaBackup 'Iniciar-ClaudeMem-Copilot.cmd'
if(Test-Path -LiteralPath $Lanzador){Copy-Item -LiteralPath $Lanzador -Destination (Join-Path (Split-Path -Parent $PSScriptRoot) 'Iniciar-ClaudeMem-Copilot.cmd') -Force}
Write-Host "Restauracion completada desde: $RutaBackup" -ForegroundColor Green
