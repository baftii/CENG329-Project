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

; INPUTS
; Button1 P2.4
; Button2 P2.5
; Button3 P2.6
; Button4 P2.7

; OUTPUTS
; Onboard Green P1.6
; Onboard Red P1.0
; Pattern LED1 P1.2
; Pattern LED2 P1.3
; Pattern LED3 P1.4
; Pattern LED4 P1.5
; Winning LED P2.2

; @brief label that the start point of the user defined program
; 		 Label calls defaultInit label for resetting al default
;        values of the variables and registers. After that it
;		 jump to the mainLoop
main:
	call #defaultInit
	jmp mainLoop

; @brief label that responsible for real game. It continues forever
;        The simon's says game has 3 major part. preGame, inGame and
;        endGame. This label calls this parts one by one and repeats
;        itself.
mainLoop:
	call #preGame
	call #inGame
	call #endGame

	jmp mainLoop

; ###############################################
; 				Pre-Game Part
; ###############################################

; @brief label of the start point of preGame part of the simon's says
;        game. Firstly it calls preGameInit label to configure ports
;        and variables for preGame part. After it will save stack pointer
;        to the variable called returnPreTransitionSP. We did this because
;        we are using stack pointer manipulation while we are in preGameStart
;        with interrupts. Therefore we need to save our base SP in preGame
;        This process can be understood with label playButtonExecute
; @related playButtonExecute, goTransition, goPreGame
preGame:
	call #preGameInit
	mov.w SP, &returnPreTransitionSP
	decd.w &returnPreTransitionSP ; we are decrementing it because after that we are calling preGameStart. We want to address of return point of preGameStart
	call #preGameStart ; This subroutine normally continues for forever but related IRQ will break this
	bic.w #BIT7|BIT6|BIT5|BIT4, &P2IE ; we are disable the buttons interrupts because if we reach this point going inGame need to be guaranteed and non-interruptable
	call #preInTransition

	mov.b #0, &isPreGame
	ret

; @brief this label configures button's interrupt edge to falling edge 
;        because we are using pull-up buttons and it will enable
;        interrupts for this buttons
preGameInit:
	clr.b &P2IFG
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IES
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IE

	ret

; @brief this label will open the LEDs one by one. It will goes until
;        related interrupts happen
; @related playButtonExecute, goPreGame
preGameStart:
	bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT
	bis.b #BIT2, &P1OUT
    call #delay1sec
    bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT
    bis.b #BIT3, &P1OUT
    call #delay1sec
    bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT
    bis.b #BIT4, &P1OUT
    call #delay1sec
    bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT
    bis.b #BIT5, &P1OUT
    call #delay1sec
    bic.b #BIT5, &P1OUT
	jmp preGameStart

; @brief this label runs while button1 is pressed in preGameStart.
; @related playButtonExecute, goTransition
preGameTransition:
	bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT
    bis.b #BIT2, &P1OUT
    call #delay1sec

    bis.b #BIT3, &P1OUT
    call #delay1sec

    bis.b #BIT4, &P1OUT
    call #delay1sec

    bis.b #BIT5, &P1OUT
    call #delay1sec

	bic.b #BIT4, &P2IE

	mov.w &returnPreTransitionSP, SP
	ret

; @brief Main purpose of this label to give free time to the user
;        when we are going into inGame part of the game. If this
;        label don't exist. InGame will start instantly and user
;        can't react it.
preInTransition:
    push r4
    push r9
    mov.w #5,r9
	jmp blinkWhile

; @brief loop body of preInTransition
; @related preInTransition
blinkWhile:
	mov.w  #800, r4
	call #delaySubRoutine

	xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT

    dec.w r9
    jnz blinkWhile

    mov.w #800, r4
    call #delaySubRoutine
    jmp endBlinkWhile

; @brief end point of preInTransition
; @related preInTransition
endBlinkWhile:
	bic.b #BIT4, &P2IE
    pop r9
	pop r4
    ret

