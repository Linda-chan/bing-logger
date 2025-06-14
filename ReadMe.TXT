﻿=====================================================================
AJPapps - Bing logger

Линда Кайе 2013-2025. Посвящается Ариэль
=====================================================================

Этот скрипт ни чего особого не делает. Он просто скачивает обойку с главной страницы Bing и сохраняет в указанную папку с файлом описания. Сохраняется только текущая обойки, другие, которые были ранее, не трогаются. Я написала его, когда разбирала кэш Бинга. Подумала, а почему бы и нет, и переделала скрипт AJPapps - Nuerburgring logger ^^

История изменений
-----------------

• 21.10.2013
  Первая версия ^^
  
• 6.11.2013
  [-] Перестало определяться описание картинки.
  
• 6.06.2014
  [+] Текстовые файлы теперь сохраняются с расширением в нижнем регистре. Для гармонии.
  
• 13.10.2014
  [+] Небольшие чистки в коде.
  [+] При скачке картинки передаётся реферер.
  [+] Вместо имени скрипта на сервер уходит случайный юзерагент.
  [+] Вместо CommonFunctions0300.DLL используется CommonFunctions0301.DLL.
  
• 2.12.2014
  [-] На сайте изменили код страницы, и описание картинки перестало определяться.
  [+] Настройки прокси вынесены в константу.
  
• 3.09.2015
  [+] Скрипт пытается получить картинку максимального размера, а не ту, которую присылает Бинг.
  [+] Обновила юзерагент для Симанки.
  
• 23.11.2015
  [-] Перестало определяться описание картинки.
  
• 15.05.2016
  [-] Перестал определяться адрес картинки.
  [-] Если в будущем скрипт снова перестанет определять адрес или описание картинки, об этом будет сообщаться.
  
• 30.06.2016
  [-] Перестал определяться адрес картинки.
  
• 4.07.2016
  [-] В описании картинки появлялся мусор в самом конце.
  [-] HTR версия не учитывала тот факт, что Bing присылает картинку в UTF-8.
  [+] Скрипт портирован в WSF формат.
  
• 1.12.2016
  [-] Перестало определяться описание картинки.
  
• 19.02.2017
  [-] Добавлена Ruby версия, работающая как под Windows, так и под Linux.
  
• 4.03.2017
  [+] Поправлен вывод Usage в VBScript версиях.
  
• 11.03.2017
  [+] В Ruby версию скрипта добавила функцию для форматирования сообщения об ошибке на случай проблем с кодировкой. Теперь сообщение об ошибке должно стать ещё красивее!
  [+] Код WHT версии немного синхронизирован с WHT версией Download mota.ru Image для обхода возможных будущих проблем определения кодировки HTML5 файлов в WinHTTP (если Bing вообще перейдёт на HTML5).
  
• 15.01.2018
  [+] Обновила модуль CharToOem.VBS.
  [+] Удалила модуль ByteOperations.VBS.
  
• 5.12.2018
  [+] Убрала ReadMe из заголовков скриптов. Чтобы не было дублей.
  [+] Если не удаётся найти описание картинки или ссылку на неё, то исходник страницы сохраняется во временном файле для отладки.
  [+] Оставила один юзерагент, чтобы сервер не напрягся от того, что с одного айпишника десять броузеров ходят.
  [-] Судя по всему, юзерагент старой версии IE вызывал проблему, когда сервер не возвращал описание картинки. Исправлено.
  
• 6.12.2018
  [-] Убран BOM из rnd.rb.
  
• 9.03.2019
  [-] Поправила ошибки в регулярных выражениях в Ruby версии скрипта.
  [-] Bing изменил формат URL картинок. Теперь они снова определяются.
  
• 10.03.2019
  [-] VBScript версия не могла правильно обработать URL, если был указан каталог для сохранения картинки.
  [-] Устранено предупреждение о неиспользуемой переменной в Ruby версии.
  
• 13.03.2019
  [-] Bing чуть подправил код страниц. Теперь URL картинок снова определяется.
  
• 17.01.2020
  [-] Опять поломали исходники страниц Bing - регэкспы не срабатывали.
  [+] Обновила юзерагент.
  [+] Обновила модуль CharToOem.VBS.
  [-] Ruby версия скрипта иногда встречала ридерект 302 и не могла его обработать.	
  
