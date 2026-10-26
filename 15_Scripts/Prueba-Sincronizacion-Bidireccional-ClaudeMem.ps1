#Requires -Version 5.1

<#
.SYNOPSIS
    Prueba reversible de sincronizacion bidireccional ClaudeMem.

.DESCRIPTION
    Usa DECISION-001 de forma temporal, con respaldo integral y restauracion
    obligatoria en finally. Valida Markdown a JSON, JSON a Markdown y bloqueo
    de doble cambio. Al finalizar restablece los archivos originales y confirma
    7 coincidencias, 0 conflictos, 7 SIN_CAMBIOS y salud 100 %.

.VERSION
    1.1.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$ConocimientoRoot = Join-Path $CopilotRoot "03_Conocimiento"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$SyncFolder = Join-Path $ClaudeMemRoot "sync"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$ReportsFolder = Join-Path $ClaudeMemRoot "reports"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$TemporalFolder = Join-Path $BackupsFolder "prueba-sync-$MarcaTiempo"
$ReportFile = Join-Path $ReportsFolder "Reporte-Prueba-Sync-Bidireccional-$MarcaTiempo.txt"

$SyncScript = Join-Path $PSScriptRoot "Sincronizar-Bidireccional-ClaudeMem.ps1"
$AuditorConflictos = Join-Path $PSScriptRoot "Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1"
$AuditorRelaciones = Join-Path $PSScriptRoot "Auditar-Relaciones-ClaudeMem.ps1"
$AuditoriaSalud = Join-Path $PSScriptRoot "Auditoria-ClaudeMem-Salud.ps1"
$ReconstruirIndice = Join-Path $PSScriptRoot "Reconstruir-Indice-ClaudeMem.ps1"

$DecisionFile = Join-Path $DataFolder "decisiones.json"
$ManifestFile = Join-Path $SyncFolder "manifiesto-bidireccional.json"
$IndexFile = Join-Path $ClaudeMemRoot "index\index.json"
$RelacionesFile = Join-Path $DataFolder "relaciones.json"
$IdPrueba = "DECISION-001"
$MarkdownFile = @(Get-ChildItem -LiteralPath $ConocimientoRoot -Recurse -File -Filter "$IdPrueba.md" -ErrorAction Stop | Select-Object -First 1).FullName
$MarcaMarkdown = "PRUEBA-MD-$MarcaTiempo"
$MarcaJson = "PRUEBA-JSON-$MarcaTiempo"
$script:Resultados = @()

function Crear-Carpeta { param([string]$Ruta) if(-not(Test-Path -LiteralPath $Ruta -PathType Container)){New-Item -ItemType Directory -Path $Ruta -Force|Out-Null} }
function Registrar { param([string]$Prueba,[bool]$Ok,[string]$Detalle) $script:Resultados += [PSCustomObject]@{Estado=$(if($Ok){'PASS'}else{'FAIL'});Prueba=$Prueba;Detalle=$Detalle} }
function Leer-Json { param([string]$Ruta) Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop|ConvertFrom-Json -ErrorAction Stop }
function Lista { param([object]$Valor) $r=@();if($null-ne$Valor){if($Valor-is[Array]){foreach($x in $Valor){if($null-ne$x){$r+=$x}}}else{$r+=$Valor}};return $r }
function Guardar-Array { param([string]$Ruta,[array]$Datos) ConvertTo-Json -InputObject ([object[]]$Datos) -Depth 40|Set-Content -LiteralPath $Ruta -Encoding UTF8;$null=Leer-Json $Ruta }
function Obtener-Auditoria { & $SyncScript -Auditar|Out-Host; return $LASTEXITCODE }
function Obtener-Clases {
    # Write-Host utiliza el flujo Information (6) en Windows PowerShell 5.1.
    # Capturamos todos los flujos para evitar falsos FAIL en la validacion.
    $Salida = & $SyncScript -Auditar 6>&1 5>&1 4>&1 3>&1 2>&1 | Out-String
    return [string]$Salida
}

