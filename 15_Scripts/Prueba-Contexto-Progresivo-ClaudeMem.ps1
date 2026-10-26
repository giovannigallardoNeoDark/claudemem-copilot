#Requires -Version 5.1
# VERSION 1.0.0
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$P=Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1';$R=@()
$N1=&$P -Consulta 'ClaudeMem memoria integracion' -Nivel 1 -MaxCaracteres 2500
$N2=&$P -Consulta 'ClaudeMem memoria integracion' -Nivel 2 -MaxCaracteres 4000
$N3=&$P -Consulta 'ClaudeMem memoria integracion' -Nivel 3 -MaxCaracteres 7000
$R+=[pscustomobject]@{Estado=$(if($N1.caracteresUsados-le2500){'PASS'}else{'FAIL'});Prueba='Nivel 1 presupuesto'}
$R+=[pscustomobject]@{Estado=$(if($N2.caracteresUsados-le4000){'PASS'}else{'FAIL'});Prueba='Nivel 2 presupuesto'}
$R+=[pscustomobject]@{Estado=$(if($N3.caracteresUsados-le7000){'PASS'}else{'FAIL'});Prueba='Nivel 3 presupuesto'}
$R+=[pscustomobject]@{Estado=$(if($N1.resultados-gt0-and$N2.resultados-gt0-and$N3.resultados-gt0){'PASS'}else{'FAIL'});Prueba='Recuperacion en 3 niveles'}
$R|Format-Table -AutoSize;$Pasa=@($R|Where-Object{[string]$_.Estado-eq'PASS'}).Count;Write-Host "Aprobadas: $Pasa / $($R.Count)";if($Pasa-ne$R.Count){exit 1}
