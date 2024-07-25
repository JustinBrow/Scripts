function New-Shortcut
{
   param (
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path -Path $_})]
      [string]$Path,
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path -Path $_})]
      [string]$Target,
      [string]$Arguments
   )
   
   if (([IO.File]::GetAttributes($target) -band [IO.FileAttributes]::Directory) -eq [IO.FileAttributes]::Directory)
   {
      $path = [IO.Path]::Combine($path, ([IO.Path]::GetFileName($target.TrimEnd('\')) + '.lnk'))
   }
   else
   {
      $path = [IO.Path]::Combine($path, ([IO.Path]::GetFileNameWithoutExtension($target) + '.lnk'))
   }
   $WshShell = New-Object -ComObject WScript.Shell
   $shortcut = $WshShell.CreateShortcut($path)
   $shortcut.TargetPath = $target
   if (-not ([String]::IsNullOrEmpty($arguments)))
   {
      $shortcut.Arguments = $arguments
   }   
   try
   {
      $shortcut.Save()
   }
   catch
   {
      throw $_
   }
   finally
   {
      [Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) | Out-Null
      [Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null
      [GC]::Collect()
      [GC]::WaitForPendingFinalizers()
   }
}
