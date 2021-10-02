<#
.SYNOPSIS
  Performs Full Device Wipe from AirWatch for a list of SerialNumbers
.DESCRIPTION
  
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.4
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/02/2018
  Update Date:    10/02/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Reset-FullDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber"
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\FullDeviceWipe.log"

$list = Read-File $file $fileColumn

Write-Log "$($MyInvocation.Line)"

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " devices will be Device Wiped back to factory settings from AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log "Wiping $($list.count) devices back to factory settings from AirWatch"
    $json = '{
        "deviceWipe": {
          "disableActivationKey": true
        }
      }'

    foreach ($item in $list) {
        Write-Progress -Activity "Deleting Devices..." -Status "Batch $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/devices/commands/DeviceWipe/device/SerialNumber/${item}"
        try {
            $result = Send-Post -endpoint $endpointURL -body $json -version "application/json;version=2"
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              if ($err.errorCode -in 400, 5100) {
                Write-Warning ("Error Wiping Device: $item : Error " +$err.errorCode + ", might be an Android device, retrying with different parameters")
                $result = Send-Post -endpoint $endpointURL -body "{}" -version "application/json;version=2"
                if ($result -ne "") {
                  $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
                  Write-Warning ("Error Wiping Device: $item : " + $err.errorCode + " " + $err.message)
                  Write-Log ("Error Wiping Device: $item : " + $err.errorCode + " " + $err.message)
                } else {
                  Write-Host "$item Wiped $result"
                  Write-Log "$item Wiped $result"
                }
              } else {
                Write-Warning ("Error Wiping Device: $item : Error", $err.errorCode, $err.message)
                Write-Log ("Error Wiping Device: $item : Error", $err.errorCode, $err.message)
              }
                
            } else {
                Write-Host "$item Wiped $result"
                Write-Log "$item Wiped $result"
            }
        }
        catch {
          $err2 = ($Error[0].ErrorDetails.Message)
          Write-Warning "Error Sending Device Wipe Command: $item $err2"
          Write-Log "Error Sending Device Wipe Command: $item $err2"
        }
    }
} else {
    Write-Host "Deletion Cancelled"
    Write-Log "Deletion Cancelled"
}




