<#
 .DESCRIPTION
    Creates Azure BluePrint

 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
 #>

# Get Azure Service Principal
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName -Require
$SubscriptionID = $Endpoint.Data.SubscriptionId
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey

# Get task input
$BlueprintLocation = $Endpoint.Data.scopeLevel
$ManagementGroup = $Endpoint.Data.managementGroupName
$BlueprintName = Get-VstsInput -Name BlueprintName
$BlueprintPath = Get-VstsInput -Name BlueprintPath
$ArtifactsPath = Get-VstsInput -Name ArtifactsPath
$PublishBlueprint = Get-VstsInput -Name PublishBlueprint
$BlueprintVersion = Get-VstsInput -Name Version

# Get Blueprint and Artifact paths
$BlueprintPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY + $BlueprintPath
$ArtifactPath = $env:SYSTEM_DEFAULTWORKINGDIRECTORY + $ArtifactsPath

# Get Access Token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$Body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret, $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $Body

# Header for all REST calls
$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")

# Create / Update Blueprint
if ($BlueprintLocation -eq "ManagementGroup" ) {
   $BPCreateUpdate = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}?api-version=2018-11-01-preview' -f $ManagementGroup, $BlueprintName
} else {
   $BPCreateUpdate = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
}

$Body = Get-Content -Raw -Path $BlueprintPath
Invoke-RestMethod -Method PUT -Uri $BPCreateUpdate -Headers $Headers -Body $Body -ContentType "application/json"

# Remove exsisting artifacts
if ($BlueprintLocation -eq "ManagementGroup" ) {
   $artifactsURI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts?api-version=2018-11-01-preview' -f $ManagementGroup, $BlueprintName
} else {
   $artifactsURI = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
}

$artifacts = Invoke-RestMethod -Method GET -Uri $artifactsURI -Headers $Headers

if ($artifacts.value.count -gt 0) {
   foreach ($artifact in $artifacts) {

      if ($BlueprintLocation -eq "ManagementGroup" ) {
         $artifactsDeleteURI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2018-11-01-preview' -f $ManagementGroup, $BlueprintName, $artifact.value.name
      } else {
         $artifactsDeleteURI = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName, $artifact.value.name
      }

      Invoke-RestMethod -Method DELETE -Uri $artifactsDeleteURI -Headers $Headers
  }
}

# Add new / updated artifacts
if (Test-Path $ArtifactPath) {
   $allArtifacts = Get-ChildItem $ArtifactPath
   if ($allArtifacts.count -gt 0) {
      foreach ($item in $allArtifacts) {

         # Add artifacts
         if ($BlueprintLocation -eq "ManagementGroup" ) {
            $artifactURI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2018-11-01-preview' -f $ManagementGroup, $BlueprintName, $item.name.Split('.')[0]
         } else {
            $artifactURI = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/artifacts/{2}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName, $item.name.Split('.')[0]
         }

         $Body = Get-Content -Raw -Path $item.FullName
         Invoke-RestMethod -Method PUT -Uri $artifactURI -Headers $Headers -Body $Body -ContentType "application/json"
      }
   }
}

# Publish blueprint
if ($PublishBlueprint -eq "true") {

    # Get current blueprint version
   if ($BlueprintVersion -eq "Increment") {
      if ($BlueprintLocation -eq "managementGroup" ) {
         $Get = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions?api-version=2018-11-01-preview" -f $ManagementGroup, $BlueprintName
      } else {
         $Get = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName
      }

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

    # Publish blueprint
   if ($BlueprintLocation -eq "managementGroup" ) {
      $PublishBlueprint = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions/{2}?api-version=2018-11-01-preview" -f $ManagementGroup, $BlueprintName, $version
   } else {
      $PublishBlueprint = 'https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}/versions/{2}?api-version=2018-11-01-preview' -f $SubscriptionID, $BlueprintName, $version
   }

   Invoke-RestMethod -Method PUT -Uri $PublishBlueprint -Headers $Headers
}