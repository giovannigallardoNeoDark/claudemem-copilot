#Requires -Version 5.1
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$CM=Join-Path (Split-Path -Parent $PSScriptRoot) '11_Herramientas\ClaudeMem'
$items=@('episodios\sesiones.json','episodios\eventos.json','episodios\observaciones.json','episodios\resumenes.json','candidatos\pendientes.json','candidatos\aprobados.json','candidatos\rechazados.json','candidatos\duplicados.json','config\politicas-captura.json','config\rutas-excluidas.json','config\clasificacion-informacion.json','config\patrones-secretos.json')
$r=@();foreach($i in $items){$p=Join-Path $CM $i;$ok=Test-Path $p;try{if($ok){$null=Get-Content $p -Raw|ConvertFrom-Json}}catch{$ok=$false};$r+=[pscustomobject]@{Estado=$(if($ok){'PASS'}else{'FAIL'});Elemento=$i}}
$official=@('data\decisiones.json','data\lecciones.json','data\hallazgos.json','index\index.json','sync\manifiesto-bidireccional.json');foreach($i in $official){$p=Join-Path $CM $i;$r+=[pscustomobject]@{Estado=$(if(Test-Path $p){'PASS'}else{'FAIL'});Elemento="Nucleo: $i"}}
$r|Format-Table -AutoSize;$pass=@($r|Where-Object Estado -eq 'PASS').Count;$pct=[math]::Round(100*$pass/$r.Count,2);Write-Host "Aprobadas: $pass / $($r.Count)";Write-Host "Resultado: $pct %";if($pass-ne$r.Count){exit 1}