; ###############################################
; 				In-Game Parts
; ###############################################

; @brief the starting point of the inGame part of the game
;        it calls inGameReset to reset variables and registers 
;        for inGame part.
inGame:
	call #inGameReset
	jmp inGameLoop

; @brief loop body of inGame. By that function we are keeping
;        game step. By requirements we need to play game for 
;        at least 3 times. This label ensures that at least 3
;        games are played
; @related inGame
inGameLoop:
	call #gamePlay
	inc.b &currentPatternStep
	cmp.b &maxPatternStep, &currentPatternStep
	jne inGameLoop
	ret

; @brief this label configures buttons interrupt registers for
;        ingame part. And this label also calculates how many
;        times game will be played randomly and saves into
;        variable called maxPatternStep
inGameReset:
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IES
	bic.b #BIT7|BIT6|BIT5|BIT4, &P2IE
	bic.b #BIT7|BIT6|BIT5|BIT4, &P2IFG

	bic.b #BIT5|BIT4|BIT3|BIT2, &P1OUT

	clr.b &currentPatternStep
	call #getRandom2
	incd.w r12
	mov.b r12, &maxPatternStep ; maxPatternStep takes value between 3-4 (included)
	ret

; @brief By this label we are adjusting the difficulty of the
;        game with respect the current iteration
; @related nextGame
gamePlay:
	mov.w SP, &inGameReturnSP ; We are saving the stack pointer at this point because we are determining the pattern succesfully achieved or not in interrupts
	                          ; If we achieves we are manipulating the stack pointer to going next step. This method handled in nextGame label.

	cmp.b #0, &currentPatternStep
	jeq easyGame ; 3-4 LED time 1500 - 2250 ms

	cmp.b #1, &currentPatternStep
	jeq mediumGame ; 4-5 LED time 1250 - 2000 ms

	cmp.b #2, &currentPatternStep
	jeq hardGame ; 6-7 LED time 750 - 1500 ms

	cmp.b #3, &currentPatternStep
	jeq hardestGame ; 8-9 LED time 500 - 1250 ms

; @brief This label configures LED count and time values for easy difficulty
;        it will run when currentPatternStep is equal to 0
;        LED count will be between 3-4 (included)
;        Delay time will be between 1500-2250ms (included)
easyGame:
	call #getRandom2
	incd.w r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #1500, r14
	call #calculateTimes

	jmp gameGO

; @brief This label configures LED count and time values for medium difficulty
;        it will run when currentPatternStep is equal to 0
;        LED count will be between 4-5 (included)
;        Delay time will be between 1250-2000 (included)
mediumGame:
	call #getRandom2
	add.w #3, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #1250, r14
	call #calculateTimes

	jmp gameGO

; @brief This label configures LED count and time values for hard difficulty
;        it will run when currentPatternStep is equal to 0
;        LED count will be between 6-7 (included)
;        Delay time will be between 750-1500 (included)
hardGame:
	call #getRandom2
	add.w #5, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #750, r14
	call #calculateTimes

	jmp gameGO

; @brief This label configures LED count and time values for hardest difficulty
;        it will run when currentPatternStep is equal to 0
;        LED count will be between 8-9 (included)
;        Delay time will be between 500-1250 (included)
hardestGame:
	call #getRandom2
	add.w #7, r12
	mov.b r12, &currentLEDCount
	mov.b &currentLEDCount, &currentTimeCount
	dec.b &currentTimeCount

	call #calculateLEDs

	mov.w #500, r14
	call #calculateTimes

	jmp gameGO

; @brief This label is the main label of inGame part of the game.
;        By the values in patternLEDData and patternTimeData arrays
;        it shows randomly generated LED pattern and it will wait 10
;        seconds. If the timeout happens it will restart the game
;        The pattern check is controlled in interrupts. Therefore,
;        this subroutine don't do anything for checking. For control
;        related subroutines are below
; @related patternLEDData
gameGO:
	clr.w r7

	call #representLED
	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IE

	mov.w #10000, r4
	call #delaySubRoutine
	jmp restartGame

