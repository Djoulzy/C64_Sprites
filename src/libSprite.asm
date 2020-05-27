.macpack        longbranch

;============================
; configuration of the sprite 
;============================

SPRITE_FRAME_VECTOR			= SCREEN_RAM + $3f8

sprite_background_color		= Black
sprite_multicolor_1			= MediumGray
sprite_multicolor_2			= White

sprt_X_LO			= $00
sprt_X_HI			= $01
sprt_Y				= $02
sprt_velocityX		= $03
sprt_velocityY		= $04
sprt_priority		= $05
sprt_color			= $06
sprt_anim_state		= $07
sprt_go_to_idle		= $08
anim_frame_act		= $09
anim_frame_stop		= $0A
anim_frame_last		= $0B
anim_delay_count	= $0C
anim_delay			= $0D
anim_pingpong		= $0E
anim_sens			= $0F
anim_boucle			= $10
anim_addr_vic		= $11

;===============================================================================
; INIT
;===============================================================================
.macro LIBSPRITE_SETSHAREDCOLORS bgColor, mColor1, mColor2
	lda #bgColor 
	sta $d021
	lda #mColor1
	sta $d025
	lda #mColor2 
	sta $d026
	lda #$00
	sta $d015					; reset sprites enabled
	sta $d01c					; reset sprites color mode
	sta $d01b					; reset sprites priority with background
	sta $d010					; reset sprites X pos 9th bit
.endmacro

.macro LIBSPRITE_INIT sprite_num, sprite_addr
	lda #01 << sprite_num		; enable Sprite
	ora $d015
	sta $d015
	lda #01 << sprite_num		; set Multicolor mode for Sprite
	ora $d01c
	sta $d01c
	lda sprite_addr+sprt_priority
	and #$01 << sprite_num
	ora $d01b					; Sprites have priority over background
	sta $d01b
	lda sprite_addr+sprt_color	; On positione la couleur individuelle
	sta $d027+sprite_num
	lda #right					; On charge l'anim 'right'
	sta sprite_addr+anim_addr_vic
	lda sprite_addr+anim_frame_stop
	sta sprite_addr+anim_frame_act
.endmacro

;===============================================================================
; POSITION
;===============================================================================
.macro LIBSPRITE_SETPOS sprite_num, sprite_addr
	lda sprite_addr+sprt_X_HI
	bne :+						; Si != 0 on jump
	lda #$01 << sprite_num
	clc
	eor #$FF
	and $d010
	jmp :++

:	lda #$01 << sprite_num
	ora $d010					

:	sta $d010					; set X-Coord high bit (9th Bit)
	lda sprite_addr+sprt_X_LO	; set Sprite#0 positions with X/Y coords to
	sta $d000+(sprite_num<<1)   ; bottom border of screen on the outer right
	lda sprite_addr+sprt_Y		; $d000 corresponds to X-Coord
	sta $d001+(sprite_num<<1)   ; $d001 corresponds to Y-Coord
.endmacro

.macro LIBSPRITE_UP sprite_num, sprite_addr
	dec sprite_addr+sprt_Y
	; dec sprite_addr+sprt_Y
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_DOWN sprite_num, sprite_addr
	inc sprite_addr+sprt_Y
	; inc sprite_addr+sprt_Y
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_RIGHT sprite_num, sprite_addr
	inc sprite_addr+sprt_X_LO
	bne :+
	lda #$01
	sta sprite_addr+sprt_X_HI
:	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_LEFT sprite_num, sprite_addr
	dec sprite_addr+sprt_X_LO
	bne :+
	lda #$00
	sta sprite_addr+sprt_X_HI
:	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

;===============================================================================
; ANIMATION
;===============================================================================
.macro LIBSPRITE_DRAW_FRAME sprite_num, sprite_addr
	lda sprite_addr+anim_frame_act
	clc
	adc sprite_addr+anim_addr_vic
	sta SPRITE_FRAME_VECTOR+sprite_num
.endmacro

.macro LIBSPRITE_SET_ANIM sprite_addr, anim
	lda #anim
	sta sprite_addr+anim_addr_vic
	lda #$00
	sta sprite_addr+anim_delay_count
.endmacro

.macro LIBSPRITE_START_ANIM sprite_addr, stop, sens
	; lda sprite_addr+sprt_anim_state
	; bne :+
	lda #stop
	sta sprite_addr+anim_frame_stop
	lda #sens
	sta sprite_addr+anim_sens
	lda #$01
	sta sprite_addr+sprt_anim_state
; :	nop
.endmacro

.macro LIBSPRITE_GO_TO_IDLE sprite_addr, stop
	lda sprite_addr+sprt_go_to_idle
	bne :+++				; si deja en retour vers idle on sort
	lda #$01
	sta sprite_addr+sprt_go_to_idle
	sta sprite_addr+sprt_anim_state
	lda #$00
	sta sprite_addr+anim_delay_count
	lda #stop
	sta sprite_addr+anim_frame_stop
	lda sprite_addr+anim_sens
	bne :+
	lda #$01
	jmp :++
