## Wtsapi  
Reimplementation of query session/qwinsta and reset session/rwinsta.  
### Installation  
Create a folder in your PowerShell modules folder and place both the module file and C# code file within. The folder and module file must have the same name.  
### Sample Usage  
Import the module.  
```
Import-Module wtsapi
```
Find all users on a single server.  
```
[Windows.Wtsapi32]::QuerySession($computerName, '*')
```
Find users matching wildcard search on a single server.  
```
[Windows.Wtsapi32]::QuerySession($computerName, '*partialSamAccountName*')
```
Find a specific user on a single server (it's still a wildcard search internally).  
```
[Windows.Wtsapi32]::QuerySession($computerName, $SamAccountName)
```
If there are multiple users with the same username, e.g. $computerName\Administrator and $domain\Administrator
both will be logged off.  
```
[Windows.Wtsapi32]::LogoffSession($computerName, $SamAccountName)
```
Returns boolean `true` if user is logged in the the computer.  
```
[Windows.Wtsapi32]::SessionExists($computerName, $SamAccountName)
```
Any of the previous, but in a loop.
```
ForEach ($computerName in $computersCollection)
{
   [Windows.Wtsapi32]::QuerySession($computerName, '*')
}
```
