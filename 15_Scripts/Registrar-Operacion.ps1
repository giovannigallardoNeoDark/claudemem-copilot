Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Log =
"$Base\03_Conocimiento\22_Operacion\BITACORA_OPERACIONAL.md"

@"

## $(Get-Date)

Operacion:

Actualizacion ecosistema

Resultado:

OK

Estado:

Completado

"@ | Add-Content $Log

Write-Host ""
Write-Host "Operacion registrada."
Write-Host ""