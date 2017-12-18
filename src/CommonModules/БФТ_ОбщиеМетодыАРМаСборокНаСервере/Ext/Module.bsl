﻿/////////////// Защита модуля ///////////////
// @protect                                //
/////////////////////////////////////////////

#Область ПрограммныйИнтерфейс

// Процедура анализа изменений хранилища 1С.
Процедура АнализИзмененийХранилища1С() Экспорт 
	ПользовательХранилища = ОбщегоНазначенияСервер.ПолучитьЗначениеКонстанты("ПользовательХранилища");
	АдресХранилища = ОбщегоНазначенияСервер.ПолучитьЗначениеКонстанты("АдресХранилища");
	ПарольХранилища = ОбщегоНазначенияСервер.ПолучитьЗначениеКонстанты("ПарольХранилища");
	Если Не ЗначениеЗаполнено(АдресХранилища) ИЛИ Не ЗначениеЗаполнено(ПользовательХранилища) Тогда
		ВызватьИсключение "Не заполнены настройки подключения к хранилищу";
	КонецЕсли;
	
	Попытка
		// Создаем временную БД
		Адрес = ПоместитьВоВременноеХранилище(Неопределено, Новый УникальныйИдентификатор());
		АдресХранилищаОтчета = ПоместитьВоВременноеХранилище(Неопределено, Новый УникальныйИдентификатор());
		БФТ_ДлительныеОперацииСервер.СоздатьВременнуюБД(Адрес);
		ПутьКВременнойБД = ПолучитьИзВременногоХранилища(Адрес); 
		
		ПоследняяЗапрашиваемаяВерсия = ПолучитьПоследнююЗапрашиваемаемуюВерсию();
		
		// Запрашиваем отчет
		БФТ_ДлительныеОперацииСервер.ПолучитьФайлОтчетаПоХранилищу(АдресХранилищаОтчета,
		ПутьКВременнойБД,
		АдресХранилища,
		ПользовательХранилища,
		ПарольХранилища,
		ПоследняяЗапрашиваемаяВерсия);
		ФайлОтчета = ПолучитьИзВременногоХранилища(АдресХранилищаОтчета); 
		
		Отчет = Новый ТабличныйДокумент();
		Отчет.Прочитать(ФайлОтчета);
		
		Построитель = Новый ПостроительЗапроса;
		Построитель.ИсточникДанных = Новый ОписаниеИсточникаДанных(Отчет.Область(3, 1, Отчет.ВысотаТаблицы, 2));
		Построитель.Выполнить();
		
		ТЗ = Построитель.Результат.Выгрузить();
		КолонкаЗаголовок = ТЗ.Колонки[0].Имя;
		КолонкаДанные = ТЗ.Колонки[1].Имя;
		
		ДанныеХранилища = Новый Массив();
		Для а = 0 По ТЗ.Количество()-1 Цикл
			// Если наткнулись на версию, следующие 4 строки нам нужны. 
			// Структура такая:
			// Версия
			// Пользователь
			// Дата создания
			// Время создания
			// Комментарий.
			Если Не СтрНачинаетсяС(ТЗ[а][КолонкаЗаголовок], "Версия") Тогда
				Продолжить;
			КонецЕсли;
			
			Данные = Новый Структура("Версия,Дата,Время,Пользователь,Комментарий");
			Данные.Версия = ТЗ[а][КолонкаДанные];
			Данные.Пользователь = ТЗ[а+1][КолонкаДанные];
			Данные.Дата = ТЗ[а+2][КолонкаДанные];
			Данные.Время = ТЗ[а+3][КолонкаДанные];
			Данные.Комментарий = ТЗ[а+4][КолонкаДанные];
			
			ДанныеХранилища.Добавить(Данные);
		КонецЦикла;
		
		СоздатьЗаписи(ДанныеХранилища);
		
		Если БФТ_ФайлСуществует(ПутьКВременнойБД) Тогда
			ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ПутьКВременнойБД);  
		КонецЕсли;
		Если БФТ_ФайлСуществует(ФайлОтчета) Тогда
			ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ФайлОтчета);  
		КонецЕсли;
	Исключение
		Если БФТ_ФайлСуществует(ПутьКВременнойБД) Тогда
			ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ПутьКВременнойБД);  
		КонецЕсли;
		Если БФТ_ФайлСуществует(ФайлОтчета) Тогда
			ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ФайлОтчета);  
		КонецЕсли;
		ВызватьИсключение;
	КонецПопытки;
