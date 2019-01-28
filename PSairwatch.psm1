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
  Version:        2.1.0
  Author:         Joshua Clark @MrTechGadget
  Source:         https://github.com/MrTechGadget/aw-bulkdevices-script
  Creation Date:  05/22/2018
  Update Date:    01/28/2018
  
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
        if ($data.$head) {
            foreach ($device in $data) {
                try {
                    $s += $device.$head
                    Write-Verbose -Message "$device.$head"
                } catch {
                    Write-Error -Message "Failed to add $device to list."
                }
            }
        } else {
            Write-Error -Message "No such column, $head, in CSV file $file."
        }

        return $s
    } else {
        Write-Verbose "$file does not exist."
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
        Write-Host "      No $file file exists, please place file in same directory as script.      " -ForegroundColor Black -BackgroundColor Red
        Write-Host "--------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
    }   
}

Function Set-Header {

    Param([string]$authorizationString, [string]$tenantCode, [string]$acceptType, [string]$contentType)

    $authString = $authorizationString
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
    $header = @{"Authorization" = $authString; "aw-tenant-code" = $tcode; "Accept" = $accept; "Content-Type" = $content}
     
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
    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
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
        Write-Host 
        $TagArr = @()
        $i=0
        foreach($tag in $TagList.keys)
        {
            Write-Host -ForegroundColor Cyan "  $($i+1)." $tag
            $TagArr += $tag
            $i++
        }
        Write-Host 
        $ans = (Read-Host 'Please enter selection') -as [int]
    
    } While ((-not $ans) -or (0 -gt $ans) -or ($TagList.Count -lt $ans))
    
    $selection = $ans-1
    $selectedTag = $TagArr[$selection]
    return $TagList.$selectedTag
}

Function Get-Device {
    Param([string]$lastseen, [string]$lgid, [string]$pageSize = "500")

    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    $endpointURL = "https://${airwatchServer}/api/mdm/devices/search?lastseen=${lastseen}&lgid=${lgid}&orderby=lastseen&sortorder=DESC&pagesize=${pageSize}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    Write-Host "Total of $($webReturn.Total) devices match search, returning the first ${pageSize} results."
    return $webReturn.Devices
}

<#  This function builds the JSON to add the tag to all of the devices. #>
Function Set-AddTagJSON {

    Param([Array]$items)
    
    Write-Verbose("------------------------------")
    Write-Verbose("Building JSON to Post")
    
    $arrayLength = $items.Count
    $counter = 0
    $quoteCharacter = [char]34

    $addTagJSON = "{ " + $quoteCharacter + "BulkValues" + $quoteCharacter + " : { " + $quoteCharacter + "Value" + $quoteCharacter + " : [ "
    foreach ($item in $items) {
        $itemString = Out-String -InputObject $item
        $itemString = $itemString.Trim()
    
        $counter = $counter + 1
        if ($counter -lt $arrayLength) {
            $addTagJSON = $addTagJSON + $quoteCharacter + $itemString + $quoteCharacter + ", "
        } else {
            $addTagJSON = $addTagJSON + $quoteCharacter + $itemString + $quoteCharacter
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
        $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/id"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn.Devices
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with the selected tag."
    }

}

Function Send-Post {
    Param(
        [Parameter(Mandatory=$True,HelpMessage="Rest Endpoint for POST, after https://airwatchServer/api/")]
        [string]$endpoint,
        [Parameter(Mandatory=$True,HelpMessage="Body to be sent")]
        [string]$body,
        [Parameter(HelpMessage="Version of API")]
        [string]$version = $version1
        )
    $headers = Set-Header $restUserName $tenantAPIKey $version "application/json"
    try {
        $endpointURL = "https://${airwatchServer}/api/${endpoint}"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $body
       
        return $webReturn
    }
    catch {
        Write-Host "Error submitting POST. $($_.Exception.Message) "
        return $webReturn
    }

}

Function Set-DeviceIdList {
    Param([object]$Devices)
    $deviceCountSkipped = 0
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
            $deviceCountSkipped++
        }
    }
    Write-Host "Skipped $deviceCountSkipped devices that are not enrolled."
    $s = $unsuper,$super
    return $s
}

Function Set-DeviceIdListSupervision {
    Param([object]$Devices)
    $deviceCountSkipped = 0
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
            $deviceCountSkipped++
        }
    }
    Write-Host "Skipped $deviceCountSkipped devices that are not enrolled."
    $s = $unsuper,$super
    return $s
}

