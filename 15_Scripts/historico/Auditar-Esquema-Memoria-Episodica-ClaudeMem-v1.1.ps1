#Requires -Version 5.1
# VERSION 1.1.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$CM = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'

function Leer-ArregloPlano {
    param([string]$Ruta,[string]$IdCampo)
    $Resultado=[ordered]@{Ruta=$Ruta;Datos=@();Errores=@()}
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){$Resultado.Errores+="Archivo inexistente";return [pscustomobject]$Resultado}
    $Texto=Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if($Texto -match '"value"\s*:' -or $Texto -match '"Count"\s*:'){$Resultado.Errores+='Envoltorio value/Count detectado'}
    $Datos=ConvertFrom-Json -InputObject $Texto -ErrorAction Stop
    $Lista=@();if($null-ne$Datos){if($Datos-is[Array]){$Lista+=@($Datos)}else{$Lista+=$Datos}}
    foreach($Item in $Lista){
        if($null-eq$Item -or @($Item.PSObject.Properties).Count-eq0){$Resultado.Errores+='Objeto vacio';continue}
        if(-not($Item.PSObject.Properties.Name -contains $IdCampo) -or [string]::IsNullOrWhiteSpace([string]$Item.$IdCampo)){$Resultado.Errores+="Falta $IdCampo";continue}
        $Resultado.Datos+=$Item
    }
    $Duplicados=@($Resultado.Datos.$IdCampo|Group-Object|Where-Object Count -gt 1)
    if($Duplicados.Count-gt0){$Resultado.Errores+="IDs duplicados: $($Duplicados.Name -join ', ')"}
    return [pscustomobject]$Resultado
}

$Sesiones=Leer-ArregloPlano (Join-Path $CM 'episodios\sesiones.json') 'sesionId'
$Eventos=Leer-ArregloPlano (Join-Path $CM 'episodios\eventos.json') 'eventoId'
$Observaciones=Leer-ArregloPlano (Join-Path $CM 'episodios\observaciones.json') 'observacionId'
$Pendientes=Leer-ArregloPlano (Join-Path $CM 'candidatos\pendientes.json') 'candidatoId'
$Aprobados=Leer-ArregloPlano (Join-Path $CM 'candidatos\aprobados.json') 'candidatoId'
$Rechazados=Leer-ArregloPlano (Join-Path $CM 'candidatos\rechazados.json') 'candidatoId'
$Duplicados=Leer-ArregloPlano (Join-Path $CM 'candidatos\duplicados.json') 'candidatoId'
$Almacenes=@($Sesiones,$Eventos,$Observaciones,$Pendientes,$Aprobados,$Rechazados,$Duplicados)
$Resultados=@()
foreach($A in $Almacenes){$Resultados+=[pscustomobject]@{Estado=$(if($A.Errores.Count-eq0){'PASS'}else{'FAIL'});Prueba="Esquema $(Split-Path $A.Ruta -Leaf)";Detalle=($A.Errores -join '; ')}}
$IdsSesion=@($Sesiones.Datos.sesionId)
foreach($E in $Eventos.Datos){if([string]$E.sesionId -notin $IdsSesion){$Resultados+=[pscustomobject]@{Estado='FAIL';Prueba='Referencia evento';Detalle="$($E.eventoId) -> $($E.sesionId)"}}}
foreach($O in $Observaciones.Datos){if([string]$O.sesionId -notin $IdsSesion){$Resultados+=[pscustomobject]@{Estado='FAIL';Prueba='Referencia observacion';Detalle="$($O.observacionId) -> $($O.sesionId)"}}}
$Bandejas = @($Pendientes, $Aprobados, $Rechazados, $Duplicados)
$Todos = @()

foreach ($Bandeja in $Bandejas) {
    $Todos += @($Bandeja.Datos.candidatoId)

    foreach ($Candidato in $Bandeja.Datos) {
        if ([string]$Candidato.sesionId -notin $IdsSesion) {
            $Resultados += [PSCustomObject]@{
                Estado = 'FAIL'
                Prueba = 'Referencia candidato'
                Detalle = "$($Candidato.candidatoId) -> $($Candidato.sesionId)"
            }
        }
    }
}

$Cruces=@($Todos|Group-Object|Where-Object Count -gt 1);$Resultados+=[pscustomobject]@{Estado=$(if($Cruces.Count-eq0){'PASS'}else{'FAIL'});Prueba='Candidato en una sola bandeja';Detalle=$(if($Cruces.Count){$Cruces.Name -join ', '}else{'Sin duplicados cruzados'})}
$Activas=@($Sesiones.Datos|Where-Object {[string]$_.estado -eq 'ACTIVA'}).Count;$Resultados+=[pscustomobject]@{Estado=$(if($Activas-eq0){'PASS'}else{'WARN'});Prueba='Sesiones activas';Detalle="$Activas"}
$Resultados|Format-Table -AutoSize
$Fallidas=@($Resultados|Where-Object Estado -eq 'FAIL').Count
Write-Host "Fallidas: $Fallidas";if($Fallidas-gt0){exit 1};Write-Host 'AUDITORIA SEMANTICA APROBADA' -ForegroundColor Green
