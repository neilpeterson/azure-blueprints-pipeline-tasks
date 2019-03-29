<#

.DESCRIPTION
    Assign Azure BluePrint

.NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps

#>

param (
    [string]$ManagementGroup,
    [string]$BlueprintName,
    [string]$BlueprintPath
)

# Get Azure Service Principal
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
$endpoint = Get-VstsEndpoint -Name $ConnectedServiceName
$TenantId = $endpoint.Auth.Parameters.tenantid
$ClientId = $endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $endpoint.Auth.Parameters.ServicePrincipalKey

# Get task input
$ManagementGroup = Get-VstsInput -Name MGName
$BlueprintName = Get-VstsInput -Name BPName

# Get Pipeline agent paths
$BlueprintPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\blueprints\create-blueprint\blueprint-body.json"

# Get Access Token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret , $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body

# Assign BluePrint
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$body = Get-Content -Raw -Path $BlueprintPath | ConvertFrom-Json
$body.properties.blueprintId = '/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}' -f $ManagementGroup, $BlueprintName
$BPAssign = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprintAssignments/{1}?api-version=2017-11-11-preview' -f $SubscriptionId, $BlueprintName
$body = $body  | ConvertTO-JSON -Depth 4
write-output $body
Invoke-RestMethod -Method PUT -Uri $BPAssign -Headers $Headers -Body $body -ContentType "application/json"