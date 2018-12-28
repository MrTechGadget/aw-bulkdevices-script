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
All of the devices in that organization group (and child org groups) that have not been seen since X days and are pending enterprise wipe are deleted are exported to a CSV file named with that date.


**Delete-User.ps1** - This script deletes users given a file with a list of UserIds. Given this is a synchronous API call, the list is broken into batches of 50 per call, to prevent timeouts from occurring. A progress bar shows progress through all of the batches, and output to the window shows successes and failures of each batch, as well as any errors.


**To-Do** - List all the new functions that have been added!

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

