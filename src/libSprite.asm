.macpack        longbranch

;============================
; configuration of the sprite 
;============================

SPRITE_FRAME_VECTOR			= SCREEN_RAM + $3f8
; $FB-$FE (always)
ANIM_VECTOR					= $FB

; ship						= $2000			; Debut de la listes de frames vue par le 6502 (Bank 3 / Default)
; sprite_ship_current_frame	= $fb
; delay_animation_pointer		= $9e
; sprite_frames_ship			= 16
; sprite_pointer_ship			= ship / $40	; Debut de la listes de frames vue par le VIC (Adresse du bank / 64)
sprite_background_color		= Black
sprite_multicolor_1			= MediumGray
sprite_multicolor_2			= White
; sprite_ship_color			= Red

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
	lda sprite_addr+5
	sta ANIM_VECTOR
	lda sprite_addr+6
	sta ANIM_VECTOR+1
.endmacro

.macro LIBSPRITE_INIT sprite_num, sprite_addr
	lda #01 << sprite_num		; enable Sprite
	ora $d015
	sta $d015
	lda #01 << sprite_num		; set Multicolor mode for Sprite
	ora $d01c
	sta $d01c
	lda sprite_addr+3
	and #$01 << sprite_num
	ora $d01b					; Sprites have priority over background
	sta $d01b

	; lda sprite_addr+4			; On initialise la frame actuelle
	; sta sprite_addr+3			; sur la derniere position

	lda sprite_addr+4			; On positione la couleur individuelle
	sta $d027+sprite_num
.endmacro

.macro LIBSPRITE_SETFRAME sprite_num
	ldy #$08
	lda (ANIM_VECTOR),Y
	ldy #$01
	clc
	adc (ANIM_VECTOR),Y
	sta SPRITE_FRAME_VECTOR+sprite_num
.endmacro

.macro LIBSPRITE_SETPOS sprite_num, sprite_addr
	lda sprite_addr+1
	bne :+						; Si != 0 on jump
	lda #$01 << sprite_num
	clc
	eor #$FF
	and $d010
	jmp :++

:	lda #$01 << sprite_num
	ora $d010					

:	sta $d010					; set X-Coord high bit (9th Bit)
	lda sprite_addr				; set Sprite#0 positions with X/Y coords to
	sta $d000+(sprite_num<<1)   ; bottom border of screen on the outer right
	lda sprite_addr+2			; $d000 corresponds to X-Coord
	sta $d001+(sprite_num<<1)   ; $d001 corresponds to Y-Coord
.endmacro

.macro LIBSPRITE_UP sprite_num, sprite_addr
	dec sprite_addr+2
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_DOWN sprite_num, sprite_addr
	inc sprite_addr+2
	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_RIGHT sprite_num, sprite_addr
	inc sprite_addr
	bne :+
	lda #$01
	sta sprite_addr+1
:	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

.macro LIBSPRITE_LEFT sprite_num, sprite_addr
	dec sprite_addr
	bne :+
	lda #$00
	sta sprite_addr+1
:	LIBSPRITE_SETPOS sprite_num, sprite_addr
.endmacro

;===============================================================================

init_sprite:
	; lda #sprite_frames_ship
	; sta sprite_ship_current_frame
	LIBSPRITE_SETSHAREDCOLORS sprite_background_color, sprite_multicolor_1, sprite_multicolor_2
	LIBSPRITE_INIT 0, sprite1
	LIBSPRITE_SETVECTOR 0, sprite1
	LIBSPRITE_SETFRAME 0
	LIBSPRITE_SETPOS 0, sprite1

	; lda #$01
	; LIBSPRITE_SETFRAME 1, sprite_pointer_ship
	; LIBSPRITE_INIT 1, sprite_ship_color
	; LIBSPRITE_SETPOS 1, $B0, $64

	; lda #$08
	; LIBSPRITE_SETFRAME 6, sprite_pointer_ship
	; LIBSPRITE_INIT 6, sprite_ship_color
	; LIBSPRITE_SETPOS 6, $B0, $B0

	rts

;===============================================================================

