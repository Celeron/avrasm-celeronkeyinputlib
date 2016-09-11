
	.NOLIST				; Disable listfile generation.
	.include "tn85def.inc"		; ���������� HAL ����������������.
	.include "macrobaselib.inc"	; ���������� ������� ����������������.
	.LIST				; Reenable listfile generation.
	;.LISTMAC			; Turn macro expansion on?	(��� �������, ���������� ���� ��������� �������� � ������������������� ���� - ������, �� ������� ��������, �.�. ���������� ����� ������.)

	.include "data.inc"		; ������ ���������: 
					;	��������� � ���������� ���������; 
					;	������� SRAM � ����������; 
					;	������� EEPROM.


;***************************************************************************
;*
;*  FLASH (������� ����)
;*
;***************************************************************************
			.CSEG

		.ORG	0x0000		; (RESET) 
		RJMP	RESET

		; ������� �������� �� ����������� ����������:
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

		.ORG	INT_VECTORS_SIZE	; ����� ������� ����������


;***** BEGIN Interrupt handlers section ************************************

;---------------------------------------------------------------------------
;
; ����������: ������ ����������
;
;---------------------------------------------------------------------------

;----- Subroutine Register Variables

; �������: ���������� �� ������ ���������� ��� - ��������� �������� ������������ �������� ������...

;----- Code

TIMER0_OVERFLOW_HANDLER:
		; ��������� � ����� ��������, ������� ������������ � ������ �����������:
		PUSHF		; ��������� ����� ������������ ��������: SREG � TEMP (TEMP1)
		PUSH	temp2	; ������� ������������ � INVB � ��.
		PUSH	temp3	;       ������� ������������ � KEY_ENHANCE_TIME_FOR_ALL_BUTTONS
		PUSH	R28	; (YL)	������� ������������ � KEY_ENHANCE_TIME_FOR_ALL_BUTTONS
		PUSH	R29	; (YH)	������� ������������ � KEY_ENHANCE_TIME_FOR_ALL_BUTTONS


		; �������� ��������� �������� ��������� ������:	���������� ������� ��� ������������ ������ (��������� ������ ����������)
		RCALL	KEY_ENHANCE_TIME_FOR_ALL_BUTTONS


		; ����� �� �����������
		POP	R29
		POP	R28
		POP	temp3
		POP	temp2
		POPF
		RETI	


;***** END Interrupt handlers section 


;***** ������������� *******************************************************
RESET:
		WDTOFF		; Disable Watchdog timer permanently (ensure)
		STACKINIT	; ������������� �����
		RAMFLUSH	; ������� ������
		GPRFLUSH	; ������� ���


;***** BEGIN Internal Hardware Init ****************************************

; ������������� ������:

		OUTI	PORTB,	0				; �������� ������� �������� ������ �����B (��������� ���������)
		OUTI	DDRB,	(1<<PinClock)			; ����� PinClock - �� "�����" (OUT)


; ������������� Timer/Counter0, ������� ������� �������:

		SETB	TIMSK,	TOIE0				; ��������� ���������� �������: Overflow Interrupt Enable 
		OUTI	TCCR0B,	(0<<CS02)|(1<<CS01)|(1<<CS00)	; ��������� ������: ������������ = clkIO/64 (�������� = From prescaler, �� �������� �������)
								; ����������: �������� ������������:
								;	CLK_XTAL = 32768 Hz
								;	TIMER1_PERIOD  = 0.5sec (�����, ��� ������������ � �������)
								;	TIMER1_DIVIDER = CLK_XTAL * TIMER0_PERIOD / 256	= 64	(��������� ������ ���������� �����, �������� ������, ������, ��������� �������������� ������������� �������!)
		;RCALL	RESET_TIMER0				; �������� ������, ����� ������ ������ � ������ ������� (�� �����������)

;***** END Internal Hardware Init 


;***** BEGIN External Hardware Init ****************************************
;***** END External Hardware Init 


;***** BEGIN "Run once" section (������ ������� ���������) *****************

		SEI  ; ��������� ���������� ����������

;***** END "Run once" section 

;***** BEGIN "Main" section ************************************************

