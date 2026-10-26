#Requires -Version 5.1
# VERSION 1.0.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Puerta=Join-Path $PSScriptRoot 'Invocar-ClaudeMem-Copilot.ps1'
$TempMd=Join-Path $env:TEMP 'ClaudeMem-contexto-prueba.md'
$TempJson=Join-Path $env:TEMP 'ClaudeMem-contexto-prueba.json'
$R=@()
$Obj=&$Puerta -Consulta 'ClaudeMem memoria integracion' -Nivel 1 -MaxCaracteres 2500 -OmitirAuditoriaPrevia
$Md=&$Puerta -Consulta 'ClaudeMem memoria integracion' -Nivel 2 -MaxCaracteres 4000 -ModoSalida MARKDOWN -OmitirAuditoriaPrevia
$null=&$Puerta -Consulta 'ClaudeMem memoria integracion' -Nivel 2 -MaxCaracteres 4000 -ModoSalida ARCHIVO -RutaSalida $TempMd -OmitirAuditoriaPrevia
$null=&$Puerta -Consulta 'ClaudeMem memoria integracion' -Nivel 3 -MaxCaracteres 7000 -ModoSalida JSON -RutaSalida $TempJson -OmitirAuditoriaPrevia
$R+=[pscustomobject]@{Estado=$(if($Obj.resultados-gt0){'PASS'}else{'FAIL'});Prueba='Objeto'}
$R+=[pscustomobject]@{Estado=$(if($Md-match'# CONTEXTO OPERATIVO'){ 'PASS'}else{'FAIL'});Prueba='Markdown'}
$R+=[pscustomobject]@{Estado=$(if(Test-Path -LiteralPath $TempMd){'PASS'}else{'FAIL'});Prueba='Archivo Markdown'}
$R+=[pscustomobject]@{Estado=$(if(Test-Path -LiteralPath $TempJson){'PASS'}else{'FAIL'});Prueba='Archivo JSON'}
$R|Format-Table -AutoSize
$Aprobadas=@($R|Where-Object{[string]$_.Estado-eq'PASS'}).Count
Write-Host "Aprobadas: $Aprobadas / $($R.Count)";if($Aprobadas-ne$R.Count){exit 1}
Remove-Item -LiteralPath $TempMd,$TempJson -Force -ErrorAction SilentlyContinue
