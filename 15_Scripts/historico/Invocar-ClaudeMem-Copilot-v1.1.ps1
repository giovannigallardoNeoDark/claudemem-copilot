#Requires -Version 5.1
# VERSION 1.1.0 - FASE 4A
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Consulta,
    [ValidateSet(1,2,3)][int]$Nivel=2,
    [ValidateRange(500,16000)][int]$MaxCaracteres=5000,
    [ValidateSet('OBJETO','MARKDOWN','JSON','ARCHIVO')][string]$ModoSalida='OBJETO',
    [string]$RutaSalida='',
    [switch]$IncluirConfidencial,
    [switch]$OmitirAuditoriaPrevia
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Preparador=Join-Path $PSScriptRoot 'Preparar-Contexto-Copilot.ps1'
$Conversor=Join-Path $PSScriptRoot 'Convertir-Registro-Contexto-Legible.ps1'
foreach($Dependencia in @($Preparador,$Conversor)){
    if(-not(Test-Path -LiteralPath $Dependencia -PathType Leaf)){throw "Falta dependencia: $Dependencia"}
}
if(-not$OmitirAuditoriaPrevia){
    $Auditor=Join-Path $PSScriptRoot 'Auditar-Ranking-Contexto-ClaudeMem.ps1'
    if(-not(Test-Path -LiteralPath $Auditor -PathType Leaf)){throw "Falta auditor: $Auditor"}
    $global:LASTEXITCODE = 0
    $SalidaAuditoria = & $Auditor 2>&1
    $CodigoAuditoria = $LASTEXITCODE
    if ($null -eq $CodigoAuditoria) { $CodigoAuditoria = 0 }
    if ([int]$CodigoAuditoria -ne 0) {
        $DetalleAuditoria = @(
            $SalidaAuditoria |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        ) -join ' '
        throw "Auditoria previa fallida (codigo $CodigoAuditoria): $DetalleAuditoria"
    }
}
$Parametros=@{Consulta=$Consulta;Nivel=$Nivel;MaxCaracteres=$MaxCaracteres;RegistrarUso=$true}
if($IncluirConfidencial){$Parametros.IncluirConfidencial=$true}
$Contexto=&$Preparador @Parametros
$Legibles=@();foreach($Elemento in $Contexto.elementos){$Legibles+=@($Elemento|&$Conversor -MaxCaracteres $(if($Nivel-eq1){250}elseif($Nivel-eq2){700}else{2500}))}
$Lineas=@('# CONTEXTO OPERATIVO PARA COPILOT','',"Paquete: $($Contexto.paqueteId)","Consulta: $Consulta","Nivel: $Nivel","Presupuesto: $($Contexto.caracteresUsados)/$($Contexto.maxCaracteres)",'','## Antecedentes')
foreach($L in $Legibles){$Lineas+='';$Lineas+="### [$($L.tipo)] $($L.titulo)";$Lineas+="- ID: $($L.id)";$Lineas+="- Fuente: $($L.fuente)";$Lineas+="- Clasificacion: $($L.clasificacion)";$Lineas+="- Puntaje: $($L.puntaje)";$Lineas+='';$Lineas+=$L.cuerpo}
$Lineas+='';$Lineas+='## Reglas de uso';$Lineas+='- Priorizar conocimiento gobernado sobre observaciones episodicas.';$Lineas+='- Mantener ID y fuente al usar una afirmacion.';$Lineas+='- No promover memoria episodica sin aprobacion explicita.'
$Markdown=$Lineas-join[Environment]::NewLine
$Resultado=[pscustomobject][ordered]@{paqueteId=$Contexto.paqueteId;consulta=$Consulta;nivel=$Nivel;resultados=$Legibles.Count;caracteresUsados=$Contexto.caracteresUsados;elementos=$Legibles;markdown=$Markdown;version='1.0.0'}
if($ModoSalida-in@('ARCHIVO','JSON')-and[string]::IsNullOrWhiteSpace($RutaSalida)){throw 'RutaSalida es obligatoria para ARCHIVO o JSON.'}
switch($ModoSalida){
    'MARKDOWN' {$Markdown}
    'JSON' {[IO.File]::WriteAllText([IO.Path]::GetFullPath($RutaSalida),($Resultado|ConvertTo-Json -Depth 30),[Text.UTF8Encoding]::new($true));$Resultado}
    'ARCHIVO' {[IO.File]::WriteAllText([IO.Path]::GetFullPath($RutaSalida),$Markdown,[Text.UTF8Encoding]::new($true));$Resultado}
    default {$Resultado}
}
