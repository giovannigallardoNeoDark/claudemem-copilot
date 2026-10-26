#Requires -Version 5.1

<#
.SYNOPSIS
    Instala o actualiza los componentes funcionales de ClaudeMem.

.DESCRIPTION
    Crea copias de seguridad y reemplaza completamente:

    1. 11_Herramientas\ClaudeMem\ClaudeMem-Core.ps1
    2. 15_Scripts\Reconstruir-Indice-ClaudeMem.ps1
    3. 15_Scripts\Sincronizar-BibliotecaViva-ClaudeMem.ps1

    No requiere ejecutar manualmente funciones internas.
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

$CoreFile = Join-Path `
    $ClaudeMemRoot `
    "ClaudeMem-Core.ps1"

$IndiceScript = Join-Path `
    $PSScriptRoot `
    "Reconstruir-Indice-ClaudeMem.ps1"

$SincronizarScript = Join-Path `
    $PSScriptRoot `
    "Sincronizar-BibliotecaViva-ClaudeMem.ps1"

$CarpetaRespaldo = Join-Path `
    $ClaudeMemRoot `
    ("backups\actualizacion-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

# ============================================================
# FUNCIONES DEL ACTUALIZADOR
# ============================================================

function Crear-Carpeta {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Respaldar-Archivo {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (Test-Path -LiteralPath $Ruta -PathType Leaf) {
        Crear-Carpeta -Ruta $CarpetaRespaldo

        Copy-Item `
            -LiteralPath $Ruta `
            -Destination $CarpetaRespaldo `
            -Force

        Write-Host "[RESPALDO] $Ruta" -ForegroundColor DarkCyan
    }
}

function Escribir-ArchivoUTF8 {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta,

        [Parameter(Mandatory)]
        [string]$Contenido
    )

    $Directorio = Split-Path -Parent $Ruta
    Crear-Carpeta -Ruta $Directorio

    Set-Content `
        -LiteralPath $Ruta `
        -Value $Contenido `
        -Encoding UTF8

    Write-Host "[ACTUALIZADO] $Ruta" -ForegroundColor Green
}

# ============================================================
# VALIDAR ESTRUCTURA BASE
# ============================================================

Crear-Carpeta -Ruta $ClaudeMemRoot
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "data")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "data\papelera")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "config")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "index")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "logs")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "backups")
Crear-Carpeta -Ruta (Join-Path $ClaudeMemRoot "exports")

# ============================================================
# RESPALDAR VERSIONES ACTUALES
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " ACTUALIZACION FUNCIONAL DE CLAUDEMEM" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

Respaldar-Archivo -Ruta $CoreFile
Respaldar-Archivo -Ruta $IndiceScript
Respaldar-Archivo -Ruta $SincronizarScript

# ============================================================
# ARCHIVO 1: CLAUDEMEM-CORE.PS1
# ============================================================

$ContenidoCore = @'
#Requires -Version 5.1

<#
.SYNOPSIS
    Nucleo operativo de ClaudeMem.

.DESCRIPTION
    Permite registrar decisiones, lecciones y hallazgos,
    buscar memoria, reconstruir el indice, crear respaldos,
    consultar el estado, ver logs y sincronizar Biblioteca Viva.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ============================================================
# RUTAS
# ============================================================

$ClaudeMem = Split-Path -Parent $MyInvocation.MyCommand.Path
$HerramientasRoot = Split-Path -Parent $ClaudeMem
$CopilotRoot = Split-Path -Parent $HerramientasRoot

$DataFolder = Join-Path $ClaudeMem "data"
$IndexFolder = Join-Path $ClaudeMem "index"
$LogsFolder = Join-Path $ClaudeMem "logs"
$BackupsFolder = Join-Path $ClaudeMem "backups"

$EstadoFile = Join-Path $ClaudeMem "estado.json"
$ConfigFile = Join-Path $ClaudeMem "config\config.json"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"
$TagsFile = Join-Path $DataFolder "tags.json"
$RelacionesFile = Join-Path $DataFolder "relaciones.json"

$IndexFile = Join-Path $IndexFolder "index.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"

$ReconstruirIndiceScript = Join-Path `
    $CopilotRoot `
    "15_Scripts\Reconstruir-Indice-ClaudeMem.ps1"

$SincronizarBibliotecaScript = Join-Path `
    $CopilotRoot `
    "15_Scripts\Sincronizar-BibliotecaViva-ClaudeMem.ps1"

# ============================================================
# INICIALIZACION
# ============================================================

