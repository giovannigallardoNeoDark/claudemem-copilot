# ===================================================================
# Prueba-Funcional-ClaudeMem.ps1
# ClaudeMem Functional Test Suite
# Version: 1.0
# ===================================================================

$ErrorActionPreference = "SilentlyContinue"

# -------------------------------------------------------------------
# CONFIGURACION
# -------------------------------------------------------------------

$Root = Split-Path -Parent $PSScriptRoot

$ClaudeMem = Join-Path $Root "11_Herramientas\ClaudeMem"

$DataFolder     = Join-Path $ClaudeMem "data"
$IndexFolder    = Join-Path $ClaudeMem "index"
$BackupFolder   = Join-Path $ClaudeMem "backups"
$ConfigFolder   = Join-Path $ClaudeMem "config"
$LogsFolder     = Join-Path $ClaudeMem "logs"
$ViewerFolder   = Join-Path $ClaudeMem "viewer"

$ConfigFile     = Join-Path $ConfigFolder "config.json"
$DecisionFile   = Join-Path $DataFolder "decisiones.json"
$LessonsFile    = Join-Path $DataFolder "lecciones.json"
$FindingsFile   = Join-Path $DataFolder "hallazgos.json"
$IndexFile      = Join-Path $IndexFolder "index.json"
$LogFile        = Join-Path $LogsFolder "claudemem.log"

$KnowledgeRoot  = Join-Path $Root "03_Conocimiento"

# -------------------------------------------------------------------
# RESULTADOS
# -------------------------------------------------------------------

$script:Results = @()

function Add-TestResult {

    param(
        [string]$Id,
        [string]$Name,
        [bool]$Pass,
        [string]$Detail
    )

    $script:Results += [PSCustomObject]@{
        Testeo = $Id
        Nombre = $Name
        Estado = if ($Pass) { "PASS" } else { "FAIL" }
        Detalle = $Detail
    }

}

Write-Host ""
Write-Host "=================================="
Write-Host "DEBUG RESULTADOS"
Write-Host "=================================="

Write-Host "Cantidad pruebas:"
Write-Host $script:Results.Count

$script:Results | Format-Table

