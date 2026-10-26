# ==========================================
# Auditoria ClaudeMem Potenciado
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte = Join-Path `
$Base `
"03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\INVENTARIO_CLAUDEMEM_POTENCIADO.md"

function Test-Comp {
    param([string]$Ruta)

    return (
        Test-Path (
            Join-Path $Base $Ruta
        )
    )
}

$Items = @()

$Items += [PSCustomObject]@{
    Componente = "MCP"
    Estado = if(Test-Comp "03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\INVENTARIO_MCP.md"){"Implementado"}else{"Pendiente"}
}

$Items += [PSCustomObject]@{
    Componente = "Pruebas MCP"
    Estado = if(Test-Comp "03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\PRUEBAS_MCP.md"){"Implementado"}else{"Pendiente"}
}

$Items += [PSCustomObject]@{
    Componente = "Matriz Integracion"
    Estado = if(Test-Comp "03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\MATRIZ_INTEGRACION.md"){"Implementado"}else{"Pendiente"}
}

$Items += [PSCustomObject]@{
    Componente = "Estado Absorcion"
    Estado = if(Test-Comp "03_Conocimiento\26_Integracion_ClaudeMem_Potenciado\ESTADO_ABSORCION.md"){"Implementado"}else{"Pendiente"}
}

$Out = @()

$Out += "# INVENTARIO CLAUDEMEM POTENCIADO"
$Out += ""
$Out += "Fecha: $(Get-Date)"
$Out += ""

foreach($I in $Items)
{
    $Out += "- $($I.Componente): $($I.Estado)"
}

$Out | Set-Content `
$Reporte `
-Encoding UTF8

Write-Host ""
Write-Host "Inventario generado." `
-ForegroundColor Green

Write-Host $Reporte `
-ForegroundColor Yellow

Write-Host ""