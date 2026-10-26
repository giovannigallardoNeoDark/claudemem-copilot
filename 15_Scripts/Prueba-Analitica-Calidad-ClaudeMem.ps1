#Requires -Version 5.1
# VERSION 1.0.0 - FASE 8A
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$A=Join-Path $PSScriptRoot 'Analizar-Calidad-ClaudeMem.ps1';$R=&$A -UltimosDias 30
$Campos=@('observacionesValidas','cuarentena','contextos','relevanciaPromedio','tasaContextosConResultados','tasaCuarentena','estado','recomendaciones');$P=@();foreach($C in $Campos){$P+=[pscustomobject]@{Estado=$(if($R.PSObject.Properties.Name-contains$C){'PASS'}else{'FAIL'});Prueba="Campo $C"}}
$P+=[pscustomobject]@{Estado=$(if([double]$R.relevanciaPromedio-ge0-and[double]$R.relevanciaPromedio-le5){'PASS'}else{'FAIL'});Prueba='Rango relevancia'}
$P+=[pscustomobject]@{Estado=$(if([double]$R.tasaCuarentena-ge0-and[double]$R.tasaCuarentena-le100){'PASS'}else{'FAIL'});Prueba='Rango porcentajes'}
$P|Format-Table -AutoSize;$F=@($P|Where-Object{$_.Estado-eq'FAIL'}).Count;Write-Host "Aprobadas: $($P.Count-$F) / $($P.Count)";if($F){exit 1}
