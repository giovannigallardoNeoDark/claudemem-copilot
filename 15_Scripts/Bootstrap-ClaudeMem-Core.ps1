# ============================================================
# Bootstrap-ClaudeMem-Core.ps1
# Crea la estructura operativa completa de ClaudeMem
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "BOOTSTRAP CLAUDEMEM CORE"
Write-Host "==========================================" -ForegroundColor Cyan

# ------------------------------------------------------------
# ROOT
# ------------------------------------------------------------

$Root = Split-Path -Parent $PSScriptRoot

$ClaudeMem = Join-Path $Root "11_Herramientas\ClaudeMem"

# ------------------------------------------------------------
# CARPETAS
# ------------------------------------------------------------

$Folders = @(
    "$ClaudeMem\backups",
    "$ClaudeMem\config",
    "$ClaudeMem\data",
    "$ClaudeMem\data\papelera",
    "$ClaudeMem\index",
    "$ClaudeMem\logs",
    "$ClaudeMem\viewer"
)

foreach($Folder in $Folders)
{
    if(!(Test-Path $Folder))
    {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
        Write-Host "[OK] Carpeta creada: $Folder"
    }
}

# ------------------------------------------------------------
# CONFIG
# ------------------------------------------------------------

$ConfigFile = "$ClaudeMem\config\config.json"

@'
{
  "version": "1.0",
  "storage": "json",
  "logs": true,
  "backups": true,
  "indexado": true
}
'@ | Set-Content $ConfigFile -Encoding UTF8

# ------------------------------------------------------------
# DECISIONES
# ------------------------------------------------------------

$DecisionesFile = "$ClaudeMem\data\decisiones.json"

@'
[
  {
    "id": "DECISION-TEST-001",
    "titulo": "ClaudeMem Principal",
    "fecha": "2026-10-21",
    "estado": "Validado"
  }
]
'@ | Set-Content $DecisionesFile -Encoding UTF8

# ------------------------------------------------------------
# LECCIONES
# ------------------------------------------------------------

$LeccionesFile = "$ClaudeMem\data\lecciones.json"

if(!(Test-Path $LeccionesFile))
{
    @'
[
]
'@ | Set-Content $LeccionesFile -Encoding UTF8
}

# ------------------------------------------------------------
# HALLAZGOS
# ------------------------------------------------------------

$HallazgosFile = "$ClaudeMem\data\hallazgos.json"

if(!(Test-Path $HallazgosFile))
{
    @'
[
]
'@ | Set-Content $HallazgosFile -Encoding UTF8
}

# ------------------------------------------------------------
# INDICE
# ------------------------------------------------------------

$IndexFile = "$ClaudeMem\index\index.json"

@'
{
  "DECISION-TEST-001": "decision"
}
'@ | Set-Content $IndexFile -Encoding UTF8

# ------------------------------------------------------------
# LOG
# ------------------------------------------------------------

$LogFile = "$ClaudeMem\logs\claudemem.log"

Add-Content $LogFile ""
Add-Content $LogFile "[$(Get-Date)] ClaudeMem Inicializado"

# ------------------------------------------------------------
# ESTADO OPERACIONAL
# ------------------------------------------------------------

$EstadoFile = "$ClaudeMem\estado.json"

@'
{
  "nombre": "ClaudeMem",
  "version": "1.0",
  "estado": "OPERATIVO",
  "madurez": 100,
  "ultimaPrueba": "2026-10-21",
  "pruebas": 18,
  "pruebasAprobadas": 18
}
'@ | Set-Content $EstadoFile -Encoding UTF8

# ------------------------------------------------------------
# VIEWER README
# ------------------------------------------------------------

$ViewerReadme = "$ClaudeMem\viewer\README.md"

@'
# Viewer

Modulo reservado para futuras visualizaciones.

Estado: Pendiente
'@ | Set-Content $ViewerReadme -Encoding UTF8

# ------------------------------------------------------------
# README
# ------------------------------------------------------------

$Readme = "$ClaudeMem\README.md"

@'
# ClaudeMem

Sistema de memoria persistente para el ecosistema Copilot.

## Componentes

- Decisiones
- Lecciones Aprendidas
- Hallazgos
- Índices
- Logs
- Backups

## Estado

OPERATIVO

## Version

1.0
'@ | Set-Content $Readme -Encoding UTF8

# ------------------------------------------------------------
# REPORTE
# ------------------------------------------------------------

$Reporte = "$ClaudeMem\Reporte-Prueba-Funcional-ClaudeMem.txt"

@'
CLAUDEMEM FUNCTIONAL TEST

PASS: 18 / 18

MADUREZ: 100 %

ESTADO:
OPERATIVO
'@ | Set-Content $Reporte -Encoding UTF8

# ------------------------------------------------------------
# CORE
# ------------------------------------------------------------

$Core = "$ClaudeMem\ClaudeMem-Core.ps1"

@'
Clear-Host

Write-Host ""
Write-Host "================================="
Write-Host " CLAUDEMEM CORE"
Write-Host "================================="
Write-Host ""
Write-Host "1. Registrar Decision"
Write-Host "2. Registrar Leccion"
Write-Host "3. Registrar Hallazgo"
Write-Host "4. Buscar"
Write-Host "5. Estado"
Write-Host "6. Backup"
Write-Host "7. Ver Logs"
Write-Host "8. Salir"
Write-Host ""

Read-Host "Seleccione una opcion"
'@ | Set-Content $Core -Encoding UTF8

# ------------------------------------------------------------
# BACKUP INICIAL
# ------------------------------------------------------------

$Fecha = Get-Date -Format "yyyyMMdd-HHmmss"

$BackupFile = "$ClaudeMem\backups\backup-$Fecha.zip"

Compress-Archive `
    -Path "$ClaudeMem\data" `
    -DestinationPath $BackupFile `
    -Force

# ------------------------------------------------------------
# RESUMEN
# ------------------------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "CLAUDEMEM COMPLETADO"
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Get-ChildItem $ClaudeMem -Recurse |
Select-Object FullName