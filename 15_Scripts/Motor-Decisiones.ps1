# ==========================================
# Motor Decisiones
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\14_Decisiones_Tecnicas\DECISIONES_AUTOGENERADAS.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# DECISION-$Fecha

Tema:

Headroom

Decision:

Mantener componente instalado y
continuar validacion funcional.

Motivo:

Instalacion completada correctamente.

Prioridad:

Alta

Estado:

Aprobada

"@ | Add-Content $Archivo

Write-Host ""
Write-Host "Decision generada."
Write-Host ""
