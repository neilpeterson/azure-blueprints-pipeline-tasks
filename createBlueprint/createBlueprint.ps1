<#
.DESCRIPTION
   Creates Azure BluePrint

.NOTES
   Author: Neil Peterson
   Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
#>

# Helper functions
Import-Module ./helperFunctions.psm1

# Get authentication details
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName -Require
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey

# Get service connection scope (Management Group or Subscription).
$ServiceConnectionScope = $Endpoint.Data.scopeLevel
$BlueprintManagementGroup = $Endpoint.Data.managementGroupId
$BlueprintSubscription = Get-VstsInput -Name AlternateLocation

if ($BlueprintSubscription -eq "true") {
   $SubscriptionID = Get-VstsInput -Name AlternateSubscription
   $ServiceConnectionScope = "Subscription"
} else {
   $SubscriptionID = $Endpoint.Data.SubscriptionId
}

# Get blueprint details
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
$Body = Get-Content -Raw -Path $BlueprintPath
$BlueprintURI = Get-BlueprintURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName
Invoke-RestMethod -Method PUT -Uri $BlueprintURI -Headers $Headers -Body $Body -ContentType "application/json"

# Remove exsisting artifacts
$ArtifactsURI = Get-AllArtifactsURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName
$artifacts = Invoke-RestMethod -Method GET -Uri $ArtifactsURI -Headers $Headers

if ($artifacts.value.count -gt 0) {
   foreach ($artifact in $artifacts) {
      $ArtifactDeleteURI = Get-ArtifactURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName -ArtifactName $artifact.value.name
      Invoke-RestMethod -Method DELETE -Uri $ArtifactDeleteURI -Headers $Headers
  }
}

# Add new / updated artifacts
if (Test-Path $ArtifactPath) {
   $allArtifacts = Get-ChildItem $ArtifactPath
   if ($allArtifacts.count -gt 0) {
      foreach ($item in $allArtifacts) {
         $Body = Get-Content -Raw -Path $item.FullName
         $ArtifactCreateURI = Get-ArtifactURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName -ArtifactName $item.name.Split('.')[0]
         Invoke-RestMethod -Method PUT -Uri $ArtifactCreateURI -Headers $Headers -Body $Body -ContentType "application/json"
      }
   }
}

# Publish blueprint
if ($PublishBlueprint -eq "true") {

    # Get current blueprint version or use pipeline string
   if ($BlueprintVersion -eq "Increment") {
      $BlueprintVersionURI = Get-BlueprintVersionsURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName
      $pubBP = Invoke-RestMethod -Method GET -Uri $BlueprintVersionURI -Headers $Headers

      if (!$pubBP.value[$pubBP.value.Count - 1].name) {
         $version = 1
      } else {
         $version = ([int]$pubBP.value[$pubBP.value.Count - 1].name) + 1
      }
   } else {
      $version = $BlueprintVersion
   }

   # Publish blueprint
   $PublishBlueprintURI = Get-PublishBlueprintURI -Scope $ServiceConnectionScope -ManagementGroup $BlueprintManagementGroup -SubscriptionID $SubscriptionID -BlueprintName $BlueprintName -BlueprintVersion $version
   Invoke-RestMethod -Method PUT -Uri $PublishBlueprintURI -Headers $Headers
}