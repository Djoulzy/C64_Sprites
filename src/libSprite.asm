;============================
; configuration of the sprite 
;============================

SPRITE_FRAME_VECTOR			= SCREEN_RAM + $3f8

ship						= $2000			; Debut de la listes de frames vue par le 6502 (Bank 3 / Default)
sprite_ship_current_frame	= $fb
delay_animation_pointer		= $9e
sprite_frames_ship			= 16
sprite_pointer_ship			= ship / $40	; Debut de la listes de frames vue par le VIC (Adresse du bank / 64)
sprite_background_color		= Black
sprite_multicolor_1			= MediumGray
sprite_multicolor_2			= White
sprite_ship_color			= Red

sprite1 = %00000001
sprite2 = %00000010
sprite3 = %00000100
sprite4 = %00001000
sprite5 = %00010000
sprite6 = %00100000
sprite7 = %01000000
sprite8 = %10000000

.macro LIBSPRITE_INIT sprite_num, bgColor, mColor1, mColor2, fgColor
	lda #01 << sprite_num		; enable Sprite
	ora $d015
	sta $d015
	lda #01 << sprite_num		; set Multicolor mode for Sprite
	ora $d01c
	sta $d01c
	lda #$00					; Sprites have priority over background
	sta $d01b

	lda #bgColor 
	sta $d021
	lda #mColor1
	sta $d025
	lda #mColor2 
	sta $d026
	lda #fgColor
	sta $d027+sprite_num
.endmacro

.macro LIBSPRITE_SETFRAME sprite_num, start_addr, frame_num
	lda #start_addr+frame_num
	sta SPRITE_FRAME_VECTOR+sprite_num
.endmacro

.macro LIBSPRITE_SETPOS sprite_num, xpos, ypos
	lda #$00					; set X-Coord high bit (9th Bit)
	sta $d010

	lda #xpos					; set Sprite#0 positions with X/Y coords to
	sta $d000+(sprite_num<<1)   ; bottom border of screen on the outer right
	lda #ypos					; $d000 corresponds to X-Coord
	sta $d001+(sprite_num<<1)   ; $d001 corresponds to Y-Coord
.endmacro

init_sprite:
	; lda #sprite_frames_ship
	; sta sprite_ship_current_frame

	LIBSPRITE_SETFRAME 0, sprite_pointer_ship, 8
	LIBSPRITE_INIT 0, sprite_background_color, sprite_multicolor_1, sprite_multicolor_2, sprite_ship_color
	LIBSPRITE_SETPOS 0, $90, $64

	LIBSPRITE_SETFRAME 1, sprite_pointer_ship, 1
	LIBSPRITE_INIT 1, sprite_background_color, sprite_multicolor_1, sprite_multicolor_2, sprite_ship_color
	LIBSPRITE_SETPOS 1, $B0, $64

	LIBSPRITE_SETFRAME 6, sprite_pointer_ship, 8
	LIBSPRITE_INIT 6, sprite_background_color, sprite_multicolor_1, Green, sprite_ship_color
	LIBSPRITE_SETPOS 6, $B0, $B0

	rts

spriteAnim:
	
	LIBSPRITE_SETFRAME 0, sprite_pointer_ship, #sprite_ship_current_frame
	dec sprite_ship_current_frame
	bne @end
	lda #sprite_frames_ship
	sta sprite_ship_current_frame
@end: rts