using namespace System.IO;

function Copy-FileSystemInfo
{
   param (
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path -Path $_})]
      [string]$Source,
      [Parameter(Mandatory=$true)]
      [ValidateScript({Test-Path -Path $_})]
      [string]$Target
   )
   $sourceAttributes = [File]::GetAttributes($Source)
   if ([FileAttributes]::Directory -eq ($sourceAttributes -band [FileAttributes]::Directory))
   {
      $sourceInfo = [DirectoryInfo]::new($Source)
   }
   else
   {
      $sourceInfo = [FileInfo]::new($Source)
   }
   $targetAttributes = [File]::GetAttributes($Target)
   if ([FileAttributes]::Directory -eq ($targetAttributes -band [FileAttributes]::Directory))
   {
      $targetInfo = [DirectoryInfo]::new($Target)
   }
   else
   {
      $targetInfo = [FileInfo]::new($Target)
   }
   $targetInfo.CreationTime = $sourceInfo.CreationTime
   $targetInfo.LastWriteTime = $sourceInfo.LastWriteTime
   $targetInfo.LastAccessTime = $sourceInfo.LastAccessTime
}
