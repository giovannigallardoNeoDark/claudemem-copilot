# ==============================================
# Auditoria Syntec
# ==============================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$Reporte = Join-Path `
$Base `
"00_Admin\Inventario\AUDITORIA_GENERAL.md"

Write-Host ""
Write-Host "Iniciando auditoria..." -ForegroundColor Cyan
Write-Host ""

# ==============================================
# FUNCIONES
# ==============================================

function Add-Line {
    param([string]$Text)

    Add-Content `
        -Path $Reporte `
        -Value $Text
}

# ==============================================
# CREAR REPORTE
# ==============================================

"# AUDITORIA GENERAL SYNTEC" | Out-File `
$Reporte `
-Encoding UTF8

Add-Line ""
Add-Line "Fecha: $Fecha"
Add-Line ""

# ==============================================
# INFORMACION GENERAL
# ==============================================

Add-Line "## Informacion General"
Add-Line ""

$TotalCarpetas =
(Get-ChildItem $Base `
    -Directory `
    -Recurse `
    -ErrorAction SilentlyContinue).Count

$TotalArchivos =
(Get-ChildItem $Base `
    -File `
    -Recurse `
    -ErrorAction SilentlyContinue).Count

Add-Line "- Carpetas: $TotalCarpetas"
Add-Line "- Archivos: $TotalArchivos"

Add-Line ""

# ==============================================
# VERSIONES
# ==============================================

Add-Line "## Herramientas Instaladas"
Add-Line ""

try {
    $GitVersion = git --version
}
catch {
    $GitVersion = "NO DETECTADO"
}

try {
    $PythonVersion = python --version
}
catch {
    $PythonVersion = "NO DETECTADO"
}

try {
    $NodeVersion = node --version
}
catch {
    $NodeVersion = "NO DETECTADO"
}

try {
    $SemgrepVersion = semgrep --version
}
catch {
    $SemgrepVersion = "NO DETECTADO"
}

Add-Line "- Git: $GitVersion"
Add-Line "- Python: $PythonVersion"
Add-Line "- NodeJS: $NodeVersion"
Add-Line "- Semgrep: $SemgrepVersion"

Add-Line ""

# ==============================================
# ESTRUCTURA PRINCIPAL
# ==============================================

Add-Line "## Carpetas Principales"
Add-Line ""

Get-ChildItem $Base -Directory |
Sort-Object Name |
ForEach-Object {

    Add-Line "- $($_.Name)"
}

Add-Line ""

# ==============================================
# BOOTSTRAPS
# ==============================================

Add-Line "## Scripts Bootstrap"
Add-Line ""

$Bootstraps =
Get-ChildItem `
"$Base\15_Scripts" `
-Filter "*Bootstrap*" `
-ErrorAction SilentlyContinue

foreach($Item in $Bootstraps)
{
    Add-Line "- $($Item.Name)"
}

Add-Line ""

# ==============================================
# TAMAÑOS
# ==============================================

Add-Line "## Uso de Espacio"
Add-Line ""

Get-ChildItem $Base -Directory |
ForEach-Object {

    $Size = (
        Get-ChildItem `
        $_.FullName `
        -Recurse `
        -File `
        -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum
    ).Sum

    $MB = [Math]::Round($Size / 1MB,2)

    Add-Line "- $($_.Name): $MB MB"
}

Add-Line ""

# ==============================================
# ARCHIVOS MAESTROS
# ==============================================

Add-Line "## Verificacion Archivos Maestros"
Add-Line ""

$MasterFiles = @(

"00_Admin\Arquitectura\ARQUITECTURA_GENERAL.md",

"00_Admin\Roadmap\ROADMAP_GENERAL.md",

"00_Admin\Inventario\INVENTARIO_HERRAMIENTAS.md",

"00_Admin\CHANGELOG.md"

)

foreach($File in $MasterFiles)
{
    $FullPath = Join-Path $Base $File

    if(Test-Path $FullPath)
    {
        Add-Line "- OK : $File"
    }
    else
    {
        Add-Line "- FALTA : $File"
    }
}

Add-Line ""

# ==============================================
# GIT
# ==============================================

Add-Line "## Git"
Add-Line ""

if(Test-Path "$Base\.git")
{
    Add-Line "- Repositorio Git detectado."
}
else
{
    Add-Line "- No existe repositorio Git."
}

Add-Line ""

# ==============================================
# FINAL
# ==============================================

Add-Line "## Resultado"

Add-Line ""

Add-Line "Auditoria finalizada correctamente."

Write-Host ""
Write-Host "AUDITORIA COMPLETADA" -ForegroundColor Green
Write-Host ""
Write-Host $Reporte -ForegroundColor Yellow
Write-Host ""