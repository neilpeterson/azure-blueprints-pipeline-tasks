<#
.DESCRIPTION
    Assign Azure BluePrint

.NOTES
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
#>

# Get authentication details
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey | ConvertTo-SecureString -AsPlainText -Force

# Get service connection scope (Management Group or Subscription)
$ServiceConnectionScope = $Endpoint.Data.scopeLevel
$BlueprintManagementGroup = $Endpoint.Data.managementGroupId
$SubscriptionID = $Endpoint.Data.SubscriptionId

# Get Blueprint Assignment details
$BlueprintName = Get-VstsInput -Name BlueprintName
$AssignmentName = Get-VstsInput -Name AssignmentName
$AssignmentFilePath = Get-VstsInput -Name ParametersFile
$TargetSubscriptionID = Get-VstsInput -Name SubscriptionID
$Wait = Get-VstsInput -Name Wait
$Timeout = Get-VstsInput -Name Timeout
$BlueprintVersion = Get-VstsInput -Name BlueprintVersion

# Install Azure PowerShell modules
Find-Module Az.Accounts | Install-Module -Force
Find-Module Az.Blueprint | Install-Module -Force

# Set Blueprint Scope (Subscription / Management Group)
if ($ServiceConnectionScope -eq 'ManagementGroup') {
    $BlueprintScope = "-ManagementGroupId $BlueprintManagementGroup"
}

if ($ServiceConnectionScope -eq 'Subscription') {
    $BlueprintScope = "-SubscriptionId $SubscriptionID"
}

# Connect to Azure
$Creds = New-Object System.Management.Automation.PSCredential ($ClientId, $ClientSecret)
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Creds -WarningAction silentlyContinue

# Get Blueprint object
if ($BlueprintVersion -eq 'latest') {
    $BluePrintObject = Invoke-Expression "Get-AzBlueprint -Name $BlueprintName $BlueprintScope"
 } else {
    $BluePrintObject = Invoke-Expression "Get-AzBlueprint -Name $BlueprintName $BlueprintScope -Version $BlueprintVersion"
 }

# Add Blueprint ID
$body = Get-Content -Raw -Path $AssignmentFilePath | ConvertFrom-Json
$body.properties.blueprintId = $BluePrintObject.id
$body | ConvertTo-Json -Depth 4 | Out-File -FilePath $AssignmentFilePath -Encoding utf8 -Force

# Create Blueprint assignment
New-AzBlueprintAssignment -Name $AssignmentName -Blueprint $BluePrintObject -AssignmentFile $AssignmentFilePath -SubscriptionId $TargetSubscriptionID

# Wait for assignment to complete
if ($Wait -eq "true") {
    $timeout = new-timespan -Seconds $Timeout
    $sw = [diagnostics.stopwatch]::StartNew()

    while (($sw.elapsed -lt $timeout) -and ($AssignemntStatus.ProvisioningState -ne "Succeeded") -and ($AssignemntStatus.ProvisioningState -ne "Failed")) {
        $AssignemntStatus = Get-AzBlueprintAssignment -Name $AssignmentName -SubscriptionId $TargetSubscriptionID
        if ($AssignemntStatus.ProvisioningState -eq "failed") {
            Throw "Assignment Failed. See Azure Portal for datails."
            break
        }
    }

    if ($AssignemntStatus.ProvisioningState -ne "Succeeded") {
        Write-Warning "Assignment has timed out, activity is exiting."
    }
}