<#
------------------------------------------------------------------------------------------------------------------
Authors      : PMN (pmoison@3li.com)
Copyright    : 3Li Business Solutions
Description  : Run Msi
------------------------------------------------------------------------------------------------------------------
References   :
Dependencies : 
------------------------------------------------------------------------------------------------------------------
Revisions    : 17/01/2019 : PMN : Initial version
------------------------------------------------------------------------------------------------------------------
#>
Param(
  [string]$MsiFilename = "", # Msi filename
  [string]$MsiOption = "", # Msi options
  [string]$MsiParameters = "" # Msi parameters
)

# Run the Msi installer 
$Arguments = "$MsiOption ""$MsiFilename"" $MsiParameters"
Write-Host "Running Msi ($MsiFilename) with option ($MsiOption) and parameters ($MsiParameters)"
$App = Start-Process "msiexec.exe" -Wait -ArgumentList $Arguments
