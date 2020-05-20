;===============================================================================

.macro LIBADDR_IND_DEC addr, offset
	ldy #offset
	lda (addr),Y
	tax
	dex
	txa
	sta (addr),Y
.endmacro

.macro LIBADDR_IND_INC addr, offset
	ldy #offset
	lda (addr),Y
	tax
	inx
	txa
	sta (addr),Y
.endmacro