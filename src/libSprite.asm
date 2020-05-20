.macpack        longbranch

;============================
; configuration of the sprite 
;============================

SPRITE_FRAME_VECTOR			= SCREEN_RAM + $3f8
; $FB-$FE (always)
ANIM_VECTOR					= $FB

sprite_background_color		= Black
sprite_multicolor_1			= MediumGray
sprite_multicolor_2			= White

sprt_X_LO			= $00
sprt_X_HI			= $01
sprt_Y				= $02
sprt_priority		= $03
sprt_color			= $04
sprt_anim_state		= $05
sprt_anim_addr_lo	= $06
sprt_anim_addr_hi	= $07

anim_frame_act		= $00
anim_frame_last		= $01
anim_delay_count	= $02
anim_delay			= $03
anim_pingpong		= $04
anim_sens			= $05
anim_boucle			= $06
anim_addr			= $07
;===============================================================================

.macro LIBSPRITE_SETSHAREDCOLORS bgColor, mColor1, mColor2
	lda #bgColor 
	sta $d021
	lda #mColor1
	sta $d025
	lda #mColor2 
	sta $d026
	lda #$00
	sta $d015	; reset sprites enabled
	sta $d01c	; reset sprites color mode
	sta $d01b	; reset sprites priority with background
	sta $d010	; reset sprites X pos 9th bit
.endmacro

.macro LIBSPRITE_SETVECTOR sprite_num, sprite_addr
	lda sprite_addr+sprt_anim_addr_lo
	sta ANIM_VECTOR
	lda sprite_addr+sprt_anim_addr_hi
	sta ANIM_VECTOR+1
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
	lda sprite_addr+sprt_color			; On positione la couleur individuelle
	sta $d027+sprite_num
.endmacro

.macro LIBSPRITE_DRAW_FRAME sprite_num
	ldy #anim_addr
	lda (ANIM_VECTOR),Y
	ldy #anim_frame_act
	clc
	adc (ANIM_VECTOR),Y
	sta SPRITE_FRAME_VECTOR+sprite_num
.endmacro

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

.macro LIBSPRITE_START_ANIM sprite_addr, anim
	lda sprite_addr+sprt_anim_state
	bne :+
	lda #<anim
	sta sprite_addr+sprt_anim_addr_lo
	lda #>anim
	sta sprite_addr+sprt_anim_addr_hi
	lda #$01
	sta sprite_addr+sprt_anim_state
:
.endmacro

.macro LIBSPRITE_UP sprite_num, sprite_addr
	dec sprite_addr+sprt_Y
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_DOWN sprite_num, sprite_addr
	inc sprite_addr+sprt_Y
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

init_sprite:
	LIBSPRITE_SETSHAREDCOLORS sprite_background_color, sprite_multicolor_1, sprite_multicolor_2
	LIBSPRITE_INIT 0, sprite1
	LIBSPRITE_SETVECTOR 0, sprite1
	LIBSPRITE_DRAW_FRAME 0
	LIBSPRITE_SETPOS 0, sprite1
	rts

;===============================================================================

spriteAnim:
	LIBSPRITE_SETVECTOR 0, sprite1

	lda sprite1+sprt_anim_state
	jeq @end_of_anim		; si animation not running on sort

	ldy #anim_delay_count	; check delay
	lda (ANIM_VECTOR),Y
	jne @decrease_delay

	LIBSPRITE_DRAW_FRAME 0
	ldy #anim_delay			; load anim delay
	lda (ANIM_VECTOR),Y
	ldy #anim_delay_count
	sta (ANIM_VECTOR),Y		; restart counter delay

	ldy #anim_sens
	lda (ANIM_VECTOR),Y
	bne @reverse
;
; Animation normale
;
	ldy #anim_frame_act			; On charge la frame actuelle
	lda (ANIM_VECTOR),Y	; on regarde si elle est à 0
	bne @dec_frame		; sinon on va en dec_frame

	ldy #anim_pingpong			; mode ping-pong
	lda (ANIM_VECTOR),Y
	bne @pingpong1		; si oui on va en pingpong

	ldy #anim_boucle			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @boucle_norm	; si oui, on redemarre l'anim
	lda #$00
	sta sprite1+sprt_anim_state		; on stoppe l'anim
	jmp @end_of_anim

@boucle_norm:
	ldy #anim_frame_last
	lda (ANIM_VECTOR),Y
	ldy #anim_frame_act
	sta (ANIM_VECTOR),Y
	jmp @end_of_anim

@dec_frame:
	LIBADDR_IND_DEC ANIM_VECTOR, anim_frame_act
	jmp @end_of_anim

@pingpong1:
	lda #$01
	ldy #anim_sens
	sta (ANIM_VECTOR),Y	; on passe en mode reverse

	ldy #anim_boucle			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @inc_frame		; si oui, on redemarre l'anim

	lda #$00			; Sinon
	ldy #anim_pingpong
	sta (ANIM_VECTOR),Y	; On annule le mode pingpong
	jmp @inc_frame
;
; Animation inverse
;
@reverse:
	ldy #anim_frame_act			; On charge la frame actuelle
	lda (ANIM_VECTOR),Y
	ldy #anim_frame_last
	cmp (ANIM_VECTOR),Y ; on compare avec la last frame
	bne @inc_frame		; si non egal on va incrementer la frame

	ldy #anim_pingpong			; mode ping-pong
	lda (ANIM_VECTOR),Y
	bne @pingpong2		; si oui on va en pingpong

	ldy #anim_boucle			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @boucle_rev		; si oui, on redemarre l'anim
	lda #$00
	sta sprite1+sprt_anim_state			; on stoppe l'anim
	jmp @end_of_anim

@boucle_rev:
	lda #$00
	ldy #anim_frame_act
	sta (ANIM_VECTOR),Y
	jmp @end_of_anim

@inc_frame:
	LIBADDR_IND_INC ANIM_VECTOR, anim_frame_act
	jmp @end_of_anim

@pingpong2:
	lda #$00
	ldy #anim_sens
	sta (ANIM_VECTOR),Y	; on passe en mode normal

	ldy #anim_boucle			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @dec_frame		; si oui, on redemarre l'anim

	lda #$00			; Sinon
	ldy #anim_pingpong
	sta (ANIM_VECTOR),Y	; On annule le mode pingpong
	jmp @dec_frame
;
; Fin Animation
;
@decrease_delay:
	LIBADDR_IND_DEC ANIM_VECTOR, anim_delay_count ; decrease delay
@end_of_anim:
	rts

;===============================================================================

go_up:
