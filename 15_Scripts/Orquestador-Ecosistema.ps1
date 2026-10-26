# ==========================================
# Orquestador Ecosistema
# ==========================================

Clear-Host

Write-Host ""
Write-Host "========================================="
Write-Host " ORQUESTADOR ECOSISTEMA"
Write-Host "========================================="
Write-Host ""

$Scripts = @(

".\Motor-Riesgos.ps1",
".\Motor-Oportunidades.ps1",
".\Motor-Beneficios.ps1",
".\Motor-Capacidades.ps1",
".\Motor-Decisiones.ps1",
".\Observador-Automatico-v7.ps1",
".\Actualizar-Dashboard.ps1",
".\Actualizar-Estado-Maestro.ps1",
".\Consolidar-Ecosistema.ps1"

)

foreach($Script in $Scripts)
{
    if(Test-Path $Script)
    {
        Write-Host ""
        Write-Host "[EJECUTANDO] $Script" -ForegroundColor Cyan

        PowerShell.exe `
            -ExecutionPolicy Bypass `
            -File $Script
    }
    else
    {
        Write-Host ""
        Write-Host "[FALTA] $Script" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host " ECOSISTEMA ACTUALIZADO"
Write-Host "========================================="
Write-Host ""