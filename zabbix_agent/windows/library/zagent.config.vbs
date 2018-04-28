Set objShell = CreateObject("WScript.Shell")
Set objSysEnv = objShell.Environment("SYSTEM")

ZBX_Path = objSysEnv("ZBX_Home")
ZBX_Conf_File = ZBX_Path & "\conf\zagent.conf"
ZBX_Conf_File_Temp = ZBX_Path & "\conf\zagent_temp.conf"

Set objFSO = CreateObject ("Scripting.FileSystemObject")
path = objFSO.GetParentFolderName (Wscript.ScriptFullName)
If Wscript.Arguments.Count < 1 Then
   Help()
ElseIf uCase(Wscript.Arguments.Item(0)) = "-ADD_INCLUDE" Then
   If Wscript.Arguments.Count <> 2 Then
      Wscript.echo "Erro de Sintaxe!"
      Help()
   End If
   If objFSO.FileExists (Wscript.Arguments.Item(1)) Then
      objFSO.CopyFile ZBX_Conf_File, ZBX_Conf_File_Temp
      Set file = objFSO.OpenTextFile (ZBX_Conf_File_Temp, 1)
      Set file_new = objFSO.CreateTextFile (ZBX_Conf_File, 2)
      Do Until file.AtEndOfStream
         lin = file.ReadLine
         If instr(1, uCase(lin), "INCLUDE=") > 0 Then
            Do Until lin = ""
               If uCase(lin) = "INCLUDE=" & uCase(Wscript.Arguments.Item(1)) Then
                  Wscript.echo "Erro! Este include ja existe."
               Else
                  file_new.WriteLine lin
               End If
               lin = file.ReadLine
            Loop
            file_new.WriteLine "Include=" & Wscript.Arguments.Item(1)
            file_new.WriteLine ""
         Else
            file_new.WriteLine lin
         End If
      Loop
      file.Close
      file_new.Close
   Else
      Wscript.echo "Erro! Arquivo '" & Wscript.Arguments.Item(1) & "' nao foi encontrado."
      Wscript.Quit
   End If
ElseIf uCase(Wscript.Arguments.Item(0)) = "-REMOVE_INCLUDE" Then
   If Wscript.Arguments.Count <> 2 Then
      Wscript.echo "Erro de Sintaxe!"
      Help()
   End If
   objFSO.CopyFile ZBX_Conf_File, ZBX_Conf_File_Temp
   Set file = objFSO.OpenTextFile (ZBX_Conf_File_Temp, 1)
   Set file_new = objFSO.CreateTextFile (ZBX_Conf_File, 2)
   Do Until file.AtEndOfStream
      lin = file.ReadLine
      If instr(1, uCase(lin),"INCLUDE=") > 0 Then
         If Split(uCase(lin), "=")(1) <> uCase(Wscript.Arguments.Item(1)) Then
            file_new.WriteLine lin
         End If
      Else
         file_new.WriteLine lin
      End If
   Loop
   file.Close
   file_new.Close
