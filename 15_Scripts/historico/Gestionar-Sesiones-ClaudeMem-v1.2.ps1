# VERSION 1.2.0
#Requires -Version 5.1
[CmdletBinding(DefaultParameterSetName='Listar')]
param(
 [Parameter(ParameterSetName='Iniciar',Mandatory=$true)][switch]$Iniciar,
 [Parameter(ParameterSetName='Cerrar',Mandatory=$true)][switch]$Cerrar,
 [Parameter(ParameterSetName='Evento',Mandatory=$true)][switch]$RegistrarEvento,
 [Parameter(ParameterSetName='Observar',Mandatory=$true)][switch]$RegistrarObservacion,
 [Parameter(ParameterSetName='Cerrar',Mandatory=$true)][Parameter(ParameterSetName='Evento',Mandatory=$true)][Parameter(ParameterSetName='Observar',Mandatory=$true)][string]$SesionId,
 [Parameter(ParameterSetName='Iniciar',Mandatory=$true)][string]$Objetivo,
 [Parameter(ParameterSetName='Evento',Mandatory=$true)][string]$TipoEvento,
 [Parameter(ParameterSetName='Evento',Mandatory=$true)][Parameter(ParameterSetName='Observar',Mandatory=$true)][string]$Contenido,
 [Parameter(ParameterSetName='Observar')][ValidateSet('PUBLICO','INTERNO','CONFIDENCIAL','RESTRINGIDO','NO_CAPTURAR')][string]$Clasificacion='INTERNO'
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$CM=Join-Path (Split-Path -Parent $PSScriptRoot) '11_Herramientas\ClaudeMem';$E=Join-Path $CM 'episodios'
function List([object]$x) {
    $r = @()
    if ($null -eq $x) { return $r }
    if ($x -is [System.Array]) {
        foreach ($item in $x) {
            if ($null -ne $item) { $r += $item }
        }
    }
    else { $r += $x }
    return $r
}
function Read([string]$p) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return @() }
    $raw = Get-Content -LiteralPath $p -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $parsed = ConvertFrom-Json -InputObject $raw -ErrorAction Stop
    return @(List $parsed)
}
function Save([string]$p,[array]$d) {
    # Elimina objetos vacios o corruptos antes de guardar.
    $clean = @(
        $d | Where-Object {
            $null -ne $_ -and $_.PSObject.Properties.Count -gt 0
        }
    )
    $tmp = "$p.tmp"
    $json = ConvertTo-Json -InputObject ([object[]]$clean) -Depth 30
    [IO.File]::WriteAllText($tmp, $json, [Text.UTF8Encoding]::new($true))
    $null = Get-Content -LiteralPath $tmp -Raw | ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $tmp -Destination $p -Force
}
$sf=Join-Path $E 'sesiones.json';$ef=Join-Path $E 'eventos.json';$of=Join-Path $E 'observaciones.json'
function Sesion-Valida([object]$s, [string]$id, [switch]$Activa) {
    if ($null -eq $s) { return $false }
    if (-not ($s.PSObject.Properties.Name -contains 'sesionId')) { return $false }
    if ([string]$s.sesionId -ne [string]$id) { return $false }
    if ($Activa) {
        if (-not ($s.PSObject.Properties.Name -contains 'estado')) { return $false }
        return ([string]$s.estado -eq 'ACTIVA')
    }
    return $true
}
if($Iniciar){$d=@(Read $sf);$id='SES-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');$d+=[pscustomobject]@{sesionId=$id;inicio=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';fin='';objetivo=$Objetivo;estado='ACTIVA'};Save $sf $d;Write-Output $id;return}
if($Cerrar){$d=@(Read $sf);$s=@($d | Where-Object { Sesion-Valida -s $_ -id $SesionId });if($s.Count -ne 1){throw 'Sesion no encontrada o duplicada'};$s[0].estado='CERRADA';$s[0].fin=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';Save $sf $d;Write-Output 'Sesion cerrada';return}
if($RegistrarEvento){$sesiones=@(Read $sf);if(@($sesiones | Where-Object { Sesion-Valida -s $_ -id $SesionId -Activa }).Count -ne 1){throw 'La sesion no existe o no esta ACTIVA'};$d=@(Read $ef);$d+=[pscustomobject]@{eventoId='EVT-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');sesionId=$SesionId;tipo=$TipoEvento;contenido=$Contenido;fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'};Save $ef $d;Write-Output 'Evento registrado';return}
if($RegistrarObservacion){if($Clasificacion -eq 'NO_CAPTURAR'){throw 'Contenido excluido por politica'};$sesiones=@(Read $sf);if(@($sesiones | Where-Object { Sesion-Valida -s $_ -id $SesionId -Activa }).Count -ne 1){throw 'La sesion no existe o no esta ACTIVA'};$d=@(Read $of);$d+=[pscustomobject]@{observacionId='OBS-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');sesionId=$SesionId;contenido=$Contenido;clasificacion=$Clasificacion;fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';estado='CAPTURADA'};Save $of $d;Write-Output 'Observacion registrada';return}
@(Read $sf)|Format-Table -AutoSize
