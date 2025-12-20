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
; Pattern LED1 P1.2
; Pattern LED2 P1.3
; Pattern LED3 P1.4
; Pattern LED4 P1.5
; Winning LED P2.2

main:
	call #defaultInit
	jmp mainLoop

mainLoop:
	call #preGame
	call #inGame
	call #endGame

	jmp mainLoop

; ###############################################
; 			Pre-Game Fonksiyonları
; ###############################################

preGame:
	call #preGameInit
	call #preGameStart
	call #preInTransition

	mov.b #0, &isPreGame
	ret

preGameInit:
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IE
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IES
	clr.b &P2IFG

	ret

; Başlangıçta çalışacak olan sırayla yakma subroutine
preGameStart:
	bis.b #BIT2, &P1OUT
        call #delay1sec
        xor.b #BIT3|BIT2, &P1OUT
        call #delay1sec
        xor.b #BIT4|BIT3, &P1OUT
        call #delay1sec
        xor.b #BIT5|BIT4, &P1OUT
        call #delay1sec
        bic.b #BIT5, &P1OUT
	jmp preGameStart

; Butona basılı tuttuğumuz sırada çalışacak subroutine

; =================================================================
; Pre Game Transition state where it turns the leds on sequentially
; =================================================================

preGameTransition:
    
    bis.b #BIT5, &P1OUT
    call #delay1sec
	
    
    bis.b #BIT4, &P1OUT
    call #delay1sec

    
    bis.b #BIT3, &P1OUT
    call #delay1sec

    
    bis.b #BIT2, &P1OUT
    call #delay1sec

	bic.b #BIT4, &P2IE

    ret
;=================================================================




; Butona basılı tutma bittikten sonra çalışacak fonksiyon

; ===================================================================================
; Pre Game Transition state after the button is pressed where it makes the leds blink
; ===================================================================================
preInTransition:
    push r4
    push r9
    mov.w #20,r9

blinkWhile:
	mov.w  #1300,r4 ; blink consequently with 1.3 second delays

	call #delaySubRoutine

	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT

    dec.w r9
    jnz blinkWhile ; if r9!=0 keep blinking

    call #delaySubRoutine
    
    jmp endBlinkWhile

endBlinkWhile:
	bic.b #BIT4, &P2IE
    pop r9
	pop r4
    ret
;==========================================================================================



	

; ###############################################
; 			In-Game Fonksiyonları
; ###############################################

inGame:
	call #inGameReset
	jmp inGameLoop

inGameLoop:
	call #gamePlay
	inc.b &currentPatternStep
	cmp.b &maxPatternStep, &currentPatternStep
	jne inGameLoop
	ret

inGameReset:
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IES
	bic.b #BIT7|BIT6|BIT5|BIT4, &P2IE
	bic.b #BIT7|BIT6|BIT5|BIT4, &P2IFG

	bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT

	clr.b &currentPatternStep
	call #getRandom2
	incd.w r12
	mov.b r12, &maxPatternStep
	ret

gamePlay:
	mov.w SP, &inGameReturnSP

	cmp.b #0, &currentPatternStep
	jeq easyGame ; 3-4 LED time 750 - 1000 ms

	cmp.b #1, &currentPatternStep
	jeq mediumGame ; 4-5 LED time 600 - 850 ms

	cmp.b #2, &currentPatternStep
	jeq hardGame ; 6-7 LED time 500 - 750 ms

	cmp.b #3, &currentPatternStep
	jeq hardestGame ; 8-9 LED time 350 - 600 ms

easyGame:
	call #getRandom2
	incd.w r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #750, r14
	call #calculateTimes

	jmp gameGO

mediumGame:
	call #getRandom2
	add.w #3, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #600, r14
	call #calculateTimes

	jmp gameGO

hardGame:
	call #getRandom2
	add.w #5, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #500, r14
	call #calculateTimes

	jmp gameGO

