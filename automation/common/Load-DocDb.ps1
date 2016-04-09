[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The path to the Git Repo.")]
    [string]$Repo,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="The name of the Azure Region/Location: East US, Central US, West US.")]
    [string]$DocDbConnStr,
    [Parameter(Mandatory=$True, Position=2, HelpMessage="The common prefix for resource naming")]
    [string]$CollectionName
)

#######################################################################################
# I M P O R T S
#######################################################################################

$invokeDT = $repo + "\Automation\Common\Invoke-DataTransfer.psm1"
Import-Module -Name $invokeDT

#######################################################################################
# V A R I A B L E S 
#######################################################################################

$DataPath = $Repo + "\Automation\Deploy\Data\" + $CollectionName

##########################################################################################
# M A I N
##########################################################################################

$Error.Clear()

# Mark the start time.
$StartTime = Get-Date

Write-Output -Verbose "Load-DocumentDb '$Repo' '$DataPath'"

# create a database, a collection and transfer data if there is any
Invoke-DataTransfer $Repo $DataPath $DocDbConnStr $CollectionName

# Mark the finish time.
$FinishTime = Get-Date

#Console output
$TotalTime = ($FinishTime - $StartTime).TotalSeconds
Write-Verbose -Message "Elapse Time (Seconds): $TotalTime"