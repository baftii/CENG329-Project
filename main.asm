;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------

; INPUTS
; Button1 P2.4
; Button2 P2.5
; Button3 P2.6
; Button4 P2.7

; OUTPUTS
; Pattern LED1 P1.3
; Pattern LED2 P1.4
; Pattern LED3 P1.5
; Pattern LED4 P1.6
; Winning LED P2.2

main:
	call #defaultInit
	call #pinConfiguration

defaultInit:
	; Delay sistemini CPU 1MHz'de çalışacak diye kurguladığımız için
	; emin olmak için clock kalibrasyon değerleri 1MHz olarak ayarlıyoruz.
	mov.b &CALBC1_1MHZ, &BCSCTL1
	mov.b &CALDCO_1MHZ, &DCOCTL

	; Random generation için ACLK kaynağını tek seferlik değiştirdik
	bis.b #LFXT1S_2, &BCSCTL3

pinConfiguration:
	; Port1
	; Reset 0x00
	bic.w #0xFF, &P1OUT
	bic.w #0xFF, &P1IN
	bic.w #0xFF, &P1SEL
	bic.w #0xFF, &P1SEL2
	bic.w #0xFF, &P1DIR
	bic.w #0xFF, &P1REN

	; Outputs
	bic.w #BIT3|BIT4|BIT5|BIT6, &P1SEL
	bic.w #BIT3|BIT4|BIT5|BIT6, &P1SEL2
	bis.w #BIT3|BIT4|BIT5|BIT6, &P1DIR
	bic.w #BIT3|BIT4|BIT5|BIT6, &P1OUT

	; Port2
	; Reset 0x00
	bic.w #0xFF, &P2OUT
	bic.w #0xFF, &P2IN
	bic.w #0xFF, &P2SEL
	bic.w #0xFF, &P2SEL2
	bic.w #0xFF, &P2DIR
	bic.w #0xFF, &P1REN

	; Inputs
	bic.w #BIT4|BIT5|BIT6|BIT7, &P2SEL
	bic.w #BIT4|BIT5|BIT6|BIT7, &P2SEL2
	bic.w #BIT4|BIT5|BIT6|BIT7, &P2DIR
	bis.w #BIT4|BIT5|BIT6|BIT7, &P2REN ; resistor-on
	bis.w #BIT4|BIT5|BIT6|BIT7, &P2OUT ; pull-up

	; Outputs
	bic.w #BIT2, &P2SEL
	bic.w #BIT2, &P2SEL2
	bis.w #BIT2, &P2DIR
	bic.w #BIT2, &P2OUT

	; Interrupts
	; TODO: EKLENECEK

	ret

; Random sayı üretimi için kullanılmaktadır.
; Texas Instrument'ın SLAA338A kodlu dokümanı örnek alınarak
; implemente edilmiştir. Bu random sayı üretimi VLO ve DCO
; saatlarinin arasındaki fark esas alınarak sağlanmaktadır.
getRandomNumber:
	mov.w #TASSEL_2 + MC_2, &TACTL
	mov.w #CM_1 + CCIS_1 + CAP, &TACCTL0
	bic.w #CCIFG, &TACCTL0

waitVLO:
	bit.w #CCIFG, &TACCTL0
	jz waitVLO
	mov.w &TACCR0, r12
	clr.w &TACTL
	bic.w #CCIFG, &TACCTL0

	ret

; Aşağıda yer alan subroutinler belirli aralıklarda random değer üretmek için eklendi
; Isterler gereksinimler doğrultusunda bu aralıkların sık kullanılacağı düşünüldüğü için
; aralık işlemleri kod içerisinde yapılması yerine özel subroutinlere ayrıldı

; 1-2
getRandom2:
	call getRandomNumber
	and.w #00000001b, r12
	inc.w r12
	ret

; 1-4
getRandom4:
	call getRandomNumber
	and.w #000000011b, r12
	inc.w r12
	ret

; 1-8
getRandom8:
	call getRandomNumber
	and.w #00000111b, r12
	inc.w r12
	ret

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
