<#
.SYNOPSIS
  Creates List of Devices that have not checked in with AirWatch since a configurable number of days ago.
.DESCRIPTION
  This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
  The user then enters a number of days(X) since the devices have been last seen.
  All of the devices in that organization group (and child org groups) that have not been seen since X days are exported to a CSV file named with that date.
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a CSV file with Devices that have not been seen in X number of days.
.NOTES
  Version:        1.2
  Author:         Joshua Clark @audioeng
  Site:           https://github.com/audioeng/aw-bulkdevices-script
  Creation Date:  09/15/2017
  Update Date:    02/13/2019
.EXAMPLE
  Get-ListOfStaleDevices.ps1 -pageSize 1000
#>

[CmdletBinding()] 
Param(
   [Parameter(HelpMessage="Number of devices returned, default is 500")]
   [string]$pageSize = "500"
)

Import-Module .\PSairwatch.psm1

Function Set-DeviceIdList {
  Param([object]$Devices)
  $s = @()
  foreach ($device in $Devices) {
      $s += $device.Id.Value
      Write-Verbose $device.Id.Value
  }
  return $s
}

<#
Start of Script
#>

$OrgGroups = Get-OrgGroups
$GroupID = Select-Tag $OrgGroups
$DaysPrior = Set-DaysPrior
$LastSeenDate = Set-LastSeenDate $DaysPrior
"Devices last seen on or before " + $LastSeenDate 
$Devices = Get-Device $LastSeenDate $GroupID $pageSize

$DeviceList = Set-DeviceIdList $Devices
$DeviceJSON = Set-AddTagJSON $DeviceList
$DeviceDetails = Get-DeviceDetails $DeviceJSON
$DeviceDetails | Export-Csv -Path "DevicesLastSeen${LastSeenDate}.csv"
