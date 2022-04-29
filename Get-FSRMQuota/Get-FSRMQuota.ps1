<#

.SYNOPSIS
Compiles information about drive quotas and inserts it into SQL server.

.DESCRIPTION
The Get-FSRMQuota script loops through the servers specified in the $Servers variable
compiling the drive quotas and then inserting the data into SQL Server.

Example Server format
@('Server1','Server2','Server3,'Server4')

.NOTES
CREATED ON: 2019-06-20
CREATED BY: Justin Brown
Purpose: This script exists to gather data for billing/reporting purposes.

#>

Set-StrictMode -Version 2.0

$DBServer = "MSSQLServer"
$DB = "DB"
$Servers = @( "" )

$BatchID = (Invoke-Sqlcmd -Query "SELECT MAX(BatchID)+1 AS NextBatchID FROM dbo.tblQuotas" -ServerInstance $DBServer -Database $DB).NextBatchID

ForEach ( $Server in $Servers )
{

	$QuotaData = Invoke-Command -ComputerName $Server -Command `
	{
	
		Get-FSRMQuota | `

		Select-Object @{ Label = "HostName"; Expression = { ( Get-Item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" ).GetValue( "HostName" ).Split( "." )[0] } },
			      PSComputerName,
			      Description,
			      Disabled,
			      MatchesTemplate,
			      TemplateName,
			      Path,
			      PeakUsage,
			      Size,
			      SoftLimit,
			      Usage
	}

	ForEach ( $QuotaObject in $QuotaData )
	{

		$HostName	 = $QuotaObject.HostName
		$PSComputerName	 = $QuotaObject.PSComputerName
		$Description	 = $QuotaObject.Description
		$Disabled	 = $QuotaObject.Disabled
		$MatchesTemplate = $QuotaObject.MatchesTemplate
		$TemplateName	 = $QuotaObject.TemplateName
		$Path		 = $QuotaObject.Path
		$PeakUsage	 = $QuotaObject.PeakUsage
		$Size		 = $QuotaObject.Size
		$SoftLimit	 = $QuotaObject.SoftLimit
		$Usage		 = $QuotaObject.Usage

		$Query = "INSERT INTO dbo.tblQuotas (BatchID
						,ObjectSID
						,HostName
						,VMName
						,Description
						,Disabled
						,MatchesTemplate
						,TemplateName
						,Path
						,PeakUsage
						,Size
						,SoftLimit
						,Usage)
			  VALUES		    ($BatchID
						,NULL
						,`'$HostName`'
						,`'$PSComputerName`'
						,`'$Description`'
						,`'$Disabled`'
						,`'$MatchesTemplate`'
						,`'$TemplateName`'
						,`'$Path`'
						,`'$PeakUsage`'
						,`'$Size`'
						,`'$SoftLimit`'
						,`'$Usage`')"

		Invoke-Sqlcmd -Query $Query -ServerInstance $DBServer -Database $DB
	}
}
