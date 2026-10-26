# ==========================================
# Observador Automatico v2
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Hallazgos =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\HALLAZGOS.md"

$Patrones =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\PATRONES.md"

$Mejoras =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\MEJORAS_AUTOGENERADAS.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# PATRON-$Fecha

Tema:
Mejora Continua

Observacion:

El ecosistema genera hallazgos de forma regular.

Recomendacion:

Priorizar capacidades reales antes
de nueva documentacion.

"@ | Add-Content $Patrones

@"

# MA-$Fecha

Prioridad:
Alta

Mejora:

Validar completamente Headroom.

Estado:
Pendiente

"@ | Add-Content $Mejoras

Write-Host ""
Write-Host "Patrones y mejoras generados."
Write-Host ""