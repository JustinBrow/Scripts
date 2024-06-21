## Put-Registry  
Rolls `New-Item`, `NewItemProperty`, and `Set-ItemProperty` into one function.
### Installation  
Create a folder in your PowerShell modules folder and place the module file within. The folder and module file must have the same name.  
### Usage  
If you do not include the $Key varaible then the value will be set under "(Default)"
```
Put-Registry -Path 'HKCU:\SOFTWARE\myOrg' -Key 'Version' -Type String -Value 2.0
```
```
Put-Registry -Path 'HKCU:\SOFTWARE\myOrg' -Type Dword -Value 1
```
### Notes  
Only tested against PowerShell 5.1 Desktop edition on Windows 10
