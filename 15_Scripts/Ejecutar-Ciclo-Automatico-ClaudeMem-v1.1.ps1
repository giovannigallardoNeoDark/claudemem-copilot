#Requires -Version 5.1
# VERSION 1.1.0 - ORQUESTADOR AUTOMATICO
[CmdletBinding()]
param(
    [string]$NombreIteracion = 'VALIDACION-CONTINUA',
    [switch]$GenerarManifiesto,
    [switch]$RepararObservaciones,
    [switch]$AbrirInforme
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ScriptsRoot = $PSScriptRoot
$CopilotRoot = Split-Path -Parent $ScriptsRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$InformesRoot = Join-Path $ClaudeMemRoot 'diagnosticos'
$Sello = Get-Date -Format 'yyyyMMdd-HHmmss'
$Resultados = @()
New-Item -ItemType Directory -Path $InformesRoot -Force | Out-Null

function Agregar-Resultado {
    param([string]$Etapa,[string]$Estado,[string]$Detalle,[double]$Segundos)
    $script:Resultados += [pscustomobject][ordered]@{ etapa=$Etapa;estado=$Estado;detalle=$Detalle;segundos=[math]::Round($Segundos,2) }
}

function Ejecutar-Etapa {
    param([string]$Nombre,[string]$Script,[string[]]$Argumentos=@(),[switch]$Opcional)
    $Ruta = Join-Path $ScriptsRoot $Script
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){
        Agregar-Resultado $Nombre $(if($Opcional){'OMITIDA'}else{'FAIL'}) "No existe: $Script" 0
        return
    }
    $Inicio=Get-Date
    try{
        # Cada etapa corre en powershell.exe aislado. Esto impide heredar LASTEXITCODE
        # de herramientas nativas o scripts ejecutados en etapas anteriores.
        $Parametros=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Ruta)+$Argumentos
        $Salida=@(& powershell.exe @Parametros 2>&1)
        $Codigo=[int]$LASTEXITCODE
        $Texto=(($Salida|ForEach-Object{[string]$_})-join ' ') -replace '\s+',' '
        if($Texto.Length-gt700){$Texto=$Texto.Substring(0,700)+'...'}
        Agregar-Resultado $Nombre $(if($Codigo-eq0){'PASS'}else{'FAIL'}) "Codigo=$Codigo; $Texto" ((Get-Date)-$Inicio).TotalSeconds
    }catch{
        Agregar-Resultado $Nombre 'FAIL' $_.Exception.Message ((Get-Date)-$Inicio).TotalSeconds
    }
}

if($GenerarManifiesto){Ejecutar-Etapa 'Regenerar manifiesto' 'Generar-Manifiesto-ClaudeMem.ps1' @('-IncluirOpcionales')}

$ManifiestoRuta=Join-Path $ClaudeMemRoot 'config\manifiesto-componentes.json'
$InicioSintaxis=Get-Date;$ErroresSintaxis=@()
if(Test-Path -LiteralPath $ManifiestoRuta -PathType Leaf){
    try{
        $M=Get-Content -LiteralPath $ManifiestoRuta -Raw|ConvertFrom-Json -ErrorAction Stop
        foreach($C in @($M.componentes|Where-Object{$_.existe})){
            $RutaC=Join-Path $CopilotRoot ([string]$C.rutaRelativa)
            if(-not(Test-Path -LiteralPath $RutaC -PathType Leaf)){$ErroresSintaxis+="Faltante: $($C.nombre)";continue}
            $T=$null;$E=$null
            [void][Management.Automation.Language.Parser]::ParseFile($RutaC,[ref]$T,[ref]$E)
            if(@($E).Count){$ErroresSintaxis+="$($C.nombre): $(@($E).Count) error(es)"}
        }
        Agregar-Resultado 'Sintaxis componentes' $(if($ErroresSintaxis.Count-eq0){'PASS'}else{'FAIL'}) $(if($ErroresSintaxis.Count-eq0){'Sin errores'}else{$ErroresSintaxis-join'; '}) ((Get-Date)-$InicioSintaxis).TotalSeconds
    }catch{Agregar-Resultado 'Sintaxis componentes' 'FAIL' $_.Exception.Message ((Get-Date)-$InicioSintaxis).TotalSeconds}
}else{Agregar-Resultado 'Sintaxis componentes' 'FAIL' 'Manifiesto inexistente' 0}