КонецПроцедуры

// Процедура выгрузки изменений из SVN.
Процедура ВыгрузкаИзмененийИзSVN() Экспорт
	
	ПараметрыКоманды = Новый Структура();
	ПараметрыКоманды.Вставить("Пароль", БФТ_ОбщиеМетодыАРМаСборокНаКлиентеНаСервере.ПарольДоступаК_SVN());
	НастройкаПодключенияКРепозиторию = Справочники.БФТ_НастройкаПодключенияКРепозиторию.ПолучитьЕдинственнуюНастройкуПодключенияКРепозиторию();
	
	ТекстXML = БФТ_ОбщиеМетодыАРМаСборокНаКлиентеНаСервере.ВыполнитьМетод(НастройкаПодключенияКРепозиторию, "log_server", ПараметрыКоманды);  
	Если Не ЗначениеЗаполнено(ТекстXML) Тогда
		Возврат;	
	КонецЕсли;
	
	XML_DOM = УтилитыDOM.ПолучитьDOM(ТекстXML);
	БФТ_ОбщиеМетодыАРМаСборокНаСервере.РазобратьФайл(Неопределено, XML_DOM);
КонецПроцедуры


// Процедура - Обновить на сервере тексты шаблонов.
//
// Параметры:
//  Коды             -  Массив  - массив кодов;
//  СодержимоеФайлов -  Соответствие  - содержимое файлов;
//  ВосстанавливатьПоддержку -  Булево  - Истина, если надо востановить поддержку.
//
&НаСервере
Процедура ОбновитьНаСервереТекстыШаблонов(Коды, СодержимоеФайлов, ВосстанавливатьПоддержку = Ложь) Экспорт 
	
	КодыШаблонов = Новый ТаблицаЗначений();
	КодыШаблонов.Колонки.Добавить("КодШаблона");
	Для Каждого Стр Из Коды Цикл
		КодыШаблонов.Добавить().КодШаблона = Стр;
	КонецЦикла;
	
	НачатьТранзакцию();
	Попытка
		// Блокируем обновляемые шаблоны. 
		Блокировка = Новый БлокировкаДанных();
		ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.БФТ_ФайлыШаблоновПреобразования");
		ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
		ЭлементБлокировки.ИсточникДанных = КодыШаблонов;
		ЭлементБлокировки.ИспользоватьИзИсточникаДанных("КодШаблона", "КодШаблона");
		Блокировка.Заблокировать();
		
		ЕстьПрава = РольДоступна(Метаданные.Роли.БФТ_АдминистраторЛок);
		ОбластьДанныхИспользование = ПараметрыСеанса.ОбластьДанныхИспользование;
		Если ЕстьПрава Тогда
			ПараметрыСеанса.ОбластьДанныхИспользование = Ложь;
		КонецЕсли;
		
		Запрос = Новый Запрос();
		Запрос.Текст = "ВЫБРАТЬ
		|	Табл.Код
		|ПОМЕСТИТЬ ВремТабл
		|ИЗ
		|	&ВремТабл КАК Табл
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	БФТ_ФайлыШаблоновПреобразования.ИдентификаторИмпорта,
		|	ВремТабл.Код
		|ИЗ
		|	ВремТабл КАК ВремТабл
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.БФТ_ФайлыШаблоновПреобразования КАК БФТ_ФайлыШаблоновПреобразования
		|		ПО (БФТ_ФайлыШаблоновПреобразования.КодШаблона = ВремТабл.Код)";
		
		ВремТабл = Новый ТаблицаЗначений();
		ВремТабл.Колонки.Добавить("Код", Новый ОписаниеТипов("Строка",,,, Новый КвалификаторыСтроки(4)));
		Для Каждого Код Из Коды Цикл
			ВремТабл.Добавить().Код = Код;	
		КонецЦикла;
		
		
		Запрос.Параметры.Вставить("ВремТабл", ВремТабл);
		Выборка = Запрос.Выполнить().Выбрать();
		Пока Выборка.Следующий() Цикл
			Если Не ЗначениеЗаполнено(Выборка.ИдентификаторИмпорта) Тогда
				// Создаем
				// Потом сделаю, нужно еще эл. справочника БФТ_ШаблоныПреобразования создавать.
				// Запись = РегистрыСведений.БФТ_ФайлыШаблоновПреобразования.СоздатьМенеджерЗаписи();
				// Запись.КодШаблона = Выборка.Код;
				// Запись.ИдентификаторИмпорта = Новый УникальныйИдентификатор();
				// Запись.ШаблонНаПоддержке = Истина;
				// Запись.ТелоФайла =
				// РегистрыСведений.БФТ_ФайлыШаблоновПреобразования.ПодготовитьТелоФайла(СодержимоеФайлов[Выборка.Код]);
				// Запись.Записать();
				Продолжить;
			КонецЕсли;
			
			Набор = РегистрыСведений.БФТ_ФайлыШаблоновПреобразования.СоздатьНаборЗаписей();
			Набор.Отбор.ИдентификаторИмпорта.Установить(Выборка.ИдентификаторИмпорта);
			Набор.Прочитать();
			
			Если Набор.Количество() > 1 Тогда
				ВызватьИсключение СтрШаблон("По идентификатору импорта ""%1"" в регистре ""Файлы шаблонов преобразования"" найдено несколько записей", Выборка.ИдентификаторИмпорта);
			КонецЕсли;
			
			Набор[0].ТелоФайла = РегистрыСведений.БФТ_ФайлыШаблоновПреобразования.ПодготовитьТелоФайла(СодержимоеФайлов[Выборка.Код]);
			Если ВосстанавливатьПоддержку Тогда
				Набор[0].ШаблонНаПоддержке = Истина;
			КонецЕсли;
			Набор.Записать();
		КонецЦикла;
		
		
		Если ЕстьПрава Тогда
			ПараметрыСеанса.ОбластьДанныхИспользование = ОбластьДанныхИспользование;
		КонецЕсли;
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;
КонецПроцедуры

