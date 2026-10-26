# ==========================================
# Auditoria Claude-Mem Ready
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte = Join-Path `
    $Base `
    "00_Admin\Dashboards\CLAUDEMEM_READY.md"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Auditoria Claude-Mem Ready"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Test-Elemento {
    param([string]$Ruta)

    $Path = Join-Path $Base $Ruta
    return (Test-Path $Path)
}

$Checks = @()

# Infraestructura

$Checks += [PSCustomObject]@{
    Nombre = "Git"
    Estado = if(Get-Command git -ErrorAction SilentlyContinue){"OK"}else{"NO"}
}

$NodePortable = Test-Path `
"$Base\11_Herramientas\Node JS\node-v24.22.1-win-x64\node.exe"

$Checks += [PSCustomObject]@{
    Nombre = "NodeJS"
    Estado = if(
        (Get-Command node -ErrorAction SilentlyContinue) -or
        $NodePortable
    ){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "npm"
    Estado = if(Get-Command npm -ErrorAction SilentlyContinue){"OK"}else{"NO"}
}

# Ecosistema

$NpmPortable = Test-Path `
"$Base\11_Herramientas\Node JS\node-v24.22.1-win-x64\npm.cmd"

$Checks += [PSCustomObject]@{
    Nombre = "npm"
    Estado = if(
        (Get-Command npm -ErrorAction SilentlyContinue) -or
        $NpmPortable
    ){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "Politica Memoria"
    Estado = if(Test-Elemento "03_Conocimiento\18_Gobierno_IA\POLITICA_MEMORIA.md"){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "Agente Memoria"
    Estado = if(Test-Elemento "03_Conocimiento\17_Agentes\01_Memoria\AGENTE_MEMORIA.md"){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "Plan ClaudeMem"
    Estado = if(Test-Elemento "03_Conocimiento\20_Implementacion\PLAN_CLAUDEMEM.md"){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "Plan Pruebas"
    Estado = if(Test-Elemento "03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_PRUEBAS.md"){"OK"}else{"NO"}
}

$Checks += [PSCustomObject]@{
    Nombre = "Plan Rollback"
    Estado = if(Test-Elemento "03_Conocimiento\23_Integraciones_Activas\ClaudeMem\PLAN_ROLLBACK.md"){"OK"}else{"NO"}
}

$Total = $Checks.Count
$OK = ($Checks | Where-Object {$_.Estado -eq "OK"}).Count

$Porcentaje = [math]::Round(($OK / $Total) * 100)

$EstadoFinal = if($Porcentaje -ge 90) {
    "LISTO"
}
elseif($Porcentaje -ge 60) {
    "PARCIAL"
}
else {
    "NO LISTO"
}

$Contenido = @()

$Contenido += "# CLAUDE-MEM READY"
$Contenido += ""
$Contenido += "Fecha: $(Get-Date)"
$Contenido += ""

foreach($Item in $Checks)
{
    $Contenido += "- $($Item.Nombre): $($Item.Estado)"
}

$Contenido += ""
$Contenido += "## Preparacion"
$Contenido += ""
$Contenido += "$Porcentaje%"
$Contenido += ""
$Contenido += "## Estado"
$Contenido += ""
$Contenido += "$EstadoFinal"

$Contenido |
Set-Content `
$Reporte `
-Encoding UTF8

Write-Host ""

foreach($Item in $Checks)
{
    Write-Host ($Item.Nombre.PadRight(25) + ": " + $Item.Estado)
}

Write-Host ""
Write-Host "PREPARACION: $Porcentaje%" -ForegroundColor Green
Write-Host "ESTADO: $EstadoFinal" -ForegroundColor Cyan
Write-Host ""
Write-Host $Reporte -ForegroundColor Yellow
Write-Host ""