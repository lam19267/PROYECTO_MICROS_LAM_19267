; Laboratorio 06
; Archivo:      lab6.S
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

reset2 macro	    
    BANKSEL PR2
    movlw   100	    
    movwf   PR2
    endm

    
;--------------------Variables----------------------------------
PSECT udata_shr ;Common memory
    
    W_TEMP: DS 1
    STATUS_TEMP: DS 1   
    nibble: DS  2
    disp_var: DS  2	   
    banderas: DS  1

PSECT udata_bank0 
    contador: DS  1
    pestaneo: DS  1

PSECT resVect, class=CODE, abs, delta=2
;--------------------------vector reset-----------------------------------------
ORG 00h        ;posicion 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT intVect, class=CODE, abs, delta=2
;--------------intrrupt vector--------------
ORG 04h 
    
push:			
    movwf   W_TEMP
    swapf   STATUS, W
    movwf   STATUS_TEMP

isr:
    BANKSEL PORTB	
    btfsc   TMR1IF	
    call    int_t1	
    btfsc   T0IF	
    call    int_t0	
    
    BANKSEL PIR1
    btfsc   TMR2IF    
    call    int_t2   
    BANKSEL TMR2
    bcf	    TMR2IF     
 
pop:			
    swapf   STATUS_TEMP, W
    movwf   STATUS
    swapf   W_TEMP, F
    swapf   W_TEMP, W
    retfie

;---------interrupcion sub rutina---------
int_t2:	
    btfsc   pestaneo, 0	  
    goto    off
on:
    bsf	    pestaneo, 0	   
    return    
off:
    bcf	    pestaneo, 0	  
    return

int_t1:
    banksel TMR1H   
    movlw   0xE1       
    movwf   TMR1H
    banksel TMR1L
    movlw   0x7C
    movwf   TMR1L
    incf    contador	
    bcf	    TMR1IF
    return    
    
int_t0:
    call    reset0	
    bcf	    PORTD, 1	
    bcf	    PORTD, 2
    btfsc   banderas, 0
    goto    disp_02   
 
disp_01:
    movf    disp_var, w
    movwf   PORTC
    bsf	    PORTD, 2
    goto    next_disp01
disp_02:
    movf    disp_var+1, W
    movwf   PORTC
    bsf	    PORTD, 1
next_disp01:
    movlw   1
    xorwf   banderas, f
    return
 

PSECT code, delta=2, abs
ORG 100h    ;posicion para el codigo
 

sietes:
    clrf	PCLATH
    bsf		PCLATH, 0
    andlw	0x0F	    ; Se pone como limite F , en hex 15
    addwf	PCL
    RETLW	00111111B   ;0
    RETLW	00000110B   ;1
    RETLW	01011011B   ;2
    RETLW	01001111B   ;3
    RETLW	01100110B   ;4
    RETLW	01101101B   ;5
    RETLW	01111101B   ;6
    RETLW	00000111B   ;7
    RETLW	01111111B   ;8
    RETLW	01101111B   ;9
    RETLW	01110111B   ;A
    RETLW	01111100B   ;B
    RETLW	00111001B   ;C
    RETLW	01011110B   ;D
    RETLW	01111001B   ;E
    RETLW	01110001B   ;F
    
    
;--------------configuracion--------------
main:
    
    BANKSEL ANSEL	
    clrf    ANSEL	
    clrf    ANSELH
   
    BANKSEL TRISA	
    clrf TRISA
    clrf TRISB
    clrf TRISC
    clrf TRISD
    clrf TRISE
    
    BANKSEL PORTA
    clrf PORTA
    clrf PORTB
    clrf PORTC
    clrf PORTD
    
    call config_timers
    
;---------------loop----------
loop:
    reset2
    BANKSEL PORTA
    call dividir_nibble	
    
    btfss pestaneo, 0
    call  preparar_nibble	
    
    btfsc pestaneo, 0
    call parpadeo	
goto loop

;---------------subrutinas---------- 
dividir_nibble:    
    movf    contador, w
    andlw   00001111B
    movwf   nibble
    swapf   contador, w	
    andlw   00001111B
    movwf   nibble+1 
    return
    
preparar_nibble:   
    movf    nibble, w
    call    sietes
    movwf   disp_var, F		
    movf    nibble+1, w
    call    sietes
    movwf   disp_var+1, F	
    bsf	    PORTD, 0
    return

parpadeo:	    
    movlw   0
    movwf   disp_var
    movwf   disp_var+1
    bcf	    PORTD, 0
    return
    
reset0:
    movlw   255	   
    movwf   TMR0
    bcf	    T0IF    

config_timers:		    
    BANKSEL OSCCON
    bcf	    IRCF2   
    bsf	    IRCF1   
    bcf	    IRCF0   
    bsf	    SCS	    

    BANKSEL INTCON
    bsf	    GIE		
    bsf	    T0IE	
    bcf	    T0IF
    
    BANKSEL PIE1
    bsf	    TMR2IE	
    bsf	    TMR1IE	
    
    BANKSEL PIR1
    bcf	    TMR2IF	
    bcf	    TMR1IF	
   
    BANKSEL OPTION_REG
    BCF	    T0CS
    BCF	    PSA		
    BSF	    PS0		
    BSF	    PS1
    BSF	    PS2
   
    BANKSEL T1CON
    bsf	    T1CKPS1	
    bsf	    T1CKPS0
    bcf	    TMR1CS	
    bsf	    TMR1ON	
    
    BANKSEL T2CON
    movlw   1001110B   
    movwf   T2CON 
    return
end