hardestGame:
	call #getRandom2
	add.w #7, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #350, r14
	call #calculateTimes

	jmp gameGO

gameGO:
	clr.w r7 ; LED counter

	call #representLED
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IE

	mov.w #10000, r4
	call #delaySubRoutine
	jmp restartGame

restartGame:
	mov.w #mainLoop, 0(SP)

	bic.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	bis.w #BIT3, &P1OUT
	call #delay250msec
	bis.w #BIT4, &P1OUT
	call #delay250msec
	bis.w #BIT2, &P1OUT
	call #delay250msec
	bis.w #BIT5, &P1OUT
	call #delay250msec
	xor.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	call #delay250msec
	xor.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	call #delay250msec
	xor.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	call #delay250msec
	xor.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	call #delay250msec
	xor.w #BIT5|BIT4|BIT3|BIT2, &P1OUT
	call #delay250msec

	ret

representLED:
	push r5
	push r6

	clr.w r5 ; LED Counter
	clr.w r6 ; Time counter
	jmp representLEDLoop

representLEDLoop:
	cmp.w r5, &currentLEDCount
	jeq representLEDEnd

	mov.b patternTimeData(r6), r4
	inc.w r6

	cmp.b #1, patternLEDData(r5)
	jeq led1On

	cmp.b #2, patternLEDData(r5)
	jeq led2On

	cmp.b #3, patternLEDData(r5)
	jeq led3On

	cmp.b #4, patternLEDData(r5)
	jeq led4On

led1On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT2, &P1OUT
	call #delaySubRoutine
	jmp representLEDLoop

led2On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT3, &P1OUT
	call #delaySubRoutine
	jmp representLEDLoop

led3On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT4, &P1OUT
	call #delaySubRoutine
	jmp representLEDLoop

led4On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT5, &P1OUT
	call #delaySubRoutine
	jmp representLEDLoop

representLEDEnd:
	pop r6
	pop r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	ret

calculateTimes:
	push r13
	clr.w r13
	jmp calculateTimeLoopCheck

calculateTimeLoopCheck:
	cmp.b r13, &currentTimeCount
	jne calculateTimeLoop
	pop r13
	ret

calculateTimeLoop:
	call #getRandom250
	add.w r14, r12
	mov.b r12, patternTimeData(r13)
	inc.w r13
	jmp calculateTimeLoopCheck

calculateLEDs:
	push r13
	clr.w r13
	jmp calculateLEDLoopCheck

calculateLEDLoopCheck:
	cmp.b r13, &currentLEDCount
	jne calculateLEDLoop
	pop r13
	ret

calculateLEDLoop:
	call #getRandom4
	mov.b r12, patternLEDData(r13)
	inc.w r13
	jmp calculateLEDLoopCheck

; ###############################################
; 			End-Game Fonksiyonları
; ###############################################

endGame:
	bis.b #BIT2, &P2OUT

	mov.w #3000, r4
	call #delaySubRoutine

	bis.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	call #delay250msec
	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT

	bic.b #BIT2, &P2OUT

	ret

; ###############################################
; 			Başlangıç Fonksiyonları
; ###############################################

; Temel başlangıç ayarlarını yapan subroutine'dir
defaultInit:
	; Delay sistemini CPU 1MHz'de çalışacak diye kurguladığımız için
	; emin olmak için clock kalibrasyon değerleri 1MHz olarak ayarlıyoruz.
	mov.b &CALBC1_1MHZ, &BCSCTL1
	mov.b &CALDCO_1MHZ, &DCOCTL

	; Random generation için ACLK kaynağını tek seferlik değiştirdik
	bis.b #LFXT1S_2, &BCSCTL3
	call #pinConfiguration
	jmp exit

