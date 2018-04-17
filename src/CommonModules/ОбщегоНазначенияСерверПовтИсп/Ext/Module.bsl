﻿Функция ПолучитьЭффективностиСотрудников() Экспорт 
	Запрос = Новый Запрос;
	Запрос.МенеджерВременныхТаблиц = Новый МенеджерВременныхТаблиц();
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	КомандаСостав.Сотрудник КАК Сотрудник
		|ПОМЕСТИТЬ СоставКоманд
		|ИЗ
		|	Справочник.Команда.Состав КАК КомандаСостав
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Команда КАК Команда
		|		ПО КомандаСостав.Ссылка = Команда.Ссылка
		|ГДЕ
		|	НЕ Команда.ПометкаУдаления
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗЛИЧНЫЕ
		|	ИсторияИзмененияСтатусов.Автор КАК Сотрудник,
		|	Задачи.Оценка КАК Оценка,
		|	Задачи.Ссылка КАК Ссылка
		|ПОМЕСТИТЬ ДанныеЗадач
		|ИЗ
		|	РегистрСведений.ИсторияИзмененияСтатусов КАК ИсторияИзмененияСтатусов
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ СоставКоманд КАК СоставКоманд
		|		ПО ИсторияИзмененияСтатусов.Автор = СоставКоманд.Сотрудник
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Задачи КАК Задачи
		|		ПО ИсторияИзмененияСтатусов.Задача = Задачи.Ссылка
		|ГДЕ
		|	ИсторияИзмененияСтатусов.ДатаСобытия МЕЖДУ &НачалоСобытия И &КонецСобытия
		|	И ИсторияИзмененияСтатусов.КонечныйСтатус В(&КонечныеСтатусы)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ДанныеЗадач.Сотрудник КАК Сотрудник,
		|	СУММА(ДанныеЗадач.Оценка) КАК ОценкаОбщая,
		|	ВЫРАЗИТЬ(СУММА(ДанныеЗадач.Оценка) / КОЛИЧЕСТВО(*) КАК ЧИСЛО(10, 2)) КАК ОценкаСредняя,
		|	КОЛИЧЕСТВО(*) КАК Количество
		|ПОМЕСТИТЬ ДанныеЗадачГруппировкаПоСотруднику
		|ИЗ
		|	ДанныеЗадач КАК ДанныеЗадач
		|
		|СГРУППИРОВАТЬ ПО
		|	ДанныеЗадач.Сотрудник
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	СУММА(ДанныеЗадач.Оценка) КАК ОценкаОбщая,
		|	ВЫРАЗИТЬ(СУММА(ДанныеЗадач.Оценка) / КОЛИЧЕСТВО(*) КАК ЧИСЛО(10, 2)) КАК ОценкаСредняя,
		|	КОЛИЧЕСТВО(*) КАК Количество
		|ПОМЕСТИТЬ ДанныеЗадачГруппировка
		|ИЗ
		|	ДанныеЗадач КАК ДанныеЗадач
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ДанныеЗадач.Сотрудник КАК Сотрудник,
		|	МАКСИМУМ(ДанныеЗадачГруппировка.ОценкаОбщая) КАК ОценкаОбщая,
		|	МАКСИМУМ(ДанныеЗадачГруппировка.ОценкаСредняя) КАК ОценкаСредняя,
		|	СУММА(ВЫБОР
		|			КОГДА ДанныеЗадач.Оценка > ЕСТЬNULL(ДанныеЗадачГруппировка.ОценкаСредняя, 0)
		|				ТОГДА 1
		|			ИНАЧЕ 0
		|		КОНЕЦ) КАК КолВоЗадачВышеСреднего,
		|	МАКСИМУМ(ДанныеЗадачГруппировка.Количество) КАК Количество,
		|	ДанныеЗадачГруппировкаПоСотруднику.Количество КАК КоличествоПоСотруднику,
		|	(ВЫРАЗИТЬ(ДанныеЗадачГруппировкаПоСотруднику.Количество / МАКСИМУМ(ДанныеЗадачГруппировка.Количество) КАК ЧИСЛО(10, 2))) * 100 КАК ОтношениеКоличеств
		|ИЗ
		|	ДанныеЗадач КАК ДанныеЗадач
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ ДанныеЗадачГруппировкаПоСотруднику КАК ДанныеЗадачГруппировкаПоСотруднику
		|		ПО ДанныеЗадач.Сотрудник = ДанныеЗадачГруппировкаПоСотруднику.Сотрудник,
		|	ДанныеЗадачГруппировка КАК ДанныеЗадачГруппировка
		|
		|СГРУППИРОВАТЬ ПО
		|	ДанныеЗадач.Сотрудник,
		|	ДанныеЗадачГруппировкаПоСотруднику.Количество";
	
	Запрос.УстановитьПараметр("КонецСобытия", КонецКвартала(ТекущаяДатаСеанса()));    
	Запрос.УстановитьПараметр("НачалоСобытия", НачалоКвартала(ТекущаяДатаСеанса()));
	Запрос.УстановитьПараметр("КонечныеСтатусы", СтрРазделить("Закрыт,Сделан,Предоставлено ПР", ","));
	
	Ответ = Новый Соответствие();
	РезультатЗапроса = Запрос.Выполнить().Выгрузить();
	РезультатЗапроса.Колонки.Добавить("Эффективность");
	Для Каждого Стр Из РезультатЗапроса Цикл
		Стр.Эффективность = Стр.ОтношениеКоличеств * (Стр.КоличествоПоСотруднику / Стр.КолВоЗадачВышеСреднего);
	КонецЦикла;
	
	Запрос.Текст = "ВЫБРАТЬ
	               |	КОЛИЧЕСТВО(*) КАК Количество,
	               |	ДанныеЗадач.Сотрудник КАК Сотрудник
	               |ИЗ
	               |	ДанныеЗадач КАК ДанныеЗадач
	               |		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ИсторияИзмененияСтатусов КАК ИсторияИзмененияСтатусов
	               |		ПО ДанныеЗадач.Ссылка = ИсторияИзмененияСтатусов.Задача
	               |ГДЕ
	               |	ИсторияИзмененияСтатусов.ДатаСобытия МЕЖДУ &НачалоСобытия И &КонецСобытия
	               |	И ИсторияИзмененияСтатусов.ИсходныйСтатус = &КонечныйСтатус
	               |
	               |СГРУППИРОВАТЬ ПО
	               |	ДанныеЗадач.Сотрудник";
	
	Запрос.УстановитьПараметр("КонечныйСтатус", "Закрыт");
	ТЗ = Запрос.Выполнить().Выгрузить();
	
	Для Каждого Стр Из РезультатЗапроса Цикл
		КоличествоВозвратов = ТЗ.Скопировать(ТЗ.НайтиСтроки(Новый Структура("Сотрудник", Стр.Сотрудник))).Итог("Количество");
		Стр.Эффективность = Стр.Эффективность - КоличествоВозвратов;
	КонецЦикла;
	
	Возврат РезультатЗапроса;
