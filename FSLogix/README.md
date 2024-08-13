## FSLogix.ps1  
Working with FSLogix profiles programatically

## FSLogix.psm1  
Function version
```
$fslogixProfiles = (Get-ChildItem -LiteralPath $profileStorage -Filter '*.vhdx' -Recurse -File).FullName

foreach ($fslogixProfile in $fslogixProfiles)
{
   try
   {
      $profileMount = $registryMount = $fslogixCookie = [string]::Empty

      $mountParams = @{
         FSLogixProfile = $fslogixProfile
         ProfileMount = ([ref]$profileMount)
         RegistryMount = ([ref]$registryMount)
         FSLogixCookie = ([ref]$fslogixCookie)
      }
      $isProfileMounted = Mount-FSLogixProfile @mountParams

      if ($isProfileMounted)
      {
         if (Test-Path $profileMount)
         {
            Get-ChildItem $profileMount
         }
         if (Test-Path $registryMount)
         {
            Get-ChildItem $registryMount
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
