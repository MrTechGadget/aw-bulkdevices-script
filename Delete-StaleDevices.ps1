<#
.SYNOPSIS
  Deletes device records for unenrolled devices that have not checked in with AirWatch since a configurable number of days ago.
.DESCRIPTION
  This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
  The user then enters a number of days(X) since the devices have been last seen.
  All of the devices in that organization group (and child org groups) that have not been seen since X days and are pending 
  enterprise wipe are deleted are exported to a CSV file named with that date.
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  Outputs a CSV file with Devices that have not been seen in X number of days that have been deleted.
.NOTES
  Version:        1.1
  Author:         Joshua Clark @audioeng
  Creation Date:  09/15/2017
  Site:           https://github.com/audioeng/aw-bulkdevices-script
.EXAMPLE
  Get-ListOfStaleDevices.ps1
#>



Function Read-Config {
    try {
        if (Test-Path "AirWatchConfig.json") {
            $h = (Get-Content "AirWatchConfig.json") -join "`n" | ConvertFrom-Json
            Write-Verbose "Config file loaded."
        } else {
            Write-Verbose "No config file exists, please complete the sample config and name the file AirWatchConfig.json "
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
            Write-Host "No config file exists, please complete the sample config and name the file AirWatchConfig.json " -ForegroundColor Black -BackgroundColor Red
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
        }
        if ($h.groupid -and $h.awtenantcode -and $h.host) {
            Write-Verbose "Config file formatted correctly."
            return $h
        } else {
            Write-Verbose "ConfigFile not correct, please complete the sample config and name the file AirWatchConfig.json"
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
            Write-Host "ConfigFile not correct, please complete the sample config and name the file AirWatchConfig.json" -ForegroundColor Black -BackgroundColor Red
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
        }
    }
    catch {
        Write-Verbose "No config file exists, please complete the sample config and name the file AirWatchConfig.json"
        Write-Host "No config file exists, please complete the sample config and name the file AirWatchConfig.json"
    }
}

<#  This implementation uses Basic authentication. #>
Function Get-BasicUserForAuth {
    $Credential = Get-Credential
    $EncodedUsernamePassword = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($('{0}:{1}' -f $Credential.UserName,$Credential.GetNetworkCredential().Password)))
    
    Return "Basic " + $EncodedUsernamePassword
}

Function Build-Headers {

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

Function Get-OrgGroups {
    $endpointURL = "https://${airwatchServer}/api/system/groups/search?orderby=name"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $OrgArray = New-Object System.Collections.Hashtable
    foreach ($org in $webReturn.LocationGroups) {
        $OrgArray.Add($org.Name, $org.Id.Value)
    }
    return $OrgArray
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
    return $TagList.$selectedTag
}

Function Get-Device {
    Param([string]$lastseen, [string]$lgid)


    $endpointURL = "https://${airwatchServer}/api/mdm/devices/search?lastseen=${lastseen}&lgid=${lgid}&orderby=lastseen&sortorder=DESC"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    Write-Host "Total of $($webReturn.Total) devices match search, returning the first 500 results."
    return $webReturn.Devices
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

Function Get-DeviceDetails {
    Param([string]$addTagJSON)
    try {
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/id"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn.Devices
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices matching."
    }

}

Function Set-DeviceIdList {
    Param([object]$Devices)
    $t = 0
    $entwipe = @()
    foreach ($device in $Devices) {
        if ($device.EnrollmentStatus -eq "EnterpriseWipePending") {
            $entwipe += $device.Id.Value
        } else {
            Write-Verbose "$($device.SerialNumber) is not pending Enterprise Wipe, skipping"
            $t++
        }
    }
    Write-Host "Skipped $t devices that are not pending enterprise wipe."
    return $entwipe
}

Function Remove-Device-EnterpriseWipe { # Enterprise Wipes List of devices by device id
    Param([string]$addTagJSON)
    try {
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/commands/bulk?command=enterprisewipe&searchby=deviceid
"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with that device id."
    }

}

Function Remove-Device-FullWipe { # Enterprise Wipes List of devices by device id
    Param([array]$devices)
    $body = ""
    $arr = @()
    foreach ($deviceid in $devices) {
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/${deviceid}/commands?command=DeviceWipe"
            $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $body
            if ($webReturn) {
                $arr += $webReturn
            }
        }
    catch {
        $e = [int]$Error[0].Exception.Response.StatusCode
        Write-Host "Error wiping device $deviceid. Status code $e. May not be any devices with that device id."
        return $e
    }
    }

    return $arr
}

Function Delete-DeviceBulk {
    Param([string]$addTagJSON)
    try {
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/bulk"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn
    }
    catch {
        return [int]$Error[0].Exception.Response.StatusCode
    }

}

Function Set-DaysPrior {
    do {
        try {
            $numOk = $true
            [int]$days = Read-Host -Prompt "Input how many days since the devices were last seen"
            } # end try
        catch {$numOK = $false}
        } # end do 
    until (($days -ge 1 -and $days -lt 200) -and $numOK)
    return 0-$days
}

Function Set-LastSeenDate {
    Param([int]$days)
    $date = Get-Date
    $lastseendate = $date.AddDays($days)
    $ls = Get-Date -Date $lastseendate -Format "yyyy-MM-dd"
    return $ls
}

<#
Start of Script
#>

<# Set configurations #>
$restUserName = Get-BasicUserForAuth
$Config = Read-Config
$tenantAPIKey = $Config.awtenantcode
$organizationGroupID = $Config.groupid
$airwatchServer = $Config.host

<# Build the headers and send the request to the server. #>
$useJSON = "application/json"
$headers = Build-Headers $restUserName $tenantAPIKey $useJSON $useJSON
$OrgGroups = Get-OrgGroups
$GroupID = Select-Tag $OrgGroups
$DaysPrior = Set-DaysPrior
$LastSeenDate = Set-LastSeenDate $DaysPrior
Write-Host("------------------------------")
Write-Host("")
Write-Host "Devices last seen on or before " + $LastSeenDate 
$Devices = Get-Device $LastSeenDate $GroupID
$DeviceList = Set-DeviceIdList $Devices
$DeviceJSON = Set-AddTagJSON $DeviceList
$DeviceDetails = Get-DeviceDetails $DeviceJSON
if ($DeviceList.Count -ne 0) {
    Write-Host $DeviceList.Count "Pending Enterprise Wipe Devices exported"
    $DeviceDetails | Export-Csv -Path "EntWipeDevicesLastSeen${LastSeenDate}.csv"
}
Write-Host("------------------------------")
Write-Host("")
$DeletedDevices = Delete-DeviceBulk $DeviceJSON

Write-Host("------------------------------")
if ($DeletedDevices -eq 404) {
    Write-Host "No devices found pending enterprise wipe in that time frame."
} else {
    $DeletedDevices
}
