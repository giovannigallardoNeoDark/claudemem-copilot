#Requires -Version 5.1

<#
.SYNOPSIS
    Repara Sincronizar-BibliotecaViva-ClaudeMem.ps1.

.DESCRIPTION
    Este reparador:

    1. Detecta la raiz del ecosistema Copilot.
    2. Respalda el sincronizador existente.
    3. Genera un sincronizador nuevo y completo.
    4. Valida la sintaxis del archivo generado.
    5. Restaura el archivo anterior si la validacion falla.
    6. No ejecuta automaticamente la sincronizacion.

.VERSION
    3.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS DEL REPARADOR
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot

$ClaudeMemRoot = Join-Path `
    $CopilotRoot `
    "11_Herramientas\ClaudeMem"

$BackupsRoot = Join-Path `
    $ClaudeMemRoot `
    "backups"

$SincronizadorFile = Join-Path `
    $PSScriptRoot `
    "Sincronizar-BibliotecaViva-ClaudeMem.ps1"

$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$RespaldoFolder = Join-Path `
    $BackupsRoot `
    "reparacion-sincronizador-$MarcaTiempo"

$RespaldoFile = Join-Path `
    $RespaldoFolder `
    "Sincronizar-BibliotecaViva-ClaudeMem-anterior.ps1"

$TemporalFile = Join-Path `
    $PSScriptRoot `
    "Sincronizar-BibliotecaViva-ClaudeMem.nuevo.tmp"

# ============================================================
# FUNCIONES DEL REPARADOR
# ============================================================

function Crear-Carpeta {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Obtener-ErroresSintaxis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )

    $Tokens = $null
    $ErroresAnalisis = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Ruta,
        [ref]$Tokens,
        [ref]$ErroresAnalisis
    )

    return @($ErroresAnalisis)
}

function Mostrar-ErroresSintaxis {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Errores
    )

    foreach ($ErrorSintaxis in $Errores) {
        $Linea = 0
        $Columna = 0

        if ($null -ne $ErrorSintaxis.Extent) {
            $Linea = $ErrorSintaxis.Extent.StartLineNumber
            $Columna = $ErrorSintaxis.Extent.StartColumnNumber
        }

        Write-Host ""
        Write-Host $ErrorSintaxis.Message -ForegroundColor Red
        Write-Host (
            "Linea {0}, columna {1}" -f $Linea, $Columna
        ) -ForegroundColor Yellow
    }
}

# ============================================================
# ENCABEZADO
# ============================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host " REPARAR SINCRONIZADOR CLAUDEMEM" `
    -ForegroundColor Cyan
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host ""

# ============================================================
# VALIDACIONES PREVIAS
# ============================================================

if (-not (Test-Path -LiteralPath $ClaudeMemRoot -PathType Container)) {
    Write-Host "[ERROR] No existe ClaudeMem:" -ForegroundColor Red
    Write-Host $ClaudeMemRoot
    exit 1
}

Crear-Carpeta -Ruta $BackupsRoot
Crear-Carpeta -Ruta $RespaldoFolder

$ExistiaSincronizador = Test-Path `
    -LiteralPath $SincronizadorFile `
    -PathType Leaf

