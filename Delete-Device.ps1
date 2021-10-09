<#
.SYNOPSIS
  Deletes device record from Workspace ONE UEM for a list of SerialNumbers
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
  Version:        1.1
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/02/2021
  Updated Date:   10/08/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Delete-Device.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber"
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\DeleteDevice.log"
$list = Read-File $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " device records will be deleted from Workspace ONE UEM",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log -logstring "Wiping $($list.count) devices deleted from Workspace ONE UEM" -logfile $Logfile
    $json = ' '

    #$DeletedDevices = Remove-DeviceBulk $DeviceJSON

    foreach ($item in $list) {
        Write-Progress -Activity "Deleting Devices..." -Status "Batch $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/devices?searchBy=Serialnumber&id=${item}"
        try {
            $result = Send-Delete -endpoint $endpointURL -body $json -version "application/json;version=1"
            if ($result -ne "") {
                Write-Warning "Error Deleting Device: $item :$result"
                Write-Log -logstring "Error Deleting Device: $item :$result" -logfile $Logfile
            } else {
                Write-Host "$item Deleted $result"
                Write-Log -logstring "$item Deleted $result" -logfile $Logfile
            }
        }
        catch {
            Write-Warning "Error Deleting: $item"
            Write-Log -logstring "Error Deleting: $item" -logfile $Logfile
        }
    }
} else {
    Write-Host "Delete Cancelled"
    Write-Log -logstring "Delete Cancelled" -logfile $Logfile
}

