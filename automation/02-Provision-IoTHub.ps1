<# 
.Synopsis 
    This PowerShell script provisions the Azure components for the d2c2d solution
.Description 
    This PowerShell script provisions the Azure components for the d2c2d solution
.Notes 
    File Name  : Provision-IoTHub.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Provision-IoTHub.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Link   
    https://microservices.codeplex.com/

.Parameter Subscription
    Example:  MySubscription
.Parameter ResourceGroup
    Example:  MyResourceGruop
.Parameter AzureLocation
    Example:  East US
.Parameter Prefix
    Example:  myOrg
.Parameter Suffix
    Example:  test
.Inputs
    The [Subscription] parameter is the name of the client Azure subscription.
    The [ResourceGroup] parameter is the name of the resource group.
    The [AzureLocation] parameter is the name of the Azure Region/Location to host the Virtual Machines for this subscription.
    The [Prefix] parameter is the common prefix that will be used to name resources
    The [Suffix] parameter is one of 'dev', 'test' or 'prod'
.Outputs
    Console
#>

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

#######################################################################################
# S E T  P A T H
#######################################################################################

$Path = Split-Path -parent $PSCommandPath
$Path = Split-Path -parent $path

##########################################################################################
# F U N C T I O N S
##########################################################################################

Function Select-Subscription()
{
    Param([String] $Subscription)

    Try
    {
        Set-AzureRmContext  -SubscriptionName $Subscription -ErrorAction Stop
    }
    Catch
    {
        Write-Verbose -Message $Error[0].Exception.Message
    }
}

##########################################################################################
# M A I N
##########################################################################################

$Error.Clear()

# Mark the start time.
$StartTime = Get-Date

# Select Subscription
Select-Subscription $Subscription

# Create Resource Group
New-AzureRMResourceGroup -Name $ResourceGroup -Location $AzureLocation

# Create IoTHub
$IoTHubName = $Prefix + "iothub" + $Suffix
$command = $path + "\Automation\Common\Create-IoTHub.ps1"
$iothub = &$command $path $Subscription $IoTHubName $ResourceGroup $AzureLocation

# output iot hub onnection information

# Mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime" -Verbose
