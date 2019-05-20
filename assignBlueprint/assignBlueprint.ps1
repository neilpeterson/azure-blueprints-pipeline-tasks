<#
.DESCRIPTION
    Assign Azure BluePrint

.NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
#>

# Helper functions
Import-Module ./helperFunctions.psm1

# Get authentication details
$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName
$Endpoint = Get-VstsEndpoint -Name $ConnectedServiceName
$TenantId = $Endpoint.Auth.Parameters.tenantid
$ClientId = $Endpoint.Auth.Parameters.ServicePrincipalId
$ClientSecret = $Endpoint.Auth.Parameters.ServicePrincipalKey

# Get Service connection details
$BlueprintManagementGroup = $Endpoint.Data.managementGroupId
$SubscriptionID = $Endpoint.Data.SubscriptionId

# Get Blueprint Assignment details
$BlueprintName = Get-VstsInput -Name BlueprintName
$ParametersFilePath = Get-VstsInput -Name ParametersFile
$TargetSubscriptionID = Get-VstsInput -Name SubscriptionID
$Wait = Get-VstsInput -Name Wait
$Timeout = Get-VstsInput -Name Timeout

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

# If scoped to Management Group, try and find Blueprint (ID).
if ($BlueprintManagementGroup) {
    $BlueprintURIManagementGroup = Get-BlueprintURI -Scope "ManagementGroup" -ManagementGroup $BlueprintManagementGroup -BlueprintName $BlueprintName
    try {
        $BlueprintID = Invoke-RestMethod -Method GET -Uri $BlueprintURIManagementGroup -Headers $Headers -ContentType "application/json"
    } catch {
        Write-Host "Blueprint not found at Managemnt Group, trying Subscription"
    }
}

# Check Subscription for the Blueprint (ID). If found at both MG and Subscription, use Subscription.
$BlueprintURISubscription = Get-BlueprintURI -Scope "Subscription" -SubscriptionID $TargetSubscriptionID -BlueprintName $BlueprintName

try {
    $BlueprintID = Invoke-RestMethod -Method GET -Uri $BlueprintURISubscription -Headers $Headers -ContentType "application/json"
} catch {
    if (!$BlueprintID) {
        Write-Host "Blueprint not found at subscription"
        Exit
    }
}

# Update Assignment body with Blueprint ID
$body.properties.blueprintId = $BlueprintID.id

# Create Assignment
$BPAssign = Get-BlueprintAssignmentURI -SubscriptionID $TargetSubscriptionID -BlueprintName $BlueprintName
$body = $body  | ConvertTO-JSON -Depth 4
Invoke-RestMethod -Method PUT -Uri $BPAssign -Headers $Headers -Body $body -ContentType "application/json"

# Wait for Assignment
if ($Wait -eq "true") {

    # Timeout logic
    $timeout = new-timespan -Seconds $Timeout
    $sw = [diagnostics.stopwatch]::StartNew()

    while ($sw.elapsed -lt $timeout){

        # Get Assignment Operation ID
        $AssignmentOperations = Get-BlueprintAssignmentOperationURI -SubscriptionID $TargetSubscriptionID -BlueprintName $BlueprintName
        $Assignment = Invoke-RestMethod -Method GET -Uri $AssignmentOperations -Headers $Headers -ContentType "application/json"

        # Get Assignment Status
        $AssignmentStatus = Get-BlueprintAssignmentStatusURI -SubscriptionID $TargetSubscriptionID -BlueprintName $BlueprintName -AssignmentOperationID $Assignment.value[0].name

        Do {
            $Status = Invoke-RestMethod -Method GET -Uri $AssignmentStatus -Headers $Headers -ContentType "application/json"

            if ($Status.properties.assignmentState -eq "failed") {
                Write-Error $Status.properties.deployments.result.error.message
                break
            }

            Sleep 5

        } while ($Status.properties.assignmentState -ne "succeeded")
    }
}