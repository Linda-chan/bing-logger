#!/usr/bin/ruby

#====================================================================
# AJPapps - VB string functions
# 
# Линда Кайе 2024. Посвящается Ариэль
#====================================================================
# 
# Этот скрипт содержит Ruby модуль со строковыми функциями в стиле 
# Visual Basic 6. Я написала его в основном в учебных целях, а также 
# потому, что все эти text[12, -5] сразу не легли на извилины.
# 
# Мне не удалось точно воспроизвести все функции, но я постаралась 
# обеспечить максимальное соответствие. Где не удалось совладать 
# с различиями в реализации опциональных параметров, я сделала 
# несколько вариантов функций. Например, instr2() принимает параметр 
# start, а instr() - нет.
# 
# Параметр Compare из перечисления превратился в булевый параметр 
# textcompare.
# 
# Кроме функций VB6, я добавила пару функций из своей библиотеки 
# AJPappsSupport.DLL - аналоги asTrimEx() сотоварищи. В конце концов 
# стандартной функцией Trim() пользоваться невозможно в принципе ^^'
# 
# Модуль используется как-то так:
# 
# > require_relative "vb"
# > 
# > txt = VB.left(txt, 12)
# > arr = VB.split(txt, "\n")
# 
# Разумеется, файл vb.rb нужно поместить в каталог с основной 
# программой.
# 
# Модуль тестировался в Ruby 2.0.0 и выше. Так же он требует гем 
# unicode, установить который можно следующей командой:
# 
# > gem install unicode
# 
# История изменений
# -----------------
# 
# • 24.02.2017
#   Первая публичная версия ^^
# 
# • 13.12.2017
#   [-] Функции split() и split2() работали в отрыве VB реалий. 
#       Исправлена куча моментов, когда параметры интерпретировались 
#       не так, как в VB.
# 
# • 14.12.2017
#   [-] Ещё одна ошибка в split() и split2(). Там лимит выставлялся 
#       в девять, и парсилась только часть строки.
# 
# • 28.10.2024
#   [+] Поправлен шебанг.
# 
#====================================================================
# Маленький копирайт
# 
# 1. Программа и исходный код распространяются бесплатно.
# 2. Вы имеете право распространять их на тех же условиях.
# 3. Вы не имеете права использовать имя автора после модификации 
#    исходного кода.
# 4. При этом желательно указывать ссылку на автора оригинальной 
#    версии исходного кода.
# 5. Вы не имеете права на платное распространение исходного кода, 
#    а также программных модулей, содержащих данный исходный код.
# 6. Программа и исходный код распространяются как есть. Автор не 
#    несёт ответственности за любые трагедии или несчастные случаи, 
#    вызванные использованием программы и исходного кода.
# 7. Для любого пункта данного соглашения может быть сделано 
#    исключение с разрешения автора программы.
# 8. По любым вопросам, связанным с данной программой, обращайтесь 
#    по адресу lindaoneesama@gmail.com
# 
# Загружено с http://purl.oclc.org/Linda_Kaioh/Homepage/
#====================================================================

require "unicode"

