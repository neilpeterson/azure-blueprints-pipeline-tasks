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
$Environment = $Endpoint.Data.Environment

# Get service connection scope (Management Group or Subscription)
$ServiceConnectionScope = $Endpoint.Data.scopeLevel
$BlueprintManagementGroup = $Endpoint.Data.managementGroupId
$SubscriptionID = $Endpoint.Data.SubscriptionId
$TargetSubscriptionID = Get-VstsInput -Name SubscriptionID # Alternate (not from service connection) subscription id.

# Get Blueprint Assignment details
$BlueprintName = Get-VstsInput -Name BlueprintName
$AssignmentName = Get-VstsInput -Name AssignmentName
$AssignmentFilePath = Get-VstsInput -Name ParametersFile
$Wait = Get-VstsInput -Name Wait
$Timeout = Get-VstsInput -Name Timeout
$BlueprintVersion = Get-VstsInput -Name BlueprintVersion
$StopOnError = Get-VstsInput -Name StopOnFailure

function Write-Log {
    param (
        [string]$log
    )
    write-output "** Assign Blueprint log: $log **"
}

# Install Azure PowerShell modules
if (Get-Module -ListAvailable -Name Az.Accounts) {
    Write-Log("Az.Accounts module is allready installed.")
}
else {
    Find-Module Az.Accounts | Install-Module -Force
    Write-Log("Az.Accounts module is not installed, installing now.")
}

if (Get-Module -ListAvailable -Name Az.Blueprint) {
    Write-Log("Az.Blueprints module is allready installed.")
}
else {
    Find-Module Az.Blueprint | Install-Module -Force
    Write-Log("Az.Blueprints module is not installed, installing now.")
}

# Set Blueprint Scope (Subscription / Management Group)
if ($ServiceConnectionScope -eq 'ManagementGroup') {
    Write-Log("Blueprint definition is located at Management Group $BlueprintManagementGroup.")
    $BlueprintScope = "-ManagementGroupId $BlueprintManagementGroup"

    # Check for subscription ID
    if ([String]::IsNullOrEmpty($TargetSubscriptionID) -eq $true) {
        throw "Target subscription not specified."
    }
}

if ($ServiceConnectionScope -eq 'Subscription') {
    Write-Log("Blueprint definition is located at Subscription Group $SubscriptionID.")
    $BlueprintScope = "-SubscriptionId $SubscriptionID"
    $TargetSubscriptionID = $SubscriptionID
}

# Connect to Azure
$Creds = New-Object System.Management.Automation.PSCredential ($ClientId, $ClientSecret)
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Creds -Environment $Environment -WarningAction silentlyContinue

# Get Blueprint object
if ($BlueprintVersion -eq 'latest') {
    $BluePrintObject = Invoke-Expression "Get-AzBlueprint -Name $BlueprintName $BlueprintScope"
    Write-Log("Get Blueprint $BlueprintName, version latest.")

 } else {
    $BluePrintObject = Invoke-Expression "Get-AzBlueprint -Name $BlueprintName $BlueprintScope -Version $BlueprintVersion"
    Write-Log("Get Blueprint $BlueprintName, version $BlueprintVersion.")
 }

# Add Blueprint ID to assignment file
$body = Get-Content -Raw -Path $AssignmentFilePath | ConvertFrom-Json
$body.properties | Add-Member -Name "blueprintId" -value $BluePrintObject.id -MemberType NoteProperty -Force
$body | ConvertTo-Json -Depth 10 | Out-File -FilePath $AssignmentFilePath -Encoding utf8 -Force

# Create Blueprint assignment
$AssignmentObject = Get-AzBlueprintAssignment -Name $AssignmentName -SubscriptionId $TargetSubscriptionID -erroraction 'silentlycontinue'

if ($AssignmentObject) {
    Set-AzBlueprintAssignment -Name $AssignmentName -Blueprint $bluePrintObject -AssignmentFile $AssignmentFilePath -SubscriptionId $TargetSubscriptionID
    Write-Log("Assignment $AssignmentName exsists, using Set-AzBlueprintAssignment.")
} else {
    New-AzBlueprintAssignment -Name $AssignmentName -Blueprint $bluePrintObject -AssignmentFile $AssignmentFilePath -SubscriptionId $TargetSubscriptionID
    Write-Log("Assignment $AssignmentName does not exsists, using New-AzBlueprintAssignment.")
}

# Wait for assignment to complete
if ($Wait -eq "true") {
    $timeout = new-timespan -Seconds $Timeout
    $sw = [diagnostics.stopwatch]::StartNew()

    while (($sw.elapsed -lt $timeout) -and ($AssignmentStatus.ProvisioningState -ne "Succeeded") -and ($AssignmentStatus.ProvisioningState -ne "Failed")) {
        $AssignmentStatus = Get-AzBlueprintAssignment -Name $AssignmentName -SubscriptionId $TargetSubscriptionID
        if ($AssignmentStatus.ProvisioningState -eq "failed") {
            if ($StopOnError -eq "true") {
                throw "Assignment Failed, see Azure portal for results."
            } else {
                Write-Host "##vso[task.logissue type=error;]Assignment Failed, see Azure portal for results."
            }
        }
    }

    if ($AssignmentStatus.ProvisioningState -ne "Succeeded" -and $AssignmentStatus.ProvisioningState -ne "Failed") {
        Write-Host "##vso[task.logissue type=warning;]Assignment has timed out, either increase timout value or check portal for results"
    } else {
        Write-Log("Assignment completed.")
    }
}