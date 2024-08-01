using namespace System;

Set-StrictMode -Version 2.0 #Ensure that basic best practices are followed

$ErrorActionPreference = 'Stop' #Stop on errors. You gotta catch 'em all!

$dbserver = 'MSSQLServer'
$database = 'DB'
$table = 'DNSRecords'

class DNSrecord {
   [string]$Domain
   [string]$Host
   [string]$Type
   [string]$OU
   DNSrecord(
      [string]$d,
      [string]$h,
      [string]$t,
      [string]$o
   ){
      $this.Domain = $d
      $this.Host = $h
      $this.Type = $t
      $this.OU = $o
   }
}

#Invoke-Sqlcmd -Query "Truncate Table $table" -ServerInstance $dbserver -Database $database

$colRecords = [Collections.ArrayList]::new()
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '@'                  ,   'A', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '@'                  ,  'MX', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '@'                  ,  'NS', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '@'                  , 'TXT', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '_dmarc'             , 'TXT', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', '20230125._domainkey', 'TXT', 'EXA' ) )
[void]$colRecords.Add( [DNSrecord]::new( 'example.com', 'www'                ,   'A', 'EXA' ) )

ForEach ($itmRecord in $colRecords)
{
   $DomainName = $itmRecord.Domain
   $HostName = $itmRecord.Host
   $RecordType = $itmRecord.Type
   $CustomerOU = $itmRecord.OU
   $Date = Get-Date
   $Query = "INSERT INTO $table (DomainName
                                ,HostName
                                ,RecordType
                                ,CustomerOU
                                ,IsTracked)
             VALUES
                                (`'$DomainName`'
                                ,`'$HostName`'
                                ,`'$RecordType`'
                                ,`'$CustomerOU`'
                                ,-1)"
   try
   {
      Invoke-Sqlcmd -Query $Query -ServerInstance $dbserver -Database $database
   }
   catch
   {
      throw $_.Exception.Message
   }
}
