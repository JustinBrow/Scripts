## Wtsapi  
Reimplementation of query session/qwinsta and reset session/rwinsta.  
### Installation  
Create a folder in your PowerShell modules folder and place both the module file and C# code file within. The folder and module file must have the same name.  
The first time the module is imported it will compile the C# code into a DLL. If the version of the DLL and C# code are not the same the module will compile the code again.  
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
### Reference/Inspiration  
https://github.com/jagilber/powershellScripts/blob/master/wts_querySessionInformation.ps1  
https://github.com/jaredcatkinson/PSReflect-Functions/blob/master/Examples/Get-NetRDPSession.ps1
https://github.com/Techsupport4me/David-Powershell/blob/master/Modules/RDS-Manager/RDS-Manager.psm1
https://github.com/guyrleech/Microsoft/blob/master/WTSApi.ps1
https://gist.github.com/swbbl/205694b7e1bdf09e74f25800194d5bcd
https://stackoverflow.com/questions/42711592/getting-the-logged-in-user-in-powershell
https://stackoverflow.com/questions/32328166/using-c-sharp-code-in-powershell-scripts-and-save-results-in-variable
https://old.reddit.com/r/PowerShell/comments/306mcn/wtsenumeratesessions/
https://www.lucd.info/2018/08/05/message-to-all-users-and-their-reply/
