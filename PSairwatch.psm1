<#
.SYNOPSIS
  Module for interacting with AirWatch via various REST APIs
.DESCRIPTION
  Module for interacting with AirWatch via various REST APIs
  Use the following to include module in your script
  
    $ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
    Set-Location $ScriptPath 
    Import-Module .\PSairwatch.psm1

.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  AirWatchConfig.json
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         Joshua Clark @audioeng
  Creation Date:  05/22/2018
  
.EXAMPLE
    $ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
    Set-Location $ScriptPath 
    Import-Module .\PSairwatch.psm1
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

Function Read-File {
    Param([string]$file, [string]$head)
    if (Test-Path $file) {
        Write-Verbose "$file exists, importing list."
        $data = Import-Csv -Path $file
        $s = @()
        foreach ($device in $data) {
            $s += $device.$head
            Write-Verbose $device.$head
        }
        return $s
    } else {
        Write-Verbose "$file does not exist."
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
        Write-Host "      No $file file exists, please place file in same directory as script.      " -ForegroundColor Black -BackgroundColor Red
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
    }   
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

Function Get-Tags {
    $endpointURL = "https://${airwatchServer}/api/mdm/tags/search?organizationgroupid=${organizationGroupID}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $TagArray = New-Object System.Collections.Hashtable
    foreach ($tag in $webReturn.Tags) {
        $TagArray.Add($tag.TagName, $tag.Id.Value)
    }
    return $TagArray
}

Function Get-Profiles {
    Param([string]$GroupID, [string]$platform)
    $endpointURL = "https://${airwatchServer}/api/mdm/profiles/search?organizationgroupid=${GroupID}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $Array = New-Object System.Collections.Hashtable
    foreach ($profile in $webReturn.Profiles) {
        if ($profile.Platform -eq $platform) {
            $Array.Add($profile.ProfileName, $profile.Id.Value)
        }
        
    }
    return $Array
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

Function Select-Platform {
    $platforms = @("Apple","Android","WindowsPc","AppleOsX","AppleTV","ChromeOS")
    $selection = $null
    $i=0
    foreach($platform in $platforms)
    {
        Write-Host -ForegroundColor Cyan "  $($i+1)." $platform
        $TagArr += $platform
        $i++
    }
    Write-Host # empty line
    $ans = (Read-Host 'Please enter selection') -as [int]
    $selection = $ans-1
    return $platforms[$selection]
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

Function Set-DeviceIdJSON {
    
    Param([Array]$deviceList,[string]$idType)
    
    Write-Verbose("------------------------------")
    Write-Verbose("Building JSON to Post")
    
    $arrayLength = $deviceList.Count
    $counter = 0
    $quoteCharacter = [char]34

    $addJSON = "{ "
    foreach ($currentDeviceID in $deviceList) {
        $deviceIDString = Out-String -InputObject $currentDeviceID
        $deviceIDString = $deviceIDString.Trim()
    
        $counter = $counter + 1
        if ($counter -lt $arrayLength) {
            $addJSON = $addJSON + $quoteCharacter + $idType + $quoteCharacter + " : " + $deviceIDString + ", "
        } else {
            $addJSON = $addJSON + $quoteCharacter + $idType + $quoteCharacter + " : " + $deviceIDString
        }
    }
    $addJSON = $addJSON + " }"
    
    Write-Verbose($addJSON)
    Write-Verbose("------------------------------")
    Write-Verbose("")
        
    Return $addJSON
}

Function Get-DeviceDetails {
    Param([string]$addTagJSON)
    try {
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/id"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn.Devices
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with the selected tag."
    }

}

Function Set-DeviceIdList {
    Param([object]$Devices)
    $s = @()
    foreach ($device in $Devices) {
        $s += $device.Id.Value
        Write-Verbose $device.Id.Value
    }
    return $s
}

Function Set-DeviceIdListSupervision {
    Param([object]$Devices)
    $t = 0
    $super = @()
    $unsuper = @()
    foreach ($device in $Devices) {
        if ($device.EnrollmentStatus -eq "Enrolled") {
            if ($device.IsSupervised -eq $True) {
                $super += $device.Id.Value
                Write-Verbose "$($device.Id.Value) is supervised"
            } else {
                $unsuper += $device.Id.Value
                Write-Verbose "$($device.Id.Value) is unsupervised"
            }
        } else {
            Write-Verbose "$($device.SerialNumber) is not enrolled, skipping"
            $t++
        }
    }
    Write-Host "Skipped $t devices that are not enrolled."
    $s = $unsuper,$super
    return $s
}

Function Install-PublicApp { 
    Param([string]$addJSON,[string]$appId)
    try {
        $endpointURL = "https://${airwatchServer}/api/mam/apps/public/$appId/install"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addJSON
       
        return $webReturn
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with that device id."
    }

}

Function Remove-Device-EnterpriseWipe { # Enterprise Wipes List of devices by device id
    Param([string]$body)
    try {
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/commands/bulk?command=enterprisewipe&searchby=deviceid"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $body
       
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

Function Set-DaysPrior {
    do {
        try {
            $numOk = $true
            [int]$days = Read-Host -Prompt "Input how many days since the devices were last seen. (Between 15 and 200"
            } # end try
        catch {$numOK = $false}
        } # end do 
    until (($days -ge 15 -and $days -lt 201) -and $numOK)
    return 0-$days
}

Function Set-LastSeenDate {
    Param([int]$days)
    $date = Get-Date
    $lastseendate = $date.AddDays($days)
    $ls = Get-Date -Date $lastseendate -Format "yyyy-MM-dd"
    return $ls
}

Function Check-Devices {
    Param([array]$devices, $profile)
    $body = ""
    $quoteCharacter = [char]34
    foreach ($deviceid in $devices) {
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/profiles?searchBy=Serialnumber&id=$deviceid"
            $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers 
            if ($webReturn) {
                $r = $webReturn.DeviceProfiles | where { $_.Id.Value -eq $profile}
                if ($r.Status -eq 1) {
                    $devid = $webReturn.DeviceId.Id.Value
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$profile/install"
                    $body = "{ " + $quoteCharacter + "SerialNumber" + $quoteCharacter + " : " + $quoteCharacter + $deviceid + $quoteCharacter +" }"
                    $webReturn2 = Invoke-RestMethod -Method Post -Uri $endpointURL2 -Headers $headers -Body $body
                    Write-Host $devid  "  install queued   " + $webReturn2
                } elseif ($r.Status -eq 0) {
                    $devid = $webReturn.DeviceId.Id.Value
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$profile/install"
                    $body = "{ " + $quoteCharacter + "SerialNumber" + $quoteCharacter + " : " + $quoteCharacter + $deviceid + $quoteCharacter +" }"
                    $webReturn2 = Invoke-RestMethod -Method Post -Uri $endpointURL2 -Headers $headers -Body $body
                    Write-Host $devid  "  install queued   " + $webReturn2
                } elseif ($r.Status -eq 3) {
                    Write-Host $webReturn.DeviceId.Id.Value profile already installed.
                } elseif ($r.Status -eq 6) {
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$profile/install"
                    $body = "{ " + $quoteCharacter + "SerialNumber" + $quoteCharacter + " : " + $quoteCharacter + $deviceid + $quoteCharacter +" }"
                    $webReturn2 = Invoke-RestMethod -Method Post -Uri $endpointURL2 -Headers $headers -Body $body
                    Write-Host $devid  "  Previous Error, install queued   " + $webReturn2
                }
            }
        }
        catch {
            $e = [int]$Error[0].Exception.Response.StatusCode
            Write-Host "Error with device $deviceid. Status code $e. May not be any devices with that serial."
        }
    }
}
Export-ModuleMember -Function Read-File, Get-BasicUserForAuth, Build-Headers, Get-Tags, Get-Profiles, Get-OrgGroups, Select-Platform, Select-Tag, Get-Device, Set-AddTagJSON, Set-DeviceIdJSON, Get-DeviceDetails, Set-DeviceIdList, Set-DeviceIdListSupervision, Install-PublicApp, Remove-Device-EnterpriseWipe, Remove-Device-FullWipe, Set-DaysPrior, Set-LastSeenDate, Check-Devices