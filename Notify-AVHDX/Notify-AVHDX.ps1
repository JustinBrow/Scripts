<#

.SYNOPSIS
Compiles a list of Hyper-V snapshot/checkpoint files and emails them to the listed recipients.

.DESCRIPTION
The Notify-AVHDX script loops through the servers and paths specified in the $HostDrive variable
compiling a list of ".avhdx" files and emailing them to persons specified in the $EmailTo &
$EmailCc variables using the SMTP server specified in the $SMTPServer variable.

Example Server\Drive\Path format
'{Server1Name}' = @('Server1Drive:Path1');
'{Server2Name}' = @('Server2Drive:Path1','Server2Drive:Path2');

.NOTES
LAST MODIFIED: 2025-11-25
CREATED ON: 2019-01-09
CREATED BY: Justin B.
Purpose: This script exists because people need to be notified when there are Hyper-V
snapshot/checkpoint files in existence.

#>

Set-StrictMode -Version 2.0 #Ensure that basic best practices are followed

$HostDrive = [Ordered]@{
   'Host01' = @('\\?\E:\','\\?\F:\');
   'Host02' = @('\\?\E:\','\\?\F:\');
   'Host03' = @('\\?\E:\','\\?\F:\');
} #Servers & Paths to search

$SMTPServer = 'mail.example.com' #Set Mail server
$EmailFrom = 'no-reply@example.com' #Set Email from
$EmailTo = 'supervisor@example.com,helpdesk@example.com' #Set Email To field
$EmailCc = 'me@example.com' #Set Email Cc field

$MessageBody = @() #Create an empty array to be filled in later

$Style = @"
   <style>BODY{font-family: Calibri; font-size: 11pt;}
   TABLE{border: 1px solid black; border-collapse: collapse;}
   TH{border: 1px solid black; background: #dddddd; padding: 5px;}
   TD{border: 1px solid black; padding: 5px;}
   </style>
"@ #CSS for email

$FileCount = 0 #This variable will be used as a counter later
$ErrorCount = 0 #This variable will be used as a counter later

$HyperVHosts = $HostDrive.Keys #Coding best practice?

ForEach ($HyperVHost in $HyperVHosts) #Loop through servers
{
   $Drives = $HostDrive[$HyperVHost] #Get the drives for the server
   
   ForEach ($Drive in $Drives) #Loop through drives for server
   {
      try
      {
         $Files = Invoke-Command -ComputerName $HyperVHost -ScriptBlock {
            try
            {
               (Get-ChildItem -LiteralPath $Using:Drive -File -Recurse -ErrorAction Stop | Where-Object Extension -eq '.avhdx').FullName
            }
            catch [System.Management.Automation.DriveNotFoundException]
            {
               throw [System.IO.DriveNotFoundException]::new($_.Exception.Message, $_)
            }
            catch
            {
               throw $_
            }
         } -ErrorAction Stop
         
         if ($Files -is [string] -and -not [string]::IsNullOrEmpty($Files))
         {
            $FileCount++
         }
         if ($Files -is [array])
         {
            $FileCount += $Files.Count
         }
      }
      catch [System.Management.Automation.Remoting.PSRemotingTransportException]
      {
         $ErrorCount++ #Increment the counter if an error occurs
         $Files = 'Error: Server is inaccessible'
      }
      catch [System.Management.Automation.RemoteException]
      {
         $ErrorCount++ #Increment the counter if an error occurs
         $Files = 'Error: Drive is inaccessible'
      }
      catch
      {
         throw $_
      }

      #Create an object that contains the data we want to see and add it to the array      
      $MessageBody = $MessageBody + ([PSCustomObject][Ordered]@{Server=$HyperVHost; Drive=$Drive -replace '^\\\\\?\\'; 'File(s)/Status'=$Files -replace '^\\\\\?\\' | Out-String})
   }
}

$EmailSubject = '{0} Hyper-V Snapshot File(s) Found' -f $FileCount #The email subject

if ($ErrorCount -ge 1)
{
   $EmailSubject = '{0} Error(s) encountered | {1}' -f $ErrorCount, $EmailSubject
}

if ($FileCount -eq 0) #If there aren't any files don't create a ticket, but do send an email to indicate the script ran
{
   $EmailTo = 'supervisor@example.com'
}

if ($MessageBody)
{
   $Message = [Net.Mail.MailMessage]::new($EmailFrom, $EmailTo)
   if ($EmailCc -and ($FileCount -ne 0))
   {
      $Message.Cc.Add($EmailCc)
   }
   $Message.Subject = $EmailSubject
   $Message.IsBodyHTML = $true
   $Message.Body = ($MessageBody | ConvertTo-Html -Head $Style) -Replace '(?m)\s+$', "<BR>`r`n" | Out-String
   $SMTP = [Net.Mail.SmtpClient]::new($SMTPServer)
   $SMTP.Send($Message)
}
