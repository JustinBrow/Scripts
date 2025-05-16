Option Explicit
Dim iAnswer

Const HKEY_CLASSES_ROOT   = &H80000000
Const HKEY_CURRENT_USER   = &H80000001
Const HKEY_LOCAL_MACHINE  = &H80000002
Const HKEY_USERS          = &H80000003
Const HKEY_CURRENT_CONFIG = &H80000005

iAnswer = _
   MsgBox("Office needs to be closed to fix your login. " &_
          "Close Office before continuing. " &_
          "Click Ok to continue.", vbOKCancel, "Office 365 login fixer")

If iAnswer = vbOK Then

   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Office\16.0\Common\Identity"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo"
   RecursiveFolderDelete "\AppData\Local\Microsoft\Office\16.0\Licensing"
   RecursiveFolderDelete "\AppData\Local\Microsoft\TokenBroker\Cache"
   RecursiveFolderDelete "\AppData\Local\Microsoft\IdentityCache"
   RecursiveFolderDelete "\AppData\Local\Microsoft\OneAuth"
   RecursiveFolderDelete "\AppData\Local\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\LocalState"
   RecursiveFolderDelete "\AppData\Local\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts"
   RecursiveFolderDelete "\AppData\Local\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\AC\TokenBroker\Accounts"

   MsgBox "Done", vbOKOnly, "Office 365 login fixer"
   WScript.Quit
Else
   WScript.Quit
End If

Sub RecursiveFolderDelete(strPath)
   Dim WshShell, objFSO, strUsername, strFolder
   Set WshShell = CreateObject("WScript.Shell")
   Set objFSO = CreateObject("Scripting.FileSystemObject")
   strUsername = WshShell.ExpandEnvironmentStrings("%USERNAME%")
   If Len(strUsername) > 0 Then
      If Len(strPath) > 0 Then
         strFolder = "C:\Users\" + strUsername + strPath
         If objFSO.FolderExists(strFolder) Then
            'MsgBox strFolder
            objFSO.DeleteFolder strFolder, True
         End If
      End If
   End If
   Set objFSO = Nothing
   Set WshShell = Nothing
End Sub

Sub RecursiveRegDelete(strHive, strKey)
Dim objReg, arrSubKeys, strSubKey, iResult
   Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
   iResult = objReg.EnumKey(strHive, strKey, arrSubKeys)
   If iResult = 0 Then
      If isArray(arrSubKeys) Then
         For Each strSubKey in arrSubKeys
            RecursiveRegDelete strHive, strKey & "\" & strSubKey
         Next
         'MsgBox strKey
         objReg.DeleteKey strHive, strKey
      Else
         'MsgBox strKey
         objReg.DeleteKey strHive, strKey
      End If
   End If
   Set objReg = Nothing
End Sub
