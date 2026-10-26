Clear-Host

Write-Host ""
Write-Host "Validación v3.0"
Write-Host ""

$Checks = @(
"Microsoft 365",
"CodeQL",
"SonarQube",
"Snyk"
)

foreach($Item in $Checks)
{
    Write-Host "[PENDIENTE] $Item"
}

Write-Host ""
Write-Host "Completar checklist de despliegue."
Write-Host ""