#Requires -Version 5.1
# VERSION 1.1.0
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Preparador=Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1'
$R=&$Preparador -Consulta 'memoria copilot integracion' -MaxCaracteres 3000 -Nivel 2
$Pruebas=@()
$Pruebas+=[pscustomobject]@{Estado=$(if($R.caracteresUsados-le$R.maxCaracteres){'PASS'}else{'FAIL'});Prueba='Presupuesto';Detalle="$($R.caracteresUsados)/$($R.maxCaracteres)"}
$Prohibidos=@($R.elementos|Where-Object{$_.clasificacion-in@('NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')});$Pruebas+=[pscustomobject]@{Estado=$(if($Prohibidos.Count-eq0){'PASS'}else{'FAIL'});Prueba='Exclusiones';Detalle=$Prohibidos.Count}
$SinFuente=@($R.elementos|Where-Object{[string]::IsNullOrWhiteSpace([string]$_.fuente)-or[string]::IsNullOrWhiteSpace([string]$_.id)});$Pruebas+=[pscustomobject]@{Estado=$(if($SinFuente.Count-eq0){'PASS'}else{'FAIL'});Prueba='Trazabilidad';Detalle=$SinFuente.Count}
$Pruebas|Format-Table -AutoSize;$F=@($Pruebas | Where-Object { [string]$_.Estado -eq 'FAIL' }).Count;Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'AUDITORIA DE CONTEXTO APROBADA' -ForegroundColor Green
