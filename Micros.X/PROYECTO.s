; PROYECTO 
; Archivo:      PROYECTO.S
; Dispositivo:	PIC16F887
; Autor:	Guillermo Lam
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	Semaforos 
; Hardware:	Semaforos con timers
;
; Creado: 1 abr, 2021
; Ultima modificacion: 1 abr, 2021

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
RIGHT EQU 2
    

    
; Variables a utilizar
PSECT udata_bank0
 banderas: DS 1
 secuencia: DS 1
 nibble: DS 2
 centenas: DS 1
 disp: DS 7
 modo: DS 1
 flags: DS 1
 contador: DS 1
 unidades: DS 1
 decenas: DS 1
 resultados: DS 1
 contador1: DS 1
 contador2: DS 1
 delay: DS 1
 delay1: DS 1
 delay2: DS 1
 selector: DS 1
 activar: DS 1
 num:	DS 1
 tiempo1: DS 1
 tiempo2: DS 1
 tiempo3: DS 1
 tiempo4: DS 1
 tiempo5: DS 1
 tiempo6: DS 1
 segundo: DS 1
 total1:  DS 1	
 total2:  DS 1
 total3:  DS 1
 tiempoi: DS 1
 tiempoii: DS 1
 tiempoiii: DS 1
 tiempoiiii: DS 1
 

    
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
    banksel PORTB	
    btfsc   TMR1IF	
    call    int_t1	
    banksel PIR1
;    btfsc   TMR2IF    
;    call    int_t2   
    banksel TMR2
    bcf	    TMR2IF  
    
pop:
    swapf STATUS_TEMP,W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie

;---------interrupcion sub rutina---------
;int_t2:	
;    btfsc   pestaneo, 0	  
;    goto    off
;on:
;    bsf	    pestaneo, 0	   
;    return    
;off:
;    bcf	    pestaneo, 0	  
;    return

int_t1:
    banksel PORTA
    call    reiniciar_tmr1
    call    secuencia1
    call    secuencia2
    call    secuencia3
    return
    
int_t0:
    call reiniciar_tmr0  ;se hace la interrupcion del timer	    ;se limpia el PORTB
    clrf PORTD
    btfsc banderas, 0	; se hace el bit test para´pasar a un display
    goto display_0	;se va al display 1
    btfsc banderas, 1	; se hace el bit test para´pasar a un display
    goto display_1	; se va al display 2
    btfsc banderas, 2	; se hace el bit test para´pasar a un display
    goto display_2	; se va al display3
    btfsc banderas, 3	
    goto display_3
    btfsc banderas, 4	
    goto display_4
    btfsc banderas, 5	
    goto display_5
    btfsc banderas, 6	
    goto display_6
    btfsc banderas, 7
    goto display_7
    
    
display_0:
    movf disp+0,W	;funcion del display
    movwf PORTC		; mueve la variale display al PORTC
    bsf	PORTD,0		;se activa el bit en la bandera definida
    bcf banderas, 0
    bsf banderas, 1
    return

display_1:
    movf disp+1,W
    movwf PORTC
    bsf PORTD, 1
    bcf banderas, 1
    bsf banderas, 2
    return
    
 display_2:
    movf disp+2,W
    movwf PORTC
    bsf PORTD,2
    bcf banderas,2
    bsf banderas,3
    return

 display_3:
    movf disp+3,W
    movwf PORTC
    bsf PORTD, 3
    bcf banderas,3
    bsf banderas,4
    return

 display_4:
    movf disp+4,W
    movwf PORTC
    bsf PORTD, 4
    bcf banderas,4
    bsf banderas,5
    return

 display_5:
    movf disp+5,W
    movwf PORTC
    bsf PORTD, 5
    bcf banderas,5
    bsf banderas,6
    return

 display_6:
    movf disp+6,W
    movwf PORTC
    bsf PORTD, 6
    bcf banderas,6
    bsf banderas,7
    return
    
display_7:
    movf disp+7,W
    movwf PORTC
    bsf PORTD, 7
    bcf banderas,7
    bsf banderas,0
    return

    
     
