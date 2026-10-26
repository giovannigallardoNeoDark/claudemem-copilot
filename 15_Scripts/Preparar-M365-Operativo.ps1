Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Dest =
"$Base\03_Conocimiento\27_M365_Copilot"

$Files = @(
"CHECKLIST_SHAREPOINT.md",
"CHECKLIST_TEAMS.md",
"CHECKLIST_OUTLOOK.md",
"CHECKLIST_ONEDRIVE.md"
)

foreach($File in $Files)
{
    $Path = Join-Path $Dest $File

    if(!(Test-Path $Path))
    {
        New-Item -ItemType File `
        -Path $Path `
        -Force | Out-Null
    }
}

Write-Host ""
Write-Host "M365 preparado."
Write-Host ""