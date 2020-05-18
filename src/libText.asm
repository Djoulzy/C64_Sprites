;===============================================================================
;                                   LibTEXT
;===============================================================================

BORDER_COL  = $d020
SCREEN_COL  = $d021
SCREEN_RAM  = $0400
COLOR_RAM   = $d800

;===============================================================================
; Constants

Black           = 0
White           = 1
Red             = 2
Cyan            = 3 
Purple          = 4
Green           = 5
Blue            = 6
Yellow          = 7
Orange          = 8
Brown           = 9
LightRed        = 10
DarkGray        = 11
MediumGray      = 12
LightGreen      = 13
LightBlue       = 14
LightGray       = 15
SpaceCharacter  = 32

False           = 0
True            = 1

;===============================================================================
; Copies ‘value’ into 1000 memory locations starting at ‘start’ address.
.macro LIBTEXT_CLEARSCREEN_V fgColor
.scope
clear:
	lda #$20                ; #$20 is the spacebar Screen Code
	sta SCREEN_RAM,x        ; fill four areas with 256 spacebar characters
	sta SCREEN_RAM+$FF,x 
	sta SCREEN_RAM+$01FE,x 
	sta SCREEN_RAM+$02FD,x 
	lda #fgColor            ; set foreground to black in Color Ram 
	sta COLOR_RAM,x  
	sta COLOR_RAM+$FF,x 
	sta COLOR_RAM+$01FE,x
	sta COLOR_RAM+$02FD,x
	inx                     ; increment X
	bne clear               ; did X turn to zero yet?
                            ; if not, continue with the loop
.endscope
.endmacro