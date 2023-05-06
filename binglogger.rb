#!/usr/local/bin/run_ruby_script_in_rvm

# Documentation:
# https://ruby-doc.org/stdlib-2.2.0/libdoc/net/http/rdoc/Net/HTTP.html

require "net/http"
require "uri"
require "openssl"
require "date"

require_relative "vb"
require_relative "rnd"

# Для show_copyright()...
APP_TITLE = "AJPapps - Bing logger Ruby ver."
APP_COPYRIGHT = "Линда Кайе 2017-2023. Посвящается Ариэль"

# Грязный хак!
BOM = "\xff\xfe".force_encoding("UTF-16LE")

# Коды возврата...
RC_OK = 0
RC_COMMAND_LINE = 1
RC_PICTURE_URL_OR_DESCRIPTION = 2
RC_NEW_PICTURE_URLS = 3
RC_JPG_FILE = 4
RC_PICTURE_FILE_OR_DESCRIPTION_FILE = 5

#====================================================================
def get_user_agent()
  # Для отладки. Для этого юзерагента Бинг выдаёт страницу без 
  # описания! Не знаю, почему...
  #return "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)"
  
  #return "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0"
  #return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/71.0.3578.100 Safari/537.36"
  return "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36"
end

#=====================================================================
def show_copyright()
  puts APP_TITLE
  puts APP_COPYRIGHT
  puts
end

#=====================================================================
def show_usage()
  puts "Использование: #{ File.split($PROGRAM_NAME)[-1] } PATH"
  puts
  puts "PATH - путь к каталогу, куда скрипт будет сохранять картинки."
  puts "       Если не указан, программа будет сохранять в текущий каталог."
end

#====================================================================
def get_path_from_arguments()
  if ARGV.length == 0 then
    return ""
  end
  
  if ARGV.length == 1 then
    if ARGV[0] == "/?" then
      show_usage
      return nil
    else
      return ARGV[0]
    end
  end
  
  show_usage
  return nil
end

#====================================================================
# Ёбаный стыд! Из-за того, что ошибки сокетов в Windows 
# на русском языке, а Руби до сих пор не знает, что где-то там 
# в Windows NT скрыто юникодное API, при попытке вывести 
# сообщение об ошибке возникает такая ошибка:
# 
# in `rescue in get_page_by_url':
# incompatible character encodings: UTF-8 and ASCII-8BIT 
# (Encoding::CompatibilityError)
# 
# У меня нет других вариантов, почему строка с ошибкой 
# получается хрен знает в какой кодировке и в консоль 
# попадает (если не отловить ошибку запроса) с крякозябрами.
#====================================================================
def get_error_message(e, default_error_text = "Unknown error")
  txt = "[#{ e.class.to_s }] #{ e.message }"
  if not Encoding.compatible?(Encoding::UTF_8, txt) then
    begin
      txt = "[#{ e.class.to_s }] #{ e.message.force_encoding("Windows-1251").encode("UTF-8") }"
    rescue
      txt = "[#{ e.class.to_s }] ***Invalid error message***"
      if not Encoding.compatible?(Encoding::UTF_8, txt) then
        txt = default_error_text
      end
    end
    if not Encoding.compatible?(Encoding::UTF_8, txt) then
      txt = "[#{ e.class.to_s }] ***Invalid error message***"
      if not Encoding.compatible?(Encoding::UTF_8, txt) then
        txt = default_error_text
      end
    end
  end
  
  return txt
end