; @brief This label will restart game if the timeout happens in gameGo
;        label. It resets the tracking parameters for the game and reset
;        the stack. After all it will restart the program by going mainLoop
;        label
restartGame:
	clr.b &P1OUT
    clr.b &isEasterActive
    
    bis.b #BIT0, &P1OUT

    mov.w #4, r15
	jmp restartBlinkLoop

; @brief loop body of restartGame label if will blink all the exterior LED
;        amount given in parameter
; @related restartGame
; @param r15 - amount of how many times will LEDs blink
restartBlinkLoop:
    bis.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
    call #delay250msec
    bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
    call #delay250msec
    dec.w r15
    jnz restartBlinkLoop
	jmp restartGameEnd

; @brief end of the restartGame label
restartGameEnd:
    bic.b #BIT0, &P1OUT

    mov.w #__STACK_END, SP ; We are resetting the stack with manipulating stack pointer
	decd.w SP ; we decrement it because we are going to ret instruction for mainLoop. Therefore we give the space for it.
    mov.w #mainLoop, 0(SP)
    bic.b #BIT4|BIT5|BIT6|BIT7, &P2IFG
    
    ret

; @brief this label responsible for showing the randomly generated pattern
;        in LEDs. It is dependant for variables called patternLEDData and
;        patternTimeData. We did it because our difficulty and count of LED
;        changes in game. With this dependancy, we get a flexibilty.
; @param patternLEDData
; @param patternTimeData
; @uses r4 - for delaySubroutine argument
; @uses r5 - LED counter
; @uses r6 - Time counter
representLED:
	push r5
	push r6

	clr.w r5 ; LED Counter
	clr.w r6 ; Time counter
	dec.w r6
	jmp representLEDLoop

; @brief loop body of representLED
; @related representLED
representLEDLoop:
	cmp.b r5, &currentLEDCount ; check for is all pattern shown or not
	jeq representLEDEnd

	inc.w r6

	cmp.b #1, patternLEDData(r5)
	jeq led1On

	cmp.b #2, patternLEDData(r5)
	jeq led2On

	cmp.b #3, patternLEDData(r5)
	jeq led3On

	cmp.b #4, patternLEDData(r5)
	jeq led4On

; @brief If the currentPattern points to the LED1 this label will runs
led1On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT2, &P1OUT
	mov.b patternTimeData(r6), r4

	call #delaySubRoutine
	jmp representLEDLoop

; @brief If the currentPattern points to the LED2 this label will runs
led2On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT3, &P1OUT
	mov.b patternTimeData(r6), r4
	call #delaySubRoutine
	jmp representLEDLoop

; @brief If the currentPattern points to the LED3 this label will runs
led3On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT4, &P1OUT
	mov.b patternTimeData(r6), r4
	call #delaySubRoutine
	jmp representLEDLoop

; @brief If the currentPattern points to the LED4 this label will runs
led4On:
	inc.w r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	bis.b #BIT5, &P1OUT
	mov.b patternTimeData(r6), r4
	call #delaySubRoutine
	jmp representLEDLoop

; @brief end of the representLED
representLEDEnd:
	pop r6
	pop r5
	bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	ret

; @brief this label calculates the time intervals respect to given input
; @param r14 - minimum time
; @uses r13 - track the how many time is generated
calculateTimes:
	push r13
	clr.w r13
	jmp calculateTimeLoopCheck

; @brief loop condition check of calculateTimes
calculateTimeLoopCheck:
	cmp.b r13, &currentTimeCount
	jne calculateTimeLoop
	pop r13
	ret

; @brief loop body of calculateTimes
calculateTimeLoop:
	call #getRandom750
	add.w r14, r12
	mov.b r12, patternTimeData(r13)
	inc.w r13
	jmp calculateTimeLoopCheck

