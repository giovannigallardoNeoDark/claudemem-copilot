Connect-MgGraph `
-Scopes `
"Group.Read.All"

Get-MgGroup `
-Filter "resourceProvisioningOptions/Any(x:x eq 'Team')"