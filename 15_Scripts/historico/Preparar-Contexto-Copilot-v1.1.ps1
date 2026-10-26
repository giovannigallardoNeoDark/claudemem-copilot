#Requires -Version 5.1
# VERSION 1.1.0
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
$Q=Palabras $Consulta;$Items=@()
$Fuentes=@(
 @{tipo='decision';ruta='data\decisiones.json'},@{tipo='leccion';ruta='data\lecciones.json'},@{tipo='hallazgo';ruta='data\hallazgos.json'}
)
foreach($F in $Fuentes){foreach($R in (Leer (Join-Path $CM $F.ruta))){$Texto=(($R|ConvertTo-Json -Depth 8 -Compress));$Score=@($Q|Where-Object{$Texto.ToLowerInvariant()-match[regex]::Escape($_)}).Count;if($Score-gt0){$Items+=[pscustomobject]@{tipo=$F.tipo;id=[string]$R.id;titulo=[string]$R.titulo;contenido=$(if($R.PSObject.Properties.Name-contains'descripcion'){[string]$R.descripcion}else{$Texto});score=$Score;fuente=$F.ruta;clasificacion='INTERNO'}}}}
foreach($R in (Leer (Join-Path $CM 'episodios\resumenes.json'))){$Texto=$R|ConvertTo-Json -Depth 15 -Compress;$Score=@($Q|Where-Object{$Texto.ToLowerInvariant()-match[regex]::Escape($_)}).Count;if($Score-gt0){$Items+=[pscustomobject]@{tipo='resumen_sesion';id=[string]$R.resumenId;titulo=[string]$R.objetivo;contenido=$Texto;score=$Score;fuente='episodios\resumenes.json';clasificacion='INTERNO'}}}
foreach($O in (Leer (Join-Path $CM 'episodios\observaciones.json'))){$Clase=[string]$O.clasificacion;if($Clase-eq'NO_CAPTURAR' -or $Clase-eq'NO_INDEXAR' -or $Clase-eq'NO_COMPARTIR'){continue};if($Clase-in@('CONFIDENCIAL','RESTRINGIDO')-and-not$IncluirConfidencial){continue};$Texto=[string]$O.contenido;$Score=@($Q|Where-Object{$Texto.ToLowerInvariant()-match[regex]::Escape($_)}).Count;if($Score-gt0){$Items+=[pscustomobject]@{tipo='observacion';id=[string]$O.observacionId;titulo='Observacion episodica';contenido=$Texto;score=$Score;fuente='episodios\observaciones.json';clasificacion=$Clase}}}
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
