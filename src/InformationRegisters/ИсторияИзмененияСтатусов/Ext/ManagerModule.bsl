﻿#Если Сервер Или ТолстыйКлиентОбычноеПриложение Или ВнешнееСоединение Тогда
	
	Процедура ОбновитьЗаписи(Номера = Неопределено) Экспорт 	
		СписокЗадач = Новый Массив();
		Если Номера = Неопределено Тогда
			СписокЗадач = ВзаимодействиеC_JIRA_КлиентСервер.ПолучитьЗадачиОбновленныеСегодня(Истина);
		Иначе
			Для Каждого Блок Из ОбщегоНазначенияКлиентСервер.РазбитьМассив(Номера, 10) Цикл
				СписокЗадачВрем = ВзаимодействиеC_JIRA_КлиентСервер.ПолучитьСписокЗадач(СтрШаблон("key in(%1)", СтрСоединить(Блок, ",")), Истина);
				СписокЗадач = ОбщегоНазначенияКлиентСервер.СлитьМассивы(СписокЗадач, СписокЗадачВрем);
			КонецЦикла;	
		КонецЕсли;
		
		Для Каждого Задача Из СписокЗадач Цикл
			НачатьТранзакцию();
			Попытка
				Лог = Задача["changelog"];
				Если Лог = Неопределено Тогда
					Продолжить;	
				КонецЕсли;
				
				Набор = РегистрыСведений.ИсторияИзмененияСтатусов.СоздатьНаборЗаписей();
				ЗадачаСсылка = Справочники.Задачи.НайтиПоКоду(Задача["key"]);
				Набор.Отбор.Задача.Установить(ЗадачаСсылка);
				
				Для Каждого ЗаписьЛога Из Лог["histories"] Цикл
					Для Каждого Изменение Из ЗаписьЛога["items"] Цикл
						Если НРег(Изменение["field"]) <> "status" Тогда
							Продолжить;	
						КонецЕсли;
						
						Запись = Набор.Добавить();
						Запись.НомерЗаписи = Набор.Количество();
						Запись.Задача = ЗадачаСсылка;
						Запись.Автор = Справочники.Пользователи.НайтиСоздатьПользователя(ЗаписьЛога["author"]);
						Запись.ДатаСобытия = ВзаимодействиеC_JIRA_КлиентСервер.ПреобразоватьВДату(ЗаписьЛога["created"]);
						Запись.ИсходныйСтатус = Изменение["fromString"];
						Запись.КонечныйСтатус = Изменение["toString"];
					КонецЦикла;
				КонецЦикла;
				
				ДатаСоздания = ВзаимодействиеC_JIRA_КлиентСервер.ПреобразоватьВДату(Задача["fields"]["created"]);
				
				ТЗ = Набор.Выгрузить();
				ТЗ.Сортировать("ДатаСобытия");
				Для а = 0 По ТЗ.Количество()-1 Цикл
					Если а = 0 Тогда // Первая запись
						ТЗ[а].МинутПробылВИсходномСтатусе = (ТЗ[а].ДатаСобытия - ДатаСоздания) / 60;
					Иначе 
						ТЗ[а].МинутПробылВИсходномСтатусе = (ТЗ[а].ДатаСобытия - ТЗ[а-1].ДатаСобытия) / 60;	
					КонецЕсли;
				КонецЦикла;
				
				Набор.Загрузить(ТЗ);
				Набор.Записать(Истина);
				
				Если СтрРазделить("ЗАКРЫТ,ПРЕДОСТАВЛЕНО ПР", ",").Найти(ВРег(ЗадачаСсылка.Статус)) <> Неопределено Тогда
					ОбонвитьВерсииВЗадаче(ЗадачаСсылка);
				КонецЕсли;
				
				ЗафиксироватьТранзакцию();
			Исключение
				ОтменитьТранзакцию();
				ВызватьИсключение;
			КонецПопытки;
		КонецЦикла;
	КонецПроцедуры
	
	
	Процедура ОбонвитьВерсииВЗадаче(ЗадачаСсылка)
		Если Не ЗначениеЗаполнено(ЗадачаСсылка) Тогда
			Возврат;	
		КонецЕсли;
		
		// Если по задаче был коммит, значит
		// Получаем максимальную версию из задачи, если она меньше текущей, тогда ничего не делаем. это нужно для отслеживания коммитов после выпуска версий.
		// Если больше чем текущая, тогда уравниваем версии.
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Задачи.Ссылка КАК Задача,
		|	Сабтаск.Ссылка КАК Сабтаск,
		|	Задачи.Код КАК ЗадачаНомер,
		|	Сабтаск.Код КАК СабтаскНомер
		|ПОМЕСТИТЬ ЗадачаИСабтаски
		|ИЗ
		|	Справочник.Задачи КАК Задачи
		|		ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Задачи КАК Сабтаск
		|		ПО Задачи.Ссылка = Сабтаск.Родитель
		|ГДЕ
		|	Задачи.Ссылка = &ЗадачаСсылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗЛИЧНЫЕ
		|	ЗадачаИСабтаски.Задача КАК Задача
		|ПОМЕСТИТЬ КоммитыПоЗадаче
		|ИЗ
		|	Справочник.БФТ_НаборыИзменений.НаборИзменений КАК БФТ_НаборыИзмененийНаборИзменений
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.БФТ_НаборыИзменений КАК БФТ_НаборыИзменений
		|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ ЗадачаИСабтаски КАК ЗадачаИСабтаски
		|			ПО (БФТ_НаборыИзменений.Код = ЗадачаИСабтаски.ЗадачаНомер
		|					ИЛИ БФТ_НаборыИзменений.Код = ЗадачаИСабтаски.СабтаскНомер)
		|		ПО БФТ_НаборыИзмененийНаборИзменений.Ссылка = БФТ_НаборыИзменений.Ссылка
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.БФТ_ИзмененияРепозитория.СрезПоследних КАК БФТ_ИзмененияРепозиторияСрезПоследних
		|		ПО БФТ_НаборыИзмененийНаборИзменений.НомерРевизии = БФТ_ИзмененияРепозиторияСрезПоследних.НомерРевизии
		|			И БФТ_НаборыИзмененийНаборИзменений.ИзменениеКонфигурации = БФТ_ИзмененияРепозиторияСрезПоследних.ИзменениеКонфигурации
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ ПЕРВЫЕ 1
		|	ЗадачиВерсии.Версия КАК Версия
		|ИЗ
		|	Справочник.Задачи.Версии КАК ЗадачиВерсии
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Релизы КАК Релизы
		|		ПО ЗадачиВерсии.Версия = Релизы.Ссылка
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ ЗадачаИСабтаски КАК Задачи
		|		ПО ЗадачиВерсии.Ссылка = Задачи.Задача,
		|	КоммитыПоЗадаче КАК КоммитыПоЗадаче
		|ГДЕ
		|	Релизы.ДатаРелиза > &ДатаРелиза
		|
		|УПОРЯДОЧИТЬ ПО
		|	Релизы.ДатаРелиза УБЫВ";
		
		ТекРазрабатываемаяВерсия = Справочники.Релизы.ТекущаяВерсияРазработка();
		Если ТекРазрабатываемаяВерсия = Неопределено Тогда
			Возврат;	
		КонецЕсли;
		
		Запрос.Параметры.Вставить("ДатаРелиза", ТекРазрабатываемаяВерсия.ДатаРелиза);
		Запрос.Параметры.Вставить("ЗадачаСсылка", ЗадачаСсылка);
		Выборка = Запрос.Выполнить().Выбрать();
		Если Выборка.Следующий() Тогда
			Задача = ЗадачаСсылка;
			Если ЗначениеЗаполнено(ЗадачаСсылка.Родитель) Тогда
				Задача = ЗадачаСсылка.Родитель;
			КонецЕсли;
			
			Справочники.Релизы.ПереместитьВВерсию(ОбщегоНазначенияКлиентСервер.ЗначениеВМассиве(Задача), ТекРазрабатываемаяВерсия, Истина);
		КонецЕсли;		
	КонецПроцедуры
	
	
#КонецЕсли