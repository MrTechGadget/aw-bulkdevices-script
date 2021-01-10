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
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/08/2021
  Update Date:    01/08/2021
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

$Logfile = "$PSScriptRoot\DeviceDetails.log"

Function Write-Log
{
    Param ([string]$logstring)

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $Logfile -value $logstring
}

$list = Read-File $file $fileColumn

Write-Log "$($MyInvocation.Line)"
Write-Log "Getting Device Details for $($list.count) devices in AirWatch"
$date = Get-Date -Format yyyyMMdd
$endpointURL = "mdm/devices?searchBy=$searchBy"
$DeviceJSON = Set-AddTagJSON $list
$results = Send-Post -endpoint $endpointURL -body $DeviceJSON
try {
    if ($results) {
        $results.Devices | Export-Csv -Path "DevicesDetails${date}.csv"
    } else {
        Write-Log "No Results"
    }
}
catch {
    Write-Log "Error (maybe no results)"
}


