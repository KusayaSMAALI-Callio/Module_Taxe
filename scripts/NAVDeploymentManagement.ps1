<#///
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : 3Li Business Solutions
Description  : Functions for NAV workstation deployment management
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies :
------------------------------------------------------------------------------------------------------------------
Revisions    : 30/07/2018 : PMN : Initial version
               25/11/2018 : PMN : Refactoring scripts
			   04/12/2018 : PMN : Add support for remote NAV Server
			   09/12/2018 : PMN : Add environment management Url and shortcut
			   17/12/2018 : PMN : Update to D365BC
   			   09/01/2019 : PMN : Update to edition projects
			   27/01/2019 : PMN : Update to edition projects
			   10/09/2019 : PMN : Update to new NavContainerHelper debug shortcut
			   08/10/2019 : PMN : Add ProjectObjectsToIgnore
			   08/10/2019 : PMN : Update for AL projects and BC v15
			   09/10/2019 : PMN : Rename NAVCodeManagement to NAVCALCodeManagement, add NAVDockerContainerManagement
			   09/10/2019 : PMN : Fix Get-VS2017HigherEditionInstalled
			   09/10/2019 : PMN : Update launch.json
			   09/10/2019 : PMN : Add scripts Sync-NavContainerTenant and Generate-NavContainerSymbolReference
			   09/10/2019 : PMN : Add authentication mode UserPassword for containers
			   10/10/2019 : PMN : Add BC icons (old and new), add debug icon
			   10/10/2019 : PMN : Change url of NavContainerHelper online help
			   28/10/2019 : PMN : Update to new NavContainerHelper Test Tool shortcut
			   13/11/2019 : PMN : Adaptations for Base App
			   14/11/2019 : PMN : Fix Create-NAVDevScripts and Create-NAVDevShortcuts folder for CAL projects
			   21/11/2019 : PMN : Add Script and task for NAVCreateDevEnv-DockerContainer
			   23/11/2019 : PMN : Add param $ProjectType to Create-NAVDevScripts
			   04/12/2019 : PMN : Invoke-NAVDownloadAndInstallWindowsClient fix update NAV Windows client path
			   04/12/2019 : PMN : Fix Sync-NavContainerTenant (CheckOnly then ForceSYnc after confirmation)
			   04/12/2019 : PMN : Fix run from CSIDE with NavUserPassword (Modify CSIDE shortcut to launch PowerShell script for ClientUserSettings context management)
               17/12/2019 : PMN : Fix NAVVersionFolder conversion to int
			   15/01/2020 : PMN : Add ProjectObjectsRangeToIgnore
			   15/01/2020 : PMN : Add NAVDownloadUrl management from local or network folder (Unc) 
			   16/01/2020 : PMN : Update al.assemblyProbingPaths with "..\Baseline\Add-Ins"
			   17/01/2020 : PMN : Export-ModifiedObjects : Fix display result
			   19/01/2020 : PMN : Add ClientServicePort management in HostedEnvironmentList, and Deployment summary html page in HostedDns
			   28/01/2020 : PMN : Add ProjectObjectsShortDateFormat and ProjectObjectsDecimalSeparator management
			   29/01/2020 : PMN : Add container shared folder
			   #10593 : 31/01/2020 : PMN : Fix bug container shared folder
			   #10735 : 02/03/2020 : PMN : Fix bug VS Code task Restart-NAVContainer (for projects with subfolder)
               #11403 : 16/03/2020 : PMN : Doesn't create "Tests et intégration (hébergés,distants)" folder if params are empty
			   #11011 : 16/03/2020 : PMN : Add Compile objects script and shortcut
			   #11677 : 31/03/2020 : PMN : Adaptations for BaseApp (especially for CMC BC15)
                                           - Add param ProjectAppsBaseAppDependencyAppIdsToNotRepublish for not republish some MS Apps (especialy for AMC Banking not compatible with CMC BC15 BaseApp (DataPerCompany property modified))
               #12633 : 19/05/2020 : PMN : Add Git multibranching management
			   #14504 : 31/07/2020 : PMN : Fix settings.json for BaseApp (add "C:/Windows/Microsoft.NET/assembly" in al.assemblyProbingPath and add "CRS.OnSaveAlFileAction": "DoNothing")
			   #14496 : 03/08/2020 : PMN : Add NAVUpdateDevEnv-DockerContainer shortcut and VS Code task
			   #137 : 26/08/2020 : PMN : Dev CAL : Fix Create-NAVDevShortcuts for CheckCodingRules and fix old shortcuts not removed
			   #256 : 12/11/2020 : PMN : Fix encoding issue with PowerShell (remove accents in folder and file names)
			   #255 : 12/11/2020 : PMN : BcContainerHelper migration preparation
------------------------------------------------------------------------------------------------------------------
#>

