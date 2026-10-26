#Requires -Version 5.1
# VERSION 2.1.0 - FASE 3B
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Consulta,
    [ValidateRange(500,16000)][int]$MaxCaracteres=5000,
    [ValidateSet(1,2,3)][int]$Nivel=2,
    [switch]$IncluirConfidencial,
    [switch]$RegistrarUso,
    [string]$ExportarJson=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=Split-Path -Parent $PSScriptRoot
$CM=Join-Path $Root '11_Herramientas\ClaudeMem'

function Leer-Lista([string]$Ruta){
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){return @()}
    $Raw=Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop
    if([string]::IsNullOrWhiteSpace($Raw)){return @()}
    $X=ConvertFrom-Json -InputObject $Raw -ErrorAction Stop
    $Lista=@();foreach($E in $X){if($null-ne$E){$Lista+=$E}}
    return $Lista
}
function Prop([object]$O,[string[]]$N,[string]$D=''){
    if($null-eq$O){return $D};$P=@($O.PSObject.Properties.Name)
    foreach($Nombre in $N){if($P-contains$Nombre){$V=[string]$O.$Nombre;if(-not[string]::IsNullOrWhiteSpace($V)){return $V}}}
    return $D
}
function Tokens([string]$T){
    $Stop=@('para','con','del','las','los','una','uno','por','que','como','este','esta','desde','sobre')
    return @([regex]::Matches($T.ToLowerInvariant(),'[a-záéíóúñ0-9]{3,}')|ForEach-Object{$_.Value}|Where-Object{$_-notin$Stop}|Sort-Object -Unique)
}
function Calcular-Puntaje([string]$Tipo,[string]$Titulo,[string]$Contenido,[string]$Etiquetas,[string[]]$Terminos,[string]$Fecha){
    $Base=@{decision=40;leccion=30;hallazgo=24;resumen_sesion=18;observacion=12}[$Tipo]
    if($null-eq$Base){$Base=10}
    $P=[double]$Base
    foreach($T in $Terminos){
        if($Titulo.ToLowerInvariant()-match[regex]::Escape($T)){$P+=10}
        if($Etiquetas.ToLowerInvariant()-match[regex]::Escape($T)){$P+=6}
        if($Contenido.ToLowerInvariant()-match[regex]::Escape($T)){$P+=3}
    }
    [datetime]$FechaConvertida = [datetime]::MinValue
    $FechaValida = $false
    if (-not [string]::IsNullOrWhiteSpace($Fecha)) {
        try {
            $FechaConvertida = [datetime]::Parse($Fecha, [Globalization.CultureInfo]::InvariantCulture)
            $FechaValida = $true
        }
        catch {
            $FechaValida = $false
        }
    }
    if ($FechaValida) {
        $Dias = [math]::Max(0, ((Get-Date) - $FechaConvertida).TotalDays)
        $P += [math]::Max(0, 8 - ($Dias / 30))
    }
    return [math]::Round($P,2)
}
$Terminos=Tokens $Consulta
$Items=@()
$Defs=@(
    @{Tipo='decision';Ruta='data\decisiones.json'},
    @{Tipo='leccion';Ruta='data\lecciones.json'},
    @{Tipo='hallazgo';Ruta='data\hallazgos.json'},
    @{Tipo='resumen_sesion';Ruta='episodios\resumenes.json'},
    @{Tipo='observacion';Ruta='episodios\observaciones.json'}
)
foreach($D in $Defs){
    foreach($R in (Leer-Lista (Join-Path $CM $D.Ruta))){
        $Clase=Prop $R @('clasificacion') 'INTERNO'
        if($Clase-in@('NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR')){continue}
        if($Clase-in@('CONFIDENCIAL','RESTRINGIDO')-and-not$IncluirConfidencial){continue}
        $Id=Prop $R @('id','registroId','resumenId','observacionId') ''
        if([string]::IsNullOrWhiteSpace($Id)){continue}
        $Titulo=Prop $R @('titulo','nombre','asunto','objetivo') $Id
        $Contenido=Prop $R @('descripcion','contenido','detalle','resumen') ($R|ConvertTo-Json -Depth 20 -Compress)
        $Etiquetas=Prop $R @('etiquetas','tags','palabrasClave') ''
        $Fecha=Prop $R @('fecha','generado','actualizado','inicio') ''
        $Puntaje=Calcular-Puntaje $D.Tipo $Titulo $Contenido $Etiquetas $Terminos $Fecha
        $Coincidencias=@($Terminos|Where-Object{($Titulo+' '+$Etiquetas+' '+$Contenido).ToLowerInvariant()-match[regex]::Escape($_)})
        if($Coincidencias.Count-eq0){continue}
        $Items+=[pscustomobject][ordered]@{tipo=$D.Tipo;id=$Id;titulo=$Titulo;contenido=$Contenido;clasificacion=$Clase;fuente=$D.Ruta;fecha=$Fecha;puntaje=$Puntaje;coincidencias=$Coincidencias}
    }
}
$Ordenados=@($Items|Sort-Object @{Expression='puntaje';Descending=$true},@{Expression='id';Descending=$false}|Group-Object id|ForEach-Object{$_.Group|Select-Object -First 1})
$Usados=@();$Total=0
foreach($I in $Ordenados){
    $Texto=$(if($Nivel-eq1){$I.titulo}elseif($Nivel-eq2){$I.contenido.Substring(0,[math]::Min(600,$I.contenido.Length))}else{$I.contenido})
    $Costo=$Texto.Length+$I.titulo.Length+160
    if($Total+$Costo-le$MaxCaracteres){$I|Add-Member NoteProperty contenidoNivel $Texto -Force;$Usados+=$I;$Total+=$Costo}
}
$PaqueteId='CTX-'+(Get-Date -Format 'yyyyMMdd-HHmmssfff')
$Salida=[pscustomobject][ordered]@{paqueteId=$PaqueteId;consulta=$Consulta;nivel=$Nivel;maxCaracteres=$MaxCaracteres;caracteresUsados=$Total;resultados=$Usados.Count;elementos=$Usados;exclusionesAplicadas=@('NO_CAPTURAR','NO_INDEXAR','NO_COMPARTIR','CONFIDENCIAL_SIN_AUTORIZACION');version='2.0.0';generado=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'}
if($RegistrarUso){
    $RutaLog=Join-Path $CM 'episodios\contextos-usados.jsonl'
    $Linea=($Salida|Select-Object paqueteId,consulta,nivel,maxCaracteres,caracteresUsados,resultados,version,generado|ConvertTo-Json -Compress)
    Add-Content -LiteralPath $RutaLog -Value $Linea -Encoding UTF8
}
if(-not[string]::IsNullOrWhiteSpace($ExportarJson)){$Abs=[IO.Path]::GetFullPath($ExportarJson);[IO.File]::WriteAllText($Abs,($Salida|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($true))}
$Salida
