.macpack cbm
;===============================================================================
.segment "ZEROPAGE"
; $92-$96 (only if no datasette is used)
; $A3-$B1 (only if no RS-232 and datasette is used)
; $F7-$FA (only if no RS-232 is used)
; $FB-$FE (always)

;===============================================================================
; Music include
.segment "MUSIC"
; .byte $00
.incbin "res/empty_1000.sid", 126

sid_init = $11ED      ; init routine for music
sid_play = $1004      ; play music routine

;===============================================================================
; Sprite include
.segment "SPRITE"
.incbin "res/jules.spd", 3		; 2048 bytes

sprite1:				; $13 bytes
.byte $05, $FF			; X Coord (LO/HI)
.byte $64				; Y Coord
.byte $00, $00			; Velocity X, velocity Y
.byte $01				; Priority ($00 priority sprite / $FF prority background)
.byte Red				; Uniq color (foreground)
.byte $00				; anim locked
.byte $04, $08			; Current frame / Stop frame
.byte $00, $05			; Current delay count / Animation delay
.byte $00, $00			; Next anim / next stop frame
.byte $00				; Adresse VIC de l'annimation

ship_right		= $80 ; $2000 / $40 ; frameset location VIC (Adresse du bank / 64)
ship_left		= ($2000 + 579) / $40 ; frameset location VIC (Adresse du bank / 64)
ship_rotate		= ($2000 + 1158) / $40
;===============================================================================
.segment "CODE"
	jmp start						; run the init code then flow into the update code

;===============================================================================

; Code Includes
.include "libAddr.asm"
.include "libText.asm"
.include "libSprite.asm"
.include "libKeyboard.asm"

;=============================================================================== 

line1:	scrcode "        salut je m'appelle jules    "
.byte	0
line2:	scrcode "    ceci est mon premier prog en asm"
.byte	0

color:
.byte $09,$09,$02,$02,$08 
.byte $08,$0a,$0a,$0f,$0f 
.byte $07,$07,$01,$01,$01 
.byte $01,$01,$01,$01,$01 
.byte $01,$01,$01,$01,$01 
.byte $01,$01,$01,$07,$07 
.byte $0f,$0f,$0a,$0a,$08 
.byte $08,$02,$02,$09,$09 

color2:
.byte $09,$09,$02,$02,$08 
.byte $08,$0a,$0a,$0f,$0f 
.byte $07,$07,$01,$01,$01 
.byte $01,$01,$01,$01,$01 
.byte $01,$01,$01,$01,$01 
.byte $01,$01,$01,$07,$07 
.byte $0f,$0f,$0a,$0a,$08 
.byte $08,$02,$02,$09,$09

;============================================================
; MAIN
;============================================================

colwash:
	ldx #$27        ; load x-register with #$27 to work through 0-39 iterations
	lda color+$27   ; init accumulator with the last color from first color table

	@cycle1:
		ldy color-1,x   ; remember the current color in color table in this iteration
		sta color-1,x   ; overwrite that location with color from accumulator
		sta $d990,x     ; put it into Color Ram into column x
		tya             ; transfer our remembered color back to accumulator
		dex             ; decrement x-register to go to next iteration
		bne @cycle1      ; repeat if there are iterations left
		sta color+$27   ; otherwise store te last color from accu into color table
		sta $d990       ; ... and into Color Ram

colwash2:
	ldx #$00        ; load x-register with #$00
	lda color2+$27  ; load the last color from the second color table

	@cycle2:
		ldy color2,x    ; remember color at currently looked color2 table location
		sta color2,x    ; overwrite location with color from accumulator
		sta $d9e0,x     ; ... and write it to Color Ram
		tya             ; transfer our remembered color back to accumulator 
		inx             ; increment x-register to go to next iteraton
		cpx #$26        ; have we gone through 39 iterations yet?
		bne @cycle2      ; if no, repeat
		sta color2+$27  ; if yes, store the final color from accu into color2 table
		sta $d9e0+$27   ; and write it into Color Ram

	rts             ; return from subroutine

