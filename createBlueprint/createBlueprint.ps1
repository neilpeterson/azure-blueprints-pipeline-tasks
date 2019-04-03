<#
 .DESCRIPTION
    Creates Azure BluePrint

 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
 #>

# Get Azure Service Principal
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName
$SubscriptionID = $Endpoint.Data.SubscriptionId
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey
$PublishBlueprint = Get-VstsInput -Name PublishBlueprint
$BlueprintVersion = Get-VstsInput -Name Version

# Get task input
$BlueprintLocation = Get-VstsInput -Name BlueprintCreationLocation
$ManagementGroup = Get-VstsInput -Name ManagementGroupName
$BlueprintName = Get-VstsInput -Name BlueprintName
$BlueprintPath = Get-VstsInput -Name BlueprintPath
$ArtifactsPath = Get-VstsInput -Name ArtifactsPath

# Get Blueprint and Artifact paths
$BlueprintPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY + $BlueprintPath
$ArtifactPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY + $ArtifactsPath

# Get Access Token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$Body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret , $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body

# Set creation endpoint location (subscription or management group)
if ($BlueprintLocation -eq "managementGroup" ) {
   $BPCreateUpdate = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}?api-version=2017-11-11-preview' -f $ManagementGroup, $BlueprintName
} else {
   $BPCreateUpdate = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
}

# Create blueprints PUT
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$Body = Get-Content -Raw -Path $BlueprintPath
Invoke-RestMethod -Method PUT -Uri $BPCreateUpdate -Headers $Headers -Body $Body -ContentType "application/json"

# Add artifacts
$allArtifacts = Get-ChildItem $ArtifactPath

foreach ($item in $allArtifacts) {
   $Body = Get-Content -Raw -Path $item.FullName

   # Set creation endpoint location (subscription or management group)
   if ($BlueprintLocation -eq "managementGroup" ) {
      $artifactURI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2017-11-11-preview' -f $ManagementGroup, $BlueprintName, $item.name.Split('.')[0]
   } else {
      $artifactURI = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName, $item.name.Split('.')[0]
   }

   # Add artifacts PUT
   Invoke-RestMethod -Method PUT -Uri $artifactURI -Headers $Headers -Body $Body -ContentType "application/json"
}

if ($PublishBlueprint -eq "true") {

   # Set version to 1 or current + 1
   if ($BlueprintVersion -eq "Increment") {

      # Set creation endpoint location (subscription or management group)
      if ($BlueprintLocation -eq "managementGroup" ) {
         $Get = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions?api-version=2017-11-11-preview" -f $ManagementGroup, $BlueprintName
      } else {
         $Get = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
      }

      # Get blueprint version GET
      $pubBP = Invoke-RestMethod -Method GET -Uri $Get -Headers $Headers

      # If not exsist, version = 1, else version + 1
      if (!$pubBP.value[$pubBP.value.Count - 1].name) {
         $version = 1
      } else {
         $version = ([int]$pubBP.value[$pubBP.value.Count - 1].name) + 1
      }
   }
   # Use version specified in pipeline task
   else {
      $version = $BlueprintVersion
   }

   # Set creation endpoint location (subscription or management group)
   if ($BlueprintLocation -eq "managementGroup" ) {
      $PublishBlueprint = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions/{2}?api-version=2017-11-11-preview" -f $ManagementGroup, $BlueprintName, $version
   } else {
      $PublishBlueprint = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions/{2}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName, $version
   }

   # Publish blueprint PUT
   Invoke-RestMethod -Method PUT -Uri $PublishBlueprint -Headers $Headers
}