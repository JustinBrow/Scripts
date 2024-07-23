## QuickBooks Backup / AutoBackupEXE.exe
The PowerShell script `QBBackup.ps1` is the culmination of all of my research into how scheduled QuickBooks backups work.  
It's purpose is to backup all files sequentially when the scheduled task runs the script.

`AutoBackupEXE.exe` looks for a file `qbbackup.sys` in a hard coded location based on the year and edition, e.g., `C:\ProgramData\Intuit\QuickBooks Enterprise Solutions 24.0\qbbackup.sys`  
`qbbackup.sys` is a text/xml file with the file extension .sys

The schedule "id" is the Unix epoch time when the backup schedule was created by the QuickBooks application.
It does not appear to require being unique. I have used the same "id" for different files without issue.  
It is not required to schedule the backup within the QuickBooks application. Just open `qbbackup.sys` in a text editor.

The schedule "id" you pass to `AutoBackupEXE.exe` must exist inside the `qbbackup.sys` xml file. Example:  
`C:\Program Files\Intuit\QuickBooks Enterprise Solutions 24.0\AutoBackupEXE.exe /FQ:\QuickBooks.qbw /S /I1619578348`
```
<?xml version="1.0"?>
<backupdata>
	<file name="Q:\QuickBooks.qbw">
		<options>
			<NumOfClosingToBUVal>4</NumOfClosingToBUVal>
			<NumOfClosingToBUOnOff>1</NumOfClosingToBUOnOff>
			<AppendDateTimestampOnOff>1</AppendDateTimestampOnOff>
			<BUExternalFiles>0</BUExternalFiles>
			<Path>E:\Backups\</Path>
			<TimesClossed>0</TimesClossed>
			<UseXpCdBurn>1</UseXpCdBurn>
			<Verify>0</Verify>
			<LimitNumCopies>1</LimitNumCopies>
			<NumCopies>3</NumCopies>
			<mrcb/>
		</options>
		<automatic>
			<AutoBUIsOn>0</AutoBUIsOn>
			<AutoBUFreq>3</AutoBUFreq>
			<TimesClossed>0</TimesClossed>
		</automatic>
		<sticky>
			<Date>1614956301</Date>
			<Path>E:\Backups\</Path>
		</sticky>
		<scheduled id="1619578348">
			<NumOfBUToKeepOnOff>1</NumOfBUToKeepOnOff>
			<NumOfBUToKeepVal>1</NumOfBUToKeepVal>
			<SchedBUName>Backup</SchedBUName>
			<Path>E:\Backups\</Path>
		</scheduled>
	</file>
</backupdata>

```

Intuit does not provide documentation on what the exit codes mean, but files that exited with exit code 0 do not produce a .qbb (QuickBooks backup) file in the backup destination so I made the assumption that exit code 2 is success.  

Running `AutoBackupEXE.exe` does not truncate the SAP SQL Anywhere (formerly Sybase SQL Anywhere) transaction .tlg file. To truncate the transaction log file you must open the .qbw file in single-user mode and perform a complete verification.
