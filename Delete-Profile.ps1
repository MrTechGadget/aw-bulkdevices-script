<#
.SYNOPSIS
  Deletes Profiles given a list of Profile IDs.
.DESCRIPTION
  Deletes Profiles given a list of Profile IDs. 
.PARAMETER file 
    Path of a CSV file with a list of Profile IDs.  This is required. 
.PARAMETER fileColumn 
    Column title in CSV file containing ProfileId values.  This is optional, with a default value of "ProfileId". 
.INPUTS
  AirWatchConfig.json
  CSV File with headers
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.3
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  01/09/2021
  Update Date:    10/13/2022
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  Delete-Profile.ps1 -file .\ProfilesTest.csv -fileColumn "ProfileId"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,HelpMessage="Path to file listing ProfileId.")]
   [string]$file,
	
   [Parameter(HelpMessage="Name of Id column in file, default is ProfileId")]
   [string]$fileColumn = "ProfileId"
)

Import-Module .\PSairwatch.psm1
Write-Log -logstring "$($MyInvocation.Line)"

$Logfile = "$PSScriptRoot\ProfileDelete.log"

$list = Read-File $file $fileColumn

Write-Log -logstring "$($MyInvocation.Line)" -logfile $Logfile

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $list.count + " profiles will be deleted from AirWatch",
    "",
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    Write-Log -logstring "Deleting $($list.count) profiles from AirWatch" -logfile $Logfile

    foreach ($item in $list) {
        Write-Progress -Activity "Deleting Profiles..." -Status "Profile $($list.IndexOf($item)+1) of $($list.Count)" -CurrentOperation "$item" -PercentComplete ((($list.IndexOf($list)+1)/($list.Count))*100)
        $endpointURL = "mdm/profiles/${item}"
        try {
            $result = Send-Delete -endpoint $endpointURL -version "application/json;version=1"
            if ($result -ne "") {
                    Write-Warning ("Error Deleting Profile: $item : $result")
                    Write-Log -logstring ("Error Deleting Profile: $item : $result") -logfile $Logfile
            } else {
                Write-Host "$item Deleted $result"
                Write-Log -logstring "$item Deleted $result" -logfile $Logfile
            }
        }
        catch {
          $err2 = $Error[0].ErrorDetails.Message
          Write-Warning "Error Sending Profile Delete Command: $item $err2"
          Write-Log -logstring "Error Sending Profile Delete Command: $item $err2" -logfile $Logfile
        }
    }
} else {
    Write-Host "Deletion Cancelled"
    Write-Log -logstring "Deletion Cancelled" -logfile $Logfile
}
