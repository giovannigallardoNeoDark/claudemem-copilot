Clear-Host

Write-Host ""
Write-Host "================================="
Write-Host " AUDITORIA SNYK"
Write-Host "================================="
Write-Host ""

if(Get-Command snyk -ErrorAction SilentlyContinue)
{
    Write-Host "Snyk instalado" -ForegroundColor Green

    $Version = snyk --version

    Write-Host "Version: $Version"
}
else
{
    Write-Host "Snyk NO instalado" `
        -ForegroundColor Red
}