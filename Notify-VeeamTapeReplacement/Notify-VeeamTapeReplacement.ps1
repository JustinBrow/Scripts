$TapeJob = 'SOBR_TAPE_MONTHLY'
$From = 'no-reply@example.com'
$To = 'me@example.com'
$Cc = 'supervisor@example.com'
$MailServer = 'mail.example.com'

$job = $null
$job = (Get-VBRTapeBackupSession -Job (Get-VBRTapeJob -Name $TapeJob)).Log | where Title -match 'Unloading|Exporting' | where Time -GT (Get-Date -Day 1)
if ($job -ne $null)
{
   $tapes = Get-VBRTapeMedium | where IsExpired -eq $true | select Barcode, ExpirationDate, MediaSet, LastWriteTime, Name, IsRetired, IsExpired, ProtectedBySoftware | select -Property *, @{label='LastWriteTimeInDays'; expression = {([datetime]::UtcNow - $_.LastWriteTime).Days}} | sort LastWriteTimeInDays
   $tape = $tapes  | where IsRetired -eq $false | select -Last 1
   $html = $tape | ConvertTo-Html -PreContent ($job | select Title, Time, Status | ConvertTo-Html -Fragment) -PostContent ($tapes | ConvertTo-Html -Fragment)
   $tape = Get-VBRTapeMedium -Name $tape.Name
   Disable-VBRTapeProtection -Medium $tape
   Send-MailMessage -Body ($html -join '') -BodyAsHtml -From $From -To $To -Cc $Cc -Subject 'Veeam Tape Status' -SmtpServer $MailServer
}