MAIN:
		; (���������: ����������� ������������ ������ � ������������ �������)

		; ������������ ������
		OUTI	DKeyScanCnt,	20				; DKeyScanCnt = ���������� ������ "������������ ������".	(� ����� ����� ���� ���� "������� �� �������")
	LoopKeyScan__MAIN:
		RCALL	KEY_SCAN_INPUT					; �������� ��������� �������� ��������� ������: ��������� ���������� ������ � ������������� �� ������-�������� (��������� �����)
		DEC8M	DKeyScanCnt
		BRNE	LoopKeyScan__MAIN
		
		; ������������ ������� ("������� �� �������")
		RCALL	SWITCH_MODES					; �����: DKeyScanCnt, ����, ������� ��������� ���, ����� "SWITCH_MODES" ���������� ~10-20���/���. ����� ����� ������������ "�������������" ������� ������ (��� �������� �����: ��� ������ ������ "DButtonStartStatus", ��� ����� �������� ���������, � ������ ���������)...
		
		RJMP	MAIN						

		; (��������� ������� ���������)


;***** END "Main" section 

;***** BEGIN Procedures section ********************************************

	; ��������! � ������� �� ��������, ��� ��������, ������ � ���������, 
	; ���������� � ������� ������ ��������� - �������� �����! 
	; �������, ����� ������ ���� �������� ������ �� ���������, ������� 
	; ������� ������������. (��������� - ������� /* ���������������� */.)

	.include "celeronkeyinputlib.inc"	; ���������� �������� ��� ���������������� ��������� �����: ������������ ������ � ���������.



;---------------------------------------------------------------------------
;---------------------------------------------------------------------------
;
; ��������� ������������ ������� ���������� ("������� �� �������")
; 
; 	SWITCH_MODES
;
;---------------------------------------------------------------------------

;----- Subroutine Register Variables

; ��� ����������.

; �������: ����� ����������/������ ���������� ��������� TEMP1, TEMP2... 
.def	ExtendDataByValue = R25

;----- Code


