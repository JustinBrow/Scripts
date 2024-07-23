$datetimeFormat = 'MM/dd/yyyy hh:mm tt'
$logFile = 'C:\logs\QBBackup.log'
$errorLog = 'C:\logs\QBBackup_error.log'

if (Test-Path $logFile)
{
   Remove-Item -LiteralPath $logFile
}
if (Test-Path $errorLog)
{
   Remove-Item -LiteralPath $errorLog
}

try
{
   # Update this when the next release of QuickBooks is installed
   [Xml]$qbbackup = Get-Content 'C:\ProgramData\Intuit\QuickBooks Enterprise Solutions 24.0\qbbackup.sys'
}
catch
{
   $Error[0] | Out-File -LiteralPath $errorLog -Append
   exit
}

if ($qbbackup -is [Xml])
{
   ForEach ($file in $qbbackup.backupdata.file)
   {
      if ($file.scheduled.Count -ge 2)
      {
         "$($file.name) has multiple backup schedules. To use this script please schedule only 1 backup" | Out-File -LiteralPath $errorLog -Append
         continue
      }

      if ($file.scheduled)
      {
         if (Test-Path $file.name)
         {
            # Update this when the next release of QuickBooks is installed
            $params = @{
               FilePath = 'C:\Program Files\Intuit\QuickBooks Enterprise Solutions 24.0\AutoBackupEXE.exe'
               ArgumentList = "/F$($file.name) /S /I$($file.scheduled.id)"
               Wait = $true
               PassThru = $true
            }

            "$($file.name)  started at $(Get-Date -Format $datetimeFormat)" | Out-File -LiteralPath $logFile -Append

            try
            {
               $process = Start-Process @params
            }
            catch
            {
               $Error[0] | Out-File -LiteralPath $errorLog -Append
               $Error.Clear()
               continue
            }

            "$($file.name) finished at $($process.ExitTime.ToString($datetimeFormat)) with code $($process.ExitCode)" | Out-File -LiteralPath $logFile -Append

            if ($process.ExitCode -ne 2)
            {
               "Exit code was not 2 at $(Get-Date -Format $datetimeFormat) for $($file.name)" | Out-File -LiteralPath $errorLog -Append
            }

            Start-Sleep -Seconds 1
         }
      }
   }
}