; Pin ayarlamalarını yapan temel subroutinedir
pinConfiguration:
	; Port1
	; Reset 0x00
	bic.b #0xFF, &P1OUT
	bic.b #0xFF, &P1IN
	bic.b #0xFF, &P1SEL
	bic.b #0xFF, &P1SEL2
	bic.b #0xFF, &P1DIR
	bic.b #0xFF, &P1REN

	; Outputs
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1SEL
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1SEL2
	bis.b #BIT2|BIT3|BIT4|BIT5, &P1DIR
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT

	; Port2
	; Reset 0x00
	bic.b #0xFF, &P2OUT
	bic.b #0xFF, &P2IN
	bic.b #0xFF, &P2SEL
	bic.b #0xFF, &P2SEL2
	bic.b #0xFF, &P2DIR
	bic.b #0xFF, &P1REN

	; Inputs
	bic.b #BIT4|BIT5|BIT6|BIT7, &P2SEL
	bic.b #BIT4|BIT5|BIT6|BIT7, &P2SEL2
	bic.b #BIT4|BIT5|BIT6|BIT7, &P2DIR
	bis.b #BIT4|BIT5|BIT6|BIT7, &P2REN ; resistor-on
	bis.b #BIT4|BIT5|BIT6|BIT7, &P2OUT ; pull-up

	; Outputs
	bic.b #BIT2, &P2SEL
	bic.b #BIT2, &P2SEL2
	bis.b #BIT2, &P2DIR
	bic.b #BIT2, &P2OUT

	; Interrupts
	bis.w #GIE, SR

	ret

; ###############################################
; 			Random Value Generation
; ###############################################

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
	call #getRandomNumber
	and.w #00000001b, r12
	inc.w r12
	ret

; 1-4
getRandom4:
	call #getRandomNumber
	and.w #000000011b, r12
	inc.w r12
	ret

; 1-8
getRandom8:
	call #getRandomNumber
	and.w #00000111b, r12
	inc.w r12
	ret

; 0-250
getRandom250:
	call #getRandomNumber
	dec.w r12
	jmp getRandom250Loop

getRandom250Loop:
	cmp.w #250, r12
	jl getRandom250End

	sub.w #250, r12
	jmp getRandom250Loop

getRandom250End:
	inc.w r12
	ret

; ###############################################
; 				Delay Subroutine
; ###############################################

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
; Çağrılacak ana subroutinedır. R4'teki argümana göre delay yapar.
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

calculateOuterCount:
	clr.w r5

outerCountLoop:
	sub.w #50, r4
	jn calculateOuterCountFinal
	inc.w r5
	jmp outerCountLoop

calculateOuterCountFinal:
	ret

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

delay2sec:
	push r4
	mov.w #2000, r4
	call #delaySubRoutine
	pop r4
	ret
	
delay1sec:
	push r4
	mov.w #1000, r4
	call #delaySubRoutine
	pop r4
	ret

delay250msec:
	push r4
	mov.w #250, r4
	call #delaySubRoutine
	pop r4
	ret

; ###############################################
;						EXIT
; ###############################################
exit:
	nop

; ###############################################
; 				  PORT2 Interrupt
; ###############################################
Port2InterruptSubroutine:
	cmp.b #1, &isPreGame
	jeq preGameInterrupt
	jmp inGameInterrupt

preGameInterrupt:
	bit.b #BIT5|BIT6|BIT7, &P2IFG
	jnz easterCheck

	bit.b #BIT4, &P2IFG
	jnz playButtonCheck

	reti

; Button4 (BIT7) -> Button4 (BIT7) -> Button2 (BIT5) -> Button3 (BIT6) -> Button2 (BIT5) -> Button1 (BIT4)
easterCheck:
	bit.b #BIT5, &P2IFG
	jnz bit5EasterCheck

	bit.b #BIT6, &P2IFG
	jnz bit6EasterCheck

	bit.b #BIT7, &P2IFG
	jnz bit7EasterCheck

bit7EasterCheck:
	cmp.b #0, &preGameCount
	jeq easterEggInc
	cmp.b #1, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

bit6EasterCheck:
	cmp.b #3, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

