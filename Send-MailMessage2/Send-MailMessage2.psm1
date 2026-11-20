function Send-MailMessage2
{
   param (
      [Parameter(Mandatory=$True)]
      [string]$From,
      [Parameter(Mandatory=$True)]
      [string[]]$To,
      [string[]]$CC,
      [string[]]$Bcc,
      [string[]]$ReplyTo,
      [string]$Subject,
      [string]$Body,
      [string]$Attachments,
      [bool]$BodyAsHtml = $False,
      [Net.Mail.MailPriority]$Priority = [Net.Mail.MailPriority]::Normal,
      [Parameter(Mandatory=$True)]
      [string]$SmtpServer,
      [string]$Password,
      [bool]$UseSsl = $False,
      [bool]$UseDefaultCredentials = $True,
      [int]$Port = 25
   )
   
   $Message = [Net.Mail.MailMessage]::new()
   $Message.From = $From
   if ($To)
   {
      foreach ($_ in $To)
      {
         $Message.To.Add($_)
      }
   }
   $Message.Subject = $Subject
   $Message.Body = $Body
   if ($Cc)
   {
      foreach ($_ in $CC)
      {
         $Message.CC.Add($_)
      }
   }
   if ($Bcc)
   {
      foreach ($_ in $Bcc)
      {
         $Message.Bcc.Add($_)
      }
   }
   if ($ReplyTo)
   {
      foreach ($_ in $ReplyTo)
      {
         $Message.ReplyToList.Add($_)
      }
   }
   $Message.IsBodyHTML = $BodyAsHtml
   $Message.Priority = $Priority
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
