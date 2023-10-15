<#
.SYNOPSIS
  Gets status of device wipes for selected Workspace ONE UEM Organization Group
.DESCRIPTION
  Gets status of device wipes for selected Workspace ONE UEM Organization Group 
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a log and a CSV of Wipe Statuses for a chosen Organization Group
.NOTES
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/14/2023
  Update Date:    10/14/2023
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Get-WipeStatus.ps1
#>

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\AccStatus.log"
Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$date = Get-Date -Format yyyyMMdd
$OrgGroups = Get-OrgGroupUUID
$GroupUuid = Select-Tag $OrgGroups

$endpointURL = "system/groups/" + $GroupUuid[1] + "/device-wipes"

$results = Send-Get -endpoint $endpointURL
$results
try {
    if ($results) {
        Write-Log -logstring $results -logfile $Logfile
        $results.device_wipes | Export-Csv -Path "DeviceWipeStatus${date}.csv"
    } else {
        Write-Log -logstring "No Results" -logfile $Logfile
    }
}
catch {
    Write-Log -logstring "Error (maybe no results)" -logfile $Logfile
}


