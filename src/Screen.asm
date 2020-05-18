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
; Variables

; Operator Calc

ScreenRAMRowStartLow
        !byte <SCREENRAM, <SCREENRAM+40, <SCREENRAM+80
        !byte <SCREENRAM+120, <SCREENRAM+160, <SCREENRAM+200
        !byte <SCREENRAM+240, <SCREENRAM+280, <SCREENRAM+320
        !byte <SCREENRAM+360, <SCREENRAM+400, <SCREENRAM+440
        !byte <SCREENRAM+480, <SCREENRAM+520, <SCREENRAM+560
        !byte <SCREENRAM+600, <SCREENRAM+640, <SCREENRAM+680
        !byte <SCREENRAM+720, <SCREENRAM+760, <SCREENRAM+800
        !byte <SCREENRAM+840, <SCREENRAM+880, <SCREENRAM+920
        !byte <SCREENRAM+960

ScreenRAMRowStartHigh ;  SCREENRAM + 40*0, 40*1, 40*2 ... 40*24
        !byte >SCREENRAM,     >SCREENRAM+40,  >SCREENRAM+80
        !byte >SCREENRAM+120, >SCREENRAM+160, >SCREENRAM+200
        !byte >SCREENRAM+240, >SCREENRAM+280, >SCREENRAM+320
        !byte >SCREENRAM+360, >SCREENRAM+400, >SCREENRAM+440
        !byte >SCREENRAM+480, >SCREENRAM+520, >SCREENRAM+560
        !byte >SCREENRAM+600, >SCREENRAM+640, >SCREENRAM+680
        !byte >SCREENRAM+720, >SCREENRAM+760, >SCREENRAM+800
        !byte >SCREENRAM+840, >SCREENRAM+880, >SCREENRAM+920
        !byte >SCREENRAM+960

ColorRAMRowStartLow ;  COLORRAM + 40*0, 40*1, 40*2 ... 40*24
        !byte <COLORRAM,     <COLORRAM+40,  <COLORRAM+80
        !byte <COLORRAM+120, <COLORRAM+160, <COLORRAM+200
        !byte <COLORRAM+240, <COLORRAM+280, <COLORRAM+320
        !byte <COLORRAM+360, <COLORRAM+400, <COLORRAM+440
        !byte <COLORRAM+480, <COLORRAM+520, <COLORRAM+560
        !byte <COLORRAM+600, <COLORRAM+640, <COLORRAM+680
        !byte <COLORRAM+720, <COLORRAM+760, <COLORRAM+800
        !byte <COLORRAM+840, <COLORRAM+880, <COLORRAM+920
        !byte <COLORRAM+960

ColorRAMRowStartHigh ;  COLORRAM + 40*0, 40*1, 40*2 ... 40*24
        !byte >COLORRAM,     >COLORRAM+40,  >COLORRAM+80
        !byte >COLORRAM+120, >COLORRAM+160, >COLORRAM+200
        !byte >COLORRAM+240, >COLORRAM+280, >COLORRAM+320
        !byte >COLORRAM+360, >COLORRAM+400, >COLORRAM+440
        !byte >COLORRAM+480, >COLORRAM+520, >COLORRAM+560
        !byte >COLORRAM+600, >COLORRAM+640, >COLORRAM+680
        !byte >COLORRAM+720, >COLORRAM+760, >COLORRAM+800
        !byte >COLORRAM+840, >COLORRAM+880, >COLORRAM+920
        !byte >COLORRAM+960

; Operator HiLo

screenColumn            !byte 0
screenScrollXValue      !byte 0

;===============================================================================
; Macros/Subroutines

; X Position Absolute, Y Position Absolute, 1st Number Low Byte Pointer
!macro  LIBSCREEN_DEBUG8BIT_VVA XPos, YPos, num {
        lda #White
        sta $0286       ; set text color
        lda #$20        ; space
        jsr $ffd2       ; print 4 spaces
        jsr $ffd2
        jsr $ffd2
        jsr $ffd2
        ;jsr $E566      ; reset cursor
        ldx #YPos       ; Select row 
        ldy #XPos       ; Select column 
        jsr $E50C       ; Set cursor 

        lda #0
        ldx num
        jsr $BDCD       ; print number
}

;============================= ==================================================

; X Position Absolute, Y Position Absolute
; 1st Number High Byte Pointer, 1st Number Low Byte Pointer
!macro  LIBSCREEN_DEBUG16BIT_VVAA XPos, YPos, num_HI, num_LO {
        lda #White
        sta $0286       ; set text color
        lda #$20        ; space
        jsr $ffd2       ; print 4 spaces
        jsr $ffd2
        jsr $ffd2
        jsr $ffd2
        ;jsr $E566      ; reset cursor
        ldx #YPos       ; Select row 
        ldy #XPos       ; Select column 
        jsr $E50C       ; Set cursor 

        lda num_HI
        ldx num_LO
        jsr $BDCD       ; print number
}