; @brief this label calculates the time intervals respect to given input
; @uses r13 - track the how many LED pattern is generated
calculateLEDs:
	push r13
	clr.w r13
	jmp calculateLEDLoopCheck

; @brief loop condition check of calculateLEDs
calculateLEDLoopCheck:
	cmp.b r13, &currentLEDCount
	jne calculateLEDLoop
	pop r13
	ret

; @brief loop body of calculateLEDs
calculateLEDLoop:
	call #getRandom4
	mov.b r12, patternLEDData(r13)
	inc.w r13
	jmp calculateLEDLoopCheck

; ###############################################
; 				End-Game Parts
; ###############################################

; @brief this label is starting point of endGame part of the game
;        it will clear related variables, blinks LED and waits to
;        give time to user
endGame:
	clr.b &isEasterActive
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
; 			Initilization Subroutines
; ###############################################

; @brief the label that handles all the first configuration all the game
defaultInit:
	mov.b &CALBC1_1MHZ, &BCSCTL1 ; We configured delaySubRoutine for 1MHz CPU Frequency. To ensure more consisting waitings
								 ; we write factory calibrated values to the control register of CPU
	mov.b &CALDCO_1MHZ, &DCOCTL

	bis.b #LFXT1S_2, &BCSCTL3 ; For random number generation we changed ACLK clock sources
	call #pinConfiguration
	ret

; @brief Label that configures all used IOs
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
	bis.b #BIT6|BIT0, &P1DIR
	bic.b #BIT6|BIT0, &P1OUT

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

; @brief this subroutine used for random value generation
;	     while we are creating this we used as a source Texas
;        Instrument's SLAA338A document. Basicly this subroutines
;        creates random value by differences VLO and DCO clock
;        It will ensure randomity by entropy of this clocks.
;        Clock frequencies affecting by environment it will give
;        entropy to the system
getRandomNumber:
	mov.w #TASSEL_2 + MC_2, &TACTL
	mov.w #CM_1 + CCIS_1 + CAP, &TACCTL0
	bic.w #CCIFG, &TACCTL0

; @brief loop body of getRandomNumber. It will wait until VLO
;        value is setted
waitVLO:
	bit.w #CCIFG, &TACCTL0
	jz waitVLO
	mov.w &TACCR0, r12
	clr.w &TACTL
	bic.w #CCIFG, &TACCTL0

	ret

; Below subroutines are originated by getRandomNumber subroutine
; However by requirement and our implementation some of the random
; value intervals are gonna be used more frequently. Therefore we
; created seperate subroutines for creating random number in specific
; interval

; 1-2
getRandom2:
	call #getRandomNumber
	and.w #0x0001, r12
	inc.w r12
	ret

; 1-4
getRandom4:
	call #getRandomNumber
	and.w #0x0003, r12
	inc.w r12
	ret

; 1-8
getRandom8:
	call #getRandomNumber
	and.w #0x0007, r12
	inc.w r12
	ret

; 0-750
getRandom750:
	call #getRandomNumber
	dec.w r12
	jmp getRandom750Loop

getRandom750Loop:
	cmp.w #750, r12
	jl getRandom750End

	sub.w #750, r12
	jmp getRandom750Loop

getRandom750End:
	inc.w r12
	ret

; ###############################################
; 				Delay Subroutine
; ###############################################

; @brief Main delay subroutine that waits based on the argument in R4.
;        This implementation assumes a CPU frequency of 1 MHz (1,000,000
;        cycles per second). To simplify programming on a 16-bit system,
;		 the delay is implemented with a granularity (resolution) of 50
;		 milliseconds. 
;        Inner Loop: Consumes exactly 50,000 cycles to achieve a 50ms delay.
;        Outer Loop: Controls how many 50ms blocks are executed. The input argument is
;                    divided by 50 to determine the outer loop count.
;
; 		 Note: The delay time is approximate. Cycle overheads for outer count calculation, 
; 		 division, and stack operations (push/pop) are not included in the delay calculation.
; @param r4 - Duration to wait in milliseconds. (Minimum value must be 50).
; @uses r5 - Registers used for loop counters and temporary calculations.
; @uses r6 - Registers used for loop counters and temporary calculations.
; @uses r7 - Registers used for loop counters and temporary calculations.
delaySubRoutine:
	push r4
	push r5
	push r6
	push r7

	call #calculateOuterCount
	call #waitDelay

	pop r7
	pop r6
	pop r5
	pop r4

	ret

