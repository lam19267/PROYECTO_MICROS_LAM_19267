; Laboratorio 05
; Archivo:      lab4.S
; Dispositivo:	PIC16F887
; Autor:	Guillermo Lam
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	contador con 7 segmentos
; Hardware:	pullup push buttons
;
; Creado: 23 feb, 2021
; Ultima modificacion: 23 feb, 2021

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

UP EQU 0
DOWN EQU 1
    
reiniciar_tmr0 macro
    banksel PORTA
    movlw 61
    movwf TMR0
    bcf T0IF
    endm
    
; Variables a utilizar
PSECT udata_bank0
 banderas: DS 1
 nibble: DS 2   
 disp: DS 5
 centenas: DS 1
 unidades: DS 1
 decenas: DS 1
 resultados: DS 1
 

    
PSECT udata_shr
 W_TEMP: DS 1
 STATUS_TEMP: DS 1
    
PSECT resVect, class=CODE, abs, delta=2
;--------------vector reset--------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT intVect, class=CODE, abs, delta=2
;--------------intrrupt vector--------------
ORG 04h ;posición 0004h para las interrupciones
push:
    movwf   W_TEMP
    swapf   STATUS,W
    movwf   STATUS_TEMP
    
isr:
    btfsc RBIF
    call int_iocb
    btfsc T0IF
    call int_t0
    
pop:
    swapf STATUS_TEMP,W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie

;---------interrupcion sub rutina---------
int_t0:
    reiniciar_tmr0  ;se hace la interrupcion del timer
    clrf PORTB	    ;se limpia el PORTB
    btfsc banderas, 0	; se hace el bit test para´pasar a un display
    goto display_1	;se va al display 1
    btfsc banderas, 1	; se hace el bit test para´pasar a un display
    goto display_2	; se va al display 2
    btfsc banderas, 2	; se hace el bit test para´pasar a un display
    goto display_3	; se va al display3
    btfsc banderas, 3	; se hace el bit test para´pasar a un display
    goto display_4	; se va al display 4
    
display_0:
    movf disp+0, W	;funcion del display
    movwf PORTC		; mueve la variale display al PORTC
    bsf	PORTB,2		;se activa el bit en la bandera definida
    goto nextdisplay	;sigue al proximo display
    return
    
display_1:
    movf disp+1,W
    movwf PORTC
    bsf PORTB, 3
    goto nextdisplay1
    return
    
 display_2:
    movf disp+2,W
    movwf PORTC
    bsf PORTB,4
    goto nextdisplay2
    return
    
 display_3:
    movf disp+3,W
    movwf PORTC
    bsf PORTB, 5
    goto nextdisplay3
    return
    
 display_4:
    movf disp+4,W
    movwf PORTC
    bsf PORTB, 6
    goto nextdisplay4
    return
    
nextdisplay:
    movlw 00000001B	;se verifica que bandera se esta utilizan
    xorwf banderas, 1	;hace un xor para seguir
    return
    
nextdisplay1:
    movlw 00000011B
    xorwf banderas, 1
    return
    
nextdisplay2:
    movlw 00000110B
    xorwf banderas, 1
    return
    
nextdisplay3:
    movlw 00001100B
    xorwf banderas, 1
    return
    
nextdisplay4:
    clrf banderas
    return
    


return_t0:
    return
     
