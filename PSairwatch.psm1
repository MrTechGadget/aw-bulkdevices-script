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
  Version:        2.12.1
  Author:         Joshua Clark @MrTechGadget
  Source:         https://github.com/MrTechGadget/aw-bulkdevices-script
  Creation Date:  05/22/2018
  Update Date:    10/08/2021
  
.EXAMPLE
    $ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
    Set-Location $ScriptPath 
    Import-Module .\PSairwatch.psm1
#>

Function Read-Config {
    try {
        if (Test-Path "AirWatchConfig.json") {
            $Config = (Get-Content "AirWatchConfig.json") -join "`n" | ConvertFrom-Json
            Write-Verbose "Config file loaded."
            if ($Config.groupid -and $Config.awtenantcode -and $Config.host) {
                Write-Verbose "Config file formatted correctly."
                return $Config
            } else {
                Write-Verbose "ConfigFile not correct, please complete the sample config and name the file AirWatchConfig.json"
                Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
                Write-Host "ConfigFile not correct, please complete the sample config and name the file AirWatchConfig.json" -ForegroundColor Black -BackgroundColor Red
                Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
                $Config
                Set-Config
            }
        } else {
            Write-Verbose "No config file exists, please complete the sample config and name the file AirWatchConfig.json "
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
            Write-Host "No config file exists, please complete the sample config and name the file AirWatchConfig.json " -ForegroundColor Black -BackgroundColor Red
            Write-Host "-----------------------------------------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Red
            Set-Config
        }
        
    }
    catch {
        Write-Verbose "No config file exists, please complete the sample config and name the file AirWatchConfig.json"
        Write-Host "No config file exists, please complete the sample config and name the file AirWatchConfig.json"
        Set-Config
    }
}

Function Set-Config {
    $apihost = Read-Host "Enter FQDN of API server, do not include protocol or path"
    $awtenantcode = Read-Host "Enter API Key"
    $groupid = Read-Host "Enter Group ID (numerical value)"
    $configuration = @{
        'groupid'      = $groupid
        'awtenantcode' = $awtenantcode
        'host'         = $apihost
    }
    ConvertTo-Json -InputObject $configuration | Set-Content -LiteralPath 'AirWatchConfig.json' -Force
    do {
        Start-Sleep -Seconds 1
    } until (Test-Path "AirWatchConfig.json")
    Start-Sleep -Seconds 3
    Read-Config
}