// Функция получает ссылку на элемент справочника "Методы работы с репозиторием (БФТ)".
//
// Параметры:
//  НастройкиСсылка - СправочникСсылка.БФТ_НастройкаПодключенияКРепозиторию - 
//    ссылка на элемент справочника "Настройка подключения к репозиторию (БФТ)"; 
//  ИмяКоманды - Строка - имя команды.
//
// Возвращаемое значение: 
//  СправочникСсылка.БФТ_МетодыРаботыСРепозиторием - 
//    ссылка на элемент справочника "Методы работы с репозиторием (БФТ)".
//
Функция ПолучитьМетод(НастройкиСсылка, ИмяКоманды) Экспорт 
	// Процедура обертка что бы можно было вызывать из клиента..
	Возврат Справочники.БФТ_НастройкаПодключенияКРепозиторию.ПолучитьМетод(НастройкиСсылка, ИмяКоманды);
КонецФункции

// Функция получения порядкового номера версии подсистемы АЦК.
//
// Возвращаемое значение: 
//  Число - номер версии АЦК.
//
Функция ПолучитьПорядковыйНомерВерсииПодсистемыАЦК() Экспорт 
	//ВерсияПодсистемыСтрокой = БФТ_ОбновлениеИнформационнойБазы.ВерсияАЦКБУ();
	//Разбивка = СтрРазделить(ВерсияПодсистемыСтрокой, ".", Ложь);
	Результат = 0;
	//Для Каждого Элем Из Разбивка Цикл
	//	Результат = Результат + СтроковыеФункцииКлиентСервер.СтрокаВЧисло(Элем);
	//КонецЦикла;
	
	Возврат Результат;
КонецФункции

// Функция разбора комментария.
//
// Параметры:
//  Комментарий  - Строка - строка для разбора комментария.
//
// Возвращаемое значение:
//   Массив   - разобранная строка.
//
&НаСервере
Функция РазборКомментария(Комментарий) Экспорт 
	Перем RegExp;
	
	RegExp = Новый COMОбъект("VBScript.RegExp");
	
	RegExp.IgnoreCase = Ложь; //Игнорировать регистр
	RegExp.Global = Истина; //Поиск всех вхождений шаблона
	RegExp.MultiLine = Ложь; //Многострочный режим
	
	RegExp.Pattern = "BU-(([\D]+[\d]+)|([\d]+))"; 
	Matches = RegExp.Execute(Комментарий);
	
	Ответ = Новый Массив();
	Для Каждого Match Из Matches Цикл
		Если ЗначениеЗаполнено(Match.Value) Тогда
			Ответ.Добавить(Match.Value);    
		КонецЕсли;
	КонецЦикла;
	
	Возврат Ответ;     
