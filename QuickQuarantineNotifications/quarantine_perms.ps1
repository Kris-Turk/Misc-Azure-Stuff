## Pre-requisites ##
# Have created a User assigned managed Identity (Have found system assigned to not work properly, seems to be a bug)
$tenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$managedIdentityName = "uai-test"


Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All, Application.Read.All, RoleManagement.ReadWrite.Directory -TenantId $tenantId



########## Grant the Exchange.ManageAsApp API permission for the managed identity to call Exchange Online ########

# Get Managed Identity ID
$MI = (Get-AzADServicePrincipal -DisplayName $managedIdentityName)
$MI_ID = $MI.Id


$AppRoleID = "dc50a0fb-09a3-484d-be87-e023b12c6440"
$ResourceID = (Get-MgServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").Id


New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI_ID -PrincipalId $MI_ID -AppRoleId $AppRoleID -ResourceId $ResourceID


########## Grant the Exchange ADmnistrator role to the Managed Identity so it can perform quarantine operations ########

$RoleID = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").Id
New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MI_ID -RoleDefinitionId $RoleID -DirectoryScopeId "/"


########## Grant API permissions to allow to sendAs shared mailbox - ########
$ResourceID = (Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'").Id
$permissions = @(
    "b633e1c5-b582-4048-a93e-9f11b44c7e96"  # Mail.Send
)
foreach ($permission in $permissions) {
    
    New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $ResourceID `
    -PrincipalId $MI_ID `
    -ResourceId $ResourceID `
    -AppRoleId $permission
}