Function Write-Log
{
    Param (
        [string]$logstring,
        [string]$Logfile = "PSairwatch.log"
    )

    $logstring = ((Get-Date).ToString() + " - " + $logstring)
    Add-content $logfile -value $logstring
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

Function Read-FileWithData {
    Param([string]$file, [string]$head, [string]$extraColumn)
    if (Test-Path $file) {
        Write-Verbose "$file exists, importing list."
        $data = Import-Csv -Path $file
        if ($data.$head) {
            return $data
        } else {
            Write-Error -Message "No such column, $head, in CSV file $file."
        }
        
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
    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    $endpointURL = "https://${airwatchServer}/api/mdm/tags/search?organizationgroupid=${organizationGroupID}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $TagArray = New-Object System.Collections.Specialized.OrderedDictionary
    foreach ($tag in $webReturn.Tags) {
        $TagArray.Add($tag.TagName, $tag.Id.Value)
    }
    return $TagArray
}

Function Get-Profiles {
    Param([string]$GroupID, [string]$platform)
    $headers = Set-Header $restUserName $tenantAPIKey "application/json" "application/json"
    $endpointURL = "https://${airwatchServer}/api/mdm/profiles/search?organizationgroupid=${GroupID}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    $Array = New-Object System.Collections.Specialized.OrderedDictionary
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
    $OrgArray = New-Object System.Collections.Specialized.OrderedDictionary
    foreach ($org in $webReturn.LocationGroups) {
        $OrgArray.Add($org.Name, $org.Id.Value)
    }
    return $OrgArray
}

Function Select-Platform {
    $platforms = @("Apple","Android","WindowsPc","AppleOsX","AppleTV","ChromeOS")
    $selection = $null
    $i=0
    foreach($platform in $platforms){
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
    
    Do {
        $mhead
        Write-Host 
        $TagArr = @()
        $i=0
        foreach($tag in $TagList.keys) {
            Write-Host -ForegroundColor Cyan "  $($i+1)." $tag
            $TagArr += $tag
            $i++
        }
        Write-Host 
        $ans = (Read-Host 'Please enter selection') -as [int]
    
    } While ((-not $ans) -or (0 -gt $ans) -or ($TagList.Count -lt $ans))
    
    $selection = $ans - 1
    $selectedTag = $TagArr[$selection]
    $tempOrg = $TagList.$selectedTag
    return [string]$tempOrg
}

Function Get-Device {
    Param([string]$lastseen, [string]$lgid, [string]$pageSize = "500")

    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    $endpointURL = "https://${airwatchServer}/api/mdm/devices/search?lastseen=${lastseen}&lgid=${lgid}&orderby=lastseen&sortorder=DESC&pagesize=${pageSize}"
    $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
    Write-Host "Total of $($webReturn.Total) devices match search, returning the first $($webReturn.PageSize) results."
    return $webReturn.Devices
}

<#  This function builds the JSON to add the tag to all of the devices. #>
Function Set-AddTagJSON {
    Param([Array]$items)
    
    Write-Verbose("------------------------------")
    Write-Verbose("Building JSON to Post")

    $addTagJSON = @{
        'BulkValues' = @{
            'Value' = @(
                $items | ForEach-Object -MemberName ToString | ForEach-Object -MemberName Trim
            )
        }
    }
    $addTagJSON = ConvertTo-Json -InputObject $addTagJSON -Compress
    
    Write-Verbose($addTagJSON)
    Write-Verbose("------------------------------")
    Write-Verbose("")
        
    Return $addTagJSON
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
        Write-Warning "Error retrieving device details. May not be any devices matching."
    }

}

Function Get-TaggedDevice {
    Param([string]$SelectedTag)

    $endpoint = "mdm/tags/${SelectedTag}/devices?"
    $webReturn = Send-Get $endpoint
    $s = @()
    foreach ($device in $webReturn.Device) {
        $s += $device.DeviceId
        Write-Verbose $device.DeviceId
    }
    return $s
}

Function Send-Get {
    Param(
        [Parameter(Mandatory=$True,HelpMessage="Rest Endpoint for Get, after https://airwatchServer/api/")]
        [string]$endpoint,
        [Parameter(HelpMessage="Version of API")]
        [string]$version = $version1
    )
    $headers = Set-Header $restUserName $tenantAPIKey $version "application/json"
    try {
        $endpointURL = "https://${airwatchServer}/api/${endpoint}"
        $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers
       
        return $webReturn
    }
    catch {
        Write-Warning "Error submitting Get. $($_.Exception.Message) "
        return $webReturn
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
        Write-Warning "Error submitting POST. $($_.Exception.Message) "
        return $webReturn
    }
}

Function Send-Put {
    Param(
        [Parameter(Mandatory=$True,HelpMessage="Rest Endpoint for PUT, after https://airwatchServer/api/")]
        [string]$endpoint,
        [Parameter(Mandatory=$True,HelpMessage="Body to be sent")]
        [string]$body,
        [Parameter(HelpMessage="Version of API")]
        [string]$version = $version1
    )
    $headers = Set-Header $restUserName $tenantAPIKey $version "application/json"
    try {
        $endpointURL = "https://${airwatchServer}/api/${endpoint}"
        $webReturn = Invoke-RestMethod -Method Put -Uri $endpointURL -Headers $headers -Body $body
       
        return $webReturn
    }
    catch {
        Write-Warning "Error submitting PUT. $($_.Exception.Message) "
        return $webReturn
    }
}

Function Send-Patch {
    Param(
        [Parameter(Mandatory=$True,HelpMessage="Rest Endpoint for Patch, after https://airwatchServer/api/")]
        [string]$endpoint,
        [Parameter(HelpMessage="Version of API")]
        [string]$version = $version1
    )
    $headers = Set-Header $restUserName $tenantAPIKey $version "application/json"
    try {
        $endpointURL = "https://${airwatchServer}/api/${endpoint}"
        $webReturn = Invoke-RestMethod -Method Patch -Uri $endpointURL -Headers $headers
       
        return $webReturn
    }
    catch {
        Write-Warning "Error submitting PUT. $($_.Exception.Message) "
        return $webReturn
    }
}

Function Send-Delete {
    Param(
        [Parameter(Mandatory=$True,HelpMessage="Rest Endpoint for Delete, after https://airwatchServer/api/")]
        [string]$endpoint,
        [Parameter(HelpMessage="Version of API")]
        [string]$version = $version1
    )
    $headers = Set-Header $restUserName $tenantAPIKey $version "application/json"
    try {
        $endpointURL = "https://${airwatchServer}/api/${endpoint}"
        $webReturn = Invoke-RestMethod -Method Delete -Uri $endpointURL -Headers $headers
       
        return $webReturn
    }
    catch {
        Write-Warning "Error submitting Delete. $($_.Exception.Message) "
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

Function Set-UnenrolledDeviceIdList {
    Param([object]$Devices)
    $t = 0
    $entwipe = @()
    foreach ($device in $Devices) {
        if ($device.EnrollmentStatus -eq "EnterpriseWipePending") {
            $entwipe += $device.Id.Value
            Write-Verbose "$($device.SerialNumber) is EnterpriseWipePending"
        } elseif ($device.EnrollmentStatus -eq "Unenrolled") {
            $entwipe += $device.Id.Value
            Write-Verbose "$($device.SerialNumber) is Unenrolled"
        } elseif ($device.EnrollmentStatus -eq "WipeInitiated") {
            $entwipe += $device.Id.Value
            Write-Verbose "$($device.SerialNumber) is WipeInitiated"
        } elseif ($device.EnrollmentStatus -eq "DeviceWipePending") {
            $entwipe += $device.Id.Value
            Write-Verbose "$($device.SerialNumber) is DeviceWipePending"
        } else {
            Write-Verbose "$($device.SerialNumber) is not pending Enterprise Wipe, Device WipeInitiated, DeviceWipePending, or Unenrolled, skipping"
            $t++
        }
    }
    Write-Host "Skipped $t devices that are not pending wipe or unenrolled."
    return $entwipe
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

# Enterprise Wipes List of devices by device id
Function Unregister-DevicesEnterpriseWipe {
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

# Enterprise Wipes List of devices by device id
Function Unregister-DeviceEnterpriseWipe {
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

Function Unregister-DeviceFullWipe {
    # Device Wipes List of devices by device id
    Param([array]$devices)
    $body = " "
    $arr = @()
    $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
    foreach ($deviceid in $devices) {
        Write-Progress -Activity "Deleting Devices..." -Status "Wiping $($devices.IndexOf($deviceid)+1) of $($devices.Count)" -CurrentOperation "$deviceid" -PercentComplete ((($devices.IndexOf($devices)+1)/($devices.Count))*100)
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/${deviceid}/commands?command=DeviceWipe"
            $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $body
            if ($webReturn) {
                $arr += $webReturn
            }
        }
        catch {
            $e = [int]$Error[0].Exception.Response.StatusCode
            Write-Error "Error wiping device $deviceid. Status code $e. May not be any devices with that device id."
        }
    }

    return $arr
}

Function Remove-DeviceBulk {
    Param([string]$addTagJSON)
    try {
        $headers = Set-Header $restUserName $tenantAPIKey $version1 "application/json"
        $endpointURL = "https://${airwatchServer}/api/mdm/devices/bulk"
        $webReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $headers -Body $addTagJSON
       
        return $webReturn
    }
    catch {
        return [int]$Error[0].Exception.Response.StatusCode
    }

}

Function Set-DaysPrior {
    Param(
        [Parameter(HelpMessage="Maximum number of days since devices were last seen, default is 200")]
        [string]$maxLastSeen = "200"
    )
    do {
        try {
            $numOk = $true
            [int]$days = Read-Host -Prompt "Input how many days since the devices were last seen. (Between 15 and ${maxLastSeen})"
        } # end try
        catch {$numOK = $false}
    } # end do 
    until (($days -ge 15 -and $days -le [int]$maxLastSeen) -and $numOK)
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
    Param([array]$devices, $ProfileSelected)
    $body = ""
    $quoteCharacter = [char]34
    foreach ($deviceid in $devices) {
        try {
            $endpointURL = "https://${airwatchServer}/api/mdm/devices/profiles?searchBy=Serialnumber&id=${deviceid}"
            $webReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $headers 
            if ($webReturn) {
                $r = $webReturn.DeviceProfiles | Where-Object { $_.Id.Value -eq $ProfileSelected}
                if ($r.Status -eq 1) {
                    $devid = $webReturn.DeviceId.Id.Value
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$ProfileSelected/install"
                    $body = "{ " + $quoteCharacter + "SerialNumber" + $quoteCharacter + " : " + $quoteCharacter + $deviceid + $quoteCharacter +" }"
                    $webReturn2 = Invoke-RestMethod -Method Post -Uri $endpointURL2 -Headers $headers -Body $body
                    Write-Host $devid  "  install queued   " + $webReturn2
                } elseif ($r.Status -eq 0) {
                    $devid = $webReturn.DeviceId.Id.Value
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$ProfileSelected/install"
                    $body = "{ " + $quoteCharacter + "SerialNumber" + $quoteCharacter + " : " + $quoteCharacter + $deviceid + $quoteCharacter +" }"
                    $webReturn2 = Invoke-RestMethod -Method Post -Uri $endpointURL2 -Headers $headers -Body $body
                    Write-Host $devid  "  install queued   " + $webReturn2
                } elseif ($r.Status -eq 3) {
                    Write-Host $webReturn.DeviceId.Id.Value profile already installed.
                } elseif ($r.Status -eq 6) {
                    $endpointURL2 = "https://${airwatchServer}/api/mdm/profiles/$ProfileSelected/install"
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
$Config = Read-Config
$restUserName = Get-BasicUserForAuth
$tenantAPIKey = $Config.awtenantcode
$organizationGroupID = $Config.groupid
$airwatchServer = $Config.host
$version1 = "application/json;version=1"
$version2 = "application/json;version=2"

Export-ModuleMember -Function * -Variable $version1,$version2