##===================================================================
# Строковые функции в стиле Visual Basic 6
##===================================================================
module VB
  
  #------------------------------------------------------------------
  # Function Left(String, Length As Long)
  #------------------------------------------------------------------
  def VB.left(text, length)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    if length <= 0 then
      return ""
    else
      if length > text.length then
        return text
      else
        return text[0, length]
      end
    end
  end
  
  #------------------------------------------------------------------
  # Function Right(String, Length As Long)
  #------------------------------------------------------------------
  def VB.right(text, length)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    if length <= 0 then
      return ""
    else
      if length > text.length then
        return text
      else
        return text[-length, length]
      end
    end
  end
  
  #------------------------------------------------------------------
  # Function Mid(String, Start As Long, [Length])
  #------------------------------------------------------------------
  def VB.mid(text, start, length = -1)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    # Если старт меньше первого символа или за пределами строки, 
    # возвращаем пустую строку. VB при значениях меньше одного 
    # ошибку возвращает, но будем милосердны...
    if start < 1 or start > text.length then
      return ""
    end
    
    # Длина возвращаемого куска строки. Если меньше одного, 
    # то смотрим, что там. Если -1, то это специальное значение 
    # (по умолчанию), обозначающее, что нужно вернуть строку 
    # до конца - обновляем значение длины на гарантированно 
    # покрывающее длину строки. Если любое другое значение, 
    # то возвращаем пустую строку...
    if length < 1 then
      if length == -1 then
        length = text.length + 10
      else
        return ""
      end
    end
    
    # В VB считается с одного, в Руби - с нуля...
    # Строку копировать не нужно - этот опервтор скастует новую...
    return text[start - 1, length]
  end
  
  #------------------------------------------------------------------
  # Не знаю, какое название придумать =_=
  #------------------------------------------------------------------
  def VB.smid(text, newtext, start, length = -1)
    # Если текст нам не передан, то и возвращать нечего.
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    # Если старт меньше первого символа или за пределами строки, 
    # возвращаем оригинальную строку - преобразований не произошло. 
    # VB при значениях меньше одного ошибку возвращает, но будем 
    # милосердны.
    if start < 1 or start > text.length then
      return text
    end
    
    # Если заменять не на что, то возвращаем исходную строку...
    if newtext.empty? then
      return text
    end
    
    # Заменяемый фрагмент имеет фактическую длину, а ещё можно 
    # указать желаемую, сколько от переданного фрагмента нужно 
    # на самом деле использовать. Если желаемая длина заменяемого 
    # фразмента меньше или равна нулю, то смотрим, что там 
    # за значение. -1 - значит передано значение по умолчанию, 
    # и следует в качестве желаемой длины использовать фактическую. 
    # Любое другое значение - на выход с оригинальной строкой, 
    # преобразование не случилось.
    if length <= 0 then
      if length == -1 then
        length = newtext.length
      else
        return text
      end
    end
    
    # Если желаемая длина больше фактической, то присваиваем 
    # ей фактическую.
    if length > newtext.length then
      length = newtext.length
    end
    
    # Если кусок текста до конца исходной строки короче желаемой 
    # длины, то желаемой длине присваиваем это значение.
    if (text.length - start + 1) < length then
      length = text.length - start + 1
    end
    
    # А теперь укорачиваем новое значение в соответствие 
    # с полученной желаемой длиной, если фактическая длина больше 
    # желаемой. А то Руби его полностью загонит.
    if newtext.length > length then
      newtext = newtext[0, length]
    end
    
    # В VB считается с одного, в Руби - с нуля...
    # Строку копировать не нужно - этот опервтор скастует новую...
    # Короче заменяем фрагмент строки новой строкой. Руби так умеет 
    # тоже.
    text[start - 1, length] = newtext
    
    # Возвращаем текст.
    return text
  end
  
  #------------------------------------------------------------------
  # Function LCase(String)
  #------------------------------------------------------------------
  def VB.lcase(text)
    return Unicode::downcase(text)
  end
  
  #------------------------------------------------------------------
  # Function UCase(String)
  #------------------------------------------------------------------
  def VB.ucase(text)
    return Unicode::upcase(text)
  end
  
  #------------------------------------------------------------------
  # Function PCase(String)
  #------------------------------------------------------------------
  def VB.pcase(text)
    return Unicode::capitalize(text)
  end
  
  #------------------------------------------------------------------
  # Function Len(Expression)
  #------------------------------------------------------------------
  def VB.len(text)
    return text.length
  end
  
  #------------------------------------------------------------------
  # Function StrReverse(Expression As String) As String
  #------------------------------------------------------------------
  def VB.strreverse(txt)
    return txt.reverse
  end
  
  #------------------------------------------------------------------
  # Function asCutLeft(Text As String, CutLen As Long) As String
  #------------------------------------------------------------------
  def VB.cutleft(text, cutlen)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    if cutlen < 0 then
      return ""
    else
      if cutlen > text.length then
        return ""
      else
        return text[cutlen, text.length]
      end
    end
  end
  
  #------------------------------------------------------------------
  # Function asCutRight(Text As String, CutLen As Long) As String
  #------------------------------------------------------------------
  def VB.cutright(text, cutlen)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    if cutlen < 0 then
      return ""
    else
      if cutlen > text.length then
        return ""
      else
        return text[0, text.length - cutlen]
      end
    end
  end
  
  #------------------------------------------------------------------
  # Function StrComp(String1, String2, [Compare As VbCompareMethod = vbBinaryCompare])
  #------------------------------------------------------------------
  def VB.strcomp(string1, string2, textcompare = false)
    if textcompare then
      rc = Unicode::strcmp(Unicode::downcase(string1), 
                           Unicode::downcase(string2))
    else
      rc = Unicode::strcmp(string1, string2)
    end
    
    if rc < 0 then rc = -1 end
    if rc > 0 then rc = 1 end
    
    return rc
  end
  
  #------------------------------------------------------------------
  # Function Space(Number As Long)
  #------------------------------------------------------------------
  def VB.space(number)
    if number <= 0 then
      return ""
    else
      return " " * number
    end
  end
  
  #------------------------------------------------------------------
  # Function String(Number As Long, Character)
  #------------------------------------------------------------------
  def VB.string(number, character)
    if number <= 0 or character.empty? then
      return ""
    else
      return character[0] * number
    end
  end
  
  #------------------------------------------------------------------
  # Function InStr([Start], [String1], [String2], [Compare As VbCompareMethod = vbBinaryCompare])
  #------------------------------------------------------------------
  def VB.instr2(start, string1, string2, textcompare = false)
    # Не заморачиваемся...
    if string1.empty? or string2.empty? or start <= 0 or start > string1.length then
      return 0
    end
    
    # В VB считается с одного, в Руби - с нуля...
    if textcompare then
      rc = Unicode::downcase(string1).index(Unicode::downcase(string2), start - 1)
    else
      rc = string1.index(string2, start - 1)
    end
    
    if rc.nil? then
      return 0
    else
      return rc + 1
    end
  end
  
  def VB.instr(string1, string2, textcompare = false)
    return instr2(1, string1, string2, textcompare)
  end
  
  #------------------------------------------------------------------
  # Function InStrRev(StringCheck As String, StringMatch As String, [Start As Long = -1], [Compare As VbCompareMethod = vbBinaryCompare]) As Long
  #------------------------------------------------------------------
  def VB.instrrev2(string1, string2, start, textcompare = false)
    # Не заморачиваемся...
    if string1.empty? or string2.empty? or start <= 0 or start > string1.length then
      return 0
    end
    
    # В VB считается с одного, в Руби - с нуля...
    if textcompare then
      rc = Unicode::downcase(string1).rindex(Unicode::downcase(string2), start - 1)
    else
      rc = string1.rindex(string2, start - 1)
    end
    
    if rc.nil? then
      return 0
    else
      return rc + 1
    end
  end
  
  def VB.instrrev(string1, string2, textcompare = false)
    return instrrev2(string1, string2, string1.length, textcompare)
  end
  
  #------------------------------------------------------------------
  # Function Split(Expression As String, [Delimiter], [Limit As Long = -1], [Compare As VbCompareMethod = vbBinaryCompare])
  # 
  # From VBA
  # --------
  # 
  # Returns a zero-based, one-dimensional array containing 
  # a specified number of substrings.
  # 
  # expression - Required. String expression containing substrings 
  #              and delimiters. If expression is a zero-length 
  #              string(""), Split returns an empty array, that is, 
  #              an array with no elements and no data.
  # 
  # delimiter  - Optional. String character used to identify 
  #              substring limits. If omitted, the space character 
  #              (" ") is assumed to be the delimiter. If delimiter 
  #              is a zero-length string, a single-element array 
  #              containing the entire expression string is returned.
  # 
  # limit      - Optional. Number of substrings to be returned; 
  #              –1 indicates that all substrings are returned.
  # 
  # compare    - Optional. Numeric value indicating the kind of 
  #              comparison to use when evaluating substrings. 
  #              See Settings section for values. 
  #------------------------------------------------------------------
  def VB.split2(text, delimiter, limit, textcompare = false)
    # Если лимит меньше минус одного, то возвращаем пустой массив.
    # VB возвращает ошибку...
    if limit < -1 then
      return []
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    # Если разделитель пуст, то возвращаем всю строку элементом 
    # массива. На самом деле не важно, строка у нас пустая или нет: 
    # если она пустая, то возвращается пустой элемент в массиве, 
    # тоесть та же строка...
    if delimiter.empty? then
      return [text]
    end
    
    # Если у нас строка пустая, возвращаем пустой массив...
    if text.empty? then
      return []
    end
    
    # Если лимит - минус один, то указываем его как размер строки 
    # плюс несколько символов, чтобы оно заведомо было больше...
    if limit == -1 then
      # +10 - это чтобы не попало на следующие условия.
      # -1 + 10 = 9 же!
      limit = text.length + 10
    end
    
    # Если лимит - ноль и разделитель не пустой, возвращаем пустой 
    # массив... Случаи, когда разделитель пуст, обрабатываются 
    # в условии выше...
    if limit == 0 and not delimiter.empty? then
      return []
    end
    
    # Если лимит - один, а текст не пуст, то возвращаем один элемент 
    # со всей строкой...
    if limit == 1 and not text.empty? then
      return [text]
    end
    
    # Пипец разветвлённая логика!
    # =_=
    
    # Создаём пустой массив, который будем заполнять...
    arr = []
    
    # Если у нас текстовое сравнение, то даункейсим разделитель 
    # и создаём копию строки в отдельной переменной. В копии будем 
    # искать, а копировать текст будем из оригинальной строки.
    # Если же у нас не текстовое сравнение, то просто копируем 
    # оригинальную строку в вновую переменную. Так как строка 
    # преобразовываться не будет, просто приравниваем...
    if textcompare then
      txt = Unicode::downcase(text)
      delimiter = Unicode::downcase(delimiter)
    else
      txt = text
    end
    
    # Поехали крутиться. Начинаем с нулевой итерации.
    # Стартовый символ - тоже ноль, как первый индекс строки.
    # Ну и ищем разделитель в копии строки.
    iterations = 0
    block_start = 0
    rc = txt.index(delimiter, block_start)
    
    # Крутимся, пока поиск не вернёт nil, что значит, что ничего 
    # не найдено...
    while not rc.nil? do
      # Если стартовый индекс совпадает с найденным индексом, 
      # то просто считаем, что нашлась пустая строка. Значит, 
      # разделители шли друг за другом. Такое упрощение нужно для 
      # специального случая, когда строка начинается с разделителя. 
      # Тогда извлечение текста интервалом выдаст нам всю строку 
      # целиком (0 - 1 = -1).
      if rc == block_start then
        txt2 = ""
      else
        # На всякий случай проверяем, не вернулся ли нам nil...
        txt2 = text[block_start .. (rc - 1)]
        if txt2.nil? then txt2 = "" end
      end
      # Добавляем в массив...
      arr << txt2
      
      # Пропускаем разделитель и переходим к следующему за ним 
      # символу. Количество итераций тоже увеличиваем.
      block_start = rc + delimiter.length
      iterations += 1
      
      # Если количество итераций добралось до лимита минус один, 
      # то делаем вид, что ничего не нашлось. Следующей итерации 
      # не будет, а код вернёт строку до конца следующим элементом - 
      # это и будет итерация, которую мы вычли. Если же лимит 
      # не превышен, ищем следующее вхождение разделителя, начиная 
      # с символа после текущего разделителя.
      if iterations >= (limit - 1) then
        rc = nil
      else
        rc = txt.index(delimiter, block_start)
      end
    end
    
    # Возвращаем строку до конца. На всякий пожарный проверяем nil!
    txt2 = text[block_start .. (text.length - 1)]
    if txt2.nil? then txt2 = "" end
    arr << txt2
    
    # Вернули массив!
    return arr
  end
  
  def VB.split(text, delimiter, textcompare = false)
    return split2(text, delimiter, -1, textcompare)
  end
  
  #------------------------------------------------------------------
  # Function LTrim(String)
  #------------------------------------------------------------------
  def VB.ltrim(text)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    for tmp in (0 .. (text.length - 1)) do
      if text[tmp] != " " then
        return text[tmp .. (text.length - 1)]
      end
    end
    
    # Если не нашли ни одного несрезаемого символа, то возвращаем 
    # пустую строку! У нас исходная строка состоит из одних пробелов 
    # и прочего, что нужно срезать!
    return ""
  end
  
  #------------------------------------------------------------------
  # Function RTrim(String)
  #------------------------------------------------------------------
  def VB.rtrim(text)
    # Не заморачиваемся...
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    for tmp in (0 .. (text.length - 1)) do
      tmp2 = (text.length - 1) - tmp
      if text[tmp2] != " " then
        return text[0 .. tmp2]
      end
    end
    
    # Если не нашли ни одного несрезаемого символа, то возвращаем 
    # пустую строку! У нас исходная строка состоит из одних пробелов 
    # и прочего, что нужно срезать!
    return ""
  end
  
  #------------------------------------------------------------------
  # Function Trim(String)
  #------------------------------------------------------------------
  def VB.trim(text)
    txt = rtrim(text)
    txt = ltrim(txt)
    return txt
  end
  
  #------------------------------------------------------------------
  # Function Join(SourceArray, [Delimiter]) As String
  #------------------------------------------------------------------
  def VB.join(sourcearray, delimiter = " ")
    return sourcearray.join(delimiter)
  end
  
  #------------------------------------------------------------------
  # Function Replace(Expression As String, Find As String, Replace As String, [Start As Long = 1], [Count As Long = -1], [Compare As VbCompareMethod = vbBinaryCompare]) As String
  # 
  # Между прочим, start - это не только откуда начать поиск. 
  # Возвращаемая строка начинается именно с этого символа. Тоесть 
  # если у нас была строка "Ariel", и start был 3, то на выходе 
  # будет что-то вроде "iel". Я НЕ ЗНАЛА ОБ ЭТОМ ДО СИХ ПОР!
  #------------------------------------------------------------------
  def VB.replace3(text, find, replacewith, start, count, textcompare = false)
    # Нет смысла что-либо возвращать, пока исходная строка пуста...
    if text.empty? then
      return ""
    end
    
    # Если искать нечего, то просто возвращаем исходную строку...
    if find.empty? then
      return text
    end
    
    # Если найти нужно ноль раз, то искать нечего - возвращаем 
    # пустую строку!
    if count <= 0 then
      return text
    end
    
    # В оригинале возвращается ошибка, но будем милосердны...
    if start < 1 then 
      start = 1
    end
    
    # Если индекс первого символа за пределами строки, то возвращаем 
    # пустую строку. См. комментарий к функции.
    if start > text.length then
      return ""
    end
    
    # Обрезаем строку, руководствуясь значением start - 
    # см. комментарий к функции. Даже если start указывает на первый 
    # символ, всё равно обрезаем, чтобы создать копию строки 
    # и не работать со ссылкой!
    text = text[(start - 1) .. (text.length - 1)]
    
    # Разбиваем строку на составляющие, исползуя строку поиска 
    # в качестве разделителя. Потом склеим - так будет проще, чем 
    # через instr(). Кстати, count здесь увеличивается на один, 
    # поскольку в этой функции count - это сколько нужно сделать 
    # замен, а в split() - сколько элементов массива нужно получить. 
    # Поэтому, если в строке одно совпадение, то оно разбивает 
    # строку на две части. Если пять, то - шесть. Короче, +1.
    arr = split2(text, find, (count + 1), textcompare)
    
    # Используем собственную функцию и возвращаем строку!
    return join(arr, replacewith)
  end
  
  def VB.replace2(text, find, replacewith, start, textcompare = false)
    # Лимит указываем как заведомо больший, чем количество символов!
    return replace3(text, find, replacewith, start, text.length + 10, textcompare)
  end
  
  def VB.replace(text, find, replacewith, textcompare = false)
    # Лимит указываем как заведомо больший, чем количество символов!
    # Начинаем с первого VB символа!
    return replace3(text, find, replacewith, 1, text.length + 10, textcompare)
  end
  
  #------------------------------------------------------------------
  def VB.is_non_trimming_char(char, trimspaces = true, trimtabs = true, 
                              trimcrs = false, trimlfs = false, trimquotes = false)
    # Нам нужен только один символ!
    char = char[0]
    
    if trimspaces and char == " " then
      return false
    end
    
    if trimtabs and char == "\t" then
      return false
    end
    
    if trimcrs and char == "\r" then
      return false
    end
    
    if trimlfs and char == "\n" then
      return false
    end
    
    if trimquotes and char == "\"" then
      return false
    end
    
    return true
  end
  
  #------------------------------------------------------------------
  # Function asLTrimEx2(Text As String, [TrimSpaces As Boolean = True], [TrimTabs As Boolean = True], [TrimCRs As Boolean = False], [TrimLFs As Boolean = False], [TrimQuotes As Boolean = False], [Reserved1 As Boolean = False], [Reserved2 As Boolean = False], [Reserved3 As Boolean = False], [Reserved4 As Boolean = False], [Reserved5 As Boolean = False]) As String
  #------------------------------------------------------------------
  def VB.ltrimex2(text, trimspaces = true, trimtabs = true, 
                  trimcrs = false, trimlfs = false, trimquotes = false)
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    for tmp in (0 .. (text.length - 1)) do
      if is_non_trimming_char(text[tmp], trimspaces, trimtabs, trimcrs, trimlfs, trimquotes) then
        #puts "VB.ltrimex2() ==> tmp: #{tmp}, text.length: #{text.length}"
        return text[tmp .. (text.length - 1)]
      end
    end
    
    # Если не нашли ни одного несрезаемого символа, то возвращаем 
    # пустую строку! У нас исходная строка состоит из одних пробелов 
    # и прочего, что нужно срезать!
    return ""
  end
  
  #------------------------------------------------------------------
  # Function asRTrimEx2(Text As String, [TrimSpaces As Boolean = True], [TrimTabs As Boolean = True], [TrimCRs As Boolean = False], [TrimLFs As Boolean = False], [TrimQuotes As Boolean = False], [Reserved1 As Boolean = False], [Reserved2 As Boolean = False], [Reserved3 As Boolean = False], [Reserved4 As Boolean = False], [Reserved5 As Boolean = False]) As String
  #------------------------------------------------------------------
  def VB.rtrimex2(text, trimspaces = true, trimtabs = true, 
                  trimcrs = false, trimlfs = false, trimquotes = false)
    if text.empty? then
      return ""
    end
    
    # Копируем строку, чтобы не работать со ссылкой...
    text = String.new(text)
    
    for tmp in (0 .. (text.length - 1)) do
      tmp2 = (text.length - 1) - tmp
      if is_non_trimming_char(text[tmp2], trimspaces, trimtabs, trimcrs, trimlfs, trimquotes) then
        #puts "VB.rtrimex2() ==> tmp: #{tmp}, text.length: #{text.length}"
        return text[0 .. tmp2]
      end
    end
    
    # Если не нашли ни одного несрезаемого символа, то возвращаем 
    # пустую строку! У нас исходная строка состоит из одних пробелов 
    # и прочего, что нужно срезать!
    return ""
  end
  
  #------------------------------------------------------------------
  # Function asTrimEx2(Text As String, [TrimSpaces As Boolean = True], [TrimTabs As Boolean = True], [TrimCRs As Boolean = False], [TrimLFs As Boolean = False], [TrimQuotes As Boolean = False], [Reserved1 As Boolean = False], [Reserved2 As Boolean = False], [Reserved3 As Boolean = False], [Reserved4 As Boolean = False], [Reserved5 As Boolean = False]) As String
  #------------------------------------------------------------------
  def VB.trimex2(text, trimspaces = true, trimtabs = true, 
                 trimcrs = false, trimlfs = false, trimquotes = false)
    txt = rtrimex2(text, trimspaces, trimtabs, trimcrs, trimlfs, trimquotes)
    txt = ltrimex2(txt, trimspaces, trimtabs, trimcrs, trimlfs, trimquotes)
    return txt
  end
  
  #------------------------------------------------------------------
  # Function asLTrimEx(Text As String) As String
  #------------------------------------------------------------------
  def VB.ltrimex(text)
    return ltrimex2(text, true, true, false, false, false)
  end
  
  #------------------------------------------------------------------
  # Function asRTrimEx(Text As String) As String
  #------------------------------------------------------------------
  def VB.rtrimex(text)
    return rtrimex2(text, true, true, false, false, false)
  end
  
  #------------------------------------------------------------------
  # Function asTrimEx(Text As String) As String
  #------------------------------------------------------------------
  def VB.trimex(text)
    return trimex2(text, true, true, false, false, false)
  end
  
  #------------------------------------------------------------------
  # Function asLTrimCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.ltrimcrlf(text)
    return ltrimex2(text, false, false, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asRTrimCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.rtrimcrlf(text)
    return rtrimex2(text, false, false, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asTrimCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.trimcrlf(text)
    return trimex2(text, false, false, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asLTrimExCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.ltrimexcrlf(text)
    return ltrimex2(text, true, true, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asRTrimExCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.rtrimexcrlf(text)
    return rtrimex2(text, true, true, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asTrimExCRLF(Text As String) As String
  #------------------------------------------------------------------
  def VB.trimexcrlf(text)
    return trimex2(text, true, true, true, true, false)
  end
  
  #------------------------------------------------------------------
  # Function asLTrimQuotes(Text As String) As String
  #------------------------------------------------------------------
  def VB.ltrimquotes(text)
    return ltrimex2(text, false, false, false, false, true)
  end
  
  #------------------------------------------------------------------
  # Function asRTrimQuotes(Text As String) As String
  #------------------------------------------------------------------
  def VB.rtrimquotes(text)
    return rtrimex2(text, false, false, false, false, true)
  end
  
  #------------------------------------------------------------------
  # Function asTrimQuotes(Text As String) As String
  #------------------------------------------------------------------
  def VB.trimquotes(text)
    return trimex2(text, false, false, false, false, true)
  end
  
  #------------------------------------------------------------------
  # Function Asc(String As String) As Integer
  #------------------------------------------------------------------
  def VB.ascw(text)
    if text.empty? then
      return 0
    else
      return text[0].ord
    end
  end
  
  #------------------------------------------------------------------
  # Function ChrW(CharCode As Long)
  #------------------------------------------------------------------
  def VB.chrw(charcode)
    return charcode.chr(Encoding::UTF_8)
  end
  
end