bit5EasterCheck:
	cmp.b #2, &preGameCount
	jeq easterEggInc
	cmp.b #4, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

easterEggInc:
	inc.w &preGameCount
	reti

playButtonCheck:
	cmp.b #5, &preGameCount
	jeq easterEggExecute

	clr.b &preGameCount
	jmp playButtonExecute

playButtonExecute:
	cmp.b #0, &isPreTransition
	jeq goTransition
	jmp goPreGame

goTransition:
	mov.b #1, &isPreTransition

	mov.w SP, &preGameReturnSP

	mov.w 2(SP), &preGameReturnPC
	mov.w 0(SP), &preGameReturnSR
	mov.w #preGameTransition, 2(SP)

	bic.b #BIT7|BIT6|BIT5, &P2IE

	clr.b &P2IFG
	xor.b #BIT4, &P2IES
	reti

goPreGame:
	mov.b #0, &isPreTransition

	mov.w &preGameReturnSP, SP

	mov.w &preGameReturnPC, 2(SP)
	mov.w &preGameReturnSR, 0(SP)

	bis.b #BIT7|BIT6|BIT5, &P2IE

	clr.b &P2IFG
	xor.b #BIT4, &P2IES
	reti

; EasterEgg sırasında çalışacak interrupt Subroutine
easterEggExecute:

	reti


inGameInterrupt:
	bit.b #BIT4, &P2IFG
	jnz handleButtonLED1

	bit.b #BIT5, &P2IFG
	jnz handleButtonLED2

	bit.b #BIT6, &P2IFG
	jnz handleButtonLED3

	bit.b #BIT7, &P2IFG
	jnz handleButtonLED4

handleButtonLED1:
	bit.b #BIT2, &P1OUT
	jnz led1Change

	cmp.b #1, patternLEDData(r7)
	jeq led1Up

	mov.w #restartGame, 2(SP)
	reti

led1Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led1Change

led1Change:
	xor.b #BIT2, &P1OUT
	xor.b #BIT4, &P2IES
	bic.b #BIT4, &P2IFG
	reti

handleButtonLED2:
	bit.b #BIT3, &P1OUT
	jnz led2Change

	cmp.b #2, patternLEDData(r7)
	jeq led2Up

	mov.w #restartGame, 2(SP)
	reti

led2Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led2Change

led2Change:
	xor.b #BIT3, &P1OUT
	xor.b #BIT5, &P2IES
	bic.b #BIT5, &P2IFG
	reti

handleButtonLED3:
	bit.b #BIT4, &P1OUT
	jnz led3Change

	cmp.b #3, patternLEDData(r7)
	jeq led3Up

	mov.w #restartGame, 2(SP)
	reti

led3Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led3Change

led3Change:
	xor.b #BIT4, &P1OUT
	xor.b #BIT6, &P2IES
	bic.b #BIT6, &P2IFG
	reti

handleButtonLED4:
	bit.b #BIT5, &P1OUT
	jnz led4Change

	cmp.b #4, patternLEDData(r7)
	jeq led4Up

	mov.w #restartGame, 2(SP)
	reti

led4Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led4Change

led4Change:
	xor.b #BIT5, &P1OUT
	xor.b #BIT7, &P2IES
	bic.b #BIT7, &P2IFG
	reti

nextGame:
	mov.w &inGameReturnSP, SP
	ret

			.data
isPreGame: .byte 1
isPreTransition: .byte 0
preGameCount: .byte 0
preGameReturnPC: .word 0
preGameReturnSR: .word 0
preGameReturnSP: .word 0

inGameReturnSP: .word 0

patternLEDData: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
patternTimeData: .word 0, 0, 0, 0, 0, 0, 0, 0, 0
currentLEDCount: .byte 0
currentTimeCount: .byte 0
maxPatternStep: .byte 0
currentPatternStep: .byte 0

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
			.sect	".int03"				; Port2 Interrupt
			.short	Port2InterruptSubroutine
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET
            
