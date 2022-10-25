
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

<# Reads Serial Numbers from Serials.csv file and outputs array of serial numbers. #>
Function Read-Serials {
    if (Test-Path "Serials.csv") {
        Write-Verbose "Serials.csv exists, importing list."
        $data = Import-Csv -Path Serials.csv
        $s = @()
        foreach ($device in $data) {
            $s += $device.SerialNumber
            Write-Verbose $device.SerialNumber
        }
        return $s
    } else {
        Write-Verbose "Serials.csv does not exist."
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
        Write-Host "      No Serials.csv file exists, please place file in same directory as script.      " -ForegroundColor Black -BackgroundColor Red
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
    }
    
}

Function Set-Headers {

    Param([string]$authoriztionString, [string]$tenantCode, [string]$acceptType, [string]$contentType)

    $authString = $authoriztionString
    $tcode = $tenantCode
    $accept = $acceptType
    $content = $contentType

    Write-Verbose("---------- Headers ----------")
    Write-Verbose("Authorization: " + $authString)
    Write-Verbose("aw-tenant-code:" + $tcode)
    Write-Verbose("Accept: " + $accept)
    Write-Verbose("Content-Type: " + $content)
    Write-Verbose("------------------------------")
    Write-Verbose("")
    $header = @{"Authorization" = $authString; "aw-tenant-code" = $tcode; "Accept" = $useJSON; "Content-Type" = $useJSON}
     
    Return $header
}

<#  This function builds the JSON to add the tag to all of the devices. #>
Function Set-AddTagJSON {

    Param([Array]$deviceList)

    Write-Verbose("------------------------------")
    Write-Verbose("Building JSON to Post")

    $arrayLength = $deviceList.Count
    $counter = 0
    $quoteCharacter = [char]34
    
    $addTagJSON = "{ " + $quoteCharacter + "BulkValues" + $quoteCharacter + " : { " + $quoteCharacter + "Value" + $quoteCharacter + " : [ "
    foreach ($currentDeviceID in $deviceList) {
        $deviceIDString = Out-String -InputObject $currentDeviceID
        $deviceIDString = $deviceIDString.Trim()

        $counter = $counter + 1
        if ($counter -lt $arrayLength) {
            $addTagJSON = $addTagJSON + $quoteCharacter + $deviceIDString + $quoteCharacter + ", "
        } else {
            $addTagJSON = $addTagJSON + $quoteCharacter + $deviceIDString + $quoteCharacter
        }
    }
    $addTagJSON = $addTagJSON + " ] } }"

    Write-Verbose($addTagJSON)
    Write-Verbose("------------------------------")
    Write-Verbose("")
    
    Return $addTagJSON
}

Function Get-Tags {
    $endpointURL = "https://${airwatchServer}/api/mdm/tags/search?organizationgroupid=${organizationGroupID}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $TagArray = New-Object System.Collections.Specialized.OrderedDictionary
    foreach ($tag in $webReturn.Tags) {
        $TagArray.Add($tag.TagName, $tag.Id.Value)
    }
    return $TagArray 
}

Function Select-Tag {
    Param([object]$TagList)

    $selection = $null
    
    Do
    {
        $mhead
        Write-Host # empty line
        $TagArr = @()
        $i=0
        foreach($tag in $TagList.keys)
        {
            Write-Host -ForegroundColor Cyan "  $($i+1)." $tag
            $TagArr += $tag
            $i++
        }
        Write-Host # empty line
        $ans = (Read-Host 'Please enter selection') -as [int]
    
    } While ((-not $ans) -or (0 -gt $ans) -or ($TagList.Count -lt $ans))
    
    $selection = $ans-1
    $selectedTag = $TagArr[$selection]
    $TagNum = [string]$TagList.$selectedTag
    return $TagNum
}

Function Get-DeviceIds {
    Param([string]$addTagJSON)

    Write-Verbose("------------------------------")
    Write-Verbose("List of Serial Numbers")
    Write-Verbose $addTagJSON
    Write-Verbose("------------------------------")

    $endpointURL = "https://${airwatchServer}/api/mdm/devices?searchby=Serialnumber"
    $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON

    $deviceids = @()
    foreach ($serial in $webReturn.Devices) {
        $deviceids += $serial.Id.Value
    }
    Write-Verbose("------------------------------")
    Write-Verbose("List of Device IDs")
    #Write-Verbose $deviceIds
    Write-Verbose("------------------------------")

    return $deviceids
}

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

Function Set-DeviceTags {
    Param([string]$selectedtag,[string]$addTagJSON,[string]$verb)

    $endpointURL = "https://${airwatchServer}/api/mdm/tags/${selectedtag}/${verb}devices"
    $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
    
    Write-Verbose("------------------------------")
    Write-Verbose("Results of ${verb} Tags Call")
    Write-Verbose("Total Items: " +$webReturn.TotalItems)
    Write-Verbose("Accepted Items: " + $webReturn.AcceptedItems)
    Write-Verbose("Failed Items: " + $webReturn.FailedItems)
    Write-Verbose("------------------------------")

    return $webReturn

}

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\TagActivity.log"

<# 
Start of Script
#>

$serialList = Read-Serials
$restUserName = Get-BasicUserForAuth
$Config = Read-Config
$tenantAPIKey = $Config.awtenantcode
$organizationGroupID = $Config.groupid
$airwatchServer = $Config.host


<# Build the headers and send the request to the server. #>
$useJSON = "application/json"
$headers = Set-Headers $restUserName $tenantAPIKey $useJSON $useJSON

<# Get the tags, displays them to the user to select which tag to add. #>
$TagList = Get-Tags
$SelectedTag = Select-Tag $TagList
$TagName = $TagList.keys | Where-Object {$TagList["$_"] -eq [string]$SelectedTag}
Write-Host "Selected Tag: "$TagName

$action = Set-Action
$SerialJSON = Set-AddTagJSON $serialList
$deviceIds = Get-DeviceIds $SerialJSON
$addTagJSON = Set-AddTagJSON $deviceIds
$results = Set-DeviceTags $SelectedTag $addTagJSON $action

Write-Host("------------------------------")
Write-Host("Results of ${action} Tags Call")
Write-Host("Total Items: " +$results.TotalItems)
Write-Host("Accepted Items: " + $results.AcceptedItems)
Write-Host("Failed Items: " + $results.FailedItems)
Write-Host("------------------------------")

