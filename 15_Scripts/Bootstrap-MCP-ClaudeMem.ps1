# ==========================================
# Bootstrap MCP ClaudeMem
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-McpFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath

    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder)) {

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    if (!(Test-Path $FullPath)) {

        $Content |
        Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
}

# ==========================================
# ESTRUCTURA
# ==========================================

New-McpFile `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\README.md" `
@"
# Integracion ClaudeMem Potenciado

Objetivo:

Absorber capacidades avanzadas del ecosistema ClaudeMem.
"@

New-McpFile `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\INVENTARIO_MCP.md" `
@"
# Inventario MCP

buscar_contexto

consultar_decisiones

consultar_lecciones

consultar_hallazgos

consultar_historial

obtener_estado_claudemem
"@

New-McpFile `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\PRUEBAS_MCP.md" `
@"
# Pruebas MCP

MCP-001
Consultar Decisiones

MCP-002
Consultar Lecciones

MCP-003
Consultar Hallazgos

MCP-004
Consultar Historial

MCP-005
Estado ClaudeMem
"@

New-McpFile `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\MATRIZ_INTEGRACION.md" `
@"
# Matriz Integracion

| Componente | Estado |
|------------|--------|
| MCP | Pendiente |
| Orquestador | Pendiente |
| Analitica | Pendiente |
| Observacion Operativa | Pendiente |
| M365 Agent | Pendiente |
"@

New-McpFile `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\ESTADO_ABSORCION.md" `
@"
# Estado Absorcion

ClaudeMem Potenciado

Estado:

En proceso
"@

Write-Host ""
Write-Host "Bootstrap MCP ClaudeMem completado." `
-ForegroundColor Cyan
Write-Host ""