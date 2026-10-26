#Requires -Version 5.1
# VERSION 1.0.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$SesionId,
    [switch]$Reemplazar
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'

function Leer-Lista([string]$Ruta){
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){return @()}
    $Raw=Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if([string]::IsNullOrWhiteSpace($Raw)){return @()}
    $X=ConvertFrom-Json -InputObject $Raw -ErrorAction Stop
    if($X-is[Array]){return @($X)}
    return @($X)
}
function Guardar-Lista([string]$Ruta,[array]$Datos){
    $Limpios=@($Datos|Where-Object{$null-ne$_ -and @($_.PSObject.Properties).Count-gt0})
    $Tmp="$Ruta.tmp";$Json=ConvertTo-Json -InputObject ([object[]]$Limpios) -Depth 40
    [IO.File]::WriteAllText($Tmp,$Json,[Text.UTF8Encoding]::new($true))
    $null=Get-Content -LiteralPath $Tmp -Raw|ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $Tmp -Destination $Ruta -Force
}
$Sesiones=Leer-Lista (Join-Path $CM 'episodios\sesiones.json')
$Sesion=@($Sesiones|Where-Object{$_.PSObject.Properties.Name-contains'sesionId' -and [string]$_.sesionId-eq$SesionId})
if($Sesion.Count-ne1){throw 'Sesion no encontrada o duplicada'}
$Eventos=@(Leer-Lista (Join-Path $CM 'episodios\eventos.json')|Where-Object{[string]$_.sesionId-eq$SesionId})
$Obs=@(Leer-Lista (Join-Path $CM 'episodios\observaciones.json')|Where-Object{[string]$_.sesionId-eq$SesionId})
$Bandejas=@('pendientes','aprobados','rechazados','duplicados');$Candidatos=@()
foreach($B in $Bandejas){$Candidatos+=@(Leer-Lista (Join-Path $CM "candidatos\$B.json")|Where-Object{[string]$_.sesionId-eq$SesionId}|ForEach-Object{$_|Add-Member NoteProperty bandeja $B -Force;$_})}
$Inicio=[datetime]::ParseExact([string]$Sesion[0].inicio,'yyyy-MM-dd HH:mm:ss',$null)
$Fin=$null;if(-not[string]::IsNullOrWhiteSpace([string]$Sesion[0].fin)){$Fin=[datetime]::ParseExact([string]$Sesion[0].fin,'yyyy-MM-dd HH:mm:ss',$null)}
$DuracionSegundos=$(if($null-ne$Fin){[int]($Fin-$Inicio).TotalSeconds}else{$null})
$Resumen=[pscustomobject][ordered]@{
 resumenId='RES-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');sesionId=$SesionId;objetivo=[string]$Sesion[0].objetivo;estadoSesion=[string]$Sesion[0].estado
 inicio=[string]$Sesion[0].inicio;fin=[string]$Sesion[0].fin;duracionSegundos=$DuracionSegundos
 cantidadEventos=$Eventos.Count;cantidadObservaciones=$Obs.Count;cantidadCandidatos=$Candidatos.Count
 tiposEvento=@($Eventos|Group-Object tipo|ForEach-Object{[pscustomobject]@{tipo=$_.Name;cantidad=$_.Count}})
 clasificaciones=@($Obs|Group-Object clasificacion|ForEach-Object{[pscustomobject]@{clasificacion=$_.Name;cantidad=$_.Count}})
 eventos=@($Eventos|Select-Object eventoId,tipo,contenido,fecha)
 observaciones=@($Obs|Select-Object observacionId,contenido,clasificacion,fecha,estado)
 candidatos=@($Candidatos|Select-Object candidatoId,tipoSugerido,contenido,estadoRevision,bandeja,fecha)
 generado=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';metodo='DETERMINISTA';version='1.0.0'
}
$RutaRes=Join-Path $CM 'episodios\resumenes.json';$Todos=Leer-Lista $RutaRes
$Existentes=@($Todos|Where-Object{[string]$_.sesionId-eq$SesionId})
if($Existentes.Count-gt0 -and -not$Reemplazar){throw 'Ya existe resumen para la sesion. Use -Reemplazar.'}
$Todos=@($Todos|Where-Object{[string]$_.sesionId-ne$SesionId});$Todos+=$Resumen;Guardar-Lista $RutaRes $Todos
$Resumen
