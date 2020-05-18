;===============================================================================
;                                   SHARED
;===============================================================================

; Execute 2 nested loops (count x 255) 
.macro LIBTEST_DELAY_V count
.scope
  ldx #count
loop:
  ldy #255
loop2:
  dey
  bne loop2
  dex
  bne loop
.endscope
.endmacro

;===============================================================================
;                                     NES
;===============================================================================
.ifdef __NES__

; Set the screen color
.macro LIBTEST_SETSCREENCOLOR_V color
  LIBGRAPHICS_DISABLEPPU
  LIBGRAPHICS_SETPPUADDRESS_A $3f00 ; set palette address to the PPU
  lda #color                      ; color -> A
  sta PPUDATA                     ; A -> PPU palette address (1st entry in palette)
  LIBGRAPHICS_RESETPPU
  LIBGRAPHICS_ENABLEPPU
.endmacro

.endif ; __NES__

;===============================================================================
;                                     C64
;===============================================================================
.ifdef __C64__

; Set the screen color
.macro LIBTEST_SETSCREENCOLOR_V color
  lda #color  ; color -> A
  sta EXTCOL  ; A -> border color
  sta BGCOL0  ; A -> screen color
.endmacro

.endif ; __C64__