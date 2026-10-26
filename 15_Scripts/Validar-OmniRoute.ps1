Clear-Host

Write-Host ""
Write-Host "Validacion OmniRoute"
Write-Host ""

$NodePath = (Resolve-Path "..\11_Herramientas\Node JS\node-v24.22.1-win-x64").Path

& "$NodePath\npm.cmd" view omniroute version

Write-Host ""
Write-Host "Validacion finalizada."