if ($ExistiaSincronizador) {
    Copy-Item `
        -LiteralPath $SincronizadorFile `
        -Destination $RespaldoFile `
        -Force

    Write-Host "[RESPALDO OK]" -ForegroundColor Green
    Write-Host $RespaldoFile
    Write-Host ""
}
else {
    Write-Host `
        "[AVISO] No existia un sincronizador anterior." `
        -ForegroundColor Yellow
    Write-Host ""
}

# ============================================================
# SINCRONIZADOR NUEVO
# ============================================================

$ContenidoSincronizador = @'
#Requires -Version 5.1

<#
.SYNOPSIS
    Sincroniza Biblioteca Viva con ClaudeMem.

.DESCRIPTION
    Busca recursivamente en 03_Conocimiento:

    - DECISION-*.md
    - LECCION-*.md
    - HALLAZGO-*.md

    Fusiona los documentos encontrados con los archivos JSON
    existentes de ClaudeMem.

    Antes de modificar los datos:
    - valida las rutas;
    - valida los JSON;
    - crea un respaldo ZIP;
    - conserva los registros existentes;
    - actualiza tags.json;
    - reconstruye index.json.

.VERSION
    1.0.0
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$CopilotRoot = Split-Path -Parent $PSScriptRoot

$ClaudeMemRoot = Join-Path `
    $CopilotRoot `
    "11_Herramientas\ClaudeMem"

$ConocimientoRoot = Join-Path `
    $CopilotRoot `
    "03_Conocimiento"

$DataFolder = Join-Path $ClaudeMemRoot "data"
$LogsFolder = Join-Path $ClaudeMemRoot "logs"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups"
$IndexFolder = Join-Path $ClaudeMemRoot "index"

$DecisionesFile = Join-Path `
    $DataFolder `
    "decisiones.json"

$LeccionesFile = Join-Path `
    $DataFolder `
    "lecciones.json"

$HallazgosFile = Join-Path `
    $DataFolder `
    "hallazgos.json"

$TagsFile = Join-Path `
    $DataFolder `
    "tags.json"

$LogFile = Join-Path `
    $LogsFolder `
    "claudemem.log"

$IndexFile = Join-Path `
    $IndexFolder `
    "index.json"

$ReconstruirIndiceScript = Join-Path `
    $PSScriptRoot `
    "Reconstruir-Indice-ClaudeMem.ps1"

# ============================================================
# FUNCIONES BASICAS
# ============================================================

function Crear-Carpeta {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Probar-TextoVacio {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Texto
    )

    if ($null -eq $Texto) {
        return $true
    }

    if ($Texto.Trim().Length -eq 0) {
        return $true
    }

    return $false
}

function Escribir-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mensaje
    )

    $Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Linea = "$Fecha - $Mensaje"

    Add-Content `
        -LiteralPath $LogFile `
        -Value $Linea `
        -Encoding UTF8
}

