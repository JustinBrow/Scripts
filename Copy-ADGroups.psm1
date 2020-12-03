#Requires -Modules ActiveDirectory

function Copy-ADGroups {
    param (
        [string]$CopyFromUser = (Read-Host "Copy from SAM"),
        [string]$CopyToUser = (Read-Host "Copy to SAM"),
        [switch]$RemoveOld
    )
    $DomainController = (Get-ADDomainController).HostName
    $CopyFromUserGroups = Get-ADUser $CopyFromUser -Properties MemberOf -Server $DomainController
    $CopyToUserGroups = Get-ADUser $CopyToUser -Properties MemberOf -Server $DomainController
    if ($RemoveOld)
    {
        $CopyToUserGroups.MemberOf | Remove-ADGroupMember -Members $CopyToUser -Server $DomainController -Confirm:$false
        $CopyToUserGroups = Get-ADUser $CopyToUser -Properties MemberOf -Server $DomainController
    }
    $CopyFromUserGroups.MemberOf | Where-Object {$CopyToUserGroups.MemberOf -NotContains $_} | Add-ADGroupMember -Members $CopyToUser -Server $DomainController
}

Export-ModuleMember -Function Copy-ADGroups