Function Install-PublicApp { 
    Param([string]$addJSON,[string]$appId)
    $appType = "public"
    Install-App($addJSON, $appId, $appType)
}

Function Install-InternalApp { 
    Param([string]$addJSON,[string]$appId)
    $appType = "internal"
    Install-App($addJSON, $appId, $appType)
}

Function Install-PurchasedApp { 
    Param([string]$addJSON,[string]$appId)
    $appType = "purchased"
    Install-App($addJSON, $appId, $appType)
}

Function Install-App { 
    Param([string]$addJSON,[string]$appId,[string]$appType)
    try {
        $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
        $endpointURL = "https://${airwatchServer}/api/mam/apps/${appType}/${appId}/install"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addJSON
       
        return $webReturn
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with that device id."
    }

}

Function Remove-DevicesEnterpriseWipe { # Enterprise Wipes List of devices by device id
    Param([string]$body)
    try {
        $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/commands/bulk?command=enterprisewipe&searchby=deviceid"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $body
       
        return $webReturn
    }
    catch {
        Write-Host "Error retrieving device details. May not be any devices with that device id."
    }

}

Function Remove-DeviceEnterpriseWipe { # Enterprise Wipes List of devices by device id
    Param([array]$devices)
    $body = ""
    $arr = @()
    foreach ($deviceid in $devices) {
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/${deviceid}/commands?command=EnterpriseWipe"
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

Function Remove-DeviceFullWipe {
    # Device Wipes List of devices by device id
    Param([array]$devices)
    $body = " "
    $arr = @()
    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
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
            [int]$days = Read-Host -Prompt "Input how many days since the devices were last seen. (Between 15 and 200)"
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

Function Update-Devices {
    Param([array]$devices, $profile)
    $body = ""
    $quoteCharacter = [char]34
    foreach ($deviceid in $devices) {
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/profiles?searchBy=Serialnumber&id=${deviceid}"
            $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers 
            if ($webReturn) {
                $r = $webReturn.DeviceProfiles | Where-Object { $_.Id.Value -eq $profile}
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

Function Split-Array {
 <#  
  .SYNOPSIS   
    Split an array
  .NOTES
    Version : July 2, 2017 - implemented suggestions from ShadowSHarmon for performance   
  .PARAMETER inArray
   A one dimensional array you want to split
  .EXAMPLE  
   Split-Array -inArray @(1,2,3,4,5,6,7,8,9,10) -parts 3
  .EXAMPLE  
   Split-Array -inArray @(1,2,3,4,5,6,7,8,9,10) -size 3
 #> 

  param($inArray,[int]$parts,[int]$size)
  
  if ($parts) {
    $PartSize = [Math]::Ceiling($inArray.count / $parts)
  } 
  if ($size) {
    $PartSize = $size
    $parts = [Math]::Ceiling($inArray.count / $size)
  }

  $outArray = New-Object 'System.Collections.Generic.List[psobject]'

  for ($i=1; $i -le $parts; $i++) {
    $start = (($i-1)*$PartSize)
    $end = (($i)*$PartSize) - 1
    if ($end -ge $inArray.count) {$end = $inArray.count -1}
	$outArray.Add(@($inArray[$start..$end]))
  }
  return ,$outArray

}

<# Set configurations #>
$restUserName = Get-BasicUserForAuth
$Config = Read-Config
$tenantAPIKey = $Config.awtenantcode
$organizationGroupID = $Config.groupid
$airwatchServer = $Config.host
$version1 = "application/json;version=1"
$version2 = "application/json;version=2"


Export-ModuleMember -Function Read-File, Get-BasicUserForAuth, Set-Header, Get-Tags, Get-Profiles, Get-OrgGroups, Select-Platform, Select-Tag, Get-Device, Set-AddTagJSON, Set-DeviceIdJSON, Get-DeviceDetails, Set-DeviceIdList, Set-DeviceIdListSupervision, Install-PublicApp, Install-InternalApp, Install-PurchasedApp, Install-App, Remove-DevicesEnterpriseWipe, Remove-DeviceEnterpriseWipe, Remove-DeviceFullWipe, Set-DaysPrior, Set-LastSeenDate, Update-Devices, Split-Array, Send-Post
