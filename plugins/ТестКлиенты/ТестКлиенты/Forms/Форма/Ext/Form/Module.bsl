﻿&НаКлиенте
Перем ЗапущенныеТестКлиенты;

&НаКлиенте
Перем КонтекстЯдра;

&НаКлиенте
Перем ПортПоУмолчанию;

// { Plugin interface
&НаКлиенте
Функция ОписаниеПлагина(ВозможныеТипыПлагинов) Экспорт
	Возврат ОписаниеПлагинаНаСервере(ВозможныеТипыПлагинов);
КонецФункции

&НаСервере
Функция ОписаниеПлагинаНаСервере(ВозможныеТипыПлагинов)
	Возврат ЭтотОбъектНаСервере().ОписаниеПлагина(ВозможныеТипыПлагинов);
КонецФункции

&НаКлиенте
Процедура Инициализация(КонтекстЯдраПараметр) Экспорт
	КонтекстЯдра = КонтекстЯдраПараметр;
КонецПроцедуры

&НаКлиенте
Функция ПортПоУмолчанию() Экспорт 
	Если Не ЗначениеЗаполнено(ПортПоУмолчанию) Тогда
		УстановитьПортПоУмолчанию(52010);
	КонецЕсли;
	Возврат ПортПоУмолчанию;
КонецФункции

&НаКлиенте
Процедура УстановитьПортПоУмолчанию(Знач Порт) Экспорт
	ПортПоУмолчанию = Порт;
КонецПроцедуры

&НаКлиенте
Процедура ПодключитьТестКлиент_ПакетныйРежим(Параметры_xddTestClient) Экспорт
	
	Если Параметры_xddTestClient.Количество() > 0 И ТипЗнч(Параметры_xddTestClient[0]) <> Тип("ФиксированныйМассив") Тогда
		НовыйМассивПараметров = Новый Массив;
		НовыйМассивПараметров.Добавить(Параметры_xddTestClient);
		Параметры_xddTestClient = НовыйМассивПараметров;
	КонецЕсли;
	
	Для Каждого ОчередныеПараметры Из Параметры_xddTestClient Цикл
		Попытка
			ПользовательПарольПорт = РазложитьСтрокуВМассивПодстрок(ОчередныеПараметры[0], ":");
			Если ПользовательПарольПорт.Количество() = 3 Тогда
				ТестКлиент = ПодключитьТестКлиент(
				ПользовательПарольПорт[0],
				ПользовательПарольПорт[1],
				ПользовательПарольПорт[2]);
				ЗапомнитьДанныеТестКлиента(ТестКлиент, ПользовательПарольПорт[0], ПользовательПарольПорт[2]);
			Иначе
				ТестКлиент = ПодключитьТестКлиент();
				ЗапомнитьДанныеТестКлиента(ТестКлиент, "", "");
			КонецЕсли;
		Исключение
			Инфо = ИнформацияОбОшибке();
			ОписаниеОшибки = "Ошибка подключения тест-клиента в пакетном режиме
			|" + ПодробноеПредставлениеОшибки(Инфо);
			
			ЗафиксироватьОшибкуВЖурналеРегистрации("xUnitFor1C.ПодключитьТестКлиент", ОписаниеОшибки);
			Сообщить(ОписаниеОшибки, СтатусСообщения.ОченьВажное);
		КонецПопытки;
	КонецЦикла;
	
КонецПроцедуры

