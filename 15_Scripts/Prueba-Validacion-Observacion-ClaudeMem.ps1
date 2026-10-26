#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6B
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop';$V=Join-Path $PSScriptRoot 'Validar-Observacion-Operativa-ClaudeMem.ps1';$R=@()
$A=&$V -Consulta 'consulta realizada' -Relevancia 4 -Resultado SIN_ERROR -Comentario 'ejemplo' -PaqueteId 'CTX-identificador'
$R+=[pscustomobject]@{Estado=$(if(-not$A.valido){'PASS'}else{'FAIL'});Prueba='Bloquea marcadores'}
$B=&$V -Consulta 'consulta inexistente' -Relevancia 4 -Resultado SIN_ERROR -PaqueteId 'CTX-NO-EXISTE'
$R+=[pscustomobject]@{Estado=$(if(-not$B.valido){'PASS'}else{'FAIL'});Prueba='Bloquea paquete inexistente'}
$C=&$V -Consulta 'fallo real de interfaz' -Relevancia 0 -Resultado ERROR_PANEL -Comentario 'La ventana no abrio.'
$R+=[pscustomobject]@{Estado=$(if($C.valido){'PASS'}else{'FAIL'});Prueba='Acepta error documentado'}
$D=&$V -Consulta 'sin resultados' -Relevancia 3 -Resultado SIN_RESULTADOS -Comentario 'sin datos'
$R+=[pscustomobject]@{Estado=$(if(-not$D.valido){'PASS'}else{'FAIL'});Prueba='Bloquea relevancia incoherente'}
$R|Format-Table -AutoSize;$Aprobadas=@($R|Where-Object{$_.Estado-eq'PASS'}).Count;Write-Host "Aprobadas: $Aprobadas / $($R.Count)";if($Aprobadas-ne$R.Count){exit 1}
