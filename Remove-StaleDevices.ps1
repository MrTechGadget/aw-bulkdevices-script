<#
.SYNOPSIS
  Executes Full or Enterprise Wipe Commands for enrolled devices that have not checked in with AirWatch since a configurable number of days ago.
.DESCRIPTION
  This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
  The user then enters a number of days(X) since the devices have been last seen.
  All of the devices in that organization group (and child org groups) that have not been seen since X days 
  are sorted into supervised and unsupervised lists. The device details for both of these lists are exported to a CSV file named with that date.
  The supervised devices are then issued full wipes and the unsupervised devices are issued enterprise wipes.
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs two CSV files with Devices that have not been seen in X number of days. One that are supervised, one that are unsupervised.
.NOTES
  Version:        1.8
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  09/15/2017
  Last Updated:   10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
  
.EXAMPLE
  Remove-StaleDevices.ps1 -pageSize 1000 -maxLastSeen 250
#>

[CmdletBinding()] 
Param(
   [Parameter(HelpMessage="Number of devices returned, default is 500")]
   [string]$pageSize = "500",
   [Parameter(HelpMessage="Maximum number of days since devices were last seen, default is 200")]
   [string]$maxLastSeen = "200"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$OrgGroups = Get-OrgGroups
$GroupID = Select-Tag $OrgGroups
$DaysPrior = Set-DaysPrior $maxLastSeen
$LastSeenDate = Set-LastSeenDate $DaysPrior
Write-Host "------------------------------"
Write-Host ""
Write-Host "Devices last seen on or before " + $LastSeenDate 
$Devices = Get-Device $LastSeenDate $GroupID $pageSize
$DeviceList = Set-DeviceIdList $Devices
$UnsupervisedDeviceJSON = Set-AddTagJSON $DeviceList[0]
$SupervisedDeviceJSON = Set-AddTagJSON $DeviceList[1]
$SupervisedDeviceDetails = Get-DeviceDetails $SupervisedDeviceJSON
$UnsupervisedDeviceDetails = Get-DeviceDetails $UnsupervisedDeviceJSON
Write-Host $DeviceList[1].Count "Supervised and" $DeviceList[0].Count "Unsupervised Devices exported"
$SupervisedDeviceDetails | Export-Csv -Path "SupervisedDevicesLastSeen${LastSeenDate}.csv"
$UnsupervisedDeviceDetails | Export-Csv -Path "UnsupervisedDevicesLastSeen${LastSeenDate}.csv"
Write-Host "------------------------------"
Write-Host ""
$FullWipe = Unregister-DeviceFullWipe $DeviceList[1]
$EnterpriseWipe = Unregister-DevicesEnterpriseWipe $UnsupervisedDeviceJSON

Write-Host ""
$FullWipe
Write-Host ""
$EnterpriseWipe
