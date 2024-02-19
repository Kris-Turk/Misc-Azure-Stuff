$tenantId = "00f0544d-ba8c-45a7-8f03-17701fc50e91"
$MI_ID = "63d68ae4-72c6-4fed-acb2-2a6f9971489b"

Connect-MgGraph -Scopes AppRoleAssignment.ReadWrite.All, Application.Read.All, RoleManagement.ReadWrite.Directory -TenantId $tenantId

$AppRoleID = "dc50a0fb-09a3-484d-be87-e023b12c6440"

$ResourceID = (Get-MgServicePrincipal -Filter "AppId eq '00000002-0000-0ff1-ce00-000000000000'").Id

New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $MI_ID -PrincipalId $MI_ID -AppRoleId $AppRoleID -ResourceId $ResourceID



$RoleID = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Exchange Administrator'").Id

New-MgRoleManagementDirectoryRoleAssignment -PrincipalId $MI_ID -RoleDefinitionId $RoleID -DirectoryScopeId "/"


### UAI

$MI_ID = (Get-AzUserAssignedIdentity -Name "uai-tpfqn" -ResourceGroupName "rg-tpf-quarantine-notification").ClientId