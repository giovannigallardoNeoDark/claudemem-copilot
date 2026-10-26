# ==========================================
# Bootstrap Gobierno IA
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-GovFile {

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

        $Content |
        Set-Content $FullPath -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

# ==========================================
# ESTRUCTURA
# ==========================================

$Files = @{

"03_Conocimiento\18_Gobierno_IA\README.md" = @"
# Gobierno IA

Biblioteca de gobierno del Copilot Empresarial.
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_MODELOS.md" = @"
# Política de Modelos

Objetivo:

Definir cuándo usar cada modelo.

Futuro:

- GPT
- Claude
- Gemini
- DeepSeek
- Qwen

Principio:

Seleccionar el modelo adecuado según la tarea.
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_MEMORIA.md" = @"
# Política de Memoria

Puede recordarse:

- Decisiones técnicas
- Lecciones aprendidas
- Procedimientos
- Conocimiento reutilizable

No debe almacenarse:

- Datos temporales
- Credenciales
- Información sensible no autorizada
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_DATOS.md" = @"
# Política de Datos

Toda información debe:

- Tener fuente
- Tener trazabilidad
- Tener control de versiones
- Tener responsable
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_PROMPTS.md" = @"
# Política de Prompts

Todo prompt reutilizable debe:

- Documentarse
- Versionarse
- Mantener objetivo claro
- Registrar mejoras
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_AGENTES.md" = @"
# Política de Agentes

Los agentes:

- No modifican estrategia
- No toman decisiones finales
- Proponen mejoras
- Mantienen trazabilidad
"@

"03_Conocimiento\18_Gobierno_IA\POLITICA_INVESTIGACION.md" = @"
# Política de Investigación

Requisitos:

- Fuentes verificables
- Validación cruzada
- Registro documental
- Conclusiones respaldadas
"@

"03_Conocimiento\18_Gobierno_IA\MATRIZ_RESPONSABILIDADES.md" = @"
# Matriz de Responsabilidades

| Área | Responsable |
|--------|--------|
| Estrategia | Coordinador |
| Memoria | Agente Memoria |
| Seguridad | Agente Seguridad |
| Investigación | Agente Investigación |
| Conocimiento | Agente Conocimiento |
"@
}

foreach($File in $Files.Keys)
{
    New-GovFile $File $Files[$File]
}

Write-Host ""
Write-Host "Bootstrap Gobierno IA completado."
Write-Host ""