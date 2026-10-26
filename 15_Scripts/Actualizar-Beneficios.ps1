Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\BENEFICIOS.md"

@"
# Beneficios Acumulados

Claude-Mem

Beneficio:
Memoria Persistente

Estado:
Operativo

---

Headroom

Beneficio:
Optimización Contexto

Estado:
Instalado

---

Observador

Beneficio:
Mejora Continua

Estado:
Activo

"@ | Set-Content $Archivo

Write-Host "Beneficios actualizados."