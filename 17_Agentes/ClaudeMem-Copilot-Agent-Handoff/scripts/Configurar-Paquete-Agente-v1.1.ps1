#Requires -Version 5.1
# VERSION 1.1.0 - CONFIGURAR PAQUETE CLAUDEMEM COPILOT
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Config
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RutaScript = $MyInvocation.MyCommand.Path
$RutaScripts = Split-Path -Parent $RutaScript
$RutaRaiz = Split-Path -Parent $RutaScripts
$RutaConfig = (Resolve-Path -LiteralPath $Config -ErrorAction Stop).Path
$RutaPlantilla = Join-Path $RutaRaiz 'appPackage\manifest.template.json'
$RutaDist = Join-Path $RutaRaiz 'dist\appPackage'

$Cfg = Get-Content -LiteralPath $RutaConfig -Raw | ConvertFrom-Json -ErrorAction Stop
$Manifest = Get-Content -LiteralPath $RutaPlantilla -Raw | ConvertFrom-Json -ErrorAction Stop

try { $AppId = [guid]$Cfg.appId } catch { throw 'appId no es un GUID valido.' }
if ($AppId -eq [guid]::Empty) { throw 'appId no puede ser el GUID vacio.' }

if ([string]::IsNullOrWhiteSpace([string]$Cfg.apiKeyRegistrationId) -or
    [string]$Cfg.apiKeyRegistrationId -like 'REPLACE*') {
    throw 'Falta apiKeyRegistrationId.'
}
if ([string]$Cfg.apiKeyRegistrationId -eq [string]$Cfg.appId) {
    throw 'apiKeyRegistrationId no puede ser igual a appId.'
}

$McpUri = [uri]$Cfg.mcpUrl
if ($McpUri.Scheme -ne 'https' -or -not $McpUri.AbsolutePath.EndsWith('/mcp')) {
    throw 'mcpUrl debe usar HTTPS y finalizar en /mcp.'
}

foreach ($Campo in @('developerWebsite','privacyUrl','termsUrl')) {
    $Valor = [string]$Cfg.$Campo
    if ([string]::IsNullOrWhiteSpace($Valor)) { throw "Falta $Campo." }
    $Uri = [uri]$Valor
    if ($Uri.Scheme -ne 'https') { throw "$Campo debe usar HTTPS." }
    if ($Uri.Host -eq 'replace.example') { throw "$Campo conserva un valor de ejemplo." }
}

$Manifest.id = [string]$AppId
$Manifest.developer.websiteUrl = [string]$Cfg.developerWebsite
$Manifest.developer.privacyUrl = [string]$Cfg.privacyUrl
$Manifest.developer.termsOfUseUrl = [string]$Cfg.termsUrl
$Manifest.validDomains = @($McpUri.Host)
$Manifest.agentConnectors[0].toolSource.remoteMcpServer.mcpServerUrl = $McpUri.AbsoluteUri.TrimEnd('/')
$Manifest.agentConnectors[0].toolSource.remoteMcpServer.authorization.referenceId = [string]$Cfg.apiKeyRegistrationId

New-Item -ItemType Directory -Path $RutaDist -Force | Out-Null
$RutaManifest = Join-Path $RutaDist 'manifest.json'
[IO.File]::WriteAllText(
    $RutaManifest,
    ($Manifest | ConvertTo-Json -Depth 30),
    [Text.UTF8Encoding]::new($false)
)

Copy-Item -LiteralPath (Join-Path $RutaRaiz 'appPackage\declarativeAgent.json') -Destination $RutaDist -Force
Copy-Item -LiteralPath (Join-Path $RutaRaiz 'appPackage\instructions.txt') -Destination $RutaDist -Force

$ManifestFinal = Get-Content -LiteralPath $RutaManifest -Raw | ConvertFrom-Json -ErrorAction Stop

[pscustomobject][ordered]@{
    Estado = 'APROBADO'
    AppId = $ManifestFinal.id
    McpUrl = $ManifestFinal.agentConnectors[0].toolSource.remoteMcpServer.mcpServerUrl
    DeveloperWebsite = $ManifestFinal.developer.websiteUrl
    PrivacyUrl = $ManifestFinal.developer.privacyUrl
    TermsUrl = $ManifestFinal.developer.termsOfUseUrl
    Paquete = $RutaDist
} | Format-List