;==============================================================================

; X Position 0-39 (Address), Y Position 0-24 (Address)
; 0 terminated string (Address),Text Color (Value)
!macro LIBSCREEN_DRAWTEXT_AAAV Xpos, Ypos, str, color {
        ldy Ypos        ; load y position as index into list
        
        lda ScreenRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ScreenRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register

        ldx #0
@loop   lda str,X
        cmp #0
        beq @done
        sta (ZeroPageLow),Y
        inx
        iny
        jmp @loop
@done
        ldy Ypos        ; load y position as index into list
        
        lda ColorRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ColorRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register

        ldx #0
@loop2  lda str,X
        cmp #0
        beq @done2
        lda #color
        sta (ZeroPageLow),Y
        inx
        iny
        jmp @loop2
@done2
}

;===============================================================================

; X Position 0-39 (Address), Y Position 0-24 (Address)
; decimal number 2 nybbles (Address),Text Color (Value)
!macro  LIBSCREEN_DRAWDECIMAL_AAAV Xpos, Ypos, num, color {
        ldy Ypos        ; load y position as index into list
        
        lda ScreenRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ScreenRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register

        ; get high nybble
        lda num
        and #$F0
        
        ; convert to ascii
        lsr
        lsr
        lsr
        lsr
        ora #$30

        sta (ZeroPageLow),Y

        ; move along to next screen position
        iny 

        ; get low nybble
        lda num
        and #$0F

        ; convert to ascii
        ora #$30  

        sta (ZeroPageLow),Y
    
        ; now set the colors
        ldy Ypos        ; load y position as index into list
        
        lda ColorRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ColorRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register

        lda #color
        sta (ZeroPageLow),Y

        ; move along to next screen position
        iny 
        
        sta (ZeroPageLow),Y
}

;==============================================================================

; Return character code (Address)
!macro  LIBSCREEN_GETCHAR char {
        lda (ZeroPageLow),Y
        sta char
}

;===============================================================================

; XPix_HI (Address), XPix_LO (Address), XAdjust (Value),
; YPix (Address),YAdjust (Value),XChar (Address),
; XOffset (Address),YChar (Address),YOffset (Address)
!macro  LIBSCREEN_PIXELTOCHAR_AAVAVAAAA XPix_HI, XPix_LO, XAdjust, YPix, YAdjust, XChar, XOffset, YChar, YOffset {
        lda XPix_HI
        sta ZeroPageParam1
        lda XPix_LO
        sta ZeroPageParam2
        lda #XAdjust
        sta ZeroPageParam3
        lda YPix
        sta ZeroPageParam4
        lda #YAdjust
        sta ZeroPageParam5
        
        jsr libScreen_PixelToChar

        lda ZeroPageParam6
        sta XChar
        lda ZeroPageParam7
        sta XOffset
        lda ZeroPageParam8
        sta YChar
        lda ZeroPageParam9
        sta YOffset
}

libScreen_PixelToChar

        ; subtract XAdjust pixels from XPixels as left of a sprite is first visible at x = 24
        +LIBMATH_SUB16BIT_AAVAAA ZeroPageParam1, ZeroPageParam2, 0, ZeroPageParam3, ZeroPageParam6, ZeroPageParam7

        lda ZeroPageParam6
        sta ZeroPageTemp

        ; divide by 8 to get character X
        lda ZeroPageParam7
        lsr     ; divide by 2
        lsr     ; and again = /4
        lsr     ; and again = /8
        sta ZeroPageParam6

        ; AND 7 to get pixel offset X
        lda ZeroPageParam7
        and #7
        sta ZeroPageParam7

        ; Adjust for XHigh
        lda ZeroPageTemp
        beq +
        +LIBMATH_ADD8BIT_AVA ZeroPageParam6, 32, ZeroPageParam6 ; shift across 32 chars

+
        ; subtract YAdjust pixels from YPixels as top of a sprite is first visible at y = 50
        +LIBMATH_SUB8BIT_AAA ZeroPageParam4, ZeroPageParam5, ZeroPageParam9


        ; divide by 8 to get character Y
        lda ZeroPageParam9
        lsr     ; divide by 2
        lsr     ; and again = /4
        lsr     ; and again = /8
        sta ZeroPageParam8

        ; AND 7 to get pixel offset Y
        lda ZeroPageParam9
        and #7
        sta ZeroPageParam9

        rts

;==============================================================================

; Update subroutine (Address)
!macro  LIBSCREEN_SCROLLXLEFT_A update {
        dec screenScrollXValue
        lda screenScrollXValue
        and #%00000111
        sta screenScrollXValue

        lda SCROLX
        and #%11111000
        ora screenScrollXValue
        sta SCROLX

        lda screenScrollXValue
        cmp #7
        bne @finished

        ; move to next column
        inc screenColumn
        jsr update      ; call the passed in function to update the screen rows
@finished
}

;==============================================================================

