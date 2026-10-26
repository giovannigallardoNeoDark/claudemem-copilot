#Requires -Version 5.1

<#
.SYNOPSIS
    Corrige el falso error de sincronizacion en ClaudeMem-Core.ps1.

.DESCRIPTION
    Sustituye la comprobacion basada en LASTEXITCODE por una
    comprobacion directa del resultado del script PowerShell.

    El proceso:
    1. Crea respaldo del Core.
    2. Localiza el bloque defectuoso.
    3. Genera una copia temporal corregida.
    4. Valida la sintaxis.
    5. Instala la correccion.
    6. Restaura el respaldo si algo falla.
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

$BackupsFolder = Join-Path `
    $ClaudeMemRoot `
    "backups"

$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupFile = Join-Path `
    $BackupsFolder `
    "ClaudeMem-Core-antes-retorno-$MarcaTiempo.ps1"

$TemporalFile = "$CoreFile.tmp"

# ============================================================
# FUNCIONES
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
    $Errores = $null

    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Ruta,
        [ref]$Tokens,
        [ref]$Errores
    )

    return @($Errores)
}

function Mostrar-ErroresSintaxis {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Errores
    )

    foreach ($ErrorSintaxis in $Errores) {
        Write-Host ""
        Write-Host $ErrorSintaxis.Message -ForegroundColor Red

        if ($null -ne $ErrorSintaxis.Extent) {
            Write-Host (
                "Linea {0}, columna {1}" -f `
                    $ErrorSintaxis.Extent.StartLineNumber,
                    $ErrorSintaxis.Extent.StartColumnNumber
            ) -ForegroundColor Yellow
        }
    }
}

function Restaurar-Core {
    if (Test-Path -LiteralPath $BackupFile -PathType Leaf) {
        Copy-Item `
            -LiteralPath $BackupFile `
            -Destination $CoreFile `
            -Force

        Write-Host ""
        Write-Host "La version anterior fue restaurada." `
            -ForegroundColor Yellow
    }
}

# ============================================================
# INICIO
# ============================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host " CORREGIR RETORNO DE SINCRONIZACION DEL CORE" `
    -ForegroundColor Cyan
Write-Host "====================================================" `
    -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $CoreFile -PathType Leaf)) {
    Write-Host "[ERROR] No se encontro ClaudeMem-Core.ps1:" `
        -ForegroundColor Red
    Write-Host $CoreFile
    exit 1
}

Crear-Carpeta -Ruta $BackupsFolder

# ============================================================
# RESPALDO
# ============================================================

Copy-Item `
    -LiteralPath $CoreFile `
    -Destination $BackupFile `
    -Force

Write-Host "[RESPALDO OK]" -ForegroundColor Green
Write-Host $BackupFile
Write-Host ""

# ============================================================
# LEER CORE
# ============================================================

$ContenidoOriginal = Get-Content `
    -LiteralPath $CoreFile `
    -Raw `
    -ErrorAction Stop

# ============================================================
# LOCALIZAR BLOQUE DEFECTUOSO
# ============================================================

$PatronDefectuoso = '(?ms)([ \t]*)&[ \t]+\$SincronizarBibliotecaScript[ \t]*\r?\n[ \t]*\r?\n[ \t]*if[ \t]*\([ \t]*\$LASTEXITCODE[ \t]*-and[ \t]*\$LASTEXITCODE[ \t]*-ne[ \t]*0[ \t]*\)[ \t]*\{[ \t]*\r?\n[ \t]*throw[ \t]+"El sincronizador termino con codigo \$LASTEXITCODE\."[ \t]*\r?\n[ \t]*\}'

$Coincidencias = @(
    [regex]::Matches(
        $ContenidoOriginal,
        $PatronDefectuoso
    )
)

if ($Coincidencias.Count -ne 1) {
    Write-Host "[ERROR] No se encontro exactamente un bloque defectuoso." `
        -ForegroundColor Red
    Write-Host ""
    Write-Host "Coincidencias encontradas: $($Coincidencias.Count)"
    Write-Host "ClaudeMem-Core.ps1 no fue modificado."
    Write-Host ""
    Write-Host "Respaldo disponible:"
    Write-Host $BackupFile
    exit 1
}

# ============================================================
# BLOQUE CORREGIDO
# ============================================================

$Indentacion = $Coincidencias[0].Groups[1].Value

$BloqueCorregido = @"
${Indentacion}& `$SincronizarBibliotecaScript

${Indentacion}`$SincronizacionCorrecta = `$?

${Indentacion}if (-not `$SincronizacionCorrecta) {
${Indentacion}    throw "El sincronizador informo un error de ejecucion."
${Indentacion}}
"@

# ============================================================
# GENERAR CONTENIDO CORREGIDO
# ============================================================

$ContenidoCorregido = [regex]::Replace(
    $ContenidoOriginal,
    $PatronDefectuoso,
    [System.Text.RegularExpressions.MatchEvaluator]{
        param($Coincidencia)

        return $BloqueCorregido
    },
    1
)

if ($ContenidoCorregido -eq $ContenidoOriginal) {
    Write-Host "[ERROR] No se produjo ningun cambio en el Core." `
        -ForegroundColor Red
    Write-Host "ClaudeMem-Core.ps1 no fue modificado."
    exit 1
}

# ============================================================
# ESCRIBIR ARCHIVO TEMPORAL
# ============================================================

Set-Content `
    -LiteralPath $TemporalFile `
    -Value $ContenidoCorregido `
    -Encoding UTF8

# ============================================================
# VALIDAR TEMPORAL
# ============================================================

Write-Host "Validando sintaxis del Core corregido..." `
    -ForegroundColor Cyan

$ErroresTemporales = @(
    Obtener-ErroresSintaxis `
        -Ruta $TemporalFile
)

if ($ErroresTemporales.Count -gt 0) {
    Write-Host ""
    Write-Host "[ERROR] El archivo temporal tiene errores." `
        -ForegroundColor Red

    Mostrar-ErroresSintaxis `
        -Errores $ErroresTemporales

    Remove-Item `
        -LiteralPath $TemporalFile `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "ClaudeMem-Core.ps1 no fue modificado." `
        -ForegroundColor Yellow
    exit 1
}

# ============================================================
# COMPROBAR EL BLOQUE TEMPORAL
# ============================================================

$ContenidoTemporal = Get-Content `
    -LiteralPath $TemporalFile `
    -Raw `
    -ErrorAction Stop

$ConservaBloqueDefectuoso = [regex]::IsMatch(
    $ContenidoTemporal,
    $PatronDefectuoso
)

if ($ConservaBloqueDefectuoso) {
    Remove-Item `
        -LiteralPath $TemporalFile `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "[ERROR] El bloque defectuoso no fue eliminado." `
        -ForegroundColor Red
    Write-Host "ClaudeMem-Core.ps1 no fue modificado." `
        -ForegroundColor Yellow
    exit 1
}

$TieneBloqueNuevo = (
    $ContenidoTemporal -match
    '\$SincronizacionCorrecta\s*=\s*\$\?'
)

if (-not $TieneBloqueNuevo) {
    Remove-Item `
        -LiteralPath $TemporalFile `
        -Force `
        -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "[ERROR] No se encontro el bloque corregido." `
        -ForegroundColor Red
    Write-Host "ClaudeMem-Core.ps1 no fue modificado." `
        -ForegroundColor Yellow
    exit 1
}

# ============================================================
# INSTALAR CORE CORREGIDO
# ============================================================

try {
    Move-Item `
        -LiteralPath $TemporalFile `
        -Destination $CoreFile `
        -Force
}
catch {
    Write-Host ""
    Write-Host "[ERROR] No se pudo instalar el Core corregido." `
        -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Restaurar-Core
    exit 1
}

# ============================================================
# VALIDACION FINAL
# ============================================================

$ErroresFinales = @(
    Obtener-ErroresSintaxis `
        -Ruta $CoreFile
)

if ($ErroresFinales.Count -gt 0) {
    Write-Host ""
    Write-Host "[ERROR] El Core instalado tiene errores." `
        -ForegroundColor Red

    Mostrar-ErroresSintaxis `
        -Errores $ErroresFinales

    Restaurar-Core
    exit 1
}

$CoreFinal = Get-Content `
    -LiteralPath $CoreFile `
    -Raw `
    -ErrorActiontinua = :IsMatch(
    $CoreFinal,
    $PatronDefectuoso
)

$BloqueNuevoInstalado = (
    $CoreFinal -match
    '\$SincronizacionCorrecta\s*=\s*\$\?'
)

if ($BloqueAntiguoContinua -or -not $BloqueNuevoInstalado) {
    Write-Host ""
    Write-Host "[ERROR] La validacion funcional del cambio fallo." `
        -ForegroundColor Red

    Restaurar-Core
    exit 1
}

# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "====================================================" `
    -ForegroundColor Green
Write-Host " CORRECCION COMPLETADA" `
    -ForegroundColor Green
Write-Host "====================================================" `
    -ForegroundColor Green
Write-Host ""
Write-Host "[SINTAXIS OK]" -ForegroundColor Green
Write-Host "[BLOQUE ANTIGUO ELIMINADO]" -ForegroundColor Green
Write-Host "[BLOQUE NUEVO INSTALADO]" -ForegroundColor Green
Write-Host ""
Write-Host "Core actualizado:"
Write-Host $CoreFile
Write-Host ""
Write-Host "Respaldo:"
Write-Host $BackupFile
Write-Host ""
Write-Host "Siguiente comando:" -ForegroundColor Cyan
Write-Host '& "..\11_Herramientas\ClaudeMem\ClaudeMem-Core.ps1"'
Write-Host ""