int_iocb:   ;se hace la interrupcion de PORTB
    banksel PORTA
    btfss PORTB, UP
    call seleccion
    btfss PORTB, DOWN
    call    subir
    btfss PORTB, RIGHT
    call    bajar
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
   bsf TRISB, RIGHT
   bcf TRISB, 3
   bcf TRISB, 4
   bcf TRISB, 5
   bcf TRISB, 6
   bcf TRISB, 7
   bcf OPTION_REG, 7
   bsf WPUB, UP
   bsf WPUB, DOWN
   bsf WPUB, RIGHT
   
   movlw 00000000B  ;Se definen outputs e inputs a TRISC
   movwf TRISC	    ;Se carga la configuración de inputs y outputs a TRISC
   
   movlw 00000000B  ;Se definen outputs e inputs a TRISD
   movwf TRISD	    ;Se carga la configuración de inputs y outputs a TRISD
   
   
    
;   call config_reloj ;se llama la configuración del reloj
   call config_iocrb
;   call config_tmr0 ;se llama a la configuracion del timer0
   call config_interrupcion
   call config_timers
   
   banksel PORTA    ;Se selecciona el banco 0
   clrf PORTA	    ;Se ponen los PORTs en 0
   clrf PORTB	    
   clrf PORTC	    
   clrf PORTD
   
   movlw    15
   movwf    contador
   movlw    15
   movwf    contador1
   movlw    31
   movwf    contador2
   movlw    10
   movwf    num
   movlw    15
   movwf    tiempo1
   movlw    15
   movwf    tiempo2
   movlw    15
   movwf    tiempo3
   movlw    1
   movwf    segundo
  
 ;---------------loop----------
 loop:
    clrf unidades
    clrf decenas
    call modos1
    call modos
    call sumas
    call sumas1
    call sumas2
    call sumas3
 goto loop
    

;---------------subrutinas---------- 

config_iocrb:
    banksel TRISA   ;se hace la configuracion del PORTB
    bsf IOCB, UP
    bsf IOCB, DOWN
    bsf IOCB, RIGHT
    banksel PORTA
    movf PORTB, W
    bcf RBIF
    return
    
config_timers:		    
    banksel OSCCON
    bsf	    IRCF2   
    bcf	    IRCF1   
    bsf	    IRCF0   
    bsf	    SCS	    

    banksel INTCON
    bsf	    GIE		
    bsf	    T0IE	
    bcf	    T0IF
    
    banksel PIE1
    bsf	    TMR2IE	
    bsf	    TMR1IE	
    
    banksel PIR1
    bcf	    TMR2IF	
    bcf	    TMR1IF	
   
    banksel OPTION_REG
    bcf	    T0CS
    bcf	    PSA		
    bsf	    PS0		
    bsf	    PS1
    bsf	    PS2
    call reiniciar_tmr0
   
    banksel T1CON
    bsf	    T1CKPS1	
    bsf	    T1CKPS0
    bcf	    TMR1CS	
    bsf	    TMR1ON
    call reiniciar_tmr1
    
    banksel T2CON
    movlw   1001110B   
    movwf   T2CON 
    return
    
 config_interrupcion:	;se hacen las interrupciones del timer0 y el PORB
    bsf GIE
    bsf RBIE
    bcf RBIF
    bsf T0IE
    bcf T0IF
    bcf TMR1IF
    bsf TMR1IE
    bsf PEIE
    return
 
 seleccion:
    incf    selector
    bcf	    STATUS, 2
    movlw   5
    subwf   selector, W
    btfss   STATUS, 2
    goto    $+8
    movlw   0
    movwf   selector
    return
    
 modos1:
    call division
    call division1
    call division2
    return
   
    
division:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    contador, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+0
    movf    resultados, W
    call    sietes
    movwf   disp+1
    return
    
division1:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    contador1, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+2
    movf    resultados, W
    call    sietes
    movwf   disp+3
    return
    
