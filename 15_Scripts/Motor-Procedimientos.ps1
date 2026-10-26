Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\03_Conocimiento\12_Procedimientos\PROCEDIMIENTOS_AUTOGENERADOS.md"

@"

# PROC-0001

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

# PROC-0002

Tema:

Mejora Continua

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

"@ | Set-Content $Salida

Write-Host "Procedimientos generados."
