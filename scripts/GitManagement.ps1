<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : Calliope 3Li
Description  : Git management
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies : posh-git (https://github.com/dahlbyk/posh-git)
               Git
------------------------------------------------------------------------------------------------------------------
Revisions    : #12633 : 15/04/2020 : PMN : Initial version
               #14111 : 29/07/2020 : PMN : Add functions Invoke-GitCloneRemoteRepos, Invoke-GitCommit, Invoke-GitAdd and Set-GitUserAndCredential
			   #1360 : 15/03/2021 : PMN : Fix posh-git new version installation
			   #4223 : 18/10/2021 : PMN : Add --depth 1 to Invoke-GitCloneRemoteRepos
------------------------------------------------------------------------------------------------------------------
#>

Function Install-PoshGit
{
	$Module = Get-InstalledModule -Name posh-git -ErrorAction SilentlyContinue
	if ($Module) 
	{
		$VersionStr = $Module.Version.ToString()
		Write-Host "posh-git $VersionStr is installed"
		$OnlineModule = Find-Module -Name posh-git -ErrorAction SilentlyContinue
		if ($OnlineModule) 
		{
			$LatestVersion = $OnlineModule.Version 
			$PoshGitVersion = $LatestVersion.ToString()
			Write-Host "posh-git $PoshGitVersion is the latest version"
			if ($PoshGitVersion -ne $Module.Version) 
			{
				Write-Host "Updating posh-git to $PoshGitVersion"
				Update-Module -Name posh-git -Force -RequiredVersion $PoshGitVersion
				Write-Host "posh-git updated"
			}
		} else {
			Write-Warning "Unable to check online latest version of posh-git (check Internet connectivity)"
		}
	} 
	else 
	{
		if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
			Write-Host "Installing NuGet Package Provider"
			Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -WarningAction SilentlyContinue | Out-Null
		}
		Write-Host "Installing posh-git"
		Install-Module -Name posh-git -Force
		$Module = Get-InstalledModule -Name posh-git -ErrorAction SilentlyContinue
		$VersionStr = $Module.Version.ToString()
		Write-Host "Add current branch to PowerShell prompt"
		Add-PoshGitToProfile -AllHosts -Force
		Write-Host "posh-git $VersionStr installed"
	}
}

Function Get-GitCurrentBranch
{
    Param(
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder = (Get-Location)
    )
	$env:GIT_REDIRECT_STDERR = '2>&1'
	$CurrentBranch = ""
	$CurrentLocation = Get-Location
	try
	{
		Set-Location -Path $GitFolder
		git branch | foreach {
			if ($_ -match "^\* (.*)") {
				$CurrentBranch += $matches[1]
			}
		}
	}
	finally
	{
		Set-Location -Path $CurrentLocation
	}
	return $CurrentBranch
}

Function Get-GitBranches
{
    Param(
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder = (Get-Location)
    )
	$env:GIT_REDIRECT_STDERR = '2>&1'
	$Branches = @()
	$CurrentLocation = Get-Location
	try
	{
		Set-Location -Path $GitFolder
		git branch | foreach {
			if ($_ -match "^\* (.*)") {
				$Branches += $matches[1]
			} else { $Branches += $_.Trim()}
		}
	}
	finally
	{
		Set-Location -Path $CurrentLocation
	}
	return $Branches
}

Function Write-GitWelcomeText
{
	Write-host "Welcome to Git PowerShell Prompt" -ForegroundColor Yellow
	Write-host ""
	Write-host "Git commands help" -ForegroundColor Yellow
	git
	Write-host ""
	Write-host "Git additional Powershell commands" -ForegroundColor Yellow
	Write-host "Get-GitBranches               Get Git local branches for a specific local folder"
	Write-host "Get-GitCurrentBranch          Get Git local current branch for a specific local folder"
	Write-host "Switch-GitBranch              Switch Git local current branch for a specific local folder"
	Write-host ""
	Write-host "Git local branches list" -ForegroundColor Yellow
	git branch
	Write-host ""
}

Function Switch-GitBranch
{
    Param(
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder = (Get-Location),
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$TargetGitBranch
    )
	$GitBranches = Get-GitBranches -GitFolder $GitFolder
	if ($GitBranches.Contains($TargetGitBranch))
	{
		$env:GIT_REDIRECT_STDERR = '2>&1'
		$CurrentLocation = Get-Location
		try
		{
			Set-Location -Path $GitFolder
			git switch $TargetGitBranch
		}
		finally
		{
			Set-Location -Path $CurrentLocation
		}
	}
	else
	{
		Write-Error "Error : $TargetGitBranch in not a valid branch name."
	}
}

Function Get-GitCurrentBranchColor
{
	Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitBranch,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitBranchesSupported
    )
	$SplitGitBranchesSupported = $GitBranchesSupported.Split(",")
	$Result = "Red"
	if ($SplitGitBranchesSupported.Contains($GitBranch))
	{
		if ($SplitGitBranchesSupported[0] -eq $GitBranch) { $Result = "Green" } else { $Result = "Yellow" }
	}
	return $Result
}

Function Invoke-GitCloneRemoteRepos
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitRemoteReposUrl,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitBranch="",
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder
    )
	$env:GIT_REDIRECT_STDERR = '2>&1'
	if ($GitBranch -eq "") {
		Write-Host "Git clone defaut branch (with --depth1) from remote repos $GitRemoteReposUrl"
		git clone --depth 1 --single-branch $GitRemoteReposUrl "$GitFolder"
	} else {
		Write-Host "Git clone $GitBranch branch (with --depth1) from remote repos $GitRemoteReposUrl"
		git clone --depth 1 --single-branch --branch $GitBranch $GitRemoteReposUrl "$GitFolder"
	}
}

Function Invoke-GitCommit
{
    Param(
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitCommitMessage,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$GitCommitAndPush
	)
	$env:GIT_REDIRECT_STDERR = '2>&1'
	$CurrentLocation = Get-Location
	try
	{
		Set-Location -Path $GitFolder
		git commit -a -m $GitCommitMessage
		if ($GitCommitAndPush) { git push --porcelain }
	}
	finally
	{
		Set-Location -Path $CurrentLocation
	}
}

Function Invoke-GitAdd
{
    Param(
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$Path
	)
	$env:GIT_REDIRECT_STDERR = '2>&1'
	$CurrentLocation = Get-Location
	try
	{
		Set-Location -Path $GitFolder
		git add --force $Path
		if ($GitCommitAndPush) { git push --porcelain }
	}
	finally
	{
		Set-Location -Path $CurrentLocation
	}
}

Function Set-GitUserAndCredential
{
    Param(
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitUserEmail,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$GitUserName,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitCredentialUrl="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$GitCredentialPassword=""
	)
	$env:GIT_REDIRECT_STDERR = '2>&1'
	Write-Host "Set Git user email and name to $GitUserEmail and $GitUserName"
	git config --global user.email $GitUserEmail
	git config --global user.name $GitUserName
	if ($GiCredentialUrl -ne "" -and $GitCredentialPassword  -ne "") {
		Write-Host "Set Git credential to Windows Credential Manager for $GitCredentialUrl"
		$Result = cmdkey /generic:LegacyGeneric:target=$GitCredentialUrl /user:PersonalAccessToken /pass:$GitCredentialPassword
		Write-Host $Result
	}
}
