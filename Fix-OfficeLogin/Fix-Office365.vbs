Option Explicit
Dim iAnswer, WshShell, strLocalAppData

Const HKEY_CLASSES_ROOT   = &H80000000
Const HKEY_CURRENT_USER   = &H80000001
Const HKEY_LOCAL_MACHINE  = &H80000002
Const HKEY_USERS          = &H80000003
Const HKEY_CURRENT_CONFIG = &H80000005

iAnswer = _
   MsgBox("Office needs to be closed to fix your login. " &_
          "Close Office then click OK to continue." &_
          "", vbOKCancel, "Office 365 login fixer")

If iAnswer = vbOK Then
   Set WshShell = CreateObject("WScript.Shell")
   strLocalAppData = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%")

   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\IdentityCRL"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Office\16.0\Common\Identity"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows\CurrentVersion\AAD\Storage"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\JoinInfo"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows NT\CurrentVersion\WorkplaceJoin\TenantInfo"
   RecursiveRegDelete HKEY_CURRENT_USER, "Software\Microsoft\Windows NT\CurrentVersion\TokenBroker\ProviderInfo\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy"
   RecursiveFolderDelete strLocalAppData, "\Microsoft\Office\16.0\Licensing"
   RecursiveFolderDelete strLocalAppData, "\Microsoft\TokenBroker\Cache"
   RecursiveFolderDelete strLocalAppData, "\Microsoft\IdentityCache"
   RecursiveFolderDelete strLocalAppData, "\Microsoft\OneAuth"
   RecursiveFolderDelete strLocalAppData, "\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\LocalState"
   RecursiveFolderDelete strLocalAppData, "\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\AC\TokenBroker\Accounts"
   RecursiveFolderDelete strLocalAppData, "\Packages\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\AC\TokenBroker\Accounts"
   ' Use this when you're NOT using Entra federated identities.
   'RegCreateDWORD HKEY_CURRENT_USER, "Software\Microsoft\Office\16.0\Common\Identity", "NoDomainUser", 1

   Set WshShell = Nothing
   MsgBox "Done", vbOKOnly, "Office 365 login fixer"
   WScript.Quit
Else
   WScript.Quit
End If

Sub RecursiveFolderDelete(strRoot, strPath)
   Dim objFSO, strFolder
   Set objFSO = CreateObject("Scripting.FileSystemObject")
   If Len(strRoot) > 0 Then
      strFolder = strRoot + strPath
      If objFSO.FolderExists(strFolder) Then
         objFSO.DeleteFolder strFolder, True
      End If
   End If
   Set objFSO = Nothing
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
         objReg.DeleteKey strHive, strKey
      Else
         objReg.DeleteKey strHive, strKey
      End If
   End If
   Set objReg = Nothing
End Sub

Sub RegCreateDWORD(strHive, strKey, strValue, dwValue)
Dim objReg, arrSubKeys, strSubKey, iResult
   Set objReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
   iResult = objReg.EnumKey(strHive, strKey, arrSubKeys)
   If iResult = 2 Then
      objReg.CreateKey strHive, strKey
   End If
   objReg.SetDWORDValue strHive, strKey, strValue, dwValue
   Set objReg = Nothing
End Sub
