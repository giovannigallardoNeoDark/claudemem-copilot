Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte =
"$Base\00_Admin\Dashboards\ESTADO_EJECUTIVO.md"

@"
# Estado Ejecutivo

Claude-Mem ........ Operativo

Headroom .......... Instalado

Observador ........ Activo

OmniRoute ......... Investigación

Madurez ........... 98%

Siguiente prioridad:

Resolver OmniRoute
"@ | Set-Content $Reporte

Write-Host ""
Write-Host "Estado Ejecutivo actualizado."
Write-Host ""
