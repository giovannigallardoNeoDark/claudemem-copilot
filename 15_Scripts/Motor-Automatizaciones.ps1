Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\03_Conocimiento\06_Automatizacion\AUTOMATIZACIONES_AUTOGENERADAS.md"

@"

# AUTO-0001

Actualizar Dashboard

Frecuencia:

Diaria

---

# AUTO-0002

Actualizar Estado Maestro

Frecuencia:

Diaria

---

# AUTO-0003

Actualizar Beneficios

Frecuencia:

Diaria

---

# AUTO-0004

Actualizar Prioridades

Frecuencia:

Diaria

"@ | Set-Content $Salida

Write-Host "Automatizaciones generadas."