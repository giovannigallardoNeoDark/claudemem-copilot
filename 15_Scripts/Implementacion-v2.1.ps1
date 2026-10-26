Clear-Host

$Scripts = @(
".\Motor-Skills-v2.ps1",
".\Motor-Procedimientos-v2.ps1",
".\Motor-Automatizaciones-v2.ps1",
".\Completar-Gobierno-M365.ps1",
".\Preparar-Seguridad-v2.ps1",
".\Motor-Riesgos.ps1",
".\Motor-Oportunidades.ps1",
".\Motor-Beneficios.ps1",
".\Motor-Capacidades.ps1",
".\Motor-Roadmap.ps1"
)

foreach($Script in $Scripts)
{
    if(Test-Path $Script)
    {
        PowerShell.exe `
        -ExecutionPolicy Bypass `
        -File $Script
    }
}

Write-Host ""
Write-Host "Copilot Empresarial v2.1 actualizado."
Write-Host ""
