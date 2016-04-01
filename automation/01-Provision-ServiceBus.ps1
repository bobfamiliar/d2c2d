<# 
.Synopsis 
    This PowerShell script provisions the Azure components for the d2c2d solution
.Description 
    This PowerShell script provisions the Azure components for the d2c2d solution
.Notes 
    File Name  : Provision-ServiceBus.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Provision-ServiceBus.ps1 [Null], [-Full], [-Detailed], [-Examples]

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
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$AzureLocation,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The common prefix for resources naming: looksfamiliar")]
    [string]$Prefix,
    [Parameter(Mandatory=$True, Position=3, HelpMessage="The suffix which is one of 'dev', 'test' or 'prod'")]
    [string]$Suffix

)

#######################################################################################
# S E T  P A T H
#######################################################################################

$Path = Split-Path -parent $PSCommandPath
$Path = Split-Path -parent $path

#######################################################################################
# I M P O R T S
#######################################################################################

$CreateQueue = $Path + "\Automation\Common\Create-Queue.psm1"
Import-Module -Name $CreateQueue

##########################################################################################
# F U N C T I O N S
##########################################################################################

Function Select-Subscription()
{
    Param([String] $Subscription)

    Try
    {
        Select-AzureSubscription -SubscriptionName $Subscription -ErrorAction Stop
    }
    Catch
    {
        Write-Verbose -Message $Error[0].Exception.Message
    }
}

function GetUniqueResourceName()
{
    Param(
        [Parameter(Mandatory=$true,Position=0)] [string] $resourceBaseName
    )
    $name = $resourceBaseName
    $name = "{0}{1:x5}" -f $resourceBaseName, (get-random -max 1048575)
    return $name
}

Function Create-ServiceBus-Namespace()
{
    Param  ([String] $Subscription, [String] $AzureLocation, [String] $Namespace)

    Try
    {
        Write-Verbose -Message "[Start] Creating new Azure Service Bus Namepsace: $Namespace in $Subscription."

        $AzureSBNS = New-AzureSBNamespace -Name $namespace -NamespaceType Messaging -Location $AzureLocation -CreateACSNamespace $false -ErrorAction Stop

        Write-Verbose -Message "[Finish] Created new Azure Service Bus Namepsace: $Namespace, in $AzureLocation."
    }
    Catch # Catching this exception implies that another Azure subscription worldwide, has already claimed this Azure Service Bus Namespace.
    {
        Throw "Namespace, $Namespace in $AzureLocation, is not available! Azure Namespaces must be UNIQUE worldwide. Aborting..."
    } 

    Return $AzureSBNS
}

##########################################################################################
# M A I N
##########################################################################################

$Error.Clear()

# Mark the start time.
$StartTime = Get-Date

# Select Subscription
Select-Subscription $Subscription

try
{
    # WARNING: Make sure to reference the latest version of Microsoft.ServiceBus.dll
    Write-Output "Adding the [Microsoft.ServiceBus.dll] assembly to the script..."
    $scriptPath = Split-Path (Get-Variable MyInvocation -Scope 0).Value.MyCommand.Path
    $packagesFolder = (Split-Path $scriptPath -Parent) + "\automation\packages"
    $assembly = Get-ChildItem $packagesFolder -Include "Microsoft.ServiceBus.dll" -Recurse
    Add-Type -Path $assembly.FullName

    Write-Output "The [Microsoft.ServiceBus.dll] assembly has been successfully added to the script."
}

catch [System.Exception]
{
    Write-Output("Could not add the Microsoft.ServiceBus.dll assembly to the script. Make sure you build the solution before running the provisioning script.")
}

#Create Service bus and queue
$sbnamespace = $prefix + "sbname" + $suffix
$unamespace = GetUniqueResourceName($sbnamespace)

$AzureSBNS = Get-AzureSBNamespace $unamespace
if ($AzureSBNS)
{
    Write-Output "Service Bus Namespace already exists."
    $ConnStr = $AzureSBNS.ConnectionString

    try
    {
        Create-ServiceBus-Queue -RepoPath $Path -ConnStr $ConnStr -QueueName messagedrop
        Write-Output -Message "Created Queue messagedrop in $unamespace"
    }
    catch [System.Exception]
    {
        Write-Output "ERROR: Creating Queue messagedrop in $unamespace"
    }

    try
    {
        Create-ServiceBus-Queue -RepoPath $Path -ConnStr $ConnStr -QueueName alarms
        Write-Output -Message "Created Queue alarms in $unamespace"
    }
    catch [System.Exception]
    {
        Write-Output "ERROR: Creating Queue alarms in $unamespace"
    }
}
else
{
    $CurrentNamespace = Create-ServiceBus-Namespace -subscription $Subscription -azurelocation $AzureLocation -namespace $unamespace -erroraction   
    $CurrentNamespace = Get-AzureSBNamespace -Name $unamespace
    Write-Output "The $unamespace namespace in the $AzureLocation region has been successfully created."

    $AzureSBNS = Get-AzureSBNamespace $unamespace
    $ConnStr = $AzureSBNS.ConnectionString

    try
    {
        Create-ServiceBus-Queue -RepoPath $Path -ConnStr $ConnStr -QueueName messagedrop
        Write-Output "Created Queue messagedrop in $unamespace"
    }
    catch [System.Exception]
    {
        Write-Output "ERROR: Creating Queue messagedrop in $unamespace"
    }

    try
    {
        Create-ServiceBus-Queue -RepoPath $Path -ConnStr $ConnStr -QueueName alarms
        Write-Output "Created Queue alarms in $unamespace"
    }
    catch [System.Exception]
    {
        Write-Output "ERROR: Creating Queue alrams in $unamespace"
    }
}

# Mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime" -Verbose
