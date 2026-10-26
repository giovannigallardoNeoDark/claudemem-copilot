#Requires -Version 5.1
# VERSION 1.0.0 - FASE 4B
[CmdletBinding(DefaultParameterSetName='Listar')]
param(
    [Parameter(ParameterSetName='Listar')][switch]$Listar,
    [Parameter(ParameterSetName='Buscar',Mandatory=$true)][string]$Buscar,
    [Parameter(ParameterSetName='Exportar',Mandatory=$true)][string]$ExportarCsv,
    [Parameter(ParameterSetName='Retencion',Mandatory=$true)][ValidateRange(1,3650)][int]$RetenerDias,
    [ValidateRange(1,1000)][int]$Ultimos=50
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
$Ruta=Join-Path $CM 'episodios\contextos-usados.jsonl'
$Backups=Join-Path $CM 'backups'

function Leer-Historial {
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){return @()}
    $Salida=@()
    foreach($Linea in Get-Content -LiteralPath $Ruta -ErrorAction Stop){
        if([string]::IsNullOrWhiteSpace($Linea)){continue}
        try{$Salida+=($Linea|ConvertFrom-Json -ErrorAction Stop)}catch{Write-Warning "Linea JSONL invalida omitida."}
    }
    return @($Salida)
}
$Datos=@(Leer-Historial)
switch($PSCmdlet.ParameterSetName){
    'Buscar' {$Datos=@($Datos|Where-Object{[string]$_.consulta -like "*$Buscar*"})}
    'Exportar' {
        $Destino=[IO.Path]::GetFullPath($ExportarCsv)
        $Datos|Select-Object paqueteId,consulta,nivel,maxCaracteres,caracteresUsados,resultados,version,generado|Export-Csv -LiteralPath $Destino -NoTypeInformation -Encoding UTF8
        Write-Host "Exportado: $Destino" -ForegroundColor Green
        return
    }
    'Retencion' {
        New-Item -ItemType Directory -Path $Backups -Force|Out-Null
        if(Test-Path -LiteralPath $Ruta){$Backup=Join-Path $Backups ("contextos-usados-pre-retencion-{0}.jsonl"-f(Get-Date -Format 'yyyyMMdd-HHmmss'));Copy-Item -LiteralPath $Ruta -Destination $Backup -Force}
        $Limite=(Get-Date).AddDays(-$RetenerDias)
        $Conservar=@($Datos|Where-Object{try{[datetime]$_.generado-ge$Limite}catch{$true}})
        $Lineas=@($Conservar|ForEach-Object{$_|ConvertTo-Json -Compress})
        [IO.File]::WriteAllLines($Ruta,[string[]]$Lineas,[Text.UTF8Encoding]::new($true))
        Write-Host "Conservados: $($Conservar.Count) de $($Datos.Count)" -ForegroundColor Green
        return
    }
}
$Datos|Sort-Object generado -Descending|Select-Object -First $Ultimos|Select-Object paqueteId,consulta,nivel,caracteresUsados,resultados,version,generado
