<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : 3Li Business Solutions
Description  : Run LS Retail Setups
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies : 
------------------------------------------------------------------------------------------------------------------
Revisions    : 10/08/2018 : PMN : Initial version
               13/08/2018 : PMN : Fix bug space before /TASKS
               14/11/2018 : PMN : Add param Folder for destination folder
               #249 : 06/11/2020 : PMN : Add LS HardwareStation shortcuts (and new param $ShortcutsFolder)
------------------------------------------------------------------------------------------------------------------
#>
Param(
  [string]$LSSetupExe = "", # LS Retail setup exe
  [string]$Tasks = "", # Setup task list
  [string]$Folder = "", # Setup default folder
  [string]$ShortcutsFolder="" # destination folder for shortcuts
)

$Arguments = "/SILENT /NOCANCEL"
if ($Tasks -ne "")
{
	$Arguments += " /TASKS=""$Tasks"""
}
if ($Folder -ne "")
{
	$Arguments += " /DIR=""$Folder"""
}

# Run the LS Retail installer 
Write-Host "Running LS Retail Setup ($LSSetupExe) with arguments ($Arguments)"
$App = Start-Process $LSSetupExe -Wait -ArgumentList $Arguments

# Create shortcuts
if ($ShortcutsFolder -ne "") {
  $TargetFolder = "C:\Program Files (x86)\LS Retail\LSHardwareStation"
  if ($Folder -ne "") { $TargetFolder = $Folder }
  if (Test-path $TargetFolder ) {
    # Create LS HardwareStation - Start shortcut
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$ShortcutsFolder\LS HardwareStation - Start.lnk"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$TargetFolder\LSHardwareStation.exe"
		$ShortCut.Arguments = "-debug"
		$ShortCut.WorkingDirectory = "$TargetFolder\"
		$ShortCut.WindowStyle = 1
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
    
    # Create LSVirtualStation - Start shortcut
		$Shell = New-Object -ComObject ("WScript.Shell")
		$ShortCutFile = "$ShortcutsFolder\LS VirtualStation - Start.lnk"
		$ShortCut = $Shell.CreateShortcut("$ShortCutFile")
		$ShortCut.TargetPath = "$TargetFolder\LSVirtualStation.exe"
		$ShortCut.Arguments = ""
		$ShortCut.WorkingDirectory = "$TargetFolder\"
		$ShortCut.WindowStyle = 1
		$ShortCut.Save()
		$bytes = [System.IO.File]::ReadAllBytes($ShortCutFile)
		$bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes($ShortCutFile, $bytes)
    
    # Create LS HardwareStation - Management Portal shortcut
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCutFile = "$ShortcutsFolder\LS HardwareStation - Management Portal.url"
    $ShortCut = $Shell.CreateShortcut("$ShortCutFile")
    $ShortCut.TargetPath = "http://localhost:8088/"
    $ShortCut.Save()
  
    # Create LS HardwareStation - Documentation shortcut
    $Shell = New-Object -ComObject ("WScript.Shell")
    $ShortCutFile = "$ShortcutsFolder\LS HardwareStation - Documentation.url"
    $ShortCut = $Shell.CreateShortcut("$ShortCutFile")
    $ShortCut.TargetPath = "https://help.lscentral.lsretail.com/Content/LS%20Retail/POS/Hardware/LS%20Hardware%20Station.htm"
    $ShortCut.Save()

  }
} 


