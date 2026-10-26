# ==========================================
# Auditoria Preparacion Integraciones
# ==========================================

Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Reporte = Join-Path `
$Base `
"00_Admin\Dashboards\PREPARACION_INTEGRACIONES.md"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Auditoria Preparacion Integraciones"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# FUNCIONES
# ==========================================

function Test-Elemento {

    param(
        [string[]]$Archivos
    )

    $Total = $Archivos.Count
    $OK = 0

    foreach($Archivo in $Archivos)
    {
        $Ruta = Join-Path $Base $Archivo

        if(Test-Path $Ruta)
        {
            $OK++
        }
    }

    $Porcentaje = [math]::Round(($OK / $Total) * 100)

    if($Porcentaje -ge 90)
    {
        return "LISTO"
    }

    if($Porcentaje -ge 50)
    {
        return "PARCIAL"
    }

    return "NO LISTO"
}

# ==========================================
# COMPONENTES
# ==========================================

$Resultados = @()

# ------------------------------------------
# CLAUDE MEM
# ------------------------------------------

$ClaudeMem = @(
"03_Conocimiento\01_Memoria\ESTRATEGIA_MEMORIA.md",
"03_Conocimiento\18_Gobierno_IA\POLITICA_MEMORIA.md",
"03_Conocimiento\20_Implementacion\PLAN_CLAUDEMEM.md",
"03_Conocimiento\17_Agentes\01_Memoria\AGENTE_MEMORIA.md"
)

$Resultados += [PSCustomObject]@{
    Componente = "Claude-Mem"
    Estado = Test-Elemento $ClaudeMem
}

# ------------------------------------------
# HEADROOM
# ------------------------------------------

$Headroom = @(
"03_Conocimiento\18_Gobierno_IA\POLITICA_MODELOS.md",
"03_Conocimiento\19_Arquitectura_Operacional\CAPAS_ARQUITECTURA.md",
"03_Conocimiento\20_Implementacion\PLAN_HEADROOM.md"
)

$Resultados += [PSCustomObject]@{
    Componente = "Headroom"
    Estado = Test-Elemento $Headroom
}

# ------------------------------------------
# OMNIROUTE
# ------------------------------------------

$OmniRoute = @(
"03_Conocimiento\18_Gobierno_IA\POLITICA_MODELOS.md",
"03_Conocimiento\19_Arquitectura_Operacional\MAPA_INTEGRACIONES.md",
"03_Conocimiento\20_Implementacion\PLAN_OMNIROUTE.md"
)

$Resultados += [PSCustomObject]@{
    Componente = "OmniRoute"
    Estado = Test-Elemento $OmniRoute
}

# ------------------------------------------
# TASK OBSERVER
# ------------------------------------------

$TaskObserver = @(
"03_Conocimiento\17_Agentes\11_Observador\AGENTE_OBSERVADOR.md",
"03_Conocimiento\11_Skills\SKILL_INVESTIGACION.md",
"03_Conocimiento\06_Automatizacion\ESTRATEGIA_AUTOMATIZACION.md",
"03_Conocimiento\20_Implementacion\PLAN_TASKOBSERVER.md"
)

$Resultados += [PSCustomObject]@{
    Componente = "Task Observer"
    Estado = Test-Elemento $TaskObserver
}

# ------------------------------------------
# GITHUB
# ------------------------------------------

$GitHub = @(
"03_Conocimiento\16_Conectores\GitHub\GITHUB_CONECTOR.md",
"03_Conocimiento\20_Implementacion\PLAN_GITHUB.md"
)

$Resultados += [PSCustomObject]@{
    Componente = "GitHub"
    Estado = Test-Elemento $GitHub
}

# ------------------------------------------
# SHAREPOINT
# ------------------------------------------

$SharePoint = @(
"03_Conocimiento\20_Implementacion\PLAN_SHAREPOINT.md",
"03_Conocimiento\16_Conectores\SharePoint"
)

$Resultados += [PSCustomObject]@{
    Componente = "SharePoint"
    Estado = Test-Elemento $SharePoint
}

# ==========================================
# CALCULO MADUREZ
# ==========================================

$Puntaje = 0

foreach($Item in $Resultados)
{
    switch($Item.Estado)
    {
        "LISTO"    { $Puntaje += 100 }
        "PARCIAL"  { $Puntaje += 50  }
        default    { $Puntaje += 0   }
    }
}

$Madurez = [math]::Round(
    $Puntaje / $Resultados.Count
)

# ==========================================
# GENERAR REPORTE
# ==========================================

$Contenido = @()

$Contenido += "# PREPARACION INTEGRACIONES"
$Contenido += ""
$Contenido += "Fecha: $(Get-Date)"
$Contenido += ""

foreach($Item in $Resultados)
{
    $Contenido += "## $($Item.Componente)"
    $Contenido += ""
    $Contenido += "$($Item.Estado)"
    $Contenido += ""
}

$Contenido += "# MADUREZ INTEGRACION"
$Contenido += ""
$Contenido += "$Madurez%"
$Contenido += ""

$Contenido += "# PRIORIDAD RECOMENDADA"
$Contenido += ""
$Contenido += "1. Claude-Mem"
$Contenido += "2. Headroom"
$Contenido += "3. OmniRoute"
$Contenido += "4. Task Observer"
$Contenido += "5. GitHub"
$Contenido += "6. SharePoint"

$Contenido |
Set-Content `
$Reporte `
-Encoding UTF8

# ==========================================
# CONSOLA
# ==========================================

Write-Host ""

foreach($Item in $Resultados)
{
    Write-Host `
    ($Item.Componente.PadRight(18) + ": " + $Item.Estado)
}

Write-Host ""
Write-Host "MADUREZ INTEGRACION: $Madurez%" `
-ForegroundColor Cyan

Write-Host ""
Write-Host $Reporte `
-ForegroundColor Yellow

Write-Host ""