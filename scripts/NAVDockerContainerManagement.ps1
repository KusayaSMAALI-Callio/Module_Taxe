<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : 3Li Business Solutions
Description  : Functions for NAV Docker container management
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies :
------------------------------------------------------------------------------------------------------------------
Revisions    : 09/10/2019 : PMN : Initial version
               13/11/2019 : PMN : Adaptations for BaseApp
			   14/11/2019 : PMN : Fix Create-NavContainer for CALAL projects and AL containers < BC 15.x
			   14/11/2019 : PMN : Fix Compile-NavContainerProjectApps for containers <> BC
			   21/11/2019 : PMN : Add assignPremiumPlan to container creation
			   21/11/2019 : PMN : Implement ruleset.json in Compile-NavContainerProjectApps
			   22/11/2019 : PMN : Add Get-NavContainerBaseAppSource
			   26/11/2019 : PMN : Fix compile.log analysing (error on app.json file)
			   26/11/2019 : PMN : Fix containername in Generate-NavContainerSymbolReference
			   04/12/2019 : PMN : Fix Sync-NavContainerTenant add param Mode
			   05/12/2019 : PMN : Fix license expiration in old container images (force licensefile param at container creation)
			   07/12/2019 : PMN : Doesn't create container with baseline database if $BranchName is Core
               17/12/2019 : PMN : Fix NAVVersionFolder conversion to int
               #11025 : 27/02/2020 : PMN : Add $ArtifactFolder parameter for AL builds
			   #11025 : 27/02/2020 : PMN : Add $EnablePerTenantExtensionCop parameter for AL compilation
			   #11498 : 19/03/2020 : PMN : Fix flag modified cleaned in container creation with baseline database 
			   #11553 : 24/03/2020 : PMN : Add param $AppIdsToProcess for AL compilation, signing and publishing
			   #11134 : 25/03/2020 : PMN : Fix Get-TestsFromNavContainer with try/catch
			   #11624 : 30/03/2020 : PMN : Add Invoke-DockerLogin (for BC next minor and major on bcinsider.azurecr.io)
			   #11677 : 31/03/2020 : PMN : Adaptations for BaseApp (especially for CMC BC15)
                                           - Allow App renaming (name and publisher) also for all Apps
										   - Unpublish and Clean Apps based on Id (before based on Name)
                                           - Use Replace-DependenciesInAppFile in MS Apps dependent on BaseApp for BaseApp renaming
                                           - Add ForceSync option for Publishing/Installing App (especially for CMC BC15 BaseApp (DataPerCompany property modified))
                                           - Add Start-NavAppDataUpgrade automatic management when App install failed
                                           - Add param BaseAppDependencyAppIdsToNotRepublish for not republish some BaseApp dependent Apps (especialy for AMC Banking not compatible with CMC BC15 BaseApp (DataPerCompany property modified))
										   - Add param BaseAppDependenciesArtifactFolder to copy BaseApp dependent Apps modified in artifact folder (in case of BaseApp renaming)
               #11198 : 13/04/2020 : PMN : Add XmlBuildScripts management
			   #12584 : 28/04/2020 : PMN : Fix tests not found in Get-TestsFromNavContainer
			   #12752 : 05/05/2020 : PMN : Fix add volume for Add-ins if folder doesn't exist
			   #13051 : 21/05/2020 : PMN : Fix BC breaking change in App depencies with the new Microsoft Application App (for BaseApp projects)
			   #13292 : 09/06/2020 : PMN : Fix Install-NavContainerAppDependencies for BaseAppDependencyAppIdsToNotRepublish exceptions (for BaseApp projects)
               #12756 : 23/06/2020 : PMN : Add LicenseType (Premium, Essentials) management
			   #14116 : 07/07/2020 : PMN : Add BC artifacts management (BC Docker images replacement)
			   #14189 : 15/07/2020 : PMN : Add param $DisableTaskScheduler to Create-NavContainer
			   #14115 : 18/07/2020 : PMN : Add copy app.json of compiled apps to build artifact folder
			   #14419 : 24/07/2020 : PMN : Replace Gb by GB
			   #14665 : 24/07/2020 : PMN : Disable AppSourceCop if OnPrem target
			   #170 : 16/09/2020 : PMN : Disable AppSourceCop if Test App (dependency to Library Assert)
			   #212 : 14/10/2020 : PMN : Fix install in container new version of App, BaseApp and reinstall uninstalled Apps
			   #243 : 02/11/2020 : PMN : Add param $CopyToFolder to Run-XmlBuildScripts (to replace $CopyToPath variable in BuildLocalInstallScripts node)
			   #253 : 11/11/2020 : PMN : Fix (workarround) NavContainetHelper issue in New-NavContainer with -includeTestToolkit for BC18 containers
			   #255 : 12/11/2020 : PMN : BcContainerHelper migration preparation
			   #86 : 12/11/2020 : PMN : Add Clean-ContainerHelperCache (clean artifacts cache)
			   #258 : 15/11/2020 : PMN : Fix (workarround) NavContainetHelper issue in New-NavContainer with -includeTestToolkit for containers BC >= 17.2
			   #259 : 15/11/2020 : PMN : Adaptations for BC17 BaseApp (MS Application App cannot be unpublished and MS Base Application App cannot be renammed)
			   #429 : 30/12/2020 : PMN : Fix Sign-NavContainerApp (https://github.com/microsoft/navcontainerhelper/issues/1579)
			   #430 : 02/03/2021 : PMN : Migration to BcContainerHelper
			   #4254 : 18/10/2021 : PMN : Set Docker container default isolation to hyperv
			   #4224 : 18/10/2021 : PMN : Set Docker container Dns to 8.8.8.8
			   #3506 : 20/10/2021 : PMN : Improve error return for DevOps
			   #3480 : 23/10/2021 : PMN : Add param ArtifactType to Run-XmlBuildScripts (for dependencies management with multiple artifact types)
			   #3480 : 23/10/2021 : PMN : Add param DoNotIncludeTests to Create-NavContainer
			   #3480 : 23/10/2021 : PMN : Add function Clean-NavContainerExternalDependencyApps (for dependencies management with multiple artifact types)
			   #4474 : 03/11/2021 : PMN : Add function Get-NavContainerAppFileInfo (for dependencies management with multiple artifact types)
			   #4680 : 17/01/2022 : PMN : Rollback set Docker container default isolation to process (bugs fixed in BCContainerHelper 2.0.17)
			   #5218 : 18/01/2022 : PMN : Fix Clean-NavContainerExternalDependencyApps if $ExternalDependenciesAppsJsonPath folder doesn't exist
------------------------------------------------------------------------------------------------------------------
#>

Function Display-NavDockerContainers
{
	Write-host "Display-NAVDockerContainers" -ForegroundColor Yellow
	Write-host "Docker images downloaded" -ForegroundColor Yellow
	docker images
	Write-host ""

	$Containers = (docker ps -a).Split("`n").Trim("`r")
	foreach ($Index in 0..$Containers.GetUpperBound(0))
	{
	    $Containers[$Index] = $Containers[$Index] -replace ',',';' -replace '\s{2,}', ','
	}
	$DockerPSA_Objects = $Containers |  ConvertFrom-Csv
	Write-Host "Docker containers created" -ForegroundColor Yellow
	Write-Host "$("CONTAINER NAME".PadRight(15))`t$("STATUS".PadRight(25))`t$("IMAGE / REPOSITORY")"
	foreach($DockerPSA_Object in $DockerPSA_Objects)
	{
	    if ($DockerPSA_Object.NAMES -ne $null) {
		    Write-Host "$($DockerPSA_Object.NAMES.PadRight(15))`t$($DockerPSA_Object.STATUS.PadRight(25))`t$($DockerPSA_Object.IMAGE)"
		} else {
	        Write-Host "$($DockerPSA_Object.PORTS.PadRight(15))`t$("Stopped".PadRight(25))`t$($DockerPSA_Object.IMAGE)"
		}
	}
	Write-host ""
}

Function Get-NavContainerDatabaseName
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName
    )
    # Get Nav container server configuration
    $NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $ContainerName
	return $NavContainerServerConfiguration.DatabaseName
}

