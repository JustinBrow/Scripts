#Requires -Version 5.1
#Requires -PSEdition Desktop
param
(
   [string]$AdminEmail,
   [string]$UserEmail,
   $QuotaThreshold,
   [string]$User,
   [string]$TargetPath,
   [string]$Server,
   $QuotaMB,
   $UsedMB,
   $UsedPercent,
   [string]$TriggeringFilePath,
   [string]$FileScreen,
   [ValidateSet('Quota', 'FileScreen')]
   [string]$Type
)

$ErrorLogPath = "$PSScriptRoot\errors.txt"

$SMTPServer = 'mail.example.com'
$SMTPUser = 'powershell@example.com'
$SMTPPassword = ''

function Send-MailMessage2
{
   param (
      [Parameter(Mandatory=$True)]
      [string]$From,
      [Parameter(Mandatory=$True)]
      [string]$To,
      [string]$Cc,
      [string]$Bcc,
      [string]$Subject,
      [string]$Body,
      [string]$Attachments,
      [bool]$BodyAsHtml = $False,
      [Parameter(Mandatory=$True)]
      [string]$SmtpServer,
      [string]$Password,
      [bool]$UseSsl = $False,
      [bool]$UseDefaultCredentials = $True,
      [int]$Port = 25
   )
   
   $Message = [Net.Mail.MailMessage]::new($From, $To)
   $Message.Subject = $Subject
   $Message.Body = $Body
   if ($Cc)
   {
      $Message.Cc.Add($Cc)
   }
   if ($Bcc)
   {
      $Message.Bcc.Add($Bcc)
   }
   $Message.IsBodyHTML = $BodyAsHtml
   if ($Attachments)
   {
      $Attachment = [Net.Mail.Attachment]::new($Attachments, [Net.Mime.MediaTypeNames+Text]::Plain)
      $Message.Attachments.Add($Attachment)
   }
   $SMTP = [Net.Mail.SmtpClient]::new($SmtpServer)
   if (-not $UseDefaultCredentials)
   {
      $SMTP.UseDefaultCredentials = $UseDefaultCredentials
      $SMTP.Credentials = [Net.NetworkCredential]::new($From, $Password)
   }
   $SMTP.EnableSsl = $UseSsl
   $SMTP.Port = $Port
   try
   {
      $SMTP.Send($Message)
   }
   catch
   {
      throw $_.Exception.Message
   }
   finally
   {
      if ($Attachment)
      {
         $Attachment.Dispose()
      }
   }
}

$SendMailArguments = @{
   SmtpServer  = $SMTPServer;
   Port        = 587;
   UseSsl      = $true;
   UseDefaultCredentials = $false;
   From        = $SMTPUser;
   Password    = $SMTPPassword;
   To          = [string]::Empty;
   Subject     = [string]::Empty;
   BodyAsHtml  = $false;
   Body        = [string]::Empty
}

if ($User -eq 'NT AUTHORITY\SYSTEM')
{
   $User = $Server
}

if ($UserEmail -eq '[Source Io Owner Email]')
{
   $UserEmail = $false
}

if ($TargetPath.EndsWith('"'))
{
   $TargetPath = $TargetPath -replace '"', '\'
}

switch ($Type)
{
   'Quota'
   {
      $SendMailArguments.Subject = "${QuotaThreshold}% quota threshold exceeded"
      $SendMailArguments.Body = "User $User has exceeded the ${QuotaThreshold}% quota threshold for the quota on $TargetPath on server $Server. The quota limit is $QuotaMB MB, and $UsedMB MB currently is in use (${UsedPercent}% of limit)."
      break
   }
   'FileScreen'
   {
      $SendMailArguments.Subject = "Unauthorized file from the $FileScreen file group detected"
      $SendMailArguments.Body = "User $User attempted to save $TriggeringFilePath to $TargetPath on the $Server server. This file is in the $FileScreen file group, which is not permitted on the server."
      break
   }
   default
   {
      Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
      'PSBoundParameters' | Out-File -FilePath $ErrorLogPath -Append
      $PSBoundParameters | Out-File -FilePath $ErrorLogPath -Append
      $SendMailArguments.Subject = "Send-FSRMNotification: $env:COMPUTERNAME"
      $SendMailArguments.Body = 'Command Type Missing'
   }
}

try
{
   if (-not $SMTPPassword)
   {
      throw 'Need password'
   }
   if ($AdminEmail)
   {
      $SendMailArguments.To = $AdminEmail
      Send-MailMessage2 @SendMailArguments
   }
   if ($UserEmail)
   {
      $SendMailArguments.To = $UserEmail
      Send-MailMessage2 @SendMailArguments
   }
}
catch
{
   Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
   'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
   $_ | Out-File -FilePath $ErrorLogPath -Append
   'SendMailArguments' | Out-File -FilePath $ErrorLogPath -Append
   $SendMailArguments | Out-File -FilePath $ErrorLogPath -Append
   exit 1
}
