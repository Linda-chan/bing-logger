Option Explicit

'====================================================================
' Byte ==> String
'====================================================================
Public Function ByteArrayToUtf8String(ByRef Data)
  Dim TMP
  Dim Stream
  
  If VarType(Data) <> vbByte + vbArray Then
    ByteArrayToUtf8String = ""
  Else
    Set Stream = CreateObject("ADODB.Stream")
    
    Stream.Mode = adModeReadWrite
    Stream.Open
    
    Stream.Type = adTypeBinary
    Stream.Write Data
    
    Stream.Position = 0
    
    Stream.Type = adTypeText
    Stream.Charset = "utf-8"
    ByteArrayToUtf8String = Stream.ReadText
  End If
End Function

'====================================================================
Public Function GetWHTResponseText(ByRef WHT)
  On Error Resume Next
  
  GetWHTResponseText = WHT.ResponseText
  If Err.Number <> 0 Then
    ' Символ Юникода не имеет сопоставления в конечной многобайтовой кодовой странице.
    Err.Clear
    GetWHTResponseText = ByteArrayToUtf8String(WHT.ResponseBody)
    If Err.Number <> 0 Then
      Err.Clear
      GetWHTResponseText = ""
    End If
  End If
End Function
