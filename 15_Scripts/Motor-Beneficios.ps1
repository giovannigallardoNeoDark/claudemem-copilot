# ==========================================
# Motor Beneficios
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Beneficios =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\BENEFICIOS.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# BENEFICIO-$Fecha

Origen:

Claude-Mem

Beneficio:

Memoria persistente y recuperacion de contexto.

Impacto:

Alto

Estado:

Activo

---

# BENEFICIO-$Fecha

Origen:

Headroom

Beneficio:

Preparacion para optimizacion de contexto.

Impacto:

Alto

Estado:

Activo

---

# BENEFICIO-$Fecha

Origen:

Observador

Beneficio:

Generacion automatica de hallazgos,
mejoras y prioridades.

Impacto:

Alto

Estado:

Activo

"@ | Add-Content $Beneficios

Write-Host ""
Write-Host "Beneficios registrados."
Write-Host ""