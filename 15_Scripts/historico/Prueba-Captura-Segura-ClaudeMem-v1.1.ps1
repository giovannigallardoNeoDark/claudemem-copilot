#Requires -Version 5.1
# VERSION 1.1.0
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Filtro=Join-Path $PSScriptRoot 'Filtrar-Contenido-Sensible-ClaudeMem.ps1'
$Resultados=@()
function Probar {
    param(
        [string]$Nombre,
        [string]$Contenido,
        [string]$Ruta,
        [string]$Clase,
        [string]$Esperado
    )

    $Evaluacion = & $Filtro `
        -Contenido $Contenido `
        -RutaOrigen $Ruta `
        -Clasificacion $Clase

    return [PSCustomObject]@{
        Estado = $(if ([string]$Evaluacion.accion -eq $Esperado) { 'PASS' } else { 'FAIL' })
        Prueba = $Nombre
        Obtenido = [string]$Evaluacion.accion
        Esperado = $Esperado
    }
}
$Resultados += Probar 'Contenido normal' 'Resultado de auditoria aprobado' 'informe.txt' 'INTERNO' 'CAPTURAR'
$Resultados += Probar 'Password' 'password=abc123' 'registro.txt' 'INTERNO' 'RECHAZAR'
$Resultados += Probar 'Token' 'token: 123456' 'registro.txt' 'INTERNO' 'RECHAZAR'
$Resultados += Probar 'API key' 'api_key=XYZ' 'registro.txt' 'INTERNO' 'RECHAZAR'
$Resultados += Probar 'Archivo excluido' 'contenido normal' '.env' 'INTERNO' 'RECHAZAR'
$Resultados += Probar 'No capturar' 'contenido normal' 'nota.txt' 'NO_CAPTURAR' 'RECHAZAR'
$Resultados += Probar 'Confidencial' 'contenido de revision' 'nota.txt' 'CONFIDENCIAL' 'REQUIERE_REVISION'
$Resultados += Probar 'No indexar' 'contenido permitido' 'nota.txt' 'NO_INDEXAR' 'CAPTURAR_NO_INDEXAR'
$Resultados|Format-Table -AutoSize;$Pass=@($Resultados|Where-Object Estado -eq 'PASS').Count;Write-Host "Aprobadas: $Pass / $($Resultados.Count)";if($Pass-ne$Resultados.Count){exit 1}
