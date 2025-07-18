Option Explicit

Const AppTitle = "AJPapps - Bing logger WHT ver."
Const AppCopyright = "Линда Кайе 2013-2024. Посвящается Ариэль"

Const HTTPREQUEST_PROXYSETTING_DEFAULT = 0
Const HTTPREQUEST_PROXYSETTING_PRECONFIG = 0
Const HTTPREQUEST_PROXYSETTING_DIRECT = 1
Const HTTPREQUEST_PROXYSETTING_PROXY = 2

Const ProxyValue = 0 ' HTTPREQUEST_PROXYSETTING_PRECONFIG
'Const ProxyValue = 1 ' HTTPREQUEST_PROXYSETTING_DIRECT

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
  Dim WHT
  Dim TXT
  
  On Error Resume Next
  
  Set WHT = CreateObject("WinHttp.WinHttpRequest.5.1")
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Не удаётся создать объект Microsoft WinHTTP Services.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  ' ResolveTimeout As Long, ConnectTimeout As Long, 
  ' SendTimeout As Long, ReceiveTimeout As Long
  WHT.SetTimeouts 300 * 1000, 300 * 1000, 300 * 1000, 300 * 1000
  
  ' Устанавливаем системный прокси для соединения. Прокси 
  ' настраивается через Proxycfg.exe, а не через настойки Инета.
  ' Иначе будет напрямик...
  WHT.SetProxy ProxyValue, "", ""
  
  WHT.Open "GET", "http://www.bing.com"
  WHT.SetRequestHeader "User-Agent", UserAgent
  WHT.Send
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Ошибка отправки HTTP запроса.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  If WHT.Status <> 200 Then
    MsgBox "Не удалось получить главную страницу Bing." & _
           vbCrLf & vbCrLf & _
           "Сервер вернул: " & WHT.Status & " " & _
           WHT.StatusText & ".", vbCritical, AppTitle
    Exit Function
  End If
  
  ' Если вдруг сервер перейдёт на HTML5, а WinHTTP будет не готов 
  ' к этому (см Download mota.ru Image), то мы всё равно будем 
  ' готовы!
  TXT = GetWHTResponseText(WHT)
  GetPictureURL = ParseHTMLAndGetPictureURL(TXT) ' String
  Description = ParseHTMLAndGetDescription(TXT)  ' String
End Function

'====================================================================
Private Function GetJPGFile(ByVal URL, ByVal IsLastOne)
  Dim WHT
  
  On Error Resume Next
  
  Set WHT = CreateObject("WinHttp.WinHttpRequest.5.1")
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить картинку с Bing." & _
           vbCrLf & vbCrLf & _
           "Не удаётся создать объект Microsoft WinHTTP Services.", _
           vbCritical, AppTitle
    Exit Function
  End If
  
  ' ResolveTimeout As Long, ConnectTimeout As Long, 
  ' SendTimeout As Long, ReceiveTimeout As Long
  WHT.SetTimeouts 300 * 1000, 300 * 1000, 300 * 1000, 300 * 1000
  
  ' Устанавливаем системный прокси для соединения. Прокси 
  ' настраивается через Proxycfg.exe, а не через настойки Инета.
  ' Иначе будет напрямик...
  WHT.SetProxy ProxyValue, "", ""
  
  WHT.Open "GET", URL
  WHT.SetRequestHeader "User-Agent", AppTitle
  WHT.SetRequestHeader "Referer", "http://www.bing.com/"
  WHT.Send
  
  If Err.Number <> 0 Then
    MsgBox "Не удалось получить картинку с Bing." & _
           vbCrLf & vbCrLf & _
           "Ошибка отправки HTTP запроса." & _
           vbCrLf & vbCrLf & URL, _
           vbCritical, AppTitle
    Exit Function
  End If
  
  If WHT.Status <> 200 Then
    ' Если файл не существует, и это не последний URL, то
    ' не сообщать ничего, а просто выйти!
    If Not (Not IsLastOne And HTR.ResponseCode = 404) Then _
      MsgBox "Не удалось получить картинку с Bing." & _
             vbCrLf & vbCrLf & _
             "Сервер вернул: " & WHT.Status & " " & _
             WHT.StatusText & ".", vbCritical, AppTitle
    Exit Function
  End If
  
  GetJPGFile = WHT.ResponseBody  ' Byte array
  'GetJPGFile = WHT.ResponseText  ' String
End Function
