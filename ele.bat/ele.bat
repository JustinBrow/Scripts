@ECHO OFF

:: ele.bat
:-------------------------------------
fsutil dirty query %systemdrive% >nul
IF NOT '%errorlevel%' == 0 (
   ECHO Requesting administrative privileges...
   GOTO getPrivileges
) ELSE (
   GOTO gotPrivileges
)

:getPrivileges
   ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getPrivileges.vbs"
   SET params = %*:"=""
   ECHO UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getPrivileges.vbs"
   
   "%SystemRoot%\System32\WScript.exe" "%temp%\getPrivileges.vbs"
   DEL "%temp%\getPrivileges.vbs"
   EXIT /B

:gotPrivileges
   pushd "%CD%"
   CD /D "%~dp0"

:--------------------------------------

rem Place commands/batch script here
