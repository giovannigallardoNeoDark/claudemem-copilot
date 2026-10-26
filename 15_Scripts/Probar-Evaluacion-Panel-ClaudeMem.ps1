#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6C
[CmdletBinding()]
param([switch]$AbrirPanel)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Obs=Join-Path $CM 'episodios\observacion-operativa.jsonl'
$Ctx=Join-Path $CM 'episodios\contextos-usados.jsonl'
$Lanzador=Join-Path $Root 'Iniciar-ClaudeMem-Copilot.cmd'
function UltimoJson([string]$Ruta){
 if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){return $null}
 $Linea=Get-Content -LiteralPath $Ruta -Tail 1
 if([string]::IsNullOrWhiteSpace($Linea)){return $null}
 return ($Linea|ConvertFrom-Json -ErrorAction Stop)
}
$Antes=UltimoJson $Obs
$IdAntes=$(if($null-ne$Antes){[string]$Antes.registroId}else{''})
Write-Host "Registro anterior: $IdAntes"
if($AbrirPanel){
 if(-not(Test-Path -LiteralPath $Lanzador -PathType Leaf)){throw "No existe: $Lanzador"}
 Write-Host 'Use una consulta nueva, genere contexto, registre la evaluacion y cierre el panel.' -ForegroundColor Cyan
 $Proceso=Start-Process -FilePath $Lanzador -PassThru
 $Proceso.WaitForExit()
}
$Despues=UltimoJson $Obs
$IdDespues=$(if($null-ne$Despues){[string]$Despues.registroId}else{''})
$Nuevo=(-not[string]::IsNullOrWhiteSpace($IdDespues))-and($IdDespues-ne$IdAntes)
$Paquete=$null
if($Nuevo-and-not[string]::IsNullOrWhiteSpace([string]$Despues.paqueteId)-and(Test-Path $Ctx)){
 foreach($Linea in Get-Content -LiteralPath $Ctx){if([string]::IsNullOrWhiteSpace($Linea)){continue};try{$C=$Linea|ConvertFrom-Json;if([string]$C.paqueteId-eq[string]$Despues.paqueteId){$Paquete=$C;break}}catch{}}
}
$ConsultaCoincide=($null-ne$Paquete-and([string]$Paquete.consulta-eq[string]$Despues.consulta))
$Resultado=[pscustomobject][ordered]@{
 registroAnterior=$IdAntes;registroNuevo=$IdDespues;evaluacionCreadaDesdePanel=$Nuevo
 paqueteId=$(if($Nuevo){[string]$Despues.paqueteId}else{' '})
 paqueteExiste=($null-ne$Paquete);consultaCoincide=$ConsultaCoincide
 resultados=$(if($null-ne$Paquete){[int]$Paquete.resultados}else{$null})
 estado=$(if($Nuevo-and$null-ne$Paquete-and$ConsultaCoincide){'PASS'}else{'PENDIENTE'})
}
$Resultado|Format-List
if($Resultado.estado-ne'PASS'){exit 1}
Write-Host 'PRUEBA FUNCIONAL DEL PANEL APROBADA' -ForegroundColor Green
