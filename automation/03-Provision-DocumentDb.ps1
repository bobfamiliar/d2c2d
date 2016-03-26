<# 
.Synopsis 
    This PowerShell script provisions DocumentDb
.Description 
    This PowerShell script provisions DocumentDb
.Notes 
    File Name  : 04-Provision-DocumentDb.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\04-Provision-DocumentDb.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Parameter Subscription
    Example:  MySubscription
.Parameter AzureLocation
    Example:  East US
.Parameter Prefix
    Example:  looksfamiliar
.Parameter Suffix
    Example:  dev
.Inputs
    The [Subscription] parameter is the name of the client Azure subscription.
    The [ResourceGroup] parameter is the name of the Azure Resource group to deploy into
    The [AzureLocation] parameter is the name of the Azure Region/Location to host the Virtual Machines for this subscription.
    The [Prefix] parameter is the common prefix that will be used to name resources
    The [Suffix] parameter is one of 'dev', 'tst' or 'prd'
.Outputs
    Console
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The name of the resource group to deploy to")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Resource Group.")]
    [string]$ResourceGroup,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=4, HelpMessage="The common prefix for resources naming: looksfamiliar")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=5, HelpMessage="The suffix which is one of 'dev', 'test' or 'prod'")]
    [string]$Suffix
)

#######################################################################################
# F U N C T I O N S
#######################################################################################

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

#######################################################################################
# S E T  P A T H
#######################################################################################

$Path = Split-Path -parent $PSCommandPath
$Path = Split-Path -parent $path

#######################################################################################
# M A I N 
#######################################################################################

$Error.Clear()

# Mark the start time.
$StartTime = Get-Date

$DocDbname = $Prefix + "docdb" + $Suffix

Select-Subscription $Subscription

# Create DocumentDb
$command = $Path + "\Automation\Common\Create-DocumentDb.ps1"
&$command $Path $Subscription $DocDbname $ResourceGroup $AzureLocation

# Mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime" -Verbose