#Requires -Version 5.1
# VERSION 1.1.0 - FASE 8B
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Script=Join-Path $PSScriptRoot 'Cierre-Madurez-Operativa-ClaudeMem.ps1'
$Salida=@(& $Script -UltimosDias 30 -MinimoObservaciones 10)
$R=@($Salida|Where-Object{$null-ne$_ -and $_.PSObject.Properties.Name-contains'fase' -and $_.fase-eq'8B'})|Select-Object -Last 1
if($null-eq$R){throw 'No se recibio el resultado estructurado de la Fase 8B.'}
$Pruebas=@(
 [pscustomobject]@{Estado=$(if($R.estado-in@('EN_OBSERVACION','CIERRE_APROBADO','MEJORA_REQUERIDA')){'PASS'}else{'FAIL'});Prueba='Estado controlado'},
 [pscustomobject]@{Estado=$(if([int]$R.calidad.lineasInvalidas-eq0){'PASS'}else{'FAIL'});Prueba='JSONL valido'},
 [pscustomobject]@{Estado=$(if([int]$R.calidad.duplicadosAceptados-eq0){'PASS'}else{'FAIL'});Prueba='Sin duplicados'},
 [pscustomobject]@{Estado=$(if([int]$R.avance-in@(99,100)){'PASS'}else{'FAIL'});Prueba='Avance calculado'}
)
$Pruebas|Format-Table -AutoSize
$F=@($Pruebas|Where-Object{$_.Estado-eq'FAIL'}).Count
Write-Host "Aprobadas: $($Pruebas.Count-$F) / $($Pruebas.Count)"
if($F){exit 1}
Write-Host "PRUEBA FASE 8B APROBADA | Estado: $($R.estado) | Avance: $($R.avance) %" -ForegroundColor Green