&НаКлиенте
Функция ПодключитьТестКлиент(Знач ИмяПользователя = "", Знач Пароль = "", Знач Порт = 0) Экспорт
	Порт = ПолучитьПорт(Порт);
	
	Результат = Неопределено;
	
	Попытка
		Выполнить "Результат = Новый ТестируемоеПриложение(, XMLСтрока(Порт));";
	Исключение
	КонецПопытки;
	
	Если Результат = Неопределено Тогда
		ВызватьИсключение "Не удалось создать объект ТестируемоеПриложение.
		|Возможно, что 1С:Предприятие 8 не было запущено в режиме Менеджера тестирования (ключ командной строки /TESTMANAGER)
		|При запуске Предприятия через Конфигуратор можно включить этот режим в параметрах конфигуратора Сервис -> Параметры -> Запуск 1С:Предприятия -> Дополнительные -> Автоматизированное тестирование -> пункт ""Запускать как менеджер тестирования"".";
	КонецЕсли;
	
	// Попытка подключиться к уже запущенному приложению.
	Подключен = Ложь;
	Попытка
		Результат.УстановитьСоединение();
		Подключен = Истина;
	Исключение
	КонецПопытки;
	
	Если Подключен Тогда
		Возврат Результат;
	КонецЕсли;
	
	СтрокаЗапуска = СтрокаЗапускаТестКлиента(ИмяПользователя, Пароль, Порт);
	
	УправлениеПриложениями = КонтекстЯдра.Плагин("УправлениеПриложениями");
	УправлениеПриложениями.ВыполнитьКомандуОСБезПоказаЧерногоОкна(СтрокаЗапуска, Ложь, Ложь);
	
	ВремяОкончанияОжидания = ТекущаяДата() + ТаймаутВСекундах();
	ОписаниеОшибкиСоединения = "";
	Пока Не ТекущаяДата() >= ВремяОкончанияОжидания Цикл
		Попытка
			Результат.УстановитьСоединение();
			Подключен = Истина;
			Прервать;
		Исключение
			ОписаниеОшибкиСоединения = ОписаниеОшибки();
		КонецПопытки;
	КонецЦикла;
	
	Если Не Подключен Тогда
		Попытка
			Результат.УстановитьСоединение();
		Исключение
			ОписаниеОшибкиСоединения = ОписаниеОшибки();
			ВызватьИсключение КонтекстЯдра.СтрШаблон_(
			"Не смогли установить соединение с тестовым приложением для пользователя %1!
			|%2",
			ИмяПользователя,
			ОписаниеОшибкиСоединения); 
		КонецПопытки;
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

&НаКлиенте
Процедура ЗавершитьВсеТестКлиенты() Экспорт
	
	Если Не ЗначениеЗаполнено(ЗапущенныеТестКлиенты) Тогда
		Возврат;
	КонецЕсли;
	
	Для Каждого ТекЗначение Из ЗапущенныеТестКлиенты Цикл
		Если ЭтоLinux() Тогда
			ЗапуститьПриложение("kill -9 `ps aux | grep -ie TESTCLIENT | grep -ie 1cv8c | awk '{print $2}'`");
		Иначе
			ЗапуститьПриложение(ТекстСкриптаЗавершитьТестКлиент(ТекЗначение.Порт));
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры

&НаКлиенте
Функция ТестКлиентПоУмолчанию() Экспорт
	
	Если ЗначениеЗаполнено(ЗапущенныеТестКлиенты) Тогда
		Возврат ЗапущенныеТестКлиенты[0].ТестКлиент;
	КонецЕсли;
	
	Результат = ПодключитьТестКлиент();
	ЗапомнитьДанныеТестКлиента(Результат, "", "");
	
	Возврат Результат;
	
КонецФункции

&НаКлиенте
Функция ТестКлиентПоПараметрам(Знач ИмяПользователя = "", Знач Пароль = "", Знач Порт = 0) Экспорт
	Порт = ПолучитьПорт(Порт);

	Результат = НайтиЗапущенныйКлиент(ИмяПользователя, Порт);
	Если Результат <> Неопределено Тогда
		Возврат Результат;
	КонецЕсли;
	
	Результат = ПодключитьТестКлиент(ИмяПользователя, Пароль, Порт);
	ЗапомнитьДанныеТестКлиента(Результат, ИмяПользователя, Порт);
	
	Возврат Результат;
	
КонецФункции

&НаКлиенте
Процедура ИдентифицироватьОкноПредупреждение(Знач ТестКлиент, Знач Пояснение = "", Знач ПропускатьПриОтсутствииПрав = Истина) Экспорт
	
	ОкноПредупреждение = ТестКлиент.НайтиОбъект(Тип("ТестируемоеОкноКлиентскогоПриложения"), "1С:Предприятие");
	Если ТипЗнч(ОкноПредупреждение) <> Тип("ТестируемоеОкноКлиентскогоПриложения") Тогда
		Возврат;
	КонецЕсли;
	
	ТекущаяИнформацияОбОшибке = ТестКлиент.ПолучитьТекущуюИнформациюОбОшибке();
	Если ТипЗнч(ТекущаяИнформацияОбОшибке) = Тип("ИнформацияОбОшибке") Тогда
		ПодробноеПредставлениеОшибки = ПодробноеПредставлениеОшибки(ТекущаяИнформацияОбОшибке);
	Иначе
		ПодробноеПредставлениеОшибки = "";
	КонецЕсли;
	
	ТекстИсключения = ТекстИсключения(ОкноПредупреждение);
	ЗакрытьВсеОткрытыеОкна(ТестКлиент);
	
	Если ПропускатьПриОтсутствииПрав И ТекстИсключения = "Недостаточно прав для просмотра" Тогда
		КонтекстЯдра.ПропуститьТест(ТекстИсключения);
	КонецЕсли;
	
	ТекстИсключения = СтрШаблон_("Выявлено модальное окно:
	|[%1] %2
	|%3",
	Пояснение,
	ТекстИсключения,
	ПодробноеПредставлениеОшибки);
	
	КонтекстЯдра.ВызватьОшибкуПроверки(ТекстИсключения);
	
