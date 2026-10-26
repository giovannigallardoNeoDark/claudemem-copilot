Clear-Host

$Base = Split-Path $PSScriptRoot -Parent

$Folder =
"$Base\03_Conocimiento\17_Agentes\TaskObserver_Avanzado"

New-Item -ItemType Directory -Path $Folder -Force | Out-Null

@(
"README.md",
"MOTOR_SKILLS.md",
"MOTOR_PROCEDIMIENTOS.md",
"MOTOR_AUTOMATIZACIONES.md",
"MOTOR_ROADMAP.md"
) | ForEach-Object {

    $File = Join-Path $Folder $_

    if(!(Test-Path $File))
    {
        New-Item -ItemType File `
        -Path $File `
        -Force | Out-Null
    }
}

Write-Host ""
Write-Host "Task Observer Avanzado creado."
Write-Host ""