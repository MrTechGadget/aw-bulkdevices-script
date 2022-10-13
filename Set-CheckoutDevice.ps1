<#
.SYNOPSIS
  Assigns staged device to user via checkout API.
.DESCRIPTION
  Assigns staged device to user via checkout API. Requires a CSV file with DeviceId and desired UserId columns
.PARAMETER file 
    Path of a CSV file with a list of DeviceId and desired UserId.  This is required. 
.PARAMETER deviceColumn 
    Column title in CSV file containing DeviceId values.  This is optional, with a default value of "DeviceId". 
.PARAMETER userColumn 
    Column title in CSV file containing UserId values.  This is optional, with a default value of "UserId". 
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/11/2021
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Set-CheckoutDevice.ps1 -file "Devices.csv" -deviceColumn "DeviceId" -userColumn "UserId"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing DeviceIds and UserIds.")]
   [string]$file,
   [Parameter(HelpMessage="Name of Id column in file, default is DeviceId")]
   [string]$deviceColumn = "DeviceId",
   [Parameter(HelpMessage="Name of desired UserId column in file, default is UserId")]
   [string]$userColumn = "UserId"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\Checkout.log"

$list = Read-FileWithData $file $deviceColumn $userColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + @($list).count + " devices will be assigned to the corresponding user identified in this file in AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log -logstring "Assigning to users on $($list.count) devices in AirWatch" -logfile $Logfile
    $i = 0
    foreach ($item in $list) {
        $i++
        Write-Progress -Activity "Assigning Devices..." -Status "$($i) of $($list.Count)" -CurrentOperation "$($item.$deviceColumn) : $($item.$userColumn)" -PercentComplete ((($i)/(@($list).Count))*100)
        $endpointURL = "mdm/devices/$($item.$deviceColumn)/enrollmentuser/$($item.$userColumn)"
        try {
            $result = Send-Patch -endpoint $endpointURL -version $version2
            if ($result -ne "") {
              $err = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
              Write-Warning ("Error Assigning DeviceName: $($item.$deviceColumn) : Error", $err.errorCode, $err.message)
              Write-Log -logstring ("Error Assigning DeviceName: $($item.$deviceColumn) : Error", $err.errorCode, $err.message) -logfile $Logfile
            } else {
                Write-Host "$($item.$deviceColumn) assigned to $($item.$userColumn) $result"
                Write-Log -logstring "$($item.$deviceColumn) assigned to $($item.$userColumn) $result" -logfile $Logfile
            }
        }
        catch {
          $err2 = ($Error[0].ErrorDetails.Message | ConvertFrom-Json)
          Write-Warning "Error Assigning DeviceName: $($item.$deviceColumn) to $($item.$userColumn) $err2"
          Write-Log -logstring "Error Assigning DeviceName: $($item.$deviceColumn) to $($item.$userColumn) $err2" -logfile $Logfile
        }
    }
} else {
    Write-Host "Action Cancelled"
    Write-Log -logstring "Action Cancelled" -logfile $Logfile
}
