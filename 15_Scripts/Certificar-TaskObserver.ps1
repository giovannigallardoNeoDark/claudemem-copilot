Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Docs = @(
"03_Conocimiento\22_Operacion\SKILLS_CERTIFICADAS.md",
"03_Conocimiento\22_Operacion\PROCEDIMIENTOS_CERTIFICADOS.md",
"03_Conocimiento\22_Operacion\AUTOMATIZACIONES_CERTIFICADAS.md",
"03_Conocimiento\22_Operacion\CATALOGO_CAPACIDADES.md"
)

$OK = 0

foreach($Doc in $Docs)
{
    if(Test-Path (Join-Path $Base $Doc))
    {
        $OK++
    }
}

$Score = ($OK / $Docs.Count) * 100

Write-Host ""
Write-Host "TASK OBSERVER"
Write-Host ""

Write-Host "$Score %"

if($Score -eq 100)
{
    Write-Host ""
    Write-Host "CERTIFICADO" `
    -ForegroundColor Green
}