#Requires -Version 5.1
# VERSION 1.0.0 - FASE 7B
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$RutaTasksJson,
    [switch]$Aplicar
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ScriptsRoot = $PSScriptRoot
$CopilotRoot = Split-Path -Parent $ScriptsRoot
$VscodeRoot = Join-Path $CopilotRoot '.vscode'
$Destino = Join-Path $VscodeRoot 'tasks.json'
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
$BackupsRoot = Join-Path $ClaudeMemRoot 'backups'
if (-not (Test-Path -LiteralPath $RutaTasksJson -PathType Leaf)) { throw "No existe tasks.json: $RutaTasksJson" }
try { $null = Get-Content -LiteralPath $RutaTasksJson -Raw | ConvertFrom-Json -ErrorAction Stop } catch { throw "tasks.json no contiene JSON valido: $($_.Exception.Message)" }
$Contenido = Get-Content -LiteralPath $RutaTasksJson -Raw
$Requeridas = @('ClaudeMem: ciclo automatico','ClaudeMem: ciclo con reparacion','ClaudeMem: abrir panel','ClaudeMem: obtener estado','ClaudeMem: abrir ultimo informe')
foreach ($Etiqueta in $Requeridas) { if ($Contenido -notmatch [regex]::Escape($Etiqueta)) { throw "Falta tarea obligatoria: $Etiqueta" } }
Write-Host "Destino: $Destino"
if (-not $Aplicar) { Write-Host 'SIMULACION APROBADA. Use -Aplicar para instalar.' -ForegroundColor Yellow; return }
New-Item -ItemType Directory -Path $VscodeRoot -Force | Out-Null
New-Item -ItemType Directory -Path $BackupsRoot -Force | Out-Null
if (Test-Path -LiteralPath $Destino -PathType Leaf) {
    $Backup = Join-Path $BackupsRoot ("tasks-pre-7B-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Copy-Item -LiteralPath $Destino -Destination $Backup -Force
    Write-Host "Backup: $Backup"
}
Copy-Item -LiteralPath $RutaTasksJson -Destination $Destino -Force
$Instalado = Get-Content -LiteralPath $Destino -Raw | ConvertFrom-Json -ErrorAction Stop
if ($Instalado.version -ne '2.0.0' -or @($Instalado.tasks).Count -lt 5) { throw 'La validacion posterior de tasks.json fallo.' }
Write-Host 'TAREAS DE VISUAL STUDIO CODE INSTALADAS' -ForegroundColor Green
