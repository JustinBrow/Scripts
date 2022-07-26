$isAdmin = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator

if (-not $isAdmin)
{
   exit
}

Set-StrictMode -Version 2.0

$SMTPServer = ''
$EmailFrom = ''
$EmailTo = ''
$EmailCc = ''

$MessageBody = [Collections.ArrayList]::new()

$Collections = Get-RDSessionCollection
ForEach ($CollectionName in $Collections.CollectionName)
{
   Get-RDSessionHost -CollectionName $CollectionName |
      Where-Object NewConnectionAllowed -eq No |
         ForEach {[void]$MessageBody.Add(
            [PSCustomObject][Ordered]@{
               CollectionName = $CollectionName;
               Server = $_.SessionHost.Split('.')[0];
               NewConnectionAllowed = $_.NewConnectionAllowed
            }
         )}
}

$EmailSubject = "Remote Desktop Session Hosts not enabled for logins"

if ($MessageBody)
{
   $Style = @"
<style>
   BODY{font-family: Calibri; font-size: 11pt;}
   TABLE{border: 1px solid black; border-collapse: collapse;}
   TH{border: 1px solid black; background: #dddddd; padding: 5px;}
   TD{border: 1px solid black; padding: 5px;}
</style>
"@

   $Message = [Net.Mail.MailMessage]::new($EmailFrom, $EmailTo)
   if ($EmailCc)
   {
      $Message.Cc.Add($EmailCc)
   }
   $Message.Subject = $EmailSubject
   $Message.IsBodyHTML = $true
   $Message.Body = $MessageBody | ConvertTo-Html -Head $Style | Out-String
   $SMTP = [Net.Mail.SmtpClient]::new($SMTPServer)
   $SMTP.Send($Message)
}
