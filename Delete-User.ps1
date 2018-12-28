<#
.SYNOPSIS
  Deletes list of users from Workspace ONE UEM (AirWatch)
.DESCRIPTION
  
.PARAMETER userFile 
    Path of a CSV file with a list of User Ids.  This is required. 
.PARAMETER userFileColumn 
    Column title in CSV file containing User Id values.  This is optional, with a default value of "Id". 
.INPUTS
  AirWatchConfig.json
  Serials.csv
.OUTPUTS
  NO OUTPUT CURRENTLY:Outputs a CSV log of actions
.NOTES
  Version:        1.1
  Author:         Joshua Clark @MrTechGadget
  Creation Date:  07/02/2018
  Update Date:    12/28/2018
  Site:           https://github.com/MrTechGadget/aw-bulkdevices-script
.EXAMPLE
  .\Delete-User.ps1 -userFile "User.csv" -userFileColumn "Id.Value"
#>


[CmdletBinding()] 
Param(
   [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$true,HelpMessage="Path to file listing UserIDs.")]
   [string]$userFile,
	
   [Parameter(HelpMessage="Name of Id column in file, default is Id")]
   [string]$userFileColumn = "Id"
)

Import-Module .\PSairwatch.psm1
$batchsize = 50
$userList = Read-File $userFile $userFileColumn
$splitUserList = Split-Array -inArray $userList -size $batchsize

$decision = $Host.UI.PromptForChoice(
    "Attention! If you proceed, " + $userList.count + " users will be deleted from AirWatch",
    "This will occur in " + [Math]::Ceiling($userList.count/$batchsize) + " batches of $batchsize", 
    @('&Yes', '&No'), 1)

if ($decision -eq 0) {
    foreach ($list in $splitUserList) {
        $json = Set-AddTagJSON $list
        Write-Progress -Activity "Deleting Users..." -Status "Batch $($splitUserList.IndexOf($list)+1) of $($splitUserList.Count)" -PercentComplete ((($splitUserList.IndexOf($list)+1)/($splitUserList.Count))*100)
        try {
            $result = Send-Post -endpoint "system/users/delete" -body $json
            if (!$result) {
                Write-Warning "Error Deleting User(s): "
                Write-Host $list
            } else {
                $result
            }
        }
        catch {
            Write-Warning "Error Deleting Users"
            Write-Host $list
        }
    }
} else {
    Write-Host "Deletion Cancelled"
}




