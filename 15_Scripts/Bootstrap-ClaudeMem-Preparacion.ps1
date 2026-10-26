# ==========================================
# Bootstrap Claude-Mem Preparacion
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

function New-Doc {

    param(
        [string]$RelativePath,
        [string]$Content
    )

    $Path = Join-Path $Base $RelativePath
    $Folder = Split-Path $Path -Parent

    if (!(Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
    }

    if (!(Test-Path $Path)) {
        $Content | Set-Content -Path $Path -Encoding UTF8
        Write-Host "[CREADO] $RelativePath" -ForegroundColor Green
    }
}

# ==========================================
# ESTRUCTURA
# ==========================================

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\CHECKLIST_PREINSTALACION.md" `
@"
# Checklist Preinstalacion Claude-Mem

## Infraestructura

- [ ] Git operativo
- [ ] NodeJS operativo
- [ ] npm operativo

## Ecosistema

- [ ] Estrategia Memoria creada
- [ ] Gobierno IA creado
- [ ] Plan Claude-Mem creado

## Operacion

- [ ] Registro Implementacion preparado
- [ ] Plan Rollback preparado
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\CHECKLIST_POSTINSTALACION.md" `
@"
# Checklist Postinstalacion Claude-Mem

- [ ] Instalacion completada
- [ ] Configuracion completada
- [ ] Pruebas ejecutadas
- [ ] Resultados documentados
- [ ] Estado actualizado
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_PRUEBAS.md" `
@"
# Plan Pruebas Claude-Mem

## Prueba 1

Guardar decision tecnica.

Resultado esperado:

Recuperacion correcta.

## Prueba 2

Guardar leccion aprendida.

Resultado esperado:

Busqueda exitosa.

## Prueba 3

Recuperar contexto.

Resultado esperado:

Coherencia entre sesiones.

## Prueba 4

Resumen automatico.

Resultado esperado:

Sintesis correcta.
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\REGISTRO_VALIDACION.md" `
@"
# Registro Validacion Claude-Mem

## Fecha

## Version

## Resultado

## Observaciones

## Incidentes

## Conclusiones
"@

New-Doc `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_ROLLBACK.md" `
@"
# Rollback Claude-Mem

Objetivo:

Volver al estado anterior si la integracion falla.

Pasos:

1. Detener servicio.
2. Respaldar configuracion.
3. Restaurar configuracion anterior.
4. Validar funcionamiento.
5. Documentar incidente.

Criterios activacion:

- Perdida contexto.
- Errores criticos.
- Corrupcion datos.
"@

# ==========================================
# VERIFICACION ENTORNO
# ==========================================

$Reporte = Join-Path `
$Base `
"03_Conocimiento\23_Integraciones_Activas\ClaudeMem\VERIFICACION_ENTORNO.md"

$Git = if(Get-Command git -ErrorAction SilentlyContinue){"OK"}else{"NO"}
$Node = if(Get-Command node -ErrorAction SilentlyContinue){"OK"}else{"NO"}
$Npm = if(Get-Command npm -ErrorAction SilentlyContinue){"OK"}else{"NO"}

@"
# Verificacion Entorno Claude-Mem

Git: $Git

NodeJS: $Node

npm: $Npm

Resultado:

Validar manualmente antes de instalacion.
"@ | Set-Content $Reporte -Encoding UTF8

Write-Host ""
Write-Host "Preparacion Claude-Mem completada." -ForegroundColor Cyan
Write-Host ""