spriteAnim:
; 	lda sprite1+6
; 	bne @end			; Si delay count != 0 on jump en @end
; 	lda sprite1+7		; On repositionne le compteur
; 	sta sprite1+6		; avec le Animation delay 

; 	LIBSPRITE_SETFRAME 0, sprite1 ; Affiche la frame actuelle
; 	lda sprite1+3		; on regarde si la current frame est à 0
; 	bne @decr			; si non on va en @dec
; 	lda sprite1+4		; si oui, on place Nb Frame dans la current frame
; 	sta sprite1+3
; 	jmp @end

; @decr:
; 	dec sprite1+3
; @end:
; 	dec sprite1+6
	LIBSPRITE_SETVECTOR 0, sprite1

	ldy #$00
	lda (ANIM_VECTOR),Y
	jeq @end_of_anim		; si animation not running on sort

	ldy #$03			; check delay
	lda (ANIM_VECTOR),Y
	jne @decrease_delay

	LIBSPRITE_SETFRAME 0
	ldy #$04			; load anim delay
	lda (ANIM_VECTOR),Y
	ldy #$03
	sta (ANIM_VECTOR),Y	; restart counter delay

	ldy #$06
	lda (ANIM_VECTOR),Y
	bne @reverse
;
; Animation normale
;
	ldy #$01			; On charge la frame actuelle
	lda (ANIM_VECTOR),Y	; on regarde si elle est à 0
	bne @dec_frame		; sinon on va en dec_frame

	ldy #$05			; mode ping-pong
	lda (ANIM_VECTOR),Y
	bne @pingpong1		; si oui on va en pingpong

	ldy #$07			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @boucle_norm	; si oui, on redemarre l'anim
	lda #$00
	ldy #$00
	sta (ANIM_VECTOR),Y	; on stoppe l'anim
	jmp @end_of_anim

@boucle_norm:
	ldy #$02
	lda (ANIM_VECTOR),Y
	ldy #$01
	sta (ANIM_VECTOR),Y
	jmp @end_of_anim

@dec_frame:
	LIBADDR_IND_DEC ANIM_VECTOR, $01
	jmp @end_of_anim

@pingpong1:
	lda #$01
	ldy #$06
	sta (ANIM_VECTOR),Y	; on passe en mode reverse

	ldy #$07			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @inc_frame		; si oui, on redemarre l'anim

	lda #$00			; Sinon
	ldx #$05
	sta (ANIM_VECTOR),Y	; On annule le mode pingpong
	jmp @inc_frame
;
; Animation inverse
;
@reverse:
	ldy #$01			; On charge la frame actuelle
	lda (ANIM_VECTOR),Y
	ldy #$02
	cmp (ANIM_VECTOR),Y ; on compare avec la last frame
	bne @inc_frame		; si non egal on va incrementer la frame

	ldy #$05			; mode ping-pong
	lda (ANIM_VECTOR),Y
	bne @pingpong2		; si oui on va en pingpong

	ldy #$07			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @boucle_rev		; si oui, on redemarre l'anim
	lda #$00
	ldy #$00
	sta (ANIM_VECTOR),Y	; on stoppe l'anim
	jmp @end_of_anim

@boucle_rev:
	lda #$00
	ldy #$01
	sta (ANIM_VECTOR),Y
	jmp @end_of_anim

@inc_frame:
	LIBADDR_IND_INC ANIM_VECTOR, $01
	jmp @end_of_anim

@pingpong2:
	lda #$00
	ldy #$06
	sta (ANIM_VECTOR),Y	; on passe en mode normal

	ldy #$07			; Doit on boucler
	lda (ANIM_VECTOR),Y
	bne @dec_frame		; si oui, on redemarre l'anim

	lda #$00			; Sinon
	ldx #$05
	sta (ANIM_VECTOR),Y	; On annule le mode pingpong
	jmp @dec_frame
;
; Fin Animation
;
@decrease_delay:
	LIBADDR_IND_DEC ANIM_VECTOR, $03 ; decrease delay
@end_of_anim:
	rts

;===============================================================================

go_up:
