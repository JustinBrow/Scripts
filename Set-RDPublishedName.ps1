<#
.SYNOPSIS
This cmdlet allows you to change the published Fully Qualified Domain Name (FQDN) that clients use to connect to a Windows Server 2019/2016/2012R2/2012 Remote Desktop Services deployment.
This FQDN is included in .rdp files published via RD Web Access and the RemoteApp and Desktop Connections feed.

.DESCRIPTION
A common scenario where the ability to change the published name is useful is when your internal domain is .local, .private, .internal, etc.
For instance, you purchase and install a wildcard certificate (*.yourdomain.com) for use with RDS, but when your users connect they receive a name mismatch error because they are attempting to connect to rdcb.yourdomain.local.
This cmdlet allows you to change the FQDN they will use to a name that will match your certificate (rdcb.yourdomain.com).

.EXAMPLE
In this example the cmdlet is run directly on the RD Connection Broker and we would like to change the published name to remote.contoso.com.
We are making this change in order to match our installed wildcard certificate which has a subject of *.contoso.com:

Set-RDPublishedName "remote.contoso.com"

.NOTES
Depending on your configuration people connecting via RD Gateway may be unable to connect after changing the published FQDN.
They may receive error message similar to below:

===============

Remote Desktop can't connect to the remote computer "remote.contoso.com" for one of these reasons:

1) Your user account is not listed in the RD Gateway's permission list

2) You might have specified the remote computer in NetBIOS format (for example, computer1), but the RD Gateway is expecting an FQDN or IP address format (for example, computer1.fabrikam.com or 157.60.0.1)

Contact your network administrator for assistance.

===============

To solve this you may need to update your RD Gateway Resource Authorization Policy (RD RAP).
In RD Gateway Manager, Properties of your RD RAP, Network Resource tab, select Allow users to connect to any network resource.
An alternative is to create a RD Gateway-managed group with all of the required target ip addresses, NetBIOS names, and FQDNs in it, and then select the group on the Network Resource tab instead of the Allow Any option described above.
You may create/edit an RDG-managed group in RD Gateway Manager, select Resource Authorization Policies in left pane, then click Manage Local Computer Groups in Actions pane.

.LINK
https://gallery.technet.microsoft.com/Change-published-FQDN-for-2a029b80
#>

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,HelpMessage="Specifies the FQDN that clients will use when connecting to the deployment.",Position=1)]
   [string]$ClientAccessName,	
   [Parameter(Mandatory=$False,HelpMessage="Specifies the RD Connection Broker server for the deployment.",Position=2)]
   [string]$ConnectionBroker="localhost"
)

$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
If (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false)  
{
    $ArgumentList = "-noprofile -noexit -file `"{0}`" -ClientAccessName $ClientAccessName -ConnectionBroker $ConnectionBroker"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($MyInvocation.MyCommand.Definition))
    Exit
}

Function Get-RDMSDeployStringProperty ([string]$PropertyName, [string]$BrokerName)
{
    $ret = iwmi -Class "Win32_RDMSDeploymentSettings" -Namespace "root\CIMV2\rdms" -Name "GetStringProperty" `
        -ArgumentList @($PropertyName) -ComputerName $BrokerName `
        -Authentication PacketPrivacy -ErrorAction Stop
    Return $ret.Value
}

Try
{
    If ((Get-RDMSDeployStringProperty "DatabaseConnectionString" $ConnectionBroker) -eq $null) {$BrokerInHAMode = $False} Else {$BrokerInHAMode = $True}
}
Catch [System.Management.ManagementException]
{
    If ($Error[0].Exception.ErrorCode -eq "InvalidNamespace")
    {
        If ($ConnectionBroker -eq "localhost")
        {
            Write-Host "`n Set-RDPublishedName Failed.`n`n The local machine does not appear to be a Connection Broker.  Please specify the`n FQDN of the RD Connection Broker using the -ConnectionBroker parameter.`n" -ForegroundColor Red
        }
        Else
        {
            Write-Host "`n Set-RDPublishedName Failed.`n`n $ConnectionBroker does not appear to be a Connection Broker.  Please make sure you have `n specified the correct FQDN for your RD Connection Broker server.`n" -ForegroundColor Red
        }
    }
    Else
    {
        $Error[0]
    }
    Exit
}

$OldClientAccessName = Get-RDMSDeployStringProperty "DeploymentRedirectorServer" $ConnectionBroker

If ($BrokerInHAMode.Value)
{
    Import-Module RemoteDesktop
    Set-RDClientAccessName -ConnectionBroker $ConnectionBroker -ClientAccessName $ClientAccessName
}
Else
{
    $return = iwmi -Class "Win32_RDMSDeploymentSettings" -Namespace "root\CIMV2\rdms" -Name "SetStringProperty" `
        -ArgumentList @("DeploymentRedirectorServer",$ClientAccessName) -ComputerName $ConnectionBroker `
        -Authentication PacketPrivacy -ErrorAction Stop
    $wksp = (gwmi -Class "Win32_Workspace" -Namespace "root\CIMV2\TerminalServices" -ComputerName $ConnectionBroker)
    $wksp.ID = $ClientAccessName
    $wksp.Put()|Out-Null
}

$CurrentClientAccessName = Get-RDMSDeployStringProperty "DeploymentRedirectorServer" $ConnectionBroker

If ($CurrentClientAccessName -eq $ClientAccessName)
{
    Write-Host "`n Set-RDPublishedName Succeeded." -ForegroundColor Green
    Write-Host "`n     Old name:  $OldClientAccessName`n`n     New name:  $CurrentClientAccessName"
    Write-Host "`n If you are currently logged on to RD Web Access, please refresh the page for the change to take effect.`n"
}
Else
{
    Write-Host "`n Set-RDPublishedName Failed.`n" -ForegroundColor Red
}