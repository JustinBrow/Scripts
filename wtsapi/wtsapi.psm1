$moduleDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Test-Path ("$moduleDir\wtsapi.dll"))
{
   $assemblyVersion = [Version]::Parse((Get-Item -Path ("$moduleDir\wtsapi.dll")).VersionInfo.ProductVersion)
   Get-Content ("$moduleDir\wtsapi.cs") -ReadCount 1 | ForEach-Object {
      $regex = [Regex]::Match($_, 'Version\("(?<Version>\d\.\d\.\d\.\d)"\)')
      if ($regex.Success -eq $true)
      {
         $sourceVersion = [Version]::Parse($regex.Groups['Version'].Value)
         return
      }
   }
   if ($assemblyVersion -ne $sourceVersion)
   {
      Add-Type -TypeDefinition (Get-Content ("$moduleDir\wtsapi.cs") | Out-String) -OutputType Library -OutputAssembly ("$moduleDir\wtsapi.dll")
      Import-Module ("$moduleDir\wtsapi.dll")
   }
   else
   {
      Import-Module ("$moduleDir\wtsapi.dll")
   }
}
else
{
   Add-Type -TypeDefinition (Get-Content ("$moduleDir\wtsapi.cs") | Out-String) -OutputType Library -OutputAssembly ("$moduleDir\wtsapi.dll")
   Import-Module ("$moduleDir\wtsapi.dll")
}
