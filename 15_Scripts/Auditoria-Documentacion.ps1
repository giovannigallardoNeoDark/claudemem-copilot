Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte = Join-Path `
$Base `
"00_Admin\Inventario\AUDITORIA_DOCUMENTACION.md"

"# AUDITORIA DOCUMENTACION" |
Out-File $Reporte -Encoding UTF8

Add-Content $Reporte ""

Get-ChildItem $Base -Directory -Recurse |
ForEach-Object {

    $Readme =
    Join-Path $_.FullName "README.md"

    if(!(Test-Path $Readme))
    {
        Add-Content `
        $Reporte `
        "FALTA README: $($_.FullName)"
    }
}

Write-Host ""
Write-Host "Auditoria terminada."
Write-Host $Reporte