Function Install-NavContainerHelper
{
	$Module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
	if ($Module) {
		Write-Warning "NavContainerHelper is installed but doesn't work anymore. It will be removed."
		Write-Host "Removing NavContainerHelper..."
		Uninstall-Module -Name NavContainerHelper -AllVersions -Force
		Write-Host "NavContainerHelper is removed. Restart the script (BcContainerHelper will be installed)..."
		[void](Read-Host 'Press [Enter] to exit...')
        Exit
	}
	$ModuleName = "BcContainerHelper"
	$Module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
	if ($Module) 
	{
		$VersionStr = $Module.Version.ToString()
		Write-Host "$ModuleName $VersionStr is installed"
		$OnlineModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue
		if ($OnlineModule) 
		{
			$LatestVersion = $OnlineModule.Version 
			$NavContainerHelperVersion = $LatestVersion.ToString()
			Write-Host "$ModuleName $NavContainerHelperVersion is the latest version"
			if ($NavContainerHelperVersion -ne $Module.Version) 
			{
				Write-Host "Updating $ModuleName to $NavContainerHelperVersion"
				Update-Module -Name $ModuleName -Force -RequiredVersion $NavContainerHelperVersion
				Write-Host "$ModuleName updated"
			}
		} else {
			Write-Warning "Unable to check online latest version of $ModuleName (check Internet connectivity)"
		}
	} 
	else 
	{
		if (!(Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
			Write-Host "Installing NuGet Package Provider"
			Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -WarningAction SilentlyContinue | Out-Null
		}
		Write-Host "Installing $ModuleName"
		Install-Module -Name $ModuleName -Force
		$Module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
		$VersionStr = $Module.Version.ToString()
		Write-Host "$ModuleName $VersionStr installed"
	}
	$BcContainerHelperConfigFile = "C:\ProgramData\BcContainerHelper\BcContainerHelper.config.json"
	$UpdateBcContainerHelperConfig = $false
	if (Test-Path $BcContainerHelperConfigFile) 
	{
		$BcContainerHelperConfigJson = Get-Content $BcContainerHelperConfigFile | ConvertFrom-Json
		if ($BcContainerHelperConfigJson.hostHelperFolder -ne "C:\ProgramData\NavContainerHelper")
		{
			Write-Warning "Setting value for hostHelperFolder in $BcContainerHelperConfigFile is not compatible with old containers and scripts. The setting is changed to ""C:\ProgramData\NavContainerHelper"""
			Copy-Item $BcContainerHelperConfigFile -Destination "$BcContainerHelperConfigFile.old" -Force
			$UpdateBcContainerHelperConfig = $true
		}
		if ($BcContainerHelperConfigJson.containerHelperFolder -ne "C:\ProgramData\NavContainerHelper")
		{
			Write-Warning "Setting value for containerHelperFolder in $BcContainerHelperConfigFile is not compatible with old containers and scripts. The setting is changed to ""C:\ProgramData\NavContainerHelper"""
			Copy-Item $BcContainerHelperConfigFile -Destination "$BcContainerHelperConfigFile.old" -Force
			$UpdateBcContainerHelperConfig = $true
		}
		if ($BcContainerHelperConfigJson.sandboxContainersAreMultitenantByDefault -eq $null -or $BcContainerHelperConfigJson.sandboxContainersAreMultitenantByDefault -ne $false )
		{
			Write-Warning "Setting value for sandboxContainersAreMultitenantByDefault in $BcContainerHelperConfigFile is not compatible with old containers and scripts. The setting is changed to ""False"""
			Copy-Item $BcContainerHelperConfigFile -Destination "$BcContainerHelperConfigFile.old" -Force
			$UpdateBcContainerHelperConfig = $true
		}
	} else { $UpdateBcContainerHelperConfig = $true}
	if ($UpdateBcContainerHelperConfig)
	{
		$BcContainerHelperConfigJsonContent = "{
	""hostHelperFolder"":  ""C:\\ProgramData\\NavContainerHelper"",
	""containerHelperFolder"":  ""C:\\ProgramData\\NavContainerHelper"",
	""sandboxContainersAreMultitenantByDefault"": false
}"
		Write-Host "Update $BcContainerHelperConfigFile"
		New-Item -Path (Split-Path $BcContainerHelperConfigFile -Parent) -ItemType Directory -Force | Out-Null
		Set-Content -Path $BcContainerHelperConfigFile -Value $BcContainerHelperConfigJsonContent -Force
		Write-Host "$BcContainerHelperConfigFile has been updated"
	}
}

Function Sync-NavContainerTenant
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$Mode
    )
	# Get NAV container server configuration
    $NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $ContainerName
	
	# Sync-NavTenant in NAV container
	Write-Host "Sync-NavTenant in $ContainerName ($Mode)"
	$StartTime = (Get-Date)
	Invoke-ScriptInNavContainer -containerName $ContainerName -ArgumentList ($NavContainerServerConfiguration.ServerInstance,$Mode) -ScriptBlock {
		param($NAVServiceInstance,$Mode)
		Get-NAVTenant $NAVServiceInstance | Sync-NavTenant -Mode $Mode -Force
	}
	$Elapsed = (Get-Date)-$StartTime
	Write-Host "The command completed in $([math]::Round($Elapsed.TotalSeconds)) seconds."
	Write-Host "Tenant successfully synchronized" -ForegroundColor Green
}

Function Generate-NavContainerSymbolReference
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName
    )

	# Generate Symbols in NAV container
	Generate-SymbolsInNavContainer -ContainerName $ContainerName

	# Get NAV container server configuration
    $NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $ContainerName

	# Restart Nav service in NAV container
	Write-Host "Restart NAV service ($($NavContainerServerConfiguration.ServerInstance))"
	Invoke-ScriptInNavContainer -containerName $ContainerName  -ArgumentList ($NavContainerServerConfiguration.ServerInstance) -ScriptBlock {
		param($NAVServiceInstance)
		Set-NavServerInstance -ServerInstance $NAVServiceInstance -Restart
	}
}

Function Clean-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder
    )

	# Clean AL project Apps in NAV container

	# Get AL project Apps folders
	$AppFolders = @()
	Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
	    $AppFolders += $_.DirectoryName
	}

	# Get NAV container server configuration
    $NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $ContainerName

	# Loop AL project Apps by dependencies (descending)
	$AppFolders = Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue
    [Array]::Reverse($AppFolders)
	$AppFolders | % {
		# Get App name
		$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
		$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
		Write-Host "Clean App $AppFile" -ForegroundColor Cyan
		# Get Apps in container with Id of App
		$Apps = Get-NavContainerAppInfo -ContainerName $ContainerName | Where AppId -eq $AppJson.Id | ForEach-Object {
		    $App = $_
			if ($App) {
				# Unsinstall App with not saving data
				UnInstall-NavContainerApp -containerName $ContainerName -appName $AppJson.Name -doNotSaveData -Force -ErrorAction SilentlyContinue
	
				# Sync App clean 
				Write-Host "Synchronizing $($AppJson.Name) (Clean)"
				Invoke-ScriptInNavContainer -ContainerName $ContainerName -argumentList ($AppJson.Name, $NavContainerServerConfiguration.ServerInstance) -scriptblock {
					Param($AppName, $NAVServiceInstance)
					Sync-NAVApp -ServerInstance $NAVServiceInstance -Name $AppName -Mode Clean -Force
				}
				Write-Host -ForegroundColor Green "App successfully synchronized"
			
				# Unpublish App with not saving data
				UnPublish-NavContainerApp -containerName $ContainerName -appName $AppJson.Name -Force -doNotSaveData

				# Sync tenant
				Sync-NavContainerTenant -ContainerName $ContainerName -Mode ForceSync
			}
		}
	}
}

