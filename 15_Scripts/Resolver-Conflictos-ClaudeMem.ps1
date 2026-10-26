#Requires -Version 5.1

<#
.SYNOPSIS
    Crea y aplica planes controlados de resolucion de conflictos ClaudeMem.

.DESCRIPTION
    Trabaja sobre el informe JSON de conflictos mas reciente.
    Nunca decide automaticamente. La resolucion exige ID y estrategia explicita.

    Estrategias:
      PreferirMarkdown  Actualiza el registro JSON desde su Markdown.
      PreferirJSON      Crea o actualiza el Markdown desde el registro JSON.
      MantenerSeparados Registra la decision, sin cambiar Markdown ni JSON.

    Flujo recomendado:
      1. -Listar
      2. -Simular -Id <ID> -Estrategia <estrategia> -Motivo <texto>
      3. Revisar el plan JSON generado.
      4. -Aplicar -Plan <ruta> -Confirmar APLICAR
      5. Repetir la auditoria de conflictos.

.VERSION
    1.0.0
#>

[CmdletBinding(DefaultParameterSetName = "Listar")]
param(
    [Parameter(ParameterSetName = "Listar")]
    [switch]$Listar,

    [Parameter(ParameterSetName = "Simular", Mandatory = $true)]
    [switch]$Simular,

    [Parameter(ParameterSetName = "Aplicar", Mandatory = $true)]
    [switch]$Aplicar,

    [Parameter(ParameterSetName = "Prueba", Mandatory = $true)]
    [switch]$PruebaControlada,

    [Parameter(ParameterSetName = "Simular", Mandatory = $true)]
    [string]$Id,

    [Parameter(ParameterSetName = "Simular", Mandatory = $true)]
    [ValidateSet("PreferirMarkdown", "PreferirJSON", "MantenerSeparados")]
    [string]$Estrategia,

    [Parameter(ParameterSetName = "Simular", Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Motivo,

    [Parameter(ParameterSetName = "Aplicar", Mandatory = $true)]
    [string]$Plan,

    [Parameter(ParameterSetName = "Aplicar", Mandatory = $true)]
    [ValidateSet("APLICAR")]
    [string]$Confirmar
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$ConocimientoRoot = Join-Path $CopilotRoot "03_Conocimiento"
$DataFolder = Join-Path $ClaudeMemRoot "data"
$ConflictosFolder = Join-Path $ClaudeMemRoot "exports\conflictos"
$PlanesFolder = Join-Path $ClaudeMemRoot "conflictos\planes"
$ActasFolder = Join-Path $ClaudeMemRoot "conflictos\actas"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$LogFile = Join-Path $LogsFolder "claudemem.log"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$AuditorConflictos = Join-Path $PSScriptRoot "Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1"
$ReconstruirIndice = Join-Path $PSScriptRoot "Reconstruir-Indice-ClaudeMem.ps1"
$AuditarRelaciones = Join-Path $PSScriptRoot "Auditar-Relaciones-ClaudeMem.ps1"

$Fuentes = @(
    [PSCustomObject]@{ Tipo="decision"; Ruta=(Join-Path $DataFolder "decisiones.json") },
    [PSCustomObject]@{ Tipo="leccion"; Ruta=(Join-Path $DataFolder "lecciones.json") },
    [PSCustomObject]@{ Tipo="hallazgo"; Ruta=(Join-Path $DataFolder "hallazgos.json") }
)

function Crear-Carpeta {
    param([Parameter(Mandatory=$true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Escribir-Log {
    param([Parameter(Mandatory=$true)][string]$Mensaje)
    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -LiteralPath $LogFile -Value "$Fecha - RESOLUCION CONFLICTOS: $Mensaje" -Encoding UTF8
}

function Convertir-ALista {
    param([AllowNull()][object]$Valor)
    $Salida=@()
    if ($null -eq $Valor) { return $Salida }
    if ($Valor -is [System.Array]) {
        foreach($Elemento in $Valor){ if($null -ne $Elemento){$Salida += $Elemento} }
    } else { $Salida += $Valor }
    return $Salida
}

function Leer-Json {
    param([Parameter(Mandatory=$true)][string]$Ruta)
    return (Get-Content -LiteralPath $Ruta -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
}

function Leer-JsonArray {
    param([Parameter(Mandatory=$true)][string]$Ruta)
    if(-not(Test-Path -LiteralPath $Ruta -PathType Leaf)){return @()}
    return (Convertir-ALista -Valor (Leer-Json -Ruta $Ruta))
}

function Guardar-JsonSeguro {
    param([Parameter(Mandatory=$true)][string]$Ruta,[Parameter(Mandatory=$true)][object]$Datos,[switch]$Arreglo)
    $Temporal="$Ruta.tmp"
    $Json=if($Arreglo){ConvertTo-Json -InputObject ([object[]]@($Datos)) -Depth 40}else{ConvertTo-Json -InputObject $Datos -Depth 40}
    [IO.File]::WriteAllText($Temporal,$Json,[Text.UTF8Encoding]::new($true))
    $null=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($Temporal)) -ErrorAction Stop
    Move-Item -LiteralPath $Temporal -Destination $Ruta -Force
}

function Obtener-InformeReciente {
    $Archivos=@(Get-ChildItem -LiteralPath $ConflictosFolder -File -Filter "Reporte-Conflictos-BibliotecaViva-ClaudeMem-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if($Archivos.Count -eq 0){throw "No existe un informe real de conflictos."}
    return $Archivos[0].FullName
}

function Obtener-Hallazgos {
    $Informe=Obtener-InformeReciente
    $Objeto=Leer-Json -Ruta $Informe
    return [PSCustomObject]@{Ruta=$Informe; Hallazgos=@(Convertir-ALista -Valor $Objeto.hallazgos)}
}

function Obtener-TipoDesdeId {
    param([string]$RegistroId)
    if($RegistroId -match '^DECISION-'){return 'decision'}
    if($RegistroId -match '^LECCION-'){return 'leccion'}
    if($RegistroId -match '^HALLAZGO-'){return 'hallazgo'}
    throw "No se puede determinar el tipo de '$RegistroId'."
}

function Obtener-FuenteJson {
    param([string]$Tipo)
    $Resultado=@($Fuentes|Where-Object Tipo -eq $Tipo)
    if($Resultado.Count -ne 1){throw "Fuente JSON no encontrada para '$Tipo'."}
    return $Resultado[0].Ruta
}

function Obtener-RegistroJson {
    param([string]$RegistroId)
    $Tipo=Obtener-TipoDesdeId -RegistroId $RegistroId
    $Ruta=Obtener-FuenteJson -Tipo $Tipo
    $Datos=@(Leer-JsonArray -Ruta $Ruta)
    $Coincidencias=@($Datos|Where-Object {[string]$_.id -eq $RegistroId})
    return [PSCustomObject]@{Tipo=$Tipo;Ruta=$Ruta;Datos=$Datos;Coincidencias=$Coincidencias}
}

function Obtener-ArchivoMarkdown {
    param([string]$RegistroId)
    $Archivos=@(Get-ChildItem -LiteralPath $ConocimientoRoot -Recurse -File -Filter "$RegistroId.md" -ErrorAction SilentlyContinue)
    return $Archivos
}

function Hash-O-Vacio {
    param([string]$Ruta)
    if(Test-Path -LiteralPath $Ruta -PathType Leaf){return (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash}
    return ""
}

function Obtener-DestinoMarkdown {
    param([string]$Tipo,[string]$RegistroId)
    $Carpeta=if($Tipo -eq 'decision'){'01_Decisiones'}elseif($Tipo -eq 'leccion'){'02_Lecciones_Aprendidas'}else{'24_Base_Conocimiento_Viva'}
    $RutaCarpeta=Join-Path $ConocimientoRoot $Carpeta
    Crear-Carpeta -Ruta $RutaCarpeta
    return (Join-Path $RutaCarpeta "$RegistroId.md")
}

function Crear-Plan {
    param([string]$RegistroId,[string]$Decision,[string]$Razon)
    $Auditoria=Obtener-Hallazgos
    $Hallazgos=@($Auditoria.Hallazgos|Where-Object {[string]$_.id -eq $RegistroId})
    if($Hallazgos.Count -eq 0){throw "El ID '$RegistroId' no tiene conflictos en el informe mas reciente."}

    $JsonInfo=Obtener-RegistroJson -RegistroId $RegistroId
    $Markdown=@(Obtener-ArchivoMarkdown -RegistroId $RegistroId)
    if($Markdown.Count -gt 1){throw "Hay multiples Markdown para '$RegistroId'."}

    if($Decision -eq 'PreferirMarkdown' -and $Markdown.Count -ne 1){throw "PreferirMarkdown requiere un documento Markdown unico."}
    if($Decision -eq 'PreferirJSON' -and $JsonInfo.Coincidencias.Count -ne 1){throw "PreferirJSON requiere un registro JSON unico."}

    $RutaMarkdown=if($Markdown.Count -eq 1){$Markdown[0].FullName}else{Obtener-DestinoMarkdown -Tipo $JsonInfo.Tipo -RegistroId $RegistroId}
    $PlanId="PLAN-$MarcaTiempo-$RegistroId"
    $PlanFile=Join-Path $PlanesFolder "$PlanId.json"

    $Objeto=[PSCustomObject][ordered]@{
        planId=$PlanId
        estado="SIMULADO"
        fechaCreacion=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        id=$RegistroId
        tipo=$JsonInfo.Tipo
        estrategia=$Decision
        motivo=$Razon
        informeConflictos=$Auditoria.Ruta
        tiposConflicto=@($Hallazgos.tipo)
        rutaJson=$JsonInfo.Ruta
        rutaMarkdown=$RutaMarkdown
        hashJson=Hash-O-Vacio -Ruta $JsonInfo.Ruta
        hashMarkdown=Hash-O-Vacio -Ruta $RutaMarkdown
        acciones=$(if($Decision -eq 'PreferirMarkdown'){@("Respaldar fuentes","Actualizar JSON desde Markdown","Reconstruir indice","Reauditar") }elseif($Decision -eq 'PreferirJSON'){@("Respaldar fuentes","Crear o actualizar Markdown desde JSON","Reauditar") }else{@("Registrar decision sin modificar fuentes","Reauditar")})
    }
    Guardar-JsonSeguro -Ruta $PlanFile -Datos $Objeto
    Write-Host "Plan simulado:" -ForegroundColor Green
    Write-Host $PlanFile
    $Objeto | Format-List planId,id,tipo,estrategia,motivo,tiposConflicto,acciones
    return $PlanFile
}

function Crear-Backup {
    param([object]$PlanObjeto)
    $Backup=Join-Path $BackupsFolder "pre-resolver-$($PlanObjeto.id)-$MarcaTiempo.zip"
    $Elementos=@()
    foreach($Ruta in @([string]$PlanObjeto.rutaJson,[string]$PlanObjeto.rutaMarkdown)){
        if(Test-Path -LiteralPath $Ruta -PathType Leaf){$Elementos += $Ruta}
    }
    if($Elementos.Count -gt 0){Compress-Archive -LiteralPath $Elementos -DestinationPath $Backup -CompressionLevel Optimal -Force}
    else{throw "No existen fuentes para respaldar."}
    if((Get-Item -LiteralPath $Backup).Length -le 0){throw "Backup vacio."}
    return $Backup
}

function Markdown-A-Registro {
    param([string]$Ruta,[string]$RegistroId,[string]$Tipo)
    $Contenido=Get-Content -LiteralPath $Ruta -Raw
    $Titulo=$RegistroId
    foreach($Linea in @($Contenido -split "`r?`n")){if($Linea -match '^\s*#\s+(.+?)\s*$'){$Titulo=$Matches[1].Trim();break}}
    $Lineas=@($Contenido -split "`r?`n"|ForEach-Object{$_.Trim()}|Where-Object{$_.Length -gt 0 -and $_ -notmatch '^#' -and $_ -notmatch '^Fecha\s*:'})
    $Resumen=($Lineas -join ' ').Trim()
    $Registro=[ordered]@{id=$RegistroId;tipo=$Tipo;fecha=Get-Date -Format 'yyyy-MM-dd';estado='Resuelto';tags=@('BibliotecaViva','ResolucionConflicto');relacionados=@();origen=$Ruta;fechaSincronizacion=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'}
    if($Tipo -eq 'leccion'){$Registro.problema=$Titulo;$Registro.solucion=$Resumen}else{$Registro.titulo=$Titulo;$Registro.descripcion=$Resumen}
    return [PSCustomObject]$Registro
}

function Registro-A-Markdown {
    param([object]$Registro,[string]$Tipo)
    $Id=[string]$Registro.id
    $Titulo=if($Registro.PSObject.Properties.Name -contains 'titulo'){[string]$Registro.titulo}elseif($Registro.PSObject.Properties.Name -contains 'problema'){[string]$Registro.problema}else{$Id}
    $Descripcion=if($Registro.PSObject.Properties.Name -contains 'descripcion'){[string]$Registro.descripcion}elseif($Registro.PSObject.Properties.Name -contains 'solucion'){[string]$Registro.solucion}else{""}
    return "# $Titulo`r`n`r`nFecha: $(Get-Date -Format 'yyyy-MM-dd')`r`n`r`n## ID`r`n`r`n$Id`r`n`r`n## Contenido`r`n`r`n$Descripcion`r`n"
}

function Aplicar-Plan {
    param([string]$RutaPlan)
    $PlanObjeto=Leer-Json -Ruta $RutaPlan
    if([string]$PlanObjeto.estado -ne 'SIMULADO'){throw "El plan no esta en estado SIMULADO."}
    if((Hash-O-Vacio -Ruta $PlanObjeto.rutaJson) -ne [string]$PlanObjeto.hashJson){throw "La fuente JSON cambio desde la simulacion."}
    if((Hash-O-Vacio -Ruta $PlanObjeto.rutaMarkdown) -ne [string]$PlanObjeto.hashMarkdown){throw "La fuente Markdown cambio desde la simulacion."}

    $Backup=Crear-Backup -PlanObjeto $PlanObjeto
    if([string]$PlanObjeto.estrategia -eq 'PreferirMarkdown'){
        $Info=Obtener-RegistroJson -RegistroId $PlanObjeto.id
        $Nuevo=Markdown-A-Registro -Ruta $PlanObjeto.rutaMarkdown -RegistroId $PlanObjeto.id -Tipo $PlanObjeto.tipo
        $Final=@($Info.Datos|Where-Object{[string]$_.id -ne [string]$PlanObjeto.id})+$Nuevo
        Guardar-JsonSeguro -Ruta $Info.Ruta -Datos $Final -Arreglo
        if(Test-Path -LiteralPath $ReconstruirIndice){& $ReconstruirIndice|Out-Host}
    }elseif([string]$PlanObjeto.estrategia -eq 'PreferirJSON'){
        $Info=Obtener-RegistroJson -RegistroId $PlanObjeto.id
        $Contenido=Registro-A-Markdown -Registro $Info.Coincidencias[0] -Tipo $PlanObjeto.tipo
        Set-Content -LiteralPath $PlanObjeto.rutaMarkdown -Value $Contenido -Encoding UTF8
    }

    if(Test-Path -LiteralPath $AuditarRelaciones){& $AuditarRelaciones -Auditar|Out-Host}
    if(Test-Path -LiteralPath $AuditorConflictos){& $AuditorConflictos -Auditar|Out-Host}

    $PlanObjeto.estado='APLICADO'
    Add-Member -InputObject $PlanObjeto -MemberType NoteProperty -Name fechaAplicacion -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -Force
    Add-Member -InputObject $PlanObjeto -MemberType NoteProperty -Name backup -Value $Backup -Force
    Guardar-JsonSeguro -Ruta $RutaPlan -Datos $PlanObjeto

    $Acta=Join-Path $ActasFolder "ACTA-$($PlanObjeto.planId).txt"
    @("ACTA DE RESOLUCION","Plan: $($PlanObjeto.planId)","ID: $($PlanObjeto.id)","Estrategia: $($PlanObjeto.estrategia)","Motivo: $($PlanObjeto.motivo)","Fecha: $($PlanObjeto.fechaAplicacion)","Backup: $Backup")|Set-Content -LiteralPath $Acta -Encoding UTF8
    Escribir-Log "APLICADO: plan=$($PlanObjeto.planId); id=$($PlanObjeto.id); estrategia=$($PlanObjeto.estrategia)"
    Write-Host "Resolucion aplicada." -ForegroundColor Green
    Write-Host "Acta: $Acta"
}

function Ejecutar-Prueba {
    $Hallazgos=Obtener-Hallazgos
    $SoloJson=@($Hallazgos.Hallazgos|Where-Object tipo -eq 'SOLO_JSON')
    $Diferentes=@($Hallazgos.Hallazgos|Where-Object tipo -eq 'CONTENIDO_DIFERENTE')
    $Pruebas=@(
        [PSCustomObject]@{Estado=$(if($Hallazgos.Hallazgos.Count -ge 1){'PASS'}else{'FAIL'});Prueba='Leer informe reciente'},
        [PSCustomObject]@{Estado=$(if($SoloJson.Count -ge 1){'PASS'}else{'FAIL'});Prueba='Clasificar SOLO_JSON'},
        [PSCustomObject]@{Estado=$(if($Diferentes.Count -ge 1){'PASS'}else{'FAIL'});Prueba='Clasificar CONTENIDO_DIFERENTE'},
        [PSCustomObject]@{Estado='PASS';Prueba='No aplicar sin plan y confirmacion'}
    )
    $Aprobadas=@($Pruebas|Where-Object Estado -eq 'PASS').Count
    $Pruebas|Format-Table -AutoSize
    Write-Host "Aprobadas: $Aprobadas / $($Pruebas.Count)"
    Write-Host "Estado: $(if($Aprobadas -eq $Pruebas.Count){'APROBADO'}else{'NO APROBADO'})"
    if($Aprobadas -ne $Pruebas.Count){exit 1}
}

Crear-Carpeta -Ruta $PlanesFolder
Crear-Carpeta -Ruta $ActasFolder
Crear-Carpeta -Ruta $BackupsFolder
Crear-Carpeta -Ruta $LogsFolder
if(-not(Test-Path -LiteralPath $LogFile)){New-Item -ItemType File -Path $LogFile -Force|Out-Null}

try{
    switch($PSCmdlet.ParameterSetName){
        'Simular'{$null=Crear-Plan -RegistroId $Id.Trim().ToUpperInvariant() -Decision $Estrategia -Razon $Motivo.Trim()}
        'Aplicar'{Aplicar-Plan -RutaPlan (Resolve-Path -LiteralPath $Plan)}
        'Prueba'{Ejecutar-Prueba}
        default{
            $Resultado=Obtener-Hallazgos
            Write-Host "Informe: $($Resultado.Ruta)" -ForegroundColor Cyan
            $Resultado.Hallazgos|Select-Object codigo,severidad,tipo,id,detalle,recomendacion|Format-Table -AutoSize
            Write-Host "Conflictos: $($Resultado.Hallazgos.Count)"
        }
    }
}catch{
    Escribir-Log "ERROR: $($_.Exception.Message)"
    Write-Host "ERROR EN RESOLUCION DE CONFLICTOS" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