; @brief subroutine that calculates how many times 50ms occurs in given input
; @param r4 - Duration to wait in milliseconds.
; @uses r5 - Registers used for loop counters and temporary calculations.
calculateOuterCount:
	clr.w r5

; @brief loop body of calculateOuterCount
outerCountLoop:
	sub.w #50, r4
	jn calculateOuterCountFinal
	inc.w r5
	jmp outerCountLoop

; @brief end of calculateOuterCount
calculateOuterCountFinal:
	ret

; @brief main subroutine for waiting time
; @uses r6 - Registers used for loop counters and temporary calculations.
; @uses r7 - Registers used for loop counters and temporary calculations.
waitDelay:
	clr.w r6

; @brief outer loop start of waitDelay
waitDelayOuterLoopInit:
	cmp.w r5, r6
	jeq waitDelayFinal
	clr.w r7

; @brief inner loop of waitDelay
waitDelayInnerLoop:
	inc.w r7 ; 1 cycle
	cmp.w #10000, r7 ; 2 cycle
	jne waitDelayInnerLoop ; 2 cycle
	; Total 5 cycle --- 50 000 olması için 10 000 kere dönmesi lazım o yüzden 10 000 ile cmp yapıyoruz

; @brief outer loop end of wait delay
waitDelayOuterLoopFinal:
	inc.w r6
	jmp waitDelayOuterLoopInit

; @brief end of waitDelay
waitDelayFinal:
	ret

; Below subroutines are originated by delaySubRoutine subroutine
; However by requirement and our implementation some of the delay
; intervals are gonna be used more frequently. Therefore we
; created seperate subroutines for waiting specific times.

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
; 				  PORT2 Interrupt
; ###############################################

; @brief IRQ subroutine of GPIO Port 2. Main of component of the game
;        It will react for all button actions. It branching two different
;        labels one is preGame one is inGame. This branching is controlled
;        by variable. This method give us characteristic for buttons functionality
;        respect to game situation
Port2InterruptSubroutine:
	cmp.b #1, &isPreGame
	jeq preGameInterrupt
	jmp inGameInterrupt

; @brief this label is runs when buttons are pressed while we are in preGame part
;        of the game
preGameInterrupt:
	bit.b #BIT5|BIT6|BIT7, &P2IFG ; Button2, Button3, Button4 is just used for easterEgg detection in preGame therefore firstly we are checking
								  ; which button occured interrupt
	jnz easterCheck

	bit.b #BIT4, &P2IFG ; Button1 is used for transition to inGame and easterEgg detection therefore we have unique label for button1
	jnz playButtonCheck

	reti

; Button4 (BIT7) -> Button4 (BIT7) -> Button2 (BIT5) -> Button3 (BIT6) -> Button2 (BIT5) -> Button1 (BIT4)
; @brief When the user in preGame if user presses button in combination shown in up,
;        easterEgg gonna be triggered. easterEgg will disbute button2, button3 and
;        button4 to their own labels to check this combination
easterCheck:
	bit.b #BIT5, &P2IFG
	jnz bit5EasterCheck

	bit.b #BIT6, &P2IFG
	jnz bit6EasterCheck

	bit.b #BIT7, &P2IFG
	jnz bit7EasterCheck

; @brief this label is used for button4 combination check
;        in given combination button4 need to be pressed firstly
;        and secondly. We are checking this and if it us true
;        we are incrementing the success count. If it is not
;        we are clearing the easterEgg success count
bit7EasterCheck:
	cmp.b #0, &preGameCount
	jeq easterEggInc
	cmp.b #1, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

