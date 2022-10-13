<#
.SYNOPSIS
  Send Query Command to list of devices with a device ID
.DESCRIPTION
  To do: provide better feedback/more options, choose platform first to eliminate errors selecting profiles with the exact same name.
  .INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.1
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  4/21/2021
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Query-Device.ps1 -file .\devices.csv -fileColumn "device_id"
  Query-Device.ps1 -file .\serial.csv -fileColumn "SerialNumber"
#>

[CmdletBinding()] 
Param(
  [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $true, 
    HelpMessage = "Path to file listing Device IDs or Serial Numbers.")]
  [string]$file,
	
  [Parameter(HelpMessage = "Name of Device Identifier column in file, default is device_id, 
    if using a serial number, as long as serial is part of the column it will query 
    based on a serial number instead of device ID.")]
  [string]$fileColumn = "device_id"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

<#
Start of Script
#>

$devicelist = Read-File $file $fileColumn
$i = 0
if ($fileColumn -like "*serial*" ) {

  foreach ($device in $devicelist) {
    $i++
    #Write-Progress -Activity "Querying Devices" -Status "$($i) of $($devicelist.Count)" -PercentComplete ((($i)/(@($devicelist).Count))*100)
    Write-Host "$i of $($deviceList.Count)"
    $json = ' '
    $endpoint = "mdm/devices/commands?command=DeviceQuery&searchby=SerialNumber&id=$device"
    try {
      Send-Post $endpoint $json
    }
    catch {
      Write-Host "Error sending query command"
    }
  }
}
else {
  foreach ($device in $devicelist) {
    $i++
    Write-Host "$i of $($deviceList.Count)"
    $json = ' '
    $endpoint = "mdm/devices/$device/commands?command=DeviceQuery"
    try {
      Send-Post $endpoint $json
    }
    catch {
      Write-Host "Error sending query command"
    }
  }
}
