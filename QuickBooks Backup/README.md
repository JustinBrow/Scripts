## QuickBooks Backup / AutoBackupEXE.exe
QBBackup.ps1 is the culmination of all of my research into how scheduled QuickBooks backups work.

AutoBackupEXE.exe looks for a file `qbbackup.sys` in a hard coded location based on the year and edition, e.g., `C:\ProgramData\Intuit\QuickBooks Enterprise Solutions 24.0\qbbackup.sys`  
qbbackup.sys is a text/xml file with the file extension .sys

The schedule "id" is the epoch time when the backup schedule was created by the QuickBooks application.
It does not appear to require being unique and it is not required to schedule backup within the QuickBooks application. I have used the same "id" for different files without issue.

The schedule id you pass to AutoBackupEXE must exist inside the qbbackup.sys xml file. Example:  
`C:\Program Files\Intuit\QuickBooks Enterprise Solutions 24.0\AutoBackupEXE.exe /FQ:\QuickBooks.qbw /S /I1619578348`
```
<scheduled id="1619578348">
    <NumOfBUToKeepOnOff>1</NumOfBUToKeepOnOff>
    <NumOfBUToKeepVal>1</NumOfBUToKeepVal>
    <SchedBUName>Backup</SchedBUName>
    <Path>E:\Backups\</Path>
</scheduled>
```

Intuit does not provide documentation on what the exit codes mean, but I see more files exit with exit code 2 than exit code 0 so I made the assumption that exit code 2 is success.  
Additionally, the files that exited with exit code 0 do not produce a qbb file in the backup destination.
