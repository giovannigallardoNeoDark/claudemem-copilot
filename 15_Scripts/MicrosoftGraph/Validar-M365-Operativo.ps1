# ==========================================
# Validar Microsoft 365 Operativo
# ==========================================

Clear-Host

Write-Host ""
Write-Host "================================="
Write-Host " VALIDACION M365"
Write-Host "================================="
Write-Host ""

# Verificar módulo

$GraphModule =
Get-Module Microsoft.Graph -ListAvailable

if($GraphModule)
{
    Write-Host "Microsoft Graph: OK" `
        -ForegroundColor Green
}
else
{
    Write-Host "Microsoft Graph: NO INSTALADO" `
        -ForegroundColor Red

    return
}

# Conectar

try
{
    Connect-MgGraph `
        -Scopes `
        "User.Read",
        "Sites.Read.All",
        "Group.Read.All",
        "Mail.Read",
        "Files.Read.All"

    $Context = Get-MgContext

    Write-Host ""
    Write-Host "Tenant:" `
        $Context.TenantId

    Write-Host ""
    Write-Host "Conectado correctamente." `
        -ForegroundColor Green

}
catch
{
    Write-Host ""
    Write-Host "Error de conexion." `
        -ForegroundColor Red
}