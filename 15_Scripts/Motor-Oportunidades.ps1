Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\OPORTUNIDADES.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# OPORTUNIDAD-$Fecha

Tema:
Headroom

Valor esperado:

Mayor contexto efectivo.

Impacto:

ALTO

Prioridad:

ALTA

---

# OPORTUNIDAD-$Fecha

Tema:
Task Observer

Valor esperado:

Mejora continua automática.

Impacto:

ALTO

Prioridad:

ALTA

---

# OPORTUNIDAD-$Fecha

Tema:
OmniRoute

Valor esperado:

Multi-modelo.

Impacto:

MEDIO

Prioridad:

MEDIA

"@ | Add-Content $Archivo

Write-Host ""
Write-Host "Oportunidades actualizadas."
Write-Host ""