КонецПроцедуры

&НаКлиенте
Функция ОсновноеОкно(ТестКлиент) Экспорт
	КлиентсткиеОкнаТестируемогоПриложения = ТестКлиент.ПолучитьПодчиненныеОбъекты();
	Для Каждого ТекОкно Из КлиентсткиеОкнаТестируемогоПриложения Цикл
		Если ТекОкно.Основное Тогда
			Возврат ТекОкно;
		КонецЕсли;
	КонецЦикла;
КонецФункции

&НаКлиенте
Процедура Пауза(ТестКлиент, КоличествоСекунд) Экспорт
	
	ТестКлиент.ОжидатьОтображениеОбъекта(Тип("ТестируемаяФорма"), "ЗаведомоОтсутствующийОбъект",, КоличествоСекунд);
	
КонецПроцедуры

&НаКлиенте
Функция ТекстИсключения(ОкноПредупреждение) Экспорт
	
	ТекстыЗаголовков = Новый Массив;
	Для Каждого ТекПолеФормы Из ОкноПредупреждение.НайтиОбъекты(Тип("ТестируемоеПолеФормы")) Цикл
		ТекстыЗаголовков.Добавить(ТекПолеФормы.ТекстЗаголовка);
	КонецЦикла;

	Для Каждого ТекДекорацияФормы Из ОкноПредупреждение.НайтиОбъекты(Тип("ТестируемаяДекорацияФормы")) Цикл
		Если ТекДекорацияФормы.Имя = "Message" Тогда
			ТекстыЗаголовков.Добавить(ТекДекорацияФормы.ТекстЗаголовка);
		КонецЕсли;
	КонецЦикла;
	
	Возврат СтрСоединить_(ТекстыЗаголовков, " ");
	
КонецФункции

&НаКлиенте
Процедура ЗакрытьВсеОткрытыеОкна(ТестКлиент) Экспорт
	
	ОкноПредупреждение = ТестКлиент.НайтиОбъект(Тип("ТестируемоеОкноКлиентскогоПриложения"), НСтр("ru = '1С:Предприятие'"));
	НажатьПодходящуюКнопку(ОкноПредупреждение);
	
	ОткрытыеОкна = ТестКлиент.НайтиОбъекты(Тип("ТестируемоеОкноКлиентскогоПриложения"));
	Для Каждого ТекОкно Из ОткрытыеОкна Цикл
		Если ТекОкно.Основное Или ТекОкно.НачальнаяСтраница Тогда
			Продолжить;
		КонецЕсли;
		
		Попытка
			ТекОкно.Закрыть();
		Исключение
			// Необходимо принудительно закрыть все окна, специальная обработка исключений не требуется.
		КонецПопытки;
		
		ОкноПредупреждение = ТестКлиент.НайтиОбъект(Тип("ТестируемоеОкноКлиентскогоПриложения"), НСтр("ru = '1С:Предприятие'"));
		НажатьПодходящуюКнопку(ОкноПредупреждение);
	КонецЦикла;
	
КонецПроцедуры

&НаКлиенте
Процедура НажатьПодходящуюКнопку(ОкноПриложения) Экспорт
	
	Если ТипЗнч(ОкноПриложения) <> Тип("ТестируемоеОкноКлиентскогоПриложения") Тогда
		Возврат;
	КонецЕсли;
	
	Кнопки = ОкноПриложения.НайтиОбъекты(Тип("ТестируемаяКнопкаФормы"));
	Если Не ЗначениеЗаполнено(Кнопки) Тогда
		Возврат;
	КонецЕсли;
	
	Для Каждого ТекПолеФормы Из ОкноПриложения.НайтиОбъекты(Тип("ТестируемоеПолеФормы")) Цикл
		Если СтрНачинаетсяС_(НРег(ТекПолеФормы.ТекстЗаголовка), "данные были изменены")
			Или СтрНачинаетсяС_(НРег(ТекПолеФормы.ТекстЗаголовка), "сохранить данные") Тогда
			Кнопки[1].Нажать();
			Возврат;
		КонецЕсли;
	КонецЦикла;

	Для Каждого ТекДекорацияФормы Из ОкноПриложения.НайтиОбъекты(Тип("ТестируемаяДекорацияФормы")) Цикл
		Если СтрНачинаетсяС_(НРег(ТекДекорацияФормы.ТекстЗаголовка), "данные были изменены")
			Или СтрНачинаетсяС_(НРег(ТекДекорацияФормы.ТекстЗаголовка), "сохранить данные") Тогда
			Кнопки[1].Нажать();
			Возврат;
		КонецЕсли;
	КонецЦикла;
	