division2:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    contador2, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+4
    movf    resultados, W
    call    sietes
    movwf   disp+5
    return
    
 division4:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    num, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+6
    movf    resultados, W
    call    sietes
    movwf   disp+7
    movf    num, W
    movwf   total1
    return
    
    
 division5:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    num, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+6
    movf    resultados, W
    call    sietes
    movwf   disp+7
    movf    num, W
    movwf   total2
    return
    
  division6:
    clrf    unidades
    clrf    decenas
    bcf	    STATUS, 0
    movf    num, W
    movwf   resultados
    movlw   10
    incf    decenas
    subwf   resultados, F
    btfsc   STATUS, 0
    goto    $-3
    decf    decenas
    addwf   resultados
    movf    decenas, W
    call    sietes
    movwf   disp+6
    movf    resultados, W
    call    sietes
    movwf   disp+7
    movf    num, W
    movwf   total3
    return
    
 modos:
    bcf	    STATUS, 2
    movlw   1
    subwf   selector, W
    btfsc   STATUS, 2
    call    modos2
    
    bcf	    STATUS, 2
    movlw   2
    subwf   selector, W
    btfsc   STATUS, 2
    call    modos3
    
    bcf	    STATUS, 2
    movlw   3
    subwf   selector, W
    btfsc   STATUS, 2
    call    modos4
    
    bcf	    STATUS, 2
    movlw   4
    subwf   selector, W
    btfsc   STATUS, 2
    call    modos5
    return
    
  modos2:
    bsf PORTB, 5
    bcf	PORTB, 6
    bcf	PORTB, 7
    call division4
    return
    
 subir:
    incf    num    
    bcf	    STATUS, 2
    movlw   21
    subwf   num, W
    btfss   STATUS, 2
    goto    $+8
    movlw   10
    movwf   num
    return
    
bajar:
    decf    num    
    bcf	    STATUS, 2
    movlw   9
    subwf   num, W
    btfss   STATUS, 2
    goto    $+8
    movlw   20
    movwf   num
    return
    
  modos3:
    bcf PORTB, 5
    bsf	PORTB, 6
    bcf	PORTB, 7
    call division5
    return
    
 modos4:
    bcf PORTB, 5
    bcf	PORTB, 6
    bsf	PORTB, 7
    call    division6
    return
    
 modos5:
    bsf PORTB, 5
    bsf	PORTB, 6
    bsf	PORTB, 7
    btfss   PORTB, DOWN
    call    aceptar
    btfss   PORTB, RIGHT
    call    cancelar
    return
    
 aceptar:
    call    inicio
    movf    tiempoi, W    
    movwf   contador1
    movf    tiempoii,W
    movwf   contador
    movf    tiempoiii, W
    movwf   contador2
    movf    total1, W
    movwf   tiempo1
    movf    total2, W 
    movwf   tiempo2
    movf    total3, W
    movwf   tiempo3
    return
    
 cancelar:
    clrf    selector
    clrf    disp+6
    clrf    disp+7
    call    modos1
    bcf	    PORTB, 5
    bcf	    PORTB, 6
    bcf	    PORTB, 7
    return
    
 sumas:
    movf    tiempo2, W
    addwf   tiempo3, W
    addwf   segundo, W
    movwf   tiempo4
    return
    
 sumas1:
    movf    tiempo1, W
    addwf   tiempo3, W
    addwf   segundo, W
    movwf   tiempo5
    return
    
 sumas2:
    movf    tiempo1, W
    addwf   tiempo2, W
    addwf   segundo, W
    movwf   tiempo6
    return
    
sumas3:
    movf    tiempo1, W
    addwf   segundo, W
    movwf   tiempoi
    return
    
inicio:
    movf    tiempo2
    movwf   tiempoii
    movf    tiempo3
    movwf   tiempoiii
    return
    
 secuencia1:
    decf    contador
    bcf	    STATUS, 2
    movlw   255
    subwf   contador, W
    btfss   STATUS, 2
    goto    $+8
    movlw   1
    xorwf   delay, 1
    movf    tiempo1, W   
    movwf   contador
    btfsc   delay, 0
    movf    tiempo4, W
    movwf   contador
    return
    
 secuencia2:
    decf    contador1
    bcf	    STATUS, 2
    movlw   255
    subwf   contador1, W
    btfss   STATUS, 2
    goto    $+8
    movlw   1
    xorwf   delay1, 1
    movf    tiempo5, W
    movwf   contador1
    btfss   delay1, 0
    movf    tiempo2, W
    movwf   contador1
    return
    
secuencia3:
    decf    contador2
    bcf	    STATUS, 2
    movlw   255
    subwf   contador2, W
    btfss   STATUS, 2
    goto    $+8
    movlw   1
    xorwf   delay2, 1
    movf    tiempo3, W
    movwf   contador2
    btfss   delay2, 0
    movf    tiempo6, W
    movwf   contador2
    return
   
    		   
reiniciar_tmr0:
    banksel PORTA
    movlw 245
    movwf TMR0
    bcf T0IF
    return
    
reiniciar_tmr1:
    banksel PIR1
    movlw 11011100B
    movwf TMR1L
    movlw 1011B
    movwf TMR1H
    bcf TMR1IF
    return
end