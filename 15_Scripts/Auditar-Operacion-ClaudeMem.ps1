#Requires -Version 5.1
# VERSION 1.0.0 - FASE 4B
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Pruebas=@()
$Dependencias=@('Invocar-ClaudeMem-Copilot.ps1','Preparar-Contexto-Copilot.ps1','Convertir-Registro-Contexto-Legible.ps1','Gestionar-Historial-Contextos-ClaudeMem.ps1')
foreach($Nombre in $Dependencias){$Existe=Test-Path -LiteralPath (Join-Path $PSScriptRoot $Nombre) -PathType Leaf;$Pruebas+=[pscustomobject]@{Estado=$(if($Existe){'PASS'}else{'FAIL'});Prueba="Dependencia $Nombre";Detalle=$Existe}}
$Puerta=Join-Path $PSScriptRoot 'Invocar-ClaudeMem-Copilot.ps1'
if(Test-Path -LiteralPath $Puerta){$R=&$Puerta -Consulta 'ClaudeMem memoria integracion Copilot' -Nivel 2 -MaxCaracteres 4000 -OmitirAuditoriaPrevia;$Pruebas+=[pscustomobject]@{Estado=$(if($R.resultados-gt0){'PASS'}else{'FAIL'});Prueba='Invocacion operativa';Detalle=$R.resultados};$Pruebas+=[pscustomobject]@{Estado=$(if($R.caracteresUsados-le4000){'PASS'}else{'FAIL'});Prueba='Presupuesto';Detalle="$($R.caracteresUsados)/4000"};$Pruebas+=[pscustomobject]@{Estado=$(if(-not($R.markdown-match'(?m)^\s*\{"')){'PASS'}else{'FAIL'});Prueba='Salida legible';Detalle='Sin JSON embebido'}}
$Pruebas|Format-Table -AutoSize
$F=@($Pruebas|Where-Object{[string]$_.Estado-eq'FAIL'}).Count
Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'AUDITORIA OPERATIVA APROBADA' -ForegroundColor Green
