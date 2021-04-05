; Laboratorio 03
; Archivo:      main.S
; Dispositivo:	PIC16F887
; Autor:	Guillermo Lam
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	contador con 7 segmentos
; Hardware:	7 segmentos en el puerto D
;
; Creado: 16 feb, 2021
; Ultima modificacion: 16 feb, 2021

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
CONFIG FOSC=INTRC_NOCLKOUT  // Oscilador interno sin salidas
CONFIG WDTE=OFF		    // WDT disbled (reinicio repititivo del pic)
CONFIG PWRTE=ON		    // PWRT enabled (espera de 72ms al inirciar)
CONFIG MCLRE=OFF	    // El pin de MCLR se utiliza como I/O
CONFIG CP=OFF		    // Sin proteccion de codigo
CONFIG CPD=OFF		    // Sin proteccion de datos
    
CONFIG BOREN=OFF	    // Sin reinicio cuando el voltaje de alimentacion baja de 4V
CONFIG IESO=OFF		    // Reinicio sin cambio de reloj de interno a externo
CONFIG FCMEN=OFF	    // Cambio de reloj externo a interno en caso de fallo
CONFIG LVP=ON		    // Programación en bajo voltaje permitida

;configuration word 2
CONFIG WRT=OFF		    // Protección de autoescritura por el programa desactivada
CONFIG BOR4V=BOR40V	    // Reinicio abajo de 4V
    
; Variables a utilizar
PSECT udata_shr
 cont: DS 1
    
PSECT resVect, class=CODE, abs, delta=2
;--------------vector reset--------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs
ORG 100h ;posición para el codigo
 
sietes:		    ;tabla de valores para el siete segmentos
    clrf PCLATH
    bsf PCLATH, 0
    andlw 0x0F
    addwf PCL
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;A
    retlw 01111100B ;B
    retlw 00111001B ;C
    retlw 01011110B ;D
    retlw 01111001B ;E
    retlw 01110001B ;F
;--------------configuracion--------------
main:
   banksel ANSEL    ;Se selecciona el banco 3
   clrf ANSEL	    ;Se ponen los pines digitales
   clrf ANSELH	    ;Se ponen los pines digitales

   banksel TRISA    ;Se selecciona el banco 1
   movlw 00000011B  ;Se definen outputs e inputs a TRISA
   movwf TRISA	    ;Se carga la configuración de inputs y outputs a TRISA
   movlw 00000000B  ;Se definen outputs e inputs a TRISB
   movwf TRISB	    ;Se carga la configuración de inputs y outputs a TRISB
   movlw 11110000B  ;Se definen outputs e inputs a TRISC
   movwf TRISC	    ;Se carga la configuración de inputs y outputs a TRISC
   movlw 00000000B  ;Se definen outputs e inputs a TRISD
   movwf TRISD	    ;Se carga la configuración de inputs y outputs a TRISD

   banksel PORTA    ;Se selecciona el banco 0
   clrf PORTA	    ;Se ponen los PORTs en 0
   clrf PORTB	    
   clrf PORTC	    
   clrf PORTD
   
   call config_reloj ;se llama la configuración del reloj
   call config_tmr0 ;se llama a la configuracion del timer0
   
   
 ;---------------loop----------
 loop:
    btfsc PORTA, 0	;Revisa si el boton 1 está en 0	    
    call incrementar1	;LLama a la función incrementar1
	
    btfsc PORTA, 1	;Revisa si el boton 2 está en 0		    
    call decrementar1	;LLama a la función decrementar1
    
    btfss T0IF		;Revisa si el timer0 esta en 1
    goto $-1		;regresa una linea
    call reiniciar_tmr0	;se reinicia el timer0
    incf PORTC		;se incrementa el PORTC
    
    bcf PORTB,0		;Se pone el PORTB en apagado
    call comparador	;se llama a la función comparador
    
 goto loop
    

;---------------subrutinas---------- 
config_reloj:
    banksel OSCCON  ;se decide en que banco se va a trabajara
    bcf IRCF2	    ;Se selecciona la configuración 010
    bsf IRCF1
    bcf IRCF0
    bsf SCS	    ;se activa el oscilador
    return
    
config_tmr0:
    banksel TRISA   ;se selecciona el banco en cual se va a trabajar
    bcf T0CS	    
    bcf PSA	    ;se setea el Prescaler
    bsf PS2
    bsf PS1
    bcf PS0
    banksel PORTC   ;se seleciona el banco en cual se va a trabajar
    call reiniciar_tmr0	;se llama la función reiniciar_tmr0
    return
    
 reiniciar_tmr0:
    movlw 11	;se guarda este valor a W
    movwf TMR0	; se mueve W al timer0
    bcf T0IF	; se apaga el T0IF
    return
    
 incrementar1:		;Función de incrementar1
    btfsc PORTA, 0	;Revisa si el boton 1 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    incf cont		;Incrementa la variable contador
    movf cont, 0	;se mueve la variable a W
    call sietes		;se llama la subrutina sietes
    movwf PORTD		;se mueve el valor de la subrutina a W
    return		;Retorna a la función

decrementar1:		;Función de decrementar1
    btfsc PORTA, 1	;Revisa si el boton 1 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    decfsz cont		;Decrementa la variable contador
    movf cont, 0	;se mueve la variable a W
    call sietes		;se llama la subrutina sietes
    movwf PORTD		;se mueve el valor de la subrutina a W
    return		;Retorna a la función
    
alarma:
    bsf PORTB,0		;Se activa el PORTB
    clrf PORTC		;se reinicia el PORTC
    return		;Retorna a la función
    
comparador:
    movf PORTC, 0	;se mueve el valor de PORTC a W
    subwf cont, 0	;se sustrae el cont de W
    btfsc STATUS, 2	;revisa el STATUS
    call alarma		;se llama a la subrutina alarma
    return		;Retorna a la función
    