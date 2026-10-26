#Requires -Version 5.1

<#
.SYNOPSIS
    Audita y repara Auditar-Relaciones-ClaudeMem.ps1 de forma segura.

.DESCRIPTION
    Detecta la version antigua que asigna directamente la propiedad
    relacionados, crea respaldo, inserta una funcion compatible con
    Windows PowerShell 5.1 y Set-StrictMode, reemplaza todas las asignaciones
    vulnerables, valida sintaxis y confirma la correccion instalada.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Auditor = Join-Path $PSScriptRoot "Auditar-Relaciones-ClaudeMem.ps1"
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot "11_Herramientas\ClaudeMem"
$BackupsFolder = Join-Path $ClaudeMemRoot "backups\scripts-corregidos"
$MarcaTiempo = Get-Date -Format "yyyyMMdd-HHmmss"
$Backup = Join-Path $BackupsFolder "Auditar-Relaciones-ClaudeMem-$MarcaTiempo.ps1"
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
Write-Host " AUDITAR Y REPARAR AUDITOR DE RELACIONES" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path -LiteralPath $Auditor -PathType Leaf)) {
    throw "No existe el archivo operativo: $Auditor"
}

Crear-Carpeta -Ruta $BackupsFolder
Copy-Item -LiteralPath $Auditor -Destination $Backup -Force
Write-Host "[OK] Respaldo creado:" -ForegroundColor Green
Write-Host $Backup
Write-Host ""

$Contenido = Get-Content -LiteralPath $Auditor -Raw -ErrorAction Stop
$Hallazgos = @()

$TieneVersionNueva = $Contenido -match 'function\s+Establecer-Relacionados'
$TieneAsignacionReparacion = $Contenido -match '\$Registro\.objeto\.relacionados\s*='
$TieneAsignacionPrueba = $Contenido -match '\$RegistroOrigen\[0\]\.objeto\.relacionados\s*='

$Hallazgos += [PSCustomObject]@{
    Prueba = "Funcion segura instalada"
    Estado = $(if ($TieneVersionNueva) { "OK" } else { "FALTA" })
}
$Hallazgos += [PSCustomObject]@{
    Prueba = "Asignacion directa en reparacion"
    Estado = $(if ($TieneAsignacionReparacion) { "DETECTADA" } else { "NO" })
}
$Hallazgos += [PSCustomObject]@{
    Prueba = "Asignacion directa en prueba"
    Estado = $(if ($TieneAsignacionPrueba) { "DETECTADA" } else { "NO" })
}

$Hallazgos | Format-Table -AutoSize
Write-Host ""

$FuncionSegura = @'
function Establecer-Relacionados {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Registro,

        [AllowEmptyCollection()]
        [array]$Valores
    )

    if ($Registro.PSObject.Properties.Name -contains "relacionados") {
        $Registro.relacionados = @($Valores)
    }
    else {
        Add-Member `
            -InputObject $Registro `
            -MemberType NoteProperty `
            -Name "relacionados" `
            -Value @($Valores) `
            -Force
    }
}

'@

if (-not $TieneVersionNueva) {
    $PuntoInsercion = 'function Obtener-RegistrosActivos {'
    if (-not $Contenido.Contains($PuntoInsercion)) {
        throw "No se encontro el punto seguro de insercion."
    }
    $Contenido = $Contenido.Replace(
        $PuntoInsercion,
        ($FuncionSegura + $PuntoInsercion)
    )
}

$Contenido = $Contenido.Replace(
    '$Registro.objeto.relacionados = @($RelacionadosLimpios)',
    'Establecer-Relacionados -Registro $Registro.objeto -Valores @($RelacionadosLimpios)'
)

$Contenido = $Contenido.Replace(
    '$RegistroOrigen[0].objeto.relacionados = @($OriginalRelacionados + "ID-INEXISTENTE-PRUEBA")',
    'Establecer-Relacionados -Registro $RegistroOrigen[0].objeto -Valores @($OriginalRelacionados + "ID-INEXISTENTE-PRUEBA")'
)

$Contenido = $Contenido.Replace(
    '$RegistroOrigen[0].objeto.relacionados = @($OriginalRelacionados)',
    'Establecer-Relacionados -Registro $RegistroOrigen[0].objeto -Valores @($OriginalRelacionados)'
)

# Actualizar marcador de version si existe.
$Contenido = [regex]::Replace(
    $Contenido,
    '(?m)^(\s*)1\.0\.0\s*$',
    '${1}1.1.0',
    1
)

Set-Content -LiteralPath $Temporal -Value $Contenido -Encoding UTF8

$Errores = @(Obtener-ErroresSintaxis -Ruta $Temporal)
if ($Errores.Count -gt 0) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    Write-Host "[ERROR] La copia corregida tiene errores de sintaxis." -ForegroundColor Red
    $Errores | ForEach-Object {
        Write-Host ("Linea {0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) -ForegroundColor Red
    }
    throw "Correccion cancelada. El auditor original no fue modificado."
}

$PruebaContenido = Get-Content -LiteralPath $Temporal -Raw
$Validaciones = @(
    ($PruebaContenido -match 'function\s+Establecer-Relacionados'),
    ($PruebaContenido -match 'Add-Member\s+`?\s*-InputObject\s+\$Registro'),
    ($PruebaContenido -notmatch '\$Registro\.objeto\.relacionados\s*='),
    ($PruebaContenido -notmatch '\$RegistroOrigen\[0\]\.objeto\.relacionados\s*=')
)

if ($Validaciones -contains $false) {
    Remove-Item -LiteralPath $Temporal -Force -ErrorAction SilentlyContinue
    throw "La validacion funcional del parche no fue aprobada."
}

Move-Item -LiteralPath $Temporal -Destination $Auditor -Force

$ErroresFinales = @(Obtener-ErroresSintaxis -Ruta $Auditor)
if ($ErroresFinales.Count -gt 0) {
    Copy-Item -LiteralPath $Backup -Destination $Auditor -Force
    throw "La validacion final fallo. Se restauro el respaldo."
}

Write-Host "====================================================" -ForegroundColor Green
Write-Host " REPARACION COMPLETADA" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[OK] Sintaxis valida" -ForegroundColor Green
Write-Host "[OK] Funcion Establecer-Relacionados instalada" -ForegroundColor Green
Write-Host "[OK] Asignaciones directas eliminadas" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo operativo:"
Write-Host $Auditor
Write-Host ""
Write-Host "Siguiente comando:" -ForegroundColor Cyan
Write-Host '.\Auditar-Relaciones-ClaudeMem.ps1 -Reparar'
Write-Host ""
