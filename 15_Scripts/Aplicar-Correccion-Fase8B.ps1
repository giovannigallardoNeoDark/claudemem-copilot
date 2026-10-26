#Requires -Version 5.1
# VERSION 1.0.0 - CORRECCION FASE 8B
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$RutaPaquete)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$P=(Resolve-Path -LiteralPath $RutaPaquete).Path
$Mapa=@{
 'Cierre-Madurez-Operativa-ClaudeMem-v1.1.ps1'='Cierre-Madurez-Operativa-ClaudeMem.ps1'
 'Prueba-Cierre-Madurez-ClaudeMem-v1.1.ps1'='Prueba-Cierre-Madurez-ClaudeMem.ps1'
}
$Root=Split-Path -Parent $PSScriptRoot;$B=Join-Path $Root '11_Herramientas\ClaudeMem\backups';New-Item -ItemType Directory -Path $B -Force|Out-Null;$S=Get-Date -Format 'yyyyMMdd-HHmmss'
foreach($K in $Mapa.Keys){$O=Join-Path $P $K;$D=Join-Path $PSScriptRoot $Mapa[$K];if(-not(Test-Path $O)){throw "Falta $K"};$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($O,[ref]$T,[ref]$E);if(@($E).Count){throw "Sintaxis invalida: $K"};if(Test-Path $D){Copy-Item $D (Join-Path $B ("$($Mapa[$K]).pre-8B-v1.1.$S.bak")) -Force};Copy-Item $O $D -Force}
Write-Host 'CORRECCION FASE 8B APLICADA' -ForegroundColor Green
$Ciclo=Join-Path $PSScriptRoot 'Ejecutar-Ciclo-Automatico-ClaudeMem.ps1'
& $Ciclo -NombreIteracion 'FASE-8B-RECONFIRMACION' -GenerarManifiesto
exit $LASTEXITCODE
