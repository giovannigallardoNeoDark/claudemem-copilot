#Requires -Version 5.1
# VERSION 1.0.0 - FASE 5A
[CmdletBinding()]
param(
    [string]$RutaSalida = '',
    [switch]$IncluirOpcionales
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$CopilotRoot = Split-Path -Parent $PSScriptRoot
$ClaudeMemRoot = Join-Path $CopilotRoot '11_Herramientas\ClaudeMem'
if ([string]::IsNullOrWhiteSpace($RutaSalida)) {
    $RutaSalida = Join-Path $ClaudeMemRoot 'config\manifiesto-componentes.json'
}
$Obligatorios = @(
    'Preparar-Contexto-Copilot.ps1',
    'Invocar-ClaudeMem-Copilot.ps1',
    'Convertir-Registro-Contexto-Legible.ps1',
    'Generar-Resumen-Sesion-ClaudeMem.ps1',
    'Gestionar-Sesiones-ClaudeMem.ps1',
    'Gestionar-Candidatos-ClaudeMem.ps1',
    'Registrar-Actividad-ClaudeMem.ps1',
    'Filtrar-Contenido-Sensible-ClaudeMem.ps1',
    'Auditar-Contexto-ClaudeMem.ps1',
    'Auditar-Ranking-Contexto-ClaudeMem.ps1',
    'Auditar-Puerta-Contexto-Copilot.ps1',
    'Auditar-Operacion-ClaudeMem.ps1',
    'Auditar-Esquema-Memoria-Episodica-ClaudeMem.ps1',
    'Auditar-Memoria-Episodica-ClaudeMem.ps1',
    'ClaudeMem-Copilot-Panel.ps1',
    'ClaudeMem-Copilot-Launcher.ps1',
    'Gestionar-Historial-Contextos-ClaudeMem.ps1'
)
$Opcionales = @(
    'Prueba-Captura-Segura-ClaudeMem.ps1',
    'Prueba-Resumen-Contexto-ClaudeMem.ps1',
    'Prueba-Contexto-Progresivo-ClaudeMem.ps1',
    'Prueba-Integracion-Copilot-ClaudeMem.ps1',
    'Prueba-Flujo-Operativo-ClaudeMem.ps1',
    'Reparar-Almacen-Sesiones-ClaudeMem.ps1',
    'Reparar-Almacen-Resumenes-ClaudeMem.ps1',
    'Sincronizar-Bidireccional-ClaudeMem.ps1'
)
$Nombres = @($Obligatorios)
if ($IncluirOpcionales) { $Nombres += $Opcionales }
$Componentes = @()
foreach ($Nombre in $Nombres) {
    $Ruta = Join-Path $PSScriptRoot $Nombre
    $Existe = Test-Path -LiteralPath $Ruta -PathType Leaf
    $Version = ''
    $Hash = ''
    $Tamano = 0
    $Fecha = ''
    if ($Existe) {
        $Item = Get-Item -LiteralPath $Ruta
        $Tamano = [int64]$Item.Length
        $Fecha = $Item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
        $Hash = (Get-FileHash -LiteralPath $Ruta -Algorithm SHA256).Hash
        $LineaVersion = Get-Content -LiteralPath $Ruta -TotalCount 8 | Where-Object { $_ -match '^# VERSION\s+(.+)$' } | Select-Object -First 1
        if ($LineaVersion -match '^# VERSION\s+(.+)$') { $Version = $Matches[1].Trim() }
    }
    $Componentes += [PSCustomObject][ordered]@{
        nombre = $Nombre
        rutaRelativa = "15_Scripts\$Nombre"
        obligatorio = ($Nombre -in $Obligatorios)
        existe = $Existe
        version = $Version
        tamano = $Tamano
        sha256 = $Hash
        fechaModificacion = $Fecha
        estado = $(if ($Existe) { 'ACTIVO' } else { 'FALTANTE' })
    }
}
$Manifiesto = [PSCustomObject][ordered]@{
    producto = 'ClaudeMem Potenciado'
    fase = '5A'
    versionEsquema = '1.0.0'
    generado = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    raiz = $CopilotRoot
    componentes = $Componentes
}
$Carpeta = Split-Path -Parent ([IO.Path]::GetFullPath($RutaSalida))
New-Item -ItemType Directory -Path $Carpeta -Force | Out-Null
[IO.File]::WriteAllText([IO.Path]::GetFullPath($RutaSalida), ($Manifiesto | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($true))
$Faltantes = @($Componentes | Where-Object { $_.obligatorio -and -not $_.existe })
$Manifiesto
if ($Faltantes.Count -gt 0) { exit 1 }
