using namespace System;

Set-StrictMode -Version 2.0 #Ensure that basic best practices are followed

$ErrorActionPreference = 'Stop' #Stop on errors. You gotta catch 'em all!

$dbserver = 'MSSQLServer'
$database = 'DB'
$tblResults = 'DNSResults'
$tblRecords = 'DNSRecords'

$properties = [ordered]@{
          DNSID = 'System.Int32';            batchID = 'System.Int32';
             OU = 'System.String';            Domain = 'System.String';
           FQDN = 'System.String';              Type = 'System.String';
            TTL = 'System.Int32';             Result = 'System.String';
      QueryDate = 'System.DateTime';      RecCreated = 'System.DateTime'
}
$DT = [Data.DataTable]::new()
ForEach ($key in $properties.Keys)
{
   $Col = [Data.DataColumn]::new()
   $Col.ColumnName = $key
   $Col.DataType = $properties[$key]
   $DT.Columns.Add($Col)
}

try
{
   $colRecords = Invoke-Sqlcmd -Query "SELECT * FROM $tblRecords" -ServerInstance $dbserver -Database $database
   $batchID = (Invoke-Sqlcmd -Query "SELECT COALESCE(MAX(BatchID),0)+1 AS NextBatchID FROM $tblResults" -ServerInstance $dbserver -Database $database).NextBatchID
}
catch
{
   throw $_.Exception.Message
}

if (-not $colRecords -or -not $batchID)
{
   throw 'Critical variable empty'
}

ForEach ($itmRecord in $colRecords)
{
   if ($itmRecord.HostName -eq '@')
   {
      $FQDN = $itmRecord.DomainName
   }
   else
   {
      $FQDN = $itmRecord.HostName + '.' + $itmRecord.DomainName
   }
   $type = $itmRecord.RecordType
   $DateTime = Get-Date
   try
   {
      $dnsResult = Resolve-DnsName -Name $FQDN -Type $type -Server 8.8.8.8 -DnsOnly
   }
   catch
   {
      $DR = $DT.NewRow()
      $DR.Item('OU') = $itmRecord.CustomerOU
      $DR.Item('Domain') = $itmRecord.DomainName
      $DR.Item('FQDN') = $FQDN
      $DR.Item('Type') = 'Unknown'
      $DR.Item('TTL') = '-1'
      $DR.Item('Result') = 'Failed to resolve DNS'
      $DR.Item('QueryDate') = $DateTime
      $DR.Item('batchID') = $batchID
      $DT.Rows.Add($DR)
      continue
   }
   if ($dnsResult)
   {
      ForEach ($itmResult in $dnsResult)
      {
         if ($itmResult.Type -ne $type)
         {
            $DR = $DT.NewRow()
            $DR.Item('OU') = $itmRecord.CustomerOU
            $DR.Item('Domain') = $itmRecord.DomainName
            $DR.Item('FQDN') = $FQDN
            $DR.Item('Type') = $itmResult.Type
            $DR.Item('TTL') = '-1'
            $DR.Item('Result') = 'Unexpected result. Expected: ' + $type
            $DR.Item('QueryDate') = $DateTime
            $DR.Item('batchID') = $batchID
            $DT.Rows.Add($DR)
            continue
         }

         $DR = $DT.NewRow()
         $DR.Item('OU') = $itmRecord.CustomerOU
         $DR.Item('Domain') = $itmRecord.DomainName
         $DR.Item('FQDN') = $FQDN
         $DR.Item('Type') = $type
         $DR.Item('TTL') = $itmResult.TTL
         switch ($itmResult.Type)
         {
            A
            {
               $DR.Item('Result') = $itmResult.IP4Address
               continue
            }
            MX
            {
               $DR.Item('Result') = $itmResult.NameExchange
               continue
            }
            NS
            {
               $DR.Item('Result') = $itmResult.NameHost
               continue
            }
            TXT
            {
               $DR.Item('Result') = $itmResult.Strings -join ' '
               continue
            }
            CNAME
            {
               $DR.Item('Result') = $itmResult.NameHost
               continue
            }
            Default
            {
               $DR.Item('Type') = $itmResult.Type
               $DR.Item('TTL') = '-1'
               $DR.Item('Result') = 'Unsupported record type'
            }
         }
         $DR.Item('QueryDate') = $DateTime
         $DR.Item('batchID') = $batchID
         $DT.Rows.Add($DR)
      }
   }
}
if ($DT.Rows.Count -gt 0)
{
   $cn = [Data.SqlClient.SqlConnection]::new("Data Source=$dbserver;Integrated Security=SSPI;Initial Catalog=$database")
   try
   {
      $cn.Open()
      $bc = [Data.SqlClient.SqlBulkCopy]::new($cn)
      $bc.BatchSize = 10000
      $bc.BulkCopyTimeout = 1000
      $bc.DestinationTableName = $tblResults
      $bc.WriteToServer($DT)
   }
   catch
   {
      $fileName = $DateTime.ToString('yyyy-MM-ddTHH.mm.sszz') + '.txt'
      $DT | Export-Csv -LiteralPath "E:\TempData\Devops\DNSRecords\$fileName" -NoTypeInformation
      throw $_.Exception.Message
   }
   finally
   {
      $bc.Close()
      $cn.Dispose()
   }
}