#====================================================================
def get_page_by_url(target_url, ua, error_message, redirect_limit = 10)
  # Это для редиректов - они тут чего-то автоматом не делаются.
  # При каждом повторном вызове функции, параметр уменьшается 
  # на один. Если тут ноль, значит, хватит крутиться. Максимальное 
  # количество редиректов всегда на один меньше первоначального 
  # значения параметра. 
  if redirect_limit <= 0 then
    $stderr.puts error_message
    $stderr.puts "Слишком много редиректов."
    return nil
  end
  
  # С пустым адресом тоже никуда не идём.
  if target_url.empty? then
    $stderr.puts error_message
    $stderr.puts "URL почему-то был пуст."
    return nil
  end
  
  # Инициализируем объект, который потом будет использовать класс 
  # сетевого доступа. Короче, это такой CrackURL.
  uri = URI(target_url)
  
  # Создаём объект HTTP запроса. Отсюда можно настраивать 
  # параметры, но само соединение ещё не установлено - это ведь 
  # запрос (заголовки и формы)!
  req = Net::HTTP::Get.new(uri)
  
  # Устанавливаем всякие заголовки...
  req["User-Agent"] = ua
  
  # Хэш с параметрами. Можно указать при вызове функции, но я для 
  # удобства всё настрою заранее...
  # У меня без use_ssl вроде бы всё работало, но мы на всякий случай 
  # устанавливаем - так в примерах из интернетов...
  options = { :use_ssl => (uri.scheme == "https") }
  
  # Ищем файл с доверенными сертификатами. Руби не умеет в виндовое 
  # хранилище, так что будем так. А сам файл генерируется скриптом 
  # от cURL. Если файла нет, но не указываем ничего.
  if File.exist?("curl-ca-bundle.crt") then
    # Файл ищется в текущем каталоге...
    options[ :ca_file ] = "curl-ca-bundle.crt"
  end
  
  # Последняя надежда - игнорирование сертификата. Не очень полезно, 
  # но если ничего не помогает...
  #options[ :verify_mode ] = OpenSSL::SSL::VERIFY_NONE
  
  # А вот теперь устанавливаем соединение. Тут мы указываем куда 
  # конкретно подключаемся. nil - это настройка прокси, тоесть 
  # прокси мы вообще не используем. Если нет nil, тогда оно будет 
  # использовать переменную HTTP_PROXY. А если же нужно указать 
  # прокси ручками, то там два параметра - host и port.
  begin
    res = Net::HTTP.start(uri.host, uri.port,
                          nil, options) do |https|
      # А вот тут делается сам запрос при помощи объекта, который 
      # получается при старте соединения.
      https.request(req)
    end
  rescue Exception => e
    $stderr.puts error_message
    $stderr.puts "Ошибка: #{ get_error_message(e, "Неизвестная ошибка") }"
    return nil
  end
  
  # Если у нас редирект, повторяем запрос...
  if res.code == "301" or res.code == "302" then
    return get_page_by_url(res["location"], ua, error_message, redirect_limit - 1)
  end
  
  # Всё, что не 200, то - ошибка...
  if res.code == "200" then
    return res.body
  else
    $stderr.puts error_message
    $stderr.puts "Сервер вернул: #{res.code} #{res.message}"
    return nil
  end
end

#====================================================================
# Эта функция возвращает сразу два значения! Но nil можно вернуть 
# одним писом...
#====================================================================
def get_picture_url_and_description(ua)
  # Сначала получаем исходник главной Бинга...
  page_source = get_page_by_url("http://bing.com", ua,
                                "Не удалось получить главную страницу Bing.")
  if page_source.nil? then
    # В случае ошибки возвращаем две пустые строки...
    return "", ""
  end
  
  # Без этого потом будут ошибки! Текст на Бинге - в UTF-8, а не 
  # в том, что возвращает класс HTTP соединений...
  # Я не делаю этого в функции потому, что там могут и бинарные 
  # данные получаться.
  page_source = page_source.force_encoding("UTF-8")
  
  # Потом парсим полученные данные.
  picture_url = parse_html_ang_get_picture_url(page_source)
  description = parse_html_ang_get_description(page_source)
  
  # Debug!
  #puts "picture_url ==> #{ picture_url }"
  #puts "file_name   ==> #{ file_name   }"
  #puts "description ==> #{ description }"
  
  # Раньше возвращались nil, но теперь возвращаем всё, как есть. 
  # А смысл, если проверка всё равно вовне идёт и (по факту) по той 
  # же пустой строке...
  return picture_url, description
