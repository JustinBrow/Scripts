$searcher = [adsisearcher]::new()
$searcher.PageSize = 100
$searcher.Filter = "(|(objectClass=user)(objectClass=contact)(objectClass=Computer))"
$properties = [ordered]@{
            badPasswordTime = 'System.Int64';                     badPasswordCount = 'System.String';
                         cn = 'System.String';                             company = 'System.String';
                 department = 'System.String';                         description = 'System.String';
                displayName = 'System.String';                   distinguishedName = 'System.String';
        extensionAttribute1 = 'System.String';                 extensionAttribute2 = 'System.String';
        extensionAttribute3 = 'System.String';                 extensionAttribute4 = 'System.String';
   facsimileTelephoneNumber = 'System.String';                           givenName = 'System.String';
              homeDirectory = 'System.String';                           homeDrive = 'System.String';
                    homeMDB = 'System.String';                                info = 'System.String';
                 lastLogoff = 'System.Int64';                   lastLogonTimestamp = 'System.Int64';
                 logonCount = 'System.String';                                mail = 'System.String';
               mailNickname = 'System.String';               mDBOverHardQuotaLimit = 'System.String';
          mDBOverQuotaLimit = 'System.String';                     mDBStorageQuota = 'System.String';
             mDBUseDefaults = 'System.String';                              mobile = 'System.String';
 msExchRecipientTypeDetails = 'System.String';                    msExchRecipLimit = 'System.String';
                       name = 'System.String';                      objectCategory = 'System.String';
                objectClass = 'System.String';                          objectGUID = 'System.String';
                  objectSID = 'System.String';                         profilePath = 'System.String';
                 pwdLastSet = 'System.Int64';                       sAMAccountName = 'System.String';
             sAMAccountType = 'System.String';                          scriptPath = 'System.String';
                         sn = 'System.String';                     telephoneNumber = 'System.String';
                      title = 'System.String';                  userAccountControl = 'System.String';
          userPrincipalName = 'System.String';                         whenChanged = 'System.DateTime';
                whenCreated = 'System.DateTime'
}

$DT = [Data.DataTable]::new()
ForEach ($key in $properties.Keys)
{
   $Col = [Data.DataColumn]::new()
   $Col.ColumnName = $key
   $Col.DataType = $properties[$key]
   $DT.Columns.Add($Col)
}

$searcher.PropertiesToLoad.AddRange([string[]]$properties.Keys)
$results = $searcher.FindAll()

ForEach ($result in $results)
{
   $DR = $DT.NewRow()
   ForEach ($key in $properties.Keys)
   {
      if ($result.Properties[$key].count -eq 0)
      {
         continue
      }
      if ($key -eq 'objectSID')
      {
         $DR.Item($key) = [System.Security.Principal.SecurityIdentifier]::new($result.Properties['objectSID'][0], 0).Value
         continue
      }
      if ($key -eq 'objectGUID')
      {
         $DR.Item($key) = ([guid]$result.Properties.objectguid[0]).Guid
         continue
      }
      if ($result.Properties[$key].count -eq 1)
      {
         $DR.Item($key) = $result.Properties[$key][0]
         continue
      }
      else
      {
         $value = [string]::Join(',', [string[]]$result.Properties[$key])
         $DR.Item($key) = $value
      }
   }
   $DT.Rows.Add($DR)
}

if ($DT.Rows.Count -gt 0)
{
   $dbserver = 'MSSQLServer'
   $database = 'DB'
   $table = 'tblActiveDirectoryObjects'

   $cn = [System.Data.SqlClient.SqlConnection]::new("Data Source=$dbserver;Integrated Security=SSPI;Initial Catalog=$database")
   $cn.Open()
   $bc = [System.Data.SqlClient.SqlBulkCopy]::new($cn)
   $bc.BatchSize = 10000
   $bc.BulkCopyTimeout = 1000
   $bc.DestinationTableName = $table
   $bc.WriteToServer($DT)
   $cn.Dispose()
}
