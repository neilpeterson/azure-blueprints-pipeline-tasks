$ManagementGroupBaseURI = "https://management.azure.com/providers/Microsoft.Management/managementGroups/{0}/providers/Microsoft.Blueprint/blueprints/{1}"
$SubscriptionBaseURI = "https://management.azure.com/subscriptions/{0}/providers/Microsoft.Blueprint/blueprints/{1}"
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

function Get-BlueprintVersionsURI {

    param (
        [string]$Scope,
        [string]$ManagementGroup,
        [string]$SubscriptionID,
        [string]$BlueprintName
    )

    $sb = [System.Text.StringBuilder]::new()

    If ($Scope -eq "ManagementGroup") {

        [void]$sb.Append($ManagementGroupBaseURI)
        [void]$sb.Append("/versions")
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$ManagementGroup)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()

    } ElseIf ($Scope -eq "Subscription") {

        [void]$sb.Append($SubscriptionBaseURI)
        [void]$sb.Append("/versions")
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$SubscriptionID)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()
    }
}

function Get-AllArtifactsURI {

    param (
        [string]$Scope,
        [string]$ManagementGroup,
        [string]$SubscriptionID,
        [string]$BlueprintName
    )

    $sb = [System.Text.StringBuilder]::new()

    If ($Scope -eq "ManagementGroup") {

        [void]$sb.Append($ManagementGroupBaseURI)
        [void]$sb.Append("/artifacts")
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$ManagementGroup)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()

    } ElseIf ($Scope -eq "Subscription") {

        [void]$sb.Append($SubscriptionBaseURI)
        [void]$sb.Append("/artifacts")
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$SubscriptionID)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()
    }
}

function Get-ArtifactURI {

    param (
        [string]$Scope,
        [string]$ManagementGroup,
        [string]$SubscriptionID,
        [string]$BlueprintName,
        [string]$ArtifactName
    )

    $sb = [System.Text.StringBuilder]::new()

    If ($Scope -eq "ManagementGroup") {

        [void]$sb.Append($ManagementGroupBaseURI)
        [void]$sb.Append("/artifacts/")
        [void]$sb.Append($ArtifactName)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$ManagementGroup)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()

    } ElseIf ($Scope -eq "Subscription") {

        [void]$sb.Append($SubscriptionBaseURI)
        [void]$sb.Append("/artifacts/")
        [void]$sb.Append($ArtifactName)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$SubscriptionID)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()
    }
}

function Get-PublishBlueprintURI {

    param (
        [string]$Scope,
        [string]$ManagementGroup,
        [string]$SubscriptionID,
        [string]$BlueprintName,
        [string]$BlueprintVersion
    )

    $sb = [System.Text.StringBuilder]::new()

    If ($Scope -eq "ManagementGroup") {

        [void]$sb.Append($ManagementGroupBaseURI)
        [void]$sb.Append("/versions/")
        [void]$sb.Append($BlueprintVersion)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$ManagementGroup)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()

    } ElseIf ($Scope -eq "Subscription") {

        [void]$sb.Append($SubscriptionBaseURI)
        [void]$sb.Append("/versions/")
        [void]$sb.Append($BlueprintVersion)
        [void]$sb.Append($APIVersion)
        [void]$sb.replace('{0}',$SubscriptionID)
        [void]$sb.replace('{1}',$BlueprintName)

        return $sb.ToString()
    }
}