function Contar-Clase {
    param(
        [Parameter(Mandatory = $true)][string]$Salida,
        [Parameter(Mandatory = $true)][string]$Clase
    )

    $Patron = '(?m)^' + [regex]::Escape($Clase) + ':\s+(\d+)\s*$'
    $Coincidencia = [regex]::Match($Salida, $Patron)
    if (-not $Coincidencia.Success) { return -1 }
    return [int]$Coincidencia.Groups[1].Value
}

function Tiene-ClaseId {
    param(
        [Parameter(Mandatory = $true)][string]$Salida,
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Clase
    )

    $Patron = '(?m)^' + [regex]::Escape($Id) + '\s+\S+\s+' + [regex]::Escape($Clase) + '\s*$'
    return [regex]::IsMatch($Salida, $Patron)
}
function Validar-ConflictosCero {
    & $AuditorConflictos -Auditar|Out-Host
    $informe=@(Get-ChildItem -LiteralPath (Join-Path $ClaudeMemRoot 'exports\conflictos') -File -Filter 'Reporte-Conflictos-BibliotecaViva-ClaudeMem-*.json'|Sort-Object LastWriteTime -Descending)[0]
    $r=Leer-Json $informe.FullName
    return (@(Lista $r.hallazgos).Count -eq 0 -and @(Lista $r.coincidencias).Count -eq 7)
}
function Restaurar-Originales {
    foreach($Nombre in @('decisiones.json','manifest.json','index.json','relaciones.json','markdown.md')){
        $Origen=Join-Path $TemporalFolder $Nombre
        if(Test-Path -LiteralPath $Origen){
            $Destino=switch($Nombre){'decisiones.json'{$DecisionFile};'manifest.json'{$ManifestFile};'index.json'{$IndexFile};'relaciones.json'{$RelacionesFile};'markdown.md'{$MarkdownFile}}
            Copy-Item -LiteralPath $Origen -Destination $Destino -Force
        }
    }
}

Crear-Carpeta $TemporalFolder
Crear-Carpeta $ReportsFolder
Crear-Carpeta $LogsFolder

$Requisitos=@($SyncScript,$AuditorConflictos,$AuditorRelaciones,$AuditoriaSalud,$ReconstruirIndice,$DecisionFile,$ManifestFile,$IndexFile,$RelacionesFile,$MarkdownFile)
$Faltantes=@($Requisitos|Where-Object{-not(Test-Path -LiteralPath $_ -PathType Leaf)})
if($Faltantes.Count-gt0){throw "Faltan requisitos: $($Faltantes -join '; ')"}

Copy-Item $DecisionFile (Join-Path $TemporalFolder 'decisiones.json') -Force
Copy-Item $ManifestFile (Join-Path $TemporalFolder 'manifest.json') -Force
Copy-Item $IndexFile (Join-Path $TemporalFolder 'index.json') -Force
Copy-Item $RelacionesFile (Join-Path $TemporalFolder 'relaciones.json') -Force
Copy-Item $MarkdownFile (Join-Path $TemporalFolder 'markdown.md') -Force

