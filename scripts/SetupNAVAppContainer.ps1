<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : Calliope 3Li
Description  : Install NAV App in container
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies : 
------------------------------------------------------------------------------------------------------------------
Revisions    : 26/02/2020 : PMN : Initial version
               #172 : 22/09/2020 : PMN : Add skipverification
               #212 : 14/10/2020 : PMN : Fix install in container new version of App, BaseApp and reinstall uninstalled Apps
               #243 : 02/11/2020 : PMN : Add copy App to $CopyToFolder folder
               #307 : 27/11/2020 : PMN : Add apps.json to folder $CopyToFolder to simplify dependent Apps deployment
               #3480 : 23/10/2021 : PMN : Add params AppSourcePrefix, OnPremCfmdPrefix, PerTenantPrefix (for dependencies management with multiple artifact types)
------------------------------------------------------------------------------------------------------------------
#>
Param(
  [string]$ContainerName = "", # Container name
  [string]$AppFile = "", # App file
  [string]$AppName = "", # App name
  [string]$SyncMode = "Add", # Sync mode
  [string]$CopyToFolder = "", # foldder to copy App
  [string]$AppSourcePrefix = "", # AppSource App object prefix
  [string]$OnPremCfmdPrefix = "", # OnPremCfmdPrefix App object prefix
  [string]$PerTenantPrefix = "" # PerTenantPrefix App object prefix
)
# Init 
$ErrorActionPreference = "Stop"

# Get App file info
$ContainerAppFile = "c:\run\my\$(Split-Path $AppFile -Leaf)"
$ContainerId = Get-NavContainerId -containerName $ContainerName
$Session = New-PSSession -ContainerId $ContainerId -RunAsAdministrator
Copy-Item $AppFile -Destination $ContainerAppFile -ToSession $Session -Force
Remove-PSSession $Session
$AppFileInfo = Invoke-ScriptInNavContainer -containerName $ContainerName -argumentList $ContainerAppFile -scriptblock {Param($ContainerAppFile)
    Get-NavAppInfo -Path "$ContainerAppFile"
    Remove-Item "$ContainerAppFile"
}

# Copy App to $CopyToFolder folder
if ($CopyToFolder -ne "")
{
    # Copy App 
    Write-Host "Copy $AppFile to $CopyToFolder folder ..."
    New-Item -Path "$CopyToFolder" -ItemType Directory -Force | Out-Null
    Copy-Item -Path "$AppFile" -Destination "$CopyToFolder\$(Split-Path $AppFile -leaf)" -Force

    # Update apps.json
    $Apps = @()
    if (Test-Path "$CopyToFolder\apps.json") {
        $JsonApps = Get-Content "$CopyToFolder\apps.json" | ConvertFrom-Json 
        foreach($JsonApp in $JsonApps) {
            if (-not (($JsonApp.publisher -eq $AppFileInfo.Publisher -and $JsonApp.name -eq $AppFileInfo.Name) -or ($JsonApp.appId -eq $AppFileInfo.AppId))) {
                $Apps += [pscustomobject]@{fileName=$JsonApp.fileName;appId=$JsonApp.appId;publisher=$JsonApp.publisher;name=$JsonApp.name;version=$JsonApp.version;brief=$JsonApp.brief;appSourcePrefix=$JsonApp.appSourcePrefix;onPremCfmdPrefix=$JsonApp.onPremCfmdPrefix;perTenantPrefix=$JsonApp.perTenantPrefix }
            } 
        }
    }
    $Apps += [pscustomobject]@{fileName=$(Split-Path $AppFile -Leaf);appId=$AppFileInfo.AppId;publisher=$AppFileInfo.Publisher;name=$AppFileInfo.Name;version=$AppFileInfo.Version.ToString();brief=$AppFileInfo.Brief;appSourcePrefix=$AppSourcePrefix;onPremCfmdPrefix=$OnPremCfmdPrefix;perTenantPrefix=$PerTenantPrefix}
    $Apps | ConvertTo-Json -Depth 10 | Set-Content "$CopyToFolder\apps.json"

}

# Set AppName
$AppName = $AppFileInfo.Name

# Get installed Apps
$InstalledApps = Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst | Where-Object { $_.IsInstalled }
Write-Host "Installed Apps:"
foreach ($InstalledApp in $InstalledApps) { Write-Host "- $($InstalledApp.Name) Publisher=$($InstalledApp.Publisher) Version=$($InstalledApp.Version)" }

# Publish 
Publish-NavContainerApp -containerName $ContainerName -appFile $AppFile -skipVerification

if ($SyncMode -eq "ForceSync")
{
    # Uninstall
    UnInstall-NavContainerApp -containerName $ContainerName -appName $AppName -Force
}

# Sync 
Sync-NavContainerApp -containerName $ContainerName -appName $AppName -appVersion $AppFileInfo.Version -Mode $SyncMode -Force

# Install
if (Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties | Where-Object { $_.Name -eq $AppName -and $_.Version -ne $AppFileInfo.Version -and ($_.IsInstalled -or $_.ExtensionDataVersion -ne $AppFileInfo.Version)}) {
    Start-NavContainerAppDataUpgrade -containerName $ContainerName -appName $AppName -appVersion $AppFileInfo.Version
} else {
    Install-NavContainerApp -containerName $ContainerName -appName $AppName -appVersion $AppFileInfo.Version
}

# Unpublish previous versions
Write-Host "Unpublish previous versions of $AppName"
Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties | Where-Object { -not $_.IsInstalled -and $_.Name -eq $AppName } | ForEach-Object { UnPublish-NavContainerApp -containerName $ContainerName -appName $AppName -version $_.Version }

# Reinstall uninstalled apps
Write-Host "Reinstall uninstalled apps"
$UninstalledApps = Get-NavContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesFirst | Where-Object { -not $_.IsInstalled -and $_.Name -ne $AppName } 
foreach ($UninstalledApp in $UninstalledApps) {
    $InstalledApp = $InstalledApps | Where-Object { $_.Name -eq $UninstalledApp.Name -and $_.Version -eq $UninstalledApp.Version }
    if ($InstalledApp) { Install-NavContainerApp -containerName $ContainerName -appName $InstalledApp.Name -appVersion $InstalledApp.Version }
}
