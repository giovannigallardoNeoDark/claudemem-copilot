#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5B
[CmdletBinding()]param([switch]$ComoJson)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Manifiesto=Join-Path $CM 'config\manifiesto-componentes.json';$M=$(if(Test-Path $Manifiesto){Get-Content $Manifiesto -Raw|ConvertFrom-Json}else{$null})
$Faltantes=$(if($null-ne$M){@($M.componentes|Where-Object{$_.obligatorio-and-not$_.existe}).Count}else{-1})
$Diagnostico=@(Get-ChildItem (Join-Path $CM 'diagnosticos') -File -Filter 'diagnostico-*.json' -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1)
$Backup=@(Get-ChildItem (Join-Path $CM 'backups') -Directory -ErrorAction SilentlyContinue|Sort-Object LastWriteTime -Descending|Select-Object -First 1)
$Contexto=Join-Path $CM 'episodios\contextos-usados.jsonl';$Ultimo='';if(Test-Path $Contexto){$Ultimo=Get-Content $Contexto -Tail 1}
$Estado=[pscustomobject][ordered]@{producto='ClaudeMem Potenciado';fase='5B';componentesObligatoriosFaltantes=$Faltantes;ultimoDiagnostico=$(if($Diagnostico.Count){$Diagnostico[0].FullName}else{''});ultimoBackup=$(if($Backup.Count){$Backup[0].FullName}else{''});ultimoContexto=$Ultimo;capturaAutomatica='DESACTIVADA';lanzadorVisible=(Test-Path (Join-Path $Root 'Iniciar-ClaudeMem-Copilot.cmd'));resultadoGlobal=$(if($Faltantes-eq0){'OPERATIVO'}else{'REVISAR'})}
if($ComoJson){$Estado|ConvertTo-Json -Depth 5}else{$Estado|Format-List}
