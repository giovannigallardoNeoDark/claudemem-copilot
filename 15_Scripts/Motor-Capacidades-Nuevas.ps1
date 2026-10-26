Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\25_Gestion_Evolucion\NUEVAS_CAPACIDADES.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# CAPACIDAD-$Fecha

Origen:

Claude-Mem

Nueva capacidad:

Memoria corporativa persistente.

---

# CAPACIDAD-$Fecha

Origen:

Headroom

Nueva capacidad:

Optimización de contexto.

---

# CAPACIDAD-$Fecha

Origen:

Observador

Nueva capacidad:

Detección automática de mejoras.

"@ | Add-Content $Archivo

Write-Host ""
Write-Host "Capacidades registradas."
Write-Host ""