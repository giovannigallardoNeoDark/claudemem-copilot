# ==========================================
# Auditoria Integraciones
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte =
Join-Path `
$Base `
"00_Admin\Dashboards\ESTADO_INTEGRACIONES.md"

$Items = @(
"03_Conocimiento\23_Integraciones_Activas\CLAUDEMEM.md",
"03_Conocimiento\23_Integraciones_Activas\Headroom\INSTALACION_REAL.md",
"03_Conocimiento\23_Integraciones_Activas\OmniRoute\README.md",
"03_Conocimiento\23_Integraciones_Activas\TaskObserver\README.md"
)

$Ok = 0

foreach($I in $Items)
{
    if(Test-Path (Join-Path $Base $I))
    {
        $Ok++
    }
}

$Score =
[math]::Round(($Ok / $Items.Count) * 100)

@"
# ESTADO INTEGRACIONES

Fecha: $(Get-Date)

Integraciones detectadas:

$Ok de $($Items.Count)

Madurez:

$Score %

"@ | Set-Content `
$Reporte `
-Encoding UTF8

Write-Host ""
Write-Host "Madurez Integraciones: $Score%"
Write-Host ""