КонецФункции

// Процедура разборки файла.
//
// Параметры:
//  Адрес  - Строка - адрес хранилища;
//  ДокументDOM  - ДокументDOM - документ DOM.
//
&НаСервере
Процедура РазобратьФайл(Адрес, ДокументDOM) Экспорт 
	Перем ЧтениеXML;
	
	ВремФайл = ПолучитьИмяВременногоФайла("xml");
	Попытка
		Если Адрес <> Неопределено Тогда
			ФайлДанные = ПолучитьИзВременногоХранилища(Адрес);
			ФайлДанные.Записать(ВремФайл);                                       
			
			ЧтениеXML = УтилитыЧтенияXML.СоздатьИзФайла(ВремФайл, "");
			DOM = Новый ПостроительDOM;                      
			XML = DOM.Прочитать(ЧтениеXML); 
		Иначе
			XML = ДокументDOM;
		КонецЕсли;
		
		ВыборкаНодов = XML.ВычислитьВыражениеXPath("/log/logentry", XML, Новый РазыменовательПространствИменDOM(XML)); 
		НачатьТранзакцию();
		Попытка
			
			Узел = ВыборкаНодов.ПолучитьСледующий();
			Пока Узел <> Неопределено Цикл
				СоздатьЗапись(Узел);
				Узел = ВыборкаНодов.ПолучитьСледующий();
			КонецЦикла; 
			
			Выборка = РегистрыСведений.БФТ_ИзмененияРепозитория.Выбрать();
			Пока Выборка.Следующий() Цикл 
				ПривязатьКЗадачам(Выборка.Комментарий, Выборка.НомерРевизии);
			КонецЦикла;
			
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			ВызватьИсключение;
		КонецПопытки;
		
		Если ЧтениеXML <> Неопределено Тогда
			ЧтениеXML.Закрыть();
		КонецЕсли;
		ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ВремФайл);
	Исключение
		Если ЧтениеXML <> Неопределено Тогда
			ЧтениеXML.Закрыть();
		КонецЕсли;
		ОбщегоНазначенияКлиентСервер.УдалитьФайлыКлиентСервер(ВремФайл);
		ВызватьИсключение;
	КонецПопытки;
	
	                                                      
КонецПроцедуры

// Процедура разборки файла.
//
// Параметры:
//  Форма  - Форма - форма;
//  ГруппаРодитель  - Неопределено - группа родитель.
//
Процедура СоздатьЭлементыФормыСписка(Форма, ГруппаРодитель = Неопределено) Экспорт 
	Если ГруппаРодитель = Неопределено Тогда
		ЭлементаРодитель = Форма;
	Иначе
		ЭлементаРодитель = ГруппаРодитель;
	КонецЕсли;
	
	ИмяРеквизита = "НастройкаПодключенияКРепозиторию";
	Если Не ОбщегоНазначенияКлиентСервер.НаличиеСвойстваУОбъекта(Форма, ИмяРеквизита) Тогда
		Реквизит = Новый РеквизитФормы(ИмяРеквизита, Новый ОписаниеТипов("СправочникСсылка.БФТ_НастройкаПодключенияКРепозиторию"));
		Реквизит.Заголовок = "Настройка подключения к репозиторию";
		Реквизиты = ОбщегоНазначенияКлиентСервер.ЗначениеВМассиве(Реквизит);
		
		Форма.ИзменитьРеквизиты(Реквизиты);                         
	КонецЕсли;
	Форма[ИмяРеквизита] = Справочники.БФТ_НастройкаПодключенияКРепозиторию.ПолучитьЕдинственнуюНастройкуПодключенияКРепозиторию(); 
	
	// Создание элемента
	Если Форма.Элементы.Найти(ИмяРеквизита) = Неопределено Тогда
		ЭлементПароль = Форма.Элементы.Добавить(ИмяРеквизита, Тип("ПолеФормы"), ЭлементаРодитель);
		ЭлементПароль.ПутьКДанным    = ИмяРеквизита;
		ЭлементПароль.Вид = ВидПоляФормы.ПолеВвода;
	КонецЕсли;
	
	// Создание кнопки
	ИмяКоманды = "ЗагрузитьИзменения";  
	Если Форма.Команды.Найти(ИмяКоманды) = Неопределено Тогда
		КомандаФормы  = Форма.Команды.Добавить(ИмяКоманды); 
		КомандаФормы.Действие = "ПолучитьИзмененияРепозитория_Подключаемый";
		
		Кнопка = Форма.Элементы.Добавить(ИмяКоманды, Тип("КнопкаФормы"), ЭлементаРодитель);
		Кнопка.Вид = ВидКнопкиФормы.ОбычнаяКнопка;
		Кнопка.ИмяКоманды = ИмяКоманды;
		Кнопка.Заголовок = "Загрузить изменения";
	КонецЕсли;
	
