$searcher = [adsisearcher]::new()
$searcher.PageSize = 100
$searcher.Filter = "(objectClass=group)"
$columns = [ordered]@{
   UserCommonName  = @{Type = 'System.String'; Expression = 'if ($DirectoryEntry.Properties.sAMAccountName) {$DirectoryEntry.Properties.sAMAccountName[0]} else {$null}'};
   objectSID       = @{Type = 'System.String'; Expression = 'if ($DirectoryEntry.InvokeGet("objectSID")) {[Security.Principal.SecurityIdentifier]::new($DirectoryEntry.InvokeGet("objectSID"), 0).Value} else {$null}'};
   GroupCommonName = @{Type = 'System.String'; Expression = 'if ($group.Properties.samaccountname) {$group.Properties.samaccountname[0]} else {$null}'};
   GroupSID        = @{Type = 'System.String'; Expression = 'if ($group.Properties.objectsid) {[Security.Principal.SecurityIdentifier]::new($group.Properties.objectsid[0], 0).Value} else {$null}'};
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
         $DR.Item($column) = Invoke-Expression $columns[$column].Expression
      }
      $DT.Rows.Add($DR)
   }
}

if ($DT.Rows.Count -gt 0)
{
   $dbserver = 'MSSQLServer'
   $database = 'DB'
   $table = 'tblActiveDirectoryGroups2Users'

   $cn = [System.Data.SqlClient.SqlConnection]::new("Data Source=$dbserver;Integrated Security=SSPI;Initial Catalog=$database")
   $cn.Open()
   $bc = [System.Data.SqlClient.SqlBulkCopy]::new($cn)
   $bc.BatchSize = 10000
   $bc.BulkCopyTimeout = 1000
   $bc.DestinationTableName = $table
   $bc.WriteToServer($DT)
   $cn.Dispose()
}
