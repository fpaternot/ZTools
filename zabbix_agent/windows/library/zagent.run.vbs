Dim LIBRARY
Dim SCRIPT
Dim PARAMETERS
Dim RETURN
Dim COUNTArray

Set objFSO = CreateObject ("Scripting.FileSystemObject")
Path = objFSO.GetParentFolderName (Wscript.ScriptFullName)

Set objShell = WScript.CreateObject( "WScript.Shell" )

LIBRARY = Path & "\library"

COUNTArray = 0
Set objArgs = WScript.Arguments
Do While CountArray < objArgs.Count
  if CountArray = 0 Then
    SCRIPT = WScript.Arguments.Item( COUNTArray )
  Else
    PARAMETERS = PARAMETERS & " """ & WScript.Arguments.Item( COUNTArray ) & """"
  End If
  COUNTArray = COUNTArray + 1
Loop

Set objFSO = CreateObject ("Scripting.FileSystemObject")
For Each File in objFSO.GetFolder (LIBRARY).Files
    If uCase(objFSO.GetBaseName (File.Path)) = uCase(SCRIPT) Then
       If uCase(objFSO.GetExtensionName (File.Path)) = "PS1" Then
          Bin_ToUse = "powershell -NoLogo -File "
          SCRIPT = SCRIPT & ".PS1"
       ElseIf uCase(objFSO.GetExtensionName (File.Path)) = "BAT" Then
          Bin_ToUse = ""
          SCRIPT = SCRIPT & ".BAT"
       ElseIf uCase(objFSO.GetExtensionName (LIBRARY & "\" & SCRIPT)) = "CMD" Then
          Bin_ToUse = ""
          SCRIPT = SCRIPT & ".CMD"
       ElseIf uCase(objFSO.GetExtensionName (LIBRARY & "\" & SCRIPT)) = "EXE" Then
          Bin_ToUse = ""
          SCRIPT = SCRIPT & ".EXE"
       ElseIf uCase(objFSO.GetExtensionName (File.Path)) = "VBS" Then
          Bin_ToUse = "cscript //nologo "
          SCRIPT = SCRIPT & ".VBS"
       ElseIf uCase(objFSO.GetExtensionName (LIBRARY & "\" & SCRIPT)) = "VBE" Then
          Bin_ToUse = "cscript //nologo "
          SCRIPT = SCRIPT & ".VBE"
       End If
    End If
Next


Set objExecObject = objShell.Exec( Bin_ToUse & """" & LIBRARY & "\" & SCRIPT & " " & """" & PARAMETERS)
objExecObject.StdIn.Close( )
Do While Not objExecObject.StdOut.AtEndOfStream
  strText = objExecObject.StdOut.ReadLine
  WScript.Echo strText 
Loop