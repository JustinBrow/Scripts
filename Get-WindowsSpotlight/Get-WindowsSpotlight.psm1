function Get-WindowsSpotlight
{
   param (
      $Source,
      $Destination = "$env:USERPROFILE\Downloads"
   )

   if ($Source)
   {
      $Files = Get-ChildItem -Path $source
   }
   else
   {
      $Files = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
   }

   $Destination = [IO.Path]::Combine($Destination, 'Windows Spotlight')
   if (-Not (Test-Path -Path $Destination))
   {
      New-Item -Type Directory -Path $Destination
   } 
   foreach ($File in $Files)
   {
      $arrBytes = Get-Content -Path $File.FullName -Encoding Byte -TotalCount 4
      $strBytes = [System.BitConverter]::ToString($arrBytes) -replace '-'
      switch -Regex ($strBytes)
      {
         '^FFD8....$'
         {
            $FileName = $File.Name + '.jpg'
            $To = [IO.Path]::Combine($Destination, $FileName)
            Copy-Item -Path $File.FullName -Destination $To
            continue
         }
         '^89504E47$'
         {
            $FileName = $File.Name + '.png'
            $To = [IO.Path]::Combine($Destination, $FileName)
            Copy-Item -Path $File.FullName -Destination $To
            continue
         }
         default
         {
            'Unknown Magic Number: ' + $strBytes
         }
      }
   }
}
