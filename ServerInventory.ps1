$SessionStateEnum = @{
1 = 'CONSOLE_CONNECT'
2 = 'CONSOLE_DISCONNECT'
3 = 'REMOTE_CONNECT'
4 = 'REMOTE_DISCONNECT'
7 = 'SESSION_LOCK'
8 = 'SESSION_UNLOCK'
}

Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, Publisher, DisplayVersion, InstallDate, @{label="Name"; expression={$_.PSChildName}} | Export-Csv -NoTypeInformation C:\temp\Software.csv
Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, Publisher, DisplayVersion, InstallDate, @{label="Name"; expression={$_.PSChildName}} | Export-Csv -NoTypeInformation C:\temp\Software.csv -Append
Get-CimInstance Win32_Service | Select-Object -Property * -ExcludeProperty "CIM*" | Export-Csv -NoTypeInformation C:\temp\Services.csv
$Properties = @{
Property = "*",
@{label = 'Principal'; expression = {$_.Principal.UserId}},
@{label = 'Actions'; expression = {($_.Actions | % {[string]::Format("@{{Type={0}, Action={1} {2}, Id={3}, ClassId={4}, Data={5}}}", $_.CimClass.CimClassName, $_.Execute, $_.Arguments, $_.Id, $_.ClassId, $_.Data)}) -join ', ' }},
@{label = 'Triggers'; expression = {($_.Triggers | % {[string]::Format("@{{Type={0}, Enabled={1}, StartBoundary={2}, EndBoundary={3}, IntervalDays={4}, Delay={5}, RandomDelay={6}, ExecutionTimeLimit={7}, Subscription={8}, ValueQueries={9}, Id={10}, StateChange={11}, UserId={12}, Repetition=@{{Duration={13}, Interval={14}, StopAtDurationEnd={15}}}}}", $_.CimClass.CimClassName, $_.Enabled, $_.StartBoundary, $_.EndBoundary, $_.DaysInterval, $_.Delay, $_.RandomDelay, $_.ExecutionTimeLimit, $_.Subscription, $_.ValueQueries, $_.Id, $SessionStateEnum[[Convert]::ToInt32($_.StateChange)], $_.UserId, $_.Repetition.Duration, $_.Repetition.Interval, $_.Repetition.StopAtDurationEnd)}) -join ', ' }},
@{label = 'Settings'; expression = {[string]::Format("@{{AllowDemandStart={0}, AllowHardTerminate={1}, Compatibility={2}, DeleteExpiredTaskAfter={3}, DisallowStartIfOnBatteries={4}, Enabled={5}, ExecutionTimeLimit={6}, Hidden={7}, IdleSettings=@{{IdleDuration={8}, RestartOnIdle={9}, StopOnIdleEnd={10}, WaitTimeout={11}}}, MultipleInstances={12}, NetworkSettings=@{{Id={13}, Name={14}}}, Priority={15}, RestartCount={16}, RestartInterval={17}, RunOnlyIfIdle={18}, RunOnlyIfNetworkAvailable={19}, StartWhenAvailable={20}, StopIfGoingOnBatteries={21}, WakeToRun={22}, DisallowStartOnRemoteAppSession={23}, UseUnifiedSchedulingEngine={24}, MaintenanceSettings={25}, Volatile={26}}}", $_.Settings.AllowDemandStart, $_.Settings.AllowHardTerminate, $_.Settings.Compatibility, $_.Settings.DeleteExpiredTaskAfter, $_.Settings.DisallowStartIfOnBatteries, $_.Settings.Enabled, $_.Settings.ExecutionTimeLimit, $_.Settings.Hidden, $_.Settings.IdleSettings.IdleDuration, $_.Settings.IdleSettings.RestartOnIdle, $_.Settings.IdleSettings.StopOnIdleEnd, $_.Settings.IdleSettings.WaitTimeout, $_.Settings.MultipleInstances, $_.Settings.NetworkSettings.Id, $_.Settings.NetworkSettings.Name, $_.Settings.Priority, $_.Settings.RestartCount, $_.Settings.RestartInterval, $_.Settings.RunOnlyIfIdle, $_.Settings.RunOnlyIfNetworkAvailable, $_.Settings.StartWhenAvailable, $_.Settings.StopIfGoingOnBatteries, $_.Settings.WakeToRun, $_.Settings.DisallowStartOnRemoteAppSession, $_.Settings.UseUnifiedSchedulingEngine, $_.Settings.MaintenanceSettings, $_.Settings.Volatile)}}
ExcludeProperty = "Actions", "Principal", "Settings", "Triggers", "CIM*"
}
Get-ScheduledTask | Select-Object @Properties | Export-Csv -NoTypeInformation C:\temp\Tasks.csv
