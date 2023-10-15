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
  Version:        1.4
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/09/2021
  Update Date:    10/14/2023
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Get-Profile.ps1 -query "status=Active&platform=Apple"
#>


[CmdletBinding()] 
Param(
   [Parameter(HelpMessage="Optional query parameters to refine search. For values, refer to API documentation. https://as135.awmdm.com/api/help/#!/apis/10003?!/ProfilesV2/ProfilesV2_Search")]
   [string]$query
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\Profiles.log"

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile
Write-Log -logstring "Getting Profiles in AirWatch" -logfile $Logfile
$date = Get-Date -Format yyyyMMdd
if ($query) {
  $endpointURL = "mdm/profiles/search?$query&PageSize=500"
} else {
  $endpointURL = "mdm/profiles/search"
}
$results = Send-Get -endpoint $endpointURL -version "application/json;version=2"

try {
  if ($results.ProfileList) {
    Write-Log -logstring "$($results.ProfileList.Length) Profiles returned out of $($results.TotalResults) total, writing csv." -logfile $Logfile
    Write-Host "$($results.ProfileList.Length) Profiles returned out of $($results.TotalResults) total, writing csv."
    $results.ProfileList | Export-Csv -Path "Profiles${query}.csv"
  } else {
    Write-Log -logstring "No Results" -logfile $Logfile
  }
}
catch {
  Write-Log -logstring "Error (maybe no results)  $_" -logfile $Logfile
}


