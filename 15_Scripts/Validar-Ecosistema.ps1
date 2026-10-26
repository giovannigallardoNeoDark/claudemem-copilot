# ==========================================
# Validar Ecosistema
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @(
"00_Admin\Dashboards\ESTADO_MAESTRO.md",
"00_Admin\Dashboards\CENTRO_CONTROL.md",
"03_Conocimiento\24_Base_Conocimiento_Viva\HALLAZGOS.md",
"03_Conocimiento\24_Base_Conocimiento_Viva\PATRONES.md",
"03_Conocimiento\24_Base_Conocimiento_Viva\BENEFICIOS.md",
"03_Conocimiento\25_Gestion_Evolucion\CAPACIDADES.md"
)

$OK = 0

foreach($Item in $Checks)
{
    if(Test-Path "$Base\$Item")
    {
        $OK++
    }
}

$Score = [math]::Round(($OK / $Checks.Count) * 100)

Write-Host ""
Write-Host "SALUD ECOSISTEMA"
Write-Host ""
Write-Host "Resultado: $Score%"
Write-Host ""

if($Score -ge 90)
{
    Write-Host "ESTADO: SALUDABLE" `
        -ForegroundColor Green
}
elseif($Score -ge 70)
{
    Write-Host "ESTADO: ESTABLE" `
        -ForegroundColor Yellow
}
else
{
    Write-Host "ESTADO: REQUIERE REVISION" `
        -ForegroundColor Red
}