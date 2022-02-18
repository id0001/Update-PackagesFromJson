<#
	Run from inside visual studio.
	Open the 'Package manager console' and run the script from the location you put it in.
	eg: C:\Update-PackagesFromJson.ps1 -Search "my.package.v1" -Json C:\my-packages.json

    Json:

    {
        "package1": ["relative-project-path", "relative-project-path"],
        "package2": ["relative-project-path", "relative-project-path"]
    }

	Usage:
	  Update-PackagesFromJson -Search <partial name of the package> -Json <path to json file> [-Force]
	  
	Options:
	  -Search  A search string for the package name. Can be partial name.
      -Json    The path to the json file.
	  -Force   Don't ask for confirmation when set to true.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $Search,

    [Parameter(Mandatory=$true)]
    [string]
    $Json,

    [Parameter()]
    [switch]
    $Force
    )


function Find-VersionName {
    param(
        [string]$Package,
        [string]$Search
    )
    
    $latest = (Find-Package -Id "$Package" -AllVersions -IncludePrerelease -First 100).Versions | Where-Object {$_.OriginalVersion -like "*$Search*"} | Select-Object -First 1 -ExpandProperty OriginalVersion
    if($latest -ne $null) {
        return $latest.Substring(0, $latest.IndexOf("+"))
    }

    return $null
}

function Update-PackageWithRetry {
    param(
        [string]$Project,
        [string]$Package,
        [string]$Version,
        [int]$Times
    )

    Write-Host "Updating $Package to version $Version..."

    for($i = 0; $i -lt $times; $i++){
        try {
            Update-Package -Id $Package -Version $Version -ProjectName $Project
            Write-Host "Done."
            break
        } catch {
            Write-Warning "Retrying package update: $($i+1)/$Times"
        }
    }
}

function Get-JsonData {
    param(
        [string]$File
    )

    $out = Get-Content $File -Raw | ConvertFrom-Json
    $hash = @{}
    $out.psobject.properties | foreach { $hash[$_.Name]=$_.Value }
    return $hash;
}

$previousVersion = $null
$jsonData = Get-JsonData $Json

foreach($package in $jsonData.Keys) {
    foreach($project in $jsonData[$package]) {
        $version = Find-VersionName -Package $package -Search $Search

        if($version -eq $null) {
            Write-Host "Version could not be found, please try again." -BackgroundColor Red
            exit
        }

        $Force = $Force -or $version -eq $previousVersion

        if($PSCmdlet.ShouldProcess("Updating UI packages to: $version", "Are you sure you want to update the packages to this version?", $version)) {
            if($Force -or $PSCmdlet.ShouldContinue("Are you sure you want to update the packages to this version?","Updating UI packages to: $version")) {
                Update-PackageWithRetry -Project $project -Package $package -Version $version -Times 3
            } else {
                exit
            }
        }

        $previousVersion = $version
    }
}