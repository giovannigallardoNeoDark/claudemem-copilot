Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\06_Automatizacion\AUTOMATIZACIONES_CERTIFICADAS.md"

@"
# Automatizaciones Certificadas

AUTO-0001

Actualizar Dashboard

Estado:
Certificada

---

AUTO-0002

Actualizar Estado Maestro

Estado:
Certificada

---

AUTO-0003

Actualizar Beneficios

Estado:
Certificada

---

AUTO-0004

Actualizar Prioridades

Estado:
Certificada
"@ | Set-Content $Archivo -Encoding UTF8

Write-Host ""
Write-Host "Automatizaciones certificadas."
Write-Host ""