; @brief this label is used for button3 combination check
;        in given combination button3 need to be pressed forthly
;        We are checking this and if it us true we are incrementing
;        the success count. If it is not we are clearing
;        the easterEgg success count
bit6EasterCheck:
	cmp.b #3, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

; @brief this label is used for button2 combination check
;        in given combination button2 need to be pressed thirdly
;        and fifthly. We are checking this and if it us true
;        we are incrementing the success count. If it is not
;        we are clearing the easterEgg success count
bit5EasterCheck:
	cmp.b #2, &preGameCount
	jeq easterEggInc
	cmp.b #4, &preGameCount
	jeq easterEggInc

	clr.b &preGameCount
	clr.b &P2IFG
	reti

; @brief this label is used for incrementing easterEgg success
;        count. It will run when button4, button3, button2 is
;        pressed in correct order
easterEggInc:
	inc.w &preGameCount
	reti

; @brief this label used for button1 control in preGame part of the game
;        firstly we are checking easterEgg. We put button1 into last element
;        of easterEgg. Because button1 has two jobs in preGame if we put
;        in middle of it we need to check much more thing and it will
;        compilate the code therefore we put into last we just checking
;        it is last element. If it is, it is easterEgg. If not it is
;        transition command.
playButtonCheck:
	cmp.b #5, &preGameCount
	jeq easterEggExecute

	clr.b &preGameCount
	jmp playButtonExecute

; @brief this label is used for button1 transition command. It will branching
;        respect to value in isPreTransition. This label creates main idea of
;        preGame. If falling-edge detects, it will go goTransition and switchs
;        mode with transition mode. If it detects rising edge before transition
;        mode is finished, it will go goPreGame to get back where it is before
;        transition. This established with stack manipulation.
playButtonExecute:
	cmp.b #0, &isPreTransition
	jeq goTransition
	jmp goPreGame

; @brief It runs when preGameStart is running and button1 is detected falling-edge
;        This label changes isPreTransition value because next time if interrupt 
;        occurs in button1 goPreGame need to run.
;        After it will record current stack pointer to preGameReturnSP. This value
;        is saved because if we need to go back goPreGame we need to know where we
;        were. Also we are recording preGameReturnPC, preGameReturnSR this purpose.
;        After saving we are 2(SP) value with preGameTranstion subroutine. Because
;        reti instruction will update PC with 2(SP).
;        Also we are disabling button4, button3 and button2 interrupts in this label
;        Because in preGameTransition this buttons are not useful we need to disable
;        for unwanted situations
goTransition:
	mov.b #1, &isPreTransition

	mov.w SP, &preGameReturnSP

	mov.w 2(SP), &preGameReturnPC
	mov.w 0(SP), &preGameReturnSR
	mov.w #preGameTransition, 2(SP)

	bic.b #BIT7|BIT6|BIT5, &P2IE

	clr.b &P2IFG
	xor.b #BIT4, &P2IES ; We are changing the edge because if unpress the button1 before complete of preGameTransition we need to know that
	reti

; @brief It runs when preGameTransition is running and button1 is detected rising-edge
;        This label is for returning last point preGameStart. While we goTransition, we
; 		 saved several values like PC, SR and SP. In this step, we are using this values
;        to get back this point. Also we are changing edge selection for detecting goTransition
;        next time.
goPreGame:
	mov.b #0, &isPreTransition

	mov.w &preGameReturnSP, SP

	mov.w &preGameReturnPC, 2(SP)
	mov.w &preGameReturnSR, 0(SP)

	bis.b #BIT7|BIT6|BIT5, &P2IE

	clr.b &P2IFG
	xor.b #BIT4, &P2IES
	reti

