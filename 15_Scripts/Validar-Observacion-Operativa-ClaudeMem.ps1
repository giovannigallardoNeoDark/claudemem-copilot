#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6B
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Consulta,
    [ValidateRange(0,5)][int]$Relevancia,
    [ValidateSet('SIN_ERROR','ERROR_PANEL','SIN_RESULTADOS','POCO_RELEVANTE','FALSO_POSITIVO_SEGURIDAD','OTRO')][string]$Resultado,
    [string]$Comentario='',
    [string]$PaqueteId='',
    [switch]$PermitirDuplicado
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$RutaContextos=Join-Path $CM 'episodios\contextos-usados.jsonl'
$RutaObservaciones=Join-Path $CM 'episodios\observacion-operativa.jsonl'
$Motivos=@()
$ConsultaNormalizada=$Consulta.Trim()
$ComentarioNormalizado=$Comentario.Trim()
$Marcadores=@(
 'consulta realizada','consulta real ejecutada','consulta concreta que necesitas resolver',
 'consulta que se desea resolver','ctx-identificador','ctx-identificador-real',
 'copiar el mensaje','describir que contenido','describir qué contenido',
 'indicar concretamente','evaluacion concreta','evaluación concreta'
)
foreach($Marcador in $Marcadores){
 if($ConsultaNormalizada.ToLowerInvariant().Contains($Marcador)-or$ComentarioNormalizado.ToLowerInvariant().Contains($Marcador)-or$PaqueteId.ToLowerInvariant().Contains($Marcador)){$Motivos+="MARCADOR_DE_EJEMPLO: $Marcador"}
}
$Contexto=$null
if(-not[string]::IsNullOrWhiteSpace($PaqueteId)){
 if(Test-Path -LiteralPath $RutaContextos){
  foreach($Linea in Get-Content -LiteralPath $RutaContextos){
   if([string]::IsNullOrWhiteSpace($Linea)){continue}
   try{$C=$Linea|ConvertFrom-Json -ErrorAction Stop;if([string]$C.paqueteId-eq$PaqueteId){$Contexto=$C;break}}catch{}
  }
 }
 if($null-eq$Contexto){$Motivos+='PAQUETE_INEXISTENTE'}
 else{
  if(([string]$Contexto.consulta).Trim()-ne$ConsultaNormalizada){$Motivos+='CONSULTA_NO_COINCIDE_CON_PAQUETE'}
  $Cantidad=[int]$Contexto.resultados
  if($Cantidad-eq0-and$Resultado-ne'SIN_RESULTADOS'){$Motivos+='CERO_RESULTADOS_REQUIERE_SIN_RESULTADOS'}
  if($Cantidad-gt0-and$Resultado-eq'SIN_RESULTADOS'){$Motivos+='SIN_RESULTADOS_INCONSISTENTE_CON_PAQUETE'}
 }
}elseif($Resultado-in@('SIN_ERROR','SIN_RESULTADOS','POCO_RELEVANTE')){$Motivos+='PAQUETE_REQUERIDO_PARA_EVALUACION_DE_CONTEXTO'}
if($Resultado-eq'SIN_RESULTADOS'-and$Relevancia-ne0){$Motivos+='SIN_RESULTADOS_REQUIERE_RELEVANCIA_0'}
if($Resultado-eq'SIN_ERROR'-and$Relevancia-lt3){$Motivos+='SIN_ERROR_REQUIERE_RELEVANCIA_3_A_5'}
if($Resultado-eq'POCO_RELEVANTE'-and$Relevancia-gt2){$Motivos+='POCO_RELEVANTE_REQUIERE_RELEVANCIA_0_A_2'}
if($Resultado-in@('ERROR_PANEL','FALSO_POSITIVO_SEGURIDAD','OTRO')-and[string]::IsNullOrWhiteSpace($ComentarioNormalizado)){$Motivos+='COMENTARIO_OBLIGATORIO'}
if(-not$PermitirDuplicado-and-not[string]::IsNullOrWhiteSpace($PaqueteId)-and(Test-Path -LiteralPath $RutaObservaciones)){
 foreach($Linea in Get-Content -LiteralPath $RutaObservaciones){if([string]::IsNullOrWhiteSpace($Linea)){continue};try{$O=$Linea|ConvertFrom-Json;if([string]$O.paqueteId-eq$PaqueteId){$Motivos+='PAQUETE_YA_EVALUADO';break}}catch{}}
}
[pscustomobject][ordered]@{valido=($Motivos.Count-eq0);motivos=@($Motivos|Sort-Object -Unique);consulta=$ConsultaNormalizada;paqueteId=$PaqueteId;resultado=$Resultado;relevancia=$Relevancia;resultadosPaquete=$(if($null-ne$Contexto){[int]$Contexto.resultados}else{$null});version='1.0.0'}
