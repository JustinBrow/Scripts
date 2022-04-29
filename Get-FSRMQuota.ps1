$DBServer = ""
$DB = ""
$Servers = @( "" )

ForEach ( $Server in $Servers ) {

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

	ForEach ( $i in 0 .. ( $QuotaData.Count - 1 ) ) {

		$HostName	 = $QuotaData[$i].HostName
		$PSComputerName	 = $QuotaData[$i].PSComputerName
		$Description	 = $QuotaData[$i].Description
		$Disabled	 = $QuotaData[$i].Disabled
		$MatchesTemplate = $QuotaData[$i].MatchesTemplate
		$TemplateName	 = $QuotaData[$i].TemplateName
		$Path		 = $QuotaData[$i].Path
		$PeakUsage	 = $QuotaData[$i].PeakUsage
		$Size		 = $QuotaData[$i].Size
		$SoftLimit	 = $QuotaData[$i].SoftLimit
		$Usage		 = $QuotaData[$i].Usage

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