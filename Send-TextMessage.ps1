<#
.SYNOPSIS
  Sends SMS message in AirWatch for a list of SerialNumbers
.DESCRIPTION
  
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.PARAMETER message 
    Column title in CSV file containing a Message to send via SMS. This is required. 
.INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  Outputs a log of actions
.NOTES
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  06/30/2021
  Update Date:    06/30/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Send-TextMessage.ps1 -file "Devices.csv" -fileColumn "SerialNumber" message "This is the message to be sent"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber",
   [Parameter(Mandatory=$True,HelpMessage="Message you would like to send")]
   [string]$message
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\TextMessage.log"

Function Write-Log
{
    Param ([string]$logstring)

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $Logfile -value $logstring
}

$list = Read-FileWithData $file $fileColumn

Write-Log "$($MyInvocation.Line)"

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + @($list).count + " devices will be sent this text message through AirWatch: $message",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log "Sending SMS to $($list.count) devices in AirWatch"
    $i = 0
    foreach ($item in $list) {
        $i++
        Write-Progress -Activity "Sending message to Devices..." -Status "$($i) of $($list.Count)" -CurrentOperation "$($item.$fileColumn)" -PercentComplete ((($i)/(@($list).Count))*100)
        $endpointURL = "mdm/devices/messages/sms?searchBy=Serialnumber&id=$($item.$fileColumn)"
        $json = '{ "MessageBody": "' + $message + '" }'
        try {
            $result = Send-Post -endpoint $endpointURL -body $json -version $version1
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              Write-Warning ("Error Sending SMS: $($item.$fileColumn) : Error", $err.errorCode, $err.message)
              Write-Log ("Error Sending SMS: $($item.$fileColumn) : Error", $err.errorCode, $err.message)
            } else {
                Write-Host "$($item.$fileColumn) sent $message. $result"
                Write-Log "$($item.$fileColumn) sent $message. $result"
            }
        }
        catch {
          $err2 = ($Error[0].ErrorDetails.Message)
          Write-Warning "Error Sending SMS: $($item.$fileColumn) to $($item.$assetColumn) $err2"
          Write-Log "Error Sending SMS: $($item.$fileColumn) to $($item.$assetColumn) $err2"
        }
    }
} else {
    Write-Host "Action Cancelled"
    Write-Log "Action Cancelled"
}

