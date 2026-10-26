Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\07_Seguridad\PLAN_SEGURIDAD_V2.md"

@"
# Seguridad V2

Fase 1

✅ Semgrep

Fase 2

⏳ CodeQL

Fase 3

⏳ SonarQube

Fase 4

⏳ Snyk

Objetivo:

Seguridad completa:

- SAST
- Dependencias
- Vulnerabilidades
- Credenciales
- Auditoría continua
"@ | Set-Content $Archivo -Encoding UTF8

Write-Host ""
Write-Host "Seguridad v2 preparada."
Write-Host ""