<#
.SYNOPSIS
  Reboots devices given a list of SerialNumbers.
.DESCRIPTION
  Reboots devices given a list of SerialNumbers. Uses the Command API to SoftReset (reboot) the device.
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  09/30/2020
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Invoke-RebootDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>


[CmdletBinding()] 
Param(
  [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $true, HelpMessage = "Path to file listing SerialNumbers.")]
  [string]$file,
	
  [Parameter(HelpMessage = "Name of Id column in file, default is SerialNumber")]
  [string]$fileColumn = "SerialNumber"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\RebootDevice.log"

$list = Read-FileWithData $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
  "Attention! If you proceed, " + @($list).count + " devices will be rebooted",
  "",
  @('&Yes', '&No'), 1)

if ($decision -eq 0) {
  Write-Log -logstring "Rebooting $($list.count) devices in AirWatch" -logfile $Logfile
  $devices = @()
  foreach ($item in $list) {
    $devices += $item.$($fileColumn)
  }
  $json = Set-AddTagJSON $devices
  Write-Progress -Activity "Rebooting Devices..." -Status "$($list.Count) devices" 
  $endpointURL = "mdm/devices/commands/bulk?command=SoftReset&searchby=SerialNumber"
  try {
    $result = Send-Post -endpoint $endpointURL -body $json -version $version1
    if ($result -eq "") {
      $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
      Write-Warning ("Error Rebooting Devices : Error", $err.errorCode, $err.message)
      Write-Log -logstring ("Error Rebooting Devices : Error", $err.errorCode, $err.message) -logfile $Logfile
    }
    else {
      Write-Host "$result"
      Write-Log -logstring "$result" -logfile $Logfile
    }
  }
  catch {
    $err2 = ($Error[0].ErrorDetails.Message)
    Write-Warning "Error Rebooting Devices $err2"
    Write-Log -logstring "Error Rebooting Devices $err2" -logfile $Logfile
  }
}
else {
  Write-Host "Action Cancelled"
  Write-Log -logstring "Action Cancelled" -logfile $Logfile
}

