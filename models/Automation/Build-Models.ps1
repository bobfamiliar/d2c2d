<#
.Synopsis 
    This PowerShell script builds the D2C2D Message Models
.Description 
    This PowerShell script builds the D2C2D Message Models
.Notes 
    File Name  : Build-Models.ps1
    Author     : Bob Familiar
    Requires   : PowerShell V4 or above, PowerShell / ISE Elevated
    Requires   : Invoke-MsBuild.psm1
    Requires   : Invoke-NuGetsUpdate.psm1

    Please do not forget to ensure you have the proper local PowerShell Execution Policy set:

        Example:  Set-ExecutionPolicy Unrestricted 

    NEED HELP?

    Get-Help .\Build-Models.ps1 [Null], [-Full], [-Detailed], [-Examples]

.Parameter Repo
    Example:  c:\users\bob\source\repos\d2c2d
.Parameter Configuration
    Example:  Debug
.Example
    .\Build-Models.ps1 -repo "c:\users\bob\source\repos\d2c2d" -configuration "debug"
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

Import-Module -Name $msbuildScriptPath
Import-Module -Name $nugetInvokeScriptPath

#######################################################################################
# V A R I A B L E S
#######################################################################################

$msbuildargsBuild = "/t:clean /t:Rebuild /p:Configuration=" + $configuration + " /v:normal"
$packagedrop = $repo + "\nugets"

#######################################################################################
# F U C N T I O N S
#######################################################################################

Function Build-Status { param ($success, $project, $operation)

    $message = ""

    if ($success)
    { 
        $message = $project + " " + $operation + " completed successfully."
    }
    else
    { 
        $message = $project + " " + $operation + " failed. Check the log file for errors."
    }

    Write-Verbose -Message $message -Verbose
}

Function Copy-Nuget { param ($assembly, $path)

    $nuget = ".\*.nupkg"
    Move-Item $nuget -Destination $packagedrop
}

Function Build-Project { param ($assembly, $path)

    $sol = $path + "\" + $assembly + ".sln"
    $buildSucceeded = Invoke-MsBuild -Path $sol -MsBuildParameters $msbuildargsBuild
    Build-Status $buildSucceeded $assembly "build"
}

#######################################################################################
# C L E A N 
#######################################################################################

$devicepack = $repo + "\nugets\*messagemodels*.*"
Remove-Item $devicepack -WhatIf
Remove-Item $devicepack -Force

#######################################################################################
# M O D E L S
#######################################################################################

$path = $repo + "\models\net4"
$assembly = "messagemodels"

Invoke-Nuget $assembly $path $repo restorePackages
Build-Project $assembly $path
Invoke-Nuget $assembly $path $repo pack
Copy-Nuget $assembly $path

$path = $repo + "\models\net5"
$assembly = "messagemodels"

Invoke-Nuget $assembly $path $repo restoreProjectJson
Build-Project $assembly $path
Invoke-Nuget $assembly $path $repo pack
Copy-Nuget $assembly $path