; Update subroutine (Address)
!macro  LIBSCREEN_SCROLLXRIGHT_A update {
        inc screenScrollXValue
        lda screenScrollXValue
        and #%00000111
        sta screenScrollXValue

        lda SCROLX
        and #%11111000
        ora screenScrollXValue
        sta SCROLX

        lda screenScrollXValue
        cmp #0
        bne @finished

        ; move to previous column
        dec screenColumn
        jsr update      ; call the passed in function to update the screen rows
@finished
}

;==============================================================================

; Update subroutine (Address)
!macro  LIBSCREEN_SCROLLXRESET_A update {
        lda #0
        sta screenColumn
        sta screenScrollXValue

        lda SCROLX
        and #%11111000
        ora screenScrollXValue
        sta SCROLX

        jsr update      ; call the passed in function to update the screen rows
}

;==============================================================================

; ScrollX value (Address)
!macro  LIBSCREEN_SETSCROLLXVALUE_A scrollx {
        lda SCROLX
        and #%11111000
        ora scrollx
        sta SCROLX
}

;==============================================================================

; ScrollX value (Value)
!macro  LIBSCREEN_SETSCROLLXVALUE_V scrollx {
        lda SCROLX
        and #%11111000
        ora #scrollx
        sta SCROLX
}

;==============================================================================

; Sets 1000 bytes of memory from start address with a value
; Start  (Address), Number (Value)
!macro  LIBSCREEN_SET1000 start, num {
        lda #num                 ; Get number to set
        ldx #250                ; Set loop value
@loop   dex                     ; Step -1
        sta start,x                ; Set start + x
        sta start+250,x            ; Set start + 250 + x
        sta start+500,x            ; Set start + 500 + x
        sta start+750,x            ; Set start + 750 + x
        bne @loop               ; If x<>0 loop
}

;==============================================================================

!macro  LIBSCREEN_SET38COLUMNMODE {
        lda SCROLX
        and #%11110111 ; clear bit 3
        sta SCROLX
}

;==============================================================================

!macro  LIBSCREEN_SET40COLUMNMODE {
        lda SCROLX
        ora #%00001000 ; set bit 3
        sta SCROLX
}

;==============================================================================

; Character Memory Slot (Value)
!macro  LIBSCREEN_SETCHARMEMORY charmem {
        ; point vic (lower 4 bits of $d018)to new character data
        lda VMCSB
        and #%11110000 ; keep higher 4 bits
        ; p208 M Jong book
        ora #charmem;$0E ; maps to  $3800 memory address
        sta VMCSB
}

;==============================================================================

; Character Code (Value)
!macro  LIBSCREEN_SETCHAR_V charcode {
        lda #charcode
        sta (ZeroPageLow),Y
}

;==============================================================================

; Character Code (Value)
!macro  LIBSCREEN_SETCHAR_A charcode {
        lda /1
        sta (ZeroPageLow),Y
}

;==============================================================================

; X Position 0-39 (Address), Y Position 0-24 (Address)
!macro  LIBSCREEN_SETCHARPOSITION_AA Xpos, Ypos {
        ldy Ypos        ; load y position as index into list
        
        lda ScreenRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ScreenRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register
}

;==============================================================================

; X Position 0-39 (Address), Y Position 0-24 (Address)
!macro  LIBSCREEN_SETCOLORPOSITION_AA  Xpos, Ypos {             
        ldy Ypos        ; load y position as index into list
        
        lda ColorRAMRowStartLow,Y ; load low address byte
        sta ZeroPageLow

        lda ColorRAMRowStartHigh,Y ; load high address byte
        sta ZeroPageHigh

        ldy Xpos        ; load x position into Y register
}

;===============================================================================

; Sets the border and background colors
; Border Color (Value), Background Color 0 (Value), Background Color 1 (Value)
; Background Color 2 (Value), Background Color 3 (Value)
!macro  LIBSCREEN_SETCOLORS bordercol, bg0, bg1, bg2, bg3 {
        lda #bordercol  ; Color0 -> A
        sta EXTCOL      ; A -> EXTCOL
        lda #bg0        ; Color1 -> A
        sta BGCOL0      ; A -> BGCOL0
        lda #bg1        ; Color2 -> A
        sta BGCOL1      ; A -> BGCOL1
        lda #bg2        ; Color3 -> A
        sta BGCOL2      ; A -> BGCOL2
        lda #bg3        ; Color4 -> A
        sta BGCOL3      ; A -> BGCOL3
}

;==============================================================================

!macro  LIBSCREEN_SETMULTICOLORMODE {
        lda SCROLX
        ora #%00010000 ; set bit 5
        sta SCROLX
}

;===============================================================================

; Waits for a given scanline
; Scanline (Value)
!macro  LIBSCREEN_WAIT_V scan {    
@loop   lda #scan       ; Scanline -> A
        cmp RASTER      ; Compare A to current raster line
        bne @loop       ; Loop if raster line not reached 255
}