<#
.SYNOPSIS
  Deletes device records for enterprise wipe pending or unenrolled devices that have not checked in with AirWatch since a configurable number of days ago.
.DESCRIPTION
  This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
  The user then enters a number of days(X) since the devices have been last seen.
  All of the devices in that organization group (and child org groups) that have not been seen since X days and are pending 
  enterprise wipe or unenrolled are deleted are exported to a CSV file named with that date.
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a CSV file with Devices that have not been seen in X number of days that have been deleted.
.NOTES
  Version:        1.7
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  09/15/2017
  Last Updated:   11/14/2019
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Delete-StaleDevices.ps1 -pageSize 1000 -maxLastSeen 250
#>

[CmdletBinding()] 
Param(
   [Parameter(HelpMessage="Number of devices returned, default is 500")]
   [string]$pageSize = "500",
   [Parameter(HelpMessage="Maximum number of days since devices were last seen, default is 200")]
   [string]$maxLastSeen = "200"
)

Import-Module .\PSairwatch.psm1


$OrgGroups = Get-OrgGroups
$GroupID = Select-Tag $OrgGroups
$DaysPrior = Set-DaysPrior $maxLastSeen
$LastSeenDate = Set-LastSeenDate $DaysPrior
Write-Host("------------------------------")
Write-Host("")
Write-Host "Devices last seen on or before " + $LastSeenDate 
$Devices = Get-Device $LastSeenDate $GroupID $pageSize
$DeviceList = Set-UnenrolledDeviceIdList $Devices
$DeviceJSON = Set-AddTagJSON $DeviceList
$DeviceDetails = Get-DeviceDetails $DeviceJSON
if ($DeviceList.Count -ne 0) {
    Write-Host $DeviceList.Count "Pending Enterprise Wipe Devices exported"
    $DeviceDetails | Export-Csv -Path "EntWipeDevicesLastSeen${LastSeenDate}.csv"
}
Write-Host("------------------------------")
Write-Host("")
$DeletedDevices = Remove-DeviceBulk $DeviceJSON

Write-Host("------------------------------")
if ($DeletedDevices -eq 404) {
    Write-Host "No devices found pending enterprise wipe in that time frame."
} else {
    $DeletedDevices
}
