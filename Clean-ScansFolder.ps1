$logFile = 'C:\logs\deletions.txt'
$errorFile = 'C:\logs\errors.txt'
$Today = Get-Date
$Today | Out-File -FilePath $logFile -Append
'FullName, LastWriteTime, CreationTime, LastAccessTime' | Out-File -FilePath $logFile -Append
$customers = @('A', 'B', 'C')
foreach ($customer in $customers)
{
    $scanDirectory = -join('E:\ftp', '\', "$customer", '\', 'scans')
    if (Test-Path -Path $scansdirectory)
    {
        $files = Get-ChildItem $scanDirectory -File -Recurse -Force | Where-Object { $_.LastWriteTime -lt $Today.AddDays(-7) -and $_.CreationTime -lt $Today.AddDays(-7) -and $_.LastAccessTime -lt $Today.AddDays(-7) }
        $folders = Get-ChildItem $scanDirectory -Directory -Recurse | Where-Object { $_.LastWriteTime -lt $Today.AddDays(-7) -and $_.CreationTime -lt $Today.AddDays(-7) -and $_.LastAccessTime -lt $Today.AddDays(-7) } | Sort-Object FullName -Descending
        ForEach ($file in $files)
        {
            try
            {
                $parent = $file.Directory
                $parentLastAccess = $parent.LastAccessTime
                $parentLastWrite = $parent.LastWriteTime
                Remove-Item -Path $file.FullName -Confirm:$false -Force
                $parent.LastAccessTime = $parentLastAccess
                $parent.LastWriteTime = $parentLastWrite 
                ($file.FullName + ', ' + $file.LastWriteTime + ', ' + $file.CreationTime + ', ' + $file.LastAccessTime) | Out-File -FilePath $logFile -Append
            }
            catch
            {
                $_.Exception.Message | Out-File -FilePath $errorFile -Append
            }
        }
        ForEach ($folder in $folders)
        {
            if ($folder.GetFiles().Count -eq 0)
            {
                try
                {
                    $parent = $folder.Parent
                    $parentLastAccess = $parent.LastAccessTime
                    $parentLastWrite = $parent.LastWriteTime
                    Remove-Item -Path $folder.FullName -Confirm:$false -Force
                    $parent.LastAccessTime = $parentLastAccess
                    $parent.LastWriteTime = $parentLastWrite 
                    ($folder.FullName + ', ' + $folder.LastWriteTime + ', ' + $folder.CreationTime + ', ' + $folder.LastAccessTime) | Out-File -FilePath $logFile -Append
                }
                catch
                {
                    $_.Exception.Message | Out-File -FilePath $errorFile -Append
                }
            }
        }
    }
}
