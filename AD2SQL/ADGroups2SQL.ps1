$searcher = [adsisearcher]::new()
$searcher.PageSize = 100
$searcher.Filter = "(objectClass=group)"
$columns = [ordered]@{
   UserCommonName  = @{Type = 'System.String'};
   objectSID       = @{Type = 'System.String'};
   GroupCommonName = @{Type = 'System.String'};
   GroupSID        = @{Type = 'System.String'};
}

$DT = [Data.DataTable]::new()
ForEach ($column in $columns.Keys)
{
   $Col = [Data.DataColumn]::new()
   $Col.ColumnName = $column
   $Col.DataType = $columns[$column].Type
   $DT.Columns.Add($Col)
}

$properties = @('sAMAccountName', 'member', 'objectSID')
$searcher.PropertiesToLoad.AddRange([string[]]$properties)
$groups = $searcher.FindAll()

ForEach ($group in $groups)
{
   ForEach ($member in $group.Properties.member)
   {
      $DR = $DT.NewRow()
      $ldapPath = 'LDAP://' + $member
      $DirectoryEntry = [adsi]::new($ldapPath)
      ForEach ($column in $columns.Keys)
      {
         switch ($column)
         {
            'UserCommonName'
            {
               $DR.Item('UserCommonName') = if ($DirectoryEntry.Properties.sAMAccountName) {$DirectoryEntry.Properties.sAMAccountName[0]} else {$null}
               continue
            }
            'objectSID'
            {
               $DR.Item('objectSID') = if ($DirectoryEntry.InvokeGet("objectSID")) {[Security.Principal.SecurityIdentifier]::new($DirectoryEntry.InvokeGet("objectSID"), 0).Value} else {$null}
               continue
            }
            'GroupCommonName'
            {
               $DR.Item('GroupCommonName') = if ($group.Properties.samaccountname) {$group.Properties.samaccountname[0]} else {$null}
               continue
            }
            'GroupSID'
            {
               $DR.Item('GroupSID') = if ($group.Properties.objectsid) {[Security.Principal.SecurityIdentifier]::new($group.Properties.objectsid[0], 0).Value} else {$null}
               continue
            }
         }
      }
      $DT.Rows.Add($DR)
   }
}

if ($DT.Rows.Count -gt 0)
{
   $dbserver = 'MSSQLServer'
   $database = 'DB'
   $table = 'tblActiveDirectoryGroups2Users'

   $cn = [Data.SqlClient.SqlConnection]::new("Data Source=$dbserver;Integrated Security=SSPI;Initial Catalog=$database")
   $cn.Open()
   $bc = [Data.SqlClient.SqlBulkCopy]::new($cn, [Data.SqlClient.SqlBulkCopyOptions]::TableLock)
   $bc.BatchSize = 10000
   $bc.BulkCopyTimeout = 1000
   $bc.DestinationTableName = $table
   $bc.WriteToServer($DT)
   $cn.Dispose()
}
