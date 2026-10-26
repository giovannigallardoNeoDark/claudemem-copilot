# ==========================================
# Observador Automatico v3
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Prioridades =
"$Base\03_Conocimiento\25_Gestion_Evolucion\REGISTRO_PRIORIDADES.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

## PRIORIDAD-$Fecha

Impacto:
ALTO

Accion:

Validar completamente Headroom.

Motivo:

Instalado pero no validado
operacionalmente.

Estado:

Pendiente

"@ | Add-Content $Prioridades

Write-Host ""
Write-Host "Prioridad registrada."
Write-Host ""