@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------

echo Adding 1368 x 912 resolution
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /f /v C_MODES_LFP_4d  /t REG_BINARY /d 01000000040000004d000000580590030854000000107d210618070000580500005805000017070000a80500003706000040dd0000b00300009003000090030000af03000091030000930300003c00000004000000000000000000000000000000000000000a0000000100000000000001000000000000000000 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0001" /f /v C_MODES_LFP_4d  /t REG_BINARY /d 01000000040000004d000000580590030854000000107d210618070000580500005805000017070000a80500003706000040dd0000b00300009003000090030000af03000091030000930300003c00000004000000000000000000000000000000000000000a0000000100000000000001000000000000000000 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0002" /f /v C_MODES_LFP_4d  /t REG_BINARY /d 01000000040000004d000000580590030854000000107d210618070000580500005805000017070000a80500003706000040dd0000b00300009003000090030000af03000091030000930300003c00000004000000000000000000000000000000000000000a0000000100000000000001000000000000000000 

echo Changing Resolution
start "" /wait "%~dp0Resources\nircmd.exe" setdisplay 1368 912 32 -updatereg
