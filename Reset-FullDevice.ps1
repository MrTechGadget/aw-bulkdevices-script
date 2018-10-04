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
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/02/2018
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

$list = Read-File $file $fileColumn


$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " devices will be Device Wiped back to factory settings from AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    $json = '{ "deviceWipe": { "disableActivationKey": true, "disallowProximitySetup": true, "preserveDataPlan": true } }'
    foreach ($item in $list) {
        try {
            $result = Send-Post -endpoint "mdm/devices/commands/DeviceWipe/device/SerialNumber/$item" -body $json -version $version2
            if (!$result) {
                Write-Warning "Error Sending Device Wipe Command"
                Write-Host $item
            } else {
                Write-Host $result
            }
        }
        catch {
            Write-Warning "Error Sending Device Wipe Command"
            Write-Host $item
        }
    }
} else {
    Write-Host "Deletion Cancelled"
}




