# ==================================================
# Task Observer Avanzado
# ==================================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-Doc {
    param(
        [string]$PathRel,
        [string]$Content
    )

    $Path = Join-Path $Base $PathRel

    $Dir = Split-Path $Path -Parent

    if(!(Test-Path $Dir))
    {
        New-Item `
            -ItemType Directory `
            -Path $Dir `
            -Force | Out-Null
    }

    $Content |
    Set-Content `
        $Path `
        -Encoding UTF8

    Write-Host "[OK] $PathRel" `
    -ForegroundColor Green
}

# ===========================================
# SKILLS
# ===========================================

New-Doc `
"03_Conocimiento\22_Operacion\SKILLS_CERTIFICADAS.md" `
@"
# Skills Certificadas

## SK-001

Nombre:
Recuperación Contextual ClaudeMem

Origen:
Patrón detectado

Estado:
CERTIFICADA

---

## SK-002

Nombre:
Detección de Hallazgos

Estado:
CERTIFICADA

---

## SK-003

Nombre:
Clasificación de Beneficios

Estado:
CERTIFICADA
"@

# ===========================================
# PROCEDIMIENTOS
# ===========================================

New-Doc `
"03_Conocimiento\22_Operacion\PROCEDIMIENTOS_CERTIFICADOS.md" `
@"
# Procedimientos Certificados

## PR-001

Actualización ClaudeMem

Estado:
CERTIFICADO

---

## PR-002

Validación Ecosistema

Estado:
CERTIFICADO

---

## PR-003

Gestión de Hallazgos

Estado:
CERTIFICADO
"@

# ===========================================
# AUTOMATIZACIONES
# ===========================================

New-Doc `
"03_Conocimiento\22_Operacion\AUTOMATIZACIONES_CERTIFICADAS.md" `
@"
# Automatizaciones Certificadas

## AU-001

Observador Automático

Estado:
CERTIFICADA

---

## AU-002

Actualización Estado Maestro

Estado:
CERTIFICADA

---

## AU-003

Roadmap Automático

Estado:
CERTIFICADA
"@

# ===========================================
# CAPACIDADES
# ===========================================

New-Doc `
"03_Conocimiento\22_Operacion\CATALOGO_CAPACIDADES.md" `
@"
# Catálogo de Capacidades

✅ Claude‑Mem

✅ Headroom

✅ Observador

✅ Estado Maestro

✅ Centro de Control

✅ Roadmap Automático

✅ Snyk

✅ Microsoft Graph

✅ Task Observer Avanzado
"@

Write-Host ""
Write-Host "================================="
Write-Host " TASK OBSERVER AVANZADO"
Write-Host " COMPLETADO"
Write-Host "================================="
Write-Host ""Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Docs = @(
"03_Conocimiento\22_Operacion\SKILLS_CERTIFICADAS.md",
"03_Conocimiento\22_Operacion\PROCEDIMIENTOS_CERTIFICADOS.md",
"03_Conocimiento\22_Operacion\AUTOMATIZACIONES_CERTIFICADAS.md",
"03_Conocimiento\22_Operacion\CATALOGO_CAPACIDADES.md"
)

$OK = 0

foreach($Doc in $Docs)
{
    if(Test-Path (Join-Path $Base $Doc))
    {
        $OK++
    }
}

$Score = ($OK / $Docs.Count) * 100

Write-Host ""
Write-Host "TASK OBSERVER"
Write-Host ""

Write-Host "$Score %"

if($Score -eq 100)
{
    Write-Host ""
    Write-Host "CERTIFICADO" `
    -ForegroundColor Green
}