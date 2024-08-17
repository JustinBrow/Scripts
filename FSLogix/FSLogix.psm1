using namespace System;
using namespace System.Diagnostics;
using namespace System.IO;

function Mount-FSLogixProfile
{
   [OutputType([Bool])]
   param (
      [Parameter(Mandatory=$true)]
      [string]$FSLogixProfile,
      [Parameter(Mandatory=$true)]
      [AllowEmptyString()]
      [ValidateScript({$_.Value.GetType() -eq [string]})]
      [ref]$ProfileMount,
      [Parameter(Mandatory=$true)]
      [AllowEmptyString()]
      [ValidateScript({$_.Value.GetType() -eq [string]})]
      [ref]$RegistryMount,
      [Parameter(Mandatory=$true)]
      [AllowEmptyString()]
      [ValidateScript({$_.Value.GetType() -eq [string]})]
      [ref]$FSLogixCookie
   )

   if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue))
   {
      New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS | Out-Null
   }

   if (-not (Test-Path 'C:\Program Files\FSLogix\Apps\frx.exe'))
   {
      throw [IO.FileNotFoundException]::new('C:\Program Files\FSLogix\Apps\frx.exe')
   }

   $procinfo = [ProcessStartInfo]::new()
   $procinfo.FileName = 'C:\Program Files\FSLogix\Apps\frx.exe'
   $procinfo.RedirectStandardError = $true
   $procinfo.RedirectStandardOutput = $true
   $procinfo.UseShellExecute = $false
   $procinfo.Arguments = 'begin-edit-profile -filename ' + $FSLogixProfile
   $proc = [Process]::new()
   $proc.StartInfo = $procinfo

   try
   {
      Write-Host ('Mounting profile: ' + [Path]::GetFileName($FSLogixProfile))
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
         $fsl = $stdout -split '\r\n' -match '^C:\\.+?$|^FSL\.VHD\.\w{3,4}$|^\w{3,4}$'
         if ($fsl.Count -ne 3)
         {
            throw [ArgumentException]::new()
         }
         $profileMountPath = [Path]::Combine($fsl[0], 'Profile')
         $registryMountPath = [Path]::Combine('HKU:\', $fsl[1])
         if (-not ((Test-Path $profileMountPath) -and (Test-Path $registryMountPath)))
         {
            throw [DirectoryNotFoundException]::new()
         }
         Write-Host 'Success!'
         Write-Host ('FSLogix profile mounted to: ' + $profileMountPath)
         Write-Host ('Profile registry mounted to: ' + $registryMountPath)
         $ProfileMount.Value = $profileMountPath
         $RegistryMount.Value = $registryMountPath
         $FSLogixCookie.Value = $fsl[2]
         return $true
      }
   }
   catch
   {
      Write-Error $_.Exception.Message
      return $false
   }
}

function Dismount-FSLogixProfile
{
   [OutputType([Bool])]
   param (
      [Parameter(Mandatory=$true)]
      [string]$FSLogixProfile,
      [Parameter(Mandatory=$true)]
      [string]$FSLogixCookie
   )

   $procinfo = [ProcessStartInfo]::new()
   $procinfo.FileName = 'C:\Program Files\FSLogix\Apps\frx.exe'
   $procinfo.RedirectStandardError = $true
   $procinfo.RedirectStandardOutput = $true
   $procinfo.UseShellExecute = $false
   $procinfo.Arguments = 'end-edit-profile -cookie ' + $FSLogixCookie + ' -filename ' + $FSLogixProfile
   $proc = [Process]::new()
   $proc.StartInfo = $procinfo

   try
   {
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
      if ($stdout -like 'Error*0x00000005*')
      {
         throw [UnauthorizedAccessException]::new($stdout)
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
         return $true
      }
   }
   catch
   {
      Write-Error $_.Exception.Message
      return $false
   }
}
