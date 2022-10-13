<#
.SYNOPSIS
  Creates List of Devices that have a particular tag in AirWatch
.DESCRIPTION
  This script displays all tags in the Organization group, allowing the user to select a tag. All of the devices with that tag are exported to a CSV file named for that tag.
  
    This PowerShell script is PowerShell Core compliant and was written with Visual Studio Code on a Mac. It has been tested on Windows and Mac, but should also run on Linux.
    Setup: 
    This script takes an input of serial numbers from a CSV file. Sample Included. 
    It also takes a config file, which houses the API Host, API key and Organization Group ID for your AirWatch environment. 
    A sample file has been included, if you don't have one the script prompt fpr the values and will create it.

.PARAMETER <Parameter_Name>

    Information you will need to use this script:
    userName - An AirWatch account in the tenant is being queried.  This user must have the API role at a minimum. Can be basic or directory user.
    password - The password that is used by the user specified in the username parameter
    tenantAPIKey - This is the REST API key that is generated in the AirWatch Console.  You locate this key at All Settings -> Advanced -> API -> REST, and you will find the key in the API Key field.  If it is not there you may need override the settings and Enable API Access
    airwatchServer - This will be the fully qualified domain name of your AirWatch API server, without the https://.  All of the REST endpoints start with a forward slash (/) so do not include that either.
    organizationGroupId - This will be the organization group Id in the AirWatch console. Not the group name, but the ID.

.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a CSV file with Devices that have the selected tag.
.NOTES
  Version:        1.5
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  09/06/2017
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
  
.EXAMPLE
  Get-ListOfTaggedDevices.ps1
#>

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

<# Start of Script #>
$TagList = Get-Tags
$SelectedTag = Select-Tag $TagList
$TagName = $TagList.keys | Where-Object {$TagList["$_"] -eq [string]$SelectedTag}
$Devices = Get-TaggedDevice $SelectedTag
$DeviceJSON = Set-AddTagJSON $Devices
$DeviceDetails = Get-DeviceDetails $DeviceJSON
$DeviceDetails | Export-Csv -Path "${TagName}.csv"
Write-Host "All Devices with ${TagName} saved to ${TagName}.csv"
