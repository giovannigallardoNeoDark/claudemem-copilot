#Requires -Version 5.1
# VERSION 1.0.0
$Panel=Join-Path $PSScriptRoot 'ClaudeMem-Copilot-Panel.ps1'
if(-not(Test-Path -LiteralPath $Panel -PathType Leaf)){throw "No existe el panel: $Panel"}
&$Panel
