
    INCLUDE 'MC9S08JM16.INC' 
	
KBIE	EQU	1
KBACK	EQU	2
KMOD    EQU 0
CLK		EQU 0		
RESET   EQU 1
LOCK	EQU	6	
RS		EQU	0		
ENABLE	EQU	1		

		ORG 	0B0H  ;Direccion de RAM  (Variables)
			


		ORG		0C000H; Direccion de RAM  (Memoria para programa)

INICIO: CLRA
		STA		SOPT1
		LDHX	#4B0H
		TXS
		MOV     #0AAH,MCGTRM
		MOV     #00000110B,MCGC1
		BRCLR	LOCK,	MCGSC,	*
		MOV		#33H,	PTFDD	  ;Configuramos los pines F0,F1,F4,F5	como salidas	
		MOV		#0FH,	PTBDD     ;Configuramos los pines B0,B1,B2,B3	como salidas
		MOV		#03H,	PTCDD	  ;Configuracion del reloj del contador	
		MOV		#00010110B, IRQSC 
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
EXITLCD:		
;-------------------PULSO-----------------------------------------
PULSO:	BCLR	CLK,PTCD
		LDHX	#10D         ;TIEMPO DE 10US
		JSR		TIEMPO
		BSET	CLK,PTCD
		LDHX	#10D		 ;TIEMPO DE 10US
		JSR		TIEMPO
		BCLR	CLK,PTCD
;-------------------INTERRUPCION IRQ------------------------------------		
INT_IRQ:
		JMP     SAL_IRQ
		
SAL_IRQ:LDHX	#50000D
		JSR	    TIEMPO
		BSET    2,IRQSC
		RTI
;-------------------INTERRUPCION KBI------------------------------------		
INT_KBI:LDA 	PTGD
		AND 	#0FH
		CBEQA   #0EH,IZQ
		CBEQA 	#0DH,DER
		CBEQA   #0BH,ROT
		CBEQA   #07H,CAER
SALIR:  BSET	KBACK,KBISC
		RTI			
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

TABLAF1:FCB 'LVL: # BEST: ***',0FFH
TABLAF2:FCB 'POINT: ####',0FFH
			
;------POSICION DE INICIO----------------------------------
		ORG		0FFCCH
		FDB		INT_KBI
		
		ORG		0FFFAH
		FDB		INT_IRQ

		ORG     0FFFEH
		FDB		INICIO
