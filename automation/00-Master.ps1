[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The name of the Azure Subscription for which you've imported a *.publishingsettings file.")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the resource group.")]
    [string]$ResourceGroup,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="The common prefix for resources naming: looksfamiliar")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=4, HelpMessage="The suffix which is one of 'dev', 'test' or 'prod'")]
    [string]$Suffix

)

$Path = Split-Path -parent $PSCommandPath
$path = Split-Path -parent $path

$command = $Path + "\Automation\01-Provision-ServiceBus.ps1"
&$command -subscription $Subscription -azurelocation $AzureLocation -prefix $Prefix -suffix $suffix

$command = $Path + "\Automation\02-Provision-IoTHub.ps1"
&$command -subscription $Subscription -resourcegroup $ResourceGroup -azurelocation $AzureLocation -prefix $Prefix -suffix $suffix

$command = $Path + "\Automation\03-Provision-DocumentDb.ps1"
&$command -subscription $Subscription -resourcegroup $ResourceGroup -azurelocation $AzureLocation -prefix $Prefix -suffix $suffix