Function Compile-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$User="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$Password="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$DevOps,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[ValidateSet("none","error","warning")]
	[string]$FailOn="error",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$EnableAppSourceCop,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$EnablePerTenantExtensionCop,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ArtifactFolder="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$AppIdsToProcess
    )
	# Compil AL project Apps in NAV container

	# Clean Output folder
	if (Test-Path "$AppProjectFolder\.output") { Remove-Item "$AppProjectFolder\.output" -Force -Recurse }
	New-Item -Path "$AppProjectFolder\.output" -ItemType Directory -Force | Out-Null
	if (Test-Path "$AppProjectFolder\.alpackages") { Remove-Item "$AppProjectFolder\.alpackages" -Force -Recurse }
	New-Item -Path "$AppProjectFolder\.alpackages" -ItemType Directory -Force | Out-Null

	# Initialize
	$Parameters = @{}
	if ($User -ne "") { $Parameters += @{"credential" = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))}}

	# Get AL project Apps folders
	$AppFolders = @()
	Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
	    $AppFolders += $_.DirectoryName
	}
	$HasError = $false
	if ($AppFolders.Count -eq 0)
	{
		$HasError = $true
		Write-Error "ERROR : No app.json found in $AppProjectFolder folder and subfolders!"
	}
	else
	{
		# Loop AL project Apps by dependencies 
		Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue | ForEach-Object {
			if (!$HasError)
			{
				# Get App.json
				$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
				$AppJsonFile = "$_\app.json"

				if ($AppIdsToProcess -eq "" -or $AppIdsToProcess.Contains($AppJson.id))
				{
					$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
					$AppDependenciesFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).dep.app"

					# Set Code analyzers
					$EnableCodeCop = $true
					$EnableUICop = (-not ((Get-NavContainerNavVersion -containerOrImageName $ContainerName) -lt 12))  # UICop analyzer is not available for NAV containers (only BC)                                                
					if ($EnableAppSourceCop -and ($AppJson.target -eq "OnPrem" -or $AppJson.target -eq "Internal")) 
					{ 
						# AppSourceCop must be disabled for OnPrem target
						$EnableAppSourceCop = $false 
						Write-Warning "Code analyzer AppSourceCop is disabled for OnPrem target"
					}
					if  (($AppJson.dependencies | Where-Object {$_.name -eq "Library Assert" }) -ne $null)
					{
						# AppSourceCop must be disabled for Test Apps
						$EnableAppSourceCop = $false 
						Write-Warning "Code analyzer AppSourceCop is disabled for Test App"
					}
					#$EnablePerTenantExtensionCop = ($AppJson.target -eq "OnPrem" -or $AppJson.target -eq "Internal")
					if ((Split-Path $_ -leaf) -eq "Base")
					{
						Write-Warning "Code analyzers are disabled for BaseApp"
						$EnableCodeCop = $false
						$EnableUICop = $false
						$EnableAppSourceCop = $false
						$EnablePerTenantExtensionCop = $false
					}

					# Get first ruleset.json found
					$RulesetFile = $null
					Get-ChildItem "$_\*.ruleset.json"  | ForEach-Object {
						$RulesetFile = $_
						return
					}

					# Compile App
					Write-Host "Compile App $AppFile"
					$HasError = $false
					if ($DevOps)
					{
						Compile-AppInNavContainer @Parameters -containerName $ContainerName -appProjectFolder $_ -appOutputFolder "$AppProjectFolder\.output" -appSymbolsFolder "$AppProjectFolder\.alpackages" -EnableCodeCop:$EnableCodeCop -EnableUICop:$EnableUICop -EnableAppSourceCop:$EnableAppSourceCop -EnablePerTenantExtensionCop:$EnablePerTenantExtensionCop -rulesetFile $RulesetFile -FailOn $FailOn -AzureDevOps
					}
					else
					{
						Compile-AppInNavContainer @Parameters -containerName $ContainerName -appProjectFolder $_ -appOutputFolder "$AppProjectFolder\.output" -appSymbolsFolder "$AppProjectFolder\.alpackages" -EnableCodeCop:$EnableCodeCop -EnableUICop:$EnableUICop -EnableAppSourceCop:$EnableAppSourceCop -EnablePerTenantExtensionCop:$EnablePerTenantExtensionCop -rulesetFile $RulesetFile -ErrorAction SilentlyContinue *> "$AppProjectFolder\.output\Compile.log"
						$WriteCompilationLineOutput=$false
						$ForegroundColor = "White"
						foreach($Line in Get-Content "$AppProjectFolder\.output\Compile.log") {
							if ($Line.StartsWith("Compilation started") -or $Line.StartsWith("error") -or $Line.Contains(": error AL")) { $WriteCompilationLineOutput = $true }
							if ($Line.StartsWith("Compilation ended"))  { $WriteCompilationLineOutput = $false }
							if ($WriteCompilationLineOutput)
							{
								if ($Line -ne "")
								{
									switch -regex ($Line) {
										"^warning (\w{2}\d{4}):(.*('.*').*|.*)$" {
											$ForegroundColor = "Yellow"
											break
										}
										"^(.*)\((\d+),(\d+)\): error (\w{2,3}\d{4}): (.*)$" {
											$ForegroundColor = "Red"
											$HasError = $true
											break
										}
										"^(.*)error (\w{2}\d{4}): (.*)$" {
											$ForegroundColor = "Red"
											$HasError = $true
											break
										}
										"^(.*)\((\d+),(\d+)\): warning (\w{2}\d{4}): (.*)$" {
											$ForegroundColor = "Yellow"
											break
										}
									}
									Write-Host $Line -ForegroundColor $ForegroundColor
								}
							}
						}
						Remove-Item "$AppProjectFolder\.output\Compile.log" -Force
					}
					if ($HasError) 
					{ 
						Write-Host "App $($AppJson.Name) compilation failed!" -ForegroundColor Red } 
					else { 
						Write-Host "App $($AppJson.Name) compilation succeeded!" -ForegroundColor Green
						Write-Host "Wait for output compiled App..."
						$WaitTimeoutSeconds = 0
						while (!(Test-Path "$AppProjectFolder\.output\$AppFile") -and $WaitTimeoutSeconds -le 30  ) { 
							Sleep -Seconds 1 
							$WaitTimeoutSeconds++
						}
						if (Test-Path "$AppProjectFolder\.output\$AppFile") { 
							Write-Host "Copy compiled App to project folders..."
							New-Item -Path "$_\.alpackages" -ItemType Directory -Force | Out-Null
							if ($AppProjectFolder -ne $_) { Copy-Item -Path "$AppProjectFolder\.alpackages\*.app" -Destination "$_\.alpackages\" -Force }
							if (Test-Path "$_\.alpackages\$AppFile") { Remove-Item "$_\.alpackages\$AppFile" -Force }
							Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$AppProjectFolder\.alpackages\$AppFile" -Force 
							Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$_\$AppFile" -Force
							if (Test-Path "$_\$AppDependenciesFile") { Remove-Item "$_\$AppDependenciesFile" -Force}
							if ($ArtifactFolder -ne "")
							{
								Write-Host "Copy compiled App to $ArtifactFolder ..."
								New-Item -Path "$ArtifactFolder" -ItemType Directory -Force | Out-Null
								Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$ArtifactFolder\$AppFile" -Force
								Write-Host "Copy App.json of compiled App to $ArtifactFolder ..."
								Copy-Item -Path $AppJsonFile -Destination "$ArtifactFolder\$((Get-Item "$ArtifactFolder\$AppFile").BaseName).json" -Force
							}
						}
						else
						{
							Write-Host "Error while downloading generating App. Try to restart the container..." -ForegroundColor Red
							$HasError = $true
						}
						#if ($_ -ne $AppFolders[$AppFolders.Length-1]) {
							#Write-Host "Wait 30s for next App compilation..."
							#Sleep -Seconds 30
						#}
					}
				}
			}
		}
	}
	return (!$HasError)
}

