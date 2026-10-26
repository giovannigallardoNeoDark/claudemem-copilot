Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Salida =
"$Base\03_Conocimiento\11_Skills\SKILLS_AUTOGENERADAS.md"

@"

# SKILL-0001

Nombre:

Validacion Node Portable

Origen:

Lecciones aprendidas

Beneficio:

Detectar automaticamente:

- node.exe
- npm.cmd
- npx.cmd

---

# SKILL-0002

Nombre:

Auditoria Ecosistema

Origen:

Madurez Continua

Beneficio:

Verificar salud del ecosistema.

"@ | Set-Content $Salida

Write-Host "Skills generadas."