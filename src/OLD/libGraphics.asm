;===============================================================================
;                                   SHARED
;===============================================================================

; Copies ‘value’ into 1000 memory locations starting at ‘start’ address.
.macro LIBGRAPHICS_SET1000_AV start, value
.scope
  lda #value      ; Get value to set
  ldx #250        ; Set loop value
loop:
  dex             ; Step -1
  sta start,x     ; Set start + x
  sta start+250,x ; Set start + 250 + x
  sta start+500,x ; Set start + 500 + x
  sta start+750,x ; Set start + 750 + x
  bne loop        ; If x != 0 loop
.endscope
.endmacro

;===============================================================================
;                                     NES
;===============================================================================
.ifdef __NES__

; Colors
Black     = 14
White     = 48
Red       = 22
Cyan      = 28
Purple    = 36
Green     = 43
Blue      = 17
Yellow    = 41

; PPU Registers
PPUCTRL   = $2000 ; NMI enable (V), PPU master/slave (P), sprite height (H), background tile select (B), sprite tile select (S), increment mode (I), nametable select (NN) 
PPUMASK   = $2001 ; color emphasis (BGR), sprite enable (s), background enable (b), sprite left column enable (M), background left column enable (m), greyscale (G) 
PPUSTATUS = $2002 ; vblank (V), sprite 0 hit (S), sprite overflow (O); read resets write pair for $2005/$2006 
OAMADDR   = $2003 ; OAM read/write address 
OAMDATA   = $2004 ; OAM data read/write 
PPUSCROLL = $2005 ; fine scroll position (two writes: X scroll, Y scroll) 
PPUADDR   = $2006 ; PPU read/write address (two writes: most significant byte, least significant byte) 
PPUDATA   = $2007 ; PPU data read/write 
OAMDMA    = $4014 ; OAM DMA high address

; APU Registers
DMCFREQ	  = $4010
APUFRAME  = $4017

;===============================================================================

; Initialize NES to a steady and stable state
.macro LIBGRAPHICS_INIT
  sei           ; ignore IRQs
  cld           ; disable decimal mode
  ldx #$40
  stx APUFRAME  ; disable APU frame IRQ
  ldx #$ff
  txs           ; Set up stack
  inx           ; now X = 0
  stx PPUCTRL   ; disable NMI
  stx PPUMASK   ; disable rendering
  stx DMCFREQ   ; disable DMC IRQs

  ; The vblank flag is in an unknown state after reset,
  ; so it is cleared here to make sure that LIBGRAPHICS_WAITVSYNC
  ; does not exit immediately.
  bit PPUSTATUS
  
  ; First of two waits for vertical blank to make sure that the
  ; PPU has stabilized
  LIBGRAPHICS_WAITVSYNC
  
  ; We now have about 30,000 cycles to burn before the PPU stabilizes.
  ; One thing we can do with this time is put RAM in a known state.
  ; Here we fill it with $00, which matches what (say) a C compiler
  ; expects for BSS.  Conveniently, X is still 0.
  txa
clrmem:
  sta $000,x
  sta $100,x
  sta $200,x
  sta $300,x
  sta $400,x
  sta $500,x
  sta $600,x
  sta $700,x
  inx
  bne clrmem
  
  ; wait for VSYNC, PPU is ready after this
  LIBGRAPHICS_WAITVSYNC

  ; enable the rendering
  LIBGRAPHICS_ENABLEPPU
.endmacro

;===============================================================================

; Disable graphics rendering
.macro LIBGRAPHICS_DISABLEPPU
  lda #0
  sta PPUMASK	; disable rendering
.endmacro

;===============================================================================

; Enable graphics rendering
.macro LIBGRAPHICS_ENABLEPPU
  lda #%00001010  ; enable background and left 8 pixels
  sta PPUMASK     ; enable rendering
.endmacro

;===============================================================================

; Reset the PPU address and scroll registers
.macro LIBGRAPHICS_RESETPPU
  lda #0
  sta PPUADDR   ; reset PPU address (write twice)
  sta PPUADDR   ; PPUADDR = 0
  sta PPUSCROLL ; reset scroll registers (write twice)
  sta PPUSCROLL ; PPUSCROLL = $0000
.endmacro

;===============================================================================

; Set the PPU address
.macro LIBGRAPHICS_SETPPUADDRESS_A address
  lda #>address	; high byte -> A register
  sta PPUADDR   ; write high byte first
  lda #<address ; low byte -> A register
  sta PPUADDR   ; then write low byte
.endmacro

;===============================================================================

; Wait for the vsync
.macro LIBGRAPHICS_WAITVSYNC
: bit PPUSTATUS ; bit 7 -> N flag
  bpl :-        ; loop back while N flag is zero
.endmacro

.endif ; __NES__

;===============================================================================
;                                     C64
;===============================================================================
.ifdef __C64__

; Colors
Black     = 0
White     = 1
Red       = 2
Cyan      = 3
Purple    = 4
Green     = 5
Blue      = 6
Yellow    = 7
Space     = 32

; Memory areas
SCREENRAM = $0400

; VIC-II Registers
SCROLY    = $D011
RASTER    = $D012
EXTCOL    = $D020
BGCOL0    = $D021

;===============================================================================

; Initialize C64 to a steady and stable state
.macro LIBGRAPHICS_INIT
  sei			                                ; disable IRQs
  LIBGRAPHICS_SET1000_AV SCREENRAM, Space ; clear the screen
.endmacro

;===============================================================================

; Wait for the vsync
.macro LIBGRAPHICS_WAITVSYNC
  LIBGRAPHICS_WAIT_V 241 ; use 241 to match NES
.endmacro 

;===============================================================================

 ; Wait for a scanline (0-261 NTSC, 0-311 PAL) 
.macro LIBGRAPHICS_WAIT_V scanline
.scope     
loop:
  lda #<scanline    ; Scanline -> Accumulator        
  cmp RASTER        ; Compare Accum to raster              
  bne loop          ; Loop if not reached
  bit SCROLY        ; Bit 7 of SCROLY ->N flag
.if scanline <= 255 ; Build-time(not run-time)   
  bmi loop          ; Loop if N flag is 1
.else
  bpl loop          ; Loop if N flag is 0
.endif
.endscope
.endmacro

.endif ; __C64__