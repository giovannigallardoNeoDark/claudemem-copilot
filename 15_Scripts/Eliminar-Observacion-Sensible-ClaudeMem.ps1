#Requires -Version 5.1
# VERSION 1.0.0
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TextoExacto
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\observaciones.json'
$Backups=Join-Path $CM 'backups'
New-Item -ItemType Directory -Path $Backups -Force|Out-Null
$Backup=Join-Path $Backups ("observaciones-pre-limpieza-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
Copy-Item -LiteralPath $Ruta -Destination $Backup -Force
$Raw=Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
$Datos=@();if(-not[string]::IsNullOrWhiteSpace($Raw)){$X=ConvertFrom-Json -InputObject $Raw -ErrorAction Stop;if($X-is[Array]){$Datos+=@($X)}else{$Datos+=$X}}
$Antes=$Datos.Count
$Limpios=@($Datos|Where-Object { -not ($_.PSObject.Properties.Name -contains 'contenido') -or [string]$_.contenido -ne $TextoExacto })
$Eliminados=$Antes-$Limpios.Count
$Tmp="$Ruta.tmp";$Json=ConvertTo-Json -InputObject ([object[]]$Limpios) -Depth 30
[IO.File]::WriteAllText($Tmp,$Json,[Text.UTF8Encoding]::new($true));$null=Get-Content $Tmp -Raw|ConvertFrom-Json;Move-Item $Tmp $Ruta -Force
Write-Host "Observaciones eliminadas: $Eliminados"
Write-Host "Backup: $Backup"
