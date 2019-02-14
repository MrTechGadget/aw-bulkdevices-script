# aw-bulkdevices-script
## A group of scripts which are used to bulk manage Workspace ONE UEM (AirWatch) managed devices and users.

**Get-ListOfStaleDevices.ps1** - This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
The user then enters a number of days(X) since the devices have been last seen.
All of the devices in that organization group (and child org groups) that have not been seen since X days are exported to a CSV file named with that date.


**Remove-StaleDevices.ps1** - This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
The user then enters a number of days(X) since the devices have been last seen.
All of the devices in that organization group (and child org groups) that have not been seen since X days are sorted into supervised and unsupervised lists. The device details for both of these lists are exported to a CSV file named with that date.
The supervised devices are then issued full wipes and the unsupervised devices are issued enterprise wipes.


**Delete-StaleDevices.ps1** - This script displays a list of all Organization groups in an environment, allowing the user to select an organization group. 
The user then enters a number of days(X) since the devices have been last seen.
All of the devices returned in the first "page" in that organization group (and child org groups) that have not been seen since X days and are pending enterprise wipe are deleted are exported to a CSV file named with that date. You can set an optional pageSize parameter to process more or less devices than the default of 500 devices.

EXAMPLE
  Get-ListOfStaleDevices.ps1 -pageSize 1000

**Delete-User.ps1** - This script deletes users from a CSV list of UserIds. The file is required, the column name is optional. If not provided, it will use the default column name of "Id". 
Given this is a synchronous API call, the list is broken into batches of 50 per call, to prevent timeouts from occurring. The user is prompted to confirm before it is executed. A progress bar shows progress through all of the batches, and output to the window shows successes and failures of each batch, as well as any errors.

EXAMPLE
  Delete-User.ps1 -userFile "User.csv" -userFileColumn "Id.Value"

**Reset-FullDevice.ps1** - This script executes a full device wipe for a CSV list of serial numbers. 
file parameter (REQUIRED) is the path to a CSV file with a list of Serial Numbers. fileColumn parameter (OPTIONAL, with a default value of "SerialNumber") is the Column title in CSV file containing SerialNumber values. 
The user is prompted to confirm before it is executed. A progress bar shows progress through all of devices, and output to the window and a log file shows successes and failures of each device, as well as any errors.

EXAMPLE
  Reset-FullDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"

**Reset-EnterpriseWipe.ps1** - This script executes an Enterprise Wipe (unenroll) for a CSV list of serial numbers. 
file parameter (REQUIRED) is the path to a CSV file with a list of Serial Numbers. fileColumn parameter (OPTIONAL, with a default value of "SerialNumber") is the Column title in CSV file containing SerialNumber values. 
The user is prompted to confirm before it is executed. A progress bar shows progress through all of devices, and output to the window and a log file shows successes and failures of each device, as well as any errors.

EXAMPLE
  Reset-EnterpriseWipe.ps1 -file "Devices.csv" -fileColumn "SerialNumber"

## Compatibility

These PowerShell scripts are PowerShell Core (PS 6) compliant and were written with Visual Studio Code on a Mac. 

They have been tested on Windows and Mac, but should also run on Linux. 

Setup:
* These scripts take a JSON config file, `AirWatchConfig.json`, which houses the API Host, API key and Organization Group ID for your AirWatch environment. The format is shown below but if the file is not present, the script will prompt for the values and write the file for you.
```
{
    "groupid" : 1234,
    "awtenantcode" : "apikey",
    "host" : "host.domain.tld"
}
```

## Author

* **Joshua Clark** - [MrTechGadget Github](https://github.com/MrTechGadget) [MrTechGadget Website](http://mrtechgadget.com/)
