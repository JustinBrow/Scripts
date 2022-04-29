$DBServer = ""
$DB = ""
$Servers = @( "" )

ForEach ( $Server in $Servers )
{

	$QuotaData = Invoke-Command -ComputerName $Server -Command { Get-FSRMQuota | `

		Select-Object @{ Label = "HostName"; Expression = { ( Get-Item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters" ).GetValue( "HostName" ).Split( "." )[0] } },
			      PSComputerName,
			      @{ Label = "Description"; Expression = { If ( ! ( $_.Description ) ) { Return "No description set." } Else { Return $_.Description } } },
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

		$Query = "INSERT INTO dbo.tblQuotas (ObjectSID
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
			  VALUES		    (NULL
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
