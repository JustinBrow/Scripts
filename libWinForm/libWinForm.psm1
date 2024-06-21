#Requires -Version 5.1
#Requires -PSEdition Desktop

$MessageBox = {
   Add-Type -AssemblyName System.Windows.Forms
   function MessageBox
   {
      param (
         [string]$Text = [string]::Empty
      )
      if (-not [string]::IsNullOrEmpty($Text))
      {
         [Windows.Forms.MessageBox]::Show($Text)
      }
   }
}

function System.Windows.Forms.MessageBox
{
      param (
         [string]$Text = [string]::Empty
      )
      if (-not [string]::IsNullOrEmpty($Text))
      {
         Start-Job -ScriptBlock {MessageBox -Text $args} -ArgumentList $Text -InitializationScript $MessageBox | Out-Null
      }
}

Export-ModuleMember -Function System.Windows.Forms.MessageBox
