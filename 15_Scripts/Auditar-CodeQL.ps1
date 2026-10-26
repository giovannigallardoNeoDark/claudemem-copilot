Clear-Host

Write-Host ""
Write-Host "AUDITORIA CODEQL"
Write-Host ""

$Workflow = "..\.github\workflows\codeql.yml"

if(Test-Path $Workflow)
{
    Write-Host "Workflow CodeQL: OK" `
    -ForegroundColor Green
}
else
{
    Write-Host "Workflow CodeQL: NO ENCONTRADO" `
    -ForegroundColor Red
}

Write-Host ""