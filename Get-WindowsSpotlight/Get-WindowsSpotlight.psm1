function Get-WindowsSpotlight
{
   param (
      [string]$Source,
      [ValidateScript({Test-Path -Path $_})]
      [string]$Destination = "$env:USERPROFILE\Downloads"
   )
   
   if ($Source)
   {
      if (Test-Path -Path $Source)
      {
         $Files = Get-ChildItem -File -Path $source
      }
      else
      {
         throw $_
      }
   }
   else
   {
      $Files = Get-ChildItem -File -Path "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
   }
   
   $To = [IO.Path]::Combine($Destination, 'Windows Spotlight')
   if (-not (Test-Path -Path $To))
   {
      try
      {
         New-Item -Type Directory -Path $To | Select-Object -ExpandProperty FullName
      }
      catch
      {
         throw $_
      }
   }
   
   if ($Files.Count -ge 1)
   {
      foreach ($File in $Files)
      {
         $arrBytes = Get-Content -Path $File.FullName -Encoding Byte -TotalCount 4
         $strBytes = [BitConverter]::ToString($arrBytes) -replace '-'
         switch -Regex ($strBytes)
         {
            '^FFD8\w{4}$'
            {
               $FileName = $File.Name + '.jpg'
               $Target = [IO.Path]::Combine($To, $FileName)
               try
               {
                  Copy-Item -Path $File.FullName -Destination $Target
               }
               catch
               {
                  throw $_
               }
               continue
            }
            '^89504E47$'
            {
               $FileName = $File.Name + '.png'
               $Target = [IO.Path]::Combine($To, $FileName)
               try
               {
                  Copy-Item -Path $File.FullName -Destination $Target
               }
               catch
               {
                  throw $_
               }
               continue
            }
            default
            {
               'Unknown Magic Number: ' + $strBytes
            }
         }
      }
   }
}