Function Publish-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$User="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$Password="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$UseDevEndpoint,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$SkipVerification,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$AppIdsToProcess,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$ForceSync,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$BaseAppDependenciesArtifactFolder="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$BaseAppDependencyAppIdsToNotRepublish=""
    )

	# Publish AL project Apps in NAV container

	# Initialize
	$Parameters = @{}
	if ($User -ne "") { $Parameters += @{"credential" = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))}}

	# Get AL project Apps folders
	$AppFolders = @()
	Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
	    $AppFolders += $_.DirectoryName
	}

	# Loop AL project Apps by dependencies
	Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue | ForEach-Object {
		$AppFolder = $_
		# Get App.json
		$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
		if ($AppIdsToProcess -eq "" -or $AppIdsToProcess.Contains($AppJson.id))
		{
			$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
            if ($ForceSync) { $SyncMode = "ForceSync" } else { $SyncMode  = "Add" }
            if ($UseDevEndpoint) { $Scope = "Tenant" } else { $Scope = "Global" }
            Write-Host "Publish App $AppFile (Scope $Scope, SyncMode $SyncMode)" -ForegroundColor Cyan
            try
            {
                Publish-NavContainerApp @Parameters -containerName $ContainerName -appFile "$AppFolder\$AppFile" -install -sync -syncMode $SyncMode -skipVerification:$SkipVerification -useDevEndpoint:$UseDevEndpoint -scope $Scope
            }
            catch
            {
                if ($_.Exception.Message -eq "Status Code 422 : Unprocessable Entity")
                {
                    Write-Warning "Error : $($_.Exception.Message) (check error detail by republishing App from VS Code). App cannot be published/installed."
                    if (!$ForceSync)
                    {
                        Write-Warning "You do want to republish/install App with forcing schema synchronization ?"
                        $Confirm = Read-Host "[Y/N] ?"
                        $ForceSync = ($Confirm -eq "Y")
                    }
                    if ($ForceSync)
                    {
                        if (Get-NavContainerAppInfo -containerName $ContainerName -appName $AppJson.Name)
                        {
                            UnPublish-NavContainerApp -containerName $ContainerName -appName $AppJson.Name -unInstall -ErrorAction SilentlyContinue *> $null
                        }
                        try
                        {
                            Publish-NavContainerApp @Parameters -containerName $ContainerName -appFile "$AppFolder\$AppFile" -install -sync -syncMode "ForceSync" -skipVerification:$SkipVerification -useDevEndpoint:$UseDevEndpoint -scope $Scope
                        }
                        catch
                        {
                            if (Get-NavContainerAppInfo -containerName $ContainerName -appName $AppJson.Name)
                            {
                                Start-NavContainerAppDataUpgrade -containerName $ContainerName -appName $AppJson.Name -appVersion $AppJson.Version
                            }
                        }
                    }
                }
                elseif (Get-NavContainerAppInfo -containerName $ContainerName -appName $AppJson.Name)
                {
                    Start-NavContainerAppDataUpgrade -containerName $ContainerName -appName $AppJson.Name -appVersion $AppJson.Version
                }
                else
                {
                    Write-Error "$($_.Exception.Message). App cannot be published/installed."
                }
            } 
			if ((Split-Path $AppFolder -leaf) -eq "Base")
			{
				if (Test-Path "$AppFolder\.unpublished\unpublishedapps.json")
				{
					Write-Warning "Reinstall/Republish Apps dependent on BaseApp (Scope $Scope)"
					$UnpublishedApps = Get-Content "$AppFolder\.unpublished\unpublishedapps.json" | ConvertFrom-Json
					foreach($UnpublishedApp in $UnpublishedApps)
					{
						if ($BaseAppDependencyAppIdsToNotRepublish.Contains($UnpublishedApp.AppId))
                        {
                            Write-Warning "$($UnpublishedApp.Name) is ignored (in BaseApp dependency Apps to not republish)..."
                        }
                        else
                        {
                            if ((Get-NavContainerNavVersion -containerOrImageName $ContainerName) -lt 17)
                            {
                                $AppDpendencyFile = Get-NavContainerAppFile -containerName $ContainerName -appName $UnpublishedApp.Name
						        if ($AppDpendencyFile)
						        {
							        $AppDpendencyFile = "$AppFolder\.unpublished\$(Split-Path $AppDpendencyFile -leaf)"
							        if (Test-Path $AppDpendencyFile) 
							        { 
                                        Publish-NavContainerApp @Parameters -containerName $ContainerName -appFile $AppDpendencyFile -install -sync -skipVerification -Scope $Scope
									    Install-NavContainerAppDependencies -ContainerName $ContainerName -AppName $UnpublishedApp.Name -AppPublisher $UnpublishedApp.Publisher -BaseAppDependencyAppIdsToNotRepublish $BaseAppDependencyAppIdsToNotRepublish
									    if ($BaseAppDependenciesArtifactFolder -ne "")
									    {
										    Write-Host "Copy $($UnpublishedApp.Name) to $BaseAppDependenciesArtifactFolder ..."
										    New-Item -Path "$BaseAppDependenciesArtifactFolder" -ItemType Directory -Force | Out-Null
										    Copy-Item -Path "$AppDpendencyFile" -Destination "$BaseAppDependenciesArtifactFolder\$(Split-Path $AppDpendencyFile -leaf)" -Force
									    }
							        }
							        else { 	Write-Error "App file not found for App name $($UnpublishedApp.Name) !" }
						        }
						        else { 	Write-Error "App file not found for App name $($UnpublishedApp.Name) !" }
                            } else { Install-NavContainerAppDependencies -ContainerName $ContainerName -AppName $UnpublishedApp.Name -AppPublisher $UnpublishedApp.Publisher -BaseAppDependencyAppIdsToNotRepublish $BaseAppDependencyAppIdsToNotRepublish }
                        }
					}
				}
			}
		}
	}
}

Function UnPublish-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$User="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$Password=""
    )

	# Clean AL project Apps in NAV container

	# Initialize
	$Parameters = @{}
	if ($User -ne "") { $Parameters += @{"credential" = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))}}

	# Get AL project Apps folders
	$AppFolders = @()
	Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
	    $AppFolders += $_.DirectoryName
	}

	# Get NAV container server configuration
    $NavContainerServerConfiguration = Get-NavContainerServerConfiguration -ContainerName $ContainerName

	# Loop AL project Apps by dependencies (descending)
	$AppFolders = Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue
    [Array]::Reverse($AppFolders)
	$AppFolders | % {
		$AppFolder = $_
		# Get App name
		$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
		$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
		Write-Host "Uninstall/Unpublish App $AppFile" -ForegroundColor Cyan
		# Get Apps in container with Id of App
		$Apps = Get-NavContainerAppInfo -ContainerName $ContainerName | Where AppId -eq $AppJson.Id | ForEach-Object {
		    $App = $_
			if ((Split-Path $AppFolder -leaf) -eq "Base")
			{
			    if ((Get-NavContainerNavVersion -containerOrImageName $ContainerName) -ge 17 -and $AppJson.Name -ne "Base Application")	{ Write-Error "Base Application cannot be renamed to $($AppJson.Name)" }
                # Uninstall/Unpublish App dependencies on BaseApp
				Write-Warning "Uninstall/Unpublish Apps dependent on BaseApp"
				$UnpublishedApps = @()
				Get-NavContainerAppInfo -containerName $ContainerName -sort DependenciesLast | ForEach-Object {
					$Dependencies = $_.Dependencies
					$Scope = $_.Scope
				    $IsBaseApplicationDependency = $false
					foreach($Dependency in $Dependencies) { if ($Dependency.Split(",")[0] -eq $App.Name) { $IsBaseApplicationDependency = $true; break} }
					if ($IsBaseApplicationDependency)
					{ 
						UnInstall-NavContainerApp -containerName $ContainerName -appName $_.Name -Force -ErrorAction SilentlyContinue
                        $UnpublishedApps += $_
                        if ((Get-NavContainerNavVersion -containerOrImageName $ContainerName) -lt 17) 
                        { 
                            UnPublish-NavContainerApp -containerName $ContainerName -appName $_.Name -force 
						    $AppDpendencyFile = Get-NavContainerAppFile -containerName $ContainerName -appName $_.Name
						    if ($AppDpendencyFile)
						    {
							    if (-not (Test-Path "$AppFolder\.unpublished\$(Split-Path $AppDpendencyFile -leaf)"))
							    {
								    $ContainerId = Get-NavContainerId -containerName $ContainerName
								    $Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
								    if (-not (Test-Path "$AppFolder\.unpublished\")) { $null = New-Item "$AppFolder\.unpublished" -ItemType Directory -Force }
								    $null = Copy-Item $AppDpendencyFile -Destination "$AppFolder\.unpublished\" -FromSession $Session -Force
								    Remove-PSSession $Session
							    }
						    }
						    else { 	Write-Error "App file not found for App name $($_.Name) !" }
                        }
					}
				}
				[Array]::Reverse($UnpublishedApps)
				if (-not (Test-Path "$AppFolder\.unpublished\")) { $null = New-Item "$AppFolder\.unpublished" -ItemType Directory -Force }
				$UnpublishedApps | ConvertTo-Json -Depth 10 | Set-Content "$AppFolder\.unpublished\unpublishedapps.json"
				# Uninstall/Unpublish BaseApp 
				UnInstall-NavContainerApp -containerName $ContainerName -appName $App.Name -Force -ErrorAction SilentlyContinue
                if ((Get-NavContainerNavVersion -containerOrImageName $ContainerName) -lt 17) { UnPublish-NavContainerApp -containerName $ContainerName -appName $App.Name -Force }
			}
			else
			{
				# Uninstall/Unpublish App 
				UnInstall-NavContainerApp -containerName $ContainerName -appName $App.Name -Force -ErrorAction SilentlyContinue
				UnPublish-NavContainerApp -containerName $ContainerName -appName $App.Name -Force
			}
		}
		if ((Split-Path $AppFolder -leaf) -eq "Base")
		{
            # Replace dependencies in App files
            $replaceDependencies = @{
                "437dbf0e-84ff-417a-965d-ed2bb9650972" = @{
                "id" = $AppJson.Id
                "name" = $AppJson.Name
                "publisher" = $AppJson.Publisher
                "minversion" = $AppJson.Version
                }
            }
            Get-ChildItem -Path "$AppFolder\.unpublished\*.App" | ForEach-Object {
                Write-Host "Replace depencies in App file $($_.Name)"
                Replace-DependenciesInAppFile -Path $_.FullName -Destination $_.FullName -replaceDependencies $replaceDependencies -containerName $ContainerName
            }
			# Restart container
			Write-Warning "Restarting container $ContainerName..."
			Restart-NavContainer -containerName $ContainerName *> $null
        }
	}
}

Function Sign-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$PfxFile,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$PfxPassword,
	[Parameter(Mandatory=$false)]
	[string]$TimeStampServer = "http://timestamp.digicert.com",
	[Parameter(Mandatory=$false)]
	[string]$DigestAlgorithm = "SHA256",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ArtifactFolder="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$AppIdsToProcess
    )

	# Sign AL project Apps in NAV container

	# Get AL project Apps folders
	$AppFolders = @()
	Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
	    $AppFolders += $_.DirectoryName
	}

	# Loop AL project Apps by dependencies
	Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue | ForEach-Object {
		# Get App.json
		$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
		if ($AppIdsToProcess -eq "" -or $AppIdsToProcess.Contains($AppJson.id))
		{
			$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
			$AppDependenciesFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).dep.app"
			Write-Host "Sign App $AppFile" -ForegroundColor Cyan
			$Module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
			if ($Module) {
				$ModuleName = $Module.Name
			} else {
				$Module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
				$ModuleName = $Module.Name
			}
			if ($ModuleName -eq "BcContainerHelper") {
				Sign-NavContainerApp -containerName $ContainerName -appFile "$AppProjectFolder\.output\$AppFile" -pfxFile $PfxFile -pfxPassword (ConvertTo-SecureString $PfxPassword -AsPlainText -Force) -timeStampServer $TimeStampServer -digestAlgorithm $DigestAlgorithm
			}
			elseif ($ModuleName -eq "NavContainerHelper") {
				Sign-NavContainerHelperApp -containerName $ContainerName -appFile "$AppProjectFolder\.output\$AppFile" -pfxFile $PfxFile -pfxPassword (ConvertTo-SecureString $PfxPassword -AsPlainText -Force)
				
			} else { Write-Host "NavContainerHelper or BcContainerHelper are not installed." -ForegroundColor Yellow }
			if (Test-Path "$AppProjectFolder\.output\$AppFile") { 
				Write-Host "Copy signed App to project folders..."
				New-Item -Path "$_\.alpackages" -ItemType Directory -Force | Out-Null
				if ($AppProjectFolder -ne $_) { Copy-Item -Path "$AppProjectFolder\.alpackages\*.app" -Destination "$_\.alpackages\" -Force }
				if (Test-Path "$_\.alpackages\$AppFile") { Remove-Item "$_\.alpackages\$AppFile" -Force }
				Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$AppProjectFolder\.alpackages\$AppFile" -Force 
				Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$_\$AppFile" -Force
				if (Test-Path "$_\$AppDependenciesFile") { Remove-Item "$_\$AppDependenciesFile" -Force}
				if ($ArtifactFolder -ne "")
				{
					Write-Host "Copy signed App to $ArtifactFolder ..."
					New-Item -Path "$ArtifactFolder" -ItemType Directory -Force | Out-Null
					Copy-Item -Path "$AppProjectFolder\.output\$AppFile" -Destination "$ArtifactFolder\$AppFile" -Force
				}
			}
		}
	}
}

