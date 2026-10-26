#Requires -Version 5.1

<#
.SYNOPSIS
    Corrige el parser Markdown del auditor de conflictos de ClaudeMem.

.DESCRIPTION
    Reemplaza Obtener-ResumenMarkdown para que, cuando exista la seccion
    ## Contenido, compare solamente el contenido de esa seccion. Tambien
    ignora las secciones estructurales ## ID y sus valores.

    Crea respaldo, valida sintaxis y conserva el archivo anterior si falla.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Auditor = Join-Path $PSScriptRoot "Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1"
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups\scripts-corregidos"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $BackupsFolder "Auditar-Conflictos-BibliotecaViva-ClaudeMem-$MarcaTiempo.ps1"
$Temporal = "$Auditor.tmp"

function Crear-Carpeta {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    if (-not (Test-Path -LiteralPath $Ruta -PathType Container)) {
        New-Item -ItemType Directory -Path $Ruta -Force | Out-Null
    }
}

function Obtener-ErroresSintaxis {
    param([Parameter(Mandatory = $true)][string]$Ruta)
    $Tokens = $null
    $Errores = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Ruta,
        [ref]$Tokens,
        [ref]$Errores
    )
    return @($Errores)
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " REPARAR PARSER DE CONFLICTOS CLAUDEMEM" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $Auditor -PathType Leaf)) {
    throw "No existe el auditor: $Auditor"
}

Crear-Carpeta -Ruta $BackupsFolder
Copy-Item -LiteralPath $Auditor -Destination $Backup -Force
Write-Host "[OK] Respaldo creado:" -ForegroundColor Green
Write-Host $Backup
Write-Host ""

$Contenido = Get-Content -LiteralPath $Auditor -Raw -ErrorAction Stop

$NuevaFuncion = @'
function Obtener-ResumenMarkdown {
    param([Parameter(Mandatory = $true)][string]$Contenido)

    $Lineas = @($Contenido -split "`r?`n")
    $IndiceContenido = -1

    for ($Indice = 0; $Indice -lt $Lineas.Count; $Indice++) {
        if ($Lineas[$Indice] -match '^\s*##\s+Contenido\s*$') {
            $IndiceContenido = $Indice
            break
        }
    }

    # Formato controlado generado desde JSON: extraer solo ## Contenido.
    if ($IndiceContenido -ge 0) {
        $Seleccionadas = @()

        for ($Indice = $IndiceContenido + 1; $Indice -lt $Lineas.Count; $Indice++) {
            $Linea = $Lineas[$Indice]

            if ($Linea -match '^\s*#{1,6}\s+') {
                break
            }

            $TextoLinea = $Linea.Trim()
            if ($TextoLinea.Length -gt 0) {
                $Seleccionadas += $TextoLinea
            }
        }

        return ($Seleccionadas -join ' ').Trim()
    }

    # Formato historico: ignorar encabezados, Fecha e ID estructural.
    $Resultado = @()
    $OmitirSiguienteValor = $false

    foreach ($Linea in $Lineas) {
        $TextoLinea = $Linea.Trim()

        if ($TextoLinea -match '^\s*##\s+ID\s*$') {
            $OmitirSiguienteValor = $true
            continue
        }

        if ($TextoLinea -match '^\s*#{1,6}\s+') {
            $OmitirSiguienteValor = $false
            continue
        }

        if ($TextoLinea -match '^\s*Fecha\s*:') {
            continue
        }

        if ($TextoLinea.Length -eq 0) {
            continue
        }

        if ($OmitirSiguienteValor) {
            $OmitirSiguienteValor = $false
            continue
        }

        $Resultado += $TextoLinea
    }

    return ($Resultado -join ' ').Trim()
}
'@

$PatronFuncion = '(?ms)^function\s+Obtener-ResumenMarkdown\s*\{.*?^\}\r?\n\r?\nfunction\s+Obtener-FechaMarkdown'
$Coincidencias = @([regex]::Matches($Contenido, $PatronFuncion))

if ($Coincidencias.Count -ne 1) {
    throw "No se encontro exactamente una funcion Obtener-ResumenMarkdown. Coincidencias: $($Coincidencias.Count)"
}

$Reemplazo = $NuevaFuncion + "`r`n`r`nfunction Obtener-FechaMarkdown"
$ContenidoCorregido = [regex]::Replace($Contenido, $PatronFuncion, $Reemplazo, 1)

$ContenidoCorregido = [regex]::Replace(
    $ContenidoCorregido,
    '(?m)^(\s*)1\.0\.0\s*$',
    '${1}1.1.0',
    1
)

Set-Content -LiteralPath $Temporal -Value $ContenidoCorregido -Encoding UTF8

$Errores = @(Obtener-ErroresSintaxis -Ruta $Temporal)
if ($Errores.Count -gt 0) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    foreach ($ErrorSintaxis in $Errores) {
        Write-Host ("Linea {0}: {1}" -f $ErrorSintaxis.Extent.StartLineNumber, $ErrorSintaxis.Message) -ForegroundColor Red
    }
    throw "El archivo corregido tiene errores. El original no fue modificado."
}

$Prueba = Get-Content -LiteralPath $Temporal -Raw
$Validaciones = @(
    ($Prueba -match '##\\s\+Contenido'),
    ($Prueba -match '\$IndiceContenido'),
    ($Prueba -match '\$OmitirSiguienteValor'),
    ($Prueba -match '(?m)^\s*1\.1\.0\s*$')
)

if ($Validaciones -contains $false) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    throw "La validacion funcional del parser corregido fallo."
}

Move-Item -LiteralPath $Temporal -Destination $Auditor -Force

$ErroresFinales = @(Obtener-ErroresSintaxis -Ruta $Auditor)
if ($ErroresFinales.Count -gt 0) {
    Copy-Item -LiteralPath $Backup -Destination $Auditor -Force
    throw "Fallo la validacion final. Se restauro el respaldo."
}

Write-Host "====================================================" -ForegroundColor Green
Write-Host " REPARACION COMPLETADA" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Sintaxis valida" -ForegroundColor Green
Write-Host "[OK] Parser de seccion Contenido instalado" -ForegroundColor Green
Write-Host "[OK] Seccion ID excluida de la comparacion" -ForegroundColor Green
Write-Host "[OK] Version 1.1.0 instalada" -ForegroundColor Green
Write-Host ""
Write-Host "Siguiente comando:" -ForegroundColor Cyan
Write-Host '.\Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1 -Auditar -IncluirCoincidencias'
Write-Host ""
