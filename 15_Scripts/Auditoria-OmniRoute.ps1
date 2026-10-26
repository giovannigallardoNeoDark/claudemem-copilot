# ==========================================
# Auditoria OmniRoute
# ==========================================

Clear-Host

Write-Host ""
Write-Host "======================="
Write-Host " Auditoria OmniRoute"
Write-Host "======================="
Write-Host ""

$NodePath = (Resolve-Path "..\11_Herramientas\Node JS\node-v24.22.1-win-x64").Path

Write-Host "NPM:"
& "$NodePath\npm.cmd" view omniroute version

Write-Host ""
Write-Host "NPX:"
& "$NodePath\npx.cmd" --yes omniroute version

Write-Host ""
Write-Host "Auditoria finalizada."