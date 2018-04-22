          INCLUDE 'MC9S08JM16.INC' 
	
KBIE	EQU	1
KBACK	EQU	2
KMOD    EQU 0
CLK		EQU 0		
RESET   EQU 1
LOCK	EQU	6	
RS		EQU	0		
ENABLE	EQU	1	
LRESET	EQU 2; PIN 42
CLKSA	EQU	3;
TOF		EQU	7;
CH2F	EQU	7;
CH2		EQU	7;
CONT1	EQU	0;
CONT2	EQU	1;
CONT3	EQU	2;
CONT4	EQU	3;

LLENAR  EQU 0
VACIAR	EQU 1

		ORG 	0B0H  					;Direccion de RAM  (Variables)
CONT	DS 1	
V_I 	DS 1
V_F		DS 1
T_O		DS 1	
INF		DS 2
SUP 	DS 2	
AUX		DS 1
VALOR_M DS 2
		ORG		0C000H; 				Direccion de RAM  (Memoria para programa)

INICIO: CLRA
		STA		SOPT1
		LDHX	#4B0H
		TXS
		MOV     #0AAH,MCGTRM
		MOV     #00000110B,MCGC1
		BRCLR	LOCK,	MCGSC,	*
		MOV		#33H,	PTFDD	      ;Configuramos los pines F0,F1,F4,F5	como salidas	
		MOV		#00101100B,	PTCDD	  ;Configuracion del reloj para sensor PTC5 - PIN 44
		MOV		#00001111B,	PTBDD	  ;Configuracion Contador	
;--------LED DE RESET		
		BSET	LRESET,PTCD;
		LDHX 	#50000D
		JSR     TIEMPO
		BCLR	LRESET,PTCD;
;--------CONFIGURACION KNI---------------			
		MOV		#0H,PTGDD;
		LDA		#0FH			 	;HABILITAR RESISTENCIAS DE PULL UP G2-G3
		STA		PTGPE				;MODIFICA REGISTRO	
		MOV		#11000011B,KBIPE	;HABILITAR INTERRUPCIONES DE PUERTOS 	
		BSET	KBACK, KBISC
		BSET	KBIE,  KBISC
		MOV     #0H,KBIES
		CLI
;------------------INICIALIZACION--------------------------
		MOV 	#0H,V_I
		MOV		#0H,V_F;
		MOV		#0H,CONT;
;------------------CONFIGURACION LCD--------------------------------------------
CON_LCD:LDHX	#50000D
		JSR		TIEMPO		
		MOV		#0FFH,	PTEDD		;Configuramos el puerto E todo como salidas
		MOV		#3H,PTDDD			;Configuramos bits 0 y 1 del puerto D como salidas
		BCLR	ENABLE,	PTDD		;Mandamos el bit 1 del registro D a 0
		MOV 	#00111000B,	PTED	;Enviamos el comando para colocar bus a 8 BITS, las 2 lineas habilitadas y matriz de 5x7 en cada cuadro
		JSR		COMANDO				;Saltamos a sub rutina para enviar el comando
		MOV		#00000110B,	PTED	;Enviamos el comando para escribir de izquierda a derecha y display estático
		JSR		COMANDO				;Saltamos a sub turtina para enviar el comando
		MOV		#00001100B,	PTED	;Enviamos el comando para encender el display, apagar el cursor y mantener el cursor estático
		JSR		COMANDO				;Saltamos a sub rutina para enviar el comando
		MOV 	#00000001B,	PTED	;Enviamos el comando para borrar el display
		JSR		COMANDO
		LDHX	#20000D
		JSR		TIEMPO
		MOV		#10000000B,	PTED	;Enviamos comando para mover el cursor a la posición 2 en la línea 1
		JSR		COMANDO
		LDHX	#0H
LINEA1: LDA 	TABLAF1,X
		CBEQA	#0FFH,CONLIN2
		STA		PTED
		JSR		DATOLCD
		AIX 	#1H
		JMP		LINEA1
CONLIN2:MOV		#11000000B,PTED			; ENVIAMOS COMANDO PARA MVER EL CURSOR EN LA POSICION 2 DE LA LINEA 2
		JSR     COMANDO
		LDHX 	#20000D
		JSR     TIEMPO
LINEA2:	LDA 	TABLAF2,X               ; Se preguntan por datos de la tabla
		CBEQA	#0FFH,EXITLCD
		STA		PTED
		JSR		DATOLCD
		AIX 	#1H
		JMP		LINEA2;
EXITLCD:

