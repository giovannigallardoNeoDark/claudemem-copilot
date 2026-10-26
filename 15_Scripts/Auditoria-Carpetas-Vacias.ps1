Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte =
Join-Path `
$Base `
"00_Admin\Inventario\AUDITORIA_CARPETAS_VACIAS.md"

"# Carpetas vacias" |
Out-File $Reporte -Encoding UTF8

Get-ChildItem `
$Base `
-Directory `
-Recurse |

ForEach-Object {

    $Items =
    Get-ChildItem `
    $_.FullName `
    -Force

    if($Items.Count -eq 0)
    {
        Add-Content `
        $Reporte `
        $_.FullName
    }
}

Write-Host $Reporte