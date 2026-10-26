#Requires -Version 5.1
# VERSION 1.0.0 - FASE 7B
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$Ruta=Join-Path $Root '.vscode\tasks.json'
if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){throw 'No existe .vscode\tasks.json'}
$J=Get-Content -LiteralPath $Ruta -Raw|ConvertFrom-Json -ErrorAction Stop
$Esperadas=@('ClaudeMem: ciclo automatico','ClaudeMem: ciclo con reparacion','ClaudeMem: abrir panel','ClaudeMem: obtener estado','ClaudeMem: abrir ultimo informe')
$Etiquetas=@($J.tasks|Select-Object -ExpandProperty label)
$R=@()
foreach($E in $Esperadas){$R+=[pscustomobject]@{Estado=$(if($E-in$Etiquetas){'PASS'}else{'FAIL'});Prueba=$E}}
$R+=[pscustomobject]@{Estado=$(if($J.version-eq'2.0.0'){'PASS'}else{'FAIL'});Prueba='Esquema tasks 2.0.0'}
$R|Format-Table -AutoSize
$A=@($R|Where-Object{$_.Estado-eq'PASS'}).Count
Write-Host "Aprobadas: $A / $($R.Count)"
if($A-ne$R.Count){exit 1}
Write-Host 'INTEGRACION VSCODE APROBADA' -ForegroundColor Green
