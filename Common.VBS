Option Explicit

'====================================================================
Private Function GetPathFromArgs()
  If WScript.Arguments.Count = 0 Then
    GetPathFromArgs = ""
    Exit Function
  End If
  
  If WScript.Arguments.Count = 1 Then
    Select Case UCase(WScript.Arguments(0))
      Case "/?"
        ShowUsage
      Case Else
        GetPathFromArgs = WScript.Arguments(0)
    End Select
    Exit Function
  End If
  
  ShowUsage
End Function

'====================================================================
Private Sub ShowUsage()
  MsgBox AppTitle & vbCrLf & _
         AppCopyright & vbCrLf & _
         vbCrLf & _
         "Использование:" & vbCrLf & _
         vbCrLf & _
         WScript.ScriptName & " [Path]" & vbCrLf & _
         vbCrLf & _
         "Path - путь к каталогу, куда скрипт будет сохранять " & _
         "картинки. Если не указан, программа будет сохранять " & _
         "в текущий каталог.", vbInformation, AppTitle
  
  ' Здесь всё закончится.
  WScript.Quit
End Sub

'====================================================================
Private Function ParseHTMLAndGetPictureURL(ByVal SourceString)
  Dim RE
  Dim MC
  Dim TXT
  Dim DumpFileName
  
  On Error Resume Next
  
  Set RE = New RegExp
  RE.Global = True
  RE.IgnoreCase = True
  RE.MultiLine = True
  
  'RE.Pattern = "{url: ""(/az/hprichbg/rb/.*?)"""
  'RE.Pattern = "{url: ""(/th\?id=OHR\.(.*?\.jpg))"
  'RE.Pattern = "{url: ""(/th\?id=OHR\.(.*?)\\u0026.*?)""}"
  'RE.Pattern = "{url:\s*?""(/th\?id=OHR\.(.*?)\\u0026.*?)""}"
  'RE.Pattern = "{""Url"":""(/th\?id=OHR\.(.*?)\\u0026.*?)"""
  'RE.Pattern = "(/th\?id=OHR\.([\w\.]*?\.jpg)\\u0026.*?)"""
  RE.Pattern = "(/th\?id=OHR\.([\w\.-]*?\.jpg)\\u0026.*?)"""
  
  Set MC = RE.Execute(SourceString)
  TXT = MC(0).SubMatches(0)
  Err.Clear
  
  If TXT = "" Then
    DumpFileName = DumpSourceHTML(SourceString)
    
    TXT = "Не удалось найти ссылку на картинку на главной " & _
          "странице Bing. Должно быть, опять что-то поменяли. " & _
          "Сообщите об этом автору."
    If DumpFileName <> "" Then
      TXT = TXT & vbCrLf & vbCrLf & _
                  "Исходная страница сохранена в файл:" & _
                  vbCrLf & vbCrLf & _
                  DumpFileName
    End If
    
    MsgBox TXT, vbCritical, AppTitle
    
    ParseHTMLAndGetPictureURL = ""
    Exit Function
  End If
  
  ' Заменяем заэкранированные слэши и амперсанды...
  TXT = Replace(TXT, "\/", "/")
  TXT = Replace(TXT, "\u0026", "&")
  
  If LCase(Left(TXT, 7)) = "http://" Then
    ParseHTMLAndGetPictureURL = TXT
  ElseIf LCase(Left(TXT, 8)) = "https://" Then
    ParseHTMLAndGetPictureURL = TXT
  ElseIf Left(TXT, 1) = "/" Then
    ParseHTMLAndGetPictureURL = "http://www.bing.com" & TXT
  Else
    ParseHTMLAndGetPictureURL = "http://www.bing.com/" & TXT
  End If
End Function

