# ============================================
# Auditoria-ClaudeMem-Salud.ps1
# ============================================

$Root = Split-Path -Parent $PSScriptRoot

$ClaudeMem = Join-Path $Root "11_Herramientas\ClaudeMem"

$Items = @(
    "$ClaudeMem\config\config.json",
    "$ClaudeMem\estado.json",
    "$ClaudeMem\data\decisiones.json",
    "$ClaudeMem\data\lecciones.json",
    "$ClaudeMem\data\hallazgos.json",
    "$ClaudeMem\index\index.json",
    "$ClaudeMem\logs\claudemem.log",
    "$ClaudeMem\data\tags.json",
    "$ClaudeMem\data\relaciones.json"
)

$Ok = 0
$Total = $Items.Count

Write-Host ""
Write-Host "================================="
Write-Host " SALUD CLAUDEMEM "
Write-Host "================================="
Write-Host ""

foreach($Item in $Items)
{
    $Existe = Test-Path $Item

    if($Existe)
    {
        $Ok++
        Write-Host "[OK] $Item" -ForegroundColor Green
    }
    else
    {
        Write-Host "[FALTA] $Item" -ForegroundColor Yellow
    }
}

$Salud = [Math]::Round(($Ok / $Total) * 100,2)

Write-Host ""
Write-Host "---------------------------------"
Write-Host "SALUD: $Salud %"
Write-Host "---------------------------------"
