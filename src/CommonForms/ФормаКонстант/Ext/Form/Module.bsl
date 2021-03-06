﻿
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
//	Корень = ХранилищеОбщихНастроек.Загрузить("Путь каталогу репозитория SVN", "ПутьККаталогуРепозитория");
КонецПроцедуры

&НаКлиенте
Процедура ПутьККаталогуСФайламиРасширенийНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;

	Если Не ЗначениеЗаполнено(НаборКонстант.ПутьККаталогуSVN) Тогда
		Сообщить("Заполните ""Путь к каталогу SVN""");
		Возврат;
	КонецЕсли;

	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.ВыборКаталога);
	ОО = Новый ОписаниеОповещения("ВыборПутиЗавершение1", ЭтотОбъект);
	Диалог.Показать(ОО);

КонецПроцедуры

&НаКлиенте
Процедура ПутьККаталогуSVNНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	
	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.ВыборКаталога);
	ОО = Новый ОписаниеОповещения("ВыборКорняЗавершение", ЭтотОбъект);
	Диалог.Показать(ОО);
КонецПроцедуры


&НаКлиенте
Процедура ПутьККаталогуШаблоновНачалоВыбора(Элемент, ДанныеВыбора, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	
	Если Не ЗначениеЗаполнено(НаборКонстант.ПутьККаталогуSVN) Тогда
		Сообщить("Заполните ""Путь к каталогу SVN""");
		Возврат;
	КонецЕсли;
	
	Диалог = Новый ДиалогВыбораФайла(РежимДиалогаВыбораФайла.ВыборКаталога);
	ОО = Новый ОписаниеОповещения("ВыборПутиЗавершение2", ЭтотОбъект);
	Диалог.Показать(ОО);

КонецПроцедуры

&НаКлиенте
Процедура ВыборКорняЗавершение(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт 
	Если ВыбранныеФайлы <> Неопределено И ВыбранныеФайлы.Количество() = 1 Тогда
		НаборКонстант.ПутьККаталогуSVN = ВыбранныеФайлы[0];
		ЭтаФорма.Модифицированность = Истина;
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ВыборПутиЗавершение1(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт 
	Если ВыбранныеФайлы <> Неопределено И ВыбранныеФайлы.Количество() = 1 Тогда
		НаборКонстант.ПутьККаталогуСФайламиРасширений	= ОбработатьПуть(ВыбранныеФайлы[0]);
		ЭтаФорма.Модифицированность = Истина;
	КонецЕсли;
КонецПроцедуры

&НаКлиенте
Процедура ВыборПутиЗавершение2(ВыбранныеФайлы, ДополнительныеПараметры) Экспорт 
	Если ВыбранныеФайлы <> Неопределено И ВыбранныеФайлы.Количество() = 1 Тогда
		НаборКонстант.ПутьККаталогуШаблонов	= ОбработатьПуть(ВыбранныеФайлы[0]);
		ЭтаФорма.Модифицированность = Истина;
	КонецЕсли;
КонецПроцедуры

&НаСервере
Функция ОбработатьПуть(Путь)
	Возврат СтрЗаменить(Путь, НаборКонстант.ПутьККаталогуSVN, "");	
КонецФункции

&НаСервере
Функция ПутьСуществует(ОтносительныйПуть)
	АбсолютныйПуть = НаборКонстант.ПутьККаталогуSVN + ОтносительныйПуть;
	
	Ф = Новый Файл(АбсолютныйПуть);
	Возврат Ф.Существует();
КонецФункции


//&НаСервереБезКонтекста
//Процедура СохранитьНаСервере(Корень)
//	ХранилищеОбщихНастроек.Сохранить("Путь каталогу репозитория SVN", "ПутьККаталогуРепозитория", Корень); 
//КонецПроцедуры

&НаСервере
Процедура ПриЗаписиНаСервере(Отказ, ТекущийОбъект, ПараметрыЗаписи)
	//СохранитьНаСервере(Корень);
	
	Если Не ПутьСуществует(НаборКонстант.ПутьККаталогуСФайламиРасширений) Тогда
		Отказ = Истина;
		Сообщить(СтрШаблон("Относительный путь ""%1"" указан не верно", НаборКонстант.ПутьККаталогуСФайламиРасширений));	
	КонецЕсли;
	Если Не ПутьСуществует(НаборКонстант.ПутьККаталогуШаблонов) Тогда
		Отказ = Истина;
		Сообщить(СтрШаблон("Относительный путь ""%1"" указан не верно", НаборКонстант.ПутьККаталогуШаблонов));	
	КонецЕсли;

КонецПроцедуры



