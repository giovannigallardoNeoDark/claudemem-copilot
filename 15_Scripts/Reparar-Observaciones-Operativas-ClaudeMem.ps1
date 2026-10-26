#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6B
[CmdletBinding()]param([switch]$Aplicar)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\observacion-operativa.jsonl';$Cuarentena=Join-Path $CM 'episodios\observacion-operativa-cuarentena.jsonl';$Backups=Join-Path $CM 'backups'
$Validador=Join-Path $PSScriptRoot 'Validar-Observacion-Operativa-ClaudeMem.ps1'
$Validos=@();$Invalidos=@();$LineasInvalidas=@()
if(Test-Path -LiteralPath $Ruta){
 foreach($Linea in Get-Content -LiteralPath $Ruta){if([string]::IsNullOrWhiteSpace($Linea)){continue};try{$R=$Linea|ConvertFrom-Json -ErrorAction Stop;$V=&$Validador -Consulta ([string]$R.consulta) -Relevancia ([int]$R.relevancia) -Resultado ([string]$R.resultado) -Comentario ([string]$R.comentario) -PaqueteId ([string]$R.paqueteId) -PermitirDuplicado;if($V.valido){$Validos+=$R}else{$Invalidos+=[pscustomobject]@{registro=$R;motivos=$V.motivos}}}catch{$LineasInvalidas+=$Linea}}
}
[pscustomobject]@{validos=$Validos.Count;inconsistentes=$Invalidos.Count;lineasInvalidas=$LineasInvalidas.Count;aplicar=[bool]$Aplicar}|Format-List
if(-not$Aplicar){return}
New-Item -ItemType Directory -Path $Backups -Force|Out-Null;$Sello=Get-Date -Format 'yyyyMMdd-HHmmss';if(Test-Path $Ruta){Copy-Item $Ruta (Join-Path $Backups "observacion-operativa-pre-reparacion-$Sello.jsonl") -Force}
foreach($I in $Invalidos){$Q=[pscustomobject]@{cuarentenaId='CUA-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';motivos=$I.motivos;registro=$I.registro;accion='REVISAR';version='1.0.0'};Add-Content $Cuarentena ($Q|ConvertTo-Json -Depth 10 -Compress) -Encoding UTF8}
foreach($L in $LineasInvalidas){$Q=[pscustomobject]@{cuarentenaId='CUA-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';motivos=@('JSON_INVALIDO');linea=$L;accion='REVISAR';version='1.0.0'};Add-Content $Cuarentena ($Q|ConvertTo-Json -Depth 10 -Compress) -Encoding UTF8}
$Tmp="$Ruta.tmp";$Salidas=@($Validos|ForEach-Object{$_|ConvertTo-Json -Compress});[IO.File]::WriteAllLines($Tmp,[string[]]$Salidas,[Text.UTF8Encoding]::new($true));foreach($L in Get-Content $Tmp){if($L){$null=$L|ConvertFrom-Json -ErrorAction Stop}};Move-Item $Tmp $Ruta -Force
Write-Host "Reparacion aplicada. Validos: $($Validos.Count); Cuarentena: $($Invalidos.Count+$LineasInvalidas.Count)" -ForegroundColor Green
