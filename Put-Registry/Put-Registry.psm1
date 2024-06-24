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
   
   $CMDOUT = @{
      Verbose = if ($PSBoundParameters.ContainsKey('Verbose')) {$PsBoundParameters.Get_Item('Verbose').IsPresent} else {$false};
      Debug = if ($PSBoundParameters.ContainsKey('Debug')) {$PsBoundParameters.Get_Item('Debug').IsPresent} else {$false}
   }
   
   Set-StrictMode -Version 3.0
   
   Start-Transaction
   
   if ([string]::IsNullOrEmpty($Key))
   {
      $Key = '(Default)'
   }
   
   Write-Verbose "Testing if path $path exists"
   $pathExists = Test-Path -Path $path @CMDOUT
   Write-Verbose "$pathExists"
   if (-not $pathExists)
   {
      try
      {
         Write-Verbose "Creating path $path"
         New-Item -Path $path -Force -UseTransaction @CMDOUT | Out-Null
      }
      catch
      {
         throw $_
      }
   }
   Write-Verbose "Testing if property $key exists under path $path"
   $property = Get-ItemProperty -Path $path -Name $key -ErrorAction SilentlyContinue @CMDOUT
   Write-Verbose (-not [string]::IsNullOrEmpty($property))
   if (-not $property)
   {
      try
      {
         Write-Verbose "Creating property $key under $path of type $type"
         New-ItemProperty -Path $path -Name $key -PropertyType $type -Value $value -UseTransaction @CMDOUT | Out-Null
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
         Write-Verbose "Setting property $key under $path of type $type"
         Set-ItemProperty -Path $path -Name $key -Type $type -Value $value -UseTransaction @CMDOUT
      }
      catch
      {
         throw $_
      }
   }
   Complete-Transaction
}