function Inicializar-ClaudeMem {
    $Carpetas = @(
        $DataFolder,
        (Join-Path $DataFolder "papelera"),
        $IndexFolder,
        $LogsFolder,
        $BackupsFolder,
        (Join-Path $ClaudeMem "config"),
        (Join-Path $ClaudeMem "exports")
    )

    foreach ($Carpeta in $Carpetas) {
        if (-not (Test-Path -LiteralPath $Carpeta)) {
            New-Item `
                -ItemType Directory `
                -Path $Carpeta `
                -Force |
            Out-Null
        }
    }

    $ArchivosArray = @(
        $DecisionesFile,
        $LeccionesFile,
        $HallazgosFile,
        $TagsFile,
        $RelacionesFile
    )

    foreach ($Archivo in $ArchivosArray) {
        if (-not (Test-Path -LiteralPath $Archivo)) {
            Set-Content `
                -LiteralPath $Archivo `
                -Value "[]" `
                -Encoding UTF8
        }
    }

    if (-not (Test-Path -LiteralPath $IndexFile)) {
        Set-Content `
            -LiteralPath $IndexFile `
            -Value "{}" `
            -Encoding UTF8
    }

    if (-not (Test-Path -LiteralPath $LogFile)) {
        New-Item `
            -ItemType File `
            -Path $LogFile `
            -Force |
        Out-Null
    }
}

# ============================================================
# FUNCIONES GENERALES
# ============================================================

function Escribir-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje
    )

    $Linea = "{0} - {1}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), `
        $Mensaje

    Add-Content `
        -LiteralPath $LogFile `
        -Value $Linea `
        -Encoding UTF8
}

function Leer-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw `
        -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($Contenido)) {
        return @()
    }

    try {
        $Datos = $Contenido | ConvertFrom-Json
        return @($Datos)
    }
    catch {
        throw "El archivo JSON no es valido: $Ruta. $($_.Exception.Message)"
    }
}

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Datos
    )

    $Temporal = "$Ruta.tmp"

    @($Datos) |
        ConvertTo-Json -Depth 30 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $Ruta `
        -Force
}

function Convertir-Lista {
    param(
        [AllowEmptyString()]
        [string]$Texto
    )

    if ([string]::IsNullOrWhiteSpace($Texto)) {
        return @()
    }

    return @(
        $Texto -split "," |
        ForEach-Object {
            $_.Trim()
        } |
        Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        } |
        Select-Object -Unique
    )
}

function Pausar-ClaudeMem {
    Write-Host ""
    [void](Read-Host "Presione Enter para continuar")
}

function Probar-IdExistente {
    param(
        [Parameter(Mandatory)]
        [string]$Id
    )

    $Archivos = @(
        $DecisionesFile,
        $LeccionesFile,
        $HallazgosFile
    )

    foreach ($Archivo in $Archivos) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Archivo)) {
            if ([string]$Registro.id -eq $Id) {
                return $true
            }
        }
    }

    return $false
}

function Solicitar-Id {
    param(
        [Parameter(Mandatory)]
        [string]$Prefijo
    )

    $Id = (Read-Host "ID, ejemplo $Prefijo-001").Trim().ToUpperInvariant()

    if ([string]::IsNullOrWhiteSpace($Id)) {
        throw "El ID no puede quedar vacio."
    }

    if ($Id -notmatch ("^" + [regex]::Escape($Prefijo) + "-[A-Z0-9_-]+$")) {
        throw "El ID debe comenzar con $Prefijo-."
    }

    if (Probar-IdExistente -Id $Id) {
        throw "El ID $Id ya existe."
    }

    return $Id
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
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            if ($Registro.id) {
                $Indice[[string]$Registro.id] = $Fuente.Tipo
            }
        }
    }

    $Temporal = "$IndexFile.tmp"

    $Indice |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $IndexFile `
        -Force

    Escribir-Log "INDICE RECONSTRUIDO: $($Indice.Count) entradas"

    return $Indice.Count
}

function Actualizar-Indice {
    try {
        $Cantidad = Reconstruir-IndiceInterno

        Write-Host ""
        Write-Host "Indice actualizado: $Cantidad entradas." -ForegroundColor Green
    }
    catch {
        Escribir-Log "ERROR AL ACTUALIZAR INDICE: $($_.Exception.Message)"
        throw
    }
}

# ============================================================
# TAGS Y RELACIONES
# ============================================================

function Actualizar-CatalogoTags {
    param(
        [AllowEmptyCollection()]
        [array]$NuevosTags
    )

    $Tags = @(Leer-JsonArray -Ruta $TagsFile)

    foreach ($Tag in @($NuevosTags)) {
        if (
            -not [string]::IsNullOrWhiteSpace([string]$Tag) -and
            $Tags -notcontains $Tag
        ) {
            $Tags += $Tag
        }
    }

    Guardar-JsonArray `
        -Ruta $TagsFile `
        -Datos @($Tags | Sort-Object -Unique)
}

