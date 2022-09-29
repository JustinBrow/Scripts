$SMTPServer = ''
$EmailFrom = ''
$EmailTo = ''
$EmailCc = ''

$Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
$Searcher.Filter = "(objectCategory=Computer)"

$Computers = @()
ForEach ($_ in $Searcher.FindAll())
{
    $Computers += $_.properties.name -replace $env:COMPUTERNAME, 'localhost'
}

$FileCount = 0

ForEach ($Computer in $Computers)
{
    Invoke-Command -ScriptBlock `
    {
        param ($Computer)

        $Drives = (Get-PSDrive).Root -match '^[A-Z]:\\$'

        ForEach ($Drive in $Drives)
        {
            if (-not (Test-Path -LiteralPath "\\?\$Drive"))
            {
                continue
            }

            ForEach ($_ in (Get-ChildItem -LiteralPath "\\?\$Drive" -Recurse))
            {
                if ($_.Extension -match '^\.pst$')
                {
                    [PSCustomObject]@{Server = $Computer -replace 'localhost', $env:COMPUTERNAME; File = $_.FullName -replace '\\\\\?\\'; Size = $_.Length; LastWriteTime = $_.LastWriteTime}
                }
            }
        }
    } -ComputerName $Computer -ArgumentList $Computer -AsJob
}

While (@(Get-Job | Where { $_.State -eq "Running" }).Count -ne 0)
{
   Start-Sleep -Seconds 10
}

$Files = ForEach ($Job in (Get-Job)) {
   Receive-Job $Job
   Remove-Job $Job
}

ForEach ($File in $Files)
{
    $Attachment = "$($File.Server),$($File.File),$($File.Size),$($File.LastWriteTime)" + "`r`n" + $Attachment
    $FileCount++
}

if ($FileCount -gt 0)
{
    $Attachment = 'Server,File,Size,LastWriteTime' + "`r`n" + $Attachment
    $Attachment = [Net.Mail.Attachment]::CreateAttachmentFromString($Attachment.ToString(), 'PST_File_Log.csv')

    $EmailSubject = "$FileCount PST File`(s`) Found"

    $Message = [Net.Mail.MailMessage]::new($EmailFrom, $EmailTo)
    If ($EmailCc)
    {
        $Message.Cc.Add($EmailCc)
    }
    $Message.Subject = $EmailSubject
    $Message.IsBodyHTML = $false
    $Message.Body = "Attached is your report."
    if ($Attachment)
    {
        $Message.Attachments.Add($Attachment)
    }
    $SMTP = [Net.Mail.SmtpClient]::new($SMTPServer)
    $SMTP.Send($Message)
}
