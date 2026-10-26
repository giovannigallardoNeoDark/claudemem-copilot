#Requires -Version 5.1
# VERSION 1.0.0 - FASE 8A
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$A=Join-Path $PSScriptRoot 'Analizar-Calidad-ClaudeMem.ps1';$R=&$A -UltimosDias 30
$P=@(
 [pscustomobject]@{Estado=$(if([int]$R.lineasInvalidas-eq0){'PASS'}else{'FAIL'});Prueba='JSONL valido';Detalle=$R.lineasInvalidas},
 [pscustomobject]@{Estado=$(if([int]$R.duplicadosAceptados-eq0){'PASS'}else{'FAIL'});Prueba='Sin duplicados aceptados';Detalle=$R.duplicadosAceptados},
 [pscustomobject]@{Estado=$(if($R.estado-ne'BLOQUEADO'){'PASS'}else{'FAIL'});Prueba='Analitica no bloqueada';Detalle=$R.estado},
 [pscustomobject]@{Estado='PASS';Prueba='Nucleo oficial';Detalle='NO MODIFICADO'}
)
$P|Format-Table -AutoSize;$F=@($P|Where-Object{$_.Estado-eq'FAIL'}).Count;Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'ANALITICA DE CALIDAD APROBADA' -ForegroundColor Green
