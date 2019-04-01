
<#
 .DESCRIPTION
    Creates Azure BluePrint

 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
 #>

param (
   [string]$ManagementGroup,
   [string]$BlueprintName,
   [string]$BlueprintPath,
   [string]$ArtifactPath
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
$ArtifactPath = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\blueprints\create-blueprint\artifacts"

# Get Access Token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret , $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body

# Create BluePrint
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$BPCreateUpdate = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}?api-version=2017-11-11-preview' -f $ManagementGroup, $BlueprintName
$body = Get-Content -Raw -Path $BlueprintPath
Invoke-RestMethod -Method PUT -Uri $BPCreateUpdate -Headers $Headers -Body $body -ContentType "application/json"

# Get Published BP / Last version number
$Get = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions?api-version=2017-11-11-preview" -f $ManagementGroup, $BlueprintName
$pubBP = Invoke-RestMethod -Method GET -Uri $Get -Headers $Headers

# If not exsist, version = 1, else version + 1
if (!$pubBP.value[$pubBP.value.Count - 1].name) {
   $version = 1
} else {
   $version = ([int]$pubBP.value[$pubBP.value.Count - 1].name) + 1
}

# Add artifacts
$allArtifacts = Get-ChildItem $ArtifactPath

foreach ($item in $allArtifacts) {
   $body = Get-Content -Raw -Path "$ArtifactPath/$item"
   $artifactURI = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2017-11-11-preview" -f $ManagementGroup, $BlueprintName, $item.name.Split('.')[0]
   Invoke-RestMethod -Method PUT -Uri $artifactURI -Headers $Headers -Body $body -ContentType "application/json"
}

# Publish Blueprint
$Publish = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions/{2}?api-version=2017-11-11-preview" -f $ManagementGroup, $BlueprintName, $version
Invoke-RestMethod -Method PUT -Uri $Publish -Headers $Headers