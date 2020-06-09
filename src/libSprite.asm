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
anim_running		= $07
anim_frame_start	= $08
anim_frame_current	= $09
anim_frame_stop		= $0A
anim_delay_count	= $0B
anim_delay			= $0C
anim_pingpong		= $0D
anim_sens			= $0E
anim_boucle			= $0F
anim_addr_vic		= $10

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

.macro LIBSPRITE_INIT sprite_num, sprite_addr, anim, start, stop
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
	lda #anim
	sta sprite_addr+anim_addr_vic
	lda #start
	sta sprite_addr+anim_frame_start
	sta sprite_addr+anim_frame_current
	lda #stop
	sta sprite_addr+anim_frame_stop
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

.macro LIBSPRITE_MOVE sprite_num, sprite_addr
	lda sprite_addr+sprt_velocityX
	bmi @go_left					; go left
	clc
	adc sprite_addr+sprt_X_LO	; right
	sta sprite_addr+sprt_X_LO
	bne @move_y
	lda #$01
	sta sprite_addr+sprt_X_HI
	jmp @move_y
@go_left:						; left
	and #$0F
	sta $FB
	lda sprite_addr+sprt_X_LO
	sec
	sbc $FB
	sta sprite_addr+sprt_X_LO
	bpl @move_y
	lda #$00
	sta sprite_addr+sprt_X_HI
@move_y:						; move Y
	lda sprite_addr+sprt_velocityY
	bmi @go_up					; go up
	clc
	adc sprite_addr+sprt_Y		; down
	sta sprite_addr+sprt_Y
	jmp @end					; go end
@go_up:			
	and #$0F					; up
	sta $FB
	lda sprite_addr+sprt_Y
	sec
	sbc $FB
	sta sprite_addr+sprt_Y
@end:
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

;===============================================================================
; ANIMATION
;===============================================================================
.macro LIBSPRITE_DRAW_FRAME sprite_num, sprite_addr
	lda sprite_addr+anim_frame_current
	clc
	adc sprite_addr+anim_addr_vic
	sta SPRITE_FRAME_VECTOR+sprite_num
.endmacro

.macro LIBSPRITE_PLAY_ANIM sprite_addr, start, stop, sens
	lda #start
	sta sprite_addr+anim_frame_start
	lda #stop
	sta sprite_addr+anim_frame_stop
	lda #sens
	sta sprite_addr+anim_sens
	lda #$01
	sta sprite_addr+anim_running
.endmacro

.macro LIBSPRITE_CHANGE_DIRECTION sprite_addr
	lda sprite_addr+anim_sens
	eor #$FF
	sta sprite_addr+anim_sens
	lda #$01
	sta sprite_addr+anim_running
.endmacro

.macro LIBSPRITE_GO_TO_IDLE sprite_addr
	lda sprite_addr+anim_frame_stop
	cmp sprite_addr+anim_frame_current
	beq :+++
	lda sprite_addr+sprt_go_to_idle
	bne :+++				; si deja en retour vers idle on sort
	lda #$01
	sta sprite_addr+sprt_go_to_idle
	sta sprite_addr+anim_running
	lda #$00
	sta sprite_addr+anim_delay_count
	lda sprite_addr+anim_frame_stop
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
	LIBSPRITE_INIT 0, sprite1, right, $04, $08
	LIBSPRITE_DRAW_FRAME 0, sprite1
	LIBSPRITE_SETPOS 0, sprite1
	rts

;===============================================================================

; spriteAnim:
; 	lda sprite1+anim_running
; 	bne :+							; si animation not running on sort
; 	rts

; :	LIBSPRITE_DRAW_FRAME 0, sprite1
; 	lda sprite1+anim_delay_count	; check delay
; 	jne @decrease_delay

; 	lda sprite1+anim_delay			; load anim delay
; 	sta sprite1+anim_delay_count	; restart counter delay

; 	lda sprite1+anim_sens
; 	bmi @negatif

; 	lda sprite1+anim_frame_stop
; 	sec
; 	sbc sprite1+anim_frame_current
; 	bmi @negatif
; ;
; ; Animation sens positif
; ;
; @positif:
; 	lda sprite1+anim_frame_current	; On charge la frame actuelle
; 	eor sprite1+anim_frame_stop		; on compare avec la last frame
; 	bne @inc_frame					; si non egal on va incrementer la frame

; 	lda sprite1+anim_pingpong		; mode ping-pong
; 	bne @pingpong2					; si oui on va en pingpong

; 	lda sprite1+anim_boucle			; Doit on boucler
; 	bne @boucle_positif				; si oui, on redemarre l'anim
; 	jmp @end_of_anim

; @boucle_positif:
; 	lda sprite1+anim_frame_start
; 	sta sprite1+anim_frame_current
; 	rts

; @inc_frame:
; 	inc sprite1+anim_frame_current
; 	rts

; @pingpong2:
; 	lda #$F0
; 	sta sprite1+anim_sens			; on passe en mode normal

; 	lda sprite1+anim_boucle			; Doit on boucler
; 	bne @dec_frame					; si oui, on redemarre l'anim

; 	lda #$00						; Sinon
; 	sta sprite1+anim_pingpong		; On annule le mode pingpong
; 	jmp @dec_frame

; ;
; ; Animation sens negatif
; ;
; @negatif:
; 	lda sprite1+anim_frame_current	; On charge la frame actuelle
; 	eor sprite1+anim_frame_start
; 	bne @dec_frame					; sinon on va en dec_frame

