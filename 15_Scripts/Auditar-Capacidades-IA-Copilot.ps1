#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$ExportarJson
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$ClaudeMem = Join-Path $Root '11_Herramientas\ClaudeMem'
$Reports = Join-Path $ClaudeMem 'reports'
$OutJson = Join-Path $Reports ("Auditoria-Capacidades-IA-Copilot-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$OutTxt = [IO.Path]::ChangeExtension($OutJson, '.txt')
if (-not (Test-Path $Reports)) { New-Item -ItemType Directory -Path $Reports -Force | Out-Null }

function Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }
function PathOk($p) { [bool](Test-Path -LiteralPath $p) }
function Add-Result([string]$Area,[string]$Component,[string]$State,[string]$Evidence,[string]$Action) {
    $script:R += [pscustomobject]@{Area=$Area;Component=$Component;Estado=$State;Evidencia=$Evidence;Accion=$Action}
}
function Test-ServicePort([int]$Port) {
    try { return (Test-NetConnection -ComputerName 'localhost' -Port $Port -WarningAction SilentlyContinue).TcpTestSucceeded } catch { return $false }
}

$script:R=@()

# Nucleo construido y evidenciado localmente
$cmData=Join-Path $ClaudeMem 'data'
$cmIndex=Join-Path $ClaudeMem 'index\index.json'
$cmManifest=Join-Path $ClaudeMem 'sync\manifiesto-bidireccional.json'
$cmOk=(PathOk (Join-Path $cmData 'decisiones.json')) -and (PathOk (Join-Path $cmData 'lecciones.json')) -and (PathOk (Join-Path $cmData 'hallazgos.json')) -and (PathOk $cmIndex)
Add-Result 'Memoria' 'ClaudeMem propio' $(if($cmOk){'OPERATIVO'}else{'INCOMPLETO'}) $(if($cmOk){'JSON e indice presentes'}else{'Faltan archivos base'}) 'Mantener auditorias y backups'
Add-Result 'Memoria' 'Manifiesto bidireccional' $(if(PathOk $cmManifest){'OPERATIVO'}else{'NO INSTALADO'}) $cmManifest 'Inicializar solo si falta'
Add-Result 'Conocimiento' 'Biblioteca Viva' $(if(PathOk (Join-Path $Root '03_Conocimiento')){'PRESENTE'}else{'NO INSTALADO'}) (Join-Path $Root '03_Conocimiento') 'Validar recuperacion desde Copilot'

# Scripts esenciales
$Scripts=@(
 'Buscar-ClaudeMem-Avanzado.ps1','Auditar-Relaciones-ClaudeMem.ps1',
 'Auditar-Conflictos-BibliotecaViva-ClaudeMem.ps1','Resolver-Conflictos-ClaudeMem.ps1',
 'Sincronizar-Bidireccional-ClaudeMem.ps1','Prueba-Sincronizacion-Bidireccional-ClaudeMem.ps1',
 'Versionar-ClaudeMem.ps1','Gestionar-Papelera-ClaudeMem.ps1'
)
foreach($s in $Scripts){$p=Join-Path $PSScriptRoot $s;Add-Result 'ClaudeMem' $s $(if(PathOk $p){'INSTALADO'}else{'FALTA'}) $p $(if(PathOk $p){'Conservar'}else{'Instalar o recuperar'})}

# Repositorios y CLIs externos. Archivo/configuracion no equivale a operativo.
$Checks=@(
 @{A='Desarrollo IA';C='ECC';Cmd='ecc';Paths=@((Join-Path $env:USERPROFILE '.claude\plugins\ecc'),(Join-Path $env:USERPROFILE '.config\ecc'))},
 @{A='Memoria externa';C='claude-mem oficial';Cmd='claude-mem';Paths=@((Join-Path $env:USERPROFILE '.claude-mem'))},
 @{A='Contexto';C='Headroom';Cmd='headroom';Paths=@()},
 @{A='Modelos';C='OmniRoute';Cmd='omniroute';Paths=@()},
 @{A='Aprendizaje';C='Task Observer';Cmd='task-observer';Paths=@((Join-Path $env:USERPROFILE '.claude\skills'))},
 @{A='Codigo';C='SonarScanner';Cmd='sonar-scanner';Paths=@()},
 @{A='Codigo';C='Semgrep';Cmd='semgrep';Paths=@()},
 @{A='Codigo';C='CodeQL';Cmd='codeql';Paths=@()},
 @{A='Codigo';C='Snyk';Cmd='snyk';Paths=@()},
 @{A='Documentos';C='ExifTool';Cmd='exiftool';Paths=@()},
 @{A='Documentos';C='MAT2';Cmd='mat2';Paths=@()},
 @{A='OCR';C='Tesseract';Cmd='tesseract';Paths=@()},
 @{A='Audio';C='Whisper';Cmd='whisper';Paths=@()},
 @{A='Diagramas';C='PlantUML';Cmd='plantuml';Paths=@()},
 @{A='Diagramas';C='Mermaid CLI';Cmd='mmdc';Paths=@()},
 @{A='Automatizacion';C='n8n';Cmd='n8n';Paths=@()},
 @{A='Versionado';C='Git';Cmd='git';Paths=@()},
 @{A='GitHub';C='GitHub CLI';Cmd='gh';Paths=@()}
)
foreach($x in $Checks){
 $cmdOk=Cmd $x.Cmd;$pathHits=@($x.Paths|Where-Object{PathOk $_})
 $state=if($cmdOk){'INSTALADO_NO_PROBADO'}elseif($pathHits.Count-gt0){'ARCHIVOS_PRESENTES_NO_PROBADO'}else{'NO DETECTADO'}
 $ev=if($cmdOk){(Get-Command $x.Cmd).Source}elseif($pathHits.Count){$pathHits -join '; '}else{'Sin comando ni ruta conocida'}
 Add-Result $x.A $x.C $state $ev $(if($state-eq'NO DETECTADO'){'Evaluar e instalar si se aprueba'}else{'Ejecutar prueba funcional y registrar version'})
}

