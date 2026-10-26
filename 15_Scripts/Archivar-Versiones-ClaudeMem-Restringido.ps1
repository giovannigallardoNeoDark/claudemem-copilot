#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5B
[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$Aplicar)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$CopilotRoot=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$Manifiesto=Join-Path $CM 'config\manifiesto-componentes.json'
if(-not(Test-Path -LiteralPath $Manifiesto -PathType Leaf)){throw 'Falta manifiesto de componentes.'}
$M=Get-Content -LiteralPath $Manifiesto -Raw|ConvertFrom-Json
$Activos=@($M.componentes|Where-Object{$_.existe}|Select-Object -ExpandProperty nombre)
$Excluidos=@('Bootstrap-Syntec','Versionar-ClaudeMem','Gestionar-Papelera-ClaudeMem','Auditar-Relaciones-ClaudeMem','Buscar-ClaudeMem-Avanzado')
$Plan=@()
foreach($A in Get-ChildItem -LiteralPath $PSScriptRoot -File -Filter '*-v*.ps1'){
    if($A.BaseName -notmatch '^(.*)-v\d+(?:\.\d+)*$'){continue}
    $Base=$Matches[1]
    if($Base-in$Excluidos){continue}
    $Activo="$Base.ps1"
    if($Activo-notin$Activos){continue}
    if(-not(Test-Path -LiteralPath (Join-Path $PSScriptRoot $Activo))){continue}
    $Plan+=[pscustomobject]@{historico=$A.Name;activo=$Activo;origen=$A.FullName;destino=(Join-Path (Join-Path $PSScriptRoot 'historico') $A.Name)}
}
$Plan|Select-Object historico,activo|Format-Table -AutoSize
Write-Host "Candidatos controlados: $($Plan.Count)"
if(-not$Aplicar){Write-Host 'SIMULACION: no se movio ningun archivo.' -ForegroundColor Yellow;return}
$Backup=Join-Path (Join-Path $CM 'backups') ("archivado-controlado-{0}"-f(Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $Backup -Force|Out-Null
$Historico=Join-Path $PSScriptRoot 'historico';New-Item -ItemType Directory -Path $Historico -Force|Out-Null
foreach($P in $Plan){Copy-Item -LiteralPath $P.origen -Destination $Backup -Force;if($PSCmdlet.ShouldProcess($P.origen,'Archivar version')){Move-Item -LiteralPath $P.origen -Destination $P.destino -Force}}
Write-Host "Backup: $Backup";Write-Host "Archivados: $($Plan.Count)" -ForegroundColor Green
