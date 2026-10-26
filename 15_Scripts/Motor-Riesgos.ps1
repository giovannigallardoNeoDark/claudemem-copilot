# ==========================================
# Motor Riesgos
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Riesgos =
"$Base\03_Conocimiento\18_Gobierno_IA\RIESGOS_ACTIVOS.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# RIESGO-$Fecha

Tema:
OmniRoute

Estado:
Investigacion tecnica

Impacto:
Medio

Probabilidad:
Media

Mitigacion:
No bloquear roadmap

---

# RIESGO-$Fecha

Tema:
Dependencia Memoria

Estado:
Controlado

Impacto:
Bajo

Mitigacion:
Base conocimiento local
Claude-Mem local

"@ | Add-Content $Riesgos

Write-Host ""
Write-Host "Riesgos actualizados."
Write-Host ""