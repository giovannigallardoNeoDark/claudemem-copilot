#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5A
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RutaPaquete,[switch]$Aplicar)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$CopilotRoot=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
if(-not(Test-Path -LiteralPath $RutaPaquete -PathType Container)){throw 'RutaPaquete debe ser una carpeta preparada.'}
$Archivos=@(Get-ChildItem -LiteralPath $RutaPaquete -File -Filter '*.ps1')
if($Archivos.Count-eq0){throw 'El paquete no contiene scripts PowerShell.'}
foreach($A in $Archivos){$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($A.FullName,[ref]$T,[ref]$E);if(@($E).Count){throw "Sintaxis invalida en $($A.Name)"}}
$Backup=Join-Path (Join-Path $CM 'backups') ("actualizacion-{0}"-f(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path (Join-Path $Backup '15_Scripts') -Force|Out-Null
foreach($A in $Archivos){$Actual=Join-Path $PSScriptRoot $A.Name;if(Test-Path -LiteralPath $Actual){Copy-Item -LiteralPath $Actual -Destination (Join-Path $Backup '15_Scripts') -Force}}
$LanzadorActual=Join-Path $CopilotRoot 'Iniciar-ClaudeMem-Copilot.cmd';if(Test-Path -LiteralPath $LanzadorActual){Copy-Item -LiteralPath $LanzadorActual -Destination $Backup -Force}
Write-Host "Backup: $Backup"
if($Aplicar){foreach($A in $Archivos){Copy-Item -LiteralPath $A.FullName -Destination (Join-Path $PSScriptRoot $A.Name) -Force};Write-Host "Actualizados: $($Archivos.Count)" -ForegroundColor Green}else{Write-Host 'Simulacion aprobada. Use -Aplicar para instalar.' -ForegroundColor Yellow}
