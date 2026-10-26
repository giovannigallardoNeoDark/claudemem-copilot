#Requires -Version 5.1
# VERSION 1.2.0
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$Consulta,
 [ValidateRange(500,12000)][int]$MaxCaracteres=4000,
 [ValidateSet(1,2,3)][int]$Nivel=2,
 [switch]$IncluirConfidencial,
 [string]$ExportarJson=''
)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot;$CM=Join-Path $Root '11_Herramientas\ClaudeMem'
function Leer([string]$P){if(-not(Test-Path $P)){return @()};$R=Get-Content $P -Raw;if([string]::IsNullOrWhiteSpace($R)){return @()};$X=$R|ConvertFrom-Json;if($X-is[Array]){return @($X)};return @($X)}
function Palabras([string]$T){@([regex]::Matches($T.ToLowerInvariant(),'[a-záéíóúñ0-9]{3,}')|ForEach-Object{$_.Value}|Sort-Object -Unique)}
function Obtener-Propiedad {
    param(
        [AllowNull()][object]$Objeto,
        [Parameter(Mandatory=$true)][string[]]$Nombres,
        [string]$Predeterminado=''
    )
    if ($null -eq $Objeto) { return $Predeterminado }
    $Propiedades = @($Objeto.PSObject.Properties.Name)
    foreach ($Nombre in $Nombres) {
        if ($Propiedades -contains $Nombre) {
            $Valor = [string]$Objeto.$Nombre
            if (-not [string]::IsNullOrWhiteSpace($Valor)) { return $Valor }
        }
    }
    return $Predeterminado
}
$Q=Palabras $Consulta;$Items=@()
$Fuentes=@(
 @{tipo='decision';ruta='data\decisiones.json'},@{tipo='leccion';ruta='data\lecciones.json'},@{tipo='hallazgo';ruta='data\hallazgos.json'}
)
foreach ($FuenteDef in $Fuentes) {
    foreach ($Registro in (Leer (Join-Path $CM $FuenteDef.ruta))) {
        $Texto = $Registro | ConvertTo-Json -Depth 8 -Compress
        $Score = @($Q | Where-Object { $Texto.ToLowerInvariant() -match [regex]::Escape($_) }).Count
        if ($Score -gt 0) {
            $Id = Obtener-Propiedad -Objeto $Registro -Nombres @('id','registroId') -Predeterminado ("SIN-ID-{0}" -f ([guid]::NewGuid().ToString('N')))
            $Titulo = Obtener-Propiedad -Objeto $Registro -Nombres @('titulo','nombre','asunto') -Predeterminado $Id
            $Contenido = Obtener-Propiedad -Objeto $Registro -Nombres @('descripcion','contenido','detalle','resumen') -Predeterminado $Texto
            $Items += [PSCustomObject]@{
                tipo = [string]$FuenteDef.tipo
                id = $Id
                titulo = $Titulo
                contenido = $Contenido
                score = $Score
                fuente = [string]$FuenteDef.ruta
                clasificacion = 'INTERNO'
            }
        }
    }
}

foreach ($ResumenSesion in (Leer (Join-Path $CM 'episodios\resumenes.json'))) {
    $Texto = $ResumenSesion | ConvertTo-Json -Depth 15 -Compress
    $Score = @($Q | Where-Object { $Texto.ToLowerInvariant() -match [regex]::Escape($_) }).Count
    if ($Score -gt 0) {
        $Id = Obtener-Propiedad -Objeto $ResumenSesion -Nombres @('resumenId') -Predeterminado ("SIN-RESUMEN-{0}" -f ([guid]::NewGuid().ToString('N')))
        $Titulo = Obtener-Propiedad -Objeto $ResumenSesion -Nombres @('objetivo','titulo') -Predeterminado $Id
        $Items += [PSCustomObject]@{
            tipo = 'resumen_sesion'; id = $Id; titulo = $Titulo; contenido = $Texto
            score = $Score; fuente = 'episodios\resumenes.json'; clasificacion = 'INTERNO'
        }
    }
}

foreach ($Observacion in (Leer (Join-Path $CM 'episodios\observaciones.json'))) {
    $Clase = Obtener-Propiedad -Objeto $Observacion -Nombres @('clasificacion') -Predeterminado 'INTERNO'
    if ($Clase -in @('NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')) { continue }
    if ($Clase -in @('CONFIDENCIAL','RESTRINGIDO') -and -not $IncluirConfidencial) { continue }
    $Texto = Obtener-Propiedad -Objeto $Observacion -Nombres @('contenido','descripcion')
    if ([string]::IsNullOrWhiteSpace($Texto)) { continue }
    $Score = @($Q | Where-Object { $Texto.ToLowerInvariant() -match [regex]::Escape($_) }).Count
    if ($Score -gt 0) {
        $Id = Obtener-Propiedad -Objeto $Observacion -Nombres @('observacionId') -Predeterminado ("SIN-OBS-{0}" -f ([guid]::NewGuid().ToString('N')))
        $Items += [PSCustomObject]@{
            tipo = 'observacion'; id = $Id; titulo = 'Observacion episodica'; contenido = $Texto
            score = $Score; fuente = 'episodios\observaciones.json'; clasificacion = $Clase
        }
    }
}

$Seleccion = @(
    $Items |
    Sort-Object `
        @{ Expression = 'score'; Descending = $true }, `
        @{ Expression = 'id'; Descending = $false } |
    Group-Object id |
    ForEach-Object {
        $_.Group | Select-Object -First 1
    }
)
$Usados=@()
$Total=0
foreach($I in $Seleccion){$Costo=([string]$I.contenido).Length+([string]$I.titulo).Length+100;if($Total+$Costo-le$MaxCaracteres){$Usados+=$I;$Total+=$Costo}}
$Contexto=[pscustomobject][ordered]@{consulta=$Consulta;nivel=$Nivel;maxCaracteres=$MaxCaracteres;caracteresUsados=$Total;resultados=$Usados.Count;elementos=$Usados;advertencias=@($(if($Usados.Count-eq0){'No se encontro contexto relacionado'}));generado=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'}
if(-not[string]::IsNullOrWhiteSpace($ExportarJson)){$Json=$Contexto|ConvertTo-Json -Depth 30;[IO.File]::WriteAllText([IO.Path]::GetFullPath($ExportarJson),$Json,[Text.UTF8Encoding]::new($true))}
$Contexto
