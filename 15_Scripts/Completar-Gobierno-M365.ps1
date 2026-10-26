Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\27_M365_Copilot\GOBIERNO_M365.md"

@"
# Gobierno Microsoft 365

SharePoint
→ Documentación oficial

Teams
→ Colaboración
→ Seguimiento
→ Notificaciones

Outlook
→ Comunicaciones oficiales
→ Informes ejecutivos

OneDrive
→ Trabajo individual
→ Archivos temporales

Copilot M365
→ Consumo del conocimiento corporativo

Regla:

Todo conocimiento reutilizable debe terminar en SharePoint.
"@ | Set-Content $Archivo -Encoding UTF8

Write-Host ""
Write-Host "Gobierno M365 completado."
Write-Host ""