<#
.Synopsis 
    This PowerShell script builds the ProvisionM Microservice
.Description 
    This PowerShell script builds the ProvisionM Microservice
.Notes 
    File Name  : Build-ProvisionM.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated
    Requires   : Invoke-MsBuild.psm1
    Requires   : Invoke-NuGetsUpdate.psm1

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Build-ProvisionM.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Parameter Repo
    Example:  c:\users\bob\source\repos\looksfamiliar
.Parameter Configuration
    Example:  Debug
.Example
    .\Device.ps1 -repo "c:\users\bob\source\repos\looksfamiliar" -configuration "debug"
.Inputs
    The [Repo] parameter is the path to the top level folder of the Git Repo.
    The [Configuration] parameter is the build configuration such as Debug or Release
.Outputs
    Console
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True, Position=0, HelpMessage="The Path to the Git Repo")]
    [string]$repo,
    [Parameter(Mandatory=$True, Position=1, HelpMessage="Build configuration such as Debug or Release")]
    [string]$configuration
)

#######################################################################################
# I M P O R T S
#######################################################################################

$msbuildScriptPath = $repo + "\Automation\Common\Invoke-MsBuild.psm1"
$nugetInvokeScriptPath = $repo + "\Automation\Common\Invoke-NuGet.psm1"
$nugetUpdateScriptPath = $repo + "\Automation\Common\Invoke-UpdateNuGet.psm1"

Import-Module -Name $msbuildScriptPath
Import-Module -Name $nugetInvokeScriptPath
Import-Module -Name $nugetUpdateScriptPath

#######################################################################################
# V A R I A B L E S
#######################################################################################

$msbuildargsBuild = "/t:clean /t:Rebuild /p:Configuration=" + $configuration + " /v:normal"
$packagedrop = $repo + "\nugets"

#######################################################################################
# F U N C T I O N S
#######################################################################################

Function Build-Status { param ($success, $project, $operation)

    $message = ""

    if ($success)
    { 
        $message = $project + " " + $operation + " completed successfully."
        Write-Verbose -Message $message -Verbose
    }
    else
    { 
        $message = $project + " " + $operation + " failed. Check the log file for errors."
        Throw $message
    }

}

Function Copy-Nuget { param ($assembly, $path)

    $nuget = ".\*.nupkg"
    Move-Item $nuget -Destination $packagedrop
}

Function Build-Project { param ($assembly, $path)

    $sol = $path + "\" + $assembly + ".sln"
    $buildSucceeded = Invoke-MsBuild -Path $sol -MsBuildParameters $msbuildargs
    Build-Status $buildSucceeded $assembly
}

#######################################################################################
# C L E A N 
#######################################################################################

$provisionpack = $repo + "\nugets\*provision*.*"
Remove-Item $provisionpack -WhatIf
Remove-Item $provisionpack -Force

#######################################################################################
# I N T E R F A C E
#######################################################################################

$path = $repo + "\Microservices\Provision\Interface"
$assembly = "IProvision"

$packagesFolder = $path + "\packages\*.*"
Remove-Item $packagesFolder -Recurse -WhatIf -ErrorAction Ignore
Remove-Item $packagesFolder -Recurse -Force -ErrorAction Ignore

Invoke-Nuget $assembly $path $repo restore
Update-NuGet IProvision MessageModelsNet4 $path $repo net461
Invoke-Nuget $assembly $path $repo restore

Build-Project $assembly $path
Invoke-Nuget $assembly $path $repo pack
Copy-Nuget $assembly $path

#######################################################################################
# S E R V I C E
#######################################################################################

$path = $repo + "\Microservices\Provision\Service"
$assembly = "ProvisionService"

$packagesFolder = $path + "\packages\*.*"
Remove-Item $packagesFolder -Recurse -WhatIf -ErrorAction Ignore
Remove-Item $packagesFolder -Recurse -Force -ErrorAction Ignore

Invoke-Nuget $assembly $path $repo restore
Update-NuGet ProvisionService MessageModelsNet4 $path $repo net461
Update-NuGet ProvisionService Store $path $repo net461
Update-NuGet ProvisionService IProvision $path $repo net461
Invoke-Nuget $assembly $path $repo restore

Build-Project $assembly $path
Invoke-Nuget $assembly $path $repo pack
Copy-Nuget $assembly $path

#######################################################################################
# S D K
#######################################################################################

$path = $repo + "\Microservices\Provision\SDK"
$assembly = "ProvisionSDK"

$packagesFolder = $path + "\packages\*.*"
Remove-Item $packagesFolder -Recurse -WhatIf -ErrorAction Ignore
Remove-Item $packagesFolder -Recurse -Force -ErrorAction Ignore

Invoke-Nuget $assembly $path $repo restore
Update-NuGet ProvisionSDK MessageModelsNet4 $path $repo net461
Update-NuGet ProvisionSDK Wire $path $repo net461
Update-NuGet ProvisionSDK IProvision $path $repo net461
Invoke-Nuget $assembly $path $repo restore

Build-Project $assembly $path
Invoke-Nuget $assembly $path $repo pack
Copy-Nuget $assembly $path

#######################################################################################
# A P I
#######################################################################################

$path = $repo + "\Microservices\Provision\API"
$assembly = "ProvisionAPI"

$packagesFolder = $path + "\packages\*.*"
Remove-Item $packagesFolder -Recurse -WhatIf -ErrorAction Ignore
Remove-Item $packagesFolder -Recurse -Force -ErrorAction Ignore

Invoke-Nuget $assembly $path $repo restore
Update-NuGet ProvisionAPI MessageModelsNet4 $path $repo net461
Update-NuGet ProvisionAPI Store $path $repo net461
Update-NuGet ProvisionAPI IProvision $path $repo net461
Update-NuGet ProvisionAPI ProvisionService $path $repo net461
Invoke-Nuget $assembly $path $repo restore

Build-Project $assembly $path
