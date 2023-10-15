<#
.SYNOPSIS
  Gets status of ACC for selected Workspace ONE UEM Organization Group
.DESCRIPTION
  Gets status of ACC for selected Workspace ONE UEM Organization Group 
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a log of ACC Status
.NOTES
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/14/2023
  Update Date:    10/14/2023
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Get-DeviceDetails.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\AccStatus.log"
Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$OrgGroups = Get-OrgGroupUUID
$GroupUuid = Select-Tag $OrgGroups

$endpointURL = "system/groups/" + $GroupUuid[1] + "/cloud-connector/connection-status"

$results = Send-Get -endpoint $endpointURL
$results
try {
    if ($results) {
        Write-Log -logstring $results -logfile $Logfile
    } else {
        Write-Log -logstring "No Results" -logfile $Logfile
    }
}
catch {
    Write-Log -logstring "Error (maybe no results)" -logfile $Logfile
}