ElseIf uCase(Wscript.Arguments.Item(0)) = "-CHANGE" Then
   If Wscript.Arguments.Count <> 2 Then
      Wscript.echo "Erro de Sintaxe!"
      Help()
   Else
      If uCase(Split(Wscript.Arguments.Item(1), "=")(0)) = "INCLUDE" Then
         Wscript.echo "Erro! O item '" & Split(Wscript.Arguments.Item(1), "=")(0) & "' so pode ser removido ou adicionado."
         Help()
      End If
      objFSO.CopyFile ZBX_Conf_File, ZBX_Conf_File_Temp
      Set file = objFSO.OpenTextFile (ZBX_Conf_File_Temp, 1)
      Set file_new = objFSO.CreateTextFile (ZBX_Conf_File, 2)
      Range = ""
      Do Until file.AtEndOfStream
         lin = file.ReadLine
         If uCase(lin) = "### OPTION: " & uCase(Split(Wscript.Arguments.Item(1), "=")(0)) Then
            file_new.WriteLine lin
            Do Until Left(lin, 9) = "# Range: " Or Split(uCase(lin), "=")(0) = uCase(Split(Wscript.Arguments.Item(1), "=")(0))
               lin = file.ReadLine
               If Split(uCase(lin), "=")(0) & "=" <> uCase(Split(Wscript.Arguments.Item(1), "=")(0)) & "=" And Left(lin, 9) <> "# Range: " Then
                  file_new.WriteLine lin
               End If
               If Left(lin, 9) = "# Range: " Then
                  Range = Split(lin, "# Range: ")(1)
               End If
            Loop
            If Range <> "" Then
               If instr(1, uCase(Range), "CHARACTERS") > 0 Then
                  TypeR = "C"
                  Min = Split(Replace(uCase(Range), " CHARACTERS", ""), "-")(0)
                  Max = Split(Replace(uCase(Range), " CHARACTERS", ""), "-")(1)
               Else
                  TypeR = "N"
                  Min = Split(Range, "-")(0)
                  Max = Split(Range, "-")(1)
               End If
            End If
         End If
         If Range <> "" Then
            If TypeR = "N" Then
               If CDbl(Split(Wscript.Arguments.Item(1), "=")(1)) < CDbl(Min) Or CDbl(Split(Wscript.Arguments.Item(1), "=")(1)) > CDbl(Max) Then
                  Wscript.echo "Erro! O valor do item '" & Split(Wscript.Arguments.Item(1), "=")(0) & "' deve ser entre '" & Min & "' e '" & Max & "'."
                  file.Close
                  file_new.Close
                  objFSO.CopyFile ZBX_Conf_File_Temp, ZBX_Conf_File
                  objFSO.DeleteFile ZBX_Conf_File_Temp
                  Wscript.quit
               End If
            ElseIf TypeR = "C" Then
               If len(Split(Wscript.Arguments.Item(1), "=")(1)) < CDbl(Min) Or len(Split(Wscript.Arguments.Item(1), "=")(1)) > CDbl(Max) Then
                  Wscript.echo "Erro! O valor do item '" & Split(Wscript.Arguments.Item(1), "=")(0) & "' deve ter entre '" & Min & "' e '" & Max & "' caracteres."
                  file.Close
                  file_new.Close
                  objFSO.CopyFile ZBX_Conf_File_Temp, ZBX_Conf_File
                  objFSO.DeleteFile ZBX_Conf_File_Temp
                  Wscript.quit
               End If
            End If
         End if
         If instr(1, uCase(lin), uCase(Split(Wscript.Arguments.Item(1), "=")(0) & "=")) > 0 Then
            file_new.WriteLine Wscript.Arguments.Item(1)
         Else
            file_new.WriteLine lin
         End If
      Loop
      file.Close
      file_new.Close
      objFSO.DeleteFile ZBX_Conf_File_Temp
   End If
ElseIf uCase(Wscript.Arguments.Item(0)) = "-GET" Then
   If Wscript.Arguments.Count <> 2 Then
      Wscript.echo "Erro de Sintaxe!"
      Help()
   Else
      Set file = objFSO.OpenTextFile (ZBX_Conf_File, 1)
      Do Until file.AtEndOfStream
         lin = file.ReadLine
         If uCase(Split(lin, "=")(0)) = uCase(Wscript.Arguments.Item(1)) Then
            Ret = lin
         End If
      Loop
      If Ret <> "" Then
         Wscript.echo Ret
      Else
         Wscript.echo "Erro! O item '" & uCase(Wscript.Arguments.Item(1)) & "' nao foi encontrado."
      End If
      file.Close
   End If
ElseIf uCase(Wscript.Arguments.Item(0)) = "-LIST" Then
   Set file = objFSO.OpenTextFile (ZBX_Conf_File, 1)
   wscript.echo file.ReadAll
   file.Close
Else
   Wscript.echo "Erro de Sintaxe!"
   Help()
End If

Function Help()
   wscript.echo ""
   wscript.echo "Utilize:"
   wscript.echo "   -change %item%=%valor%  - Para alterar o valor de um item"
   wscript.echo "   -add_include %valor%    - Para adicionar um include"
   wscript.echo "   -remove_include %valor% - Para remover um include"
   wscript.echo "   -get %item%             - Para listar o valor de um item"
   wscript.echo "   -list                   - Para listar todas as configuracoes"
   Wscript.quit
End Function
