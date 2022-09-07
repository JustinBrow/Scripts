function mbxSize {
   param (
      [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
      [string]$User
   )

   begin
   {
      Connect-Exchange

      Add-Type -Path 'C:\Program Files\Microsoft\Exchange Server\V15\Bin\Microsoft.Exchange.Data.dll'
   }

   process
   {
      if (Get-Mailbox -Identity $user)
      {
         Get-MailboxFolderStatistics -Identity $user | Sort-Object @{Expression = {[Microsoft.Exchange.Data.ByteQuantifiedSize]::Parse($_.FolderSize).ToBytes()}; Descending = $true} | Select-Object Identity, FolderSize
      }
   }
}

Export-ModuleMember mbxSize
