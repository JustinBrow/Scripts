function Out-NPP
{
   [CmdletBinding()]
   param (
      [Parameter(ValueFromPipeline = $true)]
      [string[]]$Content,
      [string]$notepadpp = 'C:\Program Files\Notepad++\notepad++.exe'
   )
   begin
   {
      $buffer = [Collections.Generic.List[string]]::new()
      $tempPath = [IO.Path]::GetTempFileName()
   }
   process
   {
      if ($null -ne $Content)
      {
         $buffer.AddRange($Content)
      }
   }
   end
   {
      if (0 -lt $buffer.Count)
      {
         $buffer | Out-File -FilePath $tempPath -Encoding utf8
         Start-Process -FilePath $notepadpp -ArgumentList $tempPath -Wait
         Remove-Item -Path $tempPath
      }
   }
}
