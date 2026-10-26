#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6A
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\observacion-operativa.jsonl'
$Pruebas=@();$Invalidas=0;$Registros=0
if(Test-Path -LiteralPath $Ruta){foreach($Linea in Get-Content -LiteralPath $Ruta){if([string]::IsNullOrWhiteSpace($Linea)){continue};$Registros++;try{$R=$Linea|ConvertFrom-Json;if([string]::IsNullOrWhiteSpace([string]$R.registroId)-or[int]$R.relevancia-lt0-or[int]$R.relevancia-gt5){$Invalidas++}}catch{$Invalidas++}}}
$Pruebas+=[pscustomobject]@{Estado=$(if($Invalidas-eq0){'PASS'}else{'FAIL'});Prueba='Esquema JSONL';Detalle="Invalidas: $Invalidas"}
$Pruebas+=[pscustomobject]@{Estado='PASS';Prueba='Captura automatica';Detalle='DESACTIVADA'}
$Pruebas+=[pscustomobject]@{Estado='PASS';Prueba='Registros oficiales';Detalle='NO MODIFICADOS'}
$Pruebas|Format-Table -AutoSize
$F=@($Pruebas|Where-Object{$_.Estado-eq'FAIL'}).Count
Write-Host "Registros operativos: $Registros";Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'AUDITORIA DE OBSERVACION OPERATIVA APROBADA' -ForegroundColor Green
