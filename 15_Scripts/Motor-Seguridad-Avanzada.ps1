# ==========================================
# Seguridad Avanzada
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\07_Seguridad\ROADMAP_SEGURIDAD.md"

@"
# Roadmap Seguridad

## Operativo

✅ Semgrep

## Pendiente

⏳ CodeQL

⏳ SonarQube

⏳ Snyk

## Objetivo

Seguridad integral:

- SAST
- Dependencias
- Vulnerabilidades
- Credenciales
- Auditoría continua
"@ | Set-Content `
$Archivo `
-Encoding UTF8

Write-Host ""
Write-Host "Roadmap Seguridad actualizado."