КонецПроцедуры

// Функция получает текст для выполнения команды.
//
// Параметры:
//  Метод - СправочникСсылка.БФТ_МетодыРаботыСРепозиторием - ссылка на элемент справочника;
//  ВнешниеПараметры - Структура - структура с параметрами.
//
// Возвращаемое значение: 
//  Строка - текст команды для выполнения.
//
Функция СформироватьКомандуВыполнения(Метод, ВнешниеПараметры = Неопределено) Экспорт 
	// Процедура обертка что бы можно было вызывать из клиента..
	Возврат Справочники.БФТ_МетодыРаботыСРепозиторием.СформироватьКомандуВыполнения(Метод, ВнешниеПараметры);
КонецФункции


#КонецОбласти

#Область СлужебныеПроцедурыИФункции


Функция КоличествоОдновременныхВыгрузок(ПутьККаталогуВыгрузки)
	Диск = Лев(ПутьККаталогуВыгрузки, СтрНайти(ПутьККаталогуВыгрузки, ":"));
	
	FSO = Новый COMОбъект("Scripting.FileSystemObject");
	Drive = FSO.GetDrive(Диск);
	СвободноеМесто = Drive.AvailableSpace/1024/1024/1024; // Гб
	
	// Максимально можно выгружать 5 ревизий (если большесильно отжирается память).
	// Каждая ревизия занимает место на диске ~2Гб.
	КолВоВозможных = Цел(СвободноеМесто / 2);
	
	Возврат ?(КолВоВозможных > 5, 5, КолВоВозможных);
КонецФункции

&НаСервере
Функция НайтиСоздатьНаборыИзменений(КодЛиста)
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	| БФТ_НаборыИзменений.Ссылка
	|ИЗ
	| Справочник.БФТ_НаборыИзменений КАК БФТ_НаборыИзменений
	|ГДЕ
	| БФТ_НаборыИзменений.Код ПОДОБНО &Код";
	
	Запрос.УстановитьПараметр("Код", КодЛиста);
	
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		Возврат Выборка.Ссылка.ПолучитьОбъект();  
	Иначе
		НовСпр = Справочники.БФТ_НаборыИзменений.СоздатьЭлемент();
		НовСпр.Код = СокрЛП(КодЛиста);
		НовСпр.Записать();
		
		Возврат НовСпр;
	КонецЕсли;
КонецФункции


Функция ПолучитьДанныеИзОчереди(РазмерБлока)
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	| БФТ_ОчередьВыгрузкиРевизийКонфигурации1С.НомерРевизии КАК НомерРевизии,
	| БФТ_ОчередьВыгрузкиРевизийКонфигурации1С.Комментарий
	|ИЗ
	| РегистрСведений.БФТ_ОчередьВыгрузкиРевизийКонфигурации1С КАК БФТ_ОчередьВыгрузкиРевизийКонфигурации1С
	|ГДЕ
	| БФТ_ОчередьВыгрузкиРевизийКонфигурации1С.Статус = ЗНАЧЕНИЕ(Перечисление.БФТ_СтатусИзмененийРепозитория.НеЗагружено)
	|
	|УПОРЯДОЧИТЬ ПО
	| НомерРевизии";
	
	// Запрос.УстановитьПараметр("Период", ТекущаяДатаСеанса() - (7 *24 *60*60));  оставляем неделю.
	ТЗ = Запрос.Выполнить().Выгрузить();
	
	Результат = Новый Массив();
	Для а = 0 По ТЗ.Количество()-1 Цикл
		// Разбиваем на блоки, чем больше ревизий параллельно выгружать, тем больше нужно место на диске. 
		Если а % РазмерБлока = 0 Тогда
			Результат.Добавить(Новый Массив());
		КонецЕсли;
		
		Результат[Результат.ВГраница()].Добавить(Новый Структура("НомерРевизии, Комментарий", ТЗ[а].НомерРевизии, ТЗ[а].Комментарий));
	КонецЦикла;
	
	Возврат Результат;