SWITCH_MODES:

		;** ����������: "������������ �������"
	;SwitchFunc_RTC_Alarm__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonRTCStatus,	BSC_ShortPress
		OR_BUTTON_HAVE_STATUS	DButtonRTCStatus,	BSC_LongHold
		BRTC	SwitchFunc_Timer1__SWITCH_MODES				; ���� ������ �� ���� ������...
		;OUTI	DButtonRTCStatus,	0b00000000			; ����� ��������� ��������� ������ - ������� "����������� �����" � ���������� ��������.	(����������: ����� ������������ ������� "����� � ����" - ���������� ����, ������-������� ������ ����� ������ ����������, ���� ���� ������ ��� ������������ � BSC_LongHold.	���������: ����� ����������� "������� �������-���������", ������������ ������������ ��������� ������, ����� ��������� �������� - ����, ������, ��� �������: ��� ������������� ����� ��������� ��������� ������������ ������!) 
										; 	�����, �����, � ��������� ���� ������ ���������: ����� ������������ ������ ���������� ����� ������ DButtonRTCStatus, ����� ������� ������������� ������������ ������������� RTC<->Alarm, ������ CShortButtonTouchDuration ���������� - ����������� �������: "����������� �����"...	������������� "user experience": ���, �������� � ������! ����� � ��������� ����� ������, �� ������� ���������� ������������� F1->F2->F1->... ������, ����� � ������� � ������ ��� �������, ������ F2, �� � �������� ������������ ������ - ������, ��� �� ����������� ������� "BSC_ShortPress", � ������� ������ ��� ������������� � F1 (��������, ����� ������� ���������-�����)! 
										; 	� �����, ����� ��-���� ����������, �����, �� �������� ""����������� �����", � ������ �������������-����������� "����������� ������".
		OUTI	DButtonRTCStatus,	0b11111111			; ����� ��������� ��������� ������ - ������� "���������� �����" � ���������� ��������.		(����������: ��� ������ ������� ���������, "� ��������� ��������-���������": ���������� ������������ ��������� ������, ����� ��������� �������� - ��� ������ �������, ��� ������������� ����� ��������� ��������� ������������ ������...)
		; <����� ������������� ���������� ��� ��������� �������>
		RJMP	EventButtonHavePressed__SWITCH_MODES


	SwitchFunc_Timer1__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonTimer1Status,	BSC_ShortPress
		OR_BUTTON_HAVE_STATUS	DButtonTimer1Status,	BSC_LongHold
		BRTC	SwitchFunc_Timer2__SWITCH_MODES				; ���� ������ �� ���� ������...
		OUTI	DButtonTimer1Status,	0b11111111			; ����� ��������� ��������� ������ - ������� "���������� �����" � ���������� ��������.
		; <����� ������������� ���������� ��� ��������� �������>
		RJMP	EventButtonHavePressed__SWITCH_MODES


	SwitchFunc_Timer2__SWITCH_MODES:
		IF_BUTTON_HAVE_STATUS	DButtonTimer2Status,	BSC_ShortPress		
		OR_BUTTON_HAVE_STATUS	DButtonTimer2Status,	BSC_LongHold		
		BRTC	SwitchFunc_End__SWITCH_MODES				; ���� ������ �� ���� ������...
		OUTI	DButtonTimer2Status,	0b11111111			; ����� ��������� ��������� ������ - ������� "���������� �����" � ���������� ��������.
		; <����� ������������� ���������� ��� ��������� �������>
		RJMP	EventButtonHavePressed__SWITCH_MODES

	SwitchFunc_End__SWITCH_MODES:




		; ��������� ����������� ��������� �������� � ������ ���������
		LDS	ExtendDataByValue,	DEncoder0Counter
		TST	ExtendDataByValue
		BREQ	NotEncoder__SWITCH_MODE_SETTINGS
		OUTI	DEncoder0Counter,	0				; ������: ����� ����������� � "������ ������" ���� ���������� �������, ������� "�������� �����" �������� ����������.
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
	NotEncoder__SWITCH_MODE_SETTINGS:


		; ��������� ����������� ��������� �������� � ������ "���������������� �������"
		; (����������� �������)
		IF_BUTTON_HAVE_STATUS	DButtonStartStatus,	BSC_ShortPress
		BRTC	Button2__SWITCH_MODE_SETTINGS				; ���� ������ �� ���� ������...
		OUTI	DButtonStartStatus,	0b11111111			; ����� ��������� ��������� ������ - ������� "���������� �����" � ���������� ��������.
		LDI	ExtendDataByValue,	1
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
		; (����������� ����, ��� ���������)
	Button2__SWITCH_MODE_SETTINGS:
		IF_BUTTON_HAVE_STATUS	DButtonStartStatus,	BSC_LongHold
		BRTC	NotButton__SWITCH_MODE_SETTINGS				; ���� ������ �� ���� ������...
		;OUTI	DButtonStartStatus,	0b11111111			; ��������: � ���� ������, ������ ������ �� ���������� - ����� ���������� ��������� "�������" � �������� "������ ���������"...
		LDI	ExtendDataByValue,	1
		; (���� ��������� ����� �������� "����� ����������" ����������� ������)
		LDS	temp1,	DButtonStartStatus
		ANDI	temp1,	0b11111<<BUTTON_HOLDING_TIME			; �������� "������� ������� ��������� ������"
		CPI	temp1,	8						; ��� ��������� ������ ����� >=4���, ��������� �������� � 2 ���� ������.
		BRLO	SlowSpeedYet__SWITCH_MODE_SETTINGS
		LSL	ExtendDataByValue
		CPI	temp1,	16						; ��� ��������� ������ ����� >=8���, ��������� �������� ��� � 2 ���� ������.
		BRLO	SlowSpeedYet__SWITCH_MODE_SETTINGS
		LSL	ExtendDataByValue
	SlowSpeedYet__SWITCH_MODE_SETTINGS:
		RJMP	ModifyData__SWITCH_MODE_SETTINGS
	NotButton__SWITCH_MODE_SETTINGS:
		RJMP	Exit__SWITCH_MODES


	ModifyData__SWITCH_MODE_SETTINGS:
		; <����� ������������� ���������� ��� ����������� "������ ������" += �������� �� �������� ExtendDataByValue >




		;** (��������� ������� ������ ���������)
		RJMP	Exit__SWITCH_MODES
EventButtonHavePressed__SWITCH_MODES:
		; �����, ����� ����������� ��� ��������������� ������� �� ������� ����� ������: ��������, ����� �������� "������� ������" � �.�.
Exit__SWITCH_MODES:
		; ���� ������� ������ �� ���� �������������, �� ������ �����
		RET



;***** END Procedures section 
; coded by (c) Celeron, 2013  http://inventproject.info/