function Registrar-RelacionesInternas {
    param(
        [Parameter(Mandatory)]
        [string]$Origen,

        [AllowEmptyCollection()]
        [array]$Destinos
    )

    $Relaciones = @(Leer-JsonArray -Ruta $RelacionesFile)

    foreach ($Destino in @($Destinos)) {
        if ([string]::IsNullOrWhiteSpace([string]$Destino)) {
            continue
        }

        $Existe = $Relaciones |
            Where-Object {
                $_.origen -eq $Origen -and
                $_.destino -eq $Destino
            } |
            Select-Object -First 1

        if (-not $Existe) {
            $Relaciones += [PSCustomObject]@{
                origen = $Origen
                destino = $Destino
                fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }

    Guardar-JsonArray `
        -Ruta $RelacionesFile `
        -Datos $Relaciones
}

# ============================================================
# REGISTROS
# ============================================================

function Registrar-Decision {
    Clear-Host

    Write-Host "REGISTRAR DECISION" -ForegroundColor Cyan
    Write-Host ""

    try {
        $Id = Solicitar-Id -Prefijo "DECISION"
        $Titulo = (Read-Host "Titulo").Trim()
        $Descripcion = (Read-Host "Descripcion").Trim()
        $Estado = (Read-Host "Estado [Propuesta/Validado/Obsoleto]").Trim()

        if ([string]::IsNullOrWhiteSpace($Titulo)) {
            throw "El titulo no puede quedar vacio."
        }

        if ([string]::IsNullOrWhiteSpace($Descripcion)) {
            throw "La descripcion no puede quedar vacia."
        }

        if ([string]::IsNullOrWhiteSpace($Estado)) {
            $Estado = "Propuesta"
        }

        $Tags = Convertir-Lista -Texto (Read-Host "Tags separados por coma")
        $Relacionados = Convertir-Lista -Texto (Read-Host "IDs relacionados separados por coma")

        $Nuevo = [PSCustomObject][ordered]@{
            id = $Id
            tipo = "decision"
            titulo = $Titulo
            descripcion = $Descripcion
            fecha = Get-Date -Format "yyyy-MM-dd"
            estado = $Estado
            tags = @($Tags)
            relacionados = @($Relacionados)
            origen = "ClaudeMem-Core"
            fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $Datos = @(Leer-JsonArray -Ruta $DecisionesFile)
        $Datos += $Nuevo

        Guardar-JsonArray `
            -Ruta $DecisionesFile `
            -Datos $Datos

        Actualizar-CatalogoTags -NuevosTags $Tags

        Registrar-RelacionesInternas `
            -Origen $Id `
            -Destinos $Relacionados

        Escribir-Log "DECISION CREADA: $Id"
        Actualizar-Indice

        Write-Host ""
        Write-Host "Decision registrada correctamente." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "No se pudo registrar la decision." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Escribir-Log "ERROR DECISION: $($_.Exception.Message)"
    }
}

function Registrar-Leccion {
    Clear-Host

    Write-Host "REGISTRAR LECCION" -ForegroundColor Cyan
    Write-Host ""

    try {
        $Id = Solicitar-Id -Prefijo "LECCION"
        $Problema = (Read-Host "Problema").Trim()
        $Solucion = (Read-Host "Solucion").Trim()

        if ([string]::IsNullOrWhiteSpace($Problema)) {
            throw "El problema no puede quedar vacio."
        }

        if ([string]::IsNullOrWhiteSpace($Solucion)) {
            throw "La solucion no puede quedar vacia."
        }

        $Tags = Convertir-Lista -Texto (Read-Host "Tags separados por coma")
        $Relacionados = Convertir-Lista -Texto (Read-Host "IDs relacionados separados por coma")

        $Nuevo = [PSCustomObject][ordered]@{
            id = $Id
            tipo = "leccion"
            problema = $Problema
            solucion = $Solucion
            fecha = Get-Date -Format "yyyy-MM-dd"
            estado = "Activa"
            tags = @($Tags)
            relacionados = @($Relacionados)
            origen = "ClaudeMem-Core"
            fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $Datos = @(Leer-JsonArray -Ruta $LeccionesFile)
        $Datos += $Nuevo

        Guardar-JsonArray `
            -Ruta $LeccionesFile `
            -Datos $Datos

        Actualizar-CatalogoTags -NuevosTags $Tags

        Registrar-RelacionesInternas `
            -Origen $Id `
            -Destinos $Relacionados

        Escribir-Log "LECCION CREADA: $Id"
        Actualizar-Indice

        Write-Host ""
        Write-Host "Leccion registrada correctamente." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "No se pudo registrar la leccion." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Escribir-Log "ERROR LECCION: $($_.Exception.Message)"
    }
}

function Registrar-Hallazgo {
    Clear-Host

    Write-Host "REGISTRAR HALLAZGO" -ForegroundColor Cyan
    Write-Host ""

    try {
        $Id = Solicitar-Id -Prefijo "HALLAZGO"
        $Titulo = (Read-Host "Titulo").Trim()
        $Descripcion = (Read-Host "Descripcion").Trim()
        $Estado = (Read-Host "Estado [Abierto/Corregido/Cerrado]").Trim()

        if ([string]::IsNullOrWhiteSpace($Descripcion)) {
            throw "La descripcion no puede quedar vacia."
        }

        if ([string]::IsNullOrWhiteSpace($Titulo)) {
            $Titulo = $Id
        }

        if ([string]::IsNullOrWhiteSpace($Estado)) {
            $Estado = "Abierto"
        }

        $Tags = Convertir-Lista -Texto (Read-Host "Tags separados por coma")
        $Relacionados = Convertir-Lista -Texto (Read-Host "IDs relacionados separados por coma")

        $Nuevo = [PSCustomObject][ordered]@{
            id = $Id
            tipo = "hallazgo"
            titulo = $Titulo
            descripcion = $Descripcion
            fecha = Get-Date -Format "yyyy-MM-dd"
            estado = $Estado
            tags = @($Tags)
            relacionados = @($Relacionados)
            origen = "ClaudeMem-Core"
            fechaCreacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        $Datos = @(Leer-JsonArray -Ruta $HallazgosFile)
        $Datos += $Nuevo

        Guardar-JsonArray `
            -Ruta $HallazgosFile `
            -Datos $Datos

        Actualizar-CatalogoTags -NuevosTags $Tags

        Registrar-RelacionesInternas `
            -Origen $Id `
            -Destinos $Relacionados

        Escribir-Log "HALLAZGO CREADO: $Id"
        Actualizar-Indice

        Write-Host ""
        Write-Host "Hallazgo registrado correctamente." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "No se pudo registrar el hallazgo." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Escribir-Log "ERROR HALLAZGO: $($_.Exception.Message)"
    }
}

# ============================================================
# BUSQUEDA
# ============================================================

function Buscar-Memoria {
    Clear-Host

    Write-Host "BUSCAR MEMORIA" -ForegroundColor Cyan
    Write-Host ""

    $Texto = (Read-Host "Texto a buscar").Trim()

    if ([string]::IsNullOrWhiteSpace($Texto)) {
        Write-Host "Debe ingresar un texto." -ForegroundColor Yellow
        return
    }

    $Patron = [regex]::Escape($Texto)
    $Resultados = @()

    $Fuentes = @(
        @{
            Ruta = $DecisionesFile
            Tipo = "Decision"
        },
        @{
            Ruta = $LeccionesFile
            Tipo = "Leccion"
        },
        @{
            Ruta = $HallazgosFile
            Tipo = "Hallazgo"
        }
    )

    foreach ($Fuente in $Fuentes) {
        foreach ($Registro in @(Leer-JsonArray -Ruta $Fuente.Ruta)) {
            $TextoRegistro = $Registro |
                ConvertTo-Json -Depth 30 -Compress

            if ($TextoRegistro -match $Patron) {
                $Titulo = ""

                if ($Registro.PSObject.Properties.Name -contains "titulo") {
                    $Titulo = [string]$Registro.titulo
                }
                elseif ($Registro.PSObject.Properties.Name -contains "problema") {
                    $Titulo = [string]$Registro.problema
                }
                elseif ($Registro.PSObject.Properties.Name -contains "descripcion") {
                    $Titulo = [string]$Registro.descripcion
                }

                $Resultados += [PSCustomObject]@{
                    Tipo = $Fuente.Tipo
                    ID = [string]$Registro.id
                    Resumen = $Titulo
                }
            }
        }
    }

    Write-Host ""

    if ($Resultados.Count -eq 0) {
        Write-Host "No se encontraron coincidencias." -ForegroundColor Yellow
    }
    else {
        $Resultados |
            Sort-Object Tipo, ID |
            Format-Table -AutoSize
    }

    Escribir-Log "BUSQUEDA '$Texto': $($Resultados.Count) coincidencias"
}

# ============================================================
# ESTADO, LOGS Y BACKUP
# ============================================================

function Mostrar-Estado {
    Clear-Host

    Write-Host "ESTADO CLAUDEMEM" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path -LiteralPath $EstadoFile)) {
        Write-Host "No existe estado.json." -ForegroundColor Yellow
        return
    }

    try {
        $Estado = Get-Content `
            -LiteralPath $EstadoFile `
            -Raw |
        ConvertFrom-Json

        $Estado |
            Format-List
    }
    catch {
        Write-Host "estado.json no contiene JSON valido." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

function Ver-Logs {
    Clear-Host

    Write-Host "ULTIMOS LOGS" -ForegroundColor Cyan
    Write-Host ""

    if (Test-Path -LiteralPath $LogFile) {
        Get-Content `
            -LiteralPath $LogFile `
            -Tail 30
    }
    else {
        Write-Host "No existe el archivo de logs." -ForegroundColor Yellow
    }
}

function Crear-Backup {
    Clear-Host

    Write-Host "CREAR BACKUP" -ForegroundColor Cyan
    Write-Host ""

    try {
        $Fecha = Get-Date -Format "yyyyMMdd-HHmmss"
        $BackupFile = Join-Path $BackupsFolder "backup-$Fecha.zip"

        $Elementos = @(
            $DataFolder,
            $IndexFolder,
            (Join-Path $ClaudeMem "config"),
            $EstadoFile,
            $LogFile
        ) |
        Where-Object {
            Test-Path -LiteralPath $_
        }

        if ($Elementos.Count -eq 0) {
            throw "No existen elementos para respaldar."
        }

        Compress-Archive `
            -LiteralPath $Elementos `
            -DestinationPath $BackupFile `
            -CompressionLevel Optimal `
            -Force

        $BackupValido = Test-Path `
            -LiteralPath $BackupFile `
            -PathType Leaf

        if (-not $BackupValido) {
            throw "El archivo ZIP no fue creado."
        }

        $Tamano = (Get-Item -LiteralPath $BackupFile).Length

        if ($Tamano -le 0) {
            throw "El archivo ZIP esta vacio."
        }

        Escribir-Log "BACKUP CREADO: $BackupFile"

        Write-Host "Backup creado correctamente." -ForegroundColor Green
        Write-Host $BackupFile
        Write-Host "Tamano: $Tamano bytes"
    }
    catch {
        Write-Host "No se pudo crear el backup." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Escribir-Log "ERROR BACKUP: $($_.Exception.Message)"
    }
}

function Sincronizar-BibliotecaViva {
    Clear-Host

    Write-Host "SINCRONIZAR BIBLIOTECA VIVA" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Path -LiteralPath $SincronizarBibliotecaScript)) {
        Write-Host "No existe el script de sincronizacion:" -ForegroundColor Red
        Write-Host $SincronizarBibliotecaScript
        return
    }

    try {
        & $SincronizarBibliotecaScript

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "El sincronizador termino con codigo $LASTEXITCODE."
        }

        Actualizar-Indice
        Escribir-Log "SINCRONIZACION BIBLIOTECA VIVA EJECUTADA"
    }
    catch {
        Write-Host "La sincronizacion fallo." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Escribir-Log "ERROR SINCRONIZACION: $($_.Exception.Message)"
    }
}

# ============================================================
# MENU
# ============================================================

Inicializar-ClaudeMem
Escribir-Log "CLAUDEMEM CORE INICIADO"

$Salir = $false

while (-not $Salir) {
    Clear-Host

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "             CLAUDEMEM CORE" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Registrar Decision"
    Write-Host "2. Registrar Leccion"
    Write-Host "3. Registrar Hallazgo"
    Write-Host "4. Buscar Memoria"
    Write-Host "5. Mostrar Estado"
    Write-Host "6. Crear Backup"
    Write-Host "7. Ver Logs"
    Write-Host "8. Reconstruir Indice"
    Write-Host "9. Sincronizar Biblioteca Viva"
    Write-Host "0. Salir"
    Write-Host ""

    $Opcion = (Read-Host "Seleccione una opcion").Trim()

    switch ($Opcion) {
        "1" {
            Registrar-Decision
            Pausar-ClaudeMem
        }

        "2" {
            Registrar-Leccion
            Pausar-ClaudeMem
        }

        "3" {
            Registrar-Hallazgo
            Pausar-ClaudeMem
        }

        "4" {
            Buscar-Memoria
            Pausar-ClaudeMem
        }

        "5" {
            Mostrar-Estado
            Pausar-ClaudeMem
        }

        "6" {
            Crear-Backup
            Pausar-ClaudeMem
        }

        "7" {
            Ver-Logs
            Pausar-ClaudeMem
        }

        "8" {
            Clear-Host

            try {
                Actualizar-Indice
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor Red
            }

            Pausar-ClaudeMem
        }

        "9" {
            Sincronizar-BibliotecaViva
            Pausar-ClaudeMem
        }

        "0" {
            $Salir = $true
        }

        default {
            Write-Host ""
            Write-Host "Opcion no valida." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}

Escribir-Log "CLAUDEMEM CORE CERRADO"

Write-Host ""
Write-Host "ClaudeMem finalizado." -ForegroundColor Green
Write-Host ""
'@

Escribir-ArchivoUTF8 `
    -Ruta $CoreFile `
    -Contenido $ContenidoCore

# ============================================================
# ARCHIVO 2: RECONSTRUIR-INDICE-CLAUDEMEM.PS1
# ============================================================

$ContenidoIndice = @'
#Requires -Version 5.1

<#
.SYNOPSIS
    Reconstruye el indice principal de ClaudeMem.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMem = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"

$DataFolder = Join-Path $ClaudeMem "data"
$IndexFolder = Join-Path $ClaudeMem "index"
$LogsFolder = Join-Path $ClaudeMem "logs"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"

$IndexFile = Join-Path $IndexFolder "index.json"
$LogFile = Join-Path $LogsFolder "claudemem.log"

function Crear-Carpeta {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Leer-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw

    if ([string]::IsNullOrWhiteSpace($Contenido)) {
        return @()
    }

    return @($Contenido | ConvertFrom-Json)
}

function Escribir-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Mensaje
    )

    $Linea = "{0} - {1}" -f `
        (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), `
        $Mensaje

    Add-Content `
        -LiteralPath $LogFile `
        -Value $Linea `
        -Encoding UTF8
}

Crear-Carpeta -Ruta $IndexFolder
Crear-Carpeta -Ruta $LogsFolder

if (-not (Test-Path -LiteralPath $LogFile)) {
    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force |
    Out-Null
}

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

try {
    foreach ($Fuente in $Fuentes) {
        $Registros = @(Leer-JsonArray -Ruta $Fuente.Ruta)

        foreach ($Registro in $Registros) {
            if ($Registro.id) {
                $Id = [string]$Registro.id

                if ($Indice.Contains($Id)) {
                    throw "ID duplicado detectado: $Id"
                }

                $Indice[$Id] = $Fuente.Tipo
            }
        }
    }

    $Temporal = "$IndexFile.tmp"

    $Indice |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $IndexFile `
        -Force

    Escribir-Log "INDICE RECONSTRUIDO: $($Indice.Count) entradas"

    Write-Host ""
    Write-Host "Indice reconstruido correctamente." -ForegroundColor Green
    Write-Host "Entradas: $($Indice.Count)"
    Write-Host "Archivo: $IndexFile"
    Write-Host ""

    Get-Content `
        -LiteralPath $IndexFile `
        -Raw
}
catch {
    Escribir-Log "ERROR INDICE: $($_.Exception.Message)"

    Write-Host ""
    Write-Host "No se pudo reconstruir el indice." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}
'@

Escribir-ArchivoUTF8 `
    -Ruta $IndiceScript `
    -Contenido $ContenidoIndice

# ============================================================
# ARCHIVO 3: SINCRONIZAR-BIBLIOTECAVIVA-CLAUDEMEM.PS1
# ============================================================

$ContenidoSincronizar = @'
#Requires -Version 5.1

<#
.SYNOPSIS
    Sincroniza documentos Markdown de Biblioteca Viva con ClaudeMem.

.DESCRIPTION
    Detecta carpetas de decisiones, lecciones y hallazgos
    dentro de 03_Conocimiento.

    Fusiona los registros importados con los registros existentes.
    No elimina los registros creados desde ClaudeMem-Core.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$CopilotRoot = Split-Path -Parent $PSScriptRoot

$ClaudeMem = Join-Path `
    $CopilotRoot `
    "11_Herramientas\ClaudeMem"

$ConocimientoRoot = Join-Path `
    $CopilotRoot `
    "03_Conocimiento"

$DataFolder = Join-Path $ClaudeMem "data"
$LogsFolder = Join-Path $ClaudeMem "logs"
$IndexFolder = Join-Path $ClaudeMem "index"

$DecisionesFile = Join-Path $DataFolder "decisiones.json"
$LeccionesFile = Join-Path $DataFolder "lecciones.json"
$HallazgosFile = Join-Path $DataFolder "hallazgos.json"
$TagsFile = Join-Path $DataFolder "tags.json"

$LogFile = Join-Path $LogsFolder "claudemem.log"

$ReconstruirIndiceScript = Join-Path `
    $PSScriptRoot `
    "Reconstruir-Indice-ClaudeMem.ps1"

function Crear-Carpeta {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        New-Item `
            -ItemType Directory `
            -Path $Ruta `
            -Force |
        Out-Null
    }
}

function Escribir-Log {
    param(
        [Parameter(Mandatory)]
        [string       -Value $Linea `
        -Encoding UTF8
}

function Leer-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta
    )

    if (-not (Test-Path -LiteralPath $Ruta)) {
        return @()
    }

    $Contenido = Get-Content `
        -LiteralPath $Ruta `
        -Raw

    if (:IsNullOrWhiteSpace($Contenido)) {
        return @()
    }

    return @($Contenido | ConvertFrom-Json)
}