Function RunTests-NavContainerProjectApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$User="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$Password="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$TestSuite="DEFAULT",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$TestResultsFile="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$DevOps,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[switch]$ByExtensionId
    )

	# Run AL tests project Apps in NAV container

	# Restart container
	Write-Warning "Restarting container $ContainerName..."
	Restart-NavContainer -containerName $ContainerName *> $null
	
	# Initialize
	$Parameters = @{}
	if ($User -ne "") { $Parameters += @{"credential" = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))}}

	if ($TestResultsFile -eq "") { $TestResultsFile = "C:\ProgramData\NavContainerHelper\Extensions\$containerName\TestResults.xml" }
	if (Test-path $TestResultsFile) { Remove-Item $TestResultsFile -Force}

	if ($ByExtensionId)
	{
		# Run tests by ExtensionId

		# Get AL project Apps folders
		$AppFolders = @()
		Get-ChildItem "$AppProjectFolder\app.json" -Recurse | ForEach-Object {
			$AppFolders += $_.DirectoryName
		}
		# Loop AL project Apps by dependencies 
		Sort-AppFoldersByDependencies -appFolders $AppFolders -WarningAction SilentlyContinue | ForEach-Object {
			# Get App 
			$AppJson = Get-Content "$_\app.json" | ConvertFrom-Json
			$AppFile = "$($AppJson.Publisher.Replace('/',''))_$($AppJson.Name.Replace('/',''))_$($AppJson.Version).app"
    
			# Get tests in container
			Write-Host "Get tests from App $AppFile"
            try
            {
    			$Tests = Get-TestsFromNavContainer @Parameters -containerName $ContainerName -ignoreGroups -testSuite $TestSuite -extensionId ($AppJson.Id)
            }
            catch
            {
                $Tests = Get-TestsFromNavContainer @Parameters -containerName $ContainerName -ignoreGroups -testSuite $TestSuite -extensionId ($AppJson.Id)
            }
			if ($Tests -and $Tests.Length) { 
				Write-Host "$($Tests.Length) tests found." 
			} elseif ($Tests -and !$Tests.Length) { 
				Write-Host "1 test found." 
			} else { Write-Host "0 test found." }

			if ($Tests)
			{
				# Run tests in container
				Write-Host "Running tests..."
				foreach($Test in $Tests)
				{
					Run-TestsInNavContainer @Parameters -containerName $ContainerName -XUnitResultFileName $TestResultsFile -testSuite $TestSuite -testCodeunit $Test.Id -AppendToXUnitResultFile:(Test-Path $TestResultsFile) -detailed
				}
			}
		}
	}
	else
	{
		# Run tests globaly
		
		# Get tests in container
		Write-Host "Get tests in container $ContainerName"
        try
        {
    		$Tests = Get-TestsFromNavContainer @Parameters -containerName $ContainerName -ignoreGroups -testSuite $TestSuite
        }
        catch
        {
            $Tests = Get-TestsFromNavContainer @Parameters -containerName $ContainerName -ignoreGroups -testSuite $TestSuite
        }
		if ($Tests -and $Tests.Length) { 
			Write-Host "$($Tests.Length) tests found." 
		} elseif ($Tests -and !$Tests.Length) { 
			Write-Host "1 test found." 
		} else { Write-Host "0 test found." }

		if ($Tests)
		{
			# Run tests in container
			Write-Host "Running tests..."
			foreach($Test in $Tests)
			{
				Run-TestsInNavContainer @Parameters -containerName $ContainerName -XUnitResultFileName $TestResultsFile -testSuite $TestSuite -testCodeunit $Test.Id -AppendToXUnitResultFile:(Test-Path $TestResultsFile) -detailed
			}
		}
	}
}

