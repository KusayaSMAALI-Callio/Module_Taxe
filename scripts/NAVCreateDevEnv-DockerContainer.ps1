<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : 3Li Business Solutions
Description  : Create local developpement environment (Docker container)
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies :
------------------------------------------------------------------------------------------------------------------
Revisions    : 03/10/2018 : PMN : Initial version
		       22/09/2018 : PMN : Add parameter -accept_outdated to container creation
               25/11/2018 : PMN : Refactoring scripts
			   28/11/2018 : PMN : Refactoring scripts (add import fob)
			   01/12/2018 : PMN : Add additionnal Dev install scripts
			   08/12/2018 : PMN : Replace fob import by baseline database
			   09/12/2018 : PMN : Add environment management Url and shortcut
			   10/12/2018 : PMN : Check memory requirements and fix 3G
			   11/12/2018 : PMN : Fix 4G for container memory and add container scripts (for install NF525 certificate in container)
			   17/12/2018 : PMN : Update to D365BC
			   05/01/2019 : PMN : Fix D365BC Windows client path
			   09/01/2019 : PMN : Update to edition projects
			   17/01/2019 : PMN : Add Sandbox accepted BranchName and check case sentitive BranchName
			   17/01/2019 : PMN : Add Build shortcuts
			   17/01/2019 : PMN : Add build with containers
			   27/01/2019 : PMN : Update build to edition projects
			   25/02/2019 : PMN : Fix bug folder doesn't exist to save Credential.xml and build scripts
			   11/09/2019 : PMN : Create container with -enableSymbolLoading
			   07/10/2019 : PMN : Update for AL projects and BC v15
			   08/10/2019 : PMN : Add ProjectObjectsToIgnore
			   09/10/2019 : PMN : Rename NAVCodeManagement to NAVCALCodeManagement, add NAVDockerContainerManagement
			   09/10/2019 : PMN : Add authentication mode UserPassword for containers
			   09/10/2019 : PMN : Autoupdate NavContainerHelper
			   09/10/2019 : PMN : Create container with isolation Process and useBestContainerOS (for unit tests purpose)
			   09/10/2019 : PMN : Restart container after creation
			   09/10/2019 : PMN : Create container with memoryLimit 8G
			   13/11/2019 : PMN : Adaptations for Base App
			   14/11/2019 : PMN : Fix Create-NavContainer for CALAL projects
			   22/11/2019 : PMN : Add Get-NavContainerBaseAppSource
			   04/12/2019 : PMN : Fix compilation from CSIDE (copy container service tier add-ins to client folder)
			   07/12/2019 : PMN : Fix BranchName <> Dev
			   09/12/2019 : PMN : Fix DevContainerCopyScript if destination folder doesn't exist
			   17/12/2019 : PMN : Fix NAVVersionFolder conversion to int
			   15/01/2020 : PMN : Add ProjectObjectsRangeToIgnore
			   16/01/2020 : PMN : For AL projects copy Baseline Add-Ins to container service tier add-ins folder
			   21/01/2020 : PMN : Fix C:\navdvd path doesn't exist in NAV container if host Windows 10 Edition < 1903
			   23/01/2020 : PMN : Add custom password for Auth = UserPassword 
			   23/01/2020 : PMN : Remove VSTSUser param
			   28/01/2020 : PMN : Add ProjectObjectsShortDateFormat and ProjectObjectsDecimalSeparator management
			   29/01/2020 : PMN : Add container shared folder
   			   #10593 : 31/01/2020 : PMN : Fix bug container shared folder
               #11071 : 26/02/2020 : PMN : Run DevLocalInstallScripts after DevContainerInstallScripts
			   #10595 : 09/03/2020 : PMN : Add $BranchName param in DevLocalInstallScripts
			   #11677 : 31/03/2020 : PMN : Adaptations for BaseApp (especially for CMC BC15)
			                               - Add param NAVContainerMemoryLimitGb in config file  (for container creation memory assigned and checked)
                                           - Add param ProjectAppsBaseAppDependencyAppIdsToNotRepublish for not republish some MS Apps (especialy for AMC Banking not compatible with CMC BC15 BaseApp (DataPerCompany property modified))
               #11198 : 13/04/2020 : PMN : Add $BaselinePath to xml Dev scripts
			   #12752 : 05/05/2020 : PMN : Fix copy file(s) to container if source doesn't exist
			   #12905 : 14/05/2020 : PMN : Add Always pull image for container creation
			   #12633 : 19/05/2020 : PMN : Add Git multibranching management
			   #12756 : 23/06/2020 : PMN : Add NAVContainerLicenseType (Premium, Essentials) management
			   #14116 : 07/07/2020 : PMN : Add BC artifacts management (BC Docker images replacement)
			   #14419 : 24/07/2020 : PMN : Replace Gb by GB
			   #14496 : 03/08/2020 : PMN : Add UpdateOnly param and update license in container
			   #212 : 14/10/2020 : PMN : Fix install in container new version of App, BaseApp and reinstall uninstalled Apps
			   #249 : 06/11/2020 : PMN : Add $ShortcutsPath param to DevLocalInstallScript xml node
			   #255 : 12/11/2020 : PMN : BcContainerHelper migration preparation			   
