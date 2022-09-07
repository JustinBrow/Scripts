function connectedToExchange
{
   [bool]((Get-PSSession).ConfigurationName -like 'Microsoft.Exchange')
}

function Connect-Exchange
{
   if (-not (connectedToExchange))
   {
      #Automagically find Exchange
      Write-Host "`nFinding Exchange`n"
      $Forest = [DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Forest.Name
      $localSite = [DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite()
      $siteDN = $localSite.GetDirectoryEntry().DistinguishedName
      $configNC = ([ADSI]"LDAP://$Forest/RootDse").configurationNamingContext
      $search = [DirectoryServices.DirectorySearcher]::new([ADSI]"LDAP://$Forest/$configNC")
      $search.Filter = "(&(objectClass=msExchExchangeServer)(msExchServerSite=$siteDN))"
      $search.PageSize = 1000
      $search.PropertiesToLoad.Clear()
      [void]$search.PropertiesToLoad.Add("msexchcurrentserverroles")
      [void]$search.PropertiesToLoad.Add("networkaddress")
      $servers = $search.FindAll()
      $server = $servers | where {($_.properties["msexchcurrentserverroles"][0] -band 1)}
      $fqdn = $server.properties["networkaddress"] | where {$_.ToString().StartsWith("ncacn_ip_tcp")} | % {$_.ToString().SubString(13)}
      Write-Host "`nConnecting to Exchange"
      $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://$fqdn/PowerShell/ -Authentication Kerberos
      Import-Module (Import-PSSession $Session 3> $Null) -Global 3> $Null
      Write-Host "`nConnected to Exchange`n"
   }
   else
   {
      Write-Host "`nAlready connected to Exchange`n"
   }
}
