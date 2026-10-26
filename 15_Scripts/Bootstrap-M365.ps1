Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Folder =
"$Base\03_Conocimiento\27_M365_Copilot"

New-Item -ItemType Directory `
-Path $Folder `
-Force | Out-Null

@(
"README.md",
"ARQUITECTURA_M365.md",
"MAPA_INTEGRACIONES.md",
"ROADMAP_M365.md",
"SHAREPOINT.md",
"TEAMS.md",
"OUTLOOK.md",
"ONEDRIVE.md"
) | ForEach-Object {

    $File = Join-Path $Folder $_

    if(!(Test-Path $File))
    {
        New-Item -ItemType File `
        -Path $File `
        -Force | Out-Null
    }
}

Write-Host ""
Write-Host "M365 creado."
Write-Host ""