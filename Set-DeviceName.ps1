<#
.SYNOPSIS
  Sets DeviceName on Supervised iOS Device(s) given a list of SerialNumbers and Desired names.
.DESCRIPTION
  Sets DeviceName on Supervised iOS Device(s) given a list of SerialNumbers and Desired names. Uses the CustomMdmCommand API to directly set the FriendlyName of the device (The name in Settings -> General -> About)
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers and desired Asset Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.PARAMETER deviceColumn 
    Column title in CSV file containing DeviceName values.  This is optional, with a default value of "DeviceName". 
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/15/2020
  Update Date:    01/15/2020
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Set-DeviceName.ps1 -file "Devices.csv" -fileColumn "SerialNumber" -deviceColumn "DeviceName"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber",
   [Parameter(HelpMessage="Name of desired asset column in file, default is DeviceName")]
   [string]$deviceColumn = "DeviceName"
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\DeviceName.log"

Function Write-Log
{
    Param ([string]$logstring)

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $Logfile -value $logstring
}

$list = Read-FileWithData $file $fileColumn $deviceColumn

Write-Log "$($MyInvocation.Line)"

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + @($list).count + " devices will have their DeviceName overwritten in AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log "Replacing DeviceName on $($list.count) devices in AirWatch"
    $i = 0
    foreach ($item in $list) {
        $i++
        Write-Progress -Activity "Editing Devices..." -Status "$($i) of $($list.Count)" -CurrentOperation "$($item.$fileColumn) : $($item.$deviceColumn)" -PercentComplete ((($i)/(@($list).Count))*100)
        $endpointURL = "mdm/devices/commands?command=CustomMdmCommand&searchBy=Serialnumber&id=$($item.$fileColumn)"
        $xmlcommand = "<dict><key>RequestType</key><string>Settings</string><key>Settings</key><array><dict><key>Item</key><string>DeviceName</string><key>DeviceName</key><string>$($item.$deviceColumn)</string></dict></array></dict>"
        $json = @{CommandXml=$xmlcommand} | ConvertTo-Json
        try {
            $result = Send-Post -endpoint $endpointURL -body $json -version $version1
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              Write-Warning ("Error Setting DeviceName: $($item.$fileColumn) : Error", $err.errorCode, $err.message)
              Write-Log ("Error Setting DeviceName: $($item.$fileColumn) : Error", $err.errorCode, $err.message)
            } else {
                Write-Host "$($item.$fileColumn) set to $($item.$deviceColumn) $result"
                Write-Log "$($item.$fileColumn) set to $($item.$deviceColumn) $result"
            }
        }
        catch {
          $err2 = ($Error[0].ErrorDetails.Message)
          Write-Warning "Error Setting DeviceName: $($item.$fileColumn) to $($item.$deviceColumn) $err2"
          Write-Log "Error Setting DeviceName: $($item.$fileColumn) to $($item.$deviceColumn) $err2"
        }
    }
} else {
    Write-Host "Action Cancelled"
    Write-Log "Action Cancelled"
}

