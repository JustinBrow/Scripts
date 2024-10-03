$Domain = 'example'
$TLD = 'com'
$MailServer = "mail.$Domain.$TLD"
$From = "noreply@$Domain.$TLD"
$To = "me@$Domain.$TLD"

$CustomerOUs = (throw 'fill me in')

Connect-Exchange

ForEach ($CustomerOU in $CustomerOUs)
{
   $mailboxes = Get-Mailbox -OrganizationalUnit "OU=$CustomerOU,DC=$Domain,DC=$TLD"
   $mailboxForwardingPreText = "<p>List of <u>administrator-created</u> Mail-server rules that forward emails to non-$CustomerOU email addresses.</p>"
   $mailboxForwarding = @($mailboxes |
      Where-Object {
         ($_.ForwardingAddress -and $_.ForwardingAddress -notmatch $CustomerOU) -or $_.ForwardingSmtpAddress} |
            Select-Object @{Label = 'Mailbox'; Expression = {$_.UserPrincipalName}},
                          @{Label = 'Forwarding Destination'; Expression = {$_.ForwardingAddress}},
                          @{Label = 'Forwarding SMTP Address'; Expression = {$_.ForwardingSMTPAddress}}
   )
   if ($mailboxForwarding.Count -gt 0)
   {
      $mailboxForwarding = $mailboxForwarding | ConvertTo-Html -Fragment -PreContent $mailboxForwardingPreText | Out-String
   }
   else
   {
      $mailboxForwarding = "<p>No <u>administrator-created</u> Mail-server rules were found that forward emails to non-$CustomerOU email addresses.</p>"
   }
   $mailboxRulesPreText = "<p>List of <u>user-created</u> Outlook rules that forward emails to non-$CustomerOU email addresses.</p>"
   $mailboxRules = @($mailboxes |
      ForEach {
         Get-InboxRule -Mailbox $_.UserPrincipalName | Where-Object {
            $_.ForwardAsAttachmentTo -match '\[SMTP:' -or $_.ForwardTo -match '\[SMTP:' -or $_.RedirectTo -match '\[SMTP:'} |
               Select-Object Name, @{Label = 'Rule'; Expression = {$_.Description}}, MailboxOwnerId,
                             @{Label = 'ForwardAsAttachmentTo'; Expression = {[string]::Join(', ', ($_.ForwardAsAttachmentTo | ForEach {if ($_ -match '\[SMTP:') {$_}}))}},
                             @{Label = 'ForwardTo'; Expression = {[string]::Join(', ', ($_.ForwardTo | ForEach {if ($_ -match '\[SMTP:') {$_}}))}},
                             @{Label = 'RedirectTo'; Expression = {[string]::Join(', ', ($_.RedirectTo | ForEach {if ($_ -match '\[SMTP:') {$_}}))}}
      }
   )
   if ($mailboxRules.Count -gt 0)
   {
      $mailboxRules = $mailboxRules | ConvertTo-Html -Fragment -As List -PreContent $mailboxRulesPreText | Out-String
   }
   else
   {
      $mailboxRules = "<p>No <u>user-created</u> Outlook rules were found that forward emails to non-$CustomerOU email addresses.</p>"
   }
   $getADGroupSplat = @{
      Filter = 'GroupCategory -eq "Distribution"'
      SearchBase = "OU=$CustomerOU,DC=$Domain,DC=$TLD"
      Properties = 'Member'
   }
   $distributionGroupsPreText = "<p>List of <u>email distributions groups</u> and non-$CustomerOU group members</p>"
   $distributionGroups = Get-ADGroup @getADGroupSplat
   $distributionGroups = ForEach ($distributionGroup in $distributionGroups) {
      $foreignUsers = ForEach ($member in $distributionGroup.Member) {
         $name, $ou = $member -split '(?<!\\),', 2
         if ($member -notin $mailboxes.distinguishedName)
         {
            $name -replace '^CN='
         }
      }
      if ($foreignUsers)
      {
         [PSCustomObject]@{'Distribution Group Name' = $distributionGroup.SamAccountName; 'Recipient Mailbox(es)' = $foreignUsers -join ', '}
      }
   }
   if ($distributionGroups.Count -gt 0)
   {
      $distributionGroups = $distributionGroups | ConvertTo-Html -Fragment -PreContent $distributionGroupsPreText | Out-String
   }
   else
   {
      $distributionGroups = "<p>No <u>email distributions groups</u> found with non-$CustomerOU group members</p>"
   }
   $body = $mailboxRules, $mailboxForwarding, $distributionGroups -join ''
   Send-MailMessage -Body $body -BodyAsHtml -From $From -SmtpServer $MailServer -Subject "$CustomerOU backchannel report" -To $To
}
