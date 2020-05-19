    CIA_PRA     =  $dc00            ; CIA#1 (Port Register A)
    CIA_PRB     =  $dc01            ; CIA#1 (Port Register B)

    CIA_DDRA    =  $dc02            ; CIA#1 (Data Direction Register A)
    CIA_DDRB    =  $dc03            ; CIA#1 (Data Direction Register B)

;===============================================================================

    X_KEY_ROW   = %11111011
    X_KEY_COL   = %10000000
    U_KEY_ROW   = %11110111
    U_KEY_COL   = %01000000
    N_KEY_ROW   = %11101111
    N_KEY_COL   = %10000000
    H_KEY_ROW   = %11110111
    H_KEY_COL   = %00100000
    J_KEY_ROW   = %11101111
    J_KEY_COL   = %00000100

;===============================================================================

.macro LIBKBD_INIT
    lda #%11111111  ; CIA#1 Port A set to output 
    sta CIA_DDRA             
    lda #%00000000  ; CIA#1 Port B set to input
    sta CIA_DDRB      
.endmacro

.macro LIBKBD_CHECK_KEY row, col
    lda #row        ; select row 3
    sta CIA_PRA 
    lda CIA_PRB     ; load column information
    and #col        ; test key
.endmacro