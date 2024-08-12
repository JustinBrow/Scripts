## FSLogix.ps1  
Working with FSLogix profiles programatically

## FSLogix.psm1  
Function version
```
foreach ($fslogixProfile in $fslogixProfiles)
{
   try
   {
      $profilePath = $registryPath = $fslogixCookie = [string]::Empty

      $mountParams = @{
         FSLogixProfile = $fslogixProfile
         ProfilePath = ([ref]$profilePath)
         RegistryPath = ([ref]$registryPath)
         FSLogixCookie = ([ref]$fslogixCookie)
      }
      $isProfileMounted = Mount-FSLogixProfile @mountParams

      if ($isProfileMounted)
      {
         if (Test-Path $profilePath)
         {
            Get-ChildItem $profilePath
         }
         if (Test-Path $registryPath)
         {
            Get-ChildItem $registryPath
         }
         Dismount-FSLogixProfile -FSLogixProfile $fslogixProfile -FSLogixCookie $fslogixCookie | Out-Null
      }
   }
   catch
   {
      $_.Exception.Message
      continue
   }
}
```
