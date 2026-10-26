Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\12_Procedimientos\PROCEDIMIENTOS_CERTIFICADOS.md"

@"
# Procedimientos Certificados

PROC-0001

Tema:
Instalacion Herramientas IA

Flujo:

Preparar
↓
Auditar
↓
Implementar
↓
Validar

---

PROC-0002

Tema:
Gestion Conocimiento

Flujo:

Hallazgo
↓
Patron
↓
Mejora
↓
Prioridad
↓
Accion
"@ | Set-Content $Archivo -Encoding UTF8

Write-Host ""
Write-Host "Procedimientos certificados."
Write-Host ""