'====================================================================
Private Function ParseHTMLAndGetDescription(ByVal SourceString)
  Dim RE
  Dim MC
  Dim TMP
  Dim TXT
  Dim DumpFileName
  
  On Error Resume Next
  
  Set RE = New RegExp
  RE.Global = True
  RE.IgnoreCase = True
  RE.MultiLine = True
  
  'RE.Pattern = """copyright"":""(.*?)"""
  RE.Pattern = """Title"":""(.*?)"",""Copyright"":""(.*?)"""
  
  Set MC = RE.Execute(SourceString)
  ' Теперь описание разделено на два поля в целях стилизации 
  ' на странице. Поэтому мы собираем оба и делаем, как было раньше. 
  ' Тоесть тут в будущем поменять, возможно, придётся не только 
  ' регэксп, но и вот это...
  TXT = MC(0).SubMatches(0) & " (" & MC(0).SubMatches(1) & ")"
  
  If TXT = "" Then
    DumpFileName = DumpSourceHTML(SourceString)
    
    TXT = "Не удалось найти описание картинки на главной " & _
          "странице Bing. Должно быть, опять что-то поменяли. " & _
          "Сообщите об этом автору."
    If DumpFileName <> "" Then
      TXT = TXT & vbCrLf & vbCrLf & _
                  "Исходная страница сохранена в файл:" & _
                  vbCrLf & vbCrLf & _
                  DumpFileName
    End If
    
    MsgBox TXT, vbCritical, AppTitle
    
    ParseHTMLAndGetDescription = ""
    Exit Function
  End If
  
  ' Поубиваем знаки подстановки...
  For TMP = 0 To 255
    TXT = Replace(TXT, "&#" & TMP & ";", Chr(TMP))
  Next
  
  ParseHTMLAndGetDescription = TXT
End Function

'====================================================================
Private Function DumpSourceHTML(ByVal SourceString)
  Dim FSO
  Dim TempFolder
  Dim FileName
  
  Const TemporaryFolder = 2
  
  On Error Resume Next
  
  ' Предполагаем худшее...
  DumpSourceHTML = ""
  
  Set FSO = CreateObject("Scripting.FileSystemObject")
  Set TempFolder = FSO.GetSpecialFolder(TemporaryFolder)
  
  FileName = FSO.BuildPath(TempFolder.Path, FSO.GetTempName())
  FileName = FileName & ".html"
  
  ' Debug!
  'MsgBox FileName
  'MsgBox "«" & SourceString & "»"
  
  ' Сохранять как Unicode, а то Stream.Write вызывает ошибку. Сюда 
  ' прилетает юникодная строка, сконвертированная из байтового 
  ' массива. HTR версия делает это средствами объекта HTTPRequest, 
  ' а у WHT версии есть файл CommonWHT.VBS, который именно это 
  ' и делает. Если такую строку скормить Stream.Write, то она 
  ' ломается на юникодных символах и выдаёт ошибку, 
  ' а не конвертирует их в ANSI символы. А вот если Stream.Write 
  ' пишет в юникодный файл, то никаких проблем. Надеюсь =_=
  PutFile FileName, SourceString, True
  If Err.Number <> 0 Then
    MsgBox FileName & vbCrLf & vbCrLf & _
           "Не удалось сохранить файл дампа.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  DumpSourceHTML = FileName
End Function

'====================================================================
Private Sub SaveJPGFile(ByVal Path, ByVal PictureURL, ByVal PictureData, ByVal Description)
  Dim FileNameJPG
  Dim FileNameTXT
  Dim TMP
  Dim TXT
  
  On Error Resume Next
  
  ' Подготовка путей...
  If Path <> "" Then _
    If Right(Path, 1) <> "\" Then _
      Path = Path & "\"
  
  ' Сохраняем картинку...
  TMP = InStrRev(PictureURL, "/")
  FileNameJPG = Mid(PictureURL, TMP + 1)
  FileNameJPG = GetFileNameFromSearchURL(FileNameJPG)
  FileNameJPG = Path & FileNameJPG
  
  PutFile FileNameJPG, PictureData, False
  If Err.Number <> 0 Then
    MsgBox FileNameJPG & vbCrLf & vbCrLf & _
           "Не удалось сохранить файл.", _
           vbCritical, AppTitle
  End If
  
  ' Сохраняем описание картинки...
  TMP = InStrRev(FileNameJPG, ".")
  If TMP = 0 Then
    FileNameTXT = FileNameJPG & ".txt"
  Else
    FileNameTXT = Left(FileNameJPG, TMP - 1) & ".txt"
  End If
  
  TXT = "Description: " & Description & vbCrLf & _
        "Picture URL: " & PictureURL & vbCrLf & _
        "Save time:   " & Now
  
  PutFile FileNameTXT, TXT, True
  If Err.Number <> 0 Then
    MsgBox FileNameTXT & vbCrLf & vbCrLf & _
           "Не удалось сохранить файл.", _
           vbCritical, AppTitle
  End If
