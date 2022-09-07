<#

.SYNOPSIS
Compiles a list of disabled Veeam backup jobs and emails them to the listed recipients.

.DESCRIPTION
The Notify-DisabledVeeamBackups queries the Veeam server specified in the $VeeamServer variable for all Veeam
jobs and loops through them compiling a list of jobs that aren't enabled and emailing them to persons specified
in the $EmailTo & $EmailCc variables using the SMTP server specified in the $SMTPServer variable.

.NOTES
CREATED ON: 2019-10-29
CREATED BY: Justin B.
Purpose: This script exists because people need to be notified when Veeam jobs are disabled.

#>

Set-StrictMode -Version 2.0

$SMTPServer = ''
$EmailFrom = ''
$EmailTo = ''
$EmailCc = ''

Add-PSSnapin VeeamPSSnapin

$Jobs = Get-VBRJob | Select-Object Name, IsScheduleEnabled

if ($Jobs.Count -ge 1)
{
   $MessageBody = [Collections.ArrayList]::new()

   $Style = @"
<style>
   BODY{font-family: Calibri; font-size: 11pt;}
   TABLE{border: 1px solid black; border-collapse: collapse;}
   TH{border: 1px solid black; background: #dddddd; padding: 5px;}
   TD{border: 1px solid black; padding: 5px;}
</style>
"@

   $FileCount = 0

   ForEach ($Job in $Jobs)
   {
      $JobName = $Job.Name
      $JobStatus = $Job.IsScheduleEnabled

      if ($JobStatus -eq $false)
      {
         $FileCount++
         [void]$MessageBody.Add([PSCustomObject][Ordered]@{Job=$JobName; Enabled=$JobStatus})
      }
   }

   if ($MessageBody)
   {
      $EmailSubject = "$FileCount Veeam Backup Job`(s`) is/are disabled. Is this intentional?"
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
}
