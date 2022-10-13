<#
.SYNOPSIS
  Gets Device Details given a list of SerialNumbers and Desired names.
.DESCRIPTION
  Gets Device Details given a list of SerialNumbers and Desired names. 
.PARAMETER file 
    Path of a CSV file with a list of Serial Numbers and desired Asset Numbers.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 
.PARAMETER searchBy 
    Type of Id to search by.  This is optional, with a default value of "SerialNumber". 
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/08/2021
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Get-DeviceDetails.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber",

   [Parameter(HelpMessage="Type of Id to search by, default is SerialNumber")]
   [string]$searchBy = "SerialNumber"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\DeviceDetails.log"

$list = Read-File $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile
Write-Log -logstring "Getting Device Details for $($list.count) devices in AirWatch" -logfile $Logfile
$date = Get-Date -Format yyyyMMdd
$endpointURL = "mdm/devices?searchBy=$searchBy"
$DeviceJSON = Set-AddTagJSON $list
$results = Send-Post -endpoint $endpointURL -body $DeviceJSON
try {
    if ($results) {
        $results.Devices | Export-Csv -Path "DevicesDetails${date}.csv"
    } else {
        Write-Log -logstring "No Results" -logfile $Logfile
    }
}
catch {
    Write-Log -logstring "Error (maybe no results)" -logfile $Logfile
}


