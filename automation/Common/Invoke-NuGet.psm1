function Invoke-NuGet { param ($assembly, $projectpath, $repo, $command)

    $nugetLocation = $repo + "\Automation\tools"

    #$source = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    #$Filename = [System.IO.Path]::GetFileName($source)
    #$nuget = "$nugetLocation\$Filename"
    $nuget = "$nugetLocation\nuget.exe"

    #$wc = New-Object System.Net.WebClient
    #$wc.DownloadFile($source, $dest)

    if ($command -eq "restoreProjectJson")
    {
        $projJson = $projectpath + "\" + $assembly + "\" + "project.json"
        $nugetparams = "restore", $projJson, "-SolutionDirectory", $projectpath
        & $nuget $nugetparams
    }

    if ($command -eq "restorePackages")
    {
        $proj = $projectpath + "\" + $assembly + "\" + $assembly + ".csproj"
        $nugetparams = "restore", $proj, "-SolutionDirectory", $projectpath
        & $nuget $nugetparams
    }
    
    if ($command -eq "pack")
    {
        $proj = $projectpath + "\" + $assembly + "\" + $assembly + ".csproj"
        $nugetparams = "spec", "-f", $proj  
        & $nuget $nugetparams

        $nugetparams = "pack", $proj  
        & $nuget $nugetparams
    } 
}

Export-ModuleMember -Function Invoke-NuGet