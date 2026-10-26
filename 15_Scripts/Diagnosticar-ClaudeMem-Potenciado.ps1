#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5A
[CmdletBinding()]
param([switch]$GenerarInforme)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$Resultados = @()
function Agregar([string]$Prueba,[bool]$Aprobado,[string]$Detalle) {
    $script:Resultados += [PSCustomObject]@{ Estado = $(if($Aprobado){'PASS'}else{'FAIL'}); Prueba=$Prueba; Detalle=$Detalle }
}
$Manifiesto = Join-Path $ClaudeMemRoot 'config\manifiesto-componentes.json'
Agregar 'Manifiesto' (Test-Path -LiteralPath $Manifiesto -PathType Leaf) $Manifiesto
if (Test-Path -LiteralPath $Manifiesto) {
    $M = Get-Content -LiteralPath $Manifiesto -Raw | ConvertFrom-Json
    foreach ($C in $M.componentes) {
        if (-not [bool]$C.obligatorio) { continue }
        $Ruta = Join-Path $CopilotRoot ([string]$C.rutaRelativa)
        $Existe = Test-Path -LiteralPath $Ruta -PathType Leaf
        Agregar "Componente $($C.nombre)" $Existe $(if($Existe){'Existe'}else{'Faltante'})
        if ($Existe) {
            $Hash = (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash
            Agregar "Hash $($C.nombre)" ($Hash -eq [string]$C.sha256) $(if($Hash -eq [string]$C.sha256){'Coincide'}else{'No coincide'})
            $Tokens=$null;$Errores=$null
            [void][Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $Ruta),[ref]$Tokens,[ref]$Errores)
            Agregar "Sintaxis $($C.nombre)" (@($Errores).Count -eq 0) "Errores: $(@($Errores).Count)"
        }
    }
}
foreach ($RutaJson in @(
    'episodios\sesiones.json','episodios\eventos.json','episodios\observaciones.json','episodios\resumenes.json',
    'candidatos\pendientes.json','candidatos\aprobados.json','candidatos\rechazados.json','candidatos\duplicados.json',
    'config\politicas-captura.json','config\rutas-excluidas.json','config\patrones-secretos.json')) {
    $Ruta = Join-Path $ClaudeMemRoot $RutaJson
    $Valido = $false
    if (Test-Path -LiteralPath $Ruta -PathType Leaf) {
        try { $Raw=Get-Content -LiteralPath $Ruta -Raw; if([string]::IsNullOrWhiteSpace($Raw)){$Valido=$true}else{$null=$Raw|ConvertFrom-Json;$Valido=$true} } catch { $Valido=$false }
    }
    Agregar "JSON $RutaJson" $Valido $(if($Valido){'Valido'}else{'Invalido o faltante'})
}
$Temporales = @(Get-ChildItem -LiteralPath $ClaudeMemRoot -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -like '*.tmp' })
Agregar 'Temporales residuales' ($Temporales.Count -eq 0) "Cantidad: $($Temporales.Count)"
$Lanzador = Join-Path $CopilotRoot 'Iniciar-ClaudeMem-Copilot.cmd'
Agregar 'Lanzador visible' (Test-Path -LiteralPath $Lanzador -PathType Leaf) $Lanzador
$Resultados | Format-Table -AutoSize
$Fallidas=@($Resultados|Where-Object{[string]$_.Estado -eq 'FAIL'}).Count
Write-Host "Fallidas: $Fallidas"
if ($GenerarInforme) {
    $Carpeta=Join-Path $ClaudeMemRoot 'diagnosticos';New-Item -ItemType Directory -Path $Carpeta -Force|Out-Null
    $Sello=Get-Date -Format 'yyyyMMdd-HHmmss'
    $Json=Join-Path $Carpeta "diagnostico-$Sello.json"
    $Md=Join-Path $Carpeta "diagnostico-$Sello.md"
    [IO.File]::WriteAllText($Json,($Resultados|ConvertTo-Json -Depth 10),[Text.UTF8Encoding]::new($true))
    $Lineas=@('# Diagnostico ClaudeMem','',"Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",'',"Fallidas: $Fallidas",'','| Estado | Prueba | Detalle |','|---|---|---|')
    foreach($R in $Resultados){$Lineas+="| $($R.Estado) | $($R.Prueba) | $($R.Detalle -replace '\|','/') |"}
    [IO.File]::WriteAllLines($Md,[string[]]$Lineas,[Text.UTF8Encoding]::new($true))
    Write-Host "Informe JSON: $Json";Write-Host "Informe Markdown: $Md"
}
if($Fallidas){exit 1};Write-Host 'DIAGNOSTICO GENERAL APROBADO' -ForegroundColor Green
