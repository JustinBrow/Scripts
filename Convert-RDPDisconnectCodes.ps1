function Convert-RDPDisconnectCode
{
# powershell script to return description of rds client disconnect codes in decimal format (not hex)
param (
    [parameter(Position=0,Mandatory=$true,HelpMessage="Enter the disconnect reason code in decimal from client side rds trace")]
    [string] $disconnectReason,
    [string] $extendedReason = 0
   )
# https://docs.rackspace.com/docs/rds-client-disconnected-codes-and-reasons
   $mstsc = New-Object -ComObject MSTscAx.MsTscAx
   Write-Host "Description: $($mstsc.GetErrorDescription($disconnectReason,$extendedReason))"
   [Runtime.InteropServices.Marshal]::ReleaseComObject($mstsc) | Out-Null
   [GC]::Collect()
   [GC]::WaitForPendingFinalizers()
}
