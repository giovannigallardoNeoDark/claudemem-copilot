#Requires -Version 5.1
# VERSION 2.0.0 - FASE 6B
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Consulta,
 [ValidateRange(0,5)][int]$Relevancia,
 [ValidateRange(0,86400)][int]$TiempoSegundos=0,
 [ValidateSet('SIN_ERROR','ERROR_PANEL','SIN_RESULTADOS','POCO_RELEVANTE','FALSO_POSITIVO_SEGURIDAD','OTRO')][string]$Resultado='SIN_ERROR',
 [string]$Comentario='',[string]$PaqueteId='',[switch]$PermitirDuplicado
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Validador=Join-Path $PSScriptRoot 'Validar-Observacion-Operativa-ClaudeMem.ps1'
if(-not(Test-Path -LiteralPath $Validador -PathType Leaf)){throw "Falta validador: $Validador"}
$Parametros=@{Consulta=$Consulta;Relevancia=$Relevancia;Resultado=$Resultado;Comentario=$Comentario;PaqueteId=$PaqueteId};if($PermitirDuplicado){$Parametros.PermitirDuplicado=$true}
$Validacion=&$Validador @Parametros
$Registro=[pscustomobject][ordered]@{registroId='OPE-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';consulta=$Consulta.Trim();paqueteId=$PaqueteId;relevancia=$Relevancia;tiempoSegundos=$TiempoSegundos;resultado=$Resultado;comentario=$Comentario.Trim();version='2.0.0'}
if(-not$Validacion.valido){
 $RutaCuarentena=Join-Path $CM 'episodios\observacion-operativa-cuarentena.jsonl'
 $Rechazo=[pscustomobject][ordered]@{cuarentenaId='CUA-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';motivos=$Validacion.motivos;registro=$Registro;accion='CORREGIR_Y_REINTENTAR';version='1.0.0'}
 Add-Content -LiteralPath $RutaCuarentena -Value ($Rechazo|ConvertTo-Json -Depth 10 -Compress) -Encoding UTF8
 Write-Error "Observacion enviada a cuarentena: $($Validacion.motivos -join '; ')" -ErrorAction Continue
 return [pscustomobject]@{estado='CUARENTENA';registroId=$Registro.registroId;motivos=$Validacion.motivos}
}
$Ruta=Join-Path $CM 'episodios\observacion-operativa.jsonl';Add-Content -LiteralPath $Ruta -Value ($Registro|ConvertTo-Json -Compress) -Encoding UTF8
[pscustomobject]@{estado='ACEPTADA';registro=$Registro}
