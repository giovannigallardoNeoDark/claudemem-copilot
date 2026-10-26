#Requires -Version 5.1
# VERSION 1.0.0
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Consulta,[ValidateSet(1,2,3)][int]$Nivel=2,[int]$MaxCaracteres=5000,[string]$ExportarMarkdown='')
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Preparador=Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1'
$C=&$Preparador -Consulta $Consulta -Nivel $Nivel -MaxCaracteres $MaxCaracteres -RegistrarUso
$Lineas=@('# PAQUETE DE CONTEXTO PARA COPILOT','',"Consulta: $($C.consulta)","Nivel: $($C.nivel)","Presupuesto: $($C.caracteresUsados)/$($C.maxCaracteres)",'','## Antecedentes priorizados')
foreach($E in $C.elementos){$Lineas+='';$Lineas+="### [$($E.tipo)] $($E.titulo)";$Lineas+="- ID: $($E.id)";$Lineas+="- Puntaje: $($E.puntaje)";$Lineas+="- Fuente: $($E.fuente)";$Lineas+="- Clasificacion: $($E.clasificacion)";$Lineas+='';$Lineas+=[string]$E.contenidoNivel}
$Lineas+='';$Lineas+='## Restricciones';$Lineas+='- No promover contenido episodico sin aprobacion explicita.';$Lineas+='- Mantener trazabilidad de cada afirmacion.';$Lineas+='- No incluir contenido NO_CAPTURAR, NO_INDEXAR o NO_COMPARTIR.'
$Markdown=$Lineas-join[Environment]::NewLine
if(-not[string]::IsNullOrWhiteSpace($ExportarMarkdown)){[IO.File]::WriteAllText([IO.Path]::GetFullPath($ExportarMarkdown),$Markdown,[Text.UTF8Encoding]::new($true))}
[pscustomobject]@{paqueteId=$C.paqueteId;markdown=$Markdown;resultados=$C.resultados;caracteresUsados=$C.caracteresUsados}
