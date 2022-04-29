Option Explicit

Dim strUsername, strFolder, strComputer
Dim objFolder, objSubFolder, objFile, objProcess
Dim colProcesses
Dim iReturn, iAnswer, iLaunch

Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
Dim objFSO : Set objFSO = CreateObject("Scripting.FileSystemObject")

strUsername = WshShell.ExpandEnvironmentStrings("%USERNAME%")

If Len(strUsername) > 0 Then
   strFolder = "C:\Users\" + strUsername + "\AppData\Roaming\Mimecast\"

   If objFSO.FolderExists(strFolder)Then
      Set objFolder = objFSO.GetFolder(strFolder)

      strComputer = "."
      Set colProcesses = GetObject("winmgmts:" & _
         "{impersonationLevel=impersonate}!\\" & strComputer & _
         "\root\cimv2").ExecQuery("SELECT * FROM Win32_Process WHERE Name LIKE '%Outlook%'")

      iLaunch = 0

      If colProcesses.Count > 0 Then
         For Each objProcess in colProcesses
            iReturn = objProcess.GetOwner(strUsername)

            If iReturn = 0 Then
               iAnswer = _
                  MsgBox("Microsoft Outlook is currently open. " &_
                         "Outlook needs to be closed to fix Mimecast. " &_
                         "Click Ok to close Outlook.", vbOKCancel, "Close Outlook")

               If iAnswer = vbOK Then
                  WshShell.Run "taskkill.exe /f /fi ""username eq %USERNAME%"" /im outlook.exe", 2, True
                  iLaunch = 1
               Else
                  WScript.Quit
               End If

               Exit For
            End If
         Next
      End If

      WScript.Sleep(2000)

      On Error Resume Next

      If objFolder.SubFolders.Count > 0 Then
         For Each objSubFolder In objFolder.SubFolders
            If objSubFolder.Files.Count > 0 Then
               For Each objFile In objSubFolder.Files
                  objFile.Delete True
                  If Err Then
                     WScript.Echo "Error deleting:" & objFile.Name & " - " & Err.Description
                  Else
                     WScript.Echo "Deleted:" & objFile.Name
                  End If
               Next
            End If

            objSubFolder.Delete True
            If Err Then
               WScript.Echo "Error deleting:" & objSubFolder.Name & " - " & Err.Description
            Else
               WScript.Echo "Deleted:" & objSubFolder.Name
            End If
         Next
      End If

      If objFolder.Files.Count > 0 Then
         For Each objFile In objFolder.Files
            objFile.Delete True
            If Err Then
               WScript.Echo "Error deleting:" & objFile.Name & " - " & Err.Description
            Else
               WScript.Echo "Deleted:" & objFile.Name
            End If
         Next
      End If

      On Error GoTo 0
   End If
End If

If iLaunch = 1 Then
   WshShell.Run "outlook.exe"
End If

Set objFSO = Nothing
Set WshShell = Nothing

WScript.Quit