Function Create-NavContainer
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerImageName="",
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$Auth,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[pscredential]$Credential=$null,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[string]$User=$null,
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[string]$Password=$null,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$LicenseFile,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$WorkspaceSourceFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$BranchName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$NAVVersionFolder,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectTargetLanguage,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$BuildBaseline="",
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$MemoryLimit,
	[switch]$NoShortcuts,
	[switch]$AlwaysPull,
	[switch]$DevOps,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$AppProjectFolder=$WorkspaceSourceFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$LicenseType="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerArtifact="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerArtifactToken="",
	[switch]$DisableTaskScheduler,
	[ValidateSet('process','hyperv')]
	[String] $Isolation = "process",
	[switch]$DoNotIncludeTests
	)

	if ($ContainerImageName -eq "" -and $ContainerArtifact -eq "") { throw "You must specify at least a value for ContainerImageName or ContainerArtifact parameter." }
	if ($ContainerArtifact -ne "")
	{
		$ContainerArtifactSegments = "$ContainerArtifact////".Split('/')
		$ContainerArtifactUrl = Get-BCArtifactUrl -storageAccount $ContainerArtifactSegments[0] -type $ContainerArtifactSegments[1] -version $ContainerArtifactSegments[2] -country $ContainerArtifactSegments[3] -select $ContainerArtifactSegments[4] -sasToken $ContainerArtifactToken | Select-Object -First 1
		if (-not ($ContainerArtifactUrl)) {
			throw "Unable to locate artifactUrl from $ContainerArtifact"
		}
		$ContainerImageName = ""
	}

	$AddInsFolder = "$WorkspaceSourceFolder\$BranchName\NAV\Add-Ins"
    $BaselineFolder = "$WorkspaceSourceFolder\Baseline"
		
	$EnableSymbolLoading = ([int]$NAVVersionFolder -le [int]"140")
	if ($EnableSymbolLoading -and $ProjectTargetLanguage -eq "AL" -and ($BuildBaseline -eq "" -or -not (Test-Path "$BaselineFolder\$BuildBaseline.bak"))) { $EnableSymbolLoading = $false }
	$IncludeCSide =  ([int]$NAVVersionFolder -le [int]"140")
	$DoNotExportObjectsToText = $true # ([int]$NAVVersionFolder -le [int]"140")
	
	if ($DoNotIncludeTests) {
		$IncludeTestToolkit = $false
		$IncludeTestLibrariesOnly = $false		
	} else {
		$IncludeTestToolkit = $true
		$IncludeTestLibrariesOnly = $true
	}

	if ($ProjectTargetLanguage -eq "CAL") {
		$IncludeTestToolkit = $false
		$IncludeTestLibrariesOnly = $false		
	}
	if ((Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue) -and ([int]$NAVVersionFolder -ge [int]"170")) { $IncludeTestToolkit = $false }

    $DoNotUseRuntimePackages = ([int]$NAVVersionFolder -ge [int]"150")

	$IncludeAL = ([int]$NAVVersionFolder -ge [int]"150" -and -not $DevOps -and $ProjectTargetLanguage -ne "CAL")
	$AssignPremiumPlan = (([int]$NAVVersionFolder -ge [int]"130") -and $LicenseType -eq "Premium")

	$Parameters = @{
		"Accept_Eula" = $true
		"Accept_Outdated" = $true
	}
	$CreateContainerArguments = "-Accept_Eula -Accept_Outdated -doNotCheckHealth -containerName $ContainerName -auth $Auth -updateHosts -includeCSide:$IncludeCSide -memoryLimit $MemoryLimit -doNotExportObjectsToText:$DoNotExportObjectsToText -enableSymbolLoading:$EnableSymbolLoading -includeTestToolkit:$IncludeTestToolkit -includeTestLibrariesOnly:$IncludeTestLibrariesOnly -doNotUseRuntimePackages:$DoNotUseRuntimePackages -includeAL:$IncludeAL -assignPremiumPlan:$AssignPremiumPlan -isolation $Isolation -useBestContainerOS -dns 8.8.8.8"
	if ($ContainerImageName -ne "") { $Parameters += @{"imageName" = $ContainerImageName } ; $CreateContainerArguments += " -imageName $ContainerImageName" }
	if ($ContainerArtifactUrl -ne "") { $Parameters += @{"artifactUrl" = $ContainerArtifactUrl } ; $CreateContainerArguments += " -artifactUrl $ContainerArtifactUrl" }

	if ($DisableTaskScheduler) { $Parameters += @{"EnableTaskScheduler" = $false } ; $CreateContainerArguments += " -EnableTaskScheduler:`$False"  }
	if ($NoShortcuts) { $Parameters += @{"shortcuts" = "None" } ; $CreateContainerArguments += " -shortcuts None"  }
	if ($AlwaysPull) { $Parameters += @{"alwaysPull" = $true  } ; $CreateContainerArguments += " -alwaysPull" }
	if ($LicenseFile -ne "" ) { $Parameters += @{"licensefile" = "$LicenseFile"  } ; $CreateContainerArguments += " -licensefile ""$LicenseFile""" } #if ($LicenseFile -ne "" -and ([int]$NAVVersionFolder -ge [int]"150" -or $IncludeAL)) { $Parameters += @{"licensefile" = "$LicenseFile"  } }

	if (Test-Path "$WorkspaceSourceFolder\Assets\AdditionalSetup.ps1") { $Parameters +=  @{"myscripts" = @("$WorkspaceSourceFolder\Assets\AdditionalSetup.ps1")} ; $CreateContainerArguments += " -myscripts @(""$WorkspaceSourceFolder\Assets\AdditionalSetup.ps1"")" }

	$AdditionalParameters = @()
	if ($ProjectTargetLanguage -ne "AL") {
		if (Test-Path $AddInsFolder) { $AdditionalParameters += "--volume ""${AddInsFolder}"":c:\run\Add-Ins" }

	}
	if ($ProjectTargetLanguage -ne "CAL") {
		$AdditionalParameters += "--volume ""${AppProjectFolder}:C:\Source"""
	}
	if ($BuildBaseline -ne "" -and $BranchName -ne "Core" -and (Test-Path "$BaselineFolder\$BuildBaseline.bak")) {
		$AdditionalParameters += "--volume ""${BaselineFolder}"":c:\temp"
		$AdditionalParameters += "--env bakfile=""c:\temp\${BuildBaseline}.bak"""
	}
	$CreateContainerArguments += " -additionalParameters @("
	$AdditionalParameters | foreach { $CreateContainerArguments += """$_""," }
	if ($CreateContainerArguments.EndsWith(",")) { $CreateContainerArguments = $CreateContainerArguments.Substring(0, $CreateContainerArguments.Length-1) + ")" } 
	
	$System = Get-WmiObject win32_OperatingSystem
	$FreePhysicalMem = [math]::round($system.FreePhysicalMemory / 1024 / 1024,1)
	Write-Host "Memory available : $FreePhysicalMem GB. Container MemoryLimit : $($MemoryLimit.Replace(""G"","""")) GB."
	Write-Host "New-NavContainer arguments : $CreateContainerArguments"

	if (-not ($Credential)) { $Credential = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force))) 	}
	if (Test-NavContainer -containerName $ContainerName) { Remove-NavContainer -containerName $ContainerName }

	Write-Host "Creating container $ContainerName..."
	$ErrorActionPreference = "Continue"
	New-NavContainer @parameters `
		-doNotCheckHealth `
		-containerName $ContainerName `
		-auth $Auth `
		-Credential $Credential `
		-updateHosts `
		-includeCSide:$IncludeCSide `
		-memoryLimit $MemoryLimit `
		-doNotExportObjectsToText:$DoNotExportObjectsToText `
		-enableSymbolLoading:$EnableSymbolLoading `
		-additionalParameters $AdditionalParameters `
		-includeTestToolkit:$IncludeTestToolkit `
        -includeTestLibrariesOnly:$IncludeTestLibrariesOnly `
        -doNotUseRuntimePackages:$DoNotUseRuntimePackages `
		-includeAL:$IncludeAL `
		-assignPremiumPlan:$AssignPremiumPlan `
		-isolation $Isolation -useBestContainerOS -dns 8.8.8.8
		        
	$ErrorActionPreference = "Stop"

	if ((Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue) -and ([int]$NAVVersionFolder -ge [int]"170"))
	{
		if (Get-NavContainerAppInfo -containerName $ContainerName | Where-Object -Property Name -eq "Performance Toolkit") { UnPublish-NavContainerApp -containerName $ContainerName -appName "Performance Toolkit" -force }
		if (Get-NavContainerAppInfo -containerName $ContainerName | Where-Object -Property Name -eq "Test Runner") { UnPublish-NavContainerApp -containerName $ContainerName -appName "Test Runner" -force }
        Import-TestToolkitToNavContainer -containerName $ContainerName -includeTestLibrariesOnly:$IncludeTestLibrariesOnly -doNotUseRuntimePackages:$DoNotUseRuntimePackages
	}

	#if ($LicenseFile -ne "" -and [int]$NAVVersionFolder -le [int]"140") 
	#{
	#	Import-NavContainerLicense -containerName $ContainerName -licenseFile  $LicenseFile
	#}

	# Wait container to be ready and restart
	$WaitSeconds = 30
	Write-Host "Waiting $WaitSeconds seconds for container to be ready..."
	Start-Sleep -Seconds $WaitSeconds
	Write-Host "Restarting container $ContainerName..."
	Restart-NavContainer -containerName $ContainerName *> $null
}