; 	lda sprite1+anim_pingpong		; mode ping-pong
; 	bne @pingpong1					; si oui on va en pingpong

; 	lda sprite1+anim_boucle			; Doit on boucler
; 	bne @boucle_negatif				; si oui, on redemarre l'anim
; 	jmp @end_of_anim

; @boucle_negatif:
; 	lda sprite1+anim_frame_stop
; 	sta sprite1+anim_frame_current
; 	rts

; @dec_frame:
; 	dec sprite1+anim_frame_current
; 	rts

; @pingpong1:
; 	lda #$0F
; 	sta sprite1+anim_sens			; on passe en mode reverse

; 	lda sprite1+anim_boucle			; Doit on boucler
; 	bne @inc_frame					; si oui, on redemarre l'anim

; 	lda #$00						; Sinon
; 	sta sprite1+anim_pingpong		; On annule le mode pingpong
; 	jmp @inc_frame

; ;
; ; Fin Animation
; ;
; @decrease_delay:
; 	dec sprite1+anim_delay_count	; decrease delay
; 	rts
; @end_of_anim:
; 	lda #$00
; ;	sta sprite1+sprt_go_to_idle
; 	sta sprite1+anim_running		; on stoppe l'anim
; 	rts

spriteAnim:
	lda sprite1+anim_running
	bne :+							; si animation not running on sort
	rts

:	LIBSPRITE_DRAW_FRAME 0, sprite1
	lda sprite1+anim_delay_count	; check delay
	jne @decrease_delay

	lda sprite1+anim_delay			; load anim delay
	sta sprite1+anim_delay_count	; restart counter delay

	lda sprite1+anim_frame_stop
	sec
	sbc sprite1+anim_frame_current
	bmi @negatif
;
; Animation sens positif
;
@positif:
	lda sprite1+anim_frame_current	; On charge la frame actuelle
	eor sprite1+anim_frame_stop		; on compare avec la last frame
	bne @inc_frame					; si non egal on va incrementer la frame

	lda sprite1+anim_pingpong		; mode ping-pong
	bne @pingpong2					; si oui on va en pingpong

	lda sprite1+anim_boucle			; Doit on boucler
	bne @boucle_positif				; si oui, on redemarre l'anim
	jmp @end_of_anim

@boucle_positif:
	lda sprite1+anim_frame_start
	sta sprite1+anim_frame_current
	rts

@inc_frame:
	inc sprite1+anim_frame_current
	rts

@pingpong2:
	lda #$F0
	sta sprite1+anim_sens			; on passe en mode normal

	lda sprite1+anim_boucle			; Doit on boucler
	bne @dec_frame					; si oui, on redemarre l'anim

	lda #$00						; Sinon
	sta sprite1+anim_pingpong		; On annule le mode pingpong
	jmp @dec_frame

;
; Animation sens negatif
;
@negatif:
	lda sprite1+anim_frame_current	; On charge la frame actuelle
	eor sprite1+anim_frame_start
	bne @dec_frame					; sinon on va en dec_frame

	lda sprite1+anim_pingpong		; mode ping-pong
	bne @pingpong1					; si oui on va en pingpong

	lda sprite1+anim_boucle			; Doit on boucler
	bne @boucle_negatif				; si oui, on redemarre l'anim
	jmp @end_of_anim

@boucle_negatif:
	lda sprite1+anim_frame_stop
	sta sprite1+anim_frame_current
	rts

@dec_frame:
	dec sprite1+anim_frame_current
	rts

@pingpong1:
	lda #$0F
	sta sprite1+anim_sens			; on passe en mode reverse

	lda sprite1+anim_boucle			; Doit on boucler
	bne @inc_frame					; si oui, on redemarre l'anim

	lda #$00						; Sinon
	sta sprite1+anim_pingpong		; On annule le mode pingpong
	jmp @inc_frame

;
; Fin Animation
;
@decrease_delay:
	dec sprite1+anim_delay_count	; decrease delay
	rts
@end_of_anim:
	lda #$00
;	sta sprite1+sprt_go_to_idle
	sta sprite1+anim_running		; on stoppe l'anim
	rts

;===============================================================================

anim_manager:
	lda sprite1+sprt_velocityY
	ora sprite1+sprt_velocityX
	jeq goto_idle

abscisse:
; 	lda sprite1+sprt_velocityX
; 	jeq ordonnee
; 	bmi go_left
; ; go_right
; 	LIBSPRITE_SET_ANIM sprite1, $00, $08
; 	lda #$01
; 	sta sprite1+sprt_velocityX
; 	jmp ordonnee
; go_left:
; 	LIBSPRITE_SET_ANIM sprite1, $09, $11
; 	lda #$F1
; 	sta sprite1+sprt_velocityX

ordonnee:
	lda sprite1+sprt_velocityY
	beq goto_idle
	bmi go_up
; go_down
	LIBSPRITE_PLAY_ANIM sprite1, $04, $08, $0F
	lda #$01
	sta sprite1+sprt_velocityY
	jmp end_manager
go_up:
	LIBSPRITE_PLAY_ANIM sprite1, $00, $04, $F0
	lda #$F1
	sta sprite1+sprt_velocityY
	jmp end_manager

goto_idle:
	; LIBSPRITE_CHANGE_DIRECTION sprite1
end_manager:
	LIBSPRITE_MOVE 0, sprite1
	lda #$00
	sta sprite1+sprt_velocityX
	sta sprite1+sprt_velocityY
	rts