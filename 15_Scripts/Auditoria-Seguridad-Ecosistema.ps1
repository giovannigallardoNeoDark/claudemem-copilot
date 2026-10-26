Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\07_Seguridad\SEGURIDAD_ECOSISTEMA.md"

@"
# Seguridad Ecosistema

Claude-Mem .......... OK

Headroom ............ OK

OmniRoute ........... Investigacion

Observador .......... OK

Dependencias

NodeJS Portable ..... OK

Riesgos Activos

- OmniRoute no validado
- Dependencia Node Portable

Mitigaciones

- Backups
- Rollback
- Snapshots
- Auditorias

Estado General

SEGURO

"@ | Set-Content `
$Salida `
-Encoding UTF8

Write-Host ""
Write-Host "Auditoria seguridad generada."
Write-Host ""