<#
.SYNOPSIS
  Gets Profiles with optional query parameters to limit results.
.DESCRIPTION
  Gets Profiles with optional query parameters to limit results. 
.PARAMETER query 
    Optional query parameters to refine search. For values, refer to API documentation. https://as135.awmdm.com/api/help/#!/apis/10003?!/ProfilesV2/ProfilesV2_Search 
    Multiple parameters should be joined with "&"
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  Outputs a CSV: "Profiles[today's date].csv"
.NOTES
  Version:        1.0
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/09/2021
  Update Date:    01/09/2021
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Get-Profiles.ps1 -query "status=Active&platform=Apple"
#>


[CmdletBinding()] 
Param(
   [Parameter(HelpMessage="Optional query parameters to refine search. For values, refer to API documentation. https://as135.awmdm.com/api/help/#!/apis/10003?!/ProfilesV2/ProfilesV2_Search")]
   [string]$query
)

Import-Module .\PSairwatch.psm1

$Logfile = "$PSScriptRoot\Profiles.log"

Function Write-Log
{
    Param ([string]$logstring)

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $Logfile -value $logstring
}

Write-Log "$($MyInvocation.Line)"
Write-Log "Getting Profiles in AirWatch"
$date = Get-Date -Format yyyyMMdd
if ($query) {
  $endpointURL = "mdm/profiles/search?$query"
} else {
  $endpointURL = "mdm/profiles/search"
}
$results = Send-Get -endpoint $endpointURL -version "application/json;version=2"
try {
    if ($results) {
        Write-Log "$($results.ProfileList.Length) Profiles returned out of $($results.TotalResults) total, writing csv."
        $results.ProfileList | Export-Csv -Path "Profiles${date}.csv"
    } else {
        Write-Log "No Results"
    }
}
catch {
    Write-Log "Error (maybe no results)  $_"
}


