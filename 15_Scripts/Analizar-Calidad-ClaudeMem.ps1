#Requires -Version 5.1
# VERSION 1.0.0 - FASE 8A
[CmdletBinding()]
param([ValidateRange(1,365)][int]$UltimosDias=30,[switch]$GenerarInforme)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Obs=Join-Path $CM 'episodios\observacion-operativa.jsonl'
$Cua=Join-Path $CM 'episodios\observacion-operativa-cuarentena.jsonl'
$Ctx=Join-Path $CM 'episodios\contextos-usados.jsonl'
$Diag=Join-Path $CM 'diagnosticos'
$Desde=(Get-Date).AddDays(-$UltimosDias)
function Leer-Jsonl([string]$Ruta,[switch]$FiltrarFecha){
 $Salida=@();$Invalidas=0
 if(Test-Path -LiteralPath $Ruta){foreach($L in Get-Content -LiteralPath $Ruta){if([string]::IsNullOrWhiteSpace($L)){continue};try{$R=$L|ConvertFrom-Json -ErrorAction Stop;if(-not$FiltrarFecha-or([datetime]$R.fecha-ge$Desde)-or([datetime]$R.generado-ge$Desde)){$Salida+=$R}}catch{$Invalidas++}}}
 [pscustomobject]@{datos=@($Salida);invalidas=$Invalidas}
}
$O=Leer-Jsonl $Obs -FiltrarFecha;$Q=Leer-Jsonl $Cua -FiltrarFecha;$C=Leer-Jsonl $Ctx
$Validas=@($O.datos);$Cuarentena=@($Q.datos);$Contextos=@($C.datos)
$Total=$Validas.Count;$Rel=$(if($Total){[math]::Round((($Validas|Measure-Object relevancia -Average).Average),2)}else{0});$Tiempo=$(if($Total){[math]::Round((($Validas|Measure-Object tiempoSegundos -Average).Average),2)}else{0})
$SinResultados=@($Validas|Where-Object{$_.resultado-eq'SIN_RESULTADOS'}).Count
$Poco=@($Validas|Where-Object{$_.resultado-eq'POCO_RELEVANTE'}).Count
$Errores=@($Validas|Where-Object{$_.resultado-eq'ERROR_PANEL'}).Count
$Falsos=@($Validas|Where-Object{$_.resultado-eq'FALSO_POSITIVO_SEGURIDAD'}).Count
$ConResultados=@($Contextos|Where-Object{[int]$_.resultados-gt0}).Count
$TasaResultados=$(if($Contextos.Count){[math]::Round(100*$ConResultados/$Contextos.Count,2)}else{0})
$TasaCuarentena=$(if(($Total+$Cuarentena.Count)-gt0){[math]::Round(100*$Cuarentena.Count/($Total+$Cuarentena.Count),2)}else{0})
$Duplicados=@($Validas|Where-Object{-not[string]::IsNullOrWhiteSpace([string]$_.paqueteId)}|Group-Object paqueteId|Where-Object{$_.Count-gt1}).Count
$Recomendaciones=@()
if($Total-lt10){$Recomendaciones+='AMPLIAR_MUESTRA_OPERATIVA'}
if($Total-ge3-and$Rel-lt4){$Recomendaciones+='REVISAR_RANKING_Y_VOCABULARIO'}
if($Contextos.Count-ge5-and$TasaResultados-lt85){$Recomendaciones+='ANALIZAR_CONSULTAS_SIN_RESULTADOS'}
if($TasaCuarentena-gt20){$Recomendaciones+='REVISAR_CAUSAS_DE_CUARENTENA'}
if($Errores-gt0){$Recomendaciones+='REVISAR_ERRORES_DEL_PANEL'}
if($Falsos-gt0){$Recomendaciones+='REVISAR_FALSOS_POSITIVOS_SEGURIDAD'}
if($Duplicados-gt0){$Recomendaciones+='ELIMINAR_DUPLICADOS_ACEPTADOS'}
$Estado=$(if(($O.invalidas+$Q.invalidas+$C.invalidas+$Duplicados)-gt0){'BLOQUEADO'}elseif($Total-lt10){'MUESTRA_INSUFICIENTE'}elseif($Rel-ge4-and$TasaResultados-ge85-and$Errores-eq0){'APROBADO'}else{'REVISAR'})
$R=[pscustomobject][ordered]@{desde=$Desde.ToString('yyyy-MM-dd');hasta=Get-Date -Format 'yyyy-MM-dd';observacionesValidas=$Total;cuarentena=$Cuarentena.Count;contextos=$Contextos.Count;relevanciaPromedio=$Rel;tiempoPromedioSegundos=$Tiempo;tasaContextosConResultados=$TasaResultados;tasaCuarentena=$TasaCuarentena;sinResultados=$SinResultados;pocoRelevantes=$Poco;erroresPanel=$Errores;falsosPositivosSeguridad=$Falsos;duplicadosAceptados=$Duplicados;lineasInvalidas=($O.invalidas+$Q.invalidas+$C.invalidas);estado=$Estado;recomendaciones=$Recomendaciones;version='1.0.0'}
if($GenerarInforme){New-Item -ItemType Directory -Path $Diag -Force|Out-Null;$S=Get-Date -Format 'yyyyMMdd-HHmmss';$J=Join-Path $Diag "calidad-ClaudeMem-$S.json";$M=Join-Path $Diag "calidad-ClaudeMem-$S.md";[IO.File]::WriteAllText($J,($R|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($true));$L=@('# Calidad operativa ClaudeMem','',"Estado: $Estado","Periodo: $($R.desde) a $($R.hasta)","Observaciones validas: $Total","Relevancia promedio: $Rel / 5","Contextos con resultados: $TasaResultados %","Tasa de cuarentena: $TasaCuarentena %","Errores del panel: $Errores","Lineas invalidas: $($R.lineasInvalidas)",'','## Recomendaciones');foreach($X in $Recomendaciones){$L+="- $X"};[IO.File]::WriteAllLines($M,[string[]]$L,[Text.UTF8Encoding]::new($true));Write-Host "Informe JSON: $J";Write-Host "Informe Markdown: $M"}
$R
if($Estado-eq'BLOQUEADO'){exit 1}