КонецПроцедуры
// } Plugin interface

// { Helpers
&НаСервере
Функция ЭтотОбъектНаСервере()
	Возврат РеквизитФормыВЗначение("Объект");
КонецФункции

&НаКлиенте
Функция СтрокаЗапускаТестКлиента(Знач ИмяПользователя, Знач Пароль, Знач Порт)
	
	Если Не ЗначениеЗаполнено(ИмяПользователя) Тогда
		ИмяПользователя = ИмяТекущегоПользователя();
	КонецЕсли;
	
	СтрокаЗапуска1с = КаталогПрограммы() + "1cv8c";
	
	Если Не ЭтоLinux() Тогда
		СтрокаЗапуска1с = КонтекстЯдра.СтрШаблон_("%1.exe", СтрокаЗапуска1с);
	КонецЕсли;
	
	Результат = КонтекстЯдра.СтрШаблон_(
	"""%1"" ENTERPRISE /IBConnectionString""%2""%3%4 /TestClient -TPort%5",
	СтрокаЗапуска1с,
	СтрЗаменить(СтрокаСоединенияИнформационнойБазы(), """", """"""),
	?(ПустаяСтрока(ИмяПользователя), "", " /N""" + ИмяПользователя + """"),
	?(ПустаяСтрока(Пароль), ""," /P""" + Пароль + """"),
	XMLСтрока(Порт));
	
	Возврат Результат;
	
КонецФункции

&НаСервереБезКонтекста
Функция ИмяТекущегоПользователя()
	
	Возврат ПользователиИнформационнойБазы.ТекущийПользователь().Имя;
	
КонецФункции

&НаКлиенте
Функция ТаймаутВСекундах()
	
	Возврат 120;
	
КонецФункции

&НаКлиенте
Функция ТекстСкриптаЗавершитьТестКлиент(НомерПорта)
	
	Результат = "wmic process where (CommandLine Like ""%/TESTCLIENT%"" And ExecutablePath Like ""%1cv8c%"") call terminate";
	
	Если Не ЗначениеЗаполнено(НомерПорта) Тогда
		Возврат Результат;
	КонецЕсли;
	
	Возврат СтрЗаменить(
	Результат,
	"%/TESTCLIENT%",
	"%/TESTCLIENT -TPort" + НомерПорта + "%");
	
КонецФункции

&НаКлиенте
Функция ПолноеИмяИсполняемогоФайла()
	
	Возврат КонтекстЯдра.СтрШаблон_("%1%2%3",
	КаталогПрограммы(),
	"1cv8c",
	РасширениеИсполняемогоФайла());
	
КонецФункции

&НаКлиенте
Функция РасширениеИсполняемогоФайла()
	
	Если ЭтоLinux() Тогда
		Возврат "";
	Иначе
		Возврат ".exe";
	КонецЕсли;
	
КонецФункции

&НаКлиенте
Функция ЭтоLinux()
	
	СисИнфо = Новый СистемнаяИнформация;
	ВерсияПриложения = СисИнфо.ВерсияПриложения;
	
	Возврат Найти(Строка(СисИнфо.ТипПлатформы), "Linux") > 0;
	
КонецФункции

&НаСервере
Процедура ЗафиксироватьОшибкуВЖурналеРегистрации(Знач ИдентификаторГенератораОтчета, Знач ОписаниеОшибки)
	ЗаписьЖурналаРегистрации(ИдентификаторГенератораОтчета, УровеньЖурналаРегистрации.Ошибка, , , ОписаниеОшибки);
КонецПроцедуры

&НаКлиенте
Процедура ЗапомнитьДанныеТестКлиента(ТестКлиент, ИмяПользователя, Порт)
	
	ДанныеТестКлиента = Новый Структура;
	ДанныеТестКлиента.Вставить("ТестКлиент", ТестКлиент);
	ДанныеТестКлиента.Вставить("ИмяПользователя", ИмяПользователя);
	ДанныеТестКлиента.Вставить("Порт", Порт);
	
	Если ЗапущенныеТестКлиенты = Неопределено Тогда
		ЗапущенныеТестКлиенты = Новый Массив;
	КонецЕсли;
	
	ЗапущенныеТестКлиенты.Добавить(ДанныеТестКлиента);
	
КонецПроцедуры

&НаКлиенте
Функция НайтиЗапущенныйКлиент(ИмяПользователя, Порт)
	
	Если Не ЗначениеЗаполнено(ЗапущенныеТестКлиенты) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Для Каждого ТекЗапущенныйКлиент Из ЗапущенныеТестКлиенты Цикл
		Если ТекЗапущенныйКлиент.ИмяПользователя = ИмяПользователя 
			И ТекЗапущенныйКлиент.Порт = Порт Тогда
			Возврат ТекЗапущенныйКлиент.ТестКлиент;
		КонецЕсли;
	КонецЦикла;
	
КонецФункции

&НаКлиенте
Функция ПолучитьПорт(Знач Порт)
	Если Не ЗначениеЗаполнено(Порт) Тогда
		Порт = ПортПоУмолчанию();
	КонецЕсли;
	Возврат Порт;
КонецФункции

&НаКлиенте
Функция РазложитьСтрокуВМассивПодстрок(Знач Строка, Знач Разделитель = ",", Знач ПропускатьПустыеСтроки = Неопределено) Экспорт
	
	Результат = Новый Массив;
	
	// для обеспечения обратной совместимости
	Если ПропускатьПустыеСтроки = Неопределено Тогда
		ПропускатьПустыеСтроки = ?(Разделитель = " ", Истина, Ложь);
		Если ПустаяСтрока(Строка) Тогда 
			Если Разделитель = " " Тогда
				Результат.Добавить("");
			КонецЕсли;
			Возврат Результат;
		КонецЕсли;
	КонецЕсли;
		
	Позиция = Найти(Строка, Разделитель);
	Пока Позиция > 0 Цикл
		Подстрока = Лев(Строка, Позиция - 1);
		Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Подстрока) Тогда
			Результат.Добавить(Подстрока);
		КонецЕсли;
		Строка = Сред(Строка, Позиция + СтрДлина(Разделитель));
		Позиция = Найти(Строка, Разделитель);
	КонецЦикла;
	
	Если Не ПропускатьПустыеСтроки Или Не ПустаяСтрока(Строка) Тогда
		Результат.Добавить(Строка);
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

// Замена функции СтрШаблон на конфигурациях с режимом совместимости < 8.3.6
// При внедрении в конфигурацию с режимом совместимости >= 8.3.6 данную функцию необходимо удалить
//
&НаКлиенте
Функция СтрШаблон_(Знач СтрокаШаблон, Знач Парам1 = Неопределено, Знач Парам2 = Неопределено,
	Знач Парам3 = Неопределено, Знач Парам4 = Неопределено, Знач Парам5 = Неопределено) Экспорт

	МассивПараметров = Новый Массив;
	МассивПараметров.Добавить(Парам1);
	МассивПараметров.Добавить(Парам2);
	МассивПараметров.Добавить(Парам3);
	МассивПараметров.Добавить(Парам4);
	МассивПараметров.Добавить(Парам5);

	Для Сч = 1 По МассивПараметров.Количество() Цикл
		ТекЗначение = МассивПараметров[Сч-1];
		СтрокаШаблон = СтрЗаменить(СтрокаШаблон, "%"+Сч, Строка(ТекЗначение));
	КонецЦикла;
	Возврат СтрокаШаблон;
КонецФункции

&НаКлиенте
Функция СтрНачинаетсяС_(Строка, СтрокаПоиска) Экспорт
	Возврат Найти(Строка, СтрокаПоиска) = 1;
КонецФункции

///  Объединяет строки из массива в строку с разделителями.
//
// Параметры:
//  Массив      - Массив - массив строк которые необходимо объединить в одну строку;
//  Разделитель - Строка - любой набор символов, который будет использован в качестве разделителя.
//
// Возвращаемое значение:
//  Строка - строка с разделителями.
//
&НаКлиенте
Функция СтрСоединить_(Массив, Разделитель = ",") Экспорт

	Результат = "";

	Для Индекс = 0 По Массив.ВГраница() Цикл
		Подстрока = Массив[Индекс];

		Если ТипЗнч(Подстрока) <> Тип("Строка") Тогда
			Подстрока = Строка(Подстрока);
		КонецЕсли;

		Если Индекс > 0 Тогда
			Результат = Результат + Разделитель;
		КонецЕсли;

		Результат = Результат + Подстрока;
	КонецЦикла;

	Возврат Результат;
КонецФункции
// } Helpers