function Inicializar-ClaudeMem {
    $Carpetas = @(
        $ClaudeMemRoot,
        $DataFolder,
        $LogsFolder,
        $BackupsFolder,
        $IndexFolder
    )

    foreach ($Carpeta in $Carpetas) {
        Crear-Carpeta -Ruta $Carpeta
    }

    $ArchivosJson = @(
        $DecisionesFile,
        $LeccionesFile,
        $HallazgosFile,
        $TagsFile
    )

    foreach ($ArchivoJson in $ArchivosJson) {
        if (-not (Test-Path -LiteralPath $ArchivoJson -PathType Leaf)) {
            Set-Content `
                -LiteralPath $ArchivoJson `
                -Value "[]" `
                -Encoding UTF8
        }
    }

    if (-not (Test-Path -LiteralPath $IndexFile -PathType Leaf)) {
        Set-Content `
            -LiteralPath $IndexFile `
            -Value "{}" `
            -Encoding UTF8
    }

    if (-not (Test-Path -LiteralPath $LogFile -PathType Leaf)) {
        New-Item `
            -ItemType File `
            -Path $LogFile `
            -Force |
        Out-Null
    }
}

# ============================================================
# JSON
# ============================================================

function Leer-JsonArray {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw `
        -ErrorAction Stop

    if (Probar-TextoVacio -Texto $Contenido) {
        return @()
    }

    try {
        $Datos = $Contenido |
            ConvertFrom-Json `
                -ErrorAction Stop

        return @($Datos)
    }
    catch {
        throw "JSON invalido en '$Ruta': $($_.Exception.Message)"
    }
}

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Ruta,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$Datos
    )

    $Temporal = "$Ruta.tmp"
    $DatosSeguros = @($Datos)

    $DatosSeguros |
        ConvertTo-Json -Depth 30 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    try {
        $ContenidoTemporal = Get-Content `
            -LiteralPath $Temporal `
            -Raw `
            -ErrorAction Stop

        $null = $ContenidoTemporal |
            ConvertFrom-Json `
                -ErrorAction Stop
    }
    catch {
        Remove-Item `
            -LiteralPath $Temporal `
            -Force `
            -ErrorAction SilentlyContinue

        throw "No se genero JSON valido para '$Ruta'."
    }

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $Ruta `
        -Force
}

# ============================================================
# RESPALDO PREVIO
# ============================================================

function Crear-RespaldoPrevio {
    $Fecha = Get-Date -Format "yyyyMMdd-HHmmss"

    $BackupFile = Join-Path `
        $BackupsFolder `
        "pre-sincronizacion-$Fecha.zip"

    $Elementos = @()

    if (Test-Path -LiteralPath $DataFolder -PathType Container) {
        $Elementos += $DataFolder
    }

    if (Test-Path -LiteralPath $IndexFolder -PathType Container) {
        $Elementos += $IndexFolder
    }

    if (Test-Path -LiteralPath $LogFile -PathType Leaf) {
        $Elementos += $LogFile
    }

    $Elementos = @($Elementos)

    if ($Elementos.Count -eq 0) {
        throw "No existen datos para crear el respaldo."
    }

    Compress-Archive `
        -LiteralPath $Elementos `
        -DestinationPath $BackupFile `
        -CompressionLevel Optimal `
        -Force

    if (-not (Test-Path -LiteralPath $BackupFile -PathType Leaf)) {
        throw "El respaldo previo no fue creado."
    }

    $BackupItem = Get-Item `
        -LiteralPath $BackupFile `
        -ErrorAction Stop

    if ($BackupItem.Length -le 0) {
        throw "El respaldo previo fue creado sin contenido."
    }

    Escribir-Log "RESPALDO PRE-SINCRONIZACION: $BackupFile"

    return $BackupFile
}

# ============================================================
# MARKDOWN
# ============================================================

function Obtener-ArchivosMarkdown {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prefijo
    )

    if (-not (Test-Path -LiteralPath $ConocimientoRoot -PathType Container)) {
        return @()
    }

    $Archivos = @(
        Get-ChildItem `
            -LiteralPath $ConocimientoRoot `
            -File `
            -Recurse `
            -Filter "$Prefijo-*.md" `
            -ErrorAction SilentlyContinue
    )

    return @($Archivos)
}

function Obtener-TituloMarkdown {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Contenido,

        [Parameter(Mandatory = $true)]
        [string]$TituloAlternativo
    )

    if (Probar-TextoVacio -Texto $Contenido) {
        return $TituloAlternativo
    }

    $Lineas = @($Contenido -split "`r?`n")

    foreach ($Linea in $Lineas) {
        if ($Linea -match "^\s*#\s+(.+?)\s*$") {
            return $Matches[1].Trim()
        }
    }

    return $TituloAlternativo
}

function Obtener-ResumenMarkdown {
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Contenido
    )

    if (Probar-TextoVacio -Texto $Contenido) {
        return ""
    }

    $LineasValidas = @(
        $Contenido -split "`r?`n" |
        ForEach-Object {
            $_.Trim()
        } |
        Where-Object {
            $_.Length -gt 0 -and
            $_ -notmatch "^\s*#"
        }
    )

    $Resumen = ($LineasValidas -join " ").Trim()

    if ($Resumen.Length -gt 1000) {
        $Resumen = $Resumen.Substring(0, 1000)
    }

    return $Resumen
}

# ============================================================
# TAGS
# ============================================================

