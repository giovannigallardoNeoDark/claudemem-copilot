#Requires -Version 5.1
# VERSION 1.0.0 - FASE 8A
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$RutaPaquete,[switch]$Aplicar)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$N=@('Analizar-Calidad-ClaudeMem.ps1','Auditar-Analitica-Calidad-ClaudeMem.ps1','Prueba-Analitica-Calidad-ClaudeMem.ps1');foreach($X in $N){$P=Join-Path $RutaPaquete $X;if(-not(Test-Path $P)){throw "Falta $X"};$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($P,[ref]$T,[ref]$E);if(@($E).Count){throw "Sintaxis invalida: $X"}}
$Orq=Join-Path $PSScriptRoot 'Ejecutar-Ciclo-Automatico-ClaudeMem.ps1';$Texto=Get-Content $Orq -Raw
if($Texto-notmatch "Analitica de calidad"){$Objetivo="    @('Diagnostico general','Diagnosticar-ClaudeMem-Potenciado.ps1',@('-GenerarInforme'),`$false)";$Reemplazo="    @('Analitica de calidad','Auditar-Analitica-Calidad-ClaudeMem.ps1',@(),`$false),`r`n$Objetivo";if(-not$Texto.Contains($Objetivo)){throw 'No se encontro punto seguro de integracion en orquestador.'};$Texto=$Texto.Replace($Objetivo,$Reemplazo)}
Write-Host 'Simulacion Fase 8A aprobada.'
if(-not$Aplicar){return}
$Root=Split-Path -Parent $PSScriptRoot;$B=Join-Path $Root '11_Herramientas\ClaudeMem\backups';New-Item -ItemType Directory -Path $B -Force|Out-Null;Copy-Item $Orq (Join-Path $B ("orquestador-pre-8A-{0}.ps1"-f(Get-Date -Format 'yyyyMMdd-HHmmss'))) -Force
foreach($X in $N){Copy-Item (Join-Path $RutaPaquete $X) (Join-Path $PSScriptRoot $X) -Force}
[IO.File]::WriteAllText($Orq,$Texto,[Text.UTF8Encoding]::new($true));Write-Host 'FASE 8A INSTALADA' -ForegroundColor Green