------------------------------------------------------------------------------------------------------------------
#>

Param(
[Parameter(ValueFromPipelinebyPropertyName=$True)]
[String]$BranchName="",
[Parameter(ValueFromPipelinebyPropertyName=$True)]
[String]$Auth="",
[Parameter(ValueFromPipelinebyPropertyName=$True)]
[String]$MyALWorkspaceSourceFolder="",
[Parameter(ValueFromPipelinebyPropertyName=$True)]
[String]$SQLPassword="",
[Parameter(ValueFromPipelinebyPropertyName=$True)]
[Switch]$UpdateOnly
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "NAVDeploymentManagement.ps1")
. (Join-Path $PSScriptRoot "NAVDockerContainerManagement.ps1")
$MyWorkspaceSourceFolder =  Split-Path $PSScriptRoot -Parent
$MyLicenseFile = "$MyWorkspaceSourceFolder\Configs\NAV-DEV-License.flf"

# Main display
if (-not $UpdateOnly) {
	Write-Host "Create local NAV/BC development environment (Docker container) (c)2020 Calliope" -ForegroundColor Cyan
} else {
	Write-Host "Update local NAV/BC development environment (Docker container) (c)2020 Calliope" -ForegroundColor Cyan
}
Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Cyan

# Read project settingsconfig file
$ConfigFile = "$MyWorkspaceSourceFolder\Configs\ProjectSettings.xml"
[xml]$Xml = Get-Content $ConfigFile
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectName
$ProjectName = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq VSTSUrl
$VSTSUrl = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq VSTSTenant
$VSTSTenant = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq VSTSProjectName
$VSTSProjectName = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq VSTSToken
$VSTSToken = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq SharePointUrl
$SharePointUrl = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq SharePointObjectMgtUrl
$SharePointObjectMgtUrl = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq SharePointEnvironmentMgtUrl
$SharePointEnvironmentMgtUrl = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq CodingRulesUrl
$CodingRulesUrl = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq HostedDns
$HostedDns = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq HostedEnvironmentList
$HostedEnvironmentList = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerName
$NAVContainerName = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerImageName
$NAVContainerImageName = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVDownloadUrl
$NAVDownloadUrl = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVDVDName
$NAVDVDName = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVVersion
$NAVVersion = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVLocalization
$NAVLocalization = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVProductName
$NAVProductName = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVVersionFolder
$NAVVersionFolder = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectTrigram
$ProjectTrigram = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq BuildBaseline
$BuildBaseline = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq BuildNotification
$BuildNotification = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq BuildMaster
$BuildMaster = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectSubName
$ProjectSubName = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectType
$ProjectType = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectObjectsRangeId
$ProjectObjectsRangeId = $Node.Value
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectVersion
$ProjectVersion = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectObjectsToIgnore
$ProjectObjectsToIgnore = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectTargetLanguage
$ProjectTargetLanguage = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectObjectsRangeToIgnore
$ProjectObjectsRangeToIgnore = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectObjectsShortDateFormat
$ProjectObjectsShortDateFormat = $Node.Value 
if (!$ProjectObjectsShortDateFormat) { $ProjectObjectsShortDateFormat = "dd/MM/yyyy" }
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectObjectsDecimalSeparator
$ProjectObjectsDecimalSeparator = $Node.Value
if (!$ProjectObjectsDecimalSeparator) { $ProjectObjectsDecimalSeparator = "," }
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerMemoryLimitGB
$NAVContainerMemoryLimitGB = "4G"
if ($Node.Value -ne $null -and $Node.Value -ne "") { $NAVContainerMemoryLimitGB = $($Node.Value) } else { if ($ProjectTargetLanguage -eq "CAL") { $NAVContainerMemoryLimitGB = "4G" } else { $NAVContainerMemoryLimitGB = "8G"} }
$Node = $Xml.Configuration.Parameter | where Id -eq ProjectAppsBaseAppDependencyAppIdsToNotRepublish
$ProjectAppsBaseAppDependencyAppIdsToNotRepublish = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerGitBranches
$NAVContainerGitBranches = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerLicenseType
if ($Node.Value -ne $null -and $Node.Value -ne "") { $NAVContainerLicenseType = $($Node.Value) } else {  $NAVContainerLicenseType = "Premium" }
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerArtifact
$NAVContainerArtifact = $Node.Value 
$Node = $Xml.Configuration.Parameter | where Id -eq NAVContainerArtifactToken
$NAVContainerArtifactToken = $Node.Value 

