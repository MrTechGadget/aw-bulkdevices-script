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
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  12/28/2018
  Updated Date:   10/13/2022
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
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\EnterpriseWipe.log"

$list = Read-File $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " devices will be unenrolled from AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log -logstring "Wiping $($list.count) devices unenrolled from AirWatch" -logfile $Logfile
    $json = ' '

    foreach ($item in $list) {
        Write-Progress -Activity "Unenrolling Devices..." -Status "Batch $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/devices/commands?command=EnterpriseWipe&searchBy=Serialnumber&id=${item}"
        try {
            $result = Send-Post -endpoint $endpointURL -body $json -version "application/json;version=1"
            if ($result -ne "") {
                Write-Warning "Error Unenrolling Device: $item :$result"
                Write-Log -logstring "Error Unenrolling Device: $item :$result" -logfile $Logfile
            } else {
                Write-Host "$item Unenrolled $result"
                Write-Log -logstring "$item Unenrolled $result" -logfile $Logfile
            }
        }
        catch {
            Write-Warning "Error Sending Unenroll Command: $item"
            Write-Log -logstring "Error Sending Unenroll Command: $item" -logfile $Logfile
        }
    }
} else {
    Write-Host "Unenroll Cancelled"
    Write-Log -logstring "Unenroll Cancelled" -logfile $Logfile
}
