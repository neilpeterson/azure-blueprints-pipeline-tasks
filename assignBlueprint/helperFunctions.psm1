$ManagementGroupBaseURI = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}"
$SubscriptionBaseURI = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}"
$AssignmentBaseURI = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprintAssignments/{1}"
$APIVersion = '?api-version=2018-11-01-preview'

function Get-BlueprintURI {

    param (
        [string]$Scope,
        [string]$ManagementGroup,
        [string]$SubscriptionID,
        [string]$BlueprintName
    )

    $sb = [System.Text.StringBuilder]::new()
    If ($Scope -eq "ManagementGroup") {

        [void]$sb.Append($ManagementGroupBaseURI)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$ManagementGroup)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()

    } ElseIf ($Scope -eq "Subscription") {

        [void]$sb.Append($SubscriptionBaseURI)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$SubscriptionID)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()
    }
}

function Get-BlueprintAssignmentURI  {

    param (
        [string]$SubscriptionID,
        [string]$BlueprintName
    )

    $sb = [System.Text.StringBuilder]::new()

    [void]$sb.Append($AssignmentBaseURI)
    [void]$sb.Append($APIVersion)
    [void]$sb.replace('{0}',$SubscriptionID)
    [void]$sb.replace('{1}',$BlueprintName)

    return $sb.ToString()
}