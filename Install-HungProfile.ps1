<#
.SYNOPSIS
  Checks install status of selected profile on a list of devices and if pending or errored sends an install command
.DESCRIPTION
  To do: provide better feedback/more options, choose platform first to eliminate errors selecting profiles with the exact same name.
  .INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.4
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  10/8/2019
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Install-HungProfile.ps1 -serialFile .\Serials.csv
#>

[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing Serial Numbers.")]
   [string]$serialFile,
	
   [Parameter(HelpMessage="Name of Serial Number column in file, default is SerialNumber")]
   [string]$serialFileColumn = "SerialNumber"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

<#
Start of Script
#>

$devicelist = Read-File $serialFile $serialFileColumn
$OrgGroups = Get-OrgGroups
$GroupID = Select-Tag $OrgGroups
$Platform = Select-Platform
$ProfileList = Get-Profiles $GroupID $Platform
$ProfileSelected = Select-Tag $ProfileList

$results = Update-Devices $devicelist $ProfileSelected[1]
$results | Export-Csv -Path "HungProfile${$ProfileSelected}.csv"