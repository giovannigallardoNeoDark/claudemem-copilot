Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Checks = @(
"$Base\00_Admin\Dashboards\CENTRO_CONTROL.md",
"$Base\00_Admin\Dashboards\ESTADO_MAESTRO.md",
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\BENEFICIOS.md",
"$Base\03_Conocimiento\25_Gestion_Evolucion\CAPACIDADES_CERTIFICADAS.md"
)

$OK = 0

foreach($C in $Checks)
{
    if(Test-Path $C)
    {
        $OK++
    }
}

$Score =
[math]::Round(($OK / $Checks.Count) * 100)

Write-Host ""
Write-Host "Validacion:"
Write-Host "$Score%"
Write-Host ""

if($Score -eq 100)
{
    Write-Host "CERTIFICADO" `
    -ForegroundColor Green
}