; @brief This label runs when easterEgg combination is achieved
;        It will set the values for easterEgg mode. The easterEgg
;        is if user find combination and start the play games. Wrong
;        answers are omitted. It will give user play like in god-mode
;        This easterEgg can be usable for once in lifetime of program
;        this will controlled by wasEasterUsed variable
easterEggExecute:
    cmp.b #1, &wasEasterUsed
    jeq easterEggExitToPreGame

    mov.b #1, &isEasterActive
    mov.b #1, &wasEasterUsed

	bic.b #BIT7|BIT6|BIT5, &P2IE ; We are disabling other buttons interrupt because we have delay in this label. Therefore, there is a chance to pressing other buttons.

    bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
    bis.b #BIT2|BIT5, &P1OUT    
    call #delay250msec
    xor.b #BIT2|BIT3|BIT4|BIT5, &P1OUT 
    call #delay250msec
    bis.b #BIT2|BIT3|BIT4|BIT5, &P1OUT 
    call #delay2sec             
    bic.b #BIT2|BIT3|BIT4|BIT5, &P1OUT
	
	jmp easterEggExitToPreGame

; @brief exit of easterEggExecute
easterEggExitToPreGame:
    clr.b &preGameCount
    clr.b &isPreTransition     
    clr.b &P2IFG

	bis.b #BIT7|BIT6|BIT5, &P2IE

    reti

; @brief This label runs when buttons are pressed in inGame part of the
;        game. The label branching for which ports interrupt occurs.
inGameInterrupt:
	bit.b #BIT4, &P2IFG
	jnz handleButtonLED1

	bit.b #BIT5, &P2IFG
	jnz handleButtonLED2

	bit.b #BIT6, &P2IFG
	jnz handleButtonLED3

	bit.b #BIT7, &P2IFG
	jnz handleButtonLED4

; @brief This label runs when button1 pressed in inGame part.
;        Firstly it checks button1 connected LED1 is on or not
;        If it is on it will just close the LED1. If it is off
;        Firstly checks easterEgg is on or not. If it is just
;        increment success. If it is not it compares LED1 value
;        with pattern. To ensure player pressed right or not.
;        If user presses wrong it will manipulate stack pointer
;        and call restartGame
handleButtonLED1:
	bit.b #BIT2, &P1OUT
	jnz led1Change

	cmp.b #1, &isEasterActive
    jeq led1Up

	cmp.b #1, patternLEDData(r7)
	jeq led1Up

	mov.w #restartGame, 2(SP)
	reti

; @brief This label increment success of currentPattern and compare
;        pattern is ended or not
led1Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led1Change

; @brief Controlls Button1 interrupt edge and LED1
led1Change:
	xor.b #BIT2, &P1OUT
	xor.b #BIT4, &P2IES
	bic.b #BIT4, &P2IFG
	reti

; @brief This label runs when button2 pressed in inGame part.
;        Firstly it checks button2 connected LED2 is on or not
;        If it is on it will just close the LED2. If it is off
;        Firstly checks easterEgg is on or not. If it is just
;        increment success. If it is not it compares LED2 value
;        with pattern. To ensure player pressed right or not.
;        If user presses wrong it will manipulate stack pointer
;        and call restartGame
handleButtonLED2:
	bit.b #BIT3, &P1OUT
	jnz led2Change

	cmp.b #1, &isEasterActive
    jeq led2Up

	cmp.b #2, patternLEDData(r7)
	jeq led2Up

	mov.w #restartGame, 2(SP)
	reti

; @brief This label increment success of currentPattern and compare
;        pattern is ended or not
led2Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led2Change

; @brief Controlls Button2 interrupt edge and LED2
led2Change:
	xor.b #BIT3, &P1OUT
	xor.b #BIT5, &P2IES
	bic.b #BIT5, &P2IFG
	reti

; @brief This label runs when button3 pressed in inGame part.
;        Firstly it checks button3 connected LED3 is on or not
;        If it is on it will just close the LED3. If it is off
;        Firstly checks easterEgg is on or not. If it is just
;        increment success. If it is not it compares LED3 value
;        with pattern. To ensure player pressed right or not.
;        If user presses wrong it will manipulate stack pointer
;        and call restartGame
handleButtonLED3:
	bit.b #BIT4, &P1OUT
	jnz led3Change

	cmp.b #1, &isEasterActive
    jeq led3Up

	cmp.b #3, patternLEDData(r7)
	jeq led3Up

	mov.w #restartGame, 2(SP)
	reti

