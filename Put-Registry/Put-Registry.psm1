#Requires -Version 5.1
#Requires -PSEdition Desktop

function Put-Registry
{
   param (
      [Parameter(Mandatory=$true)]
      [string]$Path,
      [string]$Key = [string]::Empty,
      [Parameter(Mandatory=$true)]
      [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'Unknown')]
      [string]$Type,
      [Parameter(Mandatory=$true)]
              $Value
   )
   
   $ErrorActionPreference = 'Stop'
   
   $OutputPreference = @{
      Verbose = if ($PSBoundParameters.ContainsKey('Verbose')) {$PsBoundParameters.Get_Item('Verbose').IsPresent} else {$false};
      Debug = if ($PSBoundParameters.ContainsKey('Debug')) {$PsBoundParameters.Get_Item('Debug').IsPresent} else {$false}
   }
   
   Set-StrictMode -Version 3.0
   
   Start-Transaction
   
   if ([string]::IsNullOrEmpty($Key))
   {
      $Key = '(Default)'
   }

   if ($Type -eq 'Binary' -and $Value -is [String] -and -not [String]::IsNullOrEmpty($Value))
   {
      try
      {
         [byte[]]$Value = $Value -split '(..)' -ne '' -replace '..', '0x$&'
      }
      catch
      {
         throw $_
      }
   }
   
   $item = $null
   $string = "Testing if path $path exists... "
   Write-Verbose $string
   $pathExists = Test-Path -Path $path @OutputPreference
   #if ($OutputPreference.Verbose)
   #{
      #$Host.UI.RawUI.CursorPosition = @{X = 9 + $string.Length; Y = $Host.UI.RawUI.CursorPosition.Y - 1}
      #Write-Host $pathExists -NoNewLine -BackgroundColor Black -ForegroundColor Yellow
      #$Host.UI.RawUI.CursorPosition = @{X = 0; Y = $Host.UI.RawUI.CursorPosition.Y + 1}
   #}
   Write-Verbose "$pathExists"
   if (-not $pathExists)
   {
      try
      {
         Write-Verbose "Creating path $path"
         $item = New-Item -Path $path -Force -UseTransaction @OutputPreference
      }
      catch
      {
         throw $_
      }
   }
   $string = "Testing if property $key exists under path $path... "
   Write-Verbose $string
   $property = Get-ItemProperty -Path $path -Name $key -ErrorAction SilentlyContinue @OutputPreference
   #if ($OutputPreference.Verbose)
   #{
      #$Host.UI.RawUI.CursorPosition = @{X = 9 + $string.Length; Y = $Host.UI.RawUI.CursorPosition.Y - 1}
      #Write-Host (-not [string]::IsNullOrEmpty($property)) -NoNewLine -BackgroundColor Black -ForegroundColor Yellow
      #$Host.UI.RawUI.CursorPosition = @{X = 0; Y = $Host.UI.RawUI.CursorPosition.Y + 1}
   #}
   Write-Verbose (-not [string]::IsNullOrEmpty($property))
   if (-not $property)
   {
      try
      {
         Write-Verbose "Creating property '$key' under '$path' of type '$type' with value '$value'"
         New-ItemProperty -Path $path -Name $key -PropertyType $type -Value $value -UseTransaction @OutputPreference | Out-Null
      }
      catch
      {
         throw $_
      }
   }
   else
   {
      Write-Verbose "Property: $($property | Out-String)"
      try
      {
         Write-Verbose "Setting property '$key' under '$path' of type '$type' to value '$value'"
         Set-ItemProperty -Path $path -Name $key -Type $type -Value $value -UseTransaction @OutputPreference | Out-Null
      }
      catch
      {
         throw $_
      }
   }
   Complete-Transaction
   if (-not ($item -eq $null))
   {
      $item.Close()
      [GC]::Collect()
   }
}
