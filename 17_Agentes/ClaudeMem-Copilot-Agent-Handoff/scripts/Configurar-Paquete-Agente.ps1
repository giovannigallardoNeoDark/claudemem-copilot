#Requires -Version 5.1
[CmdletBinding()]param([Parameter(Mandatory=$true)][string]$Config)
Set-StrictMode -Version Latest;$ErrorActionPreference='Stop'
$Raiz=Split-Path -Parent $PSScriptRoot;$Cfg=Get-Content -LiteralPath $Config -Raw|ConvertFrom-Json -ErrorAction Stop
if([guid]::Empty-eq[guid]$Cfg.appId){throw 'appId debe ser un GUID real y no el GUID vacio.'}
if([string]::IsNullOrWhiteSpace([string]$Cfg.apiKeyRegistrationId)-or$Cfg.apiKeyRegistrationId-like'RePLACE*'){throw 'Falta apiKeyRegistrationId.'}
$Uri=[uri]$Cfg.mcpUrl;if($Uri.Scheme-ne'https'-or-not$Uri.AbsolutePath.EndsWith('/mcp')){throw 'mcpUrl debe ser HTTPS y finalizar en /mcp.'}
$Plantilla=Get-Content (Join-Path $Raiz 'appPackage\manifest.template.json') -Raw
$HostMcp=$Uri.Host
$Valores=@{'{{APP_ID}}'=[string]$Cfg.appId;'{{MCP_URL}}'=$Uri.AbsoluteUri.TrimEnd('/');'{{MCP_HOST}}'=$HostMcp;'{{API_KEY_REGISTRATION_ID}}'=[string]$Cfg.apiKeyRegistrationId}
foreach($K in $Valores.Keys){$Plantilla=$Plantilla.Replace($K,$Valores[$K])}
if($Cfg.developerWebsite){$Plantilla=$Plantilla.Replace('https://example.invalid',[string]$Cfg.developerWebsite)}
$Dist=Join-Path $Raiz 'dist\appPackage';New-Item -ItemType Directory -Path $Dist -Force|Out-Null
[IO.File]::WriteAllText((Join-Path $Dist 'manifest.json'),$Plantilla,[Text.UTF8Encoding]::new($false))
Copy-Item (Join-Path $Raiz 'appPackage\declarativeAgent.json') $Dist -Force
Copy-Item (Join-Path $Raiz 'appPackage\instructions.txt') $Dist -Force
$null=Get-Content (Join-Path $Dist 'manifest.json') -Raw|ConvertFrom-Json -ErrorAction Stop
Write-Host "Paquete materializado en: $Dist" -ForegroundColor Green
Write-Warning 'Agregue color.png y outline.png antes de crear el ZIP final.'