end

#====================================================================
def parse_html_ang_get_picture_url(page_source)
  # String.match принимает строку и правильно переделывает её 
  # в регэксп - нам даже на слэши смотреть не надо!
  #mc = page_source.match( "{url: \"(/az/hprichbg/rb/.*?)\"" )
  #mc = page_source.match( "{url: \"(/th\\?id=OHR\\.(.*?\\.jpg))" )
  #mc = page_source.match( "{url: \"(/th\\?id=OHR\\.(.*?)\\\\u0026.*?)\"}" )
  #mc = page_source.match( "{url:\\s*?\"(/th\\?id=OHR\\.(.*?)\\\\u0026.*?)\"}" )
  #mc = page_source.match( "{\"Url\":\"(/th\\?id=OHR\\.(.*?)\\\\u0026.*?)\"" )
  mc = page_source.match( "(/th\\?id=OHR\\.([\\w\\.]*?\\.jpg)\\\\u0026.*?)\"" )
  
  # Заранее делаем вид, что получилась пустая строка. Эта переменная 
  # получит значение только если регэксп сработал.
  txt = ""
  
  # Пытаемся взять первое подсовпадение. 0 - это весь кусок целиком, 
  # 1 - первая скобочка. Удобно!
  if not mc.nil? then
    if mc.length >= 2 then
      txt = mc[1]
    end
  end
  
  # Если ничего не нашлось, пора писать мне!
  if txt.empty? then
    dump_file_name = dump_source_html(page_source)
    
    $stderr.puts "Не удалось найти ссылку на картинку на главной странице Bing."
    $stderr.puts "Должно быть, опять что-то поменяли. Сообщите об этом автору."
    if not dump_file_name.nil? then
      $stderr.puts "Исходная страница сохранена в файл: #{ dump_file_name }"
    end
    
    return ""
  end
  
  # Заменяем заэкранированные слэши и амперсанды...
  txt = VB.replace(txt, "\\/", "/")
  txt = VB.replace(txt, "\\u0026", "&")
  
  # Адрес картинки может выглядеть по-разному, но мне встречались 
  # только два последних ^^'
  if VB.left(txt, 7).downcase == "http://" then
    return txt
  elsif VB.left(txt, 8).downcase == "https://" then
    return txt
  elsif VB.left(txt, 1) == "/" then
    return "http://www.bing.com#{ txt }"
  else
    return "http://www.bing.com/#{ txt }"
  end
end

#====================================================================
def parse_html_ang_get_description(page_source)
  # String.match принимает строку и правильно переделывает её 
  # в регэксп - нам даже на слэши смотреть не надо!
  #mc = page_source.match( "\"copyright\":\"(.*?)\"" )
  mc = page_source.match( "\"Title\":\"(.*?)\",\"Copyright\":\"(.*?)\"" )
  
  # Заранее делаем вид, что получилась пустая строка. Эта переменная 
  # получит значение только если регэксп сработал.
  txt = ""
  
  # Пытаемся взять первое подсовпадение. 0 - это весь кусок целиком, 
  # 1 - первая скобочка. Удобно!
  if not mc.nil? then
    if mc.length == 3 then
      # Теперь описание разделено на два поля в целях стилизации 
      # на странице. Поэтому мы собираем оба и делаем, как было 
      # раньше. Тоесть тут в будущем поменять, возможно, придётся 
      # не только регэксп, но и вот это...
      txt = "#{ mc[1] } (#{ mc[2] })"
    end
  end
  
  # Если ничего не нашлось, пора писать мне!
  if txt.empty? then
    dump_file_name = dump_source_html(page_source)
    
    $stderr.puts "Не удалось найти описание картинки на главной странице Bing."
    $stderr.puts "Должно быть, опять что-то поменяли. Сообщите об этом автору."
    if not dump_file_name.nil? then
      $stderr.puts "Исходная страница сохранена в файл: #{ dump_file_name }"
    end
    
    return ""
  end
  
  # Поубиваем знаки подстановки...
  # По идее в Руби это не должно работать, но мы ничего не теряем...
  for tmp in (0 .. 255) do
    txt = VB.replace(txt, "&\##{ tmp };", VB.chrw(tmp))
  end
  
  # Возвращаем...
  return txt
