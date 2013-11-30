
	.NOLIST				; Disable listfile generation.
	.include "tn85def.inc"		; Используем HAL Микроконтроллера.
	.include "macrobaselib.inc"	; Библиотека базовых Макроопределений.
	.LIST				; Reenable listfile generation.
	;.LISTMAC			; Turn macro expansion on?	(При отладке, отображать тела внедрённых Макросов в дизассемблированном коде - обычно, не следует включать, т.к. генерирует много мусора.)

	.include "data.inc"		; Данные программы: 
					;	Константы и псевдонимы Регистров; 
					;	Сегмент SRAM и Переменные; 
					;	Сегмент EEPROM.


;***************************************************************************
;*
;*  FLASH (сегмент кода)
;*
;***************************************************************************
			.CSEG

		.ORG	0x0000		; (RESET) 
		RJMP	RESET

		; Таблица векторов на обработчики прерываний:
		.ORG	INT0addr	; External Interrupt 0
		RETI
		.ORG	PCI0addr	; Pin change Interrupt Request 0
		RETI
		.ORG	OC1Aaddr	; Timer/Counter1 Compare Match 1A
		RETI
		.ORG	OVF1addr	; Timer/Counter1 Overflow
		RETI
		.ORG	OVF0addr	; Timer/Counter0 Overflow
		RJMP	TIMER0_OVERFLOW_HANDLER
		.ORG	ERDYaddr	; EEPROM Ready
		RETI
		.ORG	ACIaddr		; Analog comparator
		RETI
		.ORG	ADCCaddr	; ADC Conversion ready
		RETI
		.ORG	OC1Baddr	; Timer/Counter1 Compare Match B
		RETI
		.ORG	OC0Aaddr	; Timer/Counter0 Compare Match A
		RETI
		.ORG	OC0Baddr	; Timer/Counter0 Compare Match B
		RETI
		.ORG	WDTaddr		; Watchdog Time-out
		RETI
		.ORG	USI_STARTaddr	; USI START
		RETI
		.ORG	USI_OVFaddr	; USI Overflow
		RETI

		.ORG	INT_VECTORS_SIZE	; Конец таблицы прерываний


;***** BEGIN Interrupt handlers section ************************************

;---------------------------------------------------------------------------
;
; Прерывание: отсчёт полусекунд
;
;---------------------------------------------------------------------------

;----- Subroutine Register Variables

; Памятка: обработчик не портит содержимое РОН - поскольку защищает используемые регистры Стеком...

;----- Code

TIMER0_OVERFLOW_HANDLER:
		; Сохранить в Стеке регистры, которые используются в данном обработчике:
		PUSHF		; сохраняет часто используемые регистры: SREG и TEMP (TEMP1)
		PUSH	temp2	; регистр используется в INVB и др.
		PUSH	temp3	;       регистр используется в KEY_ENHANCE_TIME_FOR_ALL_BUTTONS
		PUSH	R28	; (YL)	регистр используется в KEY_ENHANCE_TIME_FOR_ALL_BUTTONS
		PUSH	R29	; (YH)	регистр используется в KEY_ENHANCE_TIME_FOR_ALL_BUTTONS


		; Головная процедура конвеера обработки кнопок:	Наращивает таймеры для удерживаемых кнопок (запускать каждые полсекунды)
		RCALL	KEY_ENHANCE_TIME_FOR_ALL_BUTTONS


		; Выход из обработчика
		POP	R29
		POP	R28
		POP	temp3
		POP	temp2
		POPF
		RETI	


;***** END Interrupt handlers section 


;***** ИНИЦИАЛИЗАЦИЯ *******************************************************
RESET:
		WDTOFF		; Disable Watchdog timer permanently (ensure)
		STACKINIT	; Инициализация стека
		RAMFLUSH	; Очистка памяти
		GPRFLUSH	; Очистка РОН


;***** BEGIN Internal Hardware Init ****************************************

; Инициализация Портов:

		OUTI	PORTB,	0				; обнулить регистр выходных данных ПортаB (начальное положение)
		OUTI	DDRB,	(1<<PinClock)			; вывод PinClock - на "выход" (OUT)


; Инициализация Timer/Counter0, который считает секунды:

		SETB	TIMSK,	TOIE0				; Разрешаем прерывания таймера: Overflow Interrupt Enable 
		OUTI	TCCR0B,	(0<<CS02)|(1<<CS01)|(1<<CS00)	; Запустить таймер: Предделитель = clkIO/64 (Источник = From prescaler, от Тактовой частоты)
								; Примечание: Значение Предделителя:
								;	CLK_XTAL = 32768 Hz
								;	TIMER1_PERIOD  = 0.5sec (итого, два переполнения в секунду)
								;	TIMER1_DIVIDER = CLK_XTAL * TIMER0_PERIOD / 256	= 64	(Результат должен получиться целым, степенью двойки, причём, значением поддерживаемым Предделителем Таймера!)
		;RCALL	RESET_TIMER0				; Сбросить таймер, чтобы начать отсчёт с начала секунды (не обязательно)

