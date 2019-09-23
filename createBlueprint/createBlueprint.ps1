<#
.DESCRIPTION
   Creates Azure BluePrint

.NOTES
   Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
#>

# Get authentication details
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName -Require
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey | ConvertTo-SecureString -AsPlainText -Force
$Environment = $Endpoint.Data.Environment

# Get service connection scope (Management Group or Subscription)
$ServiceConnectionScope = $Endpoint.Data.scopeLevel
$BlueprintManagementGroup = $Endpoint.Data.managementGroupId
$BlueprintSubscriptionID = $Endpoint.Data.subscriptionId
$BlueprintAltSubscription = Get-VstsInput -Name AlternateLocation
$BlueprintAltSubscriptionID = Get-VstsInput -Name AlternateSubscription

# Get blueprint details
$BlueprintName = Get-VstsInput -Name BlueprintName
$BlueprintPath = Get-VstsInput -Name BlueprintPath
$PublishBlueprint = Get-VstsInput -Name PublishBlueprint
$BlueprintVersion = Get-VstsInput -Name Version

# Install Azure PowerShell modules
if (Get-Module -ListAvailable -Name Az.Accounts) {
   Write-Output "Az.Accounts module is allready installed."
}
else {
   Find-Module Az.Accounts | Install-Module -Force
}

if (Get-Module -ListAvailable -Name Az.Blueprint) {
   Write-Output "Az.Blueprint module is allready installed."
}
else {
   Find-Module Az.Blueprint | Install-Module -Force
}

# Set Blueprint Scope (Subscription / Management Group)
if ($ServiceConnectionScope -eq 'ManagementGroup' -and $BlueprintAltSubscription -eq "false" ) {
   $BlueprintScope = "-ManagementGroupId $BlueprintManagementGroup"
}

if ($ServiceConnectionScope -eq 'ManagementGroup' -and $BlueprintAltSubscription -eq "true" ) {
   $BlueprintScope = "-SubscriptionId $BlueprintAltSubscriptionID"
}

if ($ServiceConnectionScope -eq 'Subscription') {
   $BlueprintScope = "-SubscriptionId $BlueprintSubscriptionID"
}

# Verbose output
write-output "**Output from Extension**"
write-output "Blueprint Name: $BlueprintName"
write-output "Blueprint Path: $BlueprintPath"
write-output "Blueprint Scope: $BlueprintScope"
write-output "Import-AzBlueprintWithArtifact -Name $BlueprintName -InputPath $BlueprintPath $BlueprintScope -Force"

# Connect to Azure
$Creds = New-Object System.Management.Automation.PSCredential ($ClientId, $ClientSecret)
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Creds -Environment $Environment -WarningAction silentlyContinue

# Create Blueprint
write-output "Creating Blueprint"
Invoke-Expression "Import-AzBlueprintWithArtifact -Name $BlueprintName -InputPath $BlueprintPath $BlueprintScope -Force"

# Publish blueprint if publish
write-output "Publishing Blueprint"
if ($PublishBlueprint -eq "true") {
   $BlueprintObject = Invoke-Expression "Get-AzBlueprint -Name $BlueprintName $BlueprintScope"

   # Set version if increment
   if ($BlueprintVersion -eq "Increment") {
      if ($BlueprintObject.versions[$BlueprintObject.versions.count - 1] -eq 0) {
         $BlueprintVersion = 1
      } else {
         $BlueprintVersion = ([int]$BlueprintObject.versions[$BlueprintObject.versions.count - 1]) + 1
      }
   }

   # Publish blueprint
   Publish-AzBlueprint -Blueprint $BluePrintObject -Version $BlueprintVersion
}