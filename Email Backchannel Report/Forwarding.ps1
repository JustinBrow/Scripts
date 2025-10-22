$Domain = 'example'
$TLD = 'com'
$MailServer = "mail.$Domain.$TLD"
$From = "noreply@$Domain.$TLD"
$To = "me@$Domain.$TLD"

$CustomerOUs = (throw 'fill me in')

ForEach ($CustomerOU in $CustomerOUs)
{
   $mailboxes = Get-Mailbox -OrganizationalUnit "OU=$CustomerOU,DC=$Domain,DC=$TLD"
   $mailboxForwardingPreText = "<p>List of <u>administrator-created</u> Mail-server rules that forward emails.</p>"
   $mailboxForwarding = @($mailboxes |
      Where-Object {
         $PSItem.ForwardingAddress -or $PSItem.ForwardingSmtpAddress} |
            Select-Object @{Label = 'Mailbox'; Expression = {$PSItem.PrimarySmtpAddress.Address}},
                          @{Label = 'Forwarding Destination'; Expression = {$PSItem.ForwardingAddress}},
                          @{Label = 'Forwarding SMTP Address'; Expression = {$PSItem.ForwardingSMTPAddress}}
   )
   if ($mailboxForwarding.Count -gt 0)
   {
      $mailboxForwarding = $mailboxForwarding | ConvertTo-Html -Fragment -PreContent $mailboxForwardingPreText | Out-String
   }
   else
   {
      $mailboxForwarding = "<p>No <u>administrator-created</u> Mail-server rules were found that forward emails.</p>"
   }
   $mailboxRulesPreText = "<p>List of <u>user-created</u> Outlook rules that forward emails.</p>"
   $mailboxRules = @($mailboxes |
      ForEach-Object {
         Get-InboxRule -Mailbox $PSItem.UserPrincipalName |
            Where-Object {
               $PSItem.ForwardAsAttachmentTo -or $PSItem.ForwardTo -or $PSItem.RedirectTo} |
                  Select-Object Name, @{Label = 'Rule'; Expression = {$PSItem.Description}}, MailboxOwnerId,
                                @{Label = 'ForwardAsAttachmentTo'; Expression = {[string]::Join(', ', $PSItem.ForwardAsAttachmentTo)}},
                                @{Label = 'ForwardTo'; Expression = {[string]::Join(', ', $PSItem.ForwardTo)}},
                                @{Label = 'RedirectTo'; Expression = {[string]::Join(', ', $PSItem.RedirectTo)}}
      }
   )
   if ($mailboxRules.Count -gt 0)
   {
      $mailboxRules = $mailboxRules | ConvertTo-Html -Fragment -As List -PreContent $mailboxRulesPreText | Out-String
   }
   else
   {
      $mailboxRules = "<p>No <u>user-created</u> Outlook rules were found that forward emails.</p>"
   }
   $getADGroupSplat = @{
      Filter = 'GroupCategory -eq "Distribution"'
      SearchBase = "OU=$CustomerOU,DC=$Domain,DC=$TLD"
      Properties = 'Member'
   }
   $distributionGroupsPreText = "<p>List of <u>email distributions groups</u> and group members</p>"
   $distributionGroups = Get-ADGroup @getADGroupSplat
   $distributionGroups = @($distributionGroups |
      ForEach-Object {
         $users = $PSItem.Member |
            ForEach-Object {
               $name, $ou = $PSItem -split '(?<!\\),', 2
               $name -replace '^CN='
         }
         if ($users)
         {
            [PSCustomObject]@{'Distribution Group Name' = $PSItem.SamAccountName; 'Recipient Mailbox(es)' = $users -join ', '}
         }
      }
   )
   if ($distributionGroups.Count -gt 0)
   {
      $distributionGroups = $distributionGroups | ConvertTo-Html -Fragment -PreContent $distributionGroupsPreText | Out-String
   }
   else
   {
      $distributionGroups = "<p>No <u>email distributions groups</u> found with members</p>"
   }
   $body = $mailboxRules, $mailboxForwarding, $distributionGroups -join ''
   Send-MailMessage -Body $body -BodyAsHtml -From $From -SmtpServer $MailServer -Subject "$CustomerOU forwarding report" -To $To
}