function Guardar-JsonArray {
    param(
        [Parameter(Mandatory)]
        [string]$Ruta,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [array]$Datos
    )

    $Temporal = "$Ruta.tmp"

    @($Datos) |
        ConvertTo-Json -Depth 30 |
        Set-Content `
            -LiteralPath $Temporal `
            -Encoding UTF8

    Move-Item `
        -LiteralPath $Temporal `
        -Destination $Ruta `
        -Force
}

function Obtener-TituloMarkdown {
    param(
        [Parameter(Mandatory)]
        [string]$Contenido,

        [Parameter(Mandatory)]
        [string]$TituloAlternativo
    )

    $Coincidencia = :Match(
        $Contenido,
        "(?m)^\s*#\s+(.+?)\s*$"
    )

    if ($Coincidencia.Success) {
        return $Coincidencia.Groups[1].Value.Trim()
    }

    return $TituloAlternativo
}

function Obtener-ResumenMarkdown {
    param(
        [Parameter(Mandatory)]
        [string]$Contenido
    )

    $Lineas = @(
        $Contenido -split "`r?`n" |
        ForEach-Object {
            $_.Trim()
        } |
        Where-Object {
            -not :IsNullOrWhiteSpace($_) -and
            $_ -notmatch "^\s*#"
        }
    )

    $Resumen = ($Lineas -join " ").Trim()

    if ($Resumen.Length -gt 500) {
        $Resumen = $Resumen.Substring(0, 500)
    }

    return $Resumen
}

function Buscar-CarpetaTipo {
    param(
        [Parameter(Mandatory)]
        [string[]]$Patrones
    )

    $Carpetas = @(
        Get-ChildItem `
            -LiteralPath $ConocimientoRoot `
            -Directory `
            -Recurse `
            -ErrorAction SilentlyContinue
    )

    foreach ($Patron in $Patrones) {
        $Encontrada = $Carpetas |
            Where-Object {
                $_.Name -match $Patron
            } |
            Sort-Object FullName |
            Select-Object -First 1

        if ($Encontrada) {
            return $Encontrada.FullName
        }
    }

    return $null
}

function Fusionar-Markdown {
    param(
        [Parameter(Mandatory)]
        [string]$Tipo,

        [Parameter(Mandatory)]
        [string]$Prefijo,

        [Parameter(Mandatory)]
        [string[]]$PatronesCarpeta,

        [Parameter(Mandatory)]
        [string]$DestinoJson
    )

    $CarpetaOrigen = Buscar-CarpetaTipo `
        -Patrones $PatronesCarpeta

    if (-not $CarpetaOrigen) {
        Write-Host "No se encontro carpeta para $Tipo." -ForegroundColor Yellow
        Escribir-Log "SINCRONIZACION $Tipo: carpeta no encontrada"
        return 0
    }

    Write-Host ""
    Write-Host "$Tipo origen:" -ForegroundColor Cyan
    Write-Host $CarpetaOrigen

    $Archivos = @(
        Get-ChildItem `
            -LiteralPath $CarpetaOrigen `
            -Filter "$Prefijo-*.md" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue
    )

    if ($Archivos.Count -eq 0) {
        Write-Host "No existen archivos $Prefijo-*.md." -ForegroundColor Yellow
        Escribir-Log "SINCRONIZACION $Tipo: cero archivos"
        return 0
    }

    $Existentes = @(Leer-JsonArray -Ruta $DestinoJson)
    $Mapa = @{}

    foreach ($Registro in $Existentes) {
        if ($Registro.id) {
            $Mapa[[string]$Registro.id] = $Registro
        }
    }

    foreach ($Archivo in $Archivos) {
        $Contenido = Get-Content `
            -LiteralPath $Archivo.FullName `
            -Raw

        $Id = $Archivo.BaseName
        $Titulo = Obtener-TituloMarkdown `
            -Contenido $Contenido `
            -TituloAlternativo $Id

        $Resumen = Obtener-ResumenMarkdown `
            -Contenido $Contenido

        if ($Tipo -eq "decision") {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "decision"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Decision")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        elseif ($Tipo -eq "leccion") {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "leccion"
                problema = $Titulo
                solucion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Leccion")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        else {
            $Registro = [PSCustomObject][ordered]@{
                id = $Id
                tipo = "hallazgo"
                titulo = $Titulo
                descripcion = $Resumen
                fecha = $Archivo.LastWriteTime.ToString("yyyy-MM-dd")
                estado = "Sincronizado"
                tags = @("BibliotecaViva", "Hallazgo")
                relacionados = @()
                origen = $Archivo.FullName
                fechaSincronizacion = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }

        $Mapa[$Id] = $Registro
    }

    $Finales = @(
        $Mapa.Values |
        Sort-Object id
    )

    Guardar-JsonArray `
        -Ruta $DestinoJson `
        -Datos $Finales

    Write-Host "Procesados: $($Archivos.Count)" -ForegroundColor Green
    Escribir-Log "SINCRONIZACION $Tipo: $($Archivos.Count) archivos"

    return $Archivos.Count
}

# ============================================================
# EJECUCION
# ============================================================

Crear-Carpeta -Ruta $DataFolder
Crear-Carpeta -Ruta $LogsFolder
Crear-Carpeta -Ruta $IndexFolder

if (-not (Test-Path -LiteralPath $LogFile)) {
    New-Item `
        -ItemType File `
        -Path $LogFile `
        -Force |
    Out-Null
}

foreach ($ArchivoJson in @(
    $DecisionesFile,
    $LeccionesFile,
    $HallazgosFile,
    $TagsFile
)) {
    if (-not (Test-Path -LiteralPath $ArchivoJson)) {
        Set-Content `
            -LiteralPath $ArchivoJson `
            -Value "[]" `
            -Encoding UTF8
    }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " SINCRONIZAR BIBLIOTECA VIVA CON CLAUDEMEM" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $ConocimientoRoot)) {
    Write-Host "No existe la raiz de conocimiento:" -ForegroundColor Red
    Write-Host $ConocimientoRoot
    Escribir-Log "SINCRONIZACION FALLIDA: 03_Conocimiento no existe"
    exit 1
}

try {
    $TotalDecisiones = Fusionar-Markdown `
        -Tipo "decision" `
        -Prefijo "DECISION" `
        -PatronesCarpeta @(
            "^01_Decisiones$",
            "Decisiones"
        ) `
        -DestinoJson $DecisionesFile

    $TotalLecciones = Fusionar-Markdown `
        -Tipo "leccion" `
        -Prefijo "LECCION" `
        -PatronesCarpeta @(
            "^02_Lecciones_Aprendidas$",
            "Lecciones"
        ) `
        -DestinoJson $LeccionesFile

    $TotalHallazgos = Fusionar-Markdown `
        -Tipo "hallazgo" `
        -Prefijo "HALLAZGO" `
        -PatronesCarpeta @(
            "24_Base_Conocimiento_Viva",
            "Hallazgos",
            "Base_Conocimiento"
        ) `
        -DestinoJson $HallazgosFile

    $Total = $TotalDecisiones + $TotalLecciones + $TotalHallazgos

    if (Test-Path -LiteralPath $ReconstruirIndiceScript) {
        & $ReconstruirIndiceScript

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "La reconstruccion del indice termino con error."
        }
    }
    else {
        Write-Host ""
        Write-Host "Advertencia: no existe el reconstruidor de indice." -ForegroundColor Yellow
    }

    Escribir-Log "SINCRONIZACION COMPLETADA: $Total archivos"

    Write-Host ""
    Write-Host "Sincronizacion completada." -ForegroundColor Green
    Write-Host "Decisiones: $TotalDecisiones"
    Write-Host "Lecciones:  $TotalLecciones"
    Write-Host "Hallazgos:  $TotalHallazgos"
    Write-Host "Total:      $Total"
    Write-Host ""
}
catch {
    Escribir-Log "ERROR SINCRONIZACION: $($_.Exception.Message)"

    Write-Host ""
    Write-Host "La sincronizacion no pudo completarse." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""

    exit 1
}
'@

Escribir-ArchivoUTF8 `
    -Ruta $SincronizarScript `
    -Contenido $ContenidoSincronizar

# ============================================================
# VERIFICACION DE SINTAXIS
# ============================================================

Write-Host ""
Write-Host "Verificando sintaxis..." -ForegroundColor Cyan

$ArchivosParaValidar = @(
    $CoreFile,
    $IndiceScript,
    $SincronizarScript
)

$ErroresSintaxis = 0

foreach ($Archivo in $ArchivosParaValidar) {
    $Tokens = $null
    $Errores = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Archivo,
        [ref]$Tokens,
        [ref]$Errores
    )

    if ($Errores.Count -eq 0) {
        Write-Host "[SINTAXIS OK] $Archivo" -ForegroundColor Green
    }
    else {
        $ErroresSintaxis++

        Write-Host "[ERROR DE SINTAXIS] $Archivo" -ForegroundColor Red

        foreach ($ErrorSintaxis in $Errores) {
            Write-Host $ErrorSintaxis.Message -ForegroundColor Red
        }
    }
}

# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan

if ($ErroresSintaxis -eq 0) {
    Write-Host " ACTUALIZACION COMPLETADA CORRECTAMENTE" -ForegroundColor Green
}
else {
    Write-Host " ACTUALIZACION CON ERRORES DE SINTAXIS" -ForegroundColor Red
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Core:"
Write-Host $CoreFile
Write-Host ""
Write-Host "Reconstruccion de indice:"
Write-Host $IndiceScript
Write-Host ""
Write-Host "Sincronizacion:"
Write-Host $SincronizarScript
Write-Host ""
Write-Host "Respaldo de versiones anteriores:"
Write-Host $CarpetaRespaldo
Write-Host ""

if ($ErroresSintaxis -gt 0) {
    exit 1
}