КонецФункции


Функция ПолучитьПоследнююЗапрашиваемаемуюВерсию()
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ ПЕРВЫЕ 1
	| БФТ_ОчередьВыгрузкиРевизийКонфигурации1С.НомерРевизии КАК НомерРевизии
	|ИЗ
	| РегистрСведений.БФТ_ОчередьВыгрузкиРевизийКонфигурации1С КАК БФТ_ОчередьВыгрузкиРевизийКонфигурации1С
	|
	|УПОРЯДОЧИТЬ ПО
	| НомерРевизии УБЫВ";
	
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда
		Возврат Выборка.НомерРевизии;  
	КонецЕсли;
КонецФункции

&НаСервере
Функция ПреобразоватьВид(Вид)
	Если ВРег(Вид) = "FILE" Тогда
		Возврат "Файл";  
	ИначеЕсли ВРег(Вид) = "DIR" Тогда
		Возврат "Директория";  
	Иначе
		Возврат "";
	КонецЕсли;
КонецФункции

&НаСервере
Функция ПреобразоватьДействие(Действие)
	Если ВРег(Действие) = "A" Тогда
		Возврат "Добавление";  
	ИначеЕсли ВРег(Действие) = "M" Тогда
		Возврат "Изменение";  
	ИначеЕсли ВРег(Действие) = "D" Тогда
		Возврат "Удаление";  
	Иначе 
		Возврат "";
	КонецЕсли;
КонецФункции

&НаСервере
Процедура ПривязатьКЗадачам(Комментарий, НомерРевизии)
	КодыЗадач = РазборКомментария(Комментарий);   
	Если КодыЗадач.Количество() = 0 Тогда
		// Если не нашли задачи, значит не привязывваем.
		Возврат;
	КонецЕсли;
	
	Для Каждого Задача Из КодыЗадач Цикл
		ЗадачаОбъект = НайтиСоздатьНаборыИзменений(Задача);
		Отбор = Новый Структура("НомерРевизии", НомерРевизии);
		Если ЗадачаОбъект.НаборИзменений.НайтиСтроки(Отбор).Количество() = 0 Тогда
			НовСтр = ЗадачаОбъект.НаборИзменений.Добавить();
			НовСтр.НомерРевизии = СокрЛП(НомерРевизии);
		КонецЕсли;
		
		Если ЗадачаОбъект.Модифицированность() Тогда
			// Если задача была уже привязана к сборке, а у сборки статус отличается от "На редактировании".
			// Значит такая сборка уже не актуальна, ее нужно пересобирать, взводим в ней флаг.
			ЗадачаОбъект.Записать();
			ПроверитьАктуальностьСборки(ЗадачаОбъект.Ссылка);
		КонецЕсли;
		
	КонецЦикла;
КонецПроцедуры

&НаСервере
Процедура ПроверитьАктуальностьСборки(НаборИзмСсылка)
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ РАЗЛИЧНЫЕ
	| БФТ_Сборки.Ссылка
	|ИЗ
	| Справочник.БФТ_Сборки.НаборыИзменений КАК БФТ_СборкиНаборыИзменений
	|   ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.БФТ_Сборки КАК БФТ_Сборки
	|   ПО БФТ_СборкиНаборыИзменений.Ссылка = БФТ_Сборки.Ссылка
	|ГДЕ
	| БФТ_СборкиНаборыИзменений.НаборИзменений = &НаборИзменений
	| И БФТ_Сборки.ТекущийШаг > 0";
	
	Запрос.УстановитьПараметр("НаборИзменений", НаборИзмСсылка);
	
	Выборка = Запрос.Выполнить().Выбрать();
	Пока Выборка.Следующий() Цикл
		СборкаОбъект = Выборка.Ссылка.ПолучитьОбъект();
		СтрокаЗадачи = СборкаОбъект.НаборыИзменений.Найти(НаборИзмСсылка, "НаборИзменений");;
		Если СтрокаЗадачи <> Неопределено Тогда
			СтрокаЗадачи.ЗадачаНеАктуальна = Истина;  
		КонецЕсли;
		
		Если СборкаОбъект.Модифицированность() Тогда
			СборкаОбъект.Записать();  
		КонецЕсли;
		
	КонецЦикла;
