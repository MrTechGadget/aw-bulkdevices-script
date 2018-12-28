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

**Delete-User.ps1** - This script deletes users in AirWatch from a CSV list. The file is required, the column name is optional. If not provided, it will use the default column name of "Id".
  .\Delete-User.ps1 -userFile "User.csv" -userFileColumn "Id.Value"
It deletes in batches of 50 users per call. I have found that most calls with more than 70 or so users will fail. It has been tested to successfully delete over 16,000 users at a time. This takes a while of course as this is 320 batches.

**Reset-FullDevice.ps1** - This script executes a full device wipe for a CSV list of serial numbers. 
file parameter is the path to a CSV file with a list of Serial Numbers.  This is required.  
fileColumn parameter is the Column title in CSV file containing SerialNumber values.  This is optional, with a default value of "SerialNumber". 

EXAMPLE
  .\Reset-FullDevice.ps1 -file "Devices.csv" -fileColumn "SerialNumber"

The user is prompted to confirm before it is executed.

## Compatibility

These PowerShell scripts are PowerShell Core (PS 6) compliant and were written with Visual Studio Code on a Mac. 

They have been tested on Windows and Mac, but should also run on Linux. 

Setup:
* These scripts take a JSON config file, which houses the API Host, API key and Organization Group ID for your AirWatch environment. A sample file has been included, just remove the name sample and add your fields, with NO quotations. Name this file `AirWatchConfig.json`
```
{
    "groupid" : 1234,
    "awtenantcode" : "apikey",
    "host" : "host.domain.tld"
}
```

## Author

* **Joshua Clark** - [MrTechGadget Github](https://github.com/MrTechGadget) [MrTechGadget Website](http://mrtechgadget.com/)
