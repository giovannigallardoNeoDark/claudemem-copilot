# ==========================================
# Auditoria Headroom v2
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Rutas = @(
"$PSScriptRoot\node_modules\headroom-ai",
"$Base\node_modules\headroom-ai"
)

$Instalado = $false

foreach($Ruta in $Rutas)
{
    if(Test-Path $Ruta)
    {
        $Instalado = $true
        $RutaEncontrada = $Ruta
        break
    }
}

Write-Host ""
Write-Host "====================="
Write-Host " Auditar Headroom v2"
Write-Host "====================="
Write-Host ""

if($Instalado)
{
    Write-Host "HEADROOM: INSTALADO" -ForegroundColor Green
    Write-Host ""
    Write-Host $RutaEncontrada -ForegroundColor Yellow
}
else
{
    Write-Host "HEADROOM: NO ENCONTRADO" -ForegroundColor Red
}

Write-Host ""