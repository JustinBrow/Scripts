## Copy-ADGroups  
Copy AD group membership from one user to another.  
### Installation  
Create a folder in your PowerShell modules folder and place the module file within. The folder and module file must have the same name.
### Usage  
A user can be the string representation of a distinguished name, GUID , security identifier (SID), or a SAM account name.  
Uses the same input as "Get-ADUser".
```
Copy-ADGroup -CopyFromUser sAMAccountName1 -CopyToUser sAMAccountName2
```
```
Copy-ADGroup -CopyFromUser sAMAccountName1 -CopyToUser sAMAccountName2 -RemoveOld
```
### Reference/Inspiration  
https://stackoverflow.com/questions/25754596/copy-group-membership-from-one-user-to-another-in-ad
