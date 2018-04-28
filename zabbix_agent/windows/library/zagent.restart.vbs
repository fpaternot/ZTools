Set objFSO = CreateObject ("Scripting.FileSystemObject")
Path = objFSO.GetParentFolderName (Wscript.ScriptFullName)
Set objBAT = objFSO.CreateTextFile (Path & "\Restart_ZBXAgent.cmd", 2)
objBAT.WriteLine "net stop " & """" & "TVT_ZAgent" & """"
objBAT.WriteLine "timeout 2"
objBAT.WriteLine "net start " & """" & "TVT_ZAgent" & """"
objBAT.WriteLine "del /F %0"
objBAT.Close

strCommand = Path & "\Restart_ZBXAgent.cmd"
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\.\root\cimv2")

Const Create_New_Console = 16
Set objStartup = objWMIService.Get("Win32_ProcessStartup")
Set objConfig = objStartup.SpawnInstance_
objConfig.CreateFlags = Create_New_Console

Set objProcess = objWMIService.Get("Win32_Process")
intReturn = objProcess.Create (strCommand, Null, objConfig, intProcessID)

Wscript.echo "Reiniciando o ZAgent..."
