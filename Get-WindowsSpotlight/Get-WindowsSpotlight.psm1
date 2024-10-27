function Get-WindowsSpotlight
{
   param (
      [string]$Source,
      [ValidateScript({Test-Path -Path $_})]
      [string]$Destination = "$env:USERPROFILE\Downloads"
   )

   if ($Source)
   {
      $Files = Get-ChildItem -Path $source
   }
   else
   {
      $Files = Get-ChildItem -Path "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
   }

   $To = [IO.Path]::Combine($Destination, 'Windows Spotlight')
   if (-Not (Test-Path -Path $To))
   {
      New-Item -Type Directory -Path $To | Select-Object -ExpandProperty FullName
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
            $Target = [IO.Path]::Combine($To, $FileName)
            Copy-Item -Path $File.FullName -Destination $Target
            continue
         }
         '^89504E47$'
         {
            $FileName = $File.Name + '.png'
            $Target = [IO.Path]::Combine($To, $FileName)
            Copy-Item -Path $File.FullName -Destination $Target
            continue
         }
         default
         {
            'Unknown Magic Number: ' + $strBytes
         }
      }
   }
}
