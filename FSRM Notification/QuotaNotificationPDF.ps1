#Requires -Version 5.1
#Requires -PSEdition Desktop
param
(
   [string]$AdminEmail,
   $Quota,
   $QuotaMB,
   [string]$Path,
   $Used,
   $UsedMB,
   $UsedPercent,
   [string]$TriggeringFilePath,
   [string]$TriggeringFileRemotePath,
   [string]$User,
   [string]$UserEmail
)

$SMTPServer = 'mail.example.com'
$HelpDeskEmail = 'HelpDesk@Example.com'

if (-not (Test-Path Z:\))
{
   $ErrorLogPath = "$PSScriptRoot\errors.txt"
   $ScanOptions  = "$PSScriptRoot\GlobalOptions.xml"
   $FilePath     = "$PSScriptRoot\$User"
   $PDFPath      = $FilePath + '.pdf'
   $OutputPath   = Split-Path -Path $FilePath -Parent

   & subst.exe "Z:" "$Path"

   if ($LASTEXITCODE -ne 0)
   {
      Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
      'ERROR: SUBST error' | Out-File -FilePath $ErrorLogPath -Append
      exit
   }

   if (-not (Test-Path -Path $OutputPath))
   {
      try
      {
         New-Item -Path $OutputPath -Type Directory
      }
      catch
      {
         Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
         'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
         $_ | Out-File -FilePath $ErrorLogPath -Append
         exit
      }
   }

   if (Test-Path -Path $PDFPath)
   {
      try
      {
         Remove-Item -Path $PDFPath
      }
      catch
      {
         Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
         'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
         $_ | Out-File -FilePath $ErrorLogPath -Append
         exit
      }
   }

   if (-not (Test-Path -Path $ScanOptions))
   {
      Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
      'ERROR: Scan Options missing' | Out-File -FilePath $ErrorLogPath -Append
      exit
   }

   $StartProcessParams = @{
      FilePath              = 'C:\Program Files\JAM Software\TreeSize\TreeSize.exe';
      ArgumentList          = "/NoGUI /Options $ScanOptions /Scan Z:\ /PDF $PDFPath /Title Z:\ /NoHeaders";
      RedirectStandardError = $ErrorLogPath;
      Wait                  = $true
   }

   try
   {
      Start-Process @StartProcessParams
   }
   catch
   {
      Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
      'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
      $_ | Out-File -FilePath $ErrorLogPath -Append
      exit
   }

   $SendMailArguments = @{
      SmtpServer  = $SMTPServer;
      From        = $HelpDeskEmail;
      To          = $UserEmail;
      Bcc          = $AdminEmail;
      Subject     = 'Your Z Drive is nearly full';
      BodyAsHtml  = $true;
      Body        = @"
Consider purging unneeded files or moving some data to your G Drive. See attached for details.<br><br>
The quota limit is $QuotaMB MB and you're currently using $UsedMB MB or ${UsedPercent}%
"@;
      Attachments = $PDFPath
   }

   try
   {
      Send-MailMessage @SendMailArguments
   }
   catch
   {
      Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
      'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
      $_ | Out-File -FilePath $ErrorLogPath -Append
      'SendMailArguments' | Out-File -FilePath $ErrorLogPath -Append
      $SendMailArguments | Out-File -FilePath $ErrorLogPath -Append
   }

   if (Test-Path -Path $PDFPath)
   {
      try
      {
         Remove-Item -Path $PDFPath
      }
      catch
      {
         Get-Date | Out-String | Out-File -FilePath $ErrorLogPath -Append
         'ERROR:' | Out-File -FilePath $ErrorLogPath -Append
         $_ | Out-File -FilePath $ErrorLogPath -Append
         exit
      }
   }

   & subst.exe "Z:" "/D"

   exit
}