if($RepararObservaciones){
    Ejecutar-Etapa 'Simular reparacion observaciones' 'Reparar-Observaciones-Operativas-ClaudeMem.ps1'
    $S=$Resultados[-1]
    if($S.estado-eq'PASS'-and$S.detalle-match'inconsistentes\s*:\s*[1-9]'){
        Ejecutar-Etapa 'Aplicar reparacion observaciones' 'Reparar-Observaciones-Operativas-ClaudeMem.ps1' @('-Aplicar')
    }
}

$Etapas=@(
    @('Prueba validacion observaciones','Prueba-Validacion-Observacion-ClaudeMem.ps1',@(),$true),
    @('Coherencia observaciones','Auditar-Coherencia-Observacion-ClaudeMem.ps1',@(),$false),
    @('Esquema observaciones','Auditar-Observacion-Operativa-ClaudeMem.ps1',@(),$false),
    @('Auditoria operativa','Auditar-Operacion-ClaudeMem.ps1',@(),$false),
    @('Auditoria puerta Copilot','Auditar-Puerta-Contexto-Copilot.ps1',@(),$false),
    @('Auditoria ranking','Auditar-Ranking-Contexto-ClaudeMem.ps1',@(),$false),
    @('Auditoria contexto','Auditar-Contexto-ClaudeMem.ps1',@(),$false),
    @('Auditoria esquema episodico','Auditar-Esquema-Memoria-Episodica-ClaudeMem.ps1',@(),$false),
    @('Auditoria memoria episodica','Auditar-Memoria-Episodica-ClaudeMem.ps1',@(),$false),
    @('Sincronizacion bidireccional','Sincronizar-Bidireccional-ClaudeMem.ps1',@('-Auditar'),$false),
    @('Diagnostico general','Diagnosticar-ClaudeMem-Potenciado.ps1',@('-GenerarInforme'),$false)
)
foreach($E in $Etapas){Ejecutar-Etapa -Nombre $E[0] -Script $E[1] -Argumentos $E[2] -Opcional:([bool]$E[3])}

$Fallidas=@($Resultados|Where-Object{$_.estado-eq'FAIL'}).Count
$Omitidas=@($Resultados|Where-Object{$_.estado-eq'OMITIDA'}).Count
$Aprobadas=@($Resultados|Where-Object{$_.estado-eq'PASS'}).Count
$Global=if($Fallidas){'BLOQUEADO'}elseif($Omitidas){'APROBADO_CON_OBSERVACIONES'}else{'APROBADO'}
$Informe=[pscustomobject][ordered]@{iteracion=$NombreIteracion;generado=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';aprobadas=$Aprobadas;omitidas=$Omitidas;fallidas=$Fallidas;resultadoGlobal=$Global;etapas=$Resultados}
$Json=Join-Path $InformesRoot "ciclo-automatico-$Sello.json";$Md=Join-Path $InformesRoot "ciclo-automatico-$Sello.md"
[IO.File]::WriteAllText($Json,($Informe|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($true))
$L=@('# Ciclo automatico ClaudeMem','',"Iteracion: $NombreIteracion","Resultado: $Global",'','| Estado | Etapa | Segundos | Detalle |','|---|---|---:|---|')
foreach($R in $Resultados){$D=([string]$R.detalle-replace'\|','/'-replace"`r?`n",' ');$L+="| $($R.estado) | $($R.etapa) | $($R.segundos) | $D |"}
[IO.File]::WriteAllLines($Md,[string[]]$L,[Text.UTF8Encoding]::new($true))
$Resultados|Select-Object estado,etapa,segundos|Format-Table -AutoSize
Write-Host "Aprobadas: $Aprobadas | Omitidas: $Omitidas | Fallidas: $Fallidas"
Write-Host "Informe JSON: $Json";Write-Host "Informe Markdown: $Md"
Write-Host "RESULTADO FINAL: $Global" -ForegroundColor $(if($Global-eq'APROBADO'){'Green'}elseif($Global-eq'BLOQUEADO'){'Red'}else{'Yellow'})
if($AbrirInforme){Start-Process -FilePath $Md}
if($Fallidas){exit 1}
