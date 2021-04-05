; Laboratorio 04
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
 cont: DS 2
    
PSECT udata_shr
 W_TEMP: DS 1
 STATUS_TEMP: DS 1
 num: DS 1
 num1: DS 1
    
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
    reiniciar_tmr0 ;se hace la interrupcion del timer
    incf cont
    movf cont, 0
    sublw 40
    btfss    ZERO
    goto return_t0
    clrf cont
    incf num1
    movf num1, 0
    call sietes
    movwf PORTD
    return
    
int_iocb:   ;se hace la interrupcion de PORTB
    banksel PORTA
    btfss PORTB, UP
    incf PORTA
    btfss PORTB, DOWN
    decf PORTA
    bcf RBIF
    return
 
 return_t0:
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
   bcf OPTION_REG, 7
   bsf WPUB, UP
   bsf WPUB, DOWN
   movlw 00000000B  ;Se definen outputs e inputs a TRISC
   movwf TRISC	    ;Se carga la configuración de inputs y outputs a TRISC
   movlw 00000000B  ;Se definen outputs e inputs a TRISD
   movwf TRISD	    ;Se carga la configuración de inputs y outputs a TRISD

   banksel PORTA    ;Se selecciona el banco 0
   clrf PORTA	    ;Se ponen los PORTs en 0
   clrf PORTB	    
   clrf PORTC	    
   clrf PORTD
   
   call config_reloj ;se llama la configuración del reloj
   call config_iocrb
   call config_tmr0 ;se llama a la configuracion del timer0
   call config_interrupcion
   
   
 ;---------------loop----------
 loop:
    call muestra ; se llama la subrutina muestra
 goto loop
    

;---------------subrutinas---------- 
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
    bsf IRCF2	    ;Se selecciona la configuración 010
    bsf IRCF1
    bsf IRCF0
    bsf SCS	    ;se activa el oscilador
    return
    
config_tmr0:
    banksel TRISA   ;se selecciona el banco en cual se va a trabajar
    bcf T0CS	    
    bcf PSA	    ;se setea el Prescaler
    bsf PS2
    bsf PS1
    bsf PS0	    ;25ms
    reiniciar_tmr0
    return
    
 config_interrupcion:	;se hacen las interrupciones del timer0 y el PORB
    bsf GIE
    bsf T0IE
    bcf T0IF
    bsf RBIE
    bcf RBIF
    return
    
muestra:
    banksel PORTA	;Revisa si el boton 1 está en 0
    movf    PORTA, 0	;Regresa una linea para el antirrebote
    movwf num		;Incrementa la variable contador
    movf num, 0		;se mueve la variable a W
    call sietes		;se llama la subrutina sietes
    movwf PORTC		;se mueve el valor de la subrutina a W
    return		;Retorna a la función
      
end
