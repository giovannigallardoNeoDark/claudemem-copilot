#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5B
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Origen=$PSScriptRoot;$Temp=Join-Path $env:TEMP ('ClaudeMem-Restauracion-'+[guid]::NewGuid().ToString('N'))
$Backup=Join-Path $Temp 'backup';$Destino=Join-Path $Temp 'destino';New-Item -ItemType Directory -Path (Join-Path $Backup '15_Scripts'),$Destino -Force|Out-Null
$Nombres=@('Invocar-ClaudeMem-Copilot.ps1','Preparar-Contexto-Copilot.ps1','Convertir-Registro-Contexto-Legible.ps1')
foreach($N in $Nombres){Copy-Item -LiteralPath (Join-Path $Origen $N) -Destination (Join-Path $Backup '15_Scripts') -Force}
$Hashes=@{};foreach($N in $Nombres){$Hashes[$N]=(Get-FileHash (Join-Path $Origen $N) -Algorithm SHA256).Hash}
$R=@()
try{
 foreach($N in $Nombres){Copy-Item -LiteralPath (Join-Path (Join-Path $Backup '15_Scripts') $N) -Destination $Destino -Force}
 $R+=[pscustomobject]@{Estado=$(if(@(Get-ChildItem $Destino -File).Count-eq$Nombres.Count){'PASS'}else{'FAIL'});Prueba='Archivos restaurados'}
 $HashOk=$true;$SintaxisOk=$true
 foreach($N in $Nombres){if((Get-FileHash (Join-Path $Destino $N) -Algorithm SHA256).Hash-ne$Hashes[$N]){$HashOk=$false};$T=$null;$E=$null;[void][Management.Automation.Language.Parser]::ParseFile((Join-Path $Destino $N),[ref]$T,[ref]$E);if(@($E).Count){$SintaxisOk=$false}}
 $R+=[pscustomobject]@{Estado=$(if($HashOk){'PASS'}else{'FAIL'});Prueba='Hashes restaurados'}
 $R+=[pscustomobject]@{Estado=$(if($SintaxisOk){'PASS'}else{'FAIL'});Prueba='Sintaxis restaurada'}
 $RealIntacto=$true;foreach($N in $Nombres){if((Get-FileHash (Join-Path $Origen $N) -Algorithm SHA256).Hash-ne$Hashes[$N]){$RealIntacto=$false}}
 $R+=[pscustomobject]@{Estado=$(if($RealIntacto){'PASS'}else{'FAIL'});Prueba='Entorno real intacto'}
}finally{Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue}
$R|Format-Table -AutoSize;$A=@($R|Where-Object{$_.Estado-eq'PASS'}).Count;Write-Host "Aprobadas: $A / $($R.Count)";if($A-ne$R.Count){exit 1};Write-Host 'RESTAURACION AISLADA APROBADA' -ForegroundColor Green
