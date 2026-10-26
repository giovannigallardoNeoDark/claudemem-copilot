# ==========================================
# Motor de Evolucion
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Destino =
"$Base\03_Conocimiento\25_Gestion_Evolucion\REGISTRO_PRIORIDADES.md"

@"

# PRIORIDAD-0001

Tema:
Validar Headroom

Impacto:
Alto

Motivo:
Instalado pero no validado.

Estado:
Pendiente

---

# PRIORIDAD-0002

Tema:
Resolver OmniRoute

Impacto:
Alto

Motivo:
Componente estratégico del roadmap.

Estado:
Pendiente

"@ | Add-Content $Destino

Write-Host ""
Write-Host "Prioridades actualizadas."
Write-Host ""