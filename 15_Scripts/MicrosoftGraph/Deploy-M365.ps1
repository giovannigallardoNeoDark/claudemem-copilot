# ==========================================
# Deploy-M365
# ==========================================

Import-Module Microsoft.Graph -ErrorAction SilentlyContinue

Connect-MgGraph `
-Scopes `
"User.Read",
"Sites.Read.All",
"Group.Read.All",
"Files.Read.All"

Write-Host ""
Write-Host "M365 conectado."
Write-Host ""

Get-MgContext