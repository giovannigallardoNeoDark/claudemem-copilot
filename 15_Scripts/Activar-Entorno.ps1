# ==========================================
# Activar Entorno Copilot
# ==========================================

$NodePath = (Resolve-Path `
"..\11_Herramientas\Node JS\node-v24.22.1-win-x64").Path

$env:PATH = "$NodePath;$env:PATH"

Write-Host ""
Write-Host "Entorno activado."
Write-Host ""

Write-Host "Node:"
& "$NodePath\node.exe" --version

Write-Host "npm:"
& "$NodePath\npm.cmd" --version

Write-Host "npx:"
& "$NodePath\npx.cmd" --version

Write-Host ""