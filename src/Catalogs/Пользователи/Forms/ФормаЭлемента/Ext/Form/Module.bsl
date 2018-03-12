﻿
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	СпрОбъект = РеквизитФормыВЗначение("Объект");
	ДД = СпрОбъект.Аватар.Получить();
	Если ДД <> Неопределено Тогда
		Картинка = ПоместитьВоВременноеХранилище(ДД);
	КонецЕсли;
	Для Каждого Пользователь Из ПользователиИнформационнойБазы.ПолучитьПользователей() Цикл
		Элементы.ПользовательИБ.СписокВыбора.Добавить(Пользователь.УникальныйИдентификатор, Пользователь.ПолноеИмя);
	КонецЦикла;
	ОбновитьПредставлениеПользователяИБ();
КонецПроцедуры

&НаСервере
Процедура ОбновитьПредставлениеПользователяИБ()
	
	Если ЗначениеЗаполнено(Объект.ПользовательИБ) Тогда
		ПользовательИБ = ПользователиИнформационнойБазы.НайтиПоУникальномуИдентификатору(Объект.ПользовательИБ);
		ПредставлениеПользователяИБ = ?(ПользовательИБ = Неопределено, "", ПользовательИБ.ПолноеИмя);
	КонецЕсли;

КонецПроцедуры

&НаКлиенте
Процедура ПослеЗаписи(ПараметрыЗаписи)
	Оповестить("ОбновитьВкладки");
КонецПроцедуры


&НаКлиенте
Процедура ПользовательИБОбработкаВыбора(Элемент, ВыбранноеЗначение, СтандартнаяОбработка)
	СтандартнаяОбработка = Ложь;
	Объект.ПользовательИБ = ВыбранноеЗначение;
	ОбновитьПредставлениеПользователяИБ();
КонецПроцедуры

&НаКлиенте
Процедура ПередЗаписью(Отказ, ПараметрыЗаписи)
	Если Не ЗначениеЗаполнено(ПредставлениеПользователяИБ) Тогда
		Объект.ПользовательИБ = Неопределено;		
	КонецЕсли;
КонецПроцедуры




