# ==========================================
# Centro Control Ecosistema
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\00_Admin\Dashboards\CENTRO_CONTROL.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"
# CENTRO DE CONTROL

Fecha: $Fecha

## Componentes

Claude-Mem .......... Operativo

Headroom ............ Operativo

OmniRoute ........... Investigacion

Task Observer ....... Activo

---

## Conocimiento

Hallazgos ........... Activos

Patrones ............ Activos

Mejoras ............. Activas

Prioridades ......... Activas

Acciones ............ Activas

Beneficios .......... Activos

Decisiones .......... Activas

---

## Madurez

Ecosistema .......... 99%

Integraciones ....... 90%

---

## Prioridad Actual

1. Resolver OmniRoute

2. Consolidar Task Observer

3. Uso productivo ecosistema

"@ | Set-Content `
$Salida `
-Encoding UTF8

Write-Host ""
Write-Host "Centro de Control actualizado."
Write-Host ""