End Sub

'====================================================================
Private Sub PutFile(ByVal FileName, ByVal Text, ByVal Unicode)
  Select Case VarType(Text)
    Case vbString
      PutFileA FileName, Text, Unicode
    Case vbByte + vbArray
      PutFileB FileName, Text
  End Select
End Sub

Private Sub PutFileA(ByVal FileName, ByVal Text, ByVal Unicode)
  Dim FSO
  Dim File
  
  ' Debug!
  'MsgBox FileName
  'MsgBox "«" & SourceString & "»"
  
  Set FSO = CreateObject("Scripting.FileSystemObject")
  Set File = FSO.CreateTextFile(FileName, True, Unicode)
  
  File.Write Text
  File.Close
End Sub

Private Sub PutFileB(ByVal FileName, ByVal Text)
  Dim oStream
  
  Const adTypeBinary = 1
  Const adSaveCreateOverWrite = 2
  
  Set oStream = CreateObject("ADODB.Stream")
  
  oStream.Open
  oStream.Type = adTypeBinary
  oStream.Write Text
  oStream.SaveToFile FileName, adSaveCreateOverWrite
  oStream.Close
End Sub

'====================================================================
Private Function GetUserAgent()
  ' Для отладки. Для этого юзерагента Бинг выдаёт страницу без 
  ' описания! Не знаю, почему...
  'GetUserAgent = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
  
  'GetUserAgent = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0"
  'GetUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.100 Safari/537.36"
  'GetUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
  GetUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36"
End Function

'====================================================================
Private Function IsEmptyData(ByVal Data)
  If VarType(Data) = vbByte + vbArray Then
    IsEmptyData = False
  ElseIf VarType(Data) = vbString Then
    IsEmptyData = CBool(Data = "")
  Else
    IsEmptyData = True
  End If
End Function

'====================================================================
Private Function GetNewPictureURLs(ByVal PictureURL)
  Dim RE
  
  On Error Resume Next
  
  Set RE = New RegExp
  RE.Global = True
  RE.IgnoreCase = True
  RE.MultiLine = True
  
  RE.Pattern = "(_)(\d+x\d+)(\.)"
  GetNewPictureURLs = Array(RE.Replace(PictureURL, "$11920x1200$3"), _
                            RE.Replace(PictureURL, "$11920x1080$3"), _
                            RE.Replace(PictureURL, "$11366x768$3"), _
                            RE.Replace(PictureURL, "$11024x768$3"), _
                            PictureURL)
  
  If Err.Number <> 0 Then _
    GetNewPictureURLs = Array(PictureURL)
End Function

'====================================================================
Private Function GetFileNameFromSearchURL(ByVal URL)
  Dim RE
  Dim MC
  Dim TXT
  Dim DumpFileName
  
  On Error Resume Next
  
  Set RE = New RegExp
  RE.Global = True
  RE.IgnoreCase = True
  RE.MultiLine = True
  
  ' Ищем вот это:
  ' /th?id=OHR.GrapeHarvest_ROW5367417225_1920x1080.jpg
  RE.Pattern = "^th\?id=OHR\.(.*?\.jpg)"
  
  Set MC = RE.Execute(URL)
  TXT = MC(0).SubMatches(0)
  
  ' Если ничего не нашлось, возвращаем как есть!
  If TXT = "" Then
    GetFileNameFromSearchURL = URL
  Else
    GetFileNameFromSearchURL = TXT
  End If
End Function