;***** END Internal Hardware Init 


;***** BEGIN External Hardware Init ****************************************
;***** END External Hardware Init 


;***** BEGIN "Run once" section (запуск фоновых процессов) *****************

		SEI  ; Разрешаем глобальные прерывания

;***** END "Run once" section 

;***** BEGIN "Main" section ************************************************

MAIN:
		; (Суперцикл: реализующий сканирование Кнопок и переключение Режимов)

		; Сканирование Кнопок
		OUTI	DKeyScanCnt,	20				; DKeyScanCnt = количество циклов "сканирования кнопок".	(а затем будет один цикл "реакции на события")
	LoopKeyScan__MAIN:
		RCALL	KEY_SCAN_INPUT					; Головная процедура конвеера обработки кнопок: Сканирует физические кнопки и устанавливает их статус-регистры (запускать часто)
		DEC8M	DKeyScanCnt
		BRNE	LoopKeyScan__MAIN
		
		; Переключение Режимов ("реакция на события")
		RCALL	SWITCH_MODES					; Важно: DKeyScanCnt, выше, следует подбирать так, чтобы "SWITCH_MODES" выполнялся ~10-20раз/сек. Тогда будет эргономичная "инерционность" реакции кнопок (что особенно важно: для работы кнопки "DButtonStartStatus", при вводе значения Параметра, в режиме Настройки)...
		
		RJMP	MAIN						

		; (обработка событий завершена)


;***** END "Main" section 

;***** BEGIN Procedures section ********************************************

	; Внимание! В отличие от Макросов, Код процедур, всегда и полностью, 
	; включается в сегмент данных программы - занимает место! 
	; Поэтому, здесь должны быть включены только те процедуры, которые 
	; реально используются. (Остальные - следует /* закомментировать */.)

	.include "celeronkeyinputlib.inc"	; Библиотека процедур для интеллектуальной обработки ВВОДА: сканирование Кнопок и Энкодеров.



;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;
; Процедура переключения режимов интерфейса ("реакция на события")
; 
; 	SWITCH_MODES
;
;---------------------------------------------------------------------------

;----- Subroutine Register Variables

; Без параметров.

; Памятка: также использует/портит содержимое регистров TEMP1, TEMP2... 
.def	ExtendDataByValue = R25

;----- Code


