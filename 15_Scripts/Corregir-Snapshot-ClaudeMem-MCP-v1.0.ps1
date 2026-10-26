#Requires -Version 5.1
# VERSION 1.0.0 - CORRECCION MCP BOM UTF-8
[CmdletBinding()]
param(
    [string]$RutaProyecto = (Get-Location).Path,
    [string]$RutaNodePortable = 'C:\Users\aba\OneDrive - Syntec Ingeniera\Copilot\11_Herramientas\Node JS\node-v24.22.1-win-x64'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RutaProyecto = (Resolve-Path -LiteralPath $RutaProyecto).Path
$Store = Join-Path $RutaProyecto 'src\store.ts'
$Exportador = Join-Path $RutaProyecto 'scripts\Exportar-Snapshot-ClaudeMem.ps1'
$Snapshot = Join-Path $RutaProyecto 'data\claudemem-snapshot.json'
$Node = Join-Path $RutaNodePortable 'node.exe'
$Npm = Join-Path $RutaNodePortable 'npm.cmd'

foreach ($Ruta in @($Store,$Exportador,$Node,$Npm)) {
    if (-not (Test-Path -LiteralPath $Ruta -PathType Leaf)) {
        throw "Falta archivo requerido: $Ruta"
    }
}

$Backups = Join-Path $RutaProyecto 'backups-locales'
New-Item -ItemType Directory -Path $Backups -Force | Out-Null
$Sello = Get-Date -Format 'yyyyMMdd-HHmmss'
Copy-Item -LiteralPath $Store -Destination (Join-Path $Backups "store-pre-bom-$Sello.ts") -Force
Copy-Item -LiteralPath $Exportador -Destination (Join-Path $Backups "exportador-pre-bom-$Sello.ps1") -Force
if (Test-Path -LiteralPath $Snapshot -PathType Leaf) {
    Copy-Item -LiteralPath $Snapshot -Destination (Join-Path $Backups "snapshot-pre-bom-$Sello.json") -Force
}

$StoreTexto = Get-Content -LiteralPath $Store -Raw
$LecturaOriginal = 'return JSON.parse(fs.readFileSync(p,"utf8")) as Snapshot;'
$LecturaCorregida = 'return JSON.parse(fs.readFileSync(p,"utf8").replace(/^\uFEFF/, "")) as Snapshot;'
if ($StoreTexto.Contains($LecturaOriginal)) {
    $StoreTexto = $StoreTexto.Replace($LecturaOriginal,$LecturaCorregida)
}
elseif (-not $StoreTexto.Contains('.replace(/^\uFEFF/')) {
    throw 'No se encontro el punto seguro de correccion en src\store.ts.'
}
[IO.File]::WriteAllText($Store,$StoreTexto,[Text.UTF8Encoding]::new($false))

$ExportadorTexto = Get-Content -LiteralPath $Exportador -Raw
$ExportadorTexto = $ExportadorTexto.Replace('[Text.UTF8Encoding]::new($true)','[Text.UTF8Encoding]::new($false)')
[IO.File]::WriteAllText($Exportador,$ExportadorTexto,[Text.UTF8Encoding]::new($false))

& $Exportador -Salida $Snapshot | Out-Host

$Bytes = [IO.File]::ReadAllBytes($Snapshot)
$TieneBom = $Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF
if ($TieneBom) { throw 'El snapshot aun contiene BOM UTF-8.' }
$null = Get-Content -LiteralPath $Snapshot -Raw | ConvertFrom-Json -ErrorAction Stop

$env:Path = $RutaNodePortable + [IO.Path]::PathSeparator + $env:Path
Push-Location $RutaProyecto
try {
    & $Npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build fallo con codigo $LASTEXITCODE." }
    & $Npm test
    if ($LASTEXITCODE -ne 0) { throw "npm test fallo con codigo $LASTEXITCODE." }
}
finally { Pop-Location }

[pscustomobject]@{
    Estado = 'APROBADO'
    SnapshotSinBom = -not $TieneBom
    JsonValido = $true
    Build = 'PASS'
    Tests = 'PASS'
    SiguienteAccion = 'Reiniciar servidor MCP y consultar /health'
} | Format-List
