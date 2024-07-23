## FSRM Notification
This script is so that FSRM can send TreeSize reports when a user's home drive is over quota.

FSRM runs PowerShell with the following arguments `-NoProfile -NonInteractive -File "C:\Windows\TreeSize\QuotaNotification.ps1" -AdminEmail [Admin Email] -Quota [Quota Limit] -QuotaMB [Quota Limit MB] -Path [Quota Path] -Used [Quota Used] -UsedMB [Quota Used MB] -UsedPercent [Quota Used Percent] -TriggeringFilePath [Source File Path] -TriggeringFileRemotePath [Source File Remote Paths] -User [Source Io Owner] -UserEmail [Source Io Owner Email]`
