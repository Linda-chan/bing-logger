Option Explicit

Const AppTitle = "AJPapps - Bing logger HTR ver."
Const AppCopyright = "Линда Кайе 2013-2024. Посвящается Ариэль"

Const ProxyValue = 0 ' psatPreconfigByIE
'Const ProxyValue = 1 ' psatDirect

Dim Path
Dim PictureURL
Dim NewPictureURLs
Dim Description
Dim PictureData
Dim UserAgent
Dim TMP

'====================================================================
Public Sub Main()
  ' Заранее получаем юзерагент, чтобы он не менялся при запросах...
  UserAgent = GetUserAgent()
  Path = GetPathFromArgs()
  
  PictureURL = GetPictureURL(Description)
  If PictureURL = "" Then Exit Sub
  
  ' Заполняем массив URL'ами с известными размерами, а последним 
  ' элементом ставим тот, что выдал нам сам Bing. Так мы боремся 
  ' с умной автоматикой, детектящей размеры экрана по IP.
  NewPictureURLs = GetNewPictureURLs(PictureURL)
  
  ' Пытаемся получить файл с каждого URL пока не найдём чего 
  ' существующего...
  For TMP = LBound(NewPictureURLs) To UBound(NewPictureURLs)
    PictureURL = NewPictureURLs(TMP)
    PictureData = GetJPGFile(PictureURL, CBool(TMP = UBound(NewPictureURLs)))
    If Not IsEmptyData(PictureData) Then Exit For
  Next
  
  If IsEmptyData(PictureData) Then Exit Sub
  SaveJPGFile Path, PictureURL, PictureData, Description
End Sub

'====================================================================
Private Function GetPictureURL(ByRef Description)
  Dim HTR 'As ajpHTTPRequest
  Dim Proxy 'As ProxySettings
  Dim TXT
  
  GetPictureURL = ""
  
  On Error Resume Next
  
  Set HTR = CreateObject("CmnFuncs0301.ajpHTTPRequest")
  Set Proxy = CreateObject("CmnFuncs0301.ProxySettings")
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Не удаётся создать объект ajpHTTPRequest.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  On Error Goto 0
  
  Proxy.HTTP_AccessType = ProxyValue
  Set HTR.ProxySettings = Proxy
  
  HTR.Execute "www.bing.com", , , _
              "/", , , , , , _
              UserAgent, , , True, True, True
  
  If HTR.ErrorCode <> 0 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Ошибка отправки HTTP запроса.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  If HTR.ResponseCode <> 200 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Сервер вернул: " & HTR.ResponseCode & " " & _
           HTR.ResponseText & ".", vbCritical, AppTitle
    Exit Function
  End If
  
  ' Сервер возвращает нам UTF-8, поэтому перегоняем его в UTF-16...
  TXT = Utf8ToChar(HTR.ReceivedData)
  GetPictureURL = ParseHTMLAndGetPictureURL(TXT)
  Description = ParseHTMLAndGetDescription(TXT)
End Function

'====================================================================
Private Function GetJPGFile(ByVal URL, ByVal IsLastOne)
  Dim HTR 'As ajpHTTPRequest
  Dim Proxy 'As ProxySettings
  Dim Protocol
  Dim Host
  Dim Port
  Dim SearchObject
  
  GetJPGFile = ""
  
  On Error Resume Next
  
  Set HTR = CreateObject("CmnFuncs0301.ajpHTTPRequest")
  Set Proxy = CreateObject("CmnFuncs0301.ProxySettings")
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить картинку с Bing." & _
           vbCrLf & vbCrLf & _
           "Не удаётся создать объект ajpHTTPRequest.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  On Error Goto 0
  
  If Not CrackURL(URL, Protocol, Host, Port, SearchObject) Then
    MsgBox "Не удалось получить картинку с Bing." & _
           vbCrLf & vbCrLf & _
           "Ошибка парсинга URL." & _
           vbCrLf & vbCrLf & URL, _
           vbCritical, AppTitle
    Exit Function
  End If
  
  Proxy.HTTP_AccessType = ProxyValue
  Set HTR.ProxySettings = Proxy
  
  HTR.Execute Host, Port, , _
              SearchObject, , "http://www.bing.com/", , , , _
              UserAgent, , , True, True, True
  
  If HTR.ErrorCode <> 0 Then
    MsgBox "Не удалось получить картинку с Bing." & _
           vbCrLf & vbCrLf & _
           "Ошибка отправки HTTP запроса." & _
           vbCrLf & vbCrLf & URL, _
           vbCritical, AppTitle
    Exit Function
  End If
  
  If HTR.ResponseCode <> 200 Then
    ' Если файл не существует, и это не последний URL, то
    ' не сообщать ничего, а просто выйти!
    If Not (Not IsLastOne And HTR.ResponseCode = 404) Then _
      MsgBox "Не удалось получить картинку с Bing." & _
             vbCrLf & vbCrLf & _
             "Сервер вернул: " & HTR.ResponseCode & " " & _
             HTR.ResponseText & ".", vbCritical, AppTitle
    Exit Function
  End If
  
  GetJPGFile = HTR.ReceivedData
End Function

' Этот велосипед необходим, поскольку функция библиотеки ждёт Long 
' и работать с вариантом не будет =_=
Private Function CrackURL(ByVal URL, ByRef Protocol, ByRef Host, _
                          ByRef Port, ByRef SearchObject)
  Dim RE
  Dim MC
  
  On Error Resume Next
  
  Set RE = New RegExp
  RE.Global = True
  RE.IgnoreCase = True
  RE.MultiLine = True
  
  RE.Pattern = "(.*?)://(.*?)(:(.*?))?(/.*)"
  
  Set MC = RE.Execute(URL)
  Protocol = MC(0).SubMatches(0)
  Host = MC(0).SubMatches(1)
  Port = MC(0).SubMatches(3)
  If Port = "" Then Port = 80 Else Port = CLng(Port)
  SearchObject = MC(0).SubMatches(4)
  
  CrackURL = CBool(Host <> "")
End Function
