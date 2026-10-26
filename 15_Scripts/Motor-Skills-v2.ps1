Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Archivo =
"$Base\03_Conocimiento\11_Skills\SKILLS_CERTIFICADAS.md"

@"
# Skills Certificadas

SKILL-0001

Nombre:
Validacion Node Portable

Estado:
Certificada

Beneficio:
Detectar automaticamente node.exe, npm.cmd y npx.cmd.

---

SKILL-0002

Nombre:
Validacion Claude-Mem

Estado:
Certificada

Beneficio:
Verificar memoria persistente.

---

SKILL-0003

Nombre:
Auditoria Ecosistema

Estado:
Certificada

Beneficio:
Verificar salud general del ecosistema.
"@ | Set-Content $Archivo -Encoding UTF8

Write-Host ""
Write-Host "Skills certificadas actualizadas."
Write-Host ""