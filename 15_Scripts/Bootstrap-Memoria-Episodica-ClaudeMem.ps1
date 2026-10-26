#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Inicializar,[switch]$Auditar)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Folders=@('episodios','candidatos','schemas','config','reports','logs','backups')
$Stores=@{
 'episodios\sesiones.json'=@();'episodios\eventos.json'=@();'episodios\observaciones.json'=@();'episodios\resumenes.json'=@();
 'candidatos\pendientes.json'=@();'candidatos\aprobados.json'=@();'candidatos\rechazados.json'=@();'candidatos\duplicados.json'=@()
}
function SaveJson([string]$Path,[object]$Data){$tmp="$Path.tmp";[IO.File]::WriteAllText($tmp,($Data|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($true));$null=Get-Content $tmp -Raw|ConvertFrom-Json;Move-Item $tmp $Path -Force}
function EnsureJson([string]$Rel,[object]$Default){$p=Join-Path $CM $Rel;if(!(Test-Path $p)){SaveJson $p $Default}}
if($Inicializar){
 foreach($f in $Folders){New-Item -ItemType Directory -Path (Join-Path $CM $f) -Force|Out-Null}
 foreach($k in $Stores.Keys){EnsureJson $k $Stores[$k]}
 $pol=[ordered]@{version='1.0';capturaAutomatica=$false;requiereAprobacion=$true;clasificacionPredeterminada='INTERNO';excluirSecretos=$true;estados=@('PUBLICO','INTERNO','CONFIDENCIAL','RESTRINGIDO','NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')}
 EnsureJson 'config\politicas-captura.json' $pol
 EnsureJson 'config\rutas-excluidas.json' @('*.key','*.pem','*.pfx','.env','secrets.*','credentials.*','*\papelera\*','*\backups\*')
 EnsureJson 'config\clasificacion-informacion.json' ([ordered]@{PUBLICO=0;INTERNO=1;CONFIDENCIAL=2;RESTRINGIDO=3;NO_CAPTURAR=9})
 EnsureJson 'config\patrones-secretos.json' @('password','passwd','token','api[_-]?key','secret','authorization:\s*bearer')
 Write-Host 'Memoria episodica inicializada.' -ForegroundColor Green
}
$req=@($Stores.Keys)+@('config\politicas-captura.json','config\rutas-excluidas.json','config\clasificacion-informacion.json','config\patrones-secretos.json')
$r=@();foreach($x in $req){$p=Join-Path $CM $x;$ok=Test-Path $p;try{if($ok){$null=Get-Content $p -Raw|ConvertFrom-Json}}catch{$ok=$false};$r+=[pscustomobject]@{Estado=$(if($ok){'PASS'}else{'FAIL'});Elemento=$x}}
$r|Format-Table -AutoSize
$pass=@($r|Where-Object Estado -eq 'PASS').Count;Write-Host "Aprobadas: $pass / $($r.Count)";if($pass-ne$r.Count){exit 1}