try {
    $Inicial=Obtener-Clases
    Registrar 'Linea base inicial' ((Contar-Clase -Salida $Inicial -Clase 'SIN_CAMBIOS') -eq 7) '7 registros sin cambios'

    Add-Content -LiteralPath $MarkdownFile -Value "`r`n$MarcaMarkdown" -Encoding UTF8
    $AudMd=Obtener-Clases
    Registrar 'Detectar cambio solo Markdown' (Tiene-ClaseId -Salida $AudMd -Id $IdPrueba -Clase 'MARKDOWN_A_JSON') $MarcaMarkdown

    & $SyncScript -Sincronizar -Confirmar SINCRONIZAR|Out-Host
    if(-not $?){throw 'Fallo la sincronizacion Markdown a JSON.'}
    $Decisiones=@(Lista (Leer-Json $DecisionFile))
    $Decision=@($Decisiones|Where-Object{[string]$_.id-eq$IdPrueba})[0]
    $TextoDecision=($Decision|ConvertTo-Json -Depth 30 -Compress)
    Registrar 'Aplicar Markdown a JSON' ($TextoDecision -match [regex]::Escape($MarcaMarkdown)) 'Marca encontrada en JSON'

    $Decision.descripcion=[string]$Decision.descripcion+" $MarcaJson"
    Guardar-Array $DecisionFile $Decisiones
    $AudJson=Obtener-Clases
    Registrar 'Detectar cambio solo JSON' (Tiene-ClaseId -Salida $AudJson -Id $IdPrueba -Clase 'JSON_A_MARKDOWN') $MarcaJson

    & $SyncScript -Sincronizar -Confirmar SINCRONIZAR|Out-Host
    if(-not $?){throw 'Fallo la sincronizacion JSON a Markdown.'}
    $MarkdownActual=Get-Content -LiteralPath $MarkdownFile -Raw
    Registrar 'Aplicar JSON a Markdown' ($MarkdownActual -match [regex]::Escape($MarcaJson)) 'Marca encontrada en Markdown'

    Add-Content -LiteralPath $MarkdownFile -Value "`r`nDOBLE-MD-$MarcaTiempo" -Encoding UTF8
    $Decisiones=@(Lista (Leer-Json $DecisionFile))
    $Decision=@($Decisiones|Where-Object{[string]$_.id-eq$IdPrueba})[0]
    $Decision.descripcion=[string]$Decision.descripcion+" DOBLE-JSON-$MarcaTiempo"
    Guardar-Array $DecisionFile $Decisiones
    $AudDoble=Obtener-Clases
    Registrar 'Detectar doble cambio' (Tiene-ClaseId -Salida $AudDoble -Id $IdPrueba -Clase 'CONFLICTO_DOBLE_CAMBIO') 'Bloqueo detectado'

    $Proceso=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$SyncScript,'-Sincronizar','-Confirmar','SINCRONIZAR') -Wait -PassThru -WindowStyle Hidden
    Registrar 'Bloquear sincronizacion doble' ($Proceso.ExitCode -ne 0) "ExitCode=$($Proceso.ExitCode)"
}
catch {
    Registrar 'Ejecucion general' $false $_.Exception.Message
}
finally {
    Restaurar-Originales
    & $ReconstruirIndice|Out-Host
    & $AuditorRelaciones -Auditar|Out-Host
    $ConflictosOk=Validar-ConflictosCero
    $Final=Obtener-Clases
    $BaseOk=((Contar-Clase -Salida $Final -Clase 'SIN_CAMBIOS') -eq 7)
    & $AuditoriaSalud|Out-Host
    $SaludOk=$?
    Registrar 'Restaurar siete registros originales' ($ConflictosOk -and $BaseOk) '7 coincidencias, 0 conflictos, 7 sin cambios'
    Registrar 'Salud final' $SaludOk 'Auditoria ejecutada'
}

$Total=$script:Resultados.Count;$Aprobadas=@($script:Resultados|Where-Object{$_.Estado-eq'PASS'}).Count;$Fallidas=$Total-$Aprobadas;$Porcentaje=if($Total-gt0){[math]::Round(($Aprobadas/$Total)*100,2)}else{0};$EstadoFinal=if($Fallidas-eq0){'APROBADO'}else{'NO APROBADO'}
@("REPORTE PRUEBA SINCRONIZACION BIDIRECCIONAL","Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')","Estado: $EstadoFinal","Aprobadas: $Aprobadas","Fallidas: $Fallidas","Resultado: $Porcentaje %","")|Set-Content $ReportFile -Encoding UTF8
$script:Resultados|Format-Table Estado,Prueba,Detalle -AutoSize|Out-String|Add-Content $ReportFile -Encoding UTF8
Write-Host "";Write-Host 'RESULTADO PRUEBA SINCRONIZACION BIDIRECCIONAL' -ForegroundColor Cyan;$script:Resultados|Format-Table Estado,Prueba,Detalle -AutoSize;Write-Host "Aprobadas: $Aprobadas / $Total";Write-Host "Resultado: $Porcentaje %";Write-Host "Estado: $EstadoFinal";Write-Host "Informe: $ReportFile";Write-Host "Respaldo temporal: $TemporalFolder"
if($Fallidas-gt0){exit 1}