:	lda #$00
:	sta sprite_addr+anim_sens
:	nop
.endmacro

;===============================================================================

init_sprite:
	LIBSPRITE_SETSHAREDCOLORS sprite_background_color, sprite_multicolor_1, sprite_multicolor_2
	LIBSPRITE_INIT 0, sprite1
	LIBSPRITE_DRAW_FRAME 0, sprite1
	LIBSPRITE_SETPOS 0, sprite1
	rts

;===============================================================================

spriteAnim:
	lda sprite1+sprt_anim_state
	bne :+							; si animation not running on sort
	rts

:	LIBSPRITE_DRAW_FRAME 0, sprite1
	lda sprite1+anim_delay_count	; check delay
	jne @decrease_delay

	lda sprite1+anim_delay			; load anim delay
	sta sprite1+anim_delay_count	; restart counter delay

	lda sprite1+anim_sens
	bne @reverse
;
; Animation normale
;
	lda sprite1+anim_frame_act		; On charge la frame actuelle
	eor sprite1+anim_frame_stop
	bne @dec_frame					; sinon on va en dec_frame

	lda sprite1+anim_pingpong		; mode ping-pong
	bne @pingpong1					; si oui on va en pingpong

	lda sprite1+anim_boucle			; Doit on boucler
	bne @boucle_norm				; si oui, on redemarre l'anim
	jmp @end_of_anim

@boucle_norm:
	lda sprite1+anim_frame_last
	sta sprite1+anim_frame_act
	rts

@dec_frame:
	dec sprite1+anim_frame_act
	rts

@pingpong1:
	lda #$01
	sta sprite1+anim_sens			; on passe en mode reverse

	lda sprite1+anim_boucle			; Doit on boucler
	bne @inc_frame					; si oui, on redemarre l'anim

	lda #$00						; Sinon
	sta sprite1+anim_pingpong		; On annule le mode pingpong
	jmp @inc_frame
;
; Animation inverse
;
@reverse:
	lda sprite1+anim_frame_act		; On charge la frame actuelle
	eor sprite1+anim_frame_stop		; on compare avec la last frame
	bne @inc_frame					; si non egal on va incrementer la frame

	lda sprite1+anim_pingpong		; mode ping-pong
	bne @pingpong2					; si oui on va en pingpong

	lda sprite1+anim_boucle			; Doit on boucler
	bne @boucle_rev					; si oui, on redemarre l'anim
	jmp @end_of_anim

@boucle_rev:
	lda #$00
	sta sprite1+anim_frame_act
	rts

@inc_frame:
	inc sprite1+anim_frame_act
	rts

@pingpong2:
	lda #$00
	sta sprite1+anim_sens			; on passe en mode normal

	lda sprite1+anim_boucle			; Doit on boucler
	bne @dec_frame					; si oui, on redemarre l'anim

	lda #$00						; Sinon
	sta sprite1+anim_pingpong		; On annule le mode pingpong
	jmp @dec_frame
;
; Fin Animation
;
@decrease_delay:
	dec sprite1+anim_delay_count	; decrease delay
	rts
@end_of_anim:
	lda #$00
	sta sprite1+sprt_go_to_idle
	sta sprite1+sprt_anim_state		; on stoppe l'anim
	rts

;===============================================================================

anim_manager:
; ordonnee
	lda sprite1+sprt_velocityY
	beq abscisse
	bmi go_up
; go_down
	LIBSPRITE_START_ANIM sprite1, $08, $01
	LIBSPRITE_DOWN 0, sprite1
	jmp abscisse
go_up:
	LIBSPRITE_START_ANIM sprite1, $00, $00
	LIBSPRITE_UP 0, sprite1
abscisse:
	lda sprite1+sprt_velocityY
	ora sprite1+sprt_velocityX
	jeq goto_idle
	lda sprite1+sprt_velocityX
	jeq end_manager
	bmi go_left
; go_right
	LIBSPRITE_SET_ANIM sprite1, rotate
	LIBSPRITE_START_ANIM sprite1, $0F, $01
	LIBSPRITE_RIGHT 0, sprite1
	jmp end_manager
go_left:
	LIBSPRITE_SET_ANIM sprite1, rotate
	LIBSPRITE_START_ANIM sprite1, $0F, $00
	LIBSPRITE_LEFT 0, sprite1
	jmp end_manager
goto_idle:
	LIBSPRITE_GO_TO_IDLE sprite1, $04
end_manager:
	lda #$00
	sta sprite1+sprt_velocityX
	sta sprite1+sprt_velocityY
	jsr spriteAnim
	rts
