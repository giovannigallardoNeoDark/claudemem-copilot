# Manual de administracion de ClaudeMem

## Diagnostico

Ejecutar `Diagnosticar-ClaudeMem-Potenciado.ps1 -GenerarInforme`.

## Manifiesto

Regenerar con `Generar-Manifiesto-ClaudeMem.ps1 -IncluirOpcionales` despues de cambiar un archivo activo.

## Actualizacion

1. Preparar una carpeta con scripts validos.
2. Ejecutar `Actualizar-ClaudeMem-Potenciado.ps1 -RutaPaquete <carpeta>` para simular.
3. Revisar el backup.
4. Usar `-Aplicar` solo con una version aprobada.

## Recuperacion

No restaurar sobre el entorno real sin revisar previamente el respaldo, los hashes y la sintaxis. La prueba aislada debe aprobar 4/4.

## Archivado

Usar solo `Archivar-Versiones-ClaudeMem-Restringido.ps1`. Ejecutar primero sin `-Aplicar`.
