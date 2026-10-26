Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-Readme {

    param(
        [string]$Folder,
        [string]$Title,
        [string]$Description
    )

    $ReadmePath = Join-Path $Base "$Folder\README.md"

    if (!(Test-Path $ReadmePath)) {

        $Content = @"
# $Title

$Description

## Contenido

Pendiente de completar.

"@

        $Content | Set-Content `
            $ReadmePath `
            -Encoding UTF8

        Write-Host "[CREADO] $ReadmePath" `
            -ForegroundColor Green
    }
    else {

        Write-Host "[EXISTE] $ReadmePath" `
            -ForegroundColor Yellow
    }
}

New-Readme ".github" "GitHub" "Configuración GitHub"
New-Readme ".github\ISSUE_TEMPLATE" "Issue Template" "Plantillas GitHub"
New-Readme "00_Admin\Dashboards" "Dashboards" "Paneles de control"
New-Readme "00_Admin\Gobierno" "Gobierno" "Reglas y políticas"
New-Readme "00_Admin\Plantillas" "Plantillas" "Plantillas corporativas"
New-Readme "00_Admin\Wiki" "Wiki" "Conocimiento corporativo"
New-Readme "00_Admin\Arquitectura\ADR" "ADR" "Architecture Decision Records"
New-Readme "01_FIOS\DOCUMENTACION" "Documentacion FIOS" "Documentación de FIOS"
New-Readme "02_NeoDark\DOCUMENTACION" "Documentacion NeoDark" "Documentación de NeoDark"
New-Readme "07_Seguridad\CodeReview" "Code Review" "Revisión de código"
New-Readme "07_Seguridad\SecurityReview" "Security Review" "Revisión de seguridad"

Write-Host ""
Write-Host "Bootstrap Fix Readme terminado." `
-ForegroundColor Cyan