КонецПроцедуры


Процедура ПроставитьФлагЗагружено(Ревизия)
	// Для Каждого Ревизия Из Пакет Цикл.
	Набор = РегистрыСведений.БФТ_ОчередьВыгрузкиРевизийКонфигурации1С.СоздатьНаборЗаписей();
	Набор.Отбор.НомерРевизии.Установить(Ревизия.НомерРевизии);
	Набор.Прочитать();
	
	Набор[0].Статус = Перечисления.БФТ_СтатусИзмененийРепозитория.Загружено;
	Набор.Записать();
	// КонецЦикла;
КонецПроцедуры


Процедура СоздатьЗаписи(ДанныеХранилища)
	Для Каждого Данные Из ДанныеХранилища Цикл
		Запись = РегистрыСведений.БФТ_ИзмененияРепозитория.СоздатьМенеджерЗаписи();
		Данные.Свойство("Пользователь", Запись.АвторИзменений);
		Данные.Свойство("Версия", Число(Запись.НомерРевизии));
		Данные.Свойство("Комментарий", Запись.Комментарий);
		Запись.Период = СтроковыеФункцииКлиентСервер.СтрокаВДату(Данные.Дата);
		Запись.ИзменениеКонфигурации = Истина;
		Запись.Записать();
	КонецЦикла;
КонецПроцедуры

&НаСервере
Процедура СоздатьЗапись(Коммит)
	НомерРевизии = Коммит.Атрибуты.ПолучитьИменованныйЭлемент("revision");
	Если НомерРевизии = Неопределено Тогда
		Возврат;  
	КонецЕсли;                                                                                    
	
	Запись = РегистрыСведений.БФТ_ИзмененияРепозитория.СоздатьМенеджерЗаписи();
	Запись.НомерРевизии = НомерРевизии.Значение;
	Запись.ТипИзменений = Перечисления.БФТ_ТипИзменений.Шаблоны;
	
	Для Каждого Свойство Из Коммит.ДочерниеУзлы Цикл
		Если Свойство.ИмяУзла = "author" Тогда
			Запись.АвторИзменений = Свойство.ТекстовоеСодержимое;
		ИначеЕсли Свойство.ИмяУзла = "msg" Тогда
			Запись.Комментарий = СтрШаблон("%1%3%3Детали:%3%2", Свойство.ТекстовоеСодержимое, СформироватьДетали(Коммит), Символы.ПС);
		ИначеЕсли Свойство.ИмяУзла = "date" Тогда
			Запись.Период = XMLЗначение(Тип("Дата"), Свойство.ТекстовоеСодержимое);
		КонецЕсли;
	КонецЦикла;
	
	Запись.Записать();
КонецПроцедуры

&НаСервере
Функция СформироватьДетали(ЭлементDOM)
	XML = ЭлементDOM.ДокументВладелец;
	Детали = XML.ВычислитьВыражениеXPath("paths/path", ЭлементDOM, Новый РазыменовательПространствИменDOM(XML)); 
	
	Узел = Детали.ПолучитьСледующий();
	Изменения = Новый Массив();
	Пока Узел <> Неопределено Цикл
		ДействиеУзел = Узел.Атрибуты.ПолучитьИменованныйЭлемент("action");
		ВидУзел = Узел.Атрибуты.ПолучитьИменованныйЭлемент("kind");
		Если ДействиеУзел = Неопределено ИЛИ ВидУзел = Неопределено Тогда
			Продолжить;  
		КонецЕсли;    
		Действие = ПреобразоватьДействие(ДействиеУзел.Значение); 
		Вид = ПреобразоватьВид(ВидУзел.Значение); 
		
		Изменения.Добавить(СтрШаблон("Действие: ""%1""%2" +
		"Вид: ""%3""%2" +
		"Путь: ""%4""%2", Действие, Символы.ПС, Вид, Узел.ТекстовоеСодержимое));
		
		Узел = Детали.ПолучитьСледующий();
	КонецЦикла; 
	
	Возврат СтрСоединить(Изменения, Символы.ПС);
КонецФункции


#КонецОбласти

