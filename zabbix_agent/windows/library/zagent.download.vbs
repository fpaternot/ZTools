URL = WScript.Arguments(0)
saveTo = WScript.Arguments(1) & Mid(URL, instrrev(URL, "/"), 100)

Set objXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
 
objXMLHTTP.open "GET", URL, false
objXMLHTTP.send()
 
If objXMLHTTP.Status = 200 Then
Set objADOStream = CreateObject("ADODB.Stream")
objADOStream.Open
objADOStream.Type = 1 'adTypeBinary
 
objADOStream.Write objXMLHTTP.ResponseBody
objADOStream.Position = 0    'Set the stream position to the start
 
Set objFSO = Createobject("Scripting.FileSystemObject")
If objFSO.Fileexists(saveTo) Then objFSO.DeleteFile saveTo
Set objFSO = Nothing
 
objADOStream.SaveToFile saveTo
objADOStream.Close
Set objADOStream = Nothing
End if
 
Set objXMLHTTP = Nothing