SWITCH_MODES:

		;** Подсистема: "переключение Функций"
	;SwitchFunc_RTC_Alarm__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonRTCStatus,	BSC_ShortPress
		OR_BUTTON_HAVE_STATUS	DButtonRTCStatus,	BSC_LongHold
		BRTC	SwitchFunc_Timer1__SWITCH_MODES				; если кнопки не были нажаты...
		;OUTI	DButtonRTCStatus,	0b00000000			; После обработки состояния кнопки - сделать "НЕМЕДЛЕННЫЙ СБРОС" её статусного регистра.	(Примечание: здесь используется вариант "СБРОС в ноль" - вследствие чего, статус-регистр кнопки будет обнулён НЕМЕДЛЕННО, даже если кнопка ещё удерживается в BSC_LongHold.	Пояснение: Здесь отсутствует "триггер защёлка-состояния", заставляющий пользователя отпускать кнопку, перед следующим нажатием - хотя, обычно, это полезно: ибо предотвращает серии ошибочных повторных срабатываний кнопки!) 
										; 	Пусть, здесь, Я УМЫШЛЕННО ХОЧУ ОСОБОЕ ПОВЕДЕНИЕ: когда пользователь просто удерживает долго кнопку DButtonRTCStatus, чтобы функция автоматически периодически переключалась RTC<->Alarm, каждые CShortButtonTouchDuration полусекунд - Использовал вариант: "НЕМЕДЛЕННЫЙ СБРОС"...	Протестировал "user experience": Нет, неудобно и глючно! Когда я удерживаю некую кнопку, то функции циклически переключаются F1->F2->F1->... Причём, когда я попадаю в нужную мне функцию, скажем F2, то я отпускаю удерживаемую кнопку - однако, тут же срабатывает событие "BSC_ShortPress", и функция лишний раз переключается в F1 (неудобно, нужно вводить коррекцию-откат)! 
										; 	В итоге, решил всё-таки отказаться, здесь, от варианта ""НЕМЕДЛЕННЫЙ СБРОС", в пользу концептуально-правильному "ОТЛОЖЕННОМУ СБРОСУ".
		OUTI	DButtonRTCStatus,	0b11111111			; После обработки состояния кнопки - сделать "ОТЛОЖЕННЫЙ СБРОС" её статусного регистра.		(Примечание: это другой вариант поведения, "с триггером защёлкой-состояния": заставлять пользователя отпускать кнопку, перед следующим нажатием - что обычно полезно, ибо предотвращает серии ошибочных повторных срабатываний кнопки...)
		; <здесь располагается прикладной код обработки События>
		RJMP	EventButtonHavePressed__SWITCH_MODES


	SwitchFunc_Timer1__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonTimer1Status,	BSC_ShortPress
		OR_BUTTON_HAVE_STATUS	DButtonTimer1Status,	BSC_LongHold
		BRTC	SwitchFunc_Timer2__SWITCH_MODES				; если кнопки не были нажаты...
		OUTI	DButtonTimer1Status,	0b11111111			; После обработки состояния кнопки - сделать "ОТЛОЖЕННЫЙ СБРОС" её статусного регистра.
		; <здесь располагается прикладной код обработки События>
		RJMP	EventButtonHavePressed__SWITCH_MODES


	SwitchFunc_Timer2__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonTimer2Status,	BSC_ShortPress		
		OR_BUTTON_HAVE_STATUS	DButtonTimer2Status,	BSC_LongHold		
		BRTC	SwitchFunc_End__SWITCH_MODES				; если кнопки не были нажаты...
		OUTI	DButtonTimer2Status,	0b11111111			; После обработки состояния кнопки - сделать "ОТЛОЖЕННЫЙ СБРОС" её статусного регистра.
		; <здесь располагается прикладной код обработки События>
		RJMP	EventButtonHavePressed__SWITCH_MODES

	SwitchFunc_End__SWITCH_MODES:




		; Обработка МОДИФИКАЦИИ ЧИСЛОВОГО ЗНАЧЕНИЯ в памяти Энкодером
		LDS	ExtendDataByValue,	DEncoder0Counter
		TST	ExtendDataByValue
		BREQ	NotEncoder__SWITCH_MODE_SETTINGS
		OUTI	DEncoder0Counter,	0				; замечу: после прибавления к "ячейке памяти" этой аддитивной добавки, регистр "счётчика тиков" энкодера обнуляется.
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
	NotEncoder__SWITCH_MODE_SETTINGS:


		; Обработка МОДИФИКАЦИИ ЧИСЛОВОГО ЗНАЧЕНИЯ в памяти "Интеллектуальной Кнопкой"
		; (однократное нажатие)
		IF_BUTTON_HAVE_STATUS	DButtonStartStatus,	BSC_ShortPress
		BRTC	Button2__SWITCH_MODE_SETTINGS				; если кнопки не были нажаты...
		OUTI	DButtonStartStatus,	0b11111111			; После обработки состояния кнопки - сделать "ОТЛОЖЕННЫЙ СБРОС" её статусного регистра.
		LDI	ExtendDataByValue,	1
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
		; (инерционный ввод, при удержании)
	Button2__SWITCH_MODE_SETTINGS:
		IF_BUTTON_HAVE_STATUS	DButtonStartStatus,	BSC_LongHold
		BRTC	NotButton__SWITCH_MODE_SETTINGS				; если кнопки не были нажаты...
		;OUTI	DButtonStartStatus,	0b11111111			; Внимание: в этом случае, статус кнопки не сбрасываем - пусть продолжает считаться "нажатой" и набегает "таймер удержания"...
		LDI	ExtendDataByValue,	1
		; (хочу различать также ситуации "очень длительных" удерживаний кнопки)
		LDS	temp1,	DButtonStartStatus
		ANDI	temp1,	0b11111<<BUTTON_HOLDING_TIME			; выделить "счётчик времени удержания кнопки"
		CPI	temp1,	8						; при удержании кнопки свыше >=4сек, показания набегают в 2 раза бытрее.
		BRLO	SlowSpeedYet__SWITCH_MODE_SETTINGS
		LSL	ExtendDataByValue
		CPI	temp1,	16						; при удержании кнопки свыше >=8сек, показания набегают ещё в 2 раза бытрее.
		BRLO	SlowSpeedYet__SWITCH_MODE_SETTINGS
		LSL	ExtendDataByValue
	SlowSpeedYet__SWITCH_MODE_SETTINGS:
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
	NotButton__SWITCH_MODE_SETTINGS:
		RJMP	Exit__SWITCH_MODES


	ModifyData__SWITCH_MODE_SETTINGS:
		; <здесь располагается прикладной код модификации "ячейки памяти" += значение из регистра ExtendDataByValue >




		;** (обработка событий кнопок завершена)
		RJMP	Exit__SWITCH_MODES
EventButtonHavePressed__SWITCH_MODES:
		; здесь, можно расположить код неспецифической реакции на нажатие любой кнопки: например, сброс таймеров "спящего режима" и т.п.
Exit__SWITCH_MODES:
		; если нажатий кнопок не было зафиксировано, то просто выход
		RET



;***** END Procedures section 
; coded by (c) Celeron, 2013 @ http://we.easyelectronics.ru/my/Celeron/