;---------Configuracion Timers----------------		 
		MOV		#00000111B,TPM1SC;	PRESCALER DE 128
		MOV		#0F4H,TPM1MODH
		MOV		#24H,TPM1MODL
		
		MOV		#01001000B,TPM2SC;	PRESCALER DE 1 ACTIVA INTERUPCION
		MOV		#0FFH,TPM2MODH
		MOV		#0FFH,TPM2MODL
		
		MOV		#00101000B,TPM1C2SC; CONFIGURACION CANAL 2 F0
		MOV		#0H	,TPM1C2VH
		MOV 	#1H,TPM1C2VL
		
		MOV		#00001100B,TPM2C0SC; CONFIGURACION CANAL

		
		BSET	CLKSA,TPM1SC
		BSET	CLKSA,TPM2SC
;------------- CICLO INFINTO-------------

CICLO:	
		BRCLR	CH2F,TPM1C2SC,*; PREGUNTA SI PASO UN 1S
		BCLR	CH2F,TPM1C2SC; LIMPIA BANDERA
		BSET	LRESET,PTCD;
		BRCLR	CH2F,TPM2C0SC,*;
		BCLR	CH2F,TPM2C0SC;
		LDHX	#0H
		STHX	TPM2CNTH; REINICIO CONTADOR
		BRCLR	CH2F,TPM2C0SC,*;
		BCLR	CH2F,TPM2C0SC;
		LDHX	TPM2C0VH
		JSR		OPERAR
		JSR 	ACT_LCD1
FINCI:	JMP 	CICLO;RETORNA AL WHILE INFINITO		

;-------- SUBRUTINA OPERAR DATO ------------------------
OPERAR:PSHX
	   PULA
	   LDX    #233D
	   DIV
	   CLRH
	   LDX    #2D
	   DIV
	   STA	  AUX
	   LDA    #27D
	   SUB    AUX
	   STA	  VALOR_M
	   RTS
;--------RUTINA CONTADOR--------------------------------
CONTEO:	LDA		CONT;
		CBEQA	#0,CONT_1;
		CBEQA	#1,CONT_2;
		CBEQA	#2,CONT_3;
CONT_4:	MOV		#0H,CONT; 
		BCLR	CONT1,PTBD;
		BSET	CONT2,PTBD;
		BSET	CONT3,PTBD;
		BSET	CONT4,PTBD; 		
		JMP		CEXIT;
CONT_3:	INC		CONT
		BSET	CONT1,PTBD;
		BCLR	CONT2,PTBD;
		BSET	CONT3,PTBD;
		BSET	CONT4,PTBD;
		JMP		CEXIT;
CONT_2:	INC		CONT
		BSET	CONT1,PTBD;
		BSET	CONT2,PTBD;
		BCLR	CONT3,PTBD;
		BSET	CONT4,PTBD;
		JMP		CEXIT;
CONT_1:	INC		CONT
		BSET	CONT1,PTBD;
		BSET	CONT2,PTBD;
		BSET	CONT3,PTBD;
		BCLR	CONT4,PTBD;		
CEXIT:	RTS;		
;-----------INTERUPCION POR KBI----------------------
INT_KBI:BCLR	LRESET,PTCD;
		LDA 	PTGD
		AND 	#0FH
		CBEQA   #0EH,F1
		CBEQA 	#0DH,F2
		CBEQA   #0BH,F3
		CBEQA   #07H,F4
F1:		LDA		CONT;
		CBEQA	#1H,F1C1;
		CBEQA	#2H,F1C2;
		CBEQA	#3H,F1C3;
F1C4:	;LDA	#41H;
		JMP     KBIEXIT
F1C3:	;LDA		#33H;
		MOV		#3H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F1C2:	;LDA		#32H;
		MOV		#2H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F1C1:	;LDA		#31H;
		MOV		#1H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT			
F2:  	LDA		CONT;
		CBEQA	#1H,F2C1;
		CBEQA	#2H,F2C2;
		CBEQA	#3H,F2C3;
F2C4:	;LDA	#42H;
		JMP    KBIEXIT
F2C3:	;LDA		#36H;
		MOV		#6H, T_O; 
		JSR		ING_NUM;
		JMP     KBIEXIT
F2C2:	;LDA		#35H;
		MOV		#5H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F2C1:	;LDA		#34H;
		MOV		#4H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT	
F3:		LDA		CONT;
		CBEQA	#1H,F3C1;
		CBEQA	#2H,F3C2;
		CBEQA	#3H,F3C3;
F3C4:	;LDA	#43H;
		JSR		BORRAR;
		JMP     KBIEXIT
F3C3:	;LDA	#39H;
		MOV		#9H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F3C2:	;LDA	#38H;
		MOV		#8H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F3C1:	;LDA	#37H;
		MOV		#7H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT			
F4:		LDA		CONT;
		CBEQA	#1H,F4C1;
		CBEQA	#2H,F4C2;
		CBEQA	#3H,F4C3;
F4C4:	;LDA	#44H;
		JSR 	INTRO
