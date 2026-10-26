#Requires -Version 5.1
# VERSION 1.1.0 - FASE 8B
[CmdletBinding()]
param(
    [ValidateRange(1,365)][int]$UltimosDias = 30,
    [ValidateRange(3,1000)][int]$MinimoObservaciones = 10,
    [switch]$GenerarInforme
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Analizador=Join-Path $PSScriptRoot 'Analizar-Calidad-ClaudeMem.ps1'
if(-not(Test-Path -LiteralPath $Analizador -PathType Leaf)){throw "Falta analizador: $Analizador"}
$SalidaAnalizador=@(& $Analizador -UltimosDias $UltimosDias)
$Calidad=@($SalidaAnalizador|Where-Object{$null-ne$_ -and $_.PSObject.Properties.Name-contains'estado'})|Select-Object -Last 1
if($null-eq$Calidad){throw 'El analizador no devolvio un objeto de calidad valido.'}
$Criterios=@(
 [pscustomobject]@{criterio='Muestra suficiente';cumple=([int]$Calidad.observacionesValidas-ge$MinimoObservaciones);actual=$Calidad.observacionesValidas;objetivo=$MinimoObservaciones},
 [pscustomobject]@{criterio='Relevancia promedio';cumple=([double]$Calidad.relevanciaPromedio-ge4);actual=$Calidad.relevanciaPromedio;objetivo=4},
 [pscustomobject]@{criterio='Contextos con resultados';cumple=([double]$Calidad.tasaContextosConResultados-ge85);actual=$Calidad.tasaContextosConResultados;objetivo=85},
 [pscustomobject]@{criterio='Duplicados aceptados';cumple=([int]$Calidad.duplicadosAceptados-eq0);actual=$Calidad.duplicadosAceptados;objetivo=0},
 [pscustomobject]@{criterio='Lineas invalidas';cumple=([int]$Calidad.lineasInvalidas-eq0);actual=$Calidad.lineasInvalidas;objetivo=0},
 [pscustomobject]@{criterio='Errores del panel';cumple=([int]$Calidad.erroresPanel-eq0);actual=$Calidad.erroresPanel;objetivo=0}
)
$Bloqueantes=@($Criterios|Where-Object{-not$_.cumple-and$_.criterio-ne'Muestra suficiente'})
$Estado=if([int]$Calidad.lineasInvalidas-gt0-or[int]$Calidad.duplicadosAceptados-gt0){'BLOQUEADO'}elseif([int]$Calidad.observacionesValidas-lt$MinimoObservaciones){'EN_OBSERVACION'}elseif($Bloqueantes.Count-eq0){'CIERRE_APROBADO'}else{'MEJORA_REQUERIDA'}
$Resultado=[pscustomobject][ordered]@{fase='8B';generado=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';periodoDias=$UltimosDias;minimoObservaciones=$MinimoObservaciones;estado=$Estado;avance=$(if($Estado-eq'CIERRE_APROBADO'){100}else{99});calidad=$Calidad;criterios=$Criterios}
if($GenerarInforme){$Root=Split-Path -Parent $PSScriptRoot;$Dir=Join-Path $Root '11_Herramientas\ClaudeMem\diagnosticos';New-Item -ItemType Directory -Path $Dir -Force|Out-Null;$S=Get-Date -Format 'yyyyMMdd-HHmmss';$J=Join-Path $Dir "cierre-madurez-$S.json";$M=Join-Path $Dir "cierre-madurez-$S.md";[IO.File]::WriteAllText($J,($Resultado|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($true));$L=@('# Cierre de madurez operativa ClaudeMem','',"Estado: $Estado","Avance: $($Resultado.avance) %","Observaciones validas: $($Calidad.observacionesValidas) / $MinimoObservaciones",'','| Criterio | Cumple | Actual | Objetivo |','|---|---|---:|---:|');foreach($C in $Criterios){$L+="| $($C.criterio) | $($C.cumple) | $($C.actual) | $($C.objetivo) |"};[IO.File]::WriteAllLines($M,[string[]]$L,[Text.UTF8Encoding]::new($true));Write-Host "Informe JSON: $J";Write-Host "Informe Markdown: $M"}
$Criterios|Format-Table -AutoSize|Out-Host
Write-Host "ESTADO FASE 8B: $Estado"
Write-Host "AVANCE GLOBAL: $($Resultado.avance) %"
Write-Output $Resultado
if($Estado-eq'BLOQUEADO'){exit 1}
