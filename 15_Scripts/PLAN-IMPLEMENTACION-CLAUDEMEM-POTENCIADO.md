# Plan de implementación de ClaudeMem Potenciado

## Decisión arquitectónica

ClaudeMem propio continúa como memoria oficial y gobernada. Los componentes nuevos se agregan como módulos auxiliares. Ningún componente externo puede escribir directamente en decisiones, lecciones o hallazgos oficiales.

## Objetivo

Agregar memoria episódica, captura controlada, candidatos a conocimiento, privacidad, recuperación semántica, contexto automático e integración API/MCP, conservando versionado, auditoría, respaldos, relaciones y sincronización bidireccional.

## Principios

1. Conservar el núcleo actual.
2. Agregar capacidades mediante contratos compatibles.
3. Capturar primero como episodio u observación.
4. Promover solo mediante aprobación.
5. Excluir secretos y contenido clasificado.
6. Versionar y respaldar antes de cambios.
7. Integrar herramientas externas detrás de adaptadores.
8. Medir recuperación, citas, privacidad y restauración.

## Fases

### Fase 1. Memoria episódica y candidatos

Entregables:
- Bootstrap-Memoria-Episodica-ClaudeMem.ps1
- Gestionar-Sesiones-ClaudeMem.ps1
- Gestionar-Candidatos-ClaudeMem.ps1
- Auditar-Memoria-Episodica-ClaudeMem.ps1

Criterios de aceptación:
- estructura creada de forma idempotente;
- políticas de captura válidas;
- sesión de prueba creada y cerrada;
- observación registrada;
- candidato creado, aprobado o rechazado;
- cero modificaciones en los siete registros oficiales;
- auditoría 100 %.

### Fase 2. Captura segura

- adaptadores para scripts, auditorías y errores;
- filtrado de secretos;
- rutas y extensiones excluidas;
- clasificaciones PUBLICO, INTERNO, CONFIDENCIAL, RESTRINGIDO y NO_CAPTURAR;
- retención y borrado verificable.

### Fase 3. Resumen y contexto

- Generar-Resumen-Sesion-ClaudeMem.ps1;
- Preparar-Contexto-Copilot.ps1;
- recuperación progresiva en tres niveles;
- deduplicación y presupuesto de contexto;
- citas a registro, archivo, fragmento, versión y hash.

### Fase 4. RAG híbrido

- seleccionar Qdrant como índice auxiliar candidato;
- seleccionar modelo de embeddings;
- crear fragmentos y metadatos;
- combinar búsqueda estructurada, textual, vectorial y relaciones;
- evaluar precisión, relevancia, citas y permisos.

### Fase 5. API y MCP

Primero solo lectura:
- memory_search;
- memory_get;
- memory_context;
- memory_source_open.

Después escritura controlada:
- memory_session_start;
- memory_event_add;
- memory_candidate_add.

La aprobación y promoción oficial quedan fuera de las acciones automáticas iniciales.

### Fase 6. Herramientas externas

Orden recomendado:
1. Git y GitHub CLI.
2. Semgrep y CodeQL.
3. Qdrant y embeddings.
4. OCR.
5. ECC y AgentShield en laboratorio.
6. Conector Microsoft 365.

## Estructura objetivo

11_Herramientas/ClaudeMem/
- episodios/sesiones.json
- episodios/eventos.json
- episodios/observaciones.json
- episodios/resumenes.json
- candidatos/pendientes.json
- candidatos/aprobados.json
- candidatos/rechazados.json
- candidatos/duplicados.json
- config/politicas-captura.json
- config/rutas-excluidas.json
- config/clasificacion-informacion.json
- config/patrones-secretos.json
- schemas/*.schema.json

## Hitos y avance esperado

- H1 estructura episódica: 55 % a 62 %.
- H2 captura segura: 62 % a 68 %.
- H3 contexto automático: 68 % a 75 %.
- H4 RAG híbrido: 75 % a 84 %.
- H5 API/MCP: 84 % a 91 %.
- H6 integración Copilot y evaluación: 91 % a 100 %.

Los porcentajes representan cobertura funcional del objetivo ampliado, no cantidad de archivos.
