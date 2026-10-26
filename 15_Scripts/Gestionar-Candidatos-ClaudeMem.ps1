# VERSION 1.3.0
#Requires -Version 5.1
[CmdletBinding(DefaultParameterSetName='Listar')]
param(
 [Parameter(ParameterSetName='Crear',Mandatory=$true)][switch]$Crear,
 [Parameter(ParameterSetName='Resolver',Mandatory=$true)][switch]$Resolver,
 [Parameter(ParameterSetName='Crear',Mandatory=$true)][string]$SesionId,
 [Parameter(ParameterSetName='Crear',Mandatory=$true)][ValidateSet('decision','leccion','hallazgo')][string]$TipoSugerido,
 [Parameter(ParameterSetName='Crear',Mandatory=$true)][string]$Contenido,
 [Parameter(ParameterSetName='Resolver',Mandatory=$true)][string]$CandidatoId,
 [Parameter(ParameterSetName='Resolver',Mandatory=$true)][ValidateSet('APROBAR','RECHAZAR','DUPLICADO','POSPONER')][string]$Decision,
 [Parameter(ParameterSetName='Resolver')][string]$Motivo=''
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$CM=Join-Path (Split-Path -Parent $PSScriptRoot) '11_Herramientas\ClaudeMem';$CarpetaCandidatos=Join-Path $CM 'candidatos'
function Convertir-ALista($x) {
    $r = @()
    if ($null -eq $x) { return $r }
    if ($x -is [System.Array]) {
        foreach ($item in $x) {
            if ($null -ne $item -and @($item.PSObject.Properties).Count -gt 0) { $r += $item }
        }
    }
    elseif (@($x.PSObject.Properties).Count -gt 0) { $r += $x }
    return $r
}
function Leer-JsonArray($p) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { return @() }
    $raw = Get-Content -LiteralPath $p -Raw -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    return @(Convertir-ALista (ConvertFrom-Json -InputObject $raw -ErrorAction Stop))
}
function Guardar-JsonArray($p,[array]$d) {
    $clean = @($d | Where-Object { $null -ne $_ -and @($_.PSObject.Properties).Count -gt 0 })
    $t = "$p.tmp"
    [IO.File]::WriteAllText($t,([object[]]$clean|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($true))
    $null = Get-Content -LiteralPath $t -Raw | ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $t -Destination $p -Force
}
$pend=Join-Path $CarpetaCandidatos 'pendientes.json'
if($Crear){$d=@(Leer-JsonArray $pend);$id='CAND-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff');$d+=[pscustomobject]@{candidatoId=$id;sesionId=$SesionId;tipoSugerido=$TipoSugerido;contenido=$Contenido;estadoRevision='PENDIENTE';fecha=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'};Guardar-JsonArray $pend $d;Write-Output $id;return}
if($Resolver){
    $DatosPendientes = @(Leer-JsonArray $pend)
    $Coincidencias = @(
        $DatosPendientes | Where-Object {
            $_.PSObject.Properties.Name -contains 'candidatoId' -and
            [string]$_.candidatoId -eq [string]$CandidatoId
        }
    )
    if($Coincidencias.Count -ne 1){throw 'Candidato no encontrado o duplicado'}
    $DestinoNombre = if($Decision -eq 'APROBAR'){'aprobados.json'}elseif($Decision -eq 'RECHAZAR'){'rechazados.json'}elseif($Decision -eq 'DUPLICADO'){'duplicados.json'}else{$null}
    if($null -eq $DestinoNombre){
        $Coincidencias[0].estadoRevision='POSPUESTO'
        Guardar-JsonArray $pend $DatosPendientes
    }
    else{
        $Coincidencias[0].estadoRevision=$Decision
        $Coincidencias[0] | Add-Member NoteProperty motivo $Motivo -Force
        $RutaDestino=Join-Path $CarpetaCandidatos $DestinoNombre
        $DatosDestino=@(Leer-JsonArray $RutaDestino)
        $DatosDestino+=$Coincidencias[0]
        Guardar-JsonArray $RutaDestino $DatosDestino
        $Restantes=@(
            $DatosPendientes | Where-Object {
                -not ($_.PSObject.Properties.Name -contains 'candidatoId') -or
                [string]$_.candidatoId -ne [string]$CandidatoId
            }
        )
        Guardar-JsonArray $pend $Restantes
    }
    Write-Output 'Candidato resuelto'
    return
}
@(Leer-JsonArray $pend)|Format-Table -AutoSize