end

#====================================================================
def get_new_picture_urls(picture_url)
  # Регэксп можно задать специальной записью, а можно простой 
  # строкой через конструктор. Мне простая строка более по душе!
  pattern = Regexp.new("(_)(\\d+x\\d+)(\.)")
  
  # Берём полученный ранее URL картинки и из него делаем несколько 
  # с другими известными разрешениями. Сортируем по мере снижения 
  # желательности, а в конце - то, что мы ранее нашли. Дело вот 
  # в чём. Бинг по каким-то своим соображениям выбирает разрешение 
  # картинки. Если в броузере он вставит одно, то этот скрипт может 
  # получить другое. Поэтому мы угадываем разрешения и потом будем 
  # пытаться получить с лучшего к худшему - что найдётся.
  arr = [ picture_url.sub(pattern, "\\11920x1200\\3"),
          picture_url.sub(pattern, "\\11920x1080\\3"),
          picture_url.sub(pattern, "\\11366x768\\3"),
          picture_url.sub(pattern, "\\11024x768\\3"),
          picture_url ]
  
  # Возвращаем массив.
  return arr
end

#====================================================================
def get_jpg_data(picture_url, ua)
  # Сначала получаем данные картинки с Бинга...
  jpg_data = get_page_by_url(picture_url, ua,
                             "Не удалось получить картинку с Bing.")
  
  # И... И всё ^^
  return jpg_data
end

#====================================================================
def get_file_name_from_search_url(url)
  # Ищем вот это:
  # /th?id=OHR.GrapeHarvest_ROW5367417225_1920x1080.jpg
  mc = url.match( "^th\\?id=OHR\\.(.*?\\.jpg)" )
  
  # Заранее делаем вид, что получилась пустая строка. Эта переменная 
  # получит значение только если регэксп сработал.
  txt = ""
  
  # Пытаемся взять первое подсовпадение. 0 - это весь кусок целиком, 
  # 1 - первая скобочка. Удобно!
  if not mc.nil? then
    if mc.length >= 2 then
      txt = mc[1]
    end
  end
  
  # Debug!
  #puts "url ==> #{ url }"
  #puts "txt ==> #{ txt }"
  
  # Если ничего не нашлось, возвращаем как есть!
  if txt.empty? then
    return url
  else
    return txt
  end
end

#====================================================================
def get_jpg_file_name(save_path, picture_url)
  # Новая система средствами Руби! Сначала разбиваем URL на путь 
  # и имя файла! Это работает OO
  arr = File.split(picture_url)
  picture_url = arr[-1]
  
  # На всякий случай!
  if picture_url.empty? then
    picture_url = "picture.jpg"
  end
  
  # Фиксим новый формат URL с вопросительным знаком...
  picture_url = get_file_name_from_search_url(picture_url)
  
  # Теперь объединяем с каталогом, если каталог, конечно, есть. 
  # Если нет, то будет что-то вроде "/file.jpg"...
  if not save_path.empty? then
    return File.join(save_path, picture_url)
  else
    return picture_url
  end
end

#====================================================================
def get_txt_file_name(save_path, picture_url)
  # Не будем изобретать велосипед, а возьмём имя JPG файла и просто 
  # поменяем ему расширение...
  txt = get_jpg_file_name(save_path, picture_url)
  
  # Получаем расширение. Эта функция учитывает приколы вроде имён, 
  # начинающихся с точки и точки в каталогах (а не в самом файле)... 
  # Если расширения нет - дописываем. Если есть - вырезаем моими 
  # функциями и тоже дописываем.
  ext = File.extname(txt)
  if ext.empty? then
    return "#{ txt }.txt"
  else
    return "#{ VB.cutright(txt, VB.len(ext)) }.txt"
  end
