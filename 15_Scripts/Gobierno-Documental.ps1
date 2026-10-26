# ==========================================
# Gobierno Documental
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\18_Gobierno_IA\GOBIERNO_DOCUMENTAL.md"

@"
# Gobierno Documental

## Documentación Oficial

Ubicación:
SharePoint

## Conocimiento Vivo

Ubicación:
Base Conocimiento Viva

## Decisiones Técnicas

Ubicación:
Decisiones Técnicas

## Lecciones Aprendidas

Ubicación:
Lecciones Aprendidas

## Procedimientos

Ubicación:
Procedimientos

## Skills

Ubicación:
Skills

## Prompts

Ubicación:
Prompts

## Regla

Todo conocimiento reutilizable debe:
- Documentarse
- Validarse
- Certificarse
- Mantener trazabilidad
"@ | Set-Content `
$Archivo `
-Encoding UTF8

Write-Host ""
Write-Host "Gobierno Documental actualizado."