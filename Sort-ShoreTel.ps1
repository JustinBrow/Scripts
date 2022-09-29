Start-Transcript E:\ShoreTel.log
[Collections.ArrayList]$allVMs = (Get-ChildItem "C:\Shoreline Data\Vms\Message" -Recurse -File).Name
"lall`r`nexit`r`n" | Out-File C:\script.txt -Encoding ascii;
$output = & "C:\Program Files (x86)\Shoreline Communications\ShoreWare Server\Cfg.exe" -f C:\script.txt
$mbxes = [regex]::Matches(($output | Out-String), '\d{3}').Value
foreach ($mbx in $mbxes)
{
   'mbx'
   $mbx

   "openm $mbx`r`nlmbox`r`nclosem`r`nexit`r`n" | Out-File C:\script.txt -Encoding ascii;
   $output = & "C:\Program Files (x86)\Shoreline Communications\ShoreWare Server\Cfg.exe" -f C:\script.txt
   if (-not ($output))
   {
      Start-Sleep -Seconds 2
      $output = & "C:\Program Files (x86)\Shoreline Communications\ShoreWare Server\Cfg.exe" -f C:\script.txt
   }
   $name = $output -match '^Name'
   $name
   $name2 = ''
   $name2 = [regex]::Match(($name | Out-String), "Name (?<name>.+?)$").Groups['name'].Value.Trim()
   $email = $output -match '^Email address:'
   $email
   $email2 = ''
   $email2 = [regex]::Match(($email | Out-String), ": (?<email>.+?@.+?\..+)").Groups['email'].Value.Trim()
   $folder = ''
   if ($name2 -ne ',')
   {
      $folder = $name2
   }
   if ($folder -and $email2.Length -gt 0)
   {
      $folder = $folder + " - $email2"
   }
   if (-not ($folder) -and $email2.Length -gt 0)
   {
      $folder = $email2
   }
   if (-not ($folder))
   {
      $folder = 'Unknown'
   }
   $regex = [regex]::Match($output,"NEW(?<new>.*?)SAVED(?<saved>.*?)DELETED(?<deleted>.*?)")
   $newvms = ''
   if ($regex.Groups['new'].Value)
   {
      $newvms = $regex.Groups['new'].Value.Trim() -split ' '
   }
   $savedvms = ''
   if ($regex.Groups['saved'].Value)
   {
      $savedvms = $regex.Groups['saved'].Value.Trim() -split ' '
   }
   $deletedvms = ''
   if ($regex.Groups['deleted'].Value)
   {
      $deletedvms = $regex.Groups['deleted'].Value.Trim() -split ' '
   }

   if (-not (Test-Path "E:\sorted\$($folder)"))
   {
      New-Item -Type Directory E:\sorted\$($folder) | Out-Null
   }

   if ($newvms)
   {
      'new'

      foreach ($newvm in $newvms)
      {
         $newvm

         if (Test-Path "C:\Shoreline Data\Vms\Message\$($newvm).wav")
         {
            Copy-Item "C:\Shoreline Data\Vms\Message\$($newvm).wav" "E:\sorted\$($folder)\$($newvm).wav" -ErrorAction Continue
            Copy-Item "C:\Shoreline Data\Vms\Message\$($newvm).msg" "E:\sorted\$($folder)\$($newvm).msg" -ErrorAction Continue
            $allVMs.Remove("$($newvm).wav")
            $allVMs.Remove("$($newvm).msg")
         }
         else
         {
            "$($newvm).wav" | Out-File "E:\sorted\$($folder)\MissingNewVMs.txt" -Append -NoClobber
            Copy-Item "C:\Shoreline Data\Vms\Message\$($newvm).msg" "E:\sorted\$($folder)\$($newvm).msg" -ErrorAction Continue
            $allVMs.Remove("$($newvm).msg")
         }
      }
   }

   if ($savedvms)
   {
      'saved'

      foreach ($savedvm in $savedvms)
      {
         $savedvm

         if (Test-Path "C:\Shoreline Data\Vms\Message\$($savedvm).wav")
         {
            Copy-Item "C:\Shoreline Data\Vms\Message\$($savedvm).wav" "E:\sorted\$($folder)\$($savedvm).wav" -ErrorAction Continue
            Copy-Item "C:\Shoreline Data\Vms\Message\$($savedvm).msg" "E:\sorted\$($folder)\$($savedvm).msg" -ErrorAction Continue
            $allVMs.Remove("$($savedvm).wav")
            $allVMs.Remove("$($savedvm).msg")
         }
         else
         {
            "$($savedvm).wav" | Out-File "E:\sorted\$($folder)\MissingSavedVMs.txt" -Append -NoClobber
            Copy-Item "C:\Shoreline Data\Vms\Message\$($savedvm).msg" "E:\sorted\$($folder)\$($savedvm).msg" -ErrorAction Continue
            $allVMs.Remove("$($savedvm).msg")
         }
      }
   }

   if ($deletedvms)
   {
      'deleted'

      $deletedvms

      $deletedvms | Out-File "E:\sorted\$($folder)\deletedvms.txt" -Append -NoClobber
   }
   Clear-Variable folder
}
if ($allVMs)
{
   if (-not (test-path E:\sorted\Unsorted))
   {
      New-Item -Type Directory E:\sorted\Unsorted | Out-Null
   }
   foreach ($remainingVM in $allVMs)
   {
      Copy-Item "C:\Shoreline Data\Vms\Message\$($remainingVM)" "E:\sorted\Unsorted\$($remainingVM)" -ErrorAction Continue
   }
}
Stop-Transcript
Remove-Item C:\script.txt
