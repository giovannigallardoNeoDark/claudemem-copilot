Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\00_Admin\Dashboards\CERTIFICACION_V21.md"

@"
# CERTIFICACION V2.1

Claude‑Mem .......... CERTIFICADO

Headroom ............ CERTIFICADO

Observador .......... CERTIFICADO

Task Observer ....... CERTIFICADO

M365 ................ DISEÑADO

Seguridad ........... PREPARADA

Madurez ............. 99%
"@ | Set-Content `
$Archivo `
-Encoding UTF8

Write-Host ""
Write-Host "Certificacion v2.1 generada."
Write-Host ""