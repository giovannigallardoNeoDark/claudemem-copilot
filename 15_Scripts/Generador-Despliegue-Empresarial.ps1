# ==========================================
# Generador Despliegue Empresarial
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-EnterpriseFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $Path = Join-Path $Base $RelativePath

    $Folder = Split-Path $Path -Parent

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory `
        -Path $Folder `
        -Force | Out-Null
    }

    $Content | Set-Content `
    $Path `
    -Encoding UTF8

    Write-Host "[OK] $RelativePath" `
    -ForegroundColor Green
}

# ==========================================
# MICROSOFT GRAPH
# ==========================================

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Connect-M365.ps1" `
'Connect-MgGraph -Scopes "User.Read","Sites.Read.All","Files.Read.All","Group.Read.All","Mail.Read"'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Test-M365.ps1" `
'Get-MgContext'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Get-SharePointSites.ps1" `
'Get-MgSite -All'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Get-Teams.ps1" `
'Get-MgGroup -Filter "resourceProvisioningOptions/Any(x:x eq ''Team'')"'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Get-OneDrive.ps1" `
'Get-MgDrive'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Get-OutlookFolders.ps1" `
'Get-MgUserMailFolder'

New-EnterpriseFile `
"15_Scripts\MicrosoftGraph\Disconnect-M365.ps1" `
'Disconnect-MgGraph'

# ==========================================
# CODEQL
# ==========================================

New-EnterpriseFile `
".github\workflows\codeql.yml" `
@"
name: CodeQL

on:
  push:
  pull_request:

jobs:
  analyze:

    runs-on: ubuntu-latest

    permissions:
      security-events: write

    steps:

      - uses: actions/checkout@v4

      - uses: github/codeql-action/init@v3
        with:
          languages: python

      - uses: github/codeql-action/analyze@v3
"@

# ==========================================
# SEGURIDAD
# ==========================================

New-EnterpriseFile `
"07_Seguridad\PLAN_CODEQL.md" `
"# Plan CodeQL"

New-EnterpriseFile `
"07_Seguridad\PLAN_SONARQUBE.md" `
"# Plan SonarQube"

New-EnterpriseFile `
"07_Seguridad\PLAN_SNYK.md" `
"# Plan Snyk"

New-EnterpriseFile `
"07_Seguridad\CHECKLIST_CODEQL.md" `
"# Checklist CodeQL"

New-EnterpriseFile `
"07_Seguridad\CHECKLIST_SONARQUBE.md" `
"# Checklist SonarQube"

New-EnterpriseFile `
"07_Seguridad\CHECKLIST_SNYK.md" `
"# Checklist Snyk"

# ==========================================
# DESPLIEGUE
# ==========================================

New-EnterpriseFile `
"03_Conocimiento\20_Implementacion\CHECKLIST_DESPLIEGUE_EMPRESARIAL.md" `
@"
# Checklist

[ ] M365

[ ] CodeQL

[ ] SonarQube

[ ] Snyk

[ ] Validacion

[ ] Rollback
"@

New-EnterpriseFile `
"03_Conocimiento\20_Implementacion\ROLLBACK_EMPRESARIAL.md" `
@"
# Rollback

1. Restaurar Snapshot
2. Restaurar Estado Maestro
3. Restaurar Centro Control
4. Registrar incidente
"@

# ==========================================
# DASHBOARD
# ==========================================

New-EnterpriseFile `
"00_Admin\Dashboards\ESTADO_DESPLIEGUE_EMPRESARIAL.md" `
@"
# Estado Despliegue

Microsoft 365 .... Preparado

CodeQL ........... Preparado

SonarQube ........ Preparado

Snyk ............. Preparado

OmniRoute ........ Investigacion
"@

Write-Host ""
Write-Host "========================================="
Write-Host " DESPLIEGUE EMPRESARIAL PREPARADO"
Write-Host "========================================="
Write-Host ""