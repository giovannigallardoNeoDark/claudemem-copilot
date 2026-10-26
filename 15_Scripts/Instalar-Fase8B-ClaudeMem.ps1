#Requires -Version 5.1
# VERSION 1.0.0 - FASE 8B
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$RutaPaquete,[switch]$Aplicar)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$N=@('Cierre-Madurez-Operativa-ClaudeMem.ps1','Prueba-Cierre-Madurez-ClaudeMem.ps1');$P=(Resolve-Path -LiteralPath $RutaPaquete).Path
foreach($X in $N){$O=Join-Path $P $X;if(-not(Test-Path $O)){throw "Falta $X"};$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($O,[ref]$T,[ref]$E);if(@($E).Count){throw "Sintaxis invalida: $X"}}
$Orq=Join-Path $PSScriptRoot 'Ejecutar-Ciclo-Automatico-ClaudeMem.ps1';$Texto=Get-Content $Orq -Raw;$Etapa="    @('Cierre madurez operativa','Prueba-Cierre-Madurez-ClaudeMem.ps1',@(),`$false),";$Punto="    @('Diagnostico general','Diagnosticar-ClaudeMem-Potenciado.ps1',@('-GenerarInforme'),`$false)";$Integrar=$Texto-notmatch[regex]::Escape("@('Cierre madurez operativa'");if($Integrar){if(-not$Texto.Contains($Punto)){throw 'No existe punto seguro de integracion.'};$Texto=$Texto.Replace($Punto,"$Etapa`r`n$Punto")}
$Plan=@();foreach($X in $N){$O=Join-Path $P $X;$D=Join-Path $PSScriptRoot $X;$Igual=[string]::Equals([IO.Path]::GetFullPath($O),[IO.Path]::GetFullPath($D),[StringComparison]::OrdinalIgnoreCase);$Plan+=[pscustomobject]@{componente=$X;accion=$(if($Igual){'CONSERVAR_Y_VALIDAR'}else{'COPIAR'})}}
$Plan|Format-Table -AutoSize;Write-Host "Integrar etapa 8B: $Integrar";Write-Host 'SIMULACION FASE 8B APROBADA' -ForegroundColor Yellow;if(-not$Aplicar){return}
$Root=Split-Path -Parent $PSScriptRoot;$B=Join-Path $Root '11_Herramientas\ClaudeMem\backups';New-Item -ItemType Directory -Path $B -Force|Out-Null;$S=Get-Date -Format 'yyyyMMdd-HHmmss';$BO=Join-Path $B "orquestador-pre-8B-$S.ps1";Copy-Item $Orq $BO -Force
foreach($X in $N){$O=Join-Path $P $X;$D=Join-Path $PSScriptRoot $X;if(-not[string]::Equals([IO.Path]::GetFullPath($O),[IO.Path]::GetFullPath($D),[StringComparison]::OrdinalIgnoreCase)){Copy-Item $O $D -Force}}
if($Integrar){[IO.File]::WriteAllText($Orq,$Texto,[Text.UTF8Encoding]::new($true))}
$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($Orq,[ref]$T,[ref]$E);if(@($E).Count){Copy-Item $BO $Orq -Force;throw 'Fallo confirmacion. Orquestador restaurado.'};Write-Host 'FASE 8B INSTALADA Y CONFIRMADA' -ForegroundColor Green
