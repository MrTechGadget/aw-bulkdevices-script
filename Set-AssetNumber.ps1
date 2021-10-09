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
  Version:        1.5
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/14/2020
  Update Date:    10/08/2021
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

$list = Read-FileWithData $file $fileColumn $assetColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + @($list).count + " devices will have their AssetNumber overwritten in AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log -logstring "Replacing asset numbers on $($list.count) devices in AirWatch" -logfile $Logfile
    $i = 0
    foreach ($item in $list) {
        $i++
        Write-Progress -Activity "Editing Devices..." -Status "$($i) of $($list.Count)" -CurrentOperation "$($item.$fileColumn) : $($item.$assetColumn)" -PercentComplete ((($i)/(@($list).Count))*100)
        $endpointURL = "mdm/devices?searchBy=Serialnumber&id=$($item.$fileColumn)"
        $json = @{AssetNumber=$item.$assetColumn} | ConvertTo-Json
        try {
            $result = Send-Put -endpoint $endpointURL -body $json -version $version1
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              Write-Warning ("Error Setting AssetNumber: $($item.$fileColumn) : Error", $err.errorCode, $err.message)
              Write-Log -logstring ("Error Setting AssetNumber: $($item.$fileColumn) : Error", $err.errorCode, $err.message) -logfile $Logfile
            } else {
                Write-Host "$($item.$fileColumn) set to $($item.$assetColumn) $result"
                Write-Log -logstring "$($item.$fileColumn) set to $($item.$assetColumn) $result" -logfile $Logfile
            }
        }
        catch {
          $err2 = ($Error[0].ErrorDetails.Message)
          Write-Warning "Error Setting AssetNumber: $($item.$fileColumn) to $($item.$assetColumn) $err2"
          Write-Log -logstring "Error Setting AssetNumber: $($item.$fileColumn) to $($item.$assetColumn) $err2" -logfile $Logfile
        }
    }
} else {
    Write-Host "Action Cancelled"
    Write-Log -logstring "Action Cancelled" -logfile $Logfile
}