function Actualizar-Tags {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$NuevosTags
    )

    $TagsActuales = @(
        Leer-JsonArray `
            -Ruta $TagsFile
    )

    foreach ($Tag in @($NuevosTags)) {
        if (Probar-TextoVacio -Texto $Tag) {
            continue
        }

        if ($TagsActuales -notcontains $Tag) {
            $TagsActuales += $Tag
        }
    }

    $TagsFinales = @(
        $TagsActuales |
        Sort-Object -Unique
    )

    Guardar-JsonArray `
        -Ruta $TagsFile `
        -Datos $TagsFinales
}

# ============================================================
# SINCRONIZACION
# ============================================================

function Sincronizar-Tipo {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("decision", "leccion", "hallazgo")]
        [string]$Tipo,

        [Parameter(Mandatory = $true)]
        [string]$Prefijo,

        [Parameter(Mandatory = $true)]
        [string]$DestinoJson
    )

    Write-Host ""
    Write-Host "Procesando $Tipo..." -ForegroundColor Cyan

    $Archivos = @(
        Obtener-ArchivosMarkdown `
            -Prefijo $Prefijo
    )

    $CantidadArchivos = @($Archivos).Count

    if ($CantidadArchivos -eq 0) {
        Write-Host `
            "No se encontraron archivos $Prefijo-*.md." `
            -ForegroundColor Yellow

        Escribir-Log `
            "SINCRONIZACION ${Tipo}: cero archivos"

        return 0
    }

    $RegistrosExistentes = @(
        Leer-JsonArray `
            -Ruta $DestinoJson
    )

    $Mapa = @{}

    foreach ($RegistroExistente in $RegistrosExistentes) {
        if ($null -eq $RegistroExistente) {
            continue
        }

        $Propiedades = @(
            $RegistroExistente.PSObject.Properties.Name
        )

        if ($Propiedades -notcontains "id") {
            continue
        }

        $IdExistente = [string]$RegistroExistente.id

        if (Probar-TextoVacio -Texto $IdExistente) {
            continue
        }

        $Mapa[$IdExistente] = $RegistroExistente
    }

    foreach ($Archivo in $Archivos) {
        $Contenido = Get-Content `
            -LiteralPath $Archivo.FullName `
            -Raw `
            -ErrorAction Stop

        if ($null -eq $Contenido) {
            $Contenido = ""
        }

        $Id = $Archivo.BaseName

        $Titulo = Obtener-TituloMarkdown `
            -Contenido $Contenido `
            -TituloAlternativo $Id

        $Resumen = Obtener-ResumenMarkdown `
            -Contenido $Contenido

        if ($Tipo -eq "decision") {
            $RegistroNuevo = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "decision"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @(
                    "BibliotecaViva",
                    "Decision"
                )
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            $TagTipo = "Decision"
        }
        elseif ($Tipo -eq "leccion") {
            $RegistroNuevo = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "leccion"
                problema = $Titulo
                solucion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @(
                    "BibliotecaViva",
                    "Leccion"
                )
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            $TagTipo = "Leccion"
        }
        else {
            $RegistroNuevo = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "hallazgo"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @(
                    "BibliotecaViva",
                    "Hallazgo"
                )
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }

            $TagTipo = "Hallazgo"
        }

        $Mapa[$Id] = $RegistroNuevo
    }

    $RegistrosFinales = @(
        $Mapa.Values |
        Sort-Object id
    )

    Guardar-JsonArray `
        -Ruta $DestinoJson `
        -Datos $RegistrosFinales

    Actualizar-Tags `
        -NuevosTags @(
            "BibliotecaViva",
            $TagTipo
        )

    Write-Host `
        "Archivos procesados: $CantidadArchivos" `
        -ForegroundColor Green

    Escribir-Log `
        "SINCRONIZACION ${Tipo}: $CantidadArchivos archivos"

    return [int]$CantidadArchivos
}

# ============================================================
# INDICE
# ============================================================

