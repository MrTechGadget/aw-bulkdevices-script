<#
.SYNOPSIS
  Sets AssetNumber in AirWatch for a list of SerialNumbers
.DESCRIPTION
  
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers and desired Asset Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.PARAMETER assetColumn 
    Column title in CSV file containing AssetNumber values.  This is optional, with a default value of "AssetNumber". 
.INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/14/2020
  Update Date:    01/14/2020
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Set-AssetNumber.ps1 -file "Devices.csv" -fileColumn "SerialNumber" -assetColumn "AssetNumber"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber",
   [Parameter(HelpMessage="Name of desired asset column in file, default is AssetNumber")]
   [string]$assetColumn = "AssetNumber"
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\AssetNumber.log"

Function Write-Log
{
    Param ([string]$logstring)

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $Logfile -value $logstring
}

$list = Read-FileWithData $file $fileColumn $assetColumn

Write-Log "$($MyInvocation.Line)"

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " devices will have their AssetNumber overwritten in AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log "Replacing asset numbers on $($list.count) devices in AirWatch"
    
#working, but need to clean up and change logged info to reflect Asset vs wipe.
    foreach ($item in $list) {
        #errors in write-progress because of IndexOf missing in a PSCustomObject
        Write-Progress -Activity "Editing Devices..." -Status "Batch $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/devices?searchBy=Serialnumber&id=$($item.$fileColumn)"
        $json = @{AssetNumber=$item.$assetColumn} | ConvertTo-Json
        try {
            $result = Send-Put -endpoint $endpointURL -body $json -version "application/json;version=1"
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              #put in differnet error checking
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




