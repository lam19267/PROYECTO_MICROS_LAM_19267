; Laboratorio 02
; Archivo:      main.S
; Dispositivo:	PIC16F887
; Autor:	Guillermo Lam
; Compilador:	pic-as (v2.30), MPLABX V5.45
;
; Programa:	contador en el puerto A
; Hardware:	LEDs en el puerto A
;
; Creado: 9 feb, 2021
; Ultima modificacion: 12 feb, 2021

PROCESSOR 16F887
#include <xc.inc>

;configuration word 1
CONFIG FOSC=XT // Oscilador interno sin salidas
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

PSECT resVect, class=CODE, abs, delta=2
;--------------vector reset--------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main
    
PSECT code, delta=2, abs
ORG 100h ;posición para el codigo
;--------------configuracion--------------
main:
   banksel ANSEL    ;Se selecciona el banco 3
   clrf ANSEL	    ;Se ponen los pines digitales
   clrf ANSELH	    ;Se ponen los pines digitales
   
   
   banksel TRISA    ;Se selecciona el banco 1
   movlw 11011111B  ;Se definen outputs e inputs a TRISA
   movwf TRISA	    ;Se carga la configuración de inputs y outputs a TRISA
   movlw 00000000B  ;Se definen outputs e inputs a TRISB
   movwf TRISB	    ;Se carga la configuración de inputs y outputs a TRISB
   movlw 00000000B  ;Se definen outputs e inputs a TRISC
   movwf TRISC	    ;Se carga la configuración de inputs y outputs a TRISC
   movlw 00000000B  ;Se definen outputs e inputs a TRISD
   movwf TRISD	    ;Se carga la configuración de inputs y outputs a TRISD
    
   
   banksel PORTA    ;Se selecciona el banco 0
   clrf PORTA	    ;Se ponen los PORTs en 0
   clrf PORTB	    
   clrf PORTC	    
   clrf PORTD	    
   
    
 ;---------------loop----------
 loop:
    btfsc PORTA, 0	;Revisa si el boton 1 está en 0	    
    call incrementar1	;LLama a la función incrementar1
	
    btfsc PORTA, 1	;Revisa si el boton 2 está en 0		    
    call decrementar1	;LLama a la función decrementar1
	
    btfsc PORTA, 2	;Revisa si el boton 3 está en 0		    
    call incrementar2	;LLama a la función incrementar2
	    
    btfsc PORTA, 3	;Revisa si el boton 4 está en 0	   	    
    call decrementar2	;LLama a la función decrementar2	

    btfsc PORTA, 4	;Revisa si el boton 5 está en 0		    
    call suma		;LLama a la función suma
  
 goto loop		;Regresa al loop
;---------------sub rutinas----------
incrementar1:		;Función de incrementar1
    btfsc PORTA, 0	;Revisa si el boton 1 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    incf PORTB, 1	;Incrementa el PORTB en 1
    return		;Retorna a la función

decrementar1:		;Función de decrementar1
    btfsc PORTA, 1	;Revisa si el boton 2 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    decf PORTB, 1	;Decrementa el PORTB en 1
    return		;Retorna a la función
    
incrementar2:		;Función de incrementar2
    btfsc PORTA, 2	;Revisa si el boton 3 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    incf PORTC, 1	;Incrementa el PORTC en 1
    return		;Retorna a la función
    
decrementar2:		;Función de decrementar2
    btfsc PORTA, 3	;Revisa si el boton 4 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    decf PORTC, 1	;Decrementa el PORTC en 1
    return		;Retorna a la función
 
 suma:			;Función de suma
    btfsc PORTA, 4	;Revisa si el boton 5 está en 0
    goto $-1		;Regresa una linea para el antirrebote
    movf PORTB, 0	;Se mueve el PORTB a W
    addwf PORTC, 0	;Se suma el PORTC a W
    movwf PORTD		;Copia W al PORTD
    return		;Retorna a la función
    
end			;Termina el codigo

