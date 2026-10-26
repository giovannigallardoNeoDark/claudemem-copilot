# ==========================================
# Validacion Claude-Mem
# ==========================================

Clear-Host

Write-Host ""
Write-Host "===================================" -ForegroundColor Cyan
Write-Host " Validacion Claude-Mem"
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

$ClaudeMemExe =
"$env:LOCALAPPDATA\claude-mem\bin\claude-mem.exe"

if(Test-Path $ClaudeMemExe)
{
    Write-Host "[OK] Ejecutable encontrado" `
        -ForegroundColor Green

    & $ClaudeMemExe --version
}
else
{
    Write-Host "[ERROR] Ejecutable no encontrado" `
        -ForegroundColor Red
}

Write-Host ""
Write-Host "Verificar UI:" `
    -ForegroundColor Yellow

Write-Host "http://127.0.0.1:37777"

Write-Host ""