;============================================================

init_text:
	ldx #$00         ; init X register with $00
	@loop_text:
		lda line1,x      ; read characters from line1 table of text...
		beq	end
		sta $0590,x      ; ...and store in screen ram near the center
		lda line2,x      ; read characters from line2 table of text...
		sta $05e0,x      ; ...and put 2 rows below line1
		inx
	jmp @loop_text    ; loop if we are not done yet
end:
	rts

;============================================================
;    some initialization and interrupt redirect setup
;============================================================

start:
LDX #$0F
loop:
STX $d020
STX $d021
DEX
BNE loop
jmp start
	;====================
	; Initialize Memory
	;====================
	sei         ; set interrupt disable flag

	ldx #$00
	stx	BORDER_COL
	stx SCREEN_COL
	LIBTEXT_CLEARSCREEN_V $00     ; clear the screen
	LIBKBD_INIT
	jsr sid_init
	jsr init_text       ; write lines of text
	jsr init_sprite

	ldy #$7f    ; $7f = %01111111
	sty $dc0d   ; Turn off CIAs Timer interrupts
	sty $dd0d   ; Turn off CIAs Timer interrupts
	lda $dc0d   ; cancel all CIA-IRQs in queue/unprocessed
	lda $dd0d   ; cancel all CIA-IRQs in queue/unprocessed

	lda #$01    ; Set Interrupt Request Mask...
	sta $d01a   ; ...we want IRQ by Rasterbeam

	lda #<irq   ; point IRQ Vector to our custom irq routine
	ldx #>irq 
	sta $314    ; store in $314/$315
	stx $315   

	lda #$00    ; trigger first interrupt at row zero
	sta $d012

	lda $d011   ; Bit#0 of $d011 is basically...
	and #$7f    ; ...the 9th Bit for $d012
	sta $d011   ; we need to make sure it is set to zero 

	cli         ; clear interrupt disable flag
	jmp *       ; infinite loop

;============================================================
;    custom interrupt routine
;============================================================

irq:
	dec $d019        ; acknowledge IRQ
	jsr colwash      ; jump to color cycling routine
	jsr check_controls
	jsr anim_manager
	jsr spriteAnim
	jsr sid_play
	jmp $ea81        ; return to kernel interrupt routine

;===============================================================================

check_controls:
	lda #$00
	sta $dc00		; port a
	lda $dc01       ; port b
	cmp #$ff
	jeq end_kbd

	LIBKBD_CHECK_KEY U_KEY_ROW, U_KEY_COL
	bne key_down
	lda #$F1
	sta sprite1+sprt_velocityY
key_down:
	LIBKBD_CHECK_KEY N_KEY_ROW, N_KEY_COL
	bne key_right
	lda #$01
	sta sprite1+sprt_velocityY
key_right:
	LIBKBD_CHECK_KEY J_KEY_ROW, J_KEY_COL
	bne key_left
	lda #$01
	sta sprite1+sprt_velocityX
key_left:
	LIBKBD_CHECK_KEY H_KEY_ROW, H_KEY_COL
	bne key_exit
	lda #$F1
	sta sprite1+sprt_velocityX
key_exit:
	LIBKBD_CHECK_KEY X_KEY_ROW, X_KEY_COL
	bne end_kbd
	LIBTEXT_CLEARSCREEN_V Blue
	lda #$00
	sta $d015        ; turn off all sprites
	jmp $ea81        ; jmp to regular interrupt routine
	rts

cia:
	sei         ; set interrupt disable flag

	ldx #$00
	stx	BORDER_COL
	stx SCREEN_COL
	LIBTEXT_CLEARSCREEN_V $01     ; clear the screen

	ldy #$01

	ldx #$00
	stx $DC02 ; PRA en Lecture
	ldx #$FF
	stx $DC03 ; PRB en ecriture

	tya
	and $DC00
	bne UN	; on affiche 1
	sta $0400, Y
	
