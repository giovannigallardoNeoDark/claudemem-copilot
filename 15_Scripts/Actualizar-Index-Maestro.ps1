Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Destino =
"$Base\03_Conocimiento\24_Base_Conocimiento_Viva\INDEX_MAESTRO.md"

@"
# INDEX MAESTRO

## Lecciones Aprendidas

## Decisiones Tecnicas

## Hallazgos

## Casos Reales

## Skills

## Procedimientos

## Prompts

## Conectores

## Agentes

"@ | Set-Content $Destino

Write-Host "Index actualizado."