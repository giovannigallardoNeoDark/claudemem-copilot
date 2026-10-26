#Requires -Version 5.1
# VERSION 1.1.0
[CmdletBinding()]
param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][object]$Registro,[ValidateRange(120,4000)][int]$MaxCaracteres=1200)
process {
 Set-StrictMode -Version Latest
 function Valor([object]$Objeto,[string[]]$Nombres,[string]$Predeterminado='') {if($null-eq$Objeto){return $Predeterminado};$P=@($Objeto.PSObject.Properties.Name);foreach($N in $Nombres){if($P-contains$N){$V=[string]$Objeto.$N;if(-not[string]::IsNullOrWhiteSpace($V)){return $V}}};return $Predeterminado}
 $Tipo=(Valor $Registro @('tipo') 'registro').ToLowerInvariant();$Id=Valor $Registro @('id','registroId','resumenId','observacionId') 'SIN-ID';$Titulo=Valor $Registro @('titulo','nombre','asunto','objetivo') $Id
 $FuenteSemantica=$Registro;$ContenidoCrudo=Valor $Registro @('contenido','contenidoNivel') ''
 if(-not[string]::IsNullOrWhiteSpace($ContenidoCrudo)){try{$J=ConvertFrom-Json -InputObject $ContenidoCrudo -ErrorAction Stop;if($null-ne$J){$FuenteSemantica=$J}}catch{}}
 switch($Tipo){
  'decision' {$Cuerpo=Valor $FuenteSemantica @('descripcion','decision','contenido','detalle') (Valor $Registro @('contenidoNivel','contenido') '')}
  'leccion' {$Problema=Valor $FuenteSemantica @('problema') ''; $Solucion=Valor $FuenteSemantica @('solucion') ''; $Resultado=Valor $FuenteSemantica @('resultado','resultadoEsperado','validacion') ''; $Partes=@();if($Problema){$Partes+="Problema: $Problema"};if($Solucion){$Partes+="Solucion: $Solucion"};if($Resultado){$Partes+="Resultado: $Resultado"};$Cuerpo=$Partes-join[Environment]::NewLine}
  'hallazgo' {$Cuerpo=Valor $FuenteSemantica @('descripcion','hallazgo','contenido','recomendacion','detalle') (Valor $Registro @('contenidoNivel','contenido') '')}
  default {$Cuerpo=Valor $Registro @('contenidoNivel','contenido','descripcion','detalle','resumen') ''}
 }
 if([string]::IsNullOrWhiteSpace($Cuerpo)){$Cuerpo=$FuenteSemantica|ConvertTo-Json -Depth 20 -Compress};if($Cuerpo.Length-gt$MaxCaracteres){$Cuerpo=$Cuerpo.Substring(0,$MaxCaracteres)+'...'}
 [pscustomobject][ordered]@{tipo=$Tipo;id=$Id;titulo=$Titulo;cuerpo=$Cuerpo;fuente=Valor $Registro @('fuente') '';clasificacion=Valor $Registro @('clasificacion') 'INTERNO';puntaje=Valor $Registro @('puntaje') '0'}
}