int_iocb:   ;se hace la interrupcion de PORTB
    banksel PORTA
    btfss PORTB, UP
    incf PORTA
    btfss PORTB, DOWN
    decf PORTA
    bcf RBIF
    return
    
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
   movlw 00000000B  ;Se definen outputs e inputs a TRISA
   movwf TRISA	    ;Se carga la configuración de inputs y outputs a TRISA
   
   bsf TRISB, UP
   bsf TRISB, DOWN
   bcf TRISB, 2
   bcf TRISB, 3
   bcf TRISB, 4
   bcf TRISB, 5
   bcf TRISB, 6
   bcf TRISB, 7
   bcf OPTION_REG, 7
   bsf WPUB, UP
   bsf WPUB, DOWN
   
   movlw 00000000B  ;Se definen outputs e inputs a TRISC
   movwf TRISC	    ;Se carga la configuración de inputs y outputs a TRISC
   
   movlw 00000000B  ;Se definen outputs e inputs a TRISD
   movwf TRISD	    ;Se carga la configuración de inputs y outputs a TRISD
   
   call config_reloj ;se llama la configuración del reloj
   call config_iocrb
   call config_tmr0 ;se llama a la configuracion del timer0
   call config_interrupcion
   
   banksel PORTA    ;Se selecciona el banco 0
   clrf PORTA	    ;Se ponen los PORTs en 0
   clrf PORTB	    
   clrf PORTC	    
   clrf PORTD
   
   
   
 ;---------------loop----------
 loop:
    call separar_nibbles	    ;funcion de separa nibbles
    call displays		    ;funcion de mostrar displays
    clrf unidades
    clrf centenas
    clrf decenas
    call division		    ;funcion de division
 goto loop
    

;---------------subrutinas---------- 
separar_nibbles:
    movf PORTA, W		    ;se mueve el contador del PORTA a W
    andlw 0x0f			    ; se hace un and para que cuente de 0 a F
    movwf nibble		    ;se mueve a la variable nible
    swapf PORTA, W		    ;se hace un swap paraa cambiar los valores binarios del PORTA
    andlw 0x0f			    ; se hace un and para que cuente de 0 a F
    movwf nibble+1		    ;se mueve a la variable nible
    return
    
 displays:
    movf nibble, W		    ;se mueve la variable nibble a W	
    call sietes			    ; se llama a la tabla
    movwf disp			    ;se mueve w a la variable disp paara mostrar el valor
    
    movf nibble+1, W
    call sietes
    movwf disp+1
    
    movf centenas,W
    call sietes
    movwf disp+2
    
    movf decenas,W
    call sietes
    movwf disp+3
    
    movf unidades,W
    call sietes
    movwf disp+4
    return

config_iocrb:
    banksel TRISA   ;se hace la configuracion del PORTB
    bsf IOCB, UP
    bsf IOCB, DOWN
    banksel PORTA
    movf PORTB, W
    bcf RBIF
    return
    
config_reloj:
    banksel OSCCON  ;se decide en que banco se va a trabajara
    bsf IRCF2	    ;Se selecciona la configuración 111
    bsf IRCF1
    bsf IRCF0
    bsf SCS	    ;se activa el oscilador
    return
    
config_tmr0:
    banksel TRISA   ;se selecciona el banco en cual se va a trabajar
    bcf T0CS	    
    bcf PSA	    ;se setea el Prescaler
    bsf PS2
    bcf PS1
    bsf PS0	    ;25ms
    reiniciar_tmr0
    return
    
 config_interrupcion:	;se hacen las interrupciones del timer0 y el PORB
    bsf GIE
    bsf RBIE
    bcf RBIF
    bsf T0IE
    bcf T0IF
    return
    
 division:
    movf	PORTA, 0
    movwf	resultados	    ; parte de centenas
    movlw	100		    ;-100
    subwf	resultados, 0	    
    btfsc	STATUS, 0	    
    incf	centenas	    
    btfsc	STATUS, 0	    
    movwf	resultados	    
    btfsc	STATUS, 0	    
    goto	$-7		    
    movlw	10		    ;pate de decenas -10
    subwf	resultados, 0	    
    btfsc	STATUS, 0	    
    incf	decenas		    
    btfsc	STATUS, 0	    
    movwf	resultados	    
    btfsc	STATUS, 0	    
    goto	$-7		    
    movlw	1		    ;parte de unidades -1
    subwf	resultados, F	    
    btfsc	STATUS, 0	    
    incf	unidades	    
    btfss	STATUS, 0	      
    return
    goto	$-6		    
end


