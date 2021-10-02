<#
.SYNOPSIS
  Performs Enterprise Wipe (unenroll) from AirWatch for a list of SerialNumbers
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
  Creation Date:  12/28/2018
  Updated Date:   10/02/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Reset-EnterpriseDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber"
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\EnterpriseWipe.log"

$list = Read-File $file $fileColumn

Write-Log "$($MyInvocation.Line)"

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " devices will be unenrolled from AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log "Wiping $($list.count) devices unenrolled from AirWatch"
    $json = ' '

    foreach ($item in $list) {
        Write-Progress -Activity "Unenrolling Devices..." -Status "Batch $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/devices/commands?command=EnterpriseWipe&searchBy=Serialnumber&id=${item}"
        try {
            $result = Send-Post -endpoint $endpointURL -body $json -version "application/json;version=1"
            if ($result -ne "") {
                Write-Warning "Error Unenrolling Device: $item :$result"
                Write-Log "Error Unenrolling Device: $item :$result"
            } else {
                Write-Host "$item Unenrolled $result"
                Write-Log "$item Unenrolled $result"
            }
        }
        catch {
            Write-Warning "Error Sending Unenroll Command: $item"
            Write-Log "Error Sending Unenroll Command: $item"
        }
    }
} else {
    Write-Host "Unenroll Cancelled"
    Write-Log "Unenroll Cancelled"
}




