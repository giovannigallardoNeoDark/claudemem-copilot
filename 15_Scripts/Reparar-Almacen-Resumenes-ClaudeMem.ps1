#Requires -Version 5.1
# VERSION 1.1.0
[CmdletBinding()]
param([switch]$Reparar,[switch]$Auditar)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\resumenes.json'
$Backups=Join-Path $CM 'backups'

function Expandir-Resumenes([AllowNull()][object]$Nodo){
    $Salida=@()
    if($null-eq$Nodo){return $Salida}
    if($Nodo-is[System.Array]){foreach($E in $Nodo){$Salida+=@(Expandir-Resumenes $E)};return $Salida}
    $P=@($Nodo.PSObject.Properties.Name)
    if($P-contains'resumenId' -and $P-contains'sesionId'){$Salida+=$Nodo;return $Salida}
    if($P-contains'value'){$Salida+=@(Expandir-Resumenes $Nodo.value)}
    return $Salida
}
function Leer-Recuperados {
    $Raw=Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if([string]::IsNullOrWhiteSpace($Raw)){return @()}
    $X=ConvertFrom-Json -InputObject $Raw -ErrorAction Stop
    $Todos=@(Expandir-Resumenes $X)
    return @($Todos|Group-Object sesionId|ForEach-Object{$_.Group|Sort-Object generado -Descending|Select-Object -First 1})
}
if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){throw "No existe: $Ruta"}
if($Reparar){
    New-Item -ItemType Directory -Path $Backups -Force|Out-Null
    $Backup=Join-Path $Backups ("resumenes-pre-reparacion-{0}.json"-f(Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $Ruta -Destination $Backup -Force
    $Datos=@(Leer-Recuperados)
    $Tmp="$Ruta.tmp"
    # Construye explicitamente una raiz JSON plana [] para evitar arreglos anidados en Windows PowerShell 5.1.
    $ElementosJson = @(
        foreach ($Dato in $Datos) {
            ConvertTo-Json -InputObject $Dato -Depth 50 -Compress
        }
    )
    $Json = "[" + ($ElementosJson -join ",") + "]"
    [IO.File]::WriteAllText($Tmp,$Json,[Text.UTF8Encoding]::new($true))
    $null=Get-Content -LiteralPath $Tmp -Raw|ConvertFrom-Json -ErrorAction Stop
    Move-Item -LiteralPath $Tmp -Destination $Ruta -Force
    Write-Host "Backup: $Backup"
}
$TextoFinal = Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
$RaizFinal = ConvertFrom-Json -InputObject $TextoFinal -ErrorAction Stop
$Final=@(Leer-Recuperados)
$Errores=@()
if (-not $TextoFinal.TrimStart().StartsWith('[')) { $Errores += 'La raiz JSON no es un arreglo.' }
foreach ($ElementoRaiz in @($RaizFinal)) {
    if ($ElementoRaiz -is [System.Array]) { $Errores += 'Se detecto un arreglo anidado en la raiz.' }
}
foreach($R in $Final){
    foreach($Campo in @('resumenId','sesionId','objetivo','estadoSesion','generado','metodo','version')){
        if(-not($R.PSObject.Properties.Name-contains$Campo)-or[string]::IsNullOrWhiteSpace([string]$R.$Campo)){$Errores+="$([string]$R.resumenId): falta $Campo"}
    }
}
$Final|Select-Object resumenId,sesionId,objetivo,estadoSesion,generado,metodo,version|Format-Table -AutoSize
Write-Host "Resumenes validos: $($Final.Count)"
Write-Host "Errores de esquema: $($Errores.Count)"
if($Errores.Count){$Errores|ForEach-Object{Write-Host $_ -ForegroundColor Red};exit 1}
Write-Host 'AUDITORIA DE RESUMENES APROBADA' -ForegroundColor Green
