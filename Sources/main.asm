
    INCLUDE 'MC9S08JM16.INC' 
	
KBIE	EQU	1
KBACK	EQU	2
KMOD    EQU 0
CLK		EQU 0		
RESET   EQU 1
LOCK	EQU	6	
RS		EQU	0		
ENABLE	EQU	1
TRIGER	EQU 5; triger del sensor		

		ORG 	0B0H  ;Direccion de RAM  (Variables)
CONT	DS 1			


		ORG		0C000H; Direccion de RAM  (Memoria para programa)

INICIO: CLRA
		STA		SOPT1
		LDHX	#4B0H
		TXS
		MOV     #0AAH,MCGTRM
		MOV     #00000110B,MCGC1
		BRCLR	LOCK,	MCGSC,	*
		MOV		#33H,	PTFDD	  ;Configuramos los pines F0,F1,F4,F5	como salidas	
		MOV		#00100000B,	PTCDD	  ;Configuracion del reloj para sensor PTC5 - PIN 44	
		MOV		#0H,PTGDD;
		LDA		#0FH			 	;HABILITAR RESISTENCIAS DE PULL UP G2-G3
		STA		PTGPE				;MODIFICA REGISTRO	
		MOV		#11000011B,KBIPE	;HABILITAR INTERRUPCIONES DE PUERTOS
		BSET	KBACK, KBISC
		BSET	KBIE,  KBISC
		MOV     #0H,KBIES
		CLI
		
		
		;------------------CONFIGURACION LCD--------------------------------------------
CON_LCD:LDHX	#50000D
		JSR		TIEMPO		
		MOV		#0FFH,	PTEDD			;Configuramos el puerto E todo como salidas
		MOV		#3H,PTDDD			;Configuramos bits 0 y 1 del puerto D como salidas
		BCLR	ENABLE,	PTDD				;Mandamos el bit 1 del registro D a 0
		MOV 	#00111000B,	PTED			;Enviamos el comando para colocar bus a 8 BITS, las 2 lineas habilitadas y matriz de 5x7 en cada cuadro
		JSR		COMANDO					;Saltamos a sub rutina para enviar el comando
		MOV		#00000110B,	PTED			;Enviamos el comando para escribir de izquierda a derecha y display estático
		JSR		COMANDO					;Saltamos a sub turtina para enviar el comando
		MOV		#00001100B,	PTED			;Enviamos el comando para encender el display, apagar el cursor y mantener el cursor estático
		JSR		COMANDO					;Saltamos a sub rutina para enviar el comando
		MOV 	#00000001B,	PTED			;Enviamos el comando para borrar el display
		JSR		COMANDO
		LDHX	#20000D
		JSR		TIEMPO
		MOV		#10000000B,	PTED			;Enviamos comando para mover el cursor a la posición 2 en la línea 1
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
		
EXITLCD:MOV		#0H,CONT;		
CICLO:	JSR		PULSO;
		JMP 	CICLO;RETORNA AL WHILE INFINITO		
;-------------------PULSO-----------------------------------------
PULSO:	BCLR	CLK,PTCD
		LDHX	#10D         ;TIEMPO DE 10US
		JSR		TIEMPO
		JSR		CONTEO;Llama a rutina conteo
		BSET	TRIGER,PTCD
		LDHX	#10D		 ;TIEMPO DE 10US
		JSR		TIEMPO
		RTS
;-------------------INTERRUPCION KBI------------------------------------		
INT_KBI:LDA 	PTGD
		AND 	#0FH
		CBEQA   #0EH,F1
		CBEQA 	#0DH,F2
		CBEQA   #0BH,F3
		CBEQA   #07H,F4
F1:		LDA		CONT;
		CBEQA	#1H,F1C1;
		CBEQA	#2H,F1C2;
		CBEQA	#3H,F1C3;
F1C4:	LDA		#41H;
		JMP     KBIEXIT
F1C3:	LDA		#33H;
		JMP     KBIEXIT
F1C2:	LDA		#32H;
		JMP     KBIEXIT
F1C1:	LDA		#31H;
		JMP     KBIEXIT			
F2:  	LDA		CONT;
		CBEQA	#1H,F2C1;
		CBEQA	#2H,F2C2;
		CBEQA	#3H,F2C3;
F2C4:	LDA		#42H;
		JMP     KBIEXIT
F2C3:	LDA		#36H;
		JMP     KBIEXIT
F2C2:	LDA		#35H;
		JMP     KBIEXIT
F2C1:	LDA		#34H;
		JMP     KBIEXIT	
F3:		LDA		CONT;
		CBEQA	#1H,F3C1;
		CBEQA	#2H,F3C2;
		CBEQA	#3H,F3C3;
F3C4:	LDA		#43H;
		JMP     KBIEXIT
F3C3:	LDA		#39H;
		JMP     KBIEXIT
F3C2:	LDA		#38H;
		JMP     KBIEXIT
F3C1:	LDA		#37H;
		JMP     KBIEXIT			
F4:		LDA		CONT;
		CBEQA	#1H,F4C1;
		CBEQA	#2H,F4C2;
		CBEQA	#3H,F4C3;
F4C4:	LDA		#44H;
		JMP     KBIEXIT
F4C3:	LDA		#23H;
		JMP     KBIEXIT
F4C2:	LDA		#30H;
		JMP     KBIEXIT
F4C1:	LDA		#2AH;
		JMP     KBIEXIT				
KBIEXIT:MOV		#11001110B,	PTED			 
		JSR		COMANDO
		STA		PTED
		JSR		DATOLCD
		BSET	KBACK,KBISC
		RTI
;--------RUTINA CONTADOR--------------------------------
CONTEO:	LDA		CONT;
		CBEQA	#0,CONT0;
		CBEQA	#1,CONT1;
		CBEQA	#2,CONT2;
CONT3:	MOV		#0H,CONT; CONT=0;
		MOV		#00010011B,PTFD;
		JMP		CEXIT;
CONT2:	INC		CONT
		MOV		#00100011B,PTFD;
		JMP		CEXIT;
CONT1:	INC		CONT
		MOV		#00110001B,PTFD;
		JMP		CEXIT;
CONT0:	INC		CONT
		MOV		#00110010B,PTFD;		
CEXIT:	RTS;		

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
TABLAF1:FCB 'NIVEL ACTUAL: 10',0FFH
TABLAF2:FCB 'NIVEL FINAL : 10',0FFH
			
;------POSICION DE INICIO----------------------------------
		ORG		0FFCCH
		FDB		INT_KBI
		
		ORG     0FFFEH
		FDB		INICIO
