
<# Set-TagOnDevice Powershell Script Help
  .SYNOPSIS
    This Poweshell script adds a selected tag to a list of devices.
  .DESCRIPTION
    This script will take an input of serial numbers from a CSV file, converts them to device IDs. 
    It queries a list of all Tags in the environment, the user selects the Tag to add the devices to and it adds the Tag in AirWatch for each of those devices.
  .INPUTS
    CSV File with headers
  .OUTPUTS
    NO OUTPUT CURRENTLY:Outputs a log of actions
  .NOTES
    Version:        1.4
    Author:         Joshua Clark @MrTechGadget
    Creation Date:  09/06/2017
    Update Date:    10/25/2022
    Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
  .EXAMPLE
    .\Set-TagOnDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"
#>

[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,HelpMessage="Path to file listing SerialNumbers.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is SerialNumber")]
   [string]$fileColumn = "SerialNumber"
)

Function Set-Action {
    $options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Add", "&Remove")
    [int]$defaultchoice = 0
    $opt = $host.UI.PromptForChoice($Title , $Info , $Options,$defaultchoice)
    switch($opt)
    {
    0 { return "add"}
    1 { return "remove"}
    }
}



Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\TagActivity.log"

<# 
Start of Script
#>

$Config = Read-Config
$tenantAPIKey = $Config.awtenantcode
$organizationGroupID = $Config.groupid
$airwatchServer = $Config.host
$list = Read-File $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

<# Get the tags, displays them to the user to select which tag to add. #>
$TagList = Get-Tags
$SelectedTag = Select-Tag $TagList
$TagName = $TagList.keys | Where-Object {$TagList["$_"] -eq [string]$SelectedTag}
Write-Host "Selected Tag: $($TagName)"
Write-Log -logstring "Selected Tag: $($TagName)" -logfile $Logfile

$action = Set-Action
$SerialJSON = Set-AddTagJSON $list
$deviceIds = Get-DeviceIds $SerialJSON
$addTagJSON = Set-AddTagJSON $deviceIds
$endpointURL = "mdm/tags/${SelectedTag}/${action}devices"
$results = Send-Post $endpointURL $addTagJSON

Write-Host("------------------------------")
Write-Host("Results of ${action} Tags Call")
Write-Host("Total Items: " +$results.TotalItems)
Write-Host("Accepted Items: " + $results.AcceptedItems)
Write-Host("Failed Items: " + $results.FailedItems)
Write-Host("------------------------------")
Write-Log -logstring "Results of ${action} Tags Call, Total Items: $($results.TotalItems), Accepted Items: $($results.AcceptedItems), Failed Items: $($results.FailedItems)" -logfile $Logfile
