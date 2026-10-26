#Requires -Version 5.1
# VERSION 1.1.0
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ses=Get-Content (Join-Path $CM 'episodios\sesiones.json') -Raw|ConvertFrom-Json
$Id=[string](@($Ses|Sort-Object inicio -Descending|Select-Object -First 1)[0].sesionId)
$Resumen=&(Join-Path $PSScriptRoot 'Generar-Resumen-Sesion-ClaudeMem.ps1') -SesionId $Id -Reemplazar
$Contexto=&(Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1') -Consulta ([string]$Resumen.objetivo) -MaxCaracteres 4000 -Nivel 2
$R=@();$R+=[pscustomobject]@{Estado=$(if($Resumen.sesionId-eq$Id){'PASS'}else{'FAIL'});Prueba='Resumen generado'};$R+=[pscustomobject]@{Estado=$(if($Contexto.caracteresUsados-le4000){'PASS'}else{'FAIL'});Prueba='Presupuesto contexto'};$R+=[pscustomobject]@{Estado=$(if($Contexto.resultados-gt0){'PASS'}else{'FAIL'});Prueba='Recuperacion relacionada'}
$R|Format-Table -AutoSize;$P=@($R | Where-Object { [string]$_.Estado -eq 'PASS' }).Count;Write-Host "Aprobadas: $P / $($R.Count)";if($P-ne$R.Count){exit 1}
