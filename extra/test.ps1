<#
 .DESCRIPTION
    Creates Azure BluePrint
 .NOTES
    Author: Neil Peterson
    Intent: Sample to demonstrate Azure BluePrints with Azure DevOps
 #>

 param (
    [string]$ManagementGroup,
    [string]$TenantId="72f988bf-86f1-41af-91ab-2d7cd011db47",
    [string]$ClientId="d897503d-678e-4fd0-ab03-45dcfd82895a",
    [string]$ClientSecret="3eac0be6-78c4-4e36-99ad-c6f1582f196e"
  )

# Acquire an access token
$Resource = "https://management.core.windows.net/"
$RequestAccessTokenUri = 'https://login.microsoftonline.com/{0}/oauth2/token' -f $TenantId
$body = "grant_type=client_credentials&client_id={0}&client_secret={1}&resource={2}" -f $ClientId, $ClientSecret, $Resource
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

$Headers = @{}
$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
$mg = Invoke-RestMethod -Method Get -Uri https://management.azure.com/providers/Microsoft.Management/managementGroups?api-version=2018-03-01-preview -ContentType 'application/json' -Header $Headers
$s = Invoke-RestMethod -Method Get -Uri https://management.azure.com/subscriptions?api-version=2016-06-01 -ContentType 'application/json' -Header $Headers

$a = ConvertTo-JSON $mg
$b = ConvertFrom-JSON $a

write-host $a
write-host $b.value.name

$c = ConvertTo-JSON $s
$d = ConvertFrom-JSON $c
write-host $d.value.subscriptionId

# foreach ($item in $mg) {
#     write-host $item
# }