Function Get-NavContainerAppFile
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppName
	)
	$ContainerApplicationsFolder = "c:\applications"
	$AppFilename = $null
	if ($AppName -eq "Tests-TestLibraries") { $AppFilename = "$ContainerApplicationsFolder\BaseApp\Test\Microsoft_Tests-TestLibraries.app" }
	elseif ($AppName -eq "_Exclude_ClientAddIns_") { $AppFilename = "$ContainerApplicationsFolder\ClientAddIns\Source\ClientAddIns.app" } 
	elseif ($AppName -eq "WorldPay Payments Standard") { $AppFilename = "$ContainerApplicationsFolder\WorldPayPaymentsStandard\Source\WorldPayPaymentsStandard.app" }
	elseif ($AppName -eq "Sales and Inventory Forecast") { $AppFilename = "$ContainerApplicationsFolder\SalesAndInventoryForecast\Source\SalesAndInventoryForecast.app" }
	elseif ($AppName -eq "Business Central Intelligent Cloud") { $AppFilename = "$ContainerApplicationsFolder\HybridBC\Source\HybridBC.app" }
	elseif ($AppName -eq "Intelligent Cloud Base") { $AppFilename = "$ContainerApplicationsFolder\HybridBaseDeployment\Source\HybridBaseDeployment.app" }
	elseif ($AppName -eq "_Exclude_APIV1_") { $AppFilename = "$ContainerApplicationsFolder\APIV1\Source\APIV1.app" }
	elseif ($AppName -eq "AMC Banking 365 Fundamentals") { $AppFilename = "$ContainerApplicationsFolder\AMCBanking365Fundamentals\Source\AMCBanking365Fundamentals.app" }
	elseif ($AppName -eq "Essential Business Headlines") { $AppFilename = "$ContainerApplicationsFolder\EssentialBusinessHeadlines\Source\EssentialBusinessHeadlines.app"}
	elseif ($AppName -eq "PayPal Payments Standard") { $AppFilename = "$ContainerApplicationsFolder\PayPalPaymentsStandard\Source\PayPalPaymentsStandard.app"}
	elseif ($AppName -eq "Application") { $AppFilename = "$ContainerApplicationsFolder\Application\Source\Microsoft_Application.app"}
	return $AppFilename
}

Function Get-NavContainerBaseAppSource
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$BaseAppProjectFolder,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$User="",
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$Password="",
	[switch]$Clean
	)

	# Initialize
	$Parameters = @{}
	if ($User -ne "") { $Parameters += @{"credential" = (New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Password -AsPlainText -Force)))}}

	# Empty Base folder content
	if ($Clean)
	{
		Write-Host "Cleaning $BaseAppProjectFolder folder..."
		Remove-Item "$BaseAppProjectFolder\*" -Recurse -Force | Out-Null
		New-Item -Path "$BaseAppProjectFolder" -ItemType Directory -Force | Out-Null
	}

	# Get BaseApp source in container
	Write-Host "Getting Base App source code from container $ContainerName..."
	Create-AlProjectFolderFromNavContainer @parameters -containerName $ContainerName -alProjectFolder $BaseAppProjectFolder -useBaseAppProperties
}

Function Invoke-DockerLogin
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$DockerServer,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$DockerUser,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$DockerPassword
	)

	$ResultCommandFile = "DockerLoginResultCommand.txt"
	if (Test-Path "./$ResultCommandFile") { Remove-Item "./$ResultCommandFile" }
	$CurrentErrorActionPreference = $ErrorActionPreference
	try
	{
		$ErrorActionPreference = "Continue"
		Write-Host "Docker login to server $DockerServer with user $DockerUser"
		docker login "$DockerServer" -u "$DockerUser" -p "$DockerPassword" *> "./$ResultCommandFile"
	}
	finally
	{
		$ErrorActionPreference = $CurrentErrorActionPreference
	}
	$ResultCommandContent = Get-Content "./$ResultCommandFile"
	Remove-Item "./$ResultCommandFile"

	$SuccessLog = $ResultCommandContent | Where-Object { $_.StartsWith("Login Succeeded") }
	$ErrorLog = $ResultCommandContent | Where-Object { $_.StartsWith("Error ") }

	if ($ErrorLog) { Write-Error $ErrorLog } elseif (!$SuccessLog) { Write-Error "Error unknown"} else { Write-Host $SuccessLog }
}

