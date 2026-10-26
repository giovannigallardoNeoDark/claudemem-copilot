# ==========================================
# Motor Capacidades
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\25_Gestion_Evolucion\CAPACIDADES.md"

@"
# Capacidades Ecosistema

## Operativas

✅ Claude-Mem
✅ Observador Automático
✅ Hallazgos
✅ Patrones
✅ Mejoras
✅ Prioridades
✅ Acciones
✅ Seguimiento
✅ Beneficios
✅ Recomendaciones
✅ Dashboard
✅ Centro de Control

## Parciales

✅ Headroom

## Investigación

⏳ OmniRoute

## Futuras

⏳ Multi-modelo completo
⏳ Auto-evolución avanzada

"@ | Set-Content `
$Archivo `
-Encoding UTF8

Write-Host ""
Write-Host "Capacidades actualizadas."
Write-Host ""
