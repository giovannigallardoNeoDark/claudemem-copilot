# ==========================================
# Diagnostico OmniRoute Avanzado
# ==========================================

Clear-Host

$Cache =
"$env:LOCALAPPDATA\npm-cache\_npx"

Write-Host ""
Write-Host "============="
Write-Host " OmniRoute"
Write-Host "============="
Write-Host ""

Get-ChildItem `
$Cache `
-Recurse `
-Filter "package.json" `
-ErrorAction SilentlyContinue |

Where-Object {
    $_.FullName -match "omniroute"
} |

ForEach-Object {

    Write-Host ""
    Write-Host $_.FullName `
        -ForegroundColor Green

    try {

        Get-Content $_.FullName |
        Select-String `"bin`"

    }
    catch {}
}