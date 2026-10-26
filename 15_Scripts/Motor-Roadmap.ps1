Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\25_Gestion_Evolucion\ROADMAP_AUTOGENERADO.md"

@"
# ROADMAP AUTOGENERADO

## Completado

✅ Claude‑Mem

✅ Headroom

✅ Observador

## Activo

▶ OmniRoute

## Próximo

▶ Microsoft 365

▶ Seguridad Avanzada

## Futuro

▶ Multi-modelo completo

▶ Autoevolución avanzada
"@ | Set-Content `
$Archivo `
-Encoding UTF8

Write-Host "Roadmap actualizado."