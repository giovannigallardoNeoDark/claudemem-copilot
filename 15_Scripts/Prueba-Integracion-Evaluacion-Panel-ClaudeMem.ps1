#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6C
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Panel=Join-Path $PSScriptRoot 'ClaudeMem-Copilot-Panel.ps1';$R=@();$Texto=Get-Content $Panel -Raw
$R+=[pscustomobject]@{Estado=$(if($Texto-match'Registrar evaluacion'){'PASS'}else{'FAIL'});Prueba='Control evaluacion'}
$R+=[pscustomobject]@{Estado=$(if($Texto-match'PaqueteId \$script:Ultimo.paqueteId'){'PASS'}else{'FAIL'});Prueba='Paquete automatico'}
$R+=[pscustomobject]@{Estado=$(if($Texto-match'Consulta \$script:Ultimo.consulta'){'PASS'}else{'FAIL'});Prueba='Consulta automatica'}
$R+=[pscustomobject]@{Estado=$(if($Texto-match'if\(\[int\]\$R.resultados-eq0\)'){'PASS'}else{'FAIL'});Prueba='Resultado sugerido'}
$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile($Panel,[ref]$T,[ref]$E);$R+=[pscustomobject]@{Estado=$(if(@($E).Count-eq0){'PASS'}else{'FAIL'});Prueba='Sintaxis panel'}
$R|Format-Table -AutoSize;$A=@($R|Where-Object{$_.Estado-eq'PASS'}).Count;Write-Host "Aprobadas: $A / $($R.Count)";if($A-ne$R.Count){exit 1}
