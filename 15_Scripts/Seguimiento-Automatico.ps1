# ==========================================
# Seguimiento Automatico
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Seguimiento =
"$Base\03_Conocimiento\25_Gestion_Evolucion\SEGUIMIENTO.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# SEGUIMIENTO-$Fecha

Accion:

Validar Headroom

Estado:

Pendiente

Responsable:

Copilot Empresarial

Proxima Revision:

7 dias

"@ | Add-Content $Seguimiento

Write-Host ""
Write-Host "Seguimiento actualizado."
Write-Host ""