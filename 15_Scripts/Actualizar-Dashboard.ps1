Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Dashboard =
"$Base\00_Admin\Dashboards\ESTADO_OPERACIONAL.md"

@"
# Estado Operacional

Claude-Mem .......... Operativo

Headroom ............ Instalado

OmniRoute ........... Investigacion

Task Observer ....... Activo

Madurez Estimada .... 98%

"@ | Set-Content $Dashboard

Write-Host "Dashboard actualizado."