Function Create-NAVProjectShortcuts
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$DesktopPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ShortcutsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$IconsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$VSTSUrl,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$SharePointUrl="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$SharePointObjectMgtUrl="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$SharePointEnvironmentMgtUrl="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$HostedDns="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$HostedEnvironmentList="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVApplicationPath,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectSubName="",
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVVersionFolder=""
    )

	# Create project folder 
	Write-Host "Creating Desktop shortcuts for $ProjectName"
	$DesktopContainerPath = $ShortcutsPath
	$null = New-Item $DesktopContainerPath -ItemType Directory -Force

	# Create new project shortcuts
	$Shell = New-Object -ComObject ("WScript.Shell")
	$ShortCutFile = "$DesktopPath\$ProjectName.lnk"
	$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
	$ShortCut.TargetPath = "$ShortcutsPath"
	$ShortCut.Arguments = ""
	$ShortCut.WorkingDirectory = "$ShortcutsPath\"
	$ShortCut.WindowStyle = 1
	$ShortCut.Save()

	# Create DevOps shortcut
	$Shell = New-Object -ComObject ("WScript.Shell")
	if (Test-Path "$DesktopContainerPath\VSTS $ProjectName.lnk") { Remove-Item "$DesktopContainerPath\VSTS $ProjectName.lnk"}
	if (Test-Path "$DesktopContainerPath\VSTS $ProjectName.url") { Remove-Item "$DesktopContainerPath\VSTS $ProjectName.url"}
	$ShortCutFile = "$DesktopContainerPath\DevOps $ProjectName.url"
	$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
	$ShortCut.TargetPath = $VSTSUrl
	#$ShortCut.IconLocation = "$IconsPath\VSTS.ico"
	$ShortCut.Save()

	# Create SharePoint shortcut
	if (Test-Path "$DesktopContainerPath\SharePoint $ProjectName.lnk") { Remove-Item "$DesktopContainerPath\SharePoint $ProjectName.lnk"}
	if ($SharePointUrl -ne "")
	{
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\SharePoint $ProjectName.url"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = $SharePointUrl
		#$ShortCut.IconLocation = "$IconsPath\SharePoint.ico"
		$ShortCut.Save()
	}

	# Create "Developpements - Suivi objets" shortcut
	if (Test-Path $DesktopContainerPath) { Get-ChildItem "$DesktopContainerPath\D*veloppements - Suivi objets $ProjectName.*" | Remove-Item -Force }
	if ($SharePointObjectMgtUrl -ne "")
	{
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\Developpements - Suivi objets $ProjectName.url"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = $SharePointObjectMgtUrl
		#$ShortCut.IconLocation = "$IconsPath\SharePoint.ico"
		$ShortCut.Save()
	}

	# Create "Environnements - Suivi builds,releases,deploiements" shortcut
	if (Test-Path $DesktopContainerPath) { Get-ChildItem "Environnements - Suivi builds,releases,d*ploiements $ProjectName.*" | Remove-Item -Force }
	if ($SharePointEnvironmentMgtUrl -ne "")
	{
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\Environnements - Suivi builds,releases,deploiements $ProjectName.url"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = $SharePointEnvironmentMgtUrl
		#$ShortCut.IconLocation = "$IconsPath\SharePoint.ico"
		$ShortCut.Save()
	}

	# Create Normes de developpement NAV et D365BC shortcut 
	if (Test-Path $DesktopContainerPath) { Get-ChildItem "$DesktopContainerPath\Normes de d*veloppement *.*" | Remove-Item -Force }
	$Shell = New-Object -ComObject ("WScript.Shell")
	$ShortCutFile = "$DesktopContainerPath\Normes de developpement NAV et Business Central.url"
	$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
	$ShortCut.TargetPath = $CodingRulesUrl
	#$ShortCut.IconLocation = "$IconsPath\Rules.ico"
	$ShortCut.Save()

	# Create "Tests et integration (heberges,distants)" project folder on Desktop
	$DesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Tests et int*gration (h*berg*s,distants)"
	if (Test-Path $DesktopContainerPath) 
	{ 
		Get-ChildItem -Path $DesktopContainerPath -Recurse | Remove-Item -force -recurse 
	}
	$DesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Tests et integration (heberges,distants)"
	if (Test-Path $DesktopContainerPath) 
	{ 
		Get-ChildItem -Path $DesktopContainerPath -Recurse | Remove-Item -force -recurse 
		Remove-Item $DesktopContainerPath -Force 
	}

	if ($HostedDns -ne "" -and $HostedEnvironmentList -ne "")
	{
		$null = New-Item $DesktopContainerPath -ItemType Directory -Force

		$DeploymentSummaryHtmlPage = ""
		if ($HostedDns.Split(",")[1]) { $DeploymentSummaryHtmlPage = "/$($HostedDns.Split(",")[1])" }
		$HostedDns = $HostedDns.Split(",")[0]

		if ($HostedEnvironmentList -ne "")
		{
			$NAVEnvironments = $HostedEnvironmentList.Split(",")
			$ClientServicesPort = 7146
			foreach ($NAVEnvironment in $NAVEnvironments)
			{
				if ($NAVEnvironment.Split(":")[1]) { $ClientServicesPort = [int]$NAVEnvironment.Split(":")[1] }
				$NAVEnvironment = $NAVEnvironment.Split(":")[0]
				if ([int]$NAVVersionFolder -le [int]"140")
				{
					# Create ClientUserSettings.config (NavUserPassword)
					Write-Host "Creating ClientUserSettings.config and shortcuts for $NAVEnvironment (NavUserPassword)"
					$SourceFile = "$NAVApplicationPath\ClientUserSettings-$NAVEnvironment.config"
					$Script = "<?xml version=""1.0"" encoding=""utf-8""?>
					<configuration>
					  <appSettings>
						<add key=""Server"" value=""$HostedDns"" />
						<add key=""ClientServicesPort"" value=""$ClientServicesPort"" />
						<add key=""ServerInstance"" value=""$NAVEnvironment"" />
						<add key=""TenantId"" value="""" />
						<add key=""ClientServicesProtectionLevel"" value=""EncryptAndSign"" />
						<add key=""UrlHistory"" value="""" />
						<add key=""ClientServicesCompressionThreshold"" value=""64"" />
						<add key=""ClientServicesChunkSize"" value=""28"" />
						<add key=""MaxNoOfXMLRecordsToSend"" value=""5000"" />
						<add key=""MaxImageSize"" value=""26214400"" />
						<add key=""ClientServicesCredentialType"" value=""NavUserPassword"" />
						<add key=""ACSUri"" value="""" />
						<add key=""AllowNtlm"" value=""true"" />
						<add key=""ServicePrincipalNameRequired"" value=""False"" />
						<add key=""ServicesCertificateValidationEnabled"" value=""true"" />
						<add key=""DnsIdentity"" value=""3li.com"" />
						<add key=""HelpServer"" value="""" />
						<add key=""HelpServerPort"" value=""49000"" />
						<add key=""ProductName"" value="""" />
						<add key=""UnknownSpnHint"" value="""" />
					  </appSettings>
					</configuration>
					"
					Set-Content -Path $SourceFile -Value $Script -Force

					# Create Windows client Shortcut (NavUserPassword)
					$Shell = New-Object -ComObject ("WScript.Shell")
					$ShortCutFile = "$DesktopContainerPath\$NAVEnvironment (Public) Windows Client.lnk"
					$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
					$ShortCut.TargetPath = "$NAVApplicationPath\Microsoft.Dynamics.Nav.Client.exe"
					$ShortCut.Arguments = "-settings:ClientUserSettings-$NAVEnvironment.config"
					$ShortCut.WorkingDirectory = "$NAVApplicationPath\"
					$ShortCut.WindowStyle = 1
					$ShortCut.Save()
				}

				# Create Web client shortut (NavUserPassword)
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCutFile = "$DesktopContainerPath\$NAVEnvironment (Public) Web Client.lnk"
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				$ShortCut.TargetPath = "https://$HostedDns/$NAVEnvironment"
				$ShortCut.Arguments = ""
				$ShortCut.WorkingDirectory = ""
				$ShortCut.WindowStyle = 1
				if ([int]$NAVVersionFolder -le [int]"110") { $ShortCut.IconLocation = "$IconsPath\NavWeb.ico" }
				elseif ([int]$NAVVersionFolder -le [int]"140") { $ShortCut.IconLocation = "$IconsPath\BCOld.ico" }
				else { $ShortCut.IconLocation = "$IconsPath\BCNew.ico" }
				$ShortCut.Save()

				if ([int]$NAVVersionFolder -le [int]"140")
				{
					# Create ClientUserSettings.config (Office 365)
					Write-Host "Creating ClientUserSettings.config and shortcuts for $NAVEnvironment (Office 365)"
					$SourceFile = "$NAVApplicationPath\ClientUserSettings-$NAVEnvironment-O365.config"
					$Script = "<?xml version=""1.0"" encoding=""utf-8""?>
					<configuration>
					  <appSettings>
						<add key=""Server"" value=""$HostedDns"" />
						<add key=""ClientServicesPort"" value=""$ClientServicesPort"" />
						<add key=""ServerInstance"" value=""$NAVEnvironment"" />
						<add key=""TenantId"" value="""" />
						<add key=""ClientServicesProtectionLevel"" value=""EncryptAndSign"" />
						<add key=""UrlHistory"" value="""" />
						<add key=""ClientServicesCompressionThreshold"" value=""64"" />
						<add key=""ClientServicesChunkSize"" value=""28"" />
						<add key=""MaxNoOfXMLRecordsToSend"" value=""5000"" />
						<add key=""MaxImageSize"" value=""26214400"" />
						<add key=""ClientServicesCredentialType"" value=""AccessControlService"" />
						<add key=""ACSUri"" value=""https://login.windows.net/3lionline.onmicrosoft.com/wsfed?wa=wsignin1.0%26wtrealm=https://integration.3li.com/DynamicsNav%26wreply=https://$HostedDns"" />
						<add key=""AllowNtlm"" value=""true"" />
						<add key=""ServicePrincipalNameRequired"" value=""False"" />
						<add key=""ServicesCertificateValidationEnabled"" value=""true"" />
						<add key=""DnsIdentity"" value=""3li.com"" />
						<add key=""HelpServer"" value="""" />
						<add key=""HelpServerPort"" value=""49000"" />
						<add key=""ProductName"" value="""" />
						<add key=""UnknownSpnHint"" value="""" />
					  </appSettings>
					</configuration>
					"
					Set-Content -Path $SourceFile -Value $Script -Force

					# Create Windows client Shortcut (Office 365)
					$Shell = New-Object -ComObject ("WScript.Shell")
					$ShortCutFile = "$DesktopContainerPath\$NAVEnvironment (Public O365) Windows Client.lnk"
					$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
					$ShortCut.TargetPath = "$NAVApplicationPath\Microsoft.Dynamics.Nav.Client.exe"
					$ShortCut.Arguments = "-settings:ClientUserSettings-$NAVEnvironment-O365.config"
					$ShortCut.WorkingDirectory = "$NAVApplicationPath\"
					$ShortCut.WindowStyle = 1
					$ShortCut.Save()
				}

				# Create Web client shortut (Office 365)
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCutFile = "$DesktopContainerPath\$NAVEnvironment (Public O365) Web Client.lnk"
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				$ShortCut.TargetPath = "https://$HostedDns/$NAVEnvironment-O365"
				$ShortCut.Arguments = ""
				$ShortCut.WorkingDirectory = ""
				$ShortCut.WindowStyle = 1
				if ([int]$NAVVersionFolder -le [int]"110") { $ShortCut.IconLocation = "$IconsPath\NavWeb.ico" }
				elseif ([int]$NAVVersionFolder -le [int]"140") { $ShortCut.IconLocation = "$IconsPath\BCOld.ico" }
				else { $ShortCut.IconLocation = "$IconsPath\BCNew.ico" }
				$ShortCut.Save()

				# Next environment
				$ClientServicesPort += 200
			}
		}
	}

	# Create "Compte rendu de deploiement" shortcut
	if (Test-Path $DesktopContainerPath) { Get-ChildItem "$DesktopContainerPath\Compte rendu de d*ploiement.*" | Remove-Item -Force }
	if ($HostedDns -ne "")
	{
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\Compte rendu de deploiement.url"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "http://$HostedDns$DeploymentSummaryHtmlPage"
		#$ShortCut.IconLocation = "$IconsPath\SharePoint.ico"
		$ShortCut.Save()
	}
}

Function Invoke-NAVDownloadAndInstallWindowsClient
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVDownloadUrl,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVDVDName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVVersion,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVProductName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVVersionFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVLocalization,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVApplicationTargetPath,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$NoInstall
	)
	
	# Create temp folder
	$NAVTempFolder = "C:\Temp\Install"
	$null = New-Item -Path $NAVTempFolder -ItemType directory -Force
	
	# Download NAV Install
	if (-not (Test-Path "$NAVTempFolder\$NAVDVDName\setup.exe"))
	{
		if ($NAVDownloadUrl.StartsWith("http"))
		{
			# Download NAV Install from Internet (Url)
			$NAVDownloadFile = "$NAVTempFolder\NAV.$NAVVersion.$NAVLocalization.zip"
			Write-Host "Downloading $NavDownloadFile"
			Invoke-WebRequest -Uri $NAVDownloadUrl -OutFile $NAVDownloadFile
	
			# Unzip and remove file download
			Write-Host "Extracting $NavDownloadFile"
			Expand-Archive -Path $NavDownloadFile -DestinationPath "$NAVTempFolder" -Force
			Remove-Item $NavDownloadFile -Force
			Remove-Item "$NAVTempFolder\APPLICATION" -Force -Recurse

			# Unzip DVD
			Write-Host "Extracting $NAVTempFolder\$NAVDVDName.zip"
			Expand-Archive -Path "$NAVTempFolder\$NAVDVDName.zip" -DestinationPath "$NAVTempFolder\$NAVDVDName" -Force
			Remove-Item "$NAVTempFolder\$NAVDVDName.zip" -Force
		}
		else
		{
			if ((Test-Path $NAVDownloadUrl))
			{
				# Get NAV Install from local or network folder (Unc)
				if ($NAVDownloadUrl.EndsWith(".zip"))
				{
					# Get zip file
					$NAVDownloadFile = "$NAVTempFolder\NAV.$NAVVersion.$NAVLocalization.zip"
					Write-Host "Downloading $NavDownloadFile"
					Copy-Item -Path $NAVDownloadUrl -Destination $NAVDownloadFile

					# Unzip and remove file download
					Write-Host "Extracting $NavDownloadFile"
					Expand-Archive -Path $NavDownloadFile -DestinationPath "$NAVTempFolder" -Force
					Remove-Item $NavDownloadFile -Force
					Remove-Item "$NAVTempFolder\APPLICATION" -Force -Recurse

					# Unzip DVD
					Write-Host "Extracting $NAVTempFolder\$NAVDVDName.zip"
					Expand-Archive -Path "$NAVTempFolder\$NAVDVDName.zip" -DestinationPath "$NAVTempFolder\$NAVDVDName" -Force
					Remove-Item "$NAVTempFolder\$NAVDVDName.zip" -Force
				}
				else
				{
					Write-Host "Downloading $NAVDownloadUrl"
					$null = Copy-Item "$NAVDownloadUrl\*" `
						-Destination "$NAVTempFolder\$NAVDVDName" `
						-Force `
						-Recurse
				}
			}
			else
			{
				Write-Warning "File or folder ""$NAVDownloadUrl"" not found. Unable to install or upgrade NAV Windows Client !"
			}
		}
	}

	if (-not(Test-Path "C:\Program Files (x86)\$NAVProductName\$NAVVersionFolder\RoleTailored Client\Microsoft.Dynamics.Nav.Client.exe"))
	{
		if (!$NoInstall)
		{
			# Install NAV Windows Client

			# Create NAV install Config File
			$ConfigFile = "$NAVTempFolder\$NAVDVDName\InstallConfig.xml"
			$ConfigXml = "<Configuration>
			  <Component Id=""ClickOnceInstallerTools"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""NavHelpServer"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""WebClient"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""AutomatedDataCaptureSystem"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""OutlookAddIn"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""SQLServerDatabase"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""SQLDemoDatabase"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""ServiceTier"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""Pagetest"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""STOutlookIntegration"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""ServerManager"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""DevelopmentEnvironment"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Component Id=""RoleTailoredClient"" State=""Local"" ShowOptionNode=""yes""/>
			  <Component Id=""ExcelAddin"" State=""Local"" ShowOptionNode=""yes""/>
			  <Component Id=""ClassicClient"" State=""Absent"" ShowOptionNode=""yes""/>
			  <Parameter Id=""TargetPath"" Value=""C:\Program Files (x86)\$NAVProductName\$NAVVersionFolder""/>
			  <Parameter Id=""TargetPathX64"" Value=""[WIX_ProgramFilesX64Folder]\$NAVProductName\$NAVVersionFolder""/>
			  <Parameter Id=""NavServiceServerName"" Value=""$env:COMPUTERNAME""/>
			  <Parameter Id=""NavServiceInstanceName"" Value=""DynamicsNAV$NAVVersionFolder""/>
			  <Parameter Id=""NavServiceAccount"" Value=""[WIX_NetworkServiceAccount]""/>
			  <Parameter Id=""NavServiceAccountPassword"" IsHidden=""yes"" Value=""""/>
			  <Parameter Id=""ServiceCertificateThumbprint"" Value=""""/>
			  <Parameter Id=""ManagementServiceServerPort"" Value=""7045""/>
			  <Parameter Id=""ManagementServiceFirewallOption"" Value=""false""/>
			  <Parameter Id=""NavServiceClientServicesPort"" Value=""7046""/>
			  <Parameter Id=""WebServiceServerPort"" Value=""7047""/>
			  <Parameter Id=""WebServiceServerEnabled"" Value=""false""/>
			  <Parameter Id=""DataServiceServerPort"" Value=""7048""/>
			  <Parameter Id=""DataServiceServerEnabled"" Value=""false""/>
			  <Parameter Id=""DeveloperServiceServerPort"" Value=""7049""/>
			  <Parameter Id=""DeveloperServiceServerEnabled"" Value=""false""/>
			  <Parameter Id=""NavFirewallOption"" Value=""true""/>
			  <Parameter Id=""CredentialTypeOption"" Value=""Windows""/>
			  <Parameter Id=""DnsIdentity"" Value=""""/>
			  <Parameter Id=""ACSUri"" Value=""""/>
			  <Parameter Id=""SQLServer"" Value=""""/>
			  <Parameter Id=""SQLInstanceName"" Value=""""/>
			  <Parameter Id=""SQLDatabaseName"" Value=""""/>
			  <Parameter Id=""SQLReplaceDb"" Value=""FAILINSTALLATION""/>
			  <Parameter Id=""SQLAddLicense"" Value=""true""/>
			  <Parameter Id=""PostponeServerStartup"" Value=""false""/>
			  <Parameter Id=""PublicODataBaseUrl"" Value=""""/>
			  <Parameter Id=""PublicSOAPBaseUrl"" Value=""""/>
			  <Parameter Id=""PublicWebBaseUrl"" Value=""""/>
			  <Parameter Id=""PublicWinBaseUrl"" Value=""""/>
			  <Parameter Id=""WebServerPort"" Value=""8080""/>
			  <Parameter Id=""WebServerSSLCertificateThumbprint"" Value=""""/>
			  <Parameter Id=""WebClientRunDemo"" Value=""true""/>
			  <Parameter Id=""WebClientDependencyBehavior"" Value=""install""/>
			  <Parameter Id=""NavHelpServerPath"" Value=""[WIX_SystemDrive]\Inetpub\wwwroot""/>
			  <Parameter Id=""NavHelpServerName"" Value=""$env:COMPUTERNAME""/>
			  <Parameter Id=""NavHelpServerPort"" Value=""49000""/>
			</Configuration>"
			Set-Content -Path $ConfigFile -Value $ConfigXml -Force

			# Install NAV Windows Client
			$LogFile = "$NAVTempFolder\$NAVDVDName\InstallLog.txt"
			if (Test-Path $LogFile)
			{
				$null = Remove-Item -Path $LogFile -Force
			}

			$Cmd = "$NAVTempFolder\$NAVDVDName\Setup.exe"
			Write-Host "Running NAV Windows Client Install - Check $LogFile for logs..."
			$ExitCode = (Start-Process $Cmd -Wait -ArgumentList "/config $ConfigFile /log $LogFile /quiet" -Passthru).ExitCode

			# Check install
			if (Test-Path $LogFile)
			{
                $PendingReboot = Get-Content $LogFile| Where-Object { $_.Contains("ReturnCode = 3010") }
                $PendingWindowsUpdate = Get-Content $LogFile| Where-Object { $_.Contains("ReturnCode = 5100") }
                $ErrorLog = Get-Content $LogFile| Where-Object { $_.Contains("ERROR: ") }
                if ($ErrorLog -ne $null -and $PendingReboot -ne $null) 
                { 
                    throw "Error : NAV component is not installed ! Reboot computer is required for to complete the installation. Reboot the computer before and restart the installation. Check $LogFile for logs... ($ErrorLog)" 
                }
                else 
                {
                    if ($ErrorLog -ne $null -and $PendingWindowsUpdate -ne $null) 
                    {
                        throw "Error : NAV component is not installed ! Windows version is not up to date. Apply all Windows updates before and restart the installation. Check $LogFile for logs... ($ErrorLog)"
                    }
                    else
                    {
                        if ($ErrorLog -ne $null)
                        {
                            throw "Error : NAV component is not installed ! Check $LogFile for logs... ($ErrorLog)" 
                        }
                    }
}			} else
			{
				throw "Error: NAV not installed."
			}
			if ($ExitCode -ne 0)
			{
				throw "Error in NAV Windows client install - ExitCode = $ExitCode"
			}
			if (-not(Test-Path "C:\Program Files (x86)\$NAVProductName\$NAVVersionFolder\RoleTailored Client\Microsoft.Dynamics.Nav.Client.exe"))
			{
				throw "Error in NAV Windows client install - Microsoft.Dynamics.Nav.Client.exe not found."
			}
		}
	} else
	{
		if (!$NoInstall)
		{
			# Upgrade NAV Windows Client
			Write-Host "Upgrading NAV Windows Client to $NAVVersion"
			$null = Copy-Item "$NAVTempFolder\$NAVDVDName\RoleTailoredClient\program files\Microsoft Dynamics NAV\$NAVVersionFolder\*" `
				-Destination "C:\Program Files (x86)\$NAVProductName\$NAVVersionFolder" `
				-Force `
				-Recurse
		}
	}
	if ($NoInstall)
	{
		# Copy NAV Windows Client
		Write-Host "Copy NAV Windows Client to $NAVApplicationTargetPath\RoleTailored Client"
		if (-not (Test-Path $NAVApplicationTargetPath))
		{
			$null = Copy-Item "$NAVTempFolder\$NAVDVDName\RoleTailoredClient\program files\\Microsoft Dynamics NAV\$NAVVersionFolder" `
				-Destination $NAVApplicationTargetPath `
				-Force `
				-Recurse
		}
		else
		{
			$null = Copy-Item "$NAVTempFolder\$NAVDVDName\RoleTailoredClient\program files\\Microsoft Dynamics NAV\$NAVVersionFolder\*" `
				-Destination $NAVApplicationTargetPath `
				-Force `
				-Recurse
		}
	}
}

Function Get-VS2017HigherEditionInstalled
{
	$HigherEditionInstalled = ""
	$EditionList = "Enterprise,Community"
	$Editions = $EditionList.Split(",")
	foreach ($Edition in $Editions)
	{
		$CodeExePath = "$(Get-VS2017ExePath -Edition $Edition)\devenv.exe"
		$VSInstallPath = "$(Get-VS2017ExePath -Edition $Edition)\VSIXInstaller.exe"
		if ((Test-Path $VSInstallPath) -and (Test-Path $CodeExePath))
		{
			$HigherEditionInstalled = $Edition
			Break
		}
	}
	return $HigherEditionInstalled
}

Function Get-VS2017ExePath
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$Edition
	)
	return "C:\Program Files (x86)\Microsoft Visual Studio\2017\$Edition\Common7\IDE"
}

Function Invoke-VS2017DownloadAndInstall
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$Edition,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$DevelopmentTarget
	)

	# Static paramaters
	$CodeExePath = "$(Get-VS2017ExePath -Edition $Edition)\devenv.exe"
	$VSInstallPath = "$(Get-VS2017ExePath -Edition $Edition)\VSIXInstaller.exe"

	# Create temp folder
	$NAVTempFolder = "C:\Temp\Install"
	$null = New-Item -Path $NAVTempFolder -ItemType directory -Force
	
	# Download VS 2017 Install
	$VSDownloadUrl = "http://aka.ms/vs/15/release/vs_" + $Edition +".exe"
	$VSDownloadFile = "$NAVTempFolder\vs2017_$Edition.exe"
	if (-not (Test-Path $VSDownloadFile))
	{
		# Download VS 2017 Install
		Write-Host "Downloading $VSDownloadFile"
		Invoke-WebRequest -Uri $VSDownloadUrl -OutFile $VSDownloadFile
	}

	# run the installer 
	Write-Host "Running VS 2017 $Edition Install - check %TEMP% folder lor logs ..."
	if ($DevelopmentTarget)
	{
		$ArgumentList = " --add Microsoft.VisualStudio.Workload.NetWeb --add Microsoft.VisualStudio.Workload.ManagedDesktop --passive"
	}
	else
	{
		$ArgumentList = " --passive"
	}
	$App = Start-Process $VSDownloadFile -ArgumentList $ArgumentList -Wait

	# check the install
	if (-not(Test-Path $VSInstallPath) -or -not (Test-Path $CodeExePath))
	{
		throw "Error : VS 2017 $Edition Install - check %TEMP% folder lor logs ..."
	}

	if ($DevelopmentTarget)
	{
		
		# Download and install VS 2017 extension Rdlc (ID = 617ad572-c5b7-415c-b166-b2969077f719)
		$VSExtDownloadUrl = "https://probitools.gallerycdn.vsassets.io/extensions/probitools/microsoftrdlcreportdesignerforvisualstudio-18001/14.2/1517419538388/238792/3/Microsoft.RdlcDesigner.vsix"
		$VSExtDownloadFile = "$NAVTempFolder\vs2017_extension_rdlc.vsix"
		if (-not (Test-Path $VSExtDownloadFile))
		{
			# Download VS 1017 extension Rdlc
			Write-Host "Downloading $VSExtDownloadFile"
			Invoke-WebRequest -Uri $VSExtDownloadUrl -OutFile $VSExtDownloadFile

		}
		# Install extension
		Write-Host "`Installing VS 1017 extension Rdlc..." 
		$app = Start-Process $VSInstallPath -ArgumentList "/quiet $VSExtDownloadFile" -Wait
	}
}

Function Create-NAVDevScripts
{
    Param(

    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ShortcutsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$IconsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ScriptsContainerPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVDatabaseName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$BranchName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$MyWorkspaceSourceFolder,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVApplicationPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVVersionFolder,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$NavServerServiceFolder,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectTrigram,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$DockerContainer,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVServerName=".",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectObjectsRangeId="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectVersion="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectObjectsToIgnore="",
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectTargetLanguage,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$SQLUser="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$SQLPassword="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$AppProjectFolder="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectType="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectObjectsRangeToIgnore="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectObjectsShortDateFormat="dd/MM/yyyy",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectObjectsDecimalSeparator=",",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectAppsBaseAppDependencyAppIdsToNotRepublish="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVContainerGitBranches=""
	)

	# Create scripts to NavSourcesHelper folder
	Write-Host "Creating scripts in container folder ($ScriptsContainerPath)"
	$null = New-Item $ScriptsContainerPath  -ItemType Directory -Force

	if ($ProjectTargetLanguage -ne "AL")
	{
		# Scripts for CAL projects

		# Create script Export-ModifiedObjects
		$SourceFile = "$ScriptsContainerPath\Export-ModifiedObjects.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""Export NAV objects modified : NAV local database -> Workspace source folder    "" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Export NAV objects modified : Docker container -> Workspace source folder    "" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""NAV database name : $NAVDatabaseName"" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""Workspace source folder : $MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Warning ""Are you sure you want to EXPORT NAV objects to Workspace source folder ?""")
		[void]$Script.AppendLine("   `$Confirm = ""N""")
		[void]$Script.AppendLine("   `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("   if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVCALCodeManagement.ps1"")")
		[void]$Script.AppendLine("      `$StartTime = (Get-Date)")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("      `$Result = Export-ModifiedObjects -WorkspaceSourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVServerName"" -Database ""$NAVDatabaseName"" -ObjectsToIgnore ""$ProjectObjectsToIgnore"" -ObjectsRangeToIgnore ""$ProjectObjectsRangeToIgnore"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
		} else {
			[void]$Script.AppendLine("      `$Result = Export-ModifiedObjectsNAVContainer -WorkspaceSourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ContainerName ""$NAVContainerName"" -NAVVersionFolder ""$NAVVersionFolder"" -ObjectsToIgnore ""$ProjectObjectsToIgnore"" -ObjectsRangeToIgnore ""$ProjectObjectsRangeToIgnore"" -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
		}
		[void]$Script.AppendLine("      `$Elapsed = (Get-Date)-`$StartTime")
   		[void]$Script.AppendLine("      Write-Host ""Export completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force
	
		# Create script Import-ModifiedObjects
		$SourceFile = "$ScriptsContainerPath\Import-ModifiedObjects.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""Import NAV objects modified : Workspace source folder -> NAV local database    "" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Import NAV objects modified : Workspace source folder -> Docker container      "" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""NAV database name : $NAVDatabaseName"" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""Workspace source folder : $MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Warning ""Are you sure you want to IMPORT NAV objects from Workspace source folder ?""")
		[void]$Script.AppendLine("   `$Confirm = ""N""")
		[void]$Script.AppendLine("   `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("   if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVCALCodeManagement.ps1"")")
		[void]$Script.AppendLine("      `$StartTime = (Get-Date)")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("      `$Result = Import-ModifiedObjects -WorkspaceSourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVServerName"" -Database ""$NAVDatabaseName"" -ObjectsToIgnore ""$ProjectObjectsToIgnore"" -ObjectsRangeToIgnore ""$ProjectObjectsRangeToIgnore"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
		} else {
			[void]$Script.AppendLine("      `$Result = Import-ModifiedObjectsNAVContainer -WorkspaceSourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ContainerName ""$NAVContainerName"" -NAVVersionFolder ""$NAVVersionFolder"" -ObjectsToIgnore ""$ProjectObjectsToIgnore"" -ObjectsRangeToIgnore ""$ProjectObjectsRangeToIgnore"" -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
		}
		[void]$Script.AppendLine("      Write-Host ""Copy Add-ins to local client""")
		[void]$Script.AppendLine("      Copy-Item ""$MyWorkspaceSourceFolder\$BranchName\NAV\Add-Ins\*"" -Recurse -Destination ""$NAVApplicationPath\Add-ins\"" -Force")
		if (!$DockerContainer) {
			if ($NAVServerName -eq ".")
			{
				[void]$Script.AppendLine("      Write-Host ""Copy Add-ins to NAV server""")
				[void]$Script.AppendLine("      Copy-Item ""$MyWorkspaceSourceFolder\$BranchName\NAV\Add-Ins\*"" -Recurse -Destination ""$NavServerServiceFolder\Add-ins\"" -Force")
			}
		} else {
			[void]$Script.AppendLine("      Write-Host ""Copy Add-ins to Docker container""")
			[void]$Script.AppendLine("      `$ContainerId = Get-NavContainerId -containerName ""$NAVContainerName""")
			[void]$Script.AppendLine("      `$session = New-PSSession -ContainerId `$ContainerId -RunAsAdministrator")
			[void]$Script.AppendLine("      if (Test-Path ""$MyWorkspaceSourceFolder\$BranchName\NAV\Add-Ins\*"")")
			[void]$Script.AppendLine("      {")
			[void]$Script.AppendLine("         Copy-Item ""$MyWorkspaceSourceFolder\$BranchName\NAV\Add-Ins\*"" -Recurse -Destination ""C:\Program Files (x86)\Microsoft Dynamics NAV\$NAVVersionFolder\RoleTailored Client\Add-ins\"" -ToSession `$session -Force")
			[void]$Script.AppendLine("         Copy-Item ""$MyWorkspaceSourceFolder\$BranchName\NAV\Add-Ins\*"" -Recurse -Destination ""C:\Program Files\Microsoft Dynamics NAV\$NAVVersionFolder\Service\Add-ins\"" -ToSession `$session -Force")
			[void]$Script.AppendLine("      }")
		}
		[void]$Script.AppendLine("      `$Elapsed = (Get-Date)-`$StartTime")
   		[void]$Script.AppendLine("      Write-Host ""Import completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script Compile-Objects
		$SourceFile = "$ScriptsContainerPath\Compile-Objects.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   `$StartTime = (Get-Date)")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""Compile NAV objects : NAV local database -> Workspace source folder            "" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Compile NAV objects : Docker container -> Workspace source folder              "" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""NAV database name : $NAVDatabaseName"" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""Workspace source folder : $MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   `$Option = Read-Host ""Enter compilation option (possible values : (A)ll, (M)odified, (N)NotCompiled, default (N)otCompiled)""")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""NAVCALCodeManagement.ps1"")")
		[void]$Script.AppendLine("   `$StartTime = (Get-Date)")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   `$Result = Compile-ModifiedObjects -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVServerName"" -Database ""$NAVDatabaseName""  -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
		} else {
			[void]$Script.AppendLine("   `$NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $NAVContainerName")
			[void]$Script.AppendLine("   if (`$Option.StartsWith(""A"") -or `$Option.StartsWith(""a""))")
			[void]$Script.AppendLine("   {")
			[void]$Script.AppendLine("      `$Result = Compile-ModifiedObjects -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVContainerName"" -Database (`$NavContainerServerConfiguration.DatabaseName) -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator"" -All")
			[void]$Script.AppendLine("   }")
			[void]$Script.AppendLine("   elseif (`$Option.StartsWith(""M"") -or `$Option.StartsWith(""m""))")
			[void]$Script.AppendLine("   {")
			[void]$Script.AppendLine("      `$Result = Compile-ModifiedObjects -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVContainerName"" -Database (`$NavContainerServerConfiguration.DatabaseName) -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
			[void]$Script.AppendLine("   }")
			[void]$Script.AppendLine("   else")
			[void]$Script.AppendLine("   {")
			[void]$Script.AppendLine("      `$Result = Compile-NotCompiledObjects -ApplicationPath ""$NAVApplicationPath"" -Server ""$NAVContainerName"" -Database (`$NavContainerServerConfiguration.DatabaseName) -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword"" -ObjectsShortDateFormat ""$ProjectObjectsShortDateFormat"" -ObjectsDecimalSeparator ""$ProjectObjectsDecimalSeparator""")
			[void]$Script.AppendLine("   }")
		}
		[void]$Script.AppendLine("   `$Elapsed = (Get-Date)-`$StartTime")
   		[void]$Script.AppendLine("   Write-Host ""Compilation completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds.""")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   `$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("   Write-Host ""Compilation failed with error(s) in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds.""")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script CheckCodingRules
		$SourceFile = "$ScriptsContainerPath\CheckCodingRules.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Check NAV Coding rules (partially)                                             "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   Write-Host ""NAV database name : $NAVDatabaseName"" -ForegroundColor Cyan")
		} else {
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		}
		[void]$Script.AppendLine("   Write-Host ""Workspace source folder : $MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""NAVCALCodeManagement.ps1"")")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""NAVCodingRulesManagement.ps1"")")
		[void]$Script.AppendLine("   `$StartTime = (Get-Date)")
		if (!$DockerContainer) {
			[void]$Script.AppendLine("   `$Result = CheckCodingRules -ProjectTrigram ""$ProjectTrigram"" -DatabaseServer ""$NAVServerName"" -DatabaseName ""$NAVDatabaseName"" -SourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ProjectObjectsRangeId ""$ProjectObjectsRangeId"" -ProjectVersion ""$ProjectVersion""")
		} else {
			[void]$Script.AppendLine("   `$Result = CheckCodingRules -ProjectTrigram ""$ProjectTrigram"" -DatabaseServer ""$NAVContainerName"" -DatabaseName ""$NAVDatabaseName"" -SourceFolder ""$MyWorkspaceSourceFolder\$BranchName\NAV\Objects"" -ProjectObjectsRangeId ""$ProjectObjectsRangeId"" -ProjectVersion ""$ProjectVersion"" -SQLUser ""$SQLUser"" -SQLPassword ""$SQLPassword""")
		}
		[void]$Script.AppendLine("   `$Elapsed = (Get-Date)-`$StartTime")
   		[void]$Script.AppendLine("   Write-Host ""Check completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds.""")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Copy CAL function scripts to NavSourcesHelper folder
		$SourceFile = "$MyWorkspaceSourceFolder\Scripts\NAVCALCodeManagement.ps1"
		Copy-Item -Path $SourceFile -Destination "$ScriptsContainerPath\" -Force
		$SourceFile = "$MyWorkspaceSourceFolder\Scripts\NAVCodingRulesManagement.ps1"
		Copy-Item -Path $SourceFile -Destination "$ScriptsContainerPath\" -Force

		if ($DockerContainer) 
		{
			# Create script Sync-NAVContainerTenant
			$SourceFile = "$ScriptsContainerPath\Sync-NAVContainerTenant.ps1"
			$Script = [System.Text.StringBuilder]::new()
			[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
			[void]$Script.AppendLine("try")
			[void]$Script.AppendLine("{")
			[void]$Script.AppendLine("   Write-Host ""Sync-NAVContainerTenant                                                        "" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
			[void]$Script.AppendLine("   try")
			[void]$Script.AppendLine("   {")
			[void]$Script.AppendLine("      Sync-NAVContainerTenant -containerName $NAVContainerName -Mode CheckOnly")
			[void]$Script.AppendLine("      Sync-NAVContainerTenant -containerName $NAVContainerName -Mode Sync")
			[void]$Script.AppendLine("   }")
			[void]$Script.AppendLine("   catch")
			[void]$Script.AppendLine("   {")
			[void]$Script.AppendLine("      Write-Warning ""Are you sure you want to force tenant synchronization ?""")
			[void]$Script.AppendLine("      `$Confirm = ""N""")
			[void]$Script.AppendLine("      `$Confirm = Read-Host ""[Y/N] ?""")
			[void]$Script.AppendLine("      if (`$Confirm -eq ""Y"")")
			[void]$Script.AppendLine("      {")
			[void]$Script.AppendLine("         Sync-NAVContainerTenant -containerName $NAVContainerName -Mode ForceSync")
			[void]$Script.AppendLine("      }")
			[void]$Script.AppendLine("      else")
			[void]$Script.AppendLine("      {")
			[void]$Script.AppendLine("         Write-Warning ""Tenant not synchronized!""")
			[void]$Script.AppendLine("      }")
			[void]$Script.AppendLine("   }")
			[void]$Script.AppendLine("}")
			[void]$Script.AppendLine("catch")
			[void]$Script.AppendLine("{")
			[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
			#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
			[void]$Script.AppendLine("}")
			[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
			Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

			# Create script Generate-NAVContainerSymbolReference
			$SourceFile = "$ScriptsContainerPath\Generate-NAVContainerSymbolReference.ps1"
			$Script = [System.Text.StringBuilder]::new()
			[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
			[void]$Script.AppendLine("try")
			[void]$Script.AppendLine("{")
			[void]$Script.AppendLine("   Write-Host ""Generate-NAVContainerSymbolReference                                           "" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
			[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
			[void]$Script.AppendLine("   Generate-NAVContainerSymbolReference -containerName $NAVContainerName")
			[void]$Script.AppendLine("}")
			[void]$Script.AppendLine("catch")
			[void]$Script.AppendLine("{")
			[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
			#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
			[void]$Script.AppendLine("}")
			[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
			Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force
		}
	}
	if ($ProjectTargetLanguage -ne "CAL")
	{
		# Scripts for AL projects

		# Remove old script subfolder
		if (Test-Path "$ScriptsContainerPath\$(Split-Path $AppProjectFolder -Leaf)") 
		{ 
			Get-ChildItem -Path "$ScriptsContainerPath\$(Split-Path $AppProjectFolder -Leaf)" -Recurse | Remove-Item -force -recurse 
			Remove-Item "$ScriptsContainerPath\$(Split-Path $AppProjectFolder -Leaf)" -Force 
		}

		# Create script subfolder
		$null = New-Item $ScriptsContainerPath -ItemType Directory -Force

		# Create script Clean-NavContainerProjectApps
		$SourceFile = "$ScriptsContainerPath\Clean-NavContainerProjectApps.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Clean-NavContainerProjectApps                                                  "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""App project folder : $AppProjectFolder"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""GitManagement.ps1"")")
		[void]$Script.AppendLine("   `$GitCurrentBranch = Get-GitCurrentBranch -GitFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("   `$GitCurrentBranchColor = Get-GitCurrentBranchColor -GitBranch `$GitCurrentBranch -GitBranchesSupported ""$NAVContainerGitBranches""")
		[void]$Script.AppendLine("   Write-Host ""Git current branch : `$GitCurrentBranch"" -ForegroundColor `$GitCurrentBranchColor")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   [void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')")
		[void]$Script.AppendLine("   if (`$GitCurrentBranchColor -eq ""Red"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   if (Test-NavContainer -containerName $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Warning ""Are you sure you want to clean project Apps (App data will be destroyed) ?""")
		[void]$Script.AppendLine("      `$Confirm = ""N""")
		[void]$Script.AppendLine("      `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("      if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
		[void]$Script.AppendLine("         if (!(Test-NavContainer -containerName $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("         {")
		[void]$Script.AppendLine("            Write-Warning ""Docker container $NAVContainerName is not started. Starting container $NAVContainerName...""")
	    [void]$Script.AppendLine("            Start-NavContainer -containerName $NAVContainerName")
		[void]$Script.AppendLine("         }")
		[void]$Script.AppendLine("         Clean-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script Compile-NavContainerProjectApps
		$SourceFile = "$ScriptsContainerPath\Compile-NavContainerProjectApps.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Compile-NavContainerProjectApps  (build and publish)                           "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""App project folder : $AppProjectFolder"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""GitManagement.ps1"")")
		[void]$Script.AppendLine("   `$GitCurrentBranch = Get-GitCurrentBranch -GitFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("   `$GitCurrentBranchColor = Get-GitCurrentBranchColor -GitBranch `$GitCurrentBranch -GitBranchesSupported ""$NAVContainerGitBranches""")
		[void]$Script.AppendLine("   Write-Host ""Git current branch : `$GitCurrentBranch"" -ForegroundColor `$GitCurrentBranchColor")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   [void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')")
		[void]$Script.AppendLine("   if (`$GitCurrentBranchColor -eq ""Red"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   if (Test-NavContainer -containerName $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      `$JobStartTime = (Get-Date)")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
		[void]$Script.AppendLine("      if (!(Test-NavContainer -containerName $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Warning ""Docker container $NAVContainerName is not started. Starting container $NAVContainerName...""")
	    [void]$Script.AppendLine("         Start-NavContainer -containerName $NAVContainerName")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      `$StartTime = (Get-Date)")
		[void]$Script.AppendLine("      `$Compiled = (Compile-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword"" -EnableAppSourceCop:`$$($ProjectType -eq ""Edition""))")
		[void]$Script.AppendLine("		`$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("		Write-Host ""Project Apps compilation completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("      if (`$Compiled)")
		[void]$Script.AppendLine("      {")
		#[void]$Script.AppendLine("          Write-Warning ""Do you want to publish compiled Apps in container ?""")
		[void]$Script.AppendLine("         `$Confirm = ""Y""")
		#[void]$Script.AppendLine("         `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("         if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("         {")
		[void]$Script.AppendLine("            `$StartTime = (Get-Date)")
		[void]$Script.AppendLine("            UnPublish-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword""")
		[void]$Script.AppendLine("            Publish-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword"" -UseDevEndpoint -SkipVerification -BaseAppDependencyAppIdsToNotRepublish ""$ProjectAppsBaseAppDependencyAppIdsToNotRepublish""")
		[void]$Script.AppendLine("		      `$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("		      Write-Host ""Project Apps unpublishing/publishing completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("         }")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("		`$Elapsed = (Get-Date)-`$JobStartTime")
		[void]$Script.AppendLine("		Write-Host ""Project Apps compilation/unpublishing/publishing completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script Publish-NavContainerProjectApps
		$SourceFile = "$ScriptsContainerPath\Publish-NavContainerProjectApps.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Publish-NavContainerProjectApps                                                "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""App project folder : $AppProjectFolder"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""GitManagement.ps1"")")
		[void]$Script.AppendLine("   `$GitCurrentBranch = Get-GitCurrentBranch -GitFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("   `$GitCurrentBranchColor = Get-GitCurrentBranchColor -GitBranch `$GitCurrentBranch -GitBranchesSupported ""$NAVContainerGitBranches""")
		[void]$Script.AppendLine("   Write-Host ""Git current branch : `$GitCurrentBranch"" -ForegroundColor `$GitCurrentBranchColor")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   [void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')")
		[void]$Script.AppendLine("   if (`$GitCurrentBranchColor -eq ""Red"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   if (Test-NavContainer -containerName $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
		[void]$Script.AppendLine("      if (!(Test-NavContainer -containerName $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Warning ""Docker container $NAVContainerName is not started. Starting container $NAVContainerName...""")
	    [void]$Script.AppendLine("         Start-NavContainer -containerName $NAVContainerName")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      `$StartTime = (Get-Date)")
		[void]$Script.AppendLine("      UnPublish-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword""")
		[void]$Script.AppendLine("      Publish-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword"" -UseDevEndpoint -SkipVerification -BaseAppDependencyAppIdsToNotRepublish ""$ProjectAppsBaseAppDependencyAppIdsToNotRepublish""")
		[void]$Script.AppendLine("		`$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("		Write-Host ""Project Apps unpublishing/publishing completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script UnPublish-NavContainerProjectApps
		$SourceFile = "$ScriptsContainerPath\UnPublish-NavContainerProjectApps.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""UnPublish-NavContainerProjectApps                                                "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""App project folder : $AppProjectFolder"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""GitManagement.ps1"")")
		[void]$Script.AppendLine("   `$GitCurrentBranch = Get-GitCurrentBranch -GitFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("   `$GitCurrentBranchColor = Get-GitCurrentBranchColor -GitBranch `$GitCurrentBranch -GitBranchesSupported ""$NAVContainerGitBranches""")
		[void]$Script.AppendLine("   Write-Host ""Git current branch : `$GitCurrentBranch"" -ForegroundColor `$GitCurrentBranchColor")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   [void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')")
		[void]$Script.AppendLine("   if (`$GitCurrentBranchColor -eq ""Red"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   if (Test-NavContainer -containerName $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
		[void]$Script.AppendLine("      if (!(Test-NavContainer -containerName $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Warning ""Docker container $NAVContainerName is not started. Starting container $NAVContainerName...""")
	    [void]$Script.AppendLine("         Start-NavContainer -containerName $NAVContainerName")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      `$StartTime = (Get-Date)")
		[void]$Script.AppendLine("      UnPublish-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword""")
		[void]$Script.AppendLine("		`$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("		Write-Host ""Project Apps unpublishing completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script RunTests-NavContainerProjectApps
		$SourceFile = "$ScriptsContainerPath\RunTests-NavContainerProjectApps.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""RunTests-NavContainerProjectApps                                               "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""App project folder : $AppProjectFolder"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   . (Join-Path `$PSScriptRoot ""GitManagement.ps1"")")
		[void]$Script.AppendLine("   `$GitCurrentBranch = Get-GitCurrentBranch -GitFolder ""$AppProjectFolder""")
		[void]$Script.AppendLine("   `$GitCurrentBranchColor = Get-GitCurrentBranchColor -GitBranch `$GitCurrentBranch -GitBranchesSupported ""$NAVContainerGitBranches""")
		[void]$Script.AppendLine("   Write-Host ""Git current branch : `$GitCurrentBranch"" -ForegroundColor `$GitCurrentBranchColor")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   [void](Read-Host 'Press [Enter] to continue or [CTRL+C] to exit...')")
		[void]$Script.AppendLine("   if (`$GitCurrentBranchColor -eq ""Red"")")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Error: Supported Git branches for this container are $NAVContainerGitBranches. Change current Git branch or use the scripts related to the container.""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   if (Test-NavContainer -containerName $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      . (Join-Path `$PSScriptRoot ""NAVDockerContainerManagement.ps1"")")
		[void]$Script.AppendLine("      Write-Warning ""Are you sure you want to run tests (container will restart before running tests) ?""")
		[void]$Script.AppendLine("      `$Confirm = ""N""")
		[void]$Script.AppendLine("      `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("      if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         `$StartTime = (Get-Date)")
		if ([int]$NAVVersionFolder -le [int]"140")
		{
			[void]$Script.AppendLine("         RunTests-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword""")
		}
		else
		{
			[void]$Script.AppendLine("         RunTests-NavContainerProjectApps -containerName $NAVContainerName -AppProjectFolder ""$AppProjectFolder"" -User ""$SQLUser"" -Password ""$SQLPassword"" -ByExtensionId")
		}
		[void]$Script.AppendLine("		   `$Elapsed = (Get-Date)-`$StartTime")
		[void]$Script.AppendLine("		   Write-Host ""Project Apps running tests completed in `$([math]::Round(`$Elapsed.TotalSeconds)) seconds."" -ForegroundColor Cyan")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force
	}
	if ($DockerContainer) 
	{
		# Create script Start-NavContainer
		$SourceFile = "$ScriptsContainerPath\Start-NavContainer.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Start-NavContainer                                                             "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   if (Test-NavContainer $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      if (Test-NavContainer $NAVContainerName -doNotIncludeStoppedContainers)")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Host ""Container $NAVContainerName already started!""")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      else")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Host ""Starting container $NAVContainerName...""")
		[void]$Script.AppendLine("         Start-NavContainer $NAVContainerName")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script Stop-NavContainer
		$SourceFile = "$ScriptsContainerPath\Stop-NavContainer.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Stop-NavContainer                                                             "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   if (Test-NavContainer $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      if (!(Test-NavContainer $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Host ""Container $NAVContainerName already stopped!""")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      else")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Warning ""Are you sure you want to stop container $NAVContainerName ?""")
		[void]$Script.AppendLine("         `$Confirm = ""N""")
		[void]$Script.AppendLine("         `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("         if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("         {")
		[void]$Script.AppendLine("            Write-Host ""Stopping container $NAVContainerName...""")
		[void]$Script.AppendLine("            Stop-NavContainer $NAVContainerName")
		[void]$Script.AppendLine("         }")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force

		# Create script Restart-NavContainer
		$SourceFile = "$ScriptsContainerPath\Restart-NavContainer.ps1"
		$Script = [System.Text.StringBuilder]::new()
		[void]$Script.AppendLine("`$ErrorActionPreference = ""Stop""")
		[void]$Script.AppendLine("try")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host ""Restart-NavContainer                                                           "" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Project name : $ProjectName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""Docker container name : $NAVContainerName"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   Write-Host ""-------------------------------------------------------------------------------"" -ForegroundColor Cyan")
		[void]$Script.AppendLine("   if (Test-NavContainer $NAVContainerName)")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      if ((Test-NavContainer $NAVContainerName -doNotIncludeStoppedContainers))")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Warning ""Are you sure you want to restart container $NAVContainerName ?""")
		[void]$Script.AppendLine("         `$Confirm = ""N""")
		[void]$Script.AppendLine("         `$Confirm = Read-Host ""[Y/N] ?""")
		[void]$Script.AppendLine("         if (`$Confirm -eq ""Y"")")
		[void]$Script.AppendLine("         {")
		[void]$Script.AppendLine("            Write-Host ""Restarting container $NAVContainerName...""")
		[void]$Script.AppendLine("            Restart-NavContainer $NAVContainerName")
		[void]$Script.AppendLine("         }")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("      else")
		[void]$Script.AppendLine("      {")
		[void]$Script.AppendLine("         Write-Host ""Restarting container $NAVContainerName...""")
		[void]$Script.AppendLine("         Restart-NavContainer $NAVContainerName")
		[void]$Script.AppendLine("      }")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("   else")
		[void]$Script.AppendLine("   {")
		[void]$Script.AppendLine("      Write-Error ""Container $NAVContainerName doesn't exist. Re-create it with NAVCreateDevEnv-DockerContainer.bat""")
		[void]$Script.AppendLine("   }")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("catch")
		[void]$Script.AppendLine("{")
		[void]$Script.AppendLine("   Write-Host `$_.Exception.Message -Foreground Red")
		#[void]$Script.AppendLine("   Write-Host `$_.InvocationInfo.PositionMessage -Foreground Red")
		[void]$Script.AppendLine("}")
		[void]$Script.AppendLine("[void](Read-Host 'Press [Enter] to exit...')")
		Set-Content -Path $SourceFile -Value ($Script.ToString()) -Force
	}

	# Copy function scripts to NavSourcesHelper folder
	$SourceFile = "$MyWorkspaceSourceFolder\Scripts\NAVDockerContainerManagement.ps1"
	Copy-Item -Path $SourceFile -Destination "$ScriptsContainerPath\" -Force
	$SourceFile = "$MyWorkspaceSourceFolder\Scripts\GitManagement.ps1"
	Copy-Item -Path $SourceFile -Destination "$ScriptsContainerPath\" -Force

	# Copy assets to NavSourcesHelper folder
	$IconsPath = $env:ProgramData + "\NavSourcesHelper\$env:USERNAME\$ProjectName\Assets"
	$null = New-Item $IconsPath  -ItemType Directory -Force
	$SourceFile = "$PSScriptRoot\..\Assets\*"
	Copy-Item -Path $SourceFile -Destination "$IconsPath" -Force -Recurse
}

Function Create-NAVDevShortcuts
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ShortcutsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$IconsPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ScriptsContainerPath,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$BranchName,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVApplicationPath,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVServerInstanceName,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$CodingRulesUrl,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$DockerContainer,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVServerName=".",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectSubName="",
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$ProjectTargetLanguage,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$AppProjectFolder,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVVersionFolder="",
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$ContainerSharedFolder="",
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$NAVProductName
	)

	# Create "Developpement CAL and AL (Local container)" project folder on Desktop
	$DesktopContainerPath = $null
	$DesktopCALContainerPath = $null
	$DesktopALContainerPath = $null
	$DesktopPath = [Environment]::GetFolderPath("Desktop")
	if (!$DockerContainer) {
		Write-Host "Creating Desktop shortcuts for Developpement $BranchName ($NAVContainerName local database)"
		$NewDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Developpement $BranchName ($NAVContainerName local database)"
		$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\De*veloppement $BranchName ($NAVContainerName local database)"
		Get-ChildItem $OldDesktopContainerPath | % {
			$Folder = $_.FullName
			$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
			Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
			if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
		}
		$DesktopCALContainerPath = $NewDesktopContainerPath

	} else {
		Write-Host "Creating Desktop shortcuts for CAL and AL Development..."
		if ($ProjectTargetLanguage -eq "CAL") {
			$NewDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Developpement $BranchName ($NAVContainerName Docker container)"
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement $BranchName ($NAVContainerName Docker container)"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$DesktopCALContainerPath = $NewDesktopContainerPath
		} elseif ($ProjectTargetLanguage -eq "CALAL") {
			$NewDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Developpement CAL $BranchName ($NAVContainerName Docker container)"
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement CAL $BranchName ($NAVContainerName Docker container)"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$DesktopCALContainerPath = $NewDesktopContainerPath

			$NewDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Developpement AL ($NAVContainerName Docker container)"
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement AL ($NAVContainerName Docker container)"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement AL $BranchName ($(Split-Path $AppProjectFolder -Leaf))"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$DesktopALContainerPath = $NewDesktopContainerPath
		} elseif ($ProjectTargetLanguage -eq "AL") {
			$NewDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\Developpement AL ($NAVContainerName Docker container)"
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement AL ($NAVContainerName Docker container)"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$OldDesktopContainerPath = "$ShortcutsPath\$ProjectSubName\D*veloppement AL $BranchName ($(Split-Path $AppProjectFolder -Leaf))"
			if (Test-Path $OldDesktopContainerPath) {
				Get-ChildItem $OldDesktopContainerPath | % {
					$Folder = $_.FullName
					$null = New-Item $NewDesktopContainerPath -ItemType Directory -Force
					Get-ChildItem "$Folder\*" | %  { Move-Item $_.FullName -Destination "$NewDesktopContainerPath\$($_.Name)" -Force }
					if (-not (Get-ChildItem "$Folder\*")) { Remove-Item $Folder -Force }
				}
			}
			$DesktopALContainerPath = $NewDesktopContainerPath
		}
	}
	if ($DesktopCALContainerPath) { $null = New-Item $DesktopCALContainerPath -ItemType Directory -Force }
	if ($DesktopALContainerPath) { $null = New-Item $DesktopALContainerPath -ItemType Directory -Force }

	# Rename $NAVProductName
	$NAVProductName = $NAVProductName.Replace("Microsoft Dynamics 365 ","")
	$NAVProductName = $NAVProductName.Replace("Microsoft Dynamics ","")

	if ($ProjectTargetLanguage -ne "CAL")
	{
		# Create VS Code tasks.json
		Create-TasksJson -ProjectFolder $AppProjectFolder
	}

	# Create new development shortcuts
	if ($DockerContainer)
	{
		# Copy Container shortcut Windows Client
		$SourceShortcut = "$NAVContainerName Windows Client.lnk"
		$OldDestinationShortcut = "$BranchName Windows Client ($NAVContainerName Docker container).lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
        $OldDestinationShortcut = " $NAVProductName Windows Client.lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$DestinationShortcut = "$NAVProductName Windows Client ($NAVContainerName Docker container).lnk"
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
		}
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Copy Container shortcut WinClient Debugger
		$SourceShortcut = "$NAVContainerName WinClient Debugger.lnk"
		$OldDestinationShortcut = "$BranchName WinClient Debugger.lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
        $OldDestinationShortcut = " $NAVProductName Windows Client Debugger ($NAVContainerName Docker container).lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$DestinationShortcut = "$NAVProductName Windows Client Debugger ($NAVContainerName Docker container).lnk"
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
			if (Test-Path $ShortCutFile)
			{
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				$ShortCut.IconLocation = "$IconsPath\Debug.ico"
				$ShortCut.Save()
			}
		}
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Copy Container shortcut Test Tool
		$SourceShortcut = "$NAVContainerName Test Tool.lnk"
		$OldDestinationShortcut = "$BranchName Test Tool.lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
        $OldDestinationShortcut = " $NAVProductName Test Tool ($NAVContainerName Docker container).lnk"
        if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$DestinationShortcut = "$NAVProductName Test Tool ($NAVContainerName Docker container).lnk"
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
			if (Test-Path $ShortCutFile)
			{
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				if ([int]$NAVVersionFolder -le [int]"110") { $ShortCut.IconLocation = "$IconsPath\NavWeb.ico" }
				elseif ([int]$NAVVersionFolder -le [int]"140") { $ShortCut.IconLocation = "$IconsPath\BCOld.ico" }
				else { $ShortCut.IconLocation = "$IconsPath\BCNew.ico" }
				$ShortCut.Save()
			}
		}
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Copy Container shortcut Web Client
		$SourceShortcut = "$NAVContainerName Web Client.lnk"
		$OldDestinationShortcut = "$BranchName Web Client.lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
        $OldDestinationShortcut = " $NAVProductName Web Client ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$DestinationShortcut = "$NAVProductName Web Client ($NAVContainerName Docker container).lnk"
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
			if (Test-Path $ShortCutFile)
			{
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				if ([int]$NAVVersionFolder -le [int]"110") { $ShortCut.IconLocation = "$IconsPath\NavWeb.ico" }
				elseif ([int]$NAVVersionFolder -le [int]"140") { $ShortCut.IconLocation = "$IconsPath\BCOld.ico" }
				else { $ShortCut.IconLocation = "$IconsPath\BCNew.ico" }
				$ShortCut.Save()
			}
		} 
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Copy Container shortcut CSIDE
		$SourceShortcut = "$NAVContainerName CSIDE.lnk"
		$OldDestinationShortcut = "3. $BranchName CSIDE.lnk"
		$DestinationShortcut = "3. CAL CSIDE ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
		}
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		}
		if (Test-Path "$DesktopCALContainerPath\$DestinationShortcut")
		{
			# Modify CSIDE shortcut to launch PowerShell script for ClientUserSettings context management
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCut = $Shell.CreateShortcut("$DesktopCALContainerPath\$DestinationShortcut")
			$ShortcutWorkingDirectory = $ShortCut.WorkingDirectory

			$Script = [System.Text.StringBuilder]::new()
			[void]$Script.AppendLine("Copy-Item ""$ShortcutWorkingDirectory\ClientUserSettings.config"" ""`$(`$env:APPDATA)\Microsoft\Microsoft Dynamics NAV\$NAVVersionFolder\ClientUserSettings.config""")
			[void]$Script.AppendLine("& ""$($ShortCut.TargetPath)"" $($ShortCut.Arguments.Replace("" "",""""))")
			Set-Content -Path "$($ShortcutWorkingDirectory)\finsql.ps1" -Value ($Script.ToString()) -Force

			$ShortCut.TargetPath = "PowerShell.exe"
			$ShortCut.Arguments = "-ExecutionPolicy Bypass -Windowstyle hidden -File ""$ShortcutWorkingDirectory\finsql.ps1"""
			$ShortCut.WorkingDirectory = $ShortcutWorkingDirectory
			$ShortCut.WindowStyle = 7
			$ShortCut.Save()
		}

		# Copy Container shortcut Command Prompt
		$SourceShortcut = "$NAVContainerName Command Prompt.lnk"
		$OldDestinationShortcut = "$BranchName Command Prompt ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "Docker container Command Prompt ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
			if (Test-Path $ShortCutFile)
			{
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				$ShortCut.IconLocation = "$IconsPath\Docker.ico"
				$ShortCut.Save()
			}
		} 
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Copy Container shortcut PowerShell Prompt
		$SourceShortcut = "$NAVContainerName PowerShell Prompt.lnk"
		$OldDestinationShortcut = "$BranchName PowerShell Prompt ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "Docker container PowerShell Prompt ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$SourceFile = "$DesktopPath\$SourceShortcut"
		$ShortCutFile = "$IconsPath\$SourceShortcut"
		if (Test-Path $SourceFile)
		{
			Copy-Item -Path $SourceFile -Destination $ShortCutFile -Force
			Remove-Item -Path $SourceFile -Force
			if (Test-Path $ShortCutFile)
			{
				$Shell = New-Object -ComObject ("WScript.Shell")
				$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
				$ShortCut.IconLocation = "$IconsPath\Docker.ico"
				$ShortCut.Save()
			}
		} 
		if (Test-Path $ShortCutFile)
		{
			if ($DesktopCALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path $ShortCutFile -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Create NavContainerHelper (Aide) Shortcut 
		$DestinationShortcut = "NavContainerHelper (Aide).url"
		$Shell = New-Object -ComObject ("WScript.Shell")
		if (Test-Path "$DesktopContainerPath\NavContainerHelper (Aide).lnk") { Remove-Item "$DesktopContainerPath\NavContainerHelper (Aide).lnk"}
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "https://github.com/microsoft/navcontainerhelper/blob/master/NavContainerHelper.md"
		#$ShortCut.IconLocation = "$IconsPath\Help.ico"
		$ShortCut.Save()
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }


		# Create Stop-NavContainer Shortcut 
		$OldDestinationShortcut = "$BranchName Stop-NavContainer ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "Docker Stop-NavContainer ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "PowerShell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Stop-NavContainer.ps1"""
		$ShortCut.WorkingDirectory = "$ScriptsContainerPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\Docker.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		# Create Start-NavContainer Shortcut 
		$OldDestinationShortcut = "$BranchName Start-NavContainer ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "Docker Start-NavContainer ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "PowerShell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Start-NavContainer.ps1"""
		$ShortCut.WorkingDirectory = "$ScriptsContainerPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\Docker.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		# Create Restart-NavContainer Shortcut 
		$OldDestinationShortcut = "$BranchName Restart-NavContainer ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "Docker Restart-NavContainer ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "PowerShell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Restart-NavContainer.ps1"""
		$ShortCut.WorkingDirectory = "$ScriptsContainerPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\Docker.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		# Create Restart-NavContainerProjectApps VS Code task
		if ($ProjectTargetLanguage -ne "CAL")
		{
			Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL Restart-NavContainer (Ctrl+Alt+R)" -PowerShellScriptFile "$ScriptsContainerPath\Restart-NavContainer.ps1"
			Update-KeybindingsJson -Name "Calliope AL Restart-NavContainer (Ctrl+Alt+R)" -Key "Ctrl+Alt+r"
		}

		# Create Container Shared Folder shortcut
		if ($ContainerSharedFolder -ne "")
		{
			$OldDestinationShortcut = "$BranchName Container Shared Folder ($NAVContainerName Docker container).lnk"
			$DestinationShortcut = "Docker container Shared Folder ($NAVContainerName Docker container).lnk"
			if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
            if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$IconsPath\$DestinationShortcut"
			if (Test-Path "$IconsPath\$DestinationShortcut") { Remove-Item "$IconsPath\$DestinationShortcut" -Force }
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = "$ContainerSharedFolder"
			$ShortCut.Arguments = ""
			$ShortCut.WorkingDirectory = "$ContainerSharedFolder\"
			$ShortCut.WindowStyle = 1
			$ShortCut.Save()
			if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}

		# Create NAVCreateDevEnv-DockerContainer Shortcut
		$OldDestinationShortcut = "$BranchName NAVCreateDevEnv-DockerContainer.lnk"
		$DestinationShortcut = "Setup NAVCreateDevEnv-DockerContainer ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$PSScriptRoot\NAVCreateDevEnv-DockerContainer.bat"
		$ShortCut.Arguments = ""
		$ShortCut.WorkingDirectory = $PSScriptRoot
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		# Create NAVCreateDevEnv-DockerContainer VS Code task
		if ($ProjectTargetLanguage -ne "CAL")
		{
			Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL NAVCreateDevEnv-DockerContainer (Ctrl+Alt+D)" -PowerShellScriptFile "..\Scripts\NAVCreateDevEnv-DockerContainer.ps1"
			Update-KeybindingsJson -Name "Calliope AL NAVCreateDevEnv-DockerContainer (Ctrl+Alt+D)" -Key "Ctrl+Alt+d"
		}

		# Create NAVUpdateDevEnv-DockerContainer Shortcut
		$OldDestinationShortcut = "$BranchName NAVUpdateDevEnv-DockerContainer.lnk"
		$DestinationShortcut = "Setup NAVUpdateDevEnv-DockerContainer ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$PSScriptRoot\NAVUpdateDevEnv-DockerContainer.bat"
		$ShortCut.Arguments = ""
		$ShortCut.WorkingDirectory = $PSScriptRoot
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		# Create NAVUpdateDevEnv-DockerContainer VS Code task
		if ($ProjectTargetLanguage -ne "CAL")
		{
			Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL NAVUpdateDevEnv-DockerContainer (Ctrl+Alt+V)" -PowerShellScriptFile "..\Scripts\NAVUpdateDevEnv-DockerContainer.ps1"
			Update-KeybindingsJson -Name "Calliope AL NAVUpdateDevEnv-DockerContainer (Ctrl+Alt+V)" -Key "Ctrl+Alt+v"
		}

		# Create NavContainerHelper (PowerShell) Shortcut 
		$DestinationShortcut = "NavContainerHelper (PowerShell).lnk"
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$IconsPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "PowerShell.exe"
		$ShortCut.Arguments = "-NoExit -Command ""cd '$ScriptsContainerPath';.(Join-Path '$ScriptsContainerPath' ""NAVDockerContainerManagement.ps1"");Display-WelcomeText;Display-NAVDockerContainers"""
		$ShortCut.WorkingDirectory = "$ScriptsContainerPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
		if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }

		if ($ProjectTargetLanguage -ne "AL")
		{
			# Create Sync-NavContainerTenant Shortcut 
			$OldDestinationShortcut = "$BranchName CAL Sync-NavContainerTenant ($NAVContainerName Docker container).lnk"
			$DestinationShortcut = "CAL Sync-NavContainerTenant ($NAVContainerName Docker container).lnk"
			if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
            if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = "powershell.exe"
			$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Sync-NavContainerTenant.ps1"""
			$ShortCut.WindowStyle = 1
			$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
			$ShortCut.Save()
			$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
			$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
			[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

			# Create Generate-NavContainerSymbolReference Shortcut 
			$OldDestinationShortcut = "$BranchName CAL Generate-NavContainerSymbolReference ($NAVContainerName Docker container).lnk"
			$DestinationShortcut = "CAL Generate-NavContainerSymbolReference ($NAVContainerName Docker container).lnk"
			if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
            if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = "powershell.exe"
			$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Generate-NavContainerSymbolReference.ps1"""
			$ShortCut.WindowStyle = 1
			$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
			$ShortCut.Save()
			$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
			$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
			[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		}

		if ($ProjectTargetLanguage -ne "CAL")
		{
			# Create Git Command Prompt Shortcut 
			$DestinationShortcut = "Git Powershell Prompt ($(Split-Path $AppProjectFolder -Leaf)).lnk"
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$IconsPath\$DestinationShortcut"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = "PowerShell.exe"
			$ShortCut.Arguments = "-NoExit -Command ""cd '$AppProjectFolder';. (Join-Path '$ScriptsContainerPath' ""GitManagement.ps1"");Write-GitWelcomeText"""
			$ShortCut.WorkingDirectory = $AppProjectFolder
			$ShortCut.WindowStyle = 1
			$ShortCut.IconLocation = "$IconsPath\Git.ico"
			$ShortCut.Save()
			$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
			$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
			[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
			if ($DesktopCALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopCALContainerPath\$DestinationShortcut" -Force }
			if ($DesktopALContainerPath) { Copy-Item -Path "$IconsPath\$DestinationShortcut" -Destination "$DesktopALContainerPath\$DestinationShortcut" -Force }
		}
	} else {
		# Get NAV service configuration

		#$NAVService = Get-WmiObject win32_service | ?{$_.Name -eq 'MicrosoftDynamicsNavServer$'+ $NAVServerInstanceName} | select Name, DisplayName, @{Name="Path"; Expression={$_.PathName.split('"')[1]}}
		$NAVService = Invoke-Command -ComputerName $NAVServerName -ArgumentList $NAVServerInstanceName -ScriptBlock { param($NAVServerInstanceName) return Get-WmiObject win32_service | ?{$_.Name -eq 'MicrosoftDynamicsNavServer$'+ $NAVServerInstanceName} | select Name, DisplayName, @{Name="Path"; Expression={$_.PathName.split('"')[1]}} }

		$NavServerServiceFolder = Split-Path $NAVService.Path

		#$null = Import-Module ($NavServerServiceFolder + "\NavAdminTool.ps1") *> $null
		#$NAVInstanceConfiguration = Get-NAVServerConfiguration -ServerInstance $NAVServerInstanceName -AsXml
		$NAVInstanceConfiguration = Invoke-Command -ComputerName $NAVServerName -ArgumentList $NAVServerInstanceName,$NavServerServiceFolder -ScriptBlock { param($NAVServerInstanceName,$NavServerServiceFolder) $null = Import-Module ($NavServerServiceFolder + "\NavAdminTool.ps1") *> $null; return Get-NAVServerConfiguration -ServerInstance $NAVServerInstanceName -AsXml }

		$NAVClientServicesPort = [string]($NAVInstanceConfiguration.configuration.appSettings.add | where Key -eq "ClientServicesPort").Value
		#$NAVServer = [string]($NAVInstanceConfiguration.configuration.appSettings.add | where Key -eq "Server").Value
		$NAVClientServicesCredentialType = [string]($NAVInstanceConfiguration.configuration.appSettings.add | where Key -eq "ClientServicesCredentialType").Value
		$NAVDnsIdentity = [string]($NAVInstanceConfiguration.configuration.appSettings.add | where Key -eq "DnsIdentity").Value
		$NAVHelpServer = [string]($NAVInstanceConfiguration.configuration.appSettings.add | where Key -eq "HelpServer").Value

		# Create CSIDE Shortcut
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\3. $BranchName CSIDE.lnk"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$NAVApplicationPath\finsql.exe"
		$ShortCut.Arguments = "servername=$NAVServerName, Database=$NAVDatabaseName, ntauthentication=1"
		$ShortCut.WorkingDirectory = "$NAVApplicationPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create ClientUserSettings.config (Windows)
		$SourceFile = "$NAVApplicationPath\ClientUserSettings.config"
		$Script = "<?xml version=""1.0"" encoding=""utf-8""?>
		<configuration>
		  <appSettings>
			<add key=""Server"" value=""$NAVServerName"" />
			<add key=""ClientServicesPort"" value=""$NAVClientServicesPort"" />
			<add key=""ServerInstance"" value=""$NAVServerInstanceName"" />
			<add key=""TenantId"" value="""" />
			<add key=""ClientServicesProtectionLevel"" value=""EncryptAndSign"" />
			<add key=""UrlHistory"" value="""" />
			<add key=""ClientServicesCompressionThreshold"" value=""64"" />
			<add key=""ClientServicesChunkSize"" value=""28"" />
			<add key=""MaxNoOfXMLRecordsToSend"" value=""5000"" />
			<add key=""MaxImageSize"" value=""26214400"" />
			<add key=""ClientServicesCredentialType"" value=""$NAVClientServicesCredentialType"" />
			<add key=""ACSUri"" value="""" />
			<add key=""AllowNtlm"" value=""true"" />
			<add key=""ServicePrincipalNameRequired"" value=""False"" />
			<add key=""ServicesCertificateValidationEnabled"" value=""true"" />
			<add key=""DnsIdentity"" value=""$NAVDnsIdentity"" />
			<add key=""HelpServer"" value=""$NAVHelpServer"" />
			<add key=""HelpServerPort"" value=""49000"" />
			<add key=""ProductName"" value="""" />
			<add key=""UnknownSpnHint"" value="""" />
		  </appSettings>
		</configuration>
		"
		Set-Content -Path $SourceFile -Value $Script -Force

		# Create Windows client Shortcut (Windows)
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopContainerPath\$BranchName Windows Client.lnk"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$NAVApplicationPath\Microsoft.Dynamics.Nav.Client.exe"
		$ShortCut.Arguments = "-settings:ClientUserSettings.config"
		$ShortCut.WorkingDirectory = "$NAVApplicationPath\"
		$ShortCut.WindowStyle = 1
		$ShortCut.Save()

		if (!([string]::IsNullOrEmpty($NAVWebClientUrl))) 
		{
			# Create Web client Shortcut (Windows)
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$DesktopContainerPath\$BranchName Web Client.lnk"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = $NAVWebClientUrl
			$ShortCut.Arguments = ""
			$ShortCut.WorkingDirectory = ""
			$ShortCut.WindowStyle = 1
			if ([int]$NAVVersionFolder -le [int]"110") { $ShortCut.IconLocation = "$IconsPath\NavWeb.ico" }
			elseif ([int]$NAVVersionFolder -le [int]"140") { $ShortCut.IconLocation = "$IconsPath\BCOld.ico" }
			else { $ShortCut.IconLocation = "$IconsPath\BCNew.ico" }
			$ShortCut.Save()
		}
	}

	if ($ProjectTargetLanguage -ne "AL")
	{
		# Create Export modified objects Shortcut 
		$OldDestinationShortcut = "4. $BranchName EXPORT modified objects ($NAVContainerName to Workspace).lnk"
		$DestinationShortcut = "4. CAL EXPORT modified objects ($NAVContainerName to Workspace).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Export-ModifiedObjects.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Import modified objects Shortcut 
		$OldDestinationShortcut = "2. $BranchName IMPORT modified objects (Workspace to $NAVContainerName).lnk"
		$DestinationShortcut = "2. CAL IMPORT modified objects (Workspace to $NAVContainerName).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Import-ModifiedObjects.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Compile objects Shortcut 
		$OldDestinationShortcut = "$BranchName CAL Compile objects ($NAVContainerName Docker container).lnk"
		$DestinationShortcut = "CAL Compile objects ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Compile-Objects.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Check coding rules (partially) Shortcut 
		$ShortCutFile = "$DesktopCALContainerPath\$BranchName Check coding rules (partially).lnk"
		if (Test-Path $ShortCutFile) { Remove-Item $ShortCutFile -Force }
		$OldDestinationShortcut = "$BranchName CAL Check coding rules (partially)"
		$DestinationShortcut = "CAL Check coding rules (partially).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopCALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\CheckCodingRules.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\Rules.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create VS 2017 Shortcut 
		$VS2017Edition = Get-VS2017HigherEditionInstalled
		if ($VS2017Edition -ne "" -and (Test-Path "$(Get-VS2017ExePath -Edition $VS2017Edition)\devenv.exe"))
		{
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$DesktopCALContainerPath\1.5 Visual Studio 2017.lnk"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = "$(Get-VS2017ExePath -Edition $VS2017Edition)\devenv.exe"
			$ShortCut.Arguments = ""
			$ShortCut.WindowStyle = 1
			$ShortCut.Save()
			$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
			$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
			[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		}
	}
	if ($ProjectTargetLanguage -ne "CAL")
	{
		# Create VS Code Shortcut 
		$VSCodeExeFile = "$($Env:USERPROFILE)\AppData\Local\Programs\Microsoft VS Code\Code.exe"
		if (!(Test-Path $VSCodeExeFile)) { $VSCodeExeFile = "C:\Program Files\Microsoft VS Code\Code.exe" }
		if (Test-Path $VSCodeExeFile)
		{
			$Shell = New-Object -ComObject ("WScript.Shell")
			$ShortCutFile = "$DesktopALContainerPath\Visual Studio Code ($(Split-Path $AppProjectFolder -Leaf)).lnk"
			$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
			$ShortCut.TargetPath = $VSCodeExeFile
			if ([int]$NAVVersionFolder -gt [int]"110" -and (Test-Path "$AppProjectFolder\$(Split-Path $AppProjectFolder -Leaf).code-workspace")) # VS Code workspace works only with BC AL Language extension (ms-dynamics-smb.al) and doesn't work with NAV AL Language extension (microsoft.al)
			{
				$ShortCut.Arguments = """$AppProjectFolder\$(Split-Path $AppProjectFolder -Leaf).code-workspace"" -n"
			}
			else
			{
				$AppFolders = @()
				Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object { $AppFolders += $_.DirectoryName }
				if ($AppFolders.Count -eq 1)
				{
					$ShortCut.Arguments = """$($AppFolders[0])"" -n"
				}
				else
				{
					$ShortCut.Arguments = """$AppProjectFolder"" -n"
				}
			}
			$ShortCut.WindowStyle = 1
			$ShortCut.Save()
			$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
			$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
			[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
		}

		# Create Clean-NavContainerProjectApps Shortcut 
		$OldDestinationShortcut = "$BranchName AL Clean-NavContainerProjectApps ($(Split-Path $AppProjectFolder -Leaf)).lnk"
		$DestinationShortcut = "AL Clean-NavContainerProjectApps ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Clean-NavContainerProjectApps.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Clean-NavContainerProjectApps VS Code task
		Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL Clean-NavContainerProjectApps (Ctrl+Alt+C)" -PowerShellScriptFile "$ScriptsContainerPath\Clean-NavContainerProjectApps.ps1"
		Update-KeybindingsJson -Name "Calliope AL Clean-NavContainerProjectApps (Ctrl+Alt+C)" -Key "Ctrl+Alt+c"

		# Create Compile-NavContainerProjectApps Shortcut 
		$OldDestinationShortcut = "$BranchName AL Compile-NavContainerProjectApps ($(Split-Path $AppProjectFolder -Leaf)).lnk"
		$DestinationShortcut = "AL Compile-NavContainerProjectApps ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Compile-NavContainerProjectApps.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Compile-NavContainerProjectApps VS Code task
		Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL Compile-NavContainerProjectApps (Ctrl+Alt+B)" -PowerShellScriptFile "$ScriptsContainerPath\Compile-NavContainerProjectApps.ps1"
		Update-KeybindingsJson -Name "Calliope AL Compile-NavContainerProjectApps (Ctrl+Alt+B)" -Key "Ctrl+Alt+b"

		# Create Publish-NavContainerProjectApps Shortcut 
		$OldDestinationShortcut = "$BranchName AL Publish-NavContainerProjectApps ($(Split-Path $AppProjectFolder -Leaf)).lnk"
		$DestinationShortcut = "AL Publish-NavContainerProjectApps ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\Publish-NavContainerProjectApps.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create Publish-NavContainerProjectApps VS Code task
		Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL Publish-NavContainerProjectApps (Ctrl+Alt+P)" -PowerShellScriptFile "$ScriptsContainerPath\Publish-NavContainerProjectApps.ps1"
		Update-KeybindingsJson -Name "Calliope AL Publish-NavContainerProjectApps (Ctrl+Alt+P)" -Key "Ctrl+Alt+p"

		# Create UnPublish-NavContainerProjectApps Shortcut 
		$OldDestinationShortcut = "$BranchName AL UnPublish-NavContainerProjectApps ($(Split-Path $AppProjectFolder -Leaf)).lnk"
		$DestinationShortcut = "AL UnPublish-NavContainerProjectApps ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\UnPublish-NavContainerProjectApps.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create UnPublish-NavContainerProjectApps VS Code task
		Update-TasksJson -ProjectFolder $AppProjectFolder -Group "build" -Name "Calliope AL UnPublish-NavContainerProjectApps (Ctrl+Alt+U)" -PowerShellScriptFile "$ScriptsContainerPath\UnPublish-NavContainerProjectApps.ps1"
		Update-KeybindingsJson -Name "Calliope AL UnPublish-NavContainerProjectApps (Ctrl+Alt+U)" -Key "Ctrl+Alt+u"

		# Create RunTests-NavContainerProjectApps Shortcut 
		$OldDestinationShortcut = "$BranchName AL RunTests-NavContainerProjectApps ($(Split-Path $AppProjectFolder -Leaf)).lnk"
		$DestinationShortcut = "AL RunTests-NavContainerProjectApps ($NAVContainerName Docker container).lnk"
		if (Test-Path "$DesktopALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopALContainerPath\$OldDestinationShortcut" -Force }
        if (Test-Path "$DesktopCALContainerPath\$OldDestinationShortcut") { Remove-Item -Path "$DesktopCALContainerPath\$OldDestinationShortcut" -Force }
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$DesktopALContainerPath\$DestinationShortcut"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "powershell.exe"
		$ShortCut.Arguments = "-ExecutionPolicy Bypass -File ""$ScriptsContainerPath\RunTests-NavContainerProjectApps.ps1"""
		$ShortCut.WindowStyle = 1
		$ShortCut.IconLocation = "$IconsPath\PowerShell.ico"
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
		[System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)

		# Create RunTests-NavContainerProjectApps VS Code task
		Update-TasksJson -ProjectFolder $AppProjectFolder -Group "test" -Name "Calliope AL RunTests-NavContainerProjectApps (Ctrl+Alt+T)" -PowerShellScriptFile "$ScriptsContainerPath\RunTests-NavContainerProjectApps.ps1"
		Update-KeybindingsJson -Name "Calliope AL RunTests-NavContainerProjectApps (Ctrl+Alt+T)" -Key "Ctrl+Alt+t"
	}
}

Function Create-LaunchJson {
    Param(
		[string] $ProjectFolder
    )

	$LaunchJsonContent = "{
    ""version"":  ""0.2.0"",
    ""configurations"":  [
                       ]
}
"

	$WorkspaceFile = "$ProjectFolder\$(Split-Path $ProjectFolder -Leaf).code-workspace"
	if (Test-Path $WorkspaceFile)
	{
		$WorkspaceJson = Get-Content $WorkspaceFile | ConvertFrom-Json
		foreach ($Folder in $WorkspaceJson.folders)
		{
			if ((Get-ChildItem "$ProjectFolder\$($Folder.path)\launch.json" -Recurse) -eq $null)
			{
				$LaunchJsonFile = "$ProjectFolder\$($Folder.path)\.vscode\launch.json"
				Write-Host "Creating $LaunchJsonFile"
				$null = New-Item -ItemType "directory" -Path (Split-Path $LaunchJsonFile) -Force
        		Set-Content -Path $LaunchJsonFile -Value $LaunchJsonContent -Force
			}
		}
	}
	else
	{
		$AppFolders = @()
		Get-ChildItem "$ProjectFolder\app.json" -Recurse | ForEach-Object {
			$AppFolders += $_.DirectoryName
		}
		foreach($AppFolder in $AppFolders)
		{
			$LaunchJsonFile = "$AppFolder\.vscode\launch.json"
			Write-Host "Creating $LaunchJsonFile"
			$null = New-Item -ItemType "directory" -Path (Split-Path $LaunchJsonFile) -Force
			Set-Content -Path $LaunchJsonFile -Value $LaunchJsonContent -Force
		}
	}
}

Function Update-LaunchJson {
    Param(
        [string] $Name,
        [string] $Server,
        [int] $Port = 7049,
        [string] $ServerInstance = "NAV",
		[string] $Auth,
		[string] $ProjectFolder,
		[string] $NAVVersionFolder
    )
    if ([int]$NAVVersionFolder -gt [int]"110") # "breakOnError" works only with BC AL Language extension (ms-dynamics-smb.al) and doesn't work with NAV AL Language extension (microsoft.al)
	{
		$LaunchSettings = [ordered]@{ "type" = "al"
									  "request" = "launch"
									  "name" = "$Name" 
									  "server" = "$Server"
									  "serverInstance" = $ServerInstance
									  "port" = $Port
									  "tenant" = ""
									  "authentication" =  $Auth
									  "breakOnError" = $true
		}
	} 
	else
	{
		$LaunchSettings = [ordered]@{ "type" = "al"
									  "request" = "launch"
									  "name" = "$Name" 
									  "server" = "$Server"
									  "serverInstance" = $ServerInstance
									  "port" = $Port
									  "tenant" = ""
									  "authentication" =  $Auth
		}
	}
    
    Get-ChildItem $ProjectFolder -Directory -Recurse | ForEach-Object {
        $Folder = $_.FullName
        $LaunchJsonFile = Join-Path $Folder "launch.json"
        if (Test-Path $LaunchJsonFile) 
		{
            Write-Host "Updating $launchJsonFile"
            $LaunchJson = Get-Content $LaunchJsonFile | ConvertFrom-Json
            $LaunchJson.configurations = @($LaunchJson.configurations | Where-Object { $_.name -ne $Launchsettings.name })
            $LaunchJson.configurations += $LaunchSettings
            $LaunchJson | ConvertTo-Json -Depth 10 | Set-Content $LaunchJsonFile
        }
    }
}

Function Create-TasksJson {
    Param(
		[string] $ProjectFolder
    )

	$TasksJsonContent = "{
    ""version"":  ""2.0.0"",
    ""tasks"":  [
                       ]
}
"

	$WorkspaceFile = "$ProjectFolder\$(Split-Path $ProjectFolder -Leaf).code-workspace"
	if (Test-Path $WorkspaceFile)
	{
		$WorkspaceJson = Get-Content $WorkspaceFile | ConvertFrom-Json
		foreach ($Folder in $WorkspaceJson.folders)
		{
			$TasksJsonFile = "$ProjectFolder\$($Folder.path)\.vscode\tasks.json"
			Write-Host "Creating $TasksJsonFile"
			$null = New-Item -ItemType "directory" -Path (Split-Path $TasksJsonFile) -Force
        	Set-Content -Path $TasksJsonFile -Value $TasksJsonContent -Force
			break
		}
	}
	else
	{
		$AppFolders = @()
		Get-ChildItem "$ProjectFolder\app.json" -Recurse | ForEach-Object {
			$AppFolders += $_.DirectoryName
		}
		foreach($AppFolder in $AppFolders)
		{
			if (!(Test-Path "$AppFolder\.vscode\tasks.json"))
			{
				$TasksJsonFile = "$AppFolder\.vscode\tasks.json"
				Write-Host "Creating $TasksJsonFile"
				$null = New-Item -ItemType "directory" -Path (Split-Path $TasksJsonFile) -Force
				Set-Content -Path $TasksJsonFile -Value $TasksJsonContent -Force
			}
		}
	}
}

Function Update-TasksJson {
    Param(
		[string] $Group,
		[string] $ProjectFolder,
		[string] $Name,
		[string] $PowerShellScriptFile
    )
	$TaskArgs = @("-ExecutionPolicy","Unrestricted","-NoProfile","-File","'$PowerShellScriptFile'")
	$TaskPresentation = [ordered]@{ "echo" = $true
									 "reveal" = "always"
									 "focus" = $true
									 "panel" = "new"
									 "showReuseMessage" = $true
		                             "clear" = $false
	}

	$TaskSettings = [ordered]@{ "label" = "$Name"
								"type" = "shell"
								"command" = "PowerShell" 
								"problemMatcher" = "`$go"
								"group" = "$Group"
								"args" = $TaskArgs
								"presentation" = $TaskPresentation
	}
    Get-ChildItem $ProjectFolder -Directory | ForEach-Object {
        $Folder = $_.FullName
        $TasksJsonFile = Join-Path $Folder ".vscode\tasks.json"
        if (Test-Path $TasksJsonFile) 
		{
            Write-Host "Updating $TasksJsonFile"
            $TasksJson = Get-Content $TasksJsonFile | ConvertFrom-Json
            $TasksJson.tasks = @($TasksJson.tasks | Where-Object { $_.label -ne $TaskSettings.label })
            $TasksJson.tasks += $TaskSettings
            $TasksJson | ConvertTo-Json -Depth 10 | Set-Content $TasksJsonFile
        }
    }
}

Function Update-KeybindingsJson {
    Param(
		[string] $Name,
		[string] $Key
    )
	$File = "$($env:APPDATA)\Code\User\keybindings.json"
	$Command = "workbench.action.tasks.runTask"

	$NewKeybinding = [ordered]@{ "key" = "$Key"
					   "command" = "$Command"
					   "args" = "$Name"
					   "when" = "alExtensionActive"
  	}


	if (Test-path $File)
	{
		$KeybindingJson = (Get-Content $File) -replace '^\s*//.*' | Out-String | ConvertFrom-Json
	} else
	{
		$KeybindingJson = @()
	}
	if (!$KeybindingJson.Count)
	{
	   $Temp = $KeybindingJson.PSObject.Copy()
	   $KeybindingJson = @()
	   $KeybindingJson += $Temp
	}
	$Keybinding = @($KeybindingJson | Where-Object { $_.command -eq $NewKeybinding.Command -and $_.args -eq $NewKeybinding.args })
	if (!$Keybinding)
	{
		$KeybindingJson += $NewKeybinding
		$KeybindingJson | ConvertTo-Json -Depth 10 | Set-Content $File
	}
}

Function Create-SettingsJson {
    Param(
		[string] $ProjectFolder,
		[String] $ContainerName
    )

	$dotnetAssembliesFolder = "C:\ProgramData\NavContainerHelper\Extensions\$ContainerName\.netPackages"

	$SettingsJson = @{
        "al.enableCodeAnalysis" = $false
        "al.enableCodeActions" = $false
        "al.incrementalBuild" = $true
        "al.packageCachePath" = ".alpackages"
        "al.assemblyProbingPaths" = @(".netpackages", $dotnetAssembliesFolder, "C:\Windows\Microsoft.NET\assembly", "..\Baseline\Add-Ins")
        "editor.codeLens" = $false
		"CRS.OnSaveAlFileAction" ="DoNothing"
    }

	$WorkspaceFile = "$ProjectFolder\$(Split-Path $ProjectFolder -Leaf).code-workspace"
	if (Test-Path $WorkspaceFile)
	{
		$WorkspaceJson = Get-Content $WorkspaceFile | ConvertFrom-Json
		foreach ($Folder in $WorkspaceJson.folders)
		{
			if ($Folder.path -eq "Base")
			{
				$SettingsJsonFile = "$ProjectFolder\$($Folder.path)\.vscode\settings.json"
				Write-Host "Creating $SettingsJsonFile"
				$null = New-Item -ItemType "directory" -Path (Split-Path $SettingsJsonFile) -Force
        		Set-Content -Path $SettingsJsonFile -Value ($SettingsJson | ConvertTo-Json -Depth 10) -Force
			}
		}
	}
	else
	{
		$AppFolders = @()
		Get-ChildItem "$ProjectFolder\app.json" -Recurse | ForEach-Object {
			$AppFolders += $_.DirectoryName
		}
		foreach($AppFolder in $AppFolders)
		{
			if ((Split-Path $AppFolder -leaf) -eq "Base")
			{
				$SettingsJsonFile = "$AppFolder\.vscode\settings.json"
				Write-Host "Creating $SettingsJsonFile"
				$null = New-Item -ItemType "directory" -Path (Split-Path $SettingsJsonFile) -Force
				Set-Content -Path $SettingsJsonFile -Value ($SettingsJson | ConvertTo-Json -Depth 10) -Force
			}
		}
	}
}