• 7.05.2023
  [-] На сайте опять немного поменяли. Поправила.
  [+] Обновила юзерагент.
  
• 17.10.2024
  [+] Обновила юзерагент.
  
• 27.10.2024
  [-] Bing начал выдавать имена файла картинки с "EN-US" вместо "ROW". Не понимаю, от чего это зависит.
  [+] Поправлен шебанг в RB файлах.
  
• 13.05.2025
  [-] Функция GetCharset() в модуле CharToOem.VBS была капитально поломана и возвращала только значения по умолчанию.

Использование
-------------

VBScript версия этого скрипта работает только в системе Windows. По историческим причинам она сама имеет две версии:

1. WHT ver. Использует WinHTTP Services. Работает только в системе Windows 2000 и выше. При этом ни чего дополнительно ставить не нужно.

2. HTR ver. Использует мой собственный WinInet класс - ajpHTTPRequest. Поэтому требует библиотеки CommonFunctions0301.DLL. Её можно установить с любой моей программой. Однако работает даже в Windows 98.

Так же имеется Ruby версия, которая работает везде, где есть интерпретатор данного языка. Я тестировала в версиях 2.0.0 и выше. Так же она требует гем unicode, установить который можно следующей командой:

> gem install unicode

Так же при запуске Ruby версии под Windows может потребоваться файл curl-ca-bundle.crt, содержащий в себе сертификаты доверенных корневых центров сертификации, необходимых для протокола HTTPS. Этот файл должен находится в одном каталоге со скриптом, и взять его можно вместе с программой cURL вот по этому адресу:

https://curl.haxx.se

В крайнем случае можно заблокировать проверку сертификатов вообще (не рекомендуется), раcкомментировав данную строку в скрипте:

> options[ :verify_mode ] = OpenSSL::SSL::VERIFY_NONE

Вот примеры использования скрипта:

> BingLoggerHTR.WSF
> BingLoggerWHT.WSF "J:\Pics\Logs\"
> bingloggerhtr.rb /home/vanilla/pics/logs/

Обратите внимание на сохранение картинки в текущий каталог в первом примере и на Linux путь в третьем примере. Так же я рекомендую указывать каталог точно во избежание несчастных случаев. 

Лучше всего запланировать запуск скрипта в любом планировщике (даже во встроенном). При этом для начала стоит проверить параметры, которые вы передаёте скрипту, а после того как всё пройдёт успешно, заблокировать вывод сообщений.

В случае VBScript версий необходимо передать WScript.EXE параметр //b, который будет блокировать появление любых сообщений. Выглядеть это будет так:

> WScript.EXE //b "H:\BingLoggerHTR.WSF" "J:\Pics\Logs\"

В случае Ruby версии необходимо перенаправить вывод на NUL или /dev/null. Например, так:

> bingloggerhtr.rb /home/vanilla/pics/logs/ > /dev/null

Внимание! Мне встретилась проблема, когда в Windows XP SP2 файрволл Outpost сильно снижал скорость скачивания картинки, а также портил её данные. Проявлялось это только при автоматическом запуске через планировщик Windows. В чём причина такого поведения, я не знаю, но в моём случае помогло обновление файрволла.

Маленький копирайт
------------------

1. Программа и исходный код распространяются бесплатно.
2. Вы имеете право распространять их на тех же условиях.
3. Вы не имеете права использовать имя автора после модификации исходного кода.
4. При этом желательно указывать ссылку на автора оригинальной версии исходного кода.
5. Вы не имеете права на платное распространение исходного кода, а также программных модулей, содержащих данный исходный код.
6. Программа и исходный код распространяются как есть. Автор не несёт ответственности за любые трагедии или несчастные случаи, вызванные использованием программы и исходного кода.
7. Для любого пункта данного соглашения может быть сделано исключение с разрешения автора программы.
8. По любым вопросам, связанным с данной программой, обращайтесь по адресу lindaoneesama@gmail.com

Контакты
--------

Почта: lindaoneesama@gmail.com
Сайт:  https://www.lindachan.net