end

#====================================================================
def dump_source_html(page_source)
  temp_path = "#{ ENV["tmp"] }"
  if temp_path.empty? then
    temp_path = "#{ ENV["tmp"] }"
  end
  if temp_path.empty? then
    temp_path = "/tmp"
  end
  
  # Имя временного файла в стиле VBScript...
  file_name = "rad#{ Rnd.get_hex(5) }.tmp.html"
  file_name = File.join(temp_path, file_name)
  
  # Debug!
  #puts file_name
  
  # Пытаемся сохранить файл.
  # Внимание! Сообщение об ошибке выдаётся внутри этой функции =_=
  if not save_binary_file(file_name, page_source) then
    file_name = nil
  end
  
  return file_name
end

#====================================================================
def save_jpg_and_description_file(save_path, jpg_data, picture_url, description)
  # Получаем имена нужных файлов...
  file_name_jpg = get_jpg_file_name(save_path, picture_url)
  file_name_txt = get_txt_file_name(save_path, picture_url)
  
  # Debug...
  #puts "file_name_jpg ==> #{ file_name_jpg }"
  #puts "file_name_txt ==> #{ file_name_txt }"
  
  # Пытаемся сохранить JPG файл как полностью двоичный...
  # Если не получится, всё равно идём дальше.
  # Кстати, при неуспехе имена файлов обнуляются чтобы снаружи код 
  # знал, что именно не сохранилось, и не сообщал о сохранении этх 
  # файлов. А то сначала сообщение об ошибке, а потом - "Картинка 
  # сохранена в файл"...
  # Внимание! Сообщение об ошибке выдаётся внутри этой функции =_=
  if not save_binary_file(file_name_jpg, jpg_data) then
    file_name_jpg = nil
  end
  
  # Формируем текст описания. Из вредности ставим CRLF и собственный 
  # формат даты (оригинальный VBS скрипт ставит системный, но в Руби 
  # этого что-то не наблюдается) - всё равно сохранять будем 
  # в православный UTF-16LE!
  txt = "Description: #{ description }\r\n" +
        "Picture URL: #{ picture_url }\r\n" +
        "Save time:   #{ Time.now.strftime("%-d.%m.%Y %-I:%M:%S %p %:z") }"
  
  # Пытаемся сохранить описание...
  # Внимание! Сообщение об ошибке выдаётся внутри этой функции =_=
  if not save_unicode_text_file(file_name_txt, txt) then
    file_name_txt = nil
  end
  
  # Возвращаем имена файлов для сообщений и прочего...
  return file_name_jpg, file_name_txt
end

#====================================================================
def save_binary_file(file_name, data)
  # Предполагаем хорошее...
  rc = true
  
  begin
    # Открываем файл для перезаписи. Файл будет двоичным.
    # 
    # "b"  Binary file mode
    # Suppresses EOL <-> CRLF conversion on Windows. And sets 
    # external encoding to ASCII-8BIT unless explicitly specified.
    File.open(file_name, 'wb') { |file|
      # Пишем без CRLF в конце...
      file.write(data)
    }
  rescue Exception => e
    $stderr.puts "Не удалось сохранить файл: #{ file_name }"
    $stderr.puts "Ошибка: #{ get_error_message(e, "Неизвестная ошибка") }"
    
    # Нет, всё плохо...
    rc = false
  end
  
  # Возвращаем результат операции...
  return rc
end

