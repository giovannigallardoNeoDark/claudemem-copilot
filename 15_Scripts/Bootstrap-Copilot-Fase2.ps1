# ==========================================
# Bootstrap Copilot Empresarial - Fase 2
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Bootstrap Copilot Empresarial Fase 2"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function New-CopilotFile {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $FullPath = Join-Path $Base $RelativePath

    $Folder = Split-Path $FullPath -Parent

    if (!(Test-Path $Folder)) {

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null
    }

    if (!(Test-Path $FullPath)) {

        $Content |
        Set-Content `
            -Path $FullPath `
            -Encoding UTF8

        Write-Host "[CREADO] $RelativePath" `
            -ForegroundColor Green
    }
    else {

        Write-Host "[EXISTE] $RelativePath" `
            -ForegroundColor Yellow
    }
}

# ==================================================
# AUTOMATIZACION
# ==================================================

New-CopilotFile `
"03_Conocimiento\06_Automatizacion\README.md" `
@"
# Automatizacion

Biblioteca de automatizacion del Copilot Empresarial.
"@

New-CopilotFile `
"03_Conocimiento\06_Automatizacion\ESTRATEGIA_AUTOMATIZACION.md" `
@"
# Estrategia de Automatizacion

Objetivo:

Reducir tareas repetitivas mediante automatizacion.

Areas objetivo:

- Documentacion
- Informes
- Revision de codigo
- Investigacion
- Gestion del conocimiento

Herramientas futuras:

- Power Automate
- n8n
- GitHub Actions
"@

New-CopilotFile `
"03_Conocimiento\06_Automatizacion\FLUJOS.md" `
@"
# Flujos

## Flujo Documental

Solicitud
↓
Generacion
↓
Revision
↓
Publicacion

## Flujo Investigacion

Consulta
↓
Fuentes
↓
Validacion
↓
Informe
"@

New-CopilotFile `
"03_Conocimiento\06_Automatizacion\INTEGRACIONES.md" `
@"
# Integraciones

Futuras integraciones:

- GitHub
- SharePoint
- Claude-Mem
- OmniRoute
"@

# ==================================================
# CREATIVIDAD
# ==================================================

New-CopilotFile `
"03_Conocimiento\07_Creatividad\README.md" `
@"
# Creatividad

Recursos creativos del ecosistema.
"@

New-CopilotFile `
"03_Conocimiento\07_Creatividad\DIRECCION_CREATIVA.md" `
@"
# Direccion Creativa

Objetivo:

Generar contenido visual, tecnico y ejecutivo consistente.
"@

New-CopilotFile `
"03_Conocimiento\07_Creatividad\GENERACION_IMAGENES.md" `
@"
# Generacion de Imagenes

Herramientas futuras:

- Copilot Image Creator
- ChatGPT Images
- Midjourney
- Ideogram
"@

New-CopilotFile `
"03_Conocimiento\07_Creatividad\INFOGRAFIAS.md" `
@"
# Infografias

Aplicaciones:

- Procesos
- Diagramas
- Arquitecturas
- Resumenes ejecutivos
"@

# ==================================================
# MARKETING
# ==================================================

New-CopilotFile `
"03_Conocimiento\08_Marketing\README.md" `
@"
# Marketing

Biblioteca de marketing empresarial.
"@

New-CopilotFile `
"03_Conocimiento\08_Marketing\ESTRATEGIA_MARKETING.md" `
@"
# Estrategia Marketing

Objetivo:

Difundir capacidades y servicios mediante contenido profesional.
"@

New-CopilotFile `
"03_Conocimiento\08_Marketing\PROPUESTAS.md" `
@"
# Propuestas

Modelos de propuestas comerciales y tecnicas.
"@

New-CopilotFile `
"03_Conocimiento\08_Marketing\PRESENTACIONES.md" `
@"
# Presentaciones

Lineamientos para presentaciones corporativas.
"@

# ==================================================
# NORMATIVAS
# ==================================================

New-CopilotFile `
"03_Conocimiento\09_Normativas\README.md" `
@"
# Normativas

Biblioteca normativa corporativa.
"@

New-CopilotFile `
"03_Conocimiento\09_Normativas\INDICE_NORMATIVAS.md" `
@"
# Indice Normativas

## Ingenieria

- AISC
- ASME
- AWS
- API
- ANSI
- ISO
- NCh
"@

New-CopilotFile `
"03_Conocimiento\09_Normativas\MATRIZ_APLICABILIDAD.md" `
@"
# Matriz Aplicabilidad

Documento para relacionar normas y actividades.
"@

New-CopilotFile `
"03_Conocimiento\09_Normativas\GLOSARIO_NORMATIVO.md" `
@"
# Glosario Normativo

Terminos y definiciones utilizadas en normas.
"@

# ==================================================
# LECCIONES APRENDIDAS
# ==================================================

New-CopilotFile `
"03_Conocimiento\13_Lecciones_Aprendidas\README.md" `
@"
# Lecciones Aprendidas

Registro de aprendizajes reutilizables.
"@

New-CopilotFile `
"03_Conocimiento\13_Lecciones_Aprendidas\PLANTILLA_LECCION_APRENDIDA.md" `
@"
# Leccion Aprendida

Fecha:

Area:

Problema:

Solucion:

Resultado:

Recomendacion:
"@

# ==================================================
# DECISIONES TECNICAS
# ==================================================

New-CopilotFile `
"03_Conocimiento\14_Decisiones_Tecnicas\README.md" `
@"
# Decisiones Tecnicas

Repositorio de decisiones relevantes.
"@

New-CopilotFile `
"03_Conocimiento\14_Decisiones_Tecnicas\PLANTILLA_DECISION_TECNICA.md" `
@"
# Decision Tecnica

Fecha:

Contexto:

Alternativas:

Decision:

Justificacion:

Impacto:
"@

# ==================================================
# CASOS REALES
# ==================================================

New-CopilotFile `
"03_Conocimiento\15_Casos_Reales\README.md" `
@"
# Casos Reales

Repositorio de experiencias y casos documentados.
"@

New-CopilotFile `
"03_Conocimiento\15_Casos_Reales\PLANTILLA_CASO_REAL.md" `
@"
# Caso Real

Situacion:

Problema:

Acciones:

Resultado:

Lecciones:
"@

Write-Host ""
Write-Host "Bootstrap Copilot Fase 2 completado." `
-ForegroundColor Cyan
Write-Host ""