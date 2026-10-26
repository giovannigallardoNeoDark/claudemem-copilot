Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @(

"03_Conocimiento\27_M365_Copilot\SHAREPOINT_DESPLIEGUE_REAL.md",

"03_Conocimiento\27_M365_Copilot\TEAMS_DESPLIEGUE_REAL.md",

"03_Conocimiento\27_M365_Copilot\OUTLOOK_DESPLIEGUE_REAL.md",

"07_Seguridad\CODEQL_DESPLIEGUE_REAL.md",

"07_Seguridad\SONARQUBE_DESPLIEGUE_REAL.md",

"07_Seguridad\SNYK_DESPLIEGUE_REAL.md"

)

$OK = 0

foreach($Item in $Checks)
{
    if(Test-Path (Join-Path $Base $Item))
    {
        $OK++
    }
}

$Score = [math]::Round(($OK / $Checks.Count) * 100)

Write-Host ""
Write-Host "VALIDACION V4"
Write-Host ""
Write-Host "$Score %"
Write-Host ""

if($Score -eq 100)
{
    Write-Host "LISTO PARA DESPLIEGUE" `
    -ForegroundColor Green
}