Function Run-XmlBuildScripts
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ProjectFolder,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$XmlBuildScripts,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$CopyToFolder="",
	[ValidateSet("AppSource","OnPremCfmd","PerTenant","OnPrem")]
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ArtifactType=""
	)

	# Read Xml
	[xml]$Xml = $XmlBuildScripts

	# Run build container copy scripts
	$ContainerId = Get-NavContainerId -containerName $ContainerName
	$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
	foreach($Script in $Xml.BuildScripts.BuildContainerCopyScripts.BuildContainerCopyScript)
	{
		# Replace params values
		$ArgumentList = ""
		$Source = $Script.Source
		$Destination = $Script.Destination
		if ($Source -ne $null -and $Source -ne "")
		{
			$Source = $Source.Replace("$" + "AssetsPath","$ProjectFolder\Assets")
			$Source = $Source.Replace("$" + "ScriptsPath","$ProjectFolder\Scripts")
			$Source = $Source.Replace("$" + "BaselinePath","$ProjectFolder\Baseline")
		}
		# Run script
		Write-Host ("Execute container copy """ + $Script.Id + """ (" + $Source +" to $Destination)")
		# Create folder if not exists
		Invoke-Command -Session $Session -argumentList $Destination -scriptblock {
			param($Destination)
			if (-not (Test-path (Split-Path $Destination)))
			{
				New-item (Split-Path $Destination) -ItemType Directory -Force | Out-Null
			}
		}
		# Copy Item
		$null = Copy-Item $Source -Destination $Destination -ToSession $Session
	}

	# Run build container install scripts
	foreach($Script in $Xml.BuildScripts.BuildContainerInstallScripts.BuildContainerInstallScript)
	{
		# Replace params values
		$ArgumentList = @()
		$Params = $Script.Params
		if ($Params -ne $null -and $Params -ne "")
		{
			$Params = $Params.Replace("$" + "AssetsPath","$ProjectFolder\Assets")
			$Params = $Params.Replace("$" + "ScriptsPath","$ProjectFolder\Scripts")
			$Params = $Params.Replace("$" + "BaselinePath","$ProjectFolder\Baseline")
			$Params = $Params.Split(";")
			foreach($Param in $Params) { $ArgumentList += $Param }
		}
		# Run script
		Write-Host ("Execute container script """ + $Script.Id + """ (" + $Script.Value +")")
		$Command = "$ProjectFolder\Scripts\$($Script.Value)"
		Write-Host "Command= $Command"
		$null = Invoke-Command -Session $Session -ArgumentList $ArgumentList -FilePath $Command
	}

	# Run build local install scripts
	foreach($Script in $Xml.BuildScripts.BuildLocalInstallScripts.BuildLocalInstallScript)
	{
		# Replace params values
		$ArgumentList = ""
		$Params = $Script.Params
		if ($Params -ne $null -and $Params -ne "")
		{
			$Params = $Params.Replace("$" + "AssetsPath","$ProjectFolder\Assets")
			$Params = $Params.Replace("$" + "ScriptsPath","$ProjectFolder\Scripts")
			$Params = $Params.Replace("$" + "BaselinePath","$ProjectFolder\Baseline")
			$Params = $Params.Replace("$" + "ContainerName",$ContainerName)
			$Params = $Params.Replace("$" + "CopyToPath",$CopyToFolder)
			$Params = $Params.Replace("$" + "ArtifactType","$ArtifactType")
			$Params = $Params.Split(";")
			foreach($Param in $Params) { $ArgumentList += " '" + $Param + "'" }
		}
		# Run script
		Write-Host ("Execute local script """ + $Script.Id + """ (" + $Script.Value +")")
		$Command = "& '$ProjectFolder\Scripts\" + $Script.Value + "' " + $ArgumentList
		Write-Host "Command= $Command"
		try {
			$null = Invoke-Expression ($Command) 	
		}
		catch {
			throw "Error execute local script """ + $Script.Id + """ : " + $_.Exception.Message
		}
	}
}

Function Install-NavContainerAppDependencies
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$AppPublisher,
    [Parameter(ValueFromPipelinebyPropertyName=$True)]
    [String]$BaseAppDependencyAppIdsToNotRepublish=""
	)
	Write-Host "Installing $AppName dependencies on tenant default"
	Get-NavContainerAppInfo -containerName $ContainerName -sort DependenciesLast | % {
		$AppDependency = $_
		$_.Dependencies | % {
			if ($_.StartsWith("$AppName, $AppPublisher")) 
			{ 
				Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties | Where Name -eq $AppDependency.Name | ForEach-Object {
					if (-not $_.IsInstalled) 
					{ 
						if ($BaseAppDependencyAppIdsToNotRepublish.Contains($_.AppId))
                        {
                            Write-Warning "$($_.Name) is ignored (in BaseApp dependency Apps to not republish)..."
                        }
                        else
                        {
							Install-NavContainerApp -containerName $ContainerName -appName $_.Name -appVersion $_.Version -Force  
						}
					}
				}
			}
		}
	}
}

Function Display-WelcomeText
{
	$ModuleName = ""
	$Module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
	if ($Module) {
		$ModuleName = $Module.Name
	} else {
		$Module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
		$ModuleName = $Module.Name
	}
	if ($ModuleName -ne "") {
		$VersionStr = $Module.Version.ToString()
		Write-Host "$ModuleName $VersionStr is installed" -ForegroundColor Yellow
		if ($ModuleName -eq "NavContainerHelper") { 
			Write-NavContainerHelperWelcomeText 
		} elseif ($ModuleName -eq "BcContainerHelper") { 
			Import-Module bccontainerhelper *> $null
			Write-Host "Settings" -ForegroundColor Yellow
			$bcContainerHelperConfig
			Write-Host ""
		}
	} else { Write-Host "NavContainerHelper or BcContainerHelper are not installed." -ForegroundColor Yellow }
}

Function Clean-ContainerHelperCache
{
	Param(
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[String]$ContainerName="",
	[Parameter(ValueFromPipelinebyPropertyName=$True)]
	[int]$ArtifactsKeepDays = 0
	)
	$ArtifactsCacheFolder = ""
	$Module = Get-InstalledModule -Name navcontainerhelper -ErrorAction SilentlyContinue
	if ($Module) {
		Import-Module navcontainerhelper *> $null
		$ArtifactsCacheFolder = $navContainerHelperConfig.bcartifactsCacheFolder
	} else {
		$Module = Get-InstalledModule -Name bccontainerhelper -ErrorAction SilentlyContinue
		Import-Module bccontainerhelper *> $null
		$ArtifactsCacheFolder = $bcContainerHelperConfig.bcartifactsCacheFolder
	}
	# Clear sandbox artifacts cache (keep last major.minor version)
	if (Test-Path "$ArtifactsCacheFolder\sandbox") {
		Get-ChildItem "$ArtifactsCacheFolder\sandbox" | % {
			$Version = ($_.Name).Split(".")
			$MajorMinorVersionLastDate = Get-Date -Date "1970-01-01"
			$MajorMinorVersionLast = ""
			Get-ChildItem "$ArtifactsCacheFolder\sandbox\$($Version[0]).$($Version[1]).*.*" | % {
				if ($_.CreationTime -gt $MajorMinorVersionLastDate) {
					$MajorMinorVersionLastDate = $_.CreationTime
					$MajorMinorVersionLast = $_.Name
				}
			}
			Get-ChildItem "$ArtifactsCacheFolder\sandbox\$($Version[0]).$($Version[1]).*.*" | % {
				if ($_.Name -ne $MajorMinorVersionLast) {
					Write-Host "Removing Cache $($_.FullName)"
					Remove-Item $_.FullName -Recurse -Force 
				 }
			}
		}
	}
	
	# Clear all artifacts cache (keep $keepDays days)
	Flush-ContainerHelperCache -cache bcartifacts -keepDays $ArtifactsKeepDays
}

Function Sign-NavContainerHelperApp {
    Param (
        [string] $containerName = "navserver",
        [Parameter(Mandatory=$true)]
        [string] $appFile,
        [Parameter(Mandatory=$true)]
        [string] $pfxFile,
        [Parameter(Mandatory=$true)]
		[SecureString] $pfxPassword,
		[Parameter(Mandatory=$false)]
		[string] $timeStampServer = "http://timestamp.digicert.com",
		[Parameter(Mandatory=$false)]
        [string] $digestAlgorithm = "SHA256"
    )

    $containerAppFile = Get-NavContainerPath -containerName $containerName -path $appFile
    if ("$containerAppFile" -eq "") {
        throw "The app ($appFile)needs to be in a folder, which is shared with the container $containerName"
    }

    $copied = $false
    if ($pfxFile.ToLower().StartsWith("http://") -or $pfxFile.ToLower().StartsWith("https://")) {
        $containerPfxFile = $pfxFile
    } else {
        $containerPfxFile = Get-NavContainerPath -containerName $containerName -path $pfxFile
        if ("$containerPfxFile" -eq "") {
            $containerPfxFile = Join-Path "c:\run" ([System.IO.Path]::GetFileName($pfxFile))
            Copy-FileToNavContainer -containerName $containerName -localPath $pfxFile -containerPath $containerPfxFile
            $copied = $true
        }
    }

    Invoke-ScriptInNavContainer -containerName $containerName -ScriptBlock { Param($appFile, $pfxFile, $pfxPassword, $timeStampServer, $digestAlgorithm)

        if ($pfxFile.ToLower().StartsWith("http://") -or $pfxFile.ToLower().StartsWith("https://")) {
            $pfxUrl = $pfxFile
            $pfxFile = Join-Path "c:\run" ([System.Uri]::UnescapeDataString([System.IO.Path]::GetFileName($pfxUrl).split("?")[0]))
            (New-Object System.Net.WebClient).DownloadFile($pfxUrl, $pfxFile)
            $copied = $true
        }

        if (Test-Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe") {
            $signToolExe = (get-item "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe").FullName
        } else {
            Write-Host "Downloading Signing Tools"
            $winSdkSetupExe = "c:\run\install\winsdksetup.exe"
            $winSdkSetupUrl = "https://go.microsoft.com/fwlink/p/?LinkID=2023014"
            (New-Object System.Net.WebClient).DownloadFile($winSdkSetupUrl, $winSdkSetupExe)
            Write-Host "Installing Signing Tools"
            Start-Process $winSdkSetupExe -ArgumentList "/features OptionId.SigningTools /q" -Wait
            if (!(Test-Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe")) {
                throw "Cannot locate signtool.exe after installation"
            }
            $signToolExe = (get-item "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe").FullName
        }

        Write-Host "Signing $appFile"
		$unsecurepassword = ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pfxPassword)))
		$attempt = 1
        $maxAttempts = 5
        do {
            try {
                if ($digestAlgorithm) {
                    & "$signtoolexe" @("sign", "/f", "$pfxFile", "/p","$unsecurepassword", "/fd", $digestAlgorithm, "/td", $digestAlgorithm, "/tr", "$timeStampServer", "$appFile") | Write-Host
                }
                else {
                    & "$signtoolexe" @("sign", "/f", "$pfxFile", "/p","$unsecurepassword", "/t", "$timeStampServer", "$appFile") | Write-Host
                }
                break
            } catch {
                if ($attempt -ge $maxAttempts) {
                    throw
                }
                else {
                    $seconds = [Math]::Pow(4,$attempt)
                    Write-Host "Signing failed, retrying in $seconds seconds"
                    $attempt++
                    Start-Sleep -Seconds $seconds
                }
            }
        } while ($attempt -le $maxAttempts)
        if ($copied) { 
            Remove-Item $pfxFile -Force
        }
    } -ArgumentList $containerAppFile, $containerPfxFile, $pfxPassword, $timeStampServer, $digestAlgorithm
}

Function Clean-NavContainerExternalDependencyApps
{
    Param(
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ContainerName,
    [Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
    [String]$ExternalDependenciesAppsJsonPath
    )
	if ($ExternalDependenciesAppsJsonPath -ne "" -and (Test-Path $ExternalDependenciesAppsJsonPath)) {
		$ExternalDependenciesAppsJson = Get-Content "$ExternalDependenciesAppsJsonPath\apps.json" | ConvertFrom-Json
		foreach($ExternalDependencyAppsJson in $ExternalDependenciesAppsJson) {
			Write-Host "Clean App $($ExternalDependencyAppsJson.fileName)" -ForegroundColor Cyan
			UnPublish-NavContainerApp -containerName $ContainerName -publisher $ExternalDependencyAppsJson.publisher -name $ExternalDependencyAppsJson.name -version $ExternalDependencyAppsJson.version -unInstall -doNotSaveData
		}
	}
}

function Get-NavContainerAppFileInfo
{
	Param(
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$ContainerName,
	[Parameter(Mandatory=$true,ValueFromPipelinebyPropertyName=$True)]
	[String]$AppFile
	)
	$ContainerAppFile = "c:\run\my\$(Split-Path $AppFile -Leaf)"
	$ContainerId = Get-NavContainerId -containerName $ContainerName
	$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
	Copy-Item $AppFile -Destination $ContainerAppFile -ToSession $Session -Force
	Remove-PSSession $Session
	$AppFileInfo = Invoke-ScriptInNavContainer -containerName $ContainerName -argumentList $ContainerAppFile -scriptblock {Param($ContainerAppFile)
		Get-NavAppInfo -Path "$ContainerAppFile"
		Remove-Item "$ContainerAppFile"
	}
	return $AppFileInfo
}
