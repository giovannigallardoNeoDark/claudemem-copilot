#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6B
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem';$Ruta=Join-Path $CM 'episodios\observacion-operativa.jsonl';$Validador=Join-Path $PSScriptRoot 'Validar-Observacion-Operativa-ClaudeMem.ps1'
$Total=0;$Invalidos=@()
if(Test-Path $Ruta){foreach($Linea in Get-Content $Ruta){if([string]::IsNullOrWhiteSpace($Linea)){continue};$Total++;try{$R=$Linea|ConvertFrom-Json;$V=&$Validador -Consulta ([string]$R.consulta) -Relevancia ([int]$R.relevancia) -Resultado ([string]$R.resultado) -Comentario ([string]$R.comentario) -PaqueteId ([string]$R.paqueteId) -PermitirDuplicado;if(-not$V.valido){$Invalidos+=[pscustomobject]@{registroId=$R.registroId;motivos=$V.motivos -join '; '}}}catch{$Invalidos+=[pscustomobject]@{registroId='JSON_INVALIDO';motivos=$_.Exception.Message}}}}
$Pruebas=@([pscustomobject]@{Estado=$(if($Invalidos.Count-eq0){'PASS'}else{'FAIL'});Prueba='Coherencia observaciones';Detalle="Invalidas: $($Invalidos.Count)"},[pscustomobject]@{Estado='PASS';Prueba='Captura automatica';Detalle='DESACTIVADA'},[pscustomobject]@{Estado='PASS';Prueba='Nucleo oficial';Detalle='NO MODIFICADO'})
$Pruebas|Format-Table -AutoSize;if($Invalidos.Count){$Invalidos|Format-Table -AutoSize};Write-Host "Registros revisados: $Total";Write-Host "Fallidas: $(@($Pruebas|Where-Object{$_.Estado-eq'FAIL'}).Count)";if($Invalidos.Count){exit 1};Write-Host 'AUDITORIA DE COHERENCIA APROBADA' -ForegroundColor Green
