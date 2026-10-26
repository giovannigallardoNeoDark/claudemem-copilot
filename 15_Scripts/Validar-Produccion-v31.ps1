Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @(

"$Base\03_Conocimiento\27_M365_Copilot\M365_OPERATIVO_REAL.md",

"$Base\07_Seguridad\CODEQL_OPERATIVO.md",

"$Base\07_Seguridad\SONARQUBE_OPERATIVO.md",

"$Base\07_Seguridad\SNYK_OPERATIVO.md",

"$Base\00_Admin\Dashboards\CERTIFICACION_PRODUCCION.md"

)

$OK = 0

foreach($Item in $Checks)
{
    if(Test-Path $Item)
    {
        $OK++
    }
}

$Score = [math]::Round(($OK / $Checks.Count) * 100)

Write-Host ""
Write-Host "VALIDACION PRODUCCION v3.1"
Write-Host ""

Write-Host "$Score %"

Write-Host ""

if($Score -eq 100)
{
    Write-Host "DESPLIEGUE LISTO" `
    -ForegroundColor Green
}
else
{
    Write-Host "REVISAR COMPONENTES" `
    -ForegroundColor Yellow
}