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
	call #pinConfiguration

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

; milisaniye olarak parametre alacak - r4 -> input
; r5, r6, r7 kullanılan registerlar
; CPU 1MHz = 1 000 000 Hz ---- 1000 milisaniyede 1 000 000 kere cycle donuyor
; 16-bit sistem düzeyinde çalıştığımız için programlamayı kolaylaştırmak için
; 50 milisaniye hassasiyette çalışacak şekilde implemente edilmiştir. Bu amaç
; doğrultusunda 50 milisaniyede harcanacak olan cycle sayısı 50 000'dır. Bu
; cycle'ı harcatacak bir inner loop bulunacaktır. Dışarıda ise bu 50 milisaniyeden
; kaç kere çalışacağını takip edecek outer loop olacaktır. Argüman olarak alınan
; bekleme süresi 50'ye bölünecek ve outer count bulunacaktır.

; Delay süresi tahmini süre vermektedir. outercount calculation push ve pop işlemleri
; delay süresi hesabına katılmamıştır.

; Input minimum 50 olmalıdır.
delaySubRoutine:
	; Register koruma
	push r5
	push r6
	push r7

	call #calculateOuterCount
	call #waitDelay

	; Korunan Registerlari geri alma
	pop r7
	pop r6
	pop r5

	ret

; =========================

calculateOuterCount:
	clr.w r5

outerCountLoop:
	sub.w #50, r4
	jn calculateOuterCountFinal
	inc.w r5
	jmp outerCountLoop

calculateOuterCountFinal:
	ret

; =========================

waitDelay:
	clr.w r6

waitDelayOuterLoopInit:
	cmp.w r5, r6
	jeq waitDelayFinal
	clr.w r7

waitDelayInnerLoop:
	inc.w r7 ; 1 cycle
	cmp.w #10000, r7 ; 2 cycle
	jne waitDelayInnerLoop ; 2 cycle
	; Total 5 cycle --- 50 000 olması için 10 000 kere dönmesi lazım o yüzden 10 000 ile cmp yapıyoruz

waitDelayOuterLoopFinal:
	inc.w r6
	jmp waitDelayOuterLoopInit

waitDelayFinal:
	ret

; =========================

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
            
