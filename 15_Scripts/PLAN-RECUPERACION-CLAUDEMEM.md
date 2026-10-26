# Plan de recuperacion de ClaudeMem

1. Detener el panel.
2. Identificar el ultimo backup valido.
3. Comparar hashes del respaldo y del manifiesto.
4. Ejecutar una restauracion en copia aislada.
5. Validar sintaxis y diagnostico.
6. Restaurar el entorno real solo si la prueba aislada aprueba.
7. Regenerar manifiesto.
8. Ejecutar diagnostico general y auditorias.

La memoria oficial no debe modificarse durante pruebas de restauracion.
