# ==========================================
# Despliegue Copilot Empresarial v3.0
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-DeployFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $Path = Join-Path $Base $RelativePath

    $Folder = Split-Path $Path -Parent

    if(!(Test-Path $Folder))
    {
        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    $Content |
    Set-Content `
        $Path `
        -Encoding UTF8

    Write-Host "[OK] $RelativePath" `
        -ForegroundColor Green
}

# ==========================================
# CHECKLIST DESPLIEGUE
# ==========================================

New-DeployFile `
"03_Conocimiento\20_Implementacion\CHECKLIST_DESPLIEGUE_V30.md" `
@"
# Checklist Despliegue v3.0

## Microsoft 365

[ ] SharePoint

[ ] Teams

[ ] Outlook

[ ] OneDrive

## Seguridad

[ ] CodeQL

[ ] SonarQube

[ ] Snyk

## Validación

[ ] PASS

## Rollback

[ ] Disponible
"@

# ==========================================
# ROLLBACK
# ==========================================

New-DeployFile `
"03_Conocimiento\22_Operacion\ROLLBACK_V30.md" `
@"
# Rollback v3.0

## Pasos

1. Detener despliegue
2. Restaurar Snapshot
3. Verificar Claude‑Mem
4. Verificar Headroom
5. Actualizar Estado
6. Registrar incidente

## Resultado

Estado restaurado.
"@

# ==========================================
# REGISTRO DESPLIEGUE
# ==========================================

New-DeployFile `
"03_Conocimiento\22_Operacion\REGISTRO_DESPLIEGUE_V30.md" `
@"
# Registro Despliegue

Fecha:

Resultado:

Observaciones:

Estado:

Pendiente
"@

Write-Host ""
Write-Host "Despliegue v3.0 preparado."
Write-Host ""