KBIIN:	LDA 	PTGD
		AND 	#0FH
		CBEQA   #0FH,CLRKB; SALTA AL 
		JMP		KBIIN;	
CLRKB:	BSET	KBACK, KBISC		
		RTI
F4C3:	;LDA	#23H;
		JMP    KBIEXIT
F4C2:	;LDA	#30H;
		MOV		#0H,T_O;
		JSR		ING_NUM;
		JMP     KBIEXIT
F4C1:	;LDA		#2AH;
		JMP     KBIEXIT					
KBIEXIT:LDA 	PTGD
		AND 	#0FH
		CBEQA   #0FH,CLRKBI; SALTA AL 
		JMP		KBIEXIT;	
CLRKBI:	JSR 	ACT_LCD2;
		BSET	KBACK, KBISC		
		RTI
		
;------------ OPERACION A NUMERO INGRESADO----------------------
ING_NUM:LDA		#10D     ; 
		CMP 	V_I     ;A-OPR8
		BPL 	AJ1
		RTS
		
AJ1:    LDX 	V_I
		MUL
		ADD 	T_O
		STA 	V_I
		RTS
BORRAR: MOV		#0H,V_I;
		RTS
INTRO:  LDA 	#25D
		CMP 	V_I
		BPL 	MENOR			;SALTA SI ES MENOR
		MOV		#0H,V_I
		MOV		#11001110B,PTED
		JSR 	COMANDO
		MOV 	#4EH,PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		MOV		#11001111B,PTED
		JSR		COMANDO
		MOV		#41H,PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO	
		RTS
MENOR: 	MOV 	V_F, V_I
		MOV		#0H,V_I
		MOV		#11001110B,PTED
		JSR 	COMANDO
		MOV 	#2DH,PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		MOV		#11001111B,PTED
		JSR		COMANDO
		MOV		#2DH,PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO	
		RTS

;-------------------INTERRUPCION TM2CH0---------------------------------
INT_TM2:BCLR	TOF,TPM2SC
		JSR		CONTEO;
		RTI		
;-------------ACTUALIZA LCD2-------------------
ACT_LCD2:LDHX 	#10D
		LDA     V_I
		DIV
		PSHH
		ADD 	#30H
		MOV		#11001110B,PTED
		JSR 	COMANDO
		STA 	PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		PULA
		ADD		#30H
		MOV		#11001111B,PTED
		JSR		COMANDO
		STA 	PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		RTS
;-------------ACTUALIZA LCD1-------------------
ACT_LCD1:LDHX 	#10D
		LDA     VALOR_M
		DIV
		PSHH
		ADD 	#30H
		MOV		#10001110B,PTED
		JSR 	COMANDO
		STA 	PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		PULA
		ADD		#30H
		MOV		#10001111B,PTED
		JSR		COMANDO
		STA 	PTED
		JSR 	DATOLCD
		LDHX	#1000D
		JSR		TIEMPO
		RTS
;--------RUTINA COMANDO---------------------------------- 
COMANDO:BCLR	RS,		PTDD				;Mandamos el bit RS del LCD al 0 para saber que vamos a enviar un comando
		JMP		SALTOLCD					;Pasamos a hacer el pulso del enable
DATOLCD:BSET	RS,		PTDD				;Mandamos el bit RS del LCD a 1 para saber que vamos a enviar un dato
SALTOLCD:
		BSET	ENABLE,	PTDD				;Mandamos el pulso en alto al bit ENABLE del LCD
		NOP									;Con esto esperamos tiempo en alto del bit ENABLE		
		NOP
		NOP									;Con esto esperamos tiempo en alto del bit ENABLE		
		NOP
		NOP
		NOP
		BCLR	ENABLE,	PTDD				;Bajamos el bit a 0 y así aseguramos el pulso
		PSHX								;Guarda datos correspondientes lo que venia antes  
		PSHH								;para subrutina de tiempo no sobre escriba
		LDHX	#50D
		JSR		TIEMPO
		PULH								;Obtiene 
		PULX								;Datos
		RTS

;--------INICIO RUTINA DE TIEMPO------------------------------
TIEMPO: AIX		#-1D         ; resta 1 a HX
		CPHX	#0H          ; compara HX con 0
		BNE		TIEMPO       ; Si hx es igual a 0 sigue
		RTS                  ; retorna		

		
TABLAN: FCB  '0123456789',0FFH
TABLAF1:FCB 'NIVEL ACTUAL:   ',0FFH
TABLAF2:FCB 'NIVEL FINAL :   ',0FFH
			
;------POSICION DE INICIO----------------------------------
		ORG		0FFCCH
		FDB		INT_KBI
		
		ORG     0FFFEH
		FDB		INICIO
		
		ORG		0FFDAH
		FDB		INT_TM2
		