function Reconstruir-IndiceInterno {
    $Indice = [ordered]@{}

    $Fuentes = @(
        @{
            Ruta = $DecisionesFile
            Tipo = "decision"
        },
        @{
            Ruta = $LeccionesFile
            Tipo = "leccion"
        },
        @{
            Ruta = $HallazgosFile
            Tipo = "hallazgo"
        }
    )

    foreach ($Fuente in $Fuentes) {
        $Registros = @(
            Leer-JsonArray `
                -Ruta $Fuente.Ruta
        )

        foreach ($Registro in $Registros) {
            if ($null -eq $Registro) {
                continue
            }

            $Propiedades = @(
                $Registro.PSObject.Properties.Name
            )

            if ($Propiedades -notcontains "id") {
                continue
            }

            $Id = [string]$Registro.id

            if (Probar-TextoVacio -Texto $Id) {
                continue
            }

            if ($Indice.Contains($Id)) {
                throw "ID duplicado detectado: $Id"
            }

            $Indice[$Id] = $Fuente.Tipo
        }
    }

    $Temporal = "$IndexFile.tmp"

    $Indice |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    $ContenidoTemporal = Get-Content `
        -LiteralPath $Temporal `
        -Raw `
        -ErrorAction Stop

    $null = $ContenidoTemporal |
        ConvertFrom-Json `
            -ErrorAction Stop

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $IndexFile `
        -Force

    Escribir-Log `
        "INDICE RECONSTRUIDO: $($Indice.Count) entradas"

    Write-Host ""
    Write-Host `
        "Indice reconstruido: $($Indice.Count) entradas." `
        -ForegroundColor Green
}

function Reconstruir-IndiceFinal {
    if (Test-Path -LiteralPath $ReconstruirIndiceScript -PathType Leaf) {
        Write-Host ""
        Write-Host "Reconstruyendo indice..." -ForegroundColor Cyan

        try {
            & $ReconstruirIndiceScript

            if ($?) {
                return
            }
        }
        catch {
            Write-Host `
                "El reconstruidor externo fallo." `
                -ForegroundColor Yellow
            Write-Host $_.Exception.Message -ForegroundColor Yellow
        }

        Write-Host `
            "Se utilizara el reconstruidor interno." `
            -ForegroundColor Yellow
    }

    Reconstruir-IndiceInterno
}

# ============================================================
# EJECUCION PRINCIPAL
# ============================================================

Inicializar-ClaudeMem

Write-Host ""
Write-Host "================================================" `
    -ForegroundColor Cyan
Write-Host " SINCRONIZAR BIBLIOTECA VIVA CON CLAUDEMEM" `
    -ForegroundColor Cyan
Write-Host "================================================" `
    -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $ConocimientoRoot -PathType Container)) {
    Write-Host "No existe la raiz de conocimiento:" `
        -ForegroundColor Red
    Write-Host $ConocimientoRoot

    Escribir-Log `
        "SINCRONIZACION FALLIDA: no existe 03_Conocimiento"

    exit 1
}

try {
    $Respaldo = Crear-RespaldoPrevio

    Write-Host "Respaldo previo creado:" -ForegroundColor Green
    Write-Host $Respaldo

    $TotalDecisiones = Sincronizar-Tipo `
        -Tipo "decision" `
        -Prefijo "DECISION" `
        -DestinoJson $DecisionesFile

    $TotalLecciones = Sincronizar-Tipo `
        -Tipo "leccion" `
        -Prefijo "LECCION" `
        -DestinoJson $LeccionesFile

    $TotalHallazgos = Sincronizar-Tipo `
        -Tipo "hallazgo" `
        -Prefijo "HALLAZGO" `
        -DestinoJson $HallazgosFile

    $TotalProcesado = (
        [int]$TotalDecisiones +
        [int]$TotalLecciones +
        [int]$TotalHallazgos
    )

    Reconstruir-IndiceFinal

    Escribir-Log `
        "SINCRONIZACION COMPLETADA: $TotalProcesado archivos"

    Write-Host ""
    Write-Host "================================================" `
        -ForegroundColor Green
    Write-Host " SINCRONIZACION COMPLETADA" `
        -ForegroundColor Green
    Write-Host "================================================" `
        -ForegroundColor Green
    Write-Host ""
    Write-Host "Decisiones: $TotalDecisiones"
    Write-Host "Lecciones:  $TotalLecciones"
    Write-Host "Hallazgos:  $TotalHallazgos"
    Write-Host "Total:      $TotalProcesado"
    Write-Host ""
}
catch {
    $MensajeError = $_.Exception.Message

    try {
        Escribir-Log "ERROR SINCRONIZACION: $MensajeError"
    }
    catch {
        Write-Host `
            "No se pudo registrar el error en el log." `
            -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "La sincronizacion no pudo completarse." `
        -ForegroundColor Red
    Write-Host $MensajeError -ForegroundColor Red
    Write-Host ""
    Write-Host "Revise los respaldos disponibles en:" `
        -ForegroundColor Yellow
    Write-Host $BackupsFolder
    Write-Host ""

    exit 1
}
'@

# ============================================================
# ESCRIBIR PRIMERO EN ARCHIVO TEMPORAL
# ============================================================

try {
    Set-Content `
        -LiteralPath $TemporalFile `
        -Value $ContenidoSincronizador `
        -Encoding UTF8
}
catch {
    Write-Host "[ERROR] No se pudo crear el archivo temporal." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# ============================================================
# VALIDAR ARCHIVO TEMPORAL
# ============================================================

Write-Host "Validando sintaxis del nuevo sincronizador..." `
    -ForegroundColor Cyan

$ErroresNuevoArchivo = @(
    Obtener-ErroresSintaxis `
        -Ruta $TemporalFile
)

if ($ErroresNuevoArchivo.Count -gt 0) {
    Write-Host ""
    Write-Host "====================================================" `
        -ForegroundColor Red
    Write-Host " REPARACION CANCELADA" `
        -ForegroundColor Red
    Write-Host "====================================================" `
        -ForegroundColor Red

    Mostrar-ErroresSintaxis `
        -Errores $ErroresNuevoArchivo

    Remove-Item `
        -LiteralPath $TemporalFile `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host `
        "El sincronizador existente no fue reemplazado." `
        -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ============================================================
# INSTALAR SINCRONIZADOR VALIDADO
# ============================================================

try {
    Move-Item `
        -LiteralPath $TemporalFile `
        -Destination $SincronizadorFile `
        -Force
}
catch {
    Write-Host ""
    Write-Host "[ERROR] No se pudo instalar el sincronizador." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    if (
        $ExistiaSincronizador -and
        (Test-Path -LiteralPath $RespaldoFile -PathType Leaf)
    ) {
        Copy-Item `
            -LiteralPath $RespaldoFile `
            -Destination $SincronizadorFile `
            -Force

        Write-Host `
            "La version anterior fue restaurada." `
            -ForegroundColor Yellow
    }

    exit 1
}

# ============================================================
# SEGUNDA VALIDACION DEL ARCHIVO INSTALADO
# ============================================================

$ErroresArchivoInstalado = @(
    Obtener-ErroresSintaxis `
        -Ruta $SincronizadorFile
)

if ($ErroresArchivoInstalado.Count -gt 0) {
    Write-Host ""
    Write-Host `
        "[ERROR] El archivo instalado no supero la validacion." `
        -ForegroundColor Red

    Mostrar-ErroresSintaxis `
        -Errores $ErroresArchivoInstalado

    if (
        $ExistiaSincronizador -and
        (Test-Path -LiteralPath $RespaldoFile -PathType Leaf)
    ) {
        Copy-Item `
            -LiteralPath $RespaldoFile `
            -Destination $SincronizadorFile `
            -Force

        Write-Host ""
        Write-Host `
            "La version anterior fue restaurada." `
            -ForegroundColor Yellow
    }

    exit 1
}

# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Green
Write-Host " REPARACION COMPLETADA" `
    -ForegroundColor Green
Write-Host "====================================================" `
    -ForegroundColor Green
Write-Host ""
Write-Host "[SINTAXIS OK]" -ForegroundColor Green
Write-Host $SincronizadorFile
Write-Host ""
Write-Host "Respaldo de la version anterior:"
Write-Host $RespaldoFolder
Write-Host ""
Write-Host "Siguiente comando:" -ForegroundColor Cyan
Write-Host ".\Sincronizar-BibliotecaViva-ClaudeMem.ps1"
Write-Host ""