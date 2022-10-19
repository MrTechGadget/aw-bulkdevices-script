<#
.SYNOPSIS
  Sends an App install command to a list of devices
.DESCRIPTION
  To do: provide better feedback/more options, choose platform first to eliminate errors selecting profiles with the exact same name.
  .INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  4/20/2021
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Install-Application.ps1 -file .\Devices.csv -fileColumn "device_id" -appId "12345" -appType "purchased"
#>

[CmdletBinding()] 
Param(
  [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $true, HelpMessage = "Path to file listing Serial Numbers.")]
  [string]$file,
  [Parameter(HelpMessage = "Name of Serial Number column in file, default is SerialNumber")]
  [string]$fileColumn = "SerialNumber",
  [Parameter(Mandatory = $True, HelpMessage = "ID of Application")]
  [string]$appId,
  [Parameter(Mandatory = $True, HelpMessage = "App Type: internal, public, or purchased")]
  [string]$appType
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

<#
Start of Script
#>

$devicelist = Read-File $file $fileColumn
#$OrgGroups = Get-OrgGroups
#$GroupID = Select-Tag $OrgGroups
#$Platform = Select-Platform

#$ApplicationList = Get-Applications $GroupID $Platform
#$ApplicationSelected = Select-Tag $ApplicationList
if ($fileColumn -like "*serial*" ) {
  $idType = 'SerialNumber'
}
else {
  $idType = 'DeviceId'
}
$i = 0
foreach ($device in $devicelist) {
  $i++
  #Write-Progress -Activity "Installing Application" -Status "$($i) of $($devicelist.Count)" -CurrentOperation "$($device.$fileColumn)" -PercentComplete ((($i)/(@($devicelist).Count))*100)
  Write-Host "$i of $($deviceList.Count) : $device"
  $json = '{ "' + $idType + '": "' + $device + '" }'
  try {
    $installresults = Install-App $json $appId $appType
  }
  catch {
    Write-Warning "Error Installing App $device"
  }
}
