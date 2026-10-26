# ==========================================
# Copilot Empresarial
# Run-All
# ==========================================

Clear-Host

$Root = Split-Path $PSScriptRoot -Parent

$LogFile = Join-Path `
$Root `
"03_Conocimiento\22_Operacion\RUN_ALL_LOG.md"

$Fecha = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

@"

# Ejecucion

Fecha: $Fecha

"@ | Set-Content $LogFile

Write-Host ""
Write-Host "========================================="
Write-Host " COPILOT EMPRESARIAL"
Write-Host " ORQUESTADOR MAESTRO"
Write-Host "========================================="
Write-Host ""

# ------------------------------------------
# Filtros
# ------------------------------------------

$Ignore = @(
"Run-All.ps1",
"Run-All",
"Backup",
"Respaldo",
"Rollback",
"Install",
"Setup"
)

# ------------------------------------------
# Buscar scripts
# ------------------------------------------

$Scripts = Get-ChildItem `
$PSScriptRoot `
-Filter "*.ps1" `
-File |
Where-Object {

    $Nombre = $_.Name

    $Valido = $true

    foreach($Item in $Ignore)
    {
        if($Nombre -like "*$Item*")
        {
            $Valido = $false
        }
    }

    $Valido
} |
Sort-Object Name

# ------------------------------------------
# Ejecutar
# ------------------------------------------

$OK = 0
$Fail = 0

foreach($Script in $Scripts)
{
    Write-Host ""
    Write-Host "[EJECUTANDO] $($Script.Name)" `
    -ForegroundColor Cyan

    try
    {
        PowerShell.exe `
        -ExecutionPolicy Bypass `
        -File $Script.FullName

        $OK++

@"

OK : $($Script.Name)

"@ | Add-Content $LogFile
    }
    catch
    {
        $Fail++

@"

FAIL : $($Script.Name)

$($_.Exception.Message)

"@ | Add-Content $LogFile

        Write-Host ""
        Write-Host "[ERROR] $($Script.Name)" `
        -ForegroundColor Red
    }
}

# ------------------------------------------
# Resumen
# ------------------------------------------

Write-Host ""
Write-Host "========================================="
Write-Host " RESUMEN"
Write-Host "========================================="
Write-Host ""

Write-Host "Correctos : $OK" `
-ForegroundColor Green

Write-Host "Errores   : $Fail" `
-ForegroundColor Yellow

Write-Host ""

Write-Host "Log:"
Write-Host $LogFile `
-ForegroundColor Cyan

@"

## Resumen

Correctos: $OK

Errores: $Fail

"@ | Add-Content $LogFile