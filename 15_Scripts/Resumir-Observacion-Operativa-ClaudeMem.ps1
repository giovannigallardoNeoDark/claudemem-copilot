#Requires -Version 5.1
# VERSION 1.0.0 - FASE 6A
[CmdletBinding()]
param([ValidateRange(1,365)][int]$UltimosDias=5,[string]$ExportarMarkdown='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\observacion-operativa.jsonl'
$Desde=(Get-Date).AddDays(-$UltimosDias)
$Datos=@()
if(Test-Path -LiteralPath $Ruta){
 foreach($Linea in Get-Content -LiteralPath $Ruta){
  if([string]::IsNullOrWhiteSpace($Linea)){continue}
  try{$R=$Linea|ConvertFrom-Json;if([datetime]$R.fecha-ge$Desde){$Datos+=$R}}catch{}
 }
}
$Total=$Datos.Count
$Promedio=$(if($Total){[math]::Round((($Datos|Measure-Object relevancia -Average).Average),2)}else{0})
$PromedioTiempo=$(if($Total){[math]::Round((($Datos|Measure-Object tiempoSegundos -Average).Average),2)}else{0})
$Incidentes=@($Datos|Where-Object{$_.resultado-ne'SIN_ERROR'}).Count
$Resumen=[pscustomobject][ordered]@{desde=$Desde.ToString('yyyy-MM-dd');hasta=(Get-Date -Format 'yyyy-MM-dd');registros=$Total;relevanciaPromedio=$Promedio;tiempoPromedioSegundos=$PromedioTiempo;incidentes=$Incidentes;porResultado=@($Datos|Group-Object resultado|ForEach-Object{[pscustomobject]@{resultado=$_.Name;cantidad=$_.Count}})}
if(-not[string]::IsNullOrWhiteSpace($ExportarMarkdown)){
 $L=@('# Observacion operativa ClaudeMem','',"Periodo: $($Resumen.desde) a $($Resumen.hasta)","Registros: $Total","Relevancia promedio: $Promedio / 5","Tiempo promedio: $PromedioTiempo s","Incidentes: $Incidentes",'','## Resultados')
 foreach($G in $Resumen.porResultado){$L+="- $($G.resultado): $($G.cantidad)"}
 [IO.File]::WriteAllLines([IO.Path]::GetFullPath($ExportarMarkdown),[string[]]$L,[Text.UTF8Encoding]::new($true))
}
$Resumen
