# ==========================================
# Bootstrap Evaluacion Copilot
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-EvalFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath
    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

    if (!(Test-Path $FullPath)) {

        $Content | Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
}

New-EvalFile `
"03_Conocimiento\21_Evaluacion\README.md" `
"# Evaluacion Ecosistema"

New-EvalFile `
"03_Conocimiento\21_Evaluacion\CRITERIOS_EXITO.md" `
@"
# Criterios de Exito

- Trazabilidad
- Reutilizacion
- Automatizacion
- Memoria
- Escalabilidad
"@

New-EvalFile `
"03_Conocimiento\21_Evaluacion\INDICADORES.md" `
@"
# Indicadores

- Madurez
- Adopcion
- Uso
- Calidad
- Cobertura documental
"@

New-EvalFile `
"03_Conocimiento\21_Evaluacion\MATRIZ_BENEFICIO_COSTO.md" `
@"
# Matriz Beneficio Costo

Evaluar:

- Beneficio
- Complejidad
- Riesgo
- Costo
"@

New-EvalFile `
"03_Conocimiento\21_Evaluacion\MATRIZ_RIESGOS.md" `
@"
# Matriz Riesgos

ID | Riesgo | Impacto | Mitigacion
"@

New-EvalFile `
"03_Conocimiento\21_Evaluacion\CHECKLIST_PREIMPLEMENTACION.md" `
@"
# Checklist Preimplementacion

[ ] Documentacion

[ ] Dependencias

[ ] Riesgos

[ ] Plan rollback

[ ] Validacion
"@

New-EvalFile `
"03_Conocimiento\21_Evaluacion\CHECKLIST_POSTIMPLEMENTACION.md" `
@"
# Checklist Postimplementacion

[ ] Instalacion correcta

[ ] Validacion correcta

[ ] Documentacion actualizada

[ ] Auditoria completada
"@

Write-Host ""
Write-Host "Bootstrap Evaluacion completado"
Write-Host ""