# Bases vectoriales. Deteccion por Docker, procesos o puertos conocidos.
$docker=Cmd 'docker'
$qdrant=(Test-ServicePort 6333)
$weaviate=(Test-ServicePort 8080)
Add-Result 'RAG' 'Qdrant' $(if($qdrant){'CONECTADO_LOCAL'}else{'NO DETECTADO'}) 'Puerto local 6333' 'Elegir una sola base vectorial antes de instalar'
Add-Result 'RAG' 'Weaviate' $(if($weaviate){'CONECTADO_LOCAL'}else{'NO DETECTADO'}) 'Puerto local 8080' 'No instalar si se elige Qdrant'
$chromaPy=$false
try { $chromaPy = [bool](& python -c "import chromadb" 2>$null) -or ($LASTEXITCODE -eq 0) } catch {}
Add-Result 'RAG' 'ChromaDB' $(if($chromaPy){'INSTALADO_NO_PROBADO'}else{'NO DETECTADO'}) 'Import chromadb' 'Usar solo para prototipo si no se elige Qdrant'
Add-Result 'Infraestructura' 'Docker' $(if($docker){'INSTALADO_NO_PROBADO'}else{'NO DETECTADO'}) $(if($docker){(Get-Command docker).Source}else{'Sin comando docker'}) 'Probar daemon antes de desplegar servicios'

# Microsoft y configuraciones locales
$agentDirs=@(Get-ChildItem -LiteralPath $Root -Recurse -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name -match 'Agentes|Agents'})
$connDirs=@(Get-ChildItem -LiteralPath $Root -Recurse -Directory -ErrorAction SilentlyContinue|Where-Object{$_.Name -match 'Conectores|Connectors|Integraciones_Activas'})
Add-Result 'Copilot' 'Agentes locales' $(if($agentDirs.Count){'ESTRUCTURA_PRESENTE_NO_PROBADA'}else{'NO DETECTADO'}) ($agentDirs.FullName -join '; ') 'Inventariar, ejecutar y publicar agentes'
Add-Result 'Copilot' 'Conectores locales' $(if($connDirs.Count){'ESTRUCTURA_PRESENTE_NO_PROBADA'}else{'NO DETECTADO'}) ($connDirs.FullName -join '; ') 'Validar autenticacion, contenido y citas'
Add-Result 'Microsoft 365' 'Power Automate' 'NO VERIFICABLE_LOCALMENTE' 'Requiere inspeccion del tenant' 'Exportar inventario de flujos y ejecutar prueba'
Add-Result 'Microsoft 365' 'Copilot Connectors' 'NO VERIFICABLE_LOCALMENTE' 'Requiere centro de administracion/Microsoft Graph' 'Validar conexiones, errores e items indexados'
Add-Result 'Microsoft 365' 'SharePoint/OneDrive grounding' 'ALMACENAMIENTO_PRESENTE_NO_PROBADO' $Root 'Probar recuperacion desde Copilot con citas'

# SaaS/APIs: solamente detectar variables, nunca mostrar secretos.
$ApiNames=@('TAVILY_API_KEY','EXA_API_KEY','PERPLEXITY_API_KEY','JINA_API_KEY','DEEPL_AUTH_KEY','OPENAI_API_KEY','ANTHROPIC_API_KEY','SNYK_TOKEN')
foreach($n in $ApiNames){$present=[bool][Environment]::GetEnvironmentVariable($n);Add-Result 'Credenciales' $n $(if($present){'CONFIGURADA_NO_PROBADA'}else{'NO CONFIGURADA'}) $(if($present){'Variable presente'}else{'Variable ausente'}) 'No imprimir secretos; probar mediante conector aprobado'}

$R|Sort-Object Area,Component|Format-Table Area,Component,Estado,Evidencia -AutoSize|Out-String|Set-Content -LiteralPath $OutTxt -Encoding UTF8
if($ExportarJson){$R|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $OutJson -Encoding UTF8}

$R|Sort-Object Area,Component|Format-Table Area,Component,Estado,Evidencia -AutoSize
$counts=$R|Group-Object Estado|Sort-Object Count -Descending
Write-Host "`nRESUMEN" -ForegroundColor Cyan
$counts|Select-Object Name,Count|Format-Table -AutoSize
Write-Host "Informe TXT: $OutTxt"
if($ExportarJson){Write-Host "Informe JSON: $OutJson"}
