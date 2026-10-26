#Requires -Version 5.1
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Raiz=Split-Path -Parent $PSScriptRoot;$Dist=Join-Path $Raiz 'dist\appPackage';$R=@()
foreach($N in @('manifest.json','declarativeAgent.json','instructions.txt')){$P=Join-Path $Dist $N;$R+=[pscustomobject]@{Prueba="Existe $N";Estado=$(if(Test-Path $P){'PASS'}else{'FAIL'})}}
foreach($N in @('manifest.json','declarativeAgent.json')){$P=Join-Path $Dist $N;if(Test-Path $P){try{$null=Get-Content $P -Raw|ConvertFrom-Json -ErrorAction Stop;$E='PASS'}catch{$E='FAIL'};$R+=[pscustomobject]@{Prueba="JSON valido $N";Estado=$E}}
$Todo=Get-ChildItem $Raiz -Recurse -File|Where-Object{$_.FullName-notmatch'config.local.json'}|ForEach-Object{Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue}|Out-String
$R+=[pscustomobject]@{Prueba='Sin clave API incrustada';Estado=$(if($Todo-match'CLAUDEMEM_API_KEY\s*=\s*[A-Za-z0-9+/]{40,}'){'FAIL'}else{'PASS'})}
$R+=[pscustomobject]@{Prueba='URL MCP configurada';Estado=$(if($Todo-match'https://[^"\s]+/mcp'){'PASS'}else{'FAIL'})}
$R+=[pscustomobject]@{Prueba='Icono color';Estado=$(if(Test-Path (Join-Path $Dist 'color.png')){'PASS'}else{'PENDIENTE'})}
$R+=[pscustomobject]@{Prueba='Icono outline';Estado=$(if(Test-Path (Join-Path $Dist 'outline.png')){'PASS'}else{'PENDIENTE'})}
$R|Format-Table -AutoSize;$F=@($R|Where-Object{$_.Estado-eq'FAIL'}).Count;Write-Host "Fallidas: $F";if($F){exit 1};Write-Host 'VALIDACION ESTRUCTURAL APROBADA' -ForegroundColor Green