; @brief This label increment success of currentPattern and compare
;        pattern is ended or not
led3Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led3Change

; @brief Controlls Button3 interrupt edge and LED3
led3Change:
	xor.b #BIT4, &P1OUT
	xor.b #BIT6, &P2IES
	bic.b #BIT6, &P2IFG
	reti

; @brief This label runs when button4 pressed in inGame part.
;        Firstly it checks button4 connected LED4 is on or not
;        If it is on it will just close the LED4. If it is off
;        Firstly checks easterEgg is on or not. If it is just
;        increment success. If it is not it compares LED4 value
;        with pattern. To ensure player pressed right or not.
;        If user presses wrong it will manipulate stack pointer
;        and call restartGame
handleButtonLED4:
	bit.b #BIT5, &P1OUT
	jnz led4Change

	cmp.b #1, &isEasterActive
    jeq led4Up

	cmp.b #4, patternLEDData(r7)
	jeq led4Up

	mov.w #restartGame, 2(SP)
	reti

; @brief This label increment success of currentPattern and compare
;        pattern is ended or not
led4Up:
	inc.w r7
	cmp.b r7, &currentLEDCount
	jeq nextGame
	jmp led4Change

; @brief Controlls Button4 interrupt edge and LED4
led4Change:
	xor.b #BIT5, &P1OUT
	xor.b #BIT7, &P2IES
	bic.b #BIT7, &P2IFG
	reti

; @brief this label runs when pattern succesfully completed
nextGame:
	clr.b &P1OUT
	bis.b #BIT6, &P1OUT

	bic.b #BIT7|BIT6|BIT5|BIT4, &P2IE ; we are disabling interrupts because delay is called in this function

	push r4
	mov.w #2000, r4
	call #delaySubRoutine
	pop r4

	bis.b #BIT7|BIT6|BIT5|BIT4, &P2IE
	
	bic.b #BIT6, &P1OUT

	mov.w &inGameReturnSP, SP ; we manipulate the stack pointer because the pattern is completed we need to go next iteration
	ret ; normally nextGame is called using by interrupt and normally we need to use reti while we are returning interrupt
		; however in this label we are doing stack pointer manipulation and this requires using ret

; ###############################################
; 				  Variables
; ###############################################

			.data
; @brief To used for determine the program in preGame or inGame.
isPreGame: .byte 1

; @brief To used for determine the program in preGameStart or preGameTransition
isPreTransition: .byte 0

; @brief To used for keeping easterEgg success count
preGameCount: .byte 0

; @brief To used for returning preGameTranstion to preGameStart
preGameReturnPC: .word 0
preGameReturnSR: .word 0
preGameReturnSP: .word 0

; @brief To used for when inGame pattern is completed, to return next pattern iteration
inGameReturnSP: .word 0

; @brief To used for saving random generated LED pattern and Time intervals
patternLEDData: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
patternTimeData: .word 0, 0, 0, 0, 0, 0, 0, 0, 0

; @brief To used for keeping how many LED is generated by random generator in this inGameStep
currentLEDCount: .byte 0

; @brief To used for keeping how many time is generated by random generator in this inGameStep (currentLEDCount - 1)
currentTimeCount: .byte 0

; @brief To used for how many step will be played in inGame
maxPatternStep: .byte 0

; @brief To used for which step we are playing in inGame
currentPatternStep: .byte 0

; @brief To used for determine easterEgg(god-mode) is active or not
isEasterActive:   .byte 0

; @brief To used for determine easterEgg used before or not
wasEasterUsed:    .byte 0

; @brief To used for break preGameStart infinite loop and returning preGame subroutine
returnPreTransitionSP: .word 0

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
            

