Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\ESTADO_CONOCIMIENTO.md"

@"
# Estado Conocimiento

Lecciones ............ Activas
Decisiones ........... Activas
Hallazgos ............ Activos
Patrones ............. Activos
Mejoras .............. Activas
Prioridades .......... Activas
Seguimiento .......... Activo

Madurez estimada ..... 99%
"@ | Set-Content $Salida

Write-Host ""
Write-Host "Metricas actualizadas."
Write-Host ""