КонецФункции

&НаСервере
Функция ПолучитьПроцентыЗагруженности() Экспорт 
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	КомандаСостав.Сотрудник КАК Сотрудник
		|ПОМЕСТИТЬ СоставКоманд
		|ИЗ
		|	Справочник.Команда.Состав КАК КомандаСостав
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Команда КАК Команда
		|		ПО КомандаСостав.Ссылка = Команда.Ссылка
		|ГДЕ
		|	НЕ Команда.ПометкаУдаления
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	Релизы.ДатаНачала КАК ДатаНачала,
		|	Релизы.ДатаРелиза КАК ДатаРелиза,
		|	СУММА(ГрафикРаботы.РабочихЧасов) КАК РабочихЧасов,
		|	ГрафикРаботы.Пользователь КАК Пользователь
		|ПОМЕСТИТЬ ЗагрузкаНаРелиз
		|ИЗ
		|	Справочник.Релизы КАК Релизы
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ГрафикРаботы КАК ГрафикРаботы
		|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ СоставКоманд КАК СоставКоманд
		|			ПО ГрафикРаботы.Пользователь = СоставКоманд.Сотрудник
		|		ПО (НАЧАЛОПЕРИОДА(Релизы.ДатаНачала, ДЕНЬ) <= ГрафикРаботы.Дата)
		|			И (КОНЕЦПЕРИОДА(Релизы.ДатаРелиза, ДЕНЬ) >= ГрафикРаботы.Дата)
		|ГДЕ
		|	&ТекДата МЕЖДУ Релизы.ДатаНачала И Релизы.ДатаРелиза
		|
		|СГРУППИРОВАТЬ ПО
		|	Релизы.ДатаРелиза,
		|	Релизы.ДатаНачала,
		|	ГрафикРаботы.Пользователь
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ
		|	ВЫРАЗИТЬ(СУММА(Задачи.Оценка) / МАКСИМУМ(ЗагрузкаНаРелиз.РабочихЧасов) * 100 КАК ЧИСЛО(10, 2)) КАК Процент,
		|	ЗагрузкаНаРелиз.Пользователь КАК Пользователь
		|ИЗ
		|	Справочник.Задачи КАК Задачи
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ ЗагрузкаНаРелиз КАК ЗагрузкаНаРелиз
		|		ПО Задачи.Исполнитель = ЗагрузкаНаРелиз.Пользователь
		|ГДЕ
		|	НЕ Задачи.Статус В (&СтатусыИсключения)
		|	И НЕ Задачи.ПометкаУдаления
		|
		|СГРУППИРОВАТЬ ПО
		|	ЗагрузкаНаРелиз.Пользователь";
	
	Запрос.УстановитьПараметр("ТекДата", ТекущаяДатаСеанса());
	Запрос.УстановитьПараметр("СтатусыИсключения", СтрРазделить("Закрыт,Сделан,Предоставлено ПР", ","));
	
	РезультатЗапроса = Запрос.Выполнить();
	Возврат РезультатЗапроса.Выгрузить();
КонецФункции