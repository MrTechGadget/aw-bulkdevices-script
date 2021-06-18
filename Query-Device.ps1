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
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  4/21/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Query-Device.ps1 -file .\devices.csv -fileColumn "device_id"
#>

[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing Serial Numbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Device ID column in file, default is device_id")]
   [string]$fileColumn = "device_id"
)

Import-Module .\PSairwatch.psm1

<#
Start of Script
#>

$devicelist = Read-File $file $fileColumn
$i=0
foreach ($device in $devicelist) {
    $i++
    #Write-Progress -Activity "Querying Devices" -Status "$($i) of $($devicelist.Count)" -PercentComplete ((($i)/(@($devicelist).Count))*100)
    Write-Host "$i of $($deviceList.Count)"
    $json = ' '
    $endpoint = "mdm/devices/$device/commands?command=DeviceQuery" 
    try {
        $queryresult = Send-Post $endpoint $json
    }
    catch {
        Write-Host "Error sending query command"
    }
    
}