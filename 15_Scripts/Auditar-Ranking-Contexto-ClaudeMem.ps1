#Requires -Version 5.1
# VERSION 1.0.0
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$P=Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1'
$C=&$P -Consulta 'ClaudeMem memoria integracion' -Nivel 2 -MaxCaracteres 5000
$Pruebas=@()
$Prohibidos=@($C.elementos|Where-Object{$_.clasificacion-in@('NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')})
$Pruebas+=[pscustomobject]@{Estado=$(if($Prohibidos.Count-eq0){'PASS'}else{'FAIL'});Prueba='Exclusiones';Detalle=$Prohibidos.Count}
$SinTraza=@($C.elementos|Where-Object{[string]::IsNullOrWhiteSpace([string]$_.id)-or[string]::IsNullOrWhiteSpace([string]$_.fuente)})
$Pruebas+=[pscustomobject]@{Estado=$(if($SinTraza.Count-eq0){'PASS'}else{'FAIL'});Prueba='Trazabilidad';Detalle=$SinTraza.Count}
$Duplicados=@($C.elementos.id|Group-Object|Where-Object{$_.Count-gt1})
$Pruebas+=[pscustomobject]@{Estado=$(if($Duplicados.Count-eq0){'PASS'}else{'FAIL'});Prueba='Deduplicacion';Detalle=$Duplicados.Count}
$OrdenValido=$true;for($I=1;$I-lt$C.elementos.Count;$I++){if([double]$C.elementos[$I].puntaje-gt[double]$C.elementos[$I-1].puntaje){$OrdenValido=$false}}
$Pruebas+=[pscustomobject]@{Estado=$(if($OrdenValido){'PASS'}else{'FAIL'});Prueba='Orden de puntaje';Detalle=$OrdenValido}
$Pruebas+=[pscustomobject]@{Estado=$(if($C.caracteresUsados-le$C.maxCaracteres){'PASS'}else{'FAIL'});Prueba='Presupuesto';Detalle="$($C.caracteresUsados)/$($C.maxCaracteres)"}
$Pruebas|Format-Table -AutoSize;$F=@($Pruebas|Where-Object{[string]$_.Estado-eq'FAIL'}).Count;Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'AUDITORIA DE RANKING APROBADA' -ForegroundColor Green
