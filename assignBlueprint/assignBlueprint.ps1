<#
.DESCRIPTION
    Assign Azure BluePrint

.NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
#>

# Get authentication details
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey

# Get blueprint location (Management Group or Subscription).
$BlueprintManagementGroup = $Endpoint.Data.managementGroupName
$AlternateLocation = Get-VstsInput -Name AlternateLocation

if ($AlternateLocation -eq "true") {
    $BlueprintCreationScope = "Subscription"
 } else {
    $BlueprintCreationScope = $Endpoint.Data.scopeLevel
 }

# Get blueprint details
$BlueprintName = Get-VstsInput -Name BlueprintName
$ParametersFilePath = Get-VstsInput -Name ParametersFile
$SubscriptionID = Get-VstsInput -Name SubscriptionID

# Get Parameters File Path
$ParametersFilePath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY + $ParametersFilePath

# Get Access Token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret , $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body

# Header for all REST calls
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$body = Get-Content -Raw -Path $ParametersFilePath | ConvertFrom-Json

# Get Blueprint ID
if ($BlueprintCreationScope -eq "ManagementGroup" ) {
    $body.properties.blueprintId = '/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}' -f $BlueprintManagementGroup, $BlueprintName
} else {
    $body.properties.blueprintId = '/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}' -f $SubscriptionID, $BlueprintName
}

# Create Assignment
$BPAssign = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprintAssignments/{1}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
$body = $body  | ConvertTO-JSON -Depth 4
Invoke-RestMethod -Method PUT -Uri $BPAssign -Headers $Headers -Body $body -ContentType "application/json"