#====================================================================
def save_unicode_text_file(file_name, data)
  # Предполагаем хорошее...
  rc = true
  
  begin
    # Открываем файл для перезаписи. Файл будет в UTF-16LE.
    # Двоичный - чтобы не перекрывало CRLF!
    File.open(file_name, 'wb:UTF-16LE') { |file|
      # Пишем BOM, следом данные, и всё это без CRLF в конце...
      # Не знаю, как сказать Руби, чтобы он сам писал BOM. Если 
      # указать опцию "BOM" в параметрах открытия файла, то будет 
      # ошибка "Файл ещё не открыт". Судя по докам, такая опция 
      # говорит не записывать BOM, а искать, есть ли она в файле =_=
      file.write(BOM)
      file.write(data)
    }
  rescue Exception => e
    $stderr.puts "Не удалось сохранить файл: #{ file_name }"
    $stderr.puts "Ошибка: #{ get_error_message(e, "Неизвестная ошибка") }"
    
    # Нет, всё плохо...
    rc = false
  end
  
  # Возвращаем результат операции...
  return rc
end

#====================================================================
def main()
  # Обязательно ^^v
  show_copyright
  
  # Кэшируем юзерагент, чтобы он не менялся по ходу запросов...
  ua = get_user_agent()
  
  # Получаем каталог, куда нужно сохранять картинку, из командной 
  # строки. Если возвращается nil, юзер указал неверное количество 
  # параметров, либо указал "/?".
  save_path = get_path_from_arguments()
  if save_path.nil? then
    return RC_COMMAND_LINE
  end
  
  # Сообщаем, куда будем сохранять...
  if save_path.empty? then
    puts "Каталог назначения: *текущий*"
  else
    puts "Каталог назначения: #{ save_path }"
  end
  
  # Получаем URL картинки и описание. В VB вторая переменная шла 
  # ByRef параметром, но у нас же Руби!
  picture_url, description = get_picture_url_and_description(ua)
  if picture_url.empty? then
    # Если URL картинки не найден, то и возвращать нечего. Раньше 
    # проверялось и описание, но глупо не сохранить ничего!
    return RC_PICTURE_URL_OR_DESCRIPTION
  end
  
  # Сообщаем первичный URL картинки. На базе его будем строить 
  # другие...
  puts "Обнаружена картинка: #{ picture_url }"
  
  # Получаем эти самые другие...
  new_picture_urls = get_new_picture_urls(picture_url)
  if new_picture_urls.nil? then
    return RC_NEW_PICTURE_URLS
  end
  
  # Пытаемся скачать хоть какую-нибудь картинку...
  jpg_data = nil
  new_picture_urls.each do |new_picture_url|
    jpg_data = get_jpg_data(new_picture_url, ua)
    if not jpg_data.nil? then
      picture_url = new_picture_url
      break
    end
  end
  
  # Если так ничего и не удалось скачать, то выходим отсюда. Больше 
  # тут делать нечего...
  if jpg_data.nil? then
    exit RC_JPG_FILE
  end
  
  # А если удалось, то сообщаем, какой именно URL...
  puts "Получена картинка: #{ picture_url }"
  
  # Теперь пытаемся сохранить картинку и описание. Функция 
  # возвращает имена сохранённых файлов. Если какой-то файл 
  # не удалось сохранить, то вместо имени файла возвращается 
  # nil...
  file_name_jpg, file_name_txt = save_jpg_and_description_file(save_path, jpg_data, picture_url, description)
  
  # Если удалось сохранить картинку - сообщаем!
  if not file_name_jpg.nil? then
    puts "Картинка сохранена в файл: #{ file_name_jpg }"
  end
  
  # Если удалось сохранить описание - сообщаем!
  if not file_name_txt.nil? then
    puts "Описание сохранено в файл: #{ file_name_txt }"
  end
  
  # Если не удалось сохранить хоть что-то возвращаем код ошибки.
  if file_name_jpg.nil? or file_name_txt.nil? then
    return RC_PICTURE_FILE_OR_DESCRIPTION_FILE
  else
    return RC_OK
  end
end

#====================================================================
# Прикольный хак ^_^v
exit main()