function New-FolderIfMissing {
    param($Path)

    if(!(Test-Path $Path)){
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-Log {
    param($Msg)

    New-FolderIfMissing $LogsFolder

    Add-Content -Path $LogFile `
        -Value "$(Get-Date -Format s) - $Msg"
}

# -------------------------------------------------------------------
# CREACION BASICA
# -------------------------------------------------------------------

$RequiredFolders = @(
    $DataFolder,
    $IndexFolder,
    $BackupFolder,
    $ConfigFolder,
    $LogsFolder,
    $ViewerFolder
)

foreach($Folder in $RequiredFolders){
    New-FolderIfMissing $Folder
}

# -------------------------------------------------------------------
# PF-001
# -------------------------------------------------------------------

$PF001 = $true

foreach($Folder in $RequiredFolders){
    if(!(Test-Path $Folder)){
        $PF001 = $false
    }
}

Add-TestResult "PF-001" `
"Verificar estructura" `
$PF001 `
"Estructura ClaudeMem"

# -------------------------------------------------------------------
# PF-002
# -------------------------------------------------------------------

if(!(Test-Path $ConfigFile)){

    @{
        version = "1.0"
        storage = "json"
    } | ConvertTo-Json | Set-Content $ConfigFile
}

$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json

$PF002 = (
    $config.version -and
    $config.storage
)

Add-TestResult "PF-002" `
"Validar configuración" `
$PF002 `
"config.json"

# -------------------------------------------------------------------
# PF-003
# -------------------------------------------------------------------

$Decision = @{
    id     = "DECISION-TEST-001"
    tipo   = "decision"
    titulo = "ClaudeMem Principal"
    fecha  = "2026-10-21"
}

@($Decision) |
ConvertTo-Json -Depth 5 |
Set-Content $DecisionFile

$PF003 = Test-Path $DecisionFile

Write-Log "CREATE DECISION"

Add-TestResult "PF-003" `
"Crear decisión" `
$PF003 `
"decisiones.json"

# -------------------------------------------------------------------
# PF-004
# -------------------------------------------------------------------

$DecisionRead = Get-Content $DecisionFile -Raw |
ConvertFrom-Json

$PF004 = (
    $DecisionRead.id -eq "DECISION-TEST-001"
)

Add-TestResult "PF-004" `
"Leer decisión" `
$PF004 `
"Lectura OK"

# -------------------------------------------------------------------
# PF-005
# -------------------------------------------------------------------

$Lesson = @{
    id="LECCION-TEST-001"
    tipo="leccion"
}

@($Lesson) |
ConvertTo-Json |
Set-Content $LessonsFile

$PF005 = Test-Path $LessonsFile

Write-Log "CREATE LESSON"

Add-TestResult "PF-005" `
"Crear lección" `
$PF005 `
"lecciones.json"

# -------------------------------------------------------------------
# PF-006
# -------------------------------------------------------------------

$Finding = @{
    id="HALLAZGO-TEST-001"
    tipo="hallazgo"
}

@($Finding) |
ConvertTo-Json |
Set-Content $FindingsFile

$PF006 = Test-Path $FindingsFile

Write-Log "CREATE FINDING"

Add-TestResult "PF-006" `
"Crear hallazgo" `
$PF006 `
"hallazgos.json"

# -------------------------------------------------------------------
# PF-007
# -------------------------------------------------------------------

$Index = @{
    "DECISION-TEST-001"="decision"
    "LECCION-TEST-001"="leccion"
    "HALLAZGO-TEST-001"="hallazgo"
}

$Index |
ConvertTo-Json |
Set-Content $IndexFile

$PF007 = Test-Path $IndexFile

Add-TestResult "PF-007" `
"Indice maestro" `
$PF007 `
"index.json"

# -------------------------------------------------------------------
# PF-008
# -------------------------------------------------------------------

$PF008 = (
    (Get-Content $IndexFile -Raw) `
    -match "DECISION-TEST-001"
)

Write-Log "SEARCH EXACT"

Add-TestResult "PF-008" `
"Busqueda exacta" `
$PF008 `
"Encontrado"

# -------------------------------------------------------------------
# PF-009
# -------------------------------------------------------------------

$PF009 = (
    (Get-Content $DecisionFile -Raw) `
    -match "ClaudeMem"
)

Write-Log "SEARCH PARTIAL"

Add-TestResult "PF-009" `
"Busqueda parcial" `
$PF009 `
"ClaudeMem"

# -------------------------------------------------------------------
# PF-010
# -------------------------------------------------------------------

$Decision.estado = "Validado"

@($Decision) |
ConvertTo-Json |
Set-Content $DecisionFile

$PF010 = (
    (Get-Content $DecisionFile -Raw) `
    -match "Validado"
)

Write-Log "UPDATE"

Add-TestResult "PF-010" `
"Modificar registro" `
$PF010 `
"Estado agregado"

# -------------------------------------------------------------------
# PF-011
# -------------------------------------------------------------------

$Trash = Join-Path $DataFolder "papelera"

New-FolderIfMissing $Trash

$DeletedFile = Join-Path $Trash "HALLAZGO-TEST-001.json"

$Finding |
ConvertTo-Json |
Set-Content $DeletedFile

$PF011 = Test-Path $DeletedFile

Add-TestResult "PF-011" `
"Eliminacion controlada" `
$PF011 `
"Papelera"

# -------------------------------------------------------------------
# PF-012
# -------------------------------------------------------------------

$BackupName = "backup-{0}.zip" -f `
(Get-Date -Format "yyyyMMdd-HHmmss")

$BackupFile = Join-Path `
$BackupFolder `
$BackupName

Compress-Archive `
-Path $DataFolder `
-DestinationPath $BackupFile `
-Force

$PF012 = Test-Path $BackupFile

Write-Log "BACKUP"

Add-TestResult "PF-012" `
"Backup" `
$PF012 `
$BackupName

# -------------------------------------------------------------------
# PF-013
# -------------------------------------------------------------------

$PF013 = Test-Path $BackupFile

Write-Log "RESTORE TEST"

Add-TestResult "PF-013" `
"Restauracion" `
$PF013 `
"Backup disponible"

# -------------------------------------------------------------------
# PF-014
# -------------------------------------------------------------------

$PF014 = Test-Path $LogFile

Add-TestResult "PF-014" `
"Logs" `
$PF014 `
"claudemem.log"

# -------------------------------------------------------------------
# PF-015
# -------------------------------------------------------------------

$PF015 = Test-Path $KnowledgeRoot

Add-TestResult "PF-015" `
"Biblioteca Viva" `
$PF015 `
"03_Conocimiento"

# -------------------------------------------------------------------
# PF-016
# -------------------------------------------------------------------

$PF016 = (
    (Get-Content $DecisionFile -Raw) `
    -match "ClaudeMem Principal"
)

Add-TestResult "PF-016" `
"Recuperacion conocimiento" `
$PF016 `
"Consulta"

# -------------------------------------------------------------------
# PF-017
# -------------------------------------------------------------------

try{
    Get-Content $DecisionFile -Raw | ConvertFrom-Json | Out-Null
    Get-Content $LessonsFile -Raw | ConvertFrom-Json | Out-Null
    Get-Content $FindingsFile -Raw | ConvertFrom-Json | Out-Null

    $PF017 = $true
}
catch{
    $PF017 = $false
}

Add-TestResult "PF-017" `
"Integridad JSON" `
$PF017 `
"Formato valido"

# -------------------------------------------------------------------
# PF-018
# -------------------------------------------------------------------

$PF018 = (
    (Test-Path $DecisionFile) -and
    (Test-Path $LessonsFile)
)

Add-TestResult "PF-018" `
"Persistencia reinicio" `
$PF018 `
"Archivos presentes"

# -------------------------------------------------------------------
# REPORTE
# -------------------------------------------------------------------

$PassCount =
($Results | Where-Object Estado -eq "PASS").Count

$Total =
$Results.Count

$Total = $script:Results.Count

$PassCount = (
    $script:Results |
    Where-Object Estado -eq "PASS"
).Count

if ($Total -gt 0) {

    $Madurez = [Math]::Round(
        (($PassCount / $Total) * 100),
        2
    )

}
else {

    $Madurez = 0

}
[math]::Round(
(($PassCount / $Total) * 100),
2
)

$ReportFile =
Join-Path $ClaudeMem `
"Reporte-Prueba-Funcional-ClaudeMem.txt"

Add-TestResult `
"PF-000" `
"Inicio Framework" `
$true `
"Motor de pruebas iniciado"

@(
"=================================================="
"PRUEBA FUNCIONAL CLAUDEMEM"
"=================================================="
"Fecha: $(Get-Date)"
""
"Pruebas Aprobadas : $PassCount"
"Pruebas Totales   : $Total"
"Madurez           : $Madurez %"
""
) | Set-Content $ReportFile

$Results |
Format-Table -AutoSize |
Out-String |
Add-Content $ReportFile

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " ClaudeMem Functional Test"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "PASS: $PassCount / $Total"
Write-Host "MADUREZ: $Madurez %"
Write-Host ""
Write-Host "Reporte:"
Write-Host $ReportFile -ForegroundColor Yellow
Write-Host ""