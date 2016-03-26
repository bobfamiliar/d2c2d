<# 
.Synopsis 
    This PowerShell script provisions the DeviceM Microservice
.Description 
    This PowerShell script provisions the DeviceM Microservice
.Notes 
    File Name  : Provision-DeviceM.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Provision-DeviceM.ps1 [Null], [-Full], [-Detailed], [-Examples]
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The path to the Git Repo.")]
    [string]$Repo,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Azure Subscription for which you've imported a *.publishingsettings file.")]
    [string]$Subscription,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The name of the Resouce Group")]
    [string]$ResourceGroup,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=4, HelpMessage="The common prefix for resources naming: looksfamiliar")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=5, HelpMessage="The suffix which is one of 'dev', 'test' or 'prod'")]
    [string]$Suffix

)

##########################################################################################
# V A R I A B L E S
##########################################################################################

# names for app service plans
$ProvisionM_SP = "ProvisionM_SP" 

# unique names for sites
$ProvisionAPI= $Prefix + "ProvisionAPI" + $Suffix

##########################################################################################
# F U N C T I O N S
##########################################################################################

Function Select-Subscription()
{
    Param([String] $Subscription)

    Try
    {
        Set-AzureRmContext -SubscriptionName $Subscription
        Write-Verbose -Message "Currently selected Azure subscription is: $Subscription."
    }
    Catch
    {
        Write-Verbose -Message $Error[0].Exception.Message
        Write-Verbose -Message "Exiting due to exception: Subscription Not Selected."
    }
}

##########################################################################################
# M A I N
##########################################################################################

$Error.Clear()

# mark the start time.
$StartTime = Get-Date

# Select Subscription
Select-Subscription $Subscription

# create app service plan
$command = $repo + "\Automation\Common\Create-AppServicePlan.ps1"
&$command -subscription $Subscription -ResourceGroupName $ResourceGroup -ServicePlanName $ProvisionM_SP -azurelocation $AzureLocation

$command = $repo + "\Automation\Common\Create-WebSite.ps1"
&$command -subscription $Subscription -websitename $ProvisionAPI -ResourceGroupName $ResourceGroup -ServicePlanName $ProvisionM_SP -azurelocation $AzureLocation

# mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime"
