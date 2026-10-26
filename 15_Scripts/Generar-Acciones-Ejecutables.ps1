Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\ACCIONES_EJECUTABLES.md"

@"

# ACCION-0001

Objetivo:
Certificar Headroom

Prioridad:
Alta

Estado:
En proceso

Impacto:
Mayor contexto efectivo

---

# ACCION-0002

Objetivo:
Resolver OmniRoute

Prioridad:
Media

Estado:
Investigación técnica

Impacto:
Multi-modelo

"@ | Set-Content $Archivo

Write-Host "Acciones ejecutables generadas."