$ReadHost = $false
# Get Branch name
$BranchNames = @("Core","Dev", "Main", "Release", "Sandbox")
if ($ProjectTargetLanguage -ne "AL" -and $BranchName -eq "") {
	$BranchName = Read-Host "Enter Branch Name (possible values : $(($BranchNames | ForEach-Object { $_ }) -join ", "))"
	$ReadHost = $true
} else {
	if ($BranchName -eq "") { $BranchName = "Dev" }
}

# Validate Branch name
if (!($BranchNames -ccontains $BranchName))
{
        Write-Warning "$BranchName is not a valid Branch name" 
    	[void](Read-Host 'Press [Enter] to exit...')
        Break
}
# Set container name
$NAVContainerName = "$NAVContainerName-$BranchName"

# Install/update module NavContainerHelper/BcContainerHelper
Install-NavContainerHelper

# Install/update module PoshGit
if ($ProjectTargetLanguage -ne "CAL") 
{ 
	. (Join-Path $PSScriptRoot "GitManagement.ps1")
	Install-PoshGit 
}

# Set Tls protocols
Write-Host "Set Tls protocols"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol

# Test if NAV Container already exist
if (Test-NavContainer -containerName $NAVContainerName)
{
	$ConfirmCreateNAVContainer = "N"
	if (-not $UpdateOnly) {
		Write-Warning "Docker container $NAVContainerName already exist. Are you sure you want to overwrite it (all data inside will be destroyed !!!)" 
		$ConfirmCreateNAVContainer = Read-Host "[Y/N] ?"
		$ReadHost = $true
	}
	if (!(Test-NavContainer -containerName $NAVContainerName -doNotIncludeStoppedContainers))
	{
		Write-Warning "Docker container $NAVContainerName is not started. Starting container $NAVContainerName..."
		# Test memory requirement
		$System = Get-WmiObject win32_OperatingSystem
		$FreePhysicalMem = [math]::round($system.FreePhysicalMemory / 1024 / 1024,1)
		$MemoryRequired = [math]::round([Int]($NAVContainerMemoryLimitGB.Replace("G",""))*0.7,1)
		if ($FreePhysicalMem -lt $MemoryRequired)
		{
			Write-Warning "You do not have enough available memory (at least $MemoryRequired GB required, $FreePhysicalMem GB available) to install/run this Docker container!"
			[void](Read-Host 'Press [Enter] to exit...')
			Break
		}
		else { Write-Host "Memory available : $FreePhysicalMem GB. Container MemoryLimit : $($NAVContainerMemoryLimitGB.Replace(""G"","""")) GB." }
		Write-Host "Starting container $NAVContainerName..."
		Start-NavContainer $NAVContainerName *> $Null
	}
	if (!($ConfirmCreateNAVContainer -eq "Y"))
	{
		# Get NAV Container credentials
		$Auth = (Get-NavContainerServerConfiguration -ContainerName $NAVContainerName).ClientServicesCredentialType
		if ($Auth -eq "NavUserPassword") { $Auth = "UserPassword"}
	}

} else {
	# Test memory requirement
	$System = Get-WmiObject win32_OperatingSystem
	$FreePhysicalMem = [math]::round($system.FreePhysicalMemory / 1024 / 1024,1)
	$MemoryRequired = [math]::round([Int]($NAVContainerMemoryLimitGB.Replace("G",""))*0.7,1)
	if ($FreePhysicalMem -lt $MemoryRequired)
	{
		Write-Warning "You do not have enough available memory (at least $MemoryRequired required, $FreePhysicalMem GB available) to install/run Docker container!"
		[void](Read-Host 'Press [Enter] to exit...')
		Break
	}
	$ConfirmCreateNAVContainer = "Y"
}

# Get Authentication mode
$Auths = @("Windows","UserPassword")
if ($ProjectTargetLanguage -ne "AL" -and $Auth -eq "") {
	$Auth = Read-Host "Enter Authentication mode (possible values : $(($Auths | ForEach-Object { $_ }) -join ", "))"
	$ReadHost = $true
} else {
	if ($Auth -eq "") { $Auth = "UserPassword" }
}

# Validate Authentication mode
if (!($Auths -ccontains $Auth))
{
        Write-Warning "$Auth is not a valid Authentication mode" 
    	[void](Read-Host 'Press [Enter] to exit...')
        Break
}

# Get AL Workspace folder
if ($ProjectTargetLanguage -eq "CALAL" -and $MyALWorkspaceSourceFolder -eq "")
{
	$MyALWorkspaceSourceFolder  = Read-Host "Enter AL Extension Wokspace source folder"
	$ReadHost = $true
}

# Set CAL and AL Workspace source folders
if ($ProjectTargetLanguage -eq "CAL")
{
	$MyCALWorkspaceSourceFolder = $MyWorkspaceSourceFolder
	$MyALWorkspaceSourceFolder = ""
} elseif ($ProjectTargetLanguage -eq "CALAL")
{
	$MyCALWorkspaceSourceFolder = $MyWorkspaceSourceFolder
} elseif ($ProjectTargetLanguage -eq "AL")
{
	$MyCALWorkspaceSourceFolder = ""
	$MyALWorkspaceSourceFolder = $MyWorkspaceSourceFolder
}

# Validate CAL Workspace source folder and branch
if ($MyCALWorkspaceSourceFolder -ne "")
{
	# Test CAL Workspace source folder (with branch) exists
	if (-not (Test-Path "$MyCALWorkspaceSourceFolder\$BranchName"))
	{
		Write-Warning "Local CAL Workspace source folder ""$MyCALWorkspaceSourceFolder\$BranchName"" doesn't exist!" 
		[void](Read-Host 'Press [Enter] to exit...')
		Break
	}

	# Test CAL Workspace source folder is a TFVC Workspace
	$Folder = $MyCALWorkspaceSourceFolder
	if ($ProjectSubName -ne "") { $Folder = Split-Path $Folder -Parent }
	if (-NOT (Test-Path "$Folder\`$tf"))
	{
		Write-Warning "Local CAL Workspace source folder ""$MyCALWorkspaceSourceFolder"" is not a in a TFVC local Workspace!" 
    	[void](Read-Host 'Press [Enter] to exit...')
		Break
	}
}
if ($MyALWorkspaceSourceFolder -ne "")
{
	# Test AL Workspace source folder exists
	if (-NOT (Test-Path "$MyALWorkspaceSourceFolder"))
	{
		Write-Warning "Local AL workspace source folder ""$MyALWorkspaceSourceFolder"" doesn't exist!" 
		[void](Read-Host 'Press [Enter] to exit...')
		Break
	}

	# Test AL Workspace source folder is a Git Workspace
	if (-NOT (Test-Path "$MyALWorkspaceSourceFolder\.git"))
	{
		Write-Warning "Local AL Workspace source folder ""$MyALWorkspaceSourceFolder"" is not a Git local Workspace!" 
    	[void](Read-Host 'Press [Enter] to exit...')
		Break
	}
	if ([int]$NAVVersionFolder -gt [int]"110") # VS Code workspace works only with BC AL Language extension (ms-dynamics-smb.al) and doesn't work with NAV AL Language extension (microsoft.al)
	{
		# Test AL Workspace source folder conains Workspace file Workspace.code-workspace or <Project>.code-workspace
		if (-not (Test-Path "$MyALWorkspaceSourceFolder\Workspace.code-workspace") -and -not (Test-Path "$MyALWorkspaceSourceFolder\$(Split-Path $MyALWorkspaceSourceFolder -Leaf).code-workspace"))
		{
			Write-Warning "Local AL Workspace source folder ""$MyALWorkspaceSourceFolder"" doesn't contain Workspace file (.code-workspace)!" 
		}
	}

	# Get current Git branch
	$GitCurrentBranch = Get-GitCurrentBranch -GitFolder $MyALWorkspaceSourceFolder
}

# Additional display
Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Project name : $ProjectName" -ForegroundColor Cyan
Write-Host "Main local Workspace source folder : $MyWorkspaceSourceFolder" -ForegroundColor Cyan
if ($MyCALWorkspaceSourceFolder -ne "") { Write-Host "CAL local Workspace source folder : $MyCALWorkspaceSourceFolder" -ForegroundColor Cyan }
if ($MyALWorkspaceSourceFolder -ne "") { Write-Host "AL local Workspace source folder : $MyALWorkspaceSourceFolder" -ForegroundColor Cyan }
if ($GitCurrentBranch) { Write-Host "Git current branch : $GitCurrentBranch" -ForegroundColor (Get-GitCurrentBranchColor -GitBranch $GitCurrentBranch -GitBranchesSupported $NAVContainerGitBranches) }
if ($ProjectTargetLanguage -ne "AL") { Write-Host "Branch name : $BranchName" -ForegroundColor Cyan }
Write-Host "NAV Dev license : $MyLicenseFile" -ForegroundColor Cyan
Write-Host "NAV Docker container name : $NAVContainerName" -ForegroundColor Cyan
if ($NAVContainerArtifact -eq "") {
	Write-Host "NAV Docker container image version : $NAVContainerImageName" -ForegroundColor Cyan
} else {
	Write-Host "NAV Docker container artifact : $NAVContainerArtifact" -ForegroundColor Cyan
}

Write-Host "NAV Docker container authentication mode : $Auth" -ForegroundColor Cyan
Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Cyan
[void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')
Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Cyan
$ReadHost = $false

# Test Git branches supported
if ($GitCurrentBranch -and (Get-GitCurrentBranchColor -GitBranch $GitCurrentBranch -GitBranchesSupported $NAVContainerGitBranches) -eq "Red")
{
	Write-Error "Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container."
}

# Tests administrator mode
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
	[void](Read-Host 'Press [Enter] to exit...')
    Break
}

# Test NAV Windows client installed
if ([int]$NAVVersionFolder -le [int]"140")
{
	$NAVWindowsClientInstalled = $false
	$NAVDefaultApplicationTargetPath = "C:\Program Files (x86)\$NAVProductName\$NAVVersionFolder"
	$NAVDefaultApplicationPath = "$NAVDefaultApplicationTargetPath\RoleTailored Client"
	$NAVDefaultApplicationFile = "$NAVDefaultApplicationPath\Microsoft.Dynamics.Nav.Client.exe"
	if (Test-Path $NAVDefaultApplicationFile)
	{
		$NAVVersionInstalled = (get-item $NAVDefaultApplicationFile).VersionInfo.FileVersion
		if ($NAVVersionInstalled -ne "$NAVVersion.0")
		{
			$NAVWindowsClientInstalled = $false
			Write-Warning "NAV Windows client is already installed but the version ($NAVVersionInstalled) is different (required $NAVVersion.0). Do you want to update it (download 1GB and install) ?"
		}
		else
		{
			$NAVWindowsClientInstalled = $true
		}
	} else
	{
		$NAVWindowsClientInstalled = $false
		Write-Warning "NAV Windows client ($NAVVersion) is not installed. Do you want to download and install it (required for Reports and Office integration) ?"
	}
	$ConfirmInstallNAVWindowsClient = "N"
	if (!$NAVWindowsClientInstalled)
	{
		$ConfirmInstallNAVWindowsClient = Read-Host "[Y/N] ?"
		$ReadHost = $true
	}
}

# Start Installs
if ($ReadHost) { Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Cyan }
$StartTime = (Get-Date)
try
{
	# Download and install/upgrade NAV Windows Client
	if ([int]$NAVVersionFolder -le [int]"140")
	{
		$NAVApplicationTargetPath = $env:ProgramData + "\NavContainerHelper\Extensions\$NAVContainerName\Program Files\$NAVVersionFolder"
		$NAVApplicationPath = "$NAVApplicationTargetPath\RoleTailored Client"
		if ($ConfirmInstallNAVWindowsClient -eq "Y")
		{
			Write-Host "Installing / upgrading NAV Windows Client"
			Invoke-NAVDownloadAndInstallWindowsClient `
				-NAVDownloadUrl $NAVDownloadUrl `
				-NAVDVDName $NAVDVDName `
				-NAVVersion $NAVVersion `
				-NAVLocalization $NAVLocalization `
				-NAVProductName $NAVProductName `
				-NAVVersionFolder $NAVVersionFolder `
				-NAVApplicationTargetPath $NAVApplicationTargetPath
		}
	}

	# Set paths
	$DesktopPath = [Environment]::GetFolderPath("Desktop")
	$AssetsPath = $env:ProgramData + "\NavSourcesHelper\$env:USERNAME\$ProjectName\Assets"
	$ShortcutsPath = $env:ProgramData + "\NavSourcesHelper\$env:USERNAME\$ProjectName\Shortcuts"
	$ScriptsContainerPath = $env:ProgramData + "\NavSourcesHelper\Containers\$NAVContainerName\Scripts"
	$ContainerSharedFolder = "C:\ProgramData\NavContainerHelper\Extensions\$NAVContainerName\my\$NAVContainerName SharedFolder"

	# Remove old scripts folder
	$OldScriptsContainerPath = $env:ProgramData + "\NavSourcesHelper\$env:USERNAME\$ProjectName\$NAVContainerName\Scripts"
	if (Test-Path $OldScriptsContainerPath) 
	{ 
		Get-ChildItem -Path $OldScriptsContainerPath -Recurse | Remove-Item -force -recurse 
		Remove-Item $OldScriptsContainerPath -Force 
	}
	
	# Create NAV dev container
	if ($ConfirmCreateNAVContainer -eq "Y")
	{
		# Set credential
		if ($Auth -eq "Windows") {
			$Credential = get-credential -UserName $env:USERNAME -Message "Container Windows Authentication. Please enter your Windows account password."
			if (!(Test-Path $AssetsPath)) { $null = New-Item $AssetsPath -ItemType Directory -Force } 
			$Credential | Export-CliXml -Path "$AssetsPath\Credential.xml"
			$SQLUser = ""
			$SQLPassword = ""
		} else {
			$SQLUser = "sa"
			if ($SQLPassword -eq "")
			{
				$Credential = get-credential -UserName $SQLUser -Message "Container UserPassword Authentication. Please enter new password for $SQLUser."
			}
			else
			{
				$Credential = (New-Object System.Management.Automation.PSCredential ($SQLUser, (ConvertTo-SecureString $SQLPassword -AsPlainText -Force)))
			}
			if (!(Test-Path $AssetsPath)) { $null = New-Item $AssetsPath -ItemType Directory -Force } 
			$Credential | Export-CliXml -Path "$AssetsPath\Credential.xml"
			$SQLPassword = [System.Net.NetworkCredential]::new("", $Credential.Password).Password 
		}
		# Create container
		Create-NavContainer -ContainerName $NAVContainerName -ContainerImageName $NAVContainerImageName -Auth $Auth -Credential $Credential -LicenseFile $MyLicenseFile -WorkspaceSourceFolder $MyWorkspaceSourceFolder -BranchName $BranchName -NAVVersionFolder $NAVVersionFolder -ProjectTargetLanguage $ProjectTargetLanguage -BuildBaseline $BuildBaseline -MemoryLimit $NAVContainerMemoryLimitGB -AppProjectFolder $MyALWorkspaceSourceFolder -AlwaysPull -LicenseType $NAVContainerLicenseType -ContainerArtifact $NAVContainerArtifact -ContainerArtifactToken $NAVContainerArtifactToken

		if ($ProjectTargetLanguage -ne "CAL")
		{
			# Clean AL temp folders
			Write-Host "Clean AL temp folders (.output, .alpackages, .alcache, .altemplates, .unpublished)"
			Get-ChildItem "$MyALWorkspaceSourceFolder\*" -Recurse | ForEach-Object { 
				if ((Split-Path (Split-Path $_.FullName -Parent) -Leaf) -eq ".output") { Remove-Item $_.FullName -Force } 
				if ((Split-Path (Split-Path $_.FullName -Parent) -Leaf) -eq ".alpackages") { Remove-Item $_.FullName -Force } 
				if ((Split-Path (Split-Path $_.FullName -Parent) -Leaf) -eq ".alcache") { Remove-Item $_.FullName -Force } 
				if ((Split-Path (Split-Path $_.FullName -Parent) -Leaf) -eq ".altemplates") { Remove-Item $_.FullName -Force } 
				if ((Split-Path (Split-Path $_.FullName -Parent) -Leaf) -eq ".unpublished") { Remove-Item $_.FullName -Force } 
			}
		}
	}
	else
	{
		# Get container credentials
		if ($Auth -eq "UserPassword") 
		{
			if (Test-Path "$AssetsPath\Credential.xml") { $Credential = Import-CliXml -Path "$AssetsPath\Credential.xml" } else { $Credential = get-credential -UserName $SQLUser -Message "Container UserPassword Authentication. Please enter existing paswword for $SQLUser." }
			$SQLUser = "sa"
			$SQLPassword = [System.Net.NetworkCredential]::new("", $Credential.Password).Password 
		}
		else
		{
			$SQLUser = ""
			$SQLPassword = ""
		}

		# Update license in container
		Write-Host "Update license in container $NAVContainerName"
		Import-NavContainerLicense -ContainerName $NAVContainerName -licenseFile $MyLicenseFile
	}
	# Create container shared folder
	if (!(Test-Path $ContainerSharedFolder)) { $null = New-Item $ContainerSharedFolder -ItemType Directory -Force }
	Write-Host "Create container shared folder $ContainerSharedFolder (path inside container is c:\run\my\$NAVContainerName SharedFolder)"

	# Copy container service tier add-ins to local client folder
	if ([int]$NAVVersionFolder -le [int]"140")
	{
		Write-Host "Copying container service tier add-ins to client folder..."
		$ContainerId = Get-NavContainerId -containerName $NAVContainerName
		$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
		$SourcePath = "C:\navdvd\ServiceTier\Program Files\Microsoft Dynamics NAV\$NAVVersionFolder\Service\Add-ins"
		if (Invoke-Command -ArgumentList $SourcePath -ScriptBlock {param($SourcePath)Test-Path $SourcePath} -Session $Session)
		{
			Copy-Item "$SourcePath\*" -Destination "C:\ProgramData\NavContainerHelper\Extensions\$NAVContainerName\Program Files\$NAVVersionFolder\RoleTailored Client\Add-ins" -FromSession $Session -Force -Recurse
		}
		else 
		{
			$SourcePath = "C:\Program Files\Microsoft Dynamics NAV\$NAVVersionFolder\Service\Add-ins"
			if (Invoke-Command -ArgumentList $SourcePath -ScriptBlock {param($SourcePath)Test-Path $SourcePath} -Session $Session)
			{
				Copy-Item "$SourcePath\*" -Destination "C:\ProgramData\NavContainerHelper\Extensions\$NAVContainerName\Program Files\$NAVVersionFolder\RoleTailored Client\Add-ins" -FromSession $Session -Force -Recurse
			}
			else
			{
				Write-Warning "Container service tier add-ins folder not found! Add-ins not copied to client folder. Some issues can occur with compilation of objects/files referencing add-ins..."
			}
		}
		Remove-PSSession $Session
	}

	if ($ProjectTargetLanguage -ne "CAL")
	{
		# Copy Baseline Add-Ins to container service tier add-ins folder
		Write-Host "Copying Baseline Add-Ins to container service tier add-ins folder..."
		$ContainerId = Get-NavContainerId -containerName $NAVContainerName
		$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
		if (Test-Path "$MyALWorkspaceSourceFolder\Baseline\Add-Ins\*") { Copy-Item "$MyALWorkspaceSourceFolder\Baseline\Add-Ins\*" -Destination "C:\Program Files\Microsoft Dynamics NAV\$NAVVersionFolder\Service\Add-ins" -ToSession $Session -Force -Recurse -ErrorAction SilentlyContinue }
		Remove-PSSession $Session
		
		# Get Base App source in container if exist Base folder and is empty
		if ((Test-Path "$MyALWorkspaceSourceFolder\base") -and -not (Test-Path "$MyALWorkspaceSourceFolder\base\*"))
		{
			Get-NavContainerBaseAppSource -ContainerName $NAVContainerName -BaseAppProjectFolder "$MyALWorkspaceSourceFolder\base" -User $SQLUser -Password $SQLPassword -Clean
		}

		# Create / Update Workspace.code-workspace
		if (Test-Path "$MyALWorkspaceSourceFolder\Workspace.code-workspace")
		{ 
			Write-Host "Rename Workspace.code-workspace to $(Split-Path $MyALWorkspaceSourceFolder -Leaf).code-workspace"
			Rename-Item "$MyALWorkspaceSourceFolder\Workspace.code-workspace" -NewName "$MyALWorkspaceSourceFolder\$(Split-Path $MyALWorkspaceSourceFolder -Leaf).code-workspace" -Force 
		}

		# Create / Update launch.json
		Create-LaunchJson -ProjectFolder $MyALWorkspaceSourceFolder
		$NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $NAVContainerName
		Update-LaunchJson -Name $NAVContainerName -Server "http://$NAVContainerName" -Port $NavContainerServerConfiguration.DeveloperServicesPort -ServerInstance $NavContainerServerConfiguration.ServerInstance -Auth $Auth -ProjectFolder $MyALWorkspaceSourceFolder -NAVVersionFolder $NAVVersionFolder

		# Create settings.json
		Create-SettingsJson -ProjectFolder $MyALWorkspaceSourceFolder -ContainerName $NAVContainerName

	}
	
	# Create scripts to NavSourcesHelper folder
	Create-NAVDevScripts -ProjectName $ProjectName `
		-ShortcutsPath $ShortcutsPath `
	    -IconsPath $AssetsPath `
	    -ScriptsContainerPath $ScriptsContainerPath `
		-NAVContainerName $NAVContainerName `
	    -NAVDatabaseName (Get-NAVContainerDatabaseName($NAVContainerName)) `
	    -BranchName $BranchName `
		-MyWorkspaceSourceFolder $MyWorkspaceSourceFolder `
	    -NAVApplicationPath $NAVApplicationPath `
		-NAVVersionFolder $NAVVersionFolder `
	    -NavServerServiceFolder $NAVContainerName `
	    -ProjectTrigram $ProjectTrigram `
	    -DockerContainer `
		-ProjectObjectsRangeId $ProjectObjectsRangeId `
		-ProjectVersion $ProjectVersion `
		-ProjectObjectsToIgnore $ProjectObjectsToIgnore `
		-ProjectTargetLanguage $ProjectTargetLanguage `
		-SQLUser $SQLUser `
		-SQLPassword $SQLPassword `
		-AppProjectFolder $MyALWorkspaceSourceFolder `
	    -ProjectType $ProjectType `
		-ProjectObjectsRangeToIgnore $ProjectObjectsRangeToIgnore `
		-ProjectObjectsShortDateFormat $ProjectObjectsShortDateFormat `
		-ProjectObjectsDecimalSeparator $ProjectObjectsDecimalSeparator `
		-ProjectAppsBaseAppDependencyAppIdsToNotRepublish $ProjectAppsBaseAppDependencyAppIdsToNotRepublish `
		-NAVContainerGitBranches $NAVContainerGitBranches

	# Create project shortcuts
	Create-NAVProjectShortcuts -ProjectName $ProjectName `
	    -DesktopPath $DesktopPath `
		-ShortcutsPath $ShortcutsPath `
	    -IconsPath $AssetsPath `
		-VSTSUrl $VSTSUrl `
		-SharePointUrl $SharePointUrl `
		-SharePointObjectMgtUrl $SharePointObjectMgtUrl `
		-SharePointEnvironmentMgtUrl $SharePointEnvironmentMgtUrl `
		-HostedDns $HostedDns `
		-HostedEnvironmentList $HostedEnvironmentList `
		-NAVApplicationPath $NAVApplicationPath `
		-ProjectSubName $ProjectSubName `
	    -NAVVersionFolder $NAVVersionFolder

	# Create development shortcuts
	Create-NAVDevShortcuts -ProjectName $ProjectName `
		-ShortcutsPath $ShortcutsPath `
	    -IconsPath $AssetsPath `
	    -ScriptsContainerPath $ScriptsContainerPath `
		-NAVContainerName $NAVContainerName `
		-BranchName $BranchName `
		-NAVApplicationPath $NAVApplicationPath `
	    -NAVServerInstanceName $NAVContainerName `
	    -CodingRulesUrl $CodingRulesUrl `
		-DockerContainer `
		-ProjectSubName $ProjectSubName `
		-ProjectTargetLanguage $ProjectTargetLanguage `
		-AppProjectFolder $MyALWorkspaceSourceFolder `
		-NAVVersionFolder $NAVVersionFolder `
		-ContainerSharedFolder $ContainerSharedFolder `
		-NAVProductName $NAVProductName

	# Dev container scripts
	$ContainerId = Get-NavContainerId -containerName $NAVContainerName
	$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
	foreach($Script in $Xml.Configuration.DevContainerCopyScripts.DevContainerCopyScript)
	{
		# Replace params values
        $ArgumentList = ""
        $Source = $Script.Source
		$Destination = $Script.Destination
        if ($Source -ne $null -and $Source -ne "")
        {
			$Source = $Source.Replace("$" + "AssetsPath",$AssetsPath)
			$Source = $Source.Replace("$" + "BaselinePath","$MyALWorkspaceSourceFolder\Baseline")
        }

        # Run script
        Write-Host ("Execute container copy " + $Script.Id + " (" + $Source +" to $Destination)")
		# Create folder if not exists
		Invoke-Command -Session $Session -argumentList $Destination -scriptblock {
			param($Destination)
			if (-not (Test-path (Split-Path $Destination)))
			{
				New-item (Split-Path $Destination) -ItemType Directory -Force | Out-Null
			}
		}
		# Copy Item
		if (Test-Path $Source) { $null = Copy-Item $Source -Destination $Destination -ToSession $Session }
	}
	foreach($Script in $Xml.Configuration.DevContainerInstallScripts.DevContainerInstallScript)
	{
		# Replace params values
        $ArgumentList = @()
        $Params = $Script.Params
        if ($Params -ne $null -and $Params -ne "")
        {
			$Params = $Params.Replace("$" + "AssetsPath",$AssetsPath)
			$Params = $Params.Split(";")
            foreach($Param in $Params) { $ArgumentList += $Param }
        }

        # Run script
        Write-Host ("Execute container script " + $Script.Id + " (" + $Script.Value +")")
		$Command = "$PSScriptRoot\$($Script.Value)"
		Write-Host "Command= $Command"
		$null = Invoke-Command -Session $Session -ArgumentList $ArgumentList -FilePath $Command
	}
	Remove-PSSession $Session

	# Dev local install scripts
	foreach($Script in $Xml.Configuration.DevLocalInstallScripts.DevLocalInstallScript)
	{
		# Replace params values
        $ArgumentList = ""
        $Params = $Script.Params
        if ($Params -ne $null -and $Params -ne "")
        {
			$Params = $Params.Replace("$" + "AssetsPath",$AssetsPath)
			$Params = $Params.Replace("$" + "ContainerName",$NAVContainerName)
			$Params = $Params.Replace("$" + "BranchName",$BranchName)
			$Params = $Params.Replace("$" + "BaselinePath","$MyALWorkspaceSourceFolder\Baseline")
			$Params = $Params.Replace("$" + "ShortcutsPath","$ShortcutsPath")
			$Params = $Params.Split(";")
            foreach($Param in $Params) { $ArgumentList += " '" + $Param + "'" }
        }

        # Run script
        Write-Host ("Execute local script " + $Script.Id + " (" + $Script.Value +")")
		$Command = "& '$PSScriptRoot\" + $Script.Value + "' " + $ArgumentList
		Write-Host "Command= $Command"
        $null = Invoke-Expression ($Command) 
	}


	# Open project folder shortcuts
	start "$DesktopPath\$ProjectName.lnk"
	
	# End
	$Elapsed = (Get-Date)-$StartTime
	Write-Host "Create/Update local NAV development environment (Docker container) completed succesfully in $([math]::Round($Elapsed.TotalSeconds)) seconds." -ForegroundColor Green
}
catch
{
    Write-Host $_.Exception.Message -Foreground Red
    Write-Host $_.InvocationInfo.PositionMessage -Foreground Red
}
[void](Read-Host 'Press [Enter] to exit...')
