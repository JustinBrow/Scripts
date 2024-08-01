using namespace System;
using namespace System.Collections;
using namespace System.Diagnostics;
using namespace System.IO;

if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue))
{
   New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
}

$ErrorActionPreference = 'Stop'

$computer = '\\FileServer'
$share = 'FSLogixProfiles$'
$path = 'Production\Customer1'

$profilePath = [Path]::Combine($computer, $share, $path)

$fslogixProfiles = (Get-ChildItem -LiteralPath $profilePath -Filter '*.vhdx' -Recurse -File).FullName

if ($fslogixProfiles)
{
   # My super cool generic list to add data to
   #$mySuperGenericList = [Generic.List[Object]]::new()

   foreach ($fslogixProfile in $fslogixProfiles)
   {
      $procinfo = [ProcessStartInfo]::new()
      $procinfo.FileName = 'C:\Program Files\FSLogix\Apps\frx.exe'
      $procinfo.RedirectStandardError = $true
      $procinfo.RedirectStandardOutput = $true
      $procinfo.UseShellExecute = $false
      $procinfo.Arguments = 'begin-edit-profile -filename ' + $fslogixProfile
      $proc = [Process]::new()
      $proc.StartInfo = $procinfo
      try
      {
         Write-Host ('Mounting profile: ' + [Path]::GetFileName($fslogixProfile))
         [void]$proc.Start()
         $proc.WaitForExit()
         [string]$stdout = $proc.StandardOutput.ReadToEnd()
         [string]$stderr = $proc.StandardOutput.ReadToEnd()
         if ($stdout -eq 'Invalid Syntax')
         {
            throw [ArgumentException]::new()
         }
         if ($stdout -like 'Error*0x00000522*')
         {
            throw [UnauthorizedAccessException]::new($stdout)
         }
         if ($stdout -like 'Error*0x00000020*')
         {
            throw [IOException]::new($stdout)
         }
         if ($stdout -like 'Error*')
         {
            throw $stdout
         }
         elseif (-not [string]::IsNullOrEmpty($stderr))
         {
            throw $stderr
         }
         elseif ([string]::IsNullOrEmpty($stdout))
         {
            throw
         }
         if (($stdout -split '\r\n')[-2] -eq 'Operation completed successfully!')
         {
            Write-Host 'Success!'
         }
         # This will match the file path, registry mount, and FSLogix cookie.
         # The cookie appears to be a hexadecimal timestamp of some kind.
         $fsl = $stdout -split '\r\n' -match '^C:\\.+?$|^FSL\.VHD\.\w{3,4}$|^\w{3,4}$'
         if ($fsl.Count -ne 3)
         {
            throw [ArgumentException]::new()
         }
         $profilePath = [Path]::Combine($fsl[0], 'Profile')
         Write-Host ('FSLogix profile mounted to: ' + $profilePath)
         $registryPath = [Path]::Combine('HKU:\', $fsl[1])
         Write-Host ('Profile registry mounted to: ' + $registryPath)
         if (-not ((Test-Path $profilePath) -and (Test-Path $registryPath)))
         {
            throw [DirectoryNotFoundException]::new()
         }

         # Do something cool here with the mounted profile and added it to my List<Object>
         #$mySuperGenericList.Add($coolThing)

         $procinfo.Arguments = 'end-edit-profile -cookie ' + $fsl[2] + ' -filename ' + $fslogixProfile
         $proc = [Process]::new()
         $proc.StartInfo = $procinfo
         Write-Host 'Unmounting profile...'
         [void]$proc.Start()
         $proc.WaitForExit()
         [string]$stdout = $proc.StandardOutput.ReadToEnd()
         [string]$stderr = $proc.StandardOutput.ReadToEnd()
         if ($stdout -eq 'Invalid Syntax')
         {
            [ArgumentException]::new($stdout)
            $host.EnterNestedPrompt()
         }
         if ($stdout -like 'Error*0x00000522*')
         {
            throw [UnauthorizedAccessException]::new($stdout)
         }
         if ($stdout -like 'Error*0x00000057*')
         {
            throw [ArgumentException]::new($stdout)
         }
         if ($stdout -like 'Error*0x00000002*')
         {
            throw [FileNotFoundException]::new($stdout)
         }
         if ($stdout -like 'Error*')
         {
            throw $stdout
         }
         elseif (-not [string]::IsNullOrEmpty($stderr))
         {
            throw $stderr
         }
         elseif ([string]::IsNullOrEmpty($stdout))
         {
            throw
         }
         if (($stdout -split '\r\n')[-2] -eq 'Operation completed successfully!')
         {
            Write-Host 'Success!'
         }
      }
      catch
      {
         $_.Exception.Message
         continue
      }
   }
}

if ($mySuperGenericList)
{
   $mySuperGenericList | Export-Csv C:\temp\csv.csv -NoTypeInformation
   $mySuperGenericList | Export-Clixml C:\temp\cli.xml
   $mySuperGenericList | ConvertTo-Html | Out-File C:\temp\table.html
   $mySuperGenericList | ConvertTo-Html -As List | Out-File C:\temp\list.html
   $mySuperGenericList | ConvertTo-Json | Out-File C:\temp\file.json
   $mySuperGenericList | ConvertTo-Json -Compress | Out-File C:\temp\file.min.json
   $mySuperGenericList | ConvertTo-Xml -As String -NoTypeInformation | Out-File C:\temp\file.xml
   $mySuperGenericList | ConvertTo-Csv -NoTypeInformation | Out-File C:\temp\file.csv
   $mySuperGenericList | Out-File C:\temp\file.txt
}

# Mounting Errors
# Error attaching VHD (0x00000020): The process cannot access the file because it is being used by another process.
# Error attaching VHD (0x00000522): A required privilege is not held by the client.
# Error opening VHD (0x0000065E): Data of this type is not supported.

# Unmounting Errors
# Error unloading registry hive (0x00000522): A required privilege is not held by the client.
# Error unloading registry hive (0x00000057): The parameter is incorrect.
# Error removing mount point (0x00000002): The system cannot find the file specified.
# Error detaching VHD (0x00000522): A required privilege is not held by the client.
# Error detaching VHD (0x00000015): The device is not ready.
