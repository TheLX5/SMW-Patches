@includefrom "sram_plus.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SRAM Plus, SRAM table
;
; This patch basically rewrites all of the SRAM saving, loading, and erasing
; save file routines that SMW uses. It uses DMA to copy the values, meaning that
; it is much more efficient than before. The patch also frees up 141 bytes at
; $1F49 by moving the SRAM buffer to $1EA2.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This file controls what addresses are saved to the SRAM, and their default
; values.
;
; To add a RAM address to the list, simply put dl $xxxxxx : dw $yyyy on a new
; line under sram_table, where $xxxxxx is the RAM address and $yyyy is the
; number of bytes to save. DO NOT get rid of the "dl $7E1EA2 : dw $008D".
;
; For example, to save Mario and Luigi's lives, coins, powerup, item box, and
; yoshi color, you would use:
;
;		dl $7E0DB4 : dw $000A
;
; as these addresses range from $7E0DB4 to $7E0DBD, taking up a total of $000A
; bytes. Note that this actually doesn't work AS IS, though - you need to
; disable the game from automatically clearing those specific addresses when
; loading a save file.
;
; Once this is done, you must supply what the default values for the RAM
; addresses will be. This can be done by placing the appropriate number of
; bytes under sram_defaults, in order.
;
; There is a maximum of 8190 bytes that can be saved to SRAM for any save file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sram_table:	dl $7E1EA2 : dw $008D
		dl $7FB40C : dw $00C0	; $7FB40C is the address of !freeram_checkpoint defined in retry_table.asm
.end
		
sram_defaults:	db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00,$00,$00,$00
		db $00,$00,$00,$00,$00

		; initial midway state, $C0=192 bytes
		db $00,$00,$01,$00,$02,$00,$03,$00,$04,$00,$05,$00,$06,$00,$07,$00
		db $08,$00,$09,$00,$0A,$00,$0B,$00,$0C,$00,$0D,$00,$0E,$00,$0F,$00
		db $10,$00,$11,$00,$12,$00,$13,$00,$14,$00,$15,$00,$16,$00,$17,$00
		db $18,$00,$19,$00,$1A,$00,$1B,$00,$1C,$00,$1D,$00,$1E,$00,$1F,$00
		db $20,$00,$21,$00,$22,$00,$23,$00,$24,$00,$01,$01,$02,$01,$03,$01
		db $04,$01,$05,$01,$06,$01,$07,$01,$08,$01,$09,$01,$0A,$01,$0B,$01
		db $0C,$01,$0D,$01,$0E,$01,$0F,$01,$10,$01,$11,$01,$12,$01,$13,$01
		db $14,$01,$15,$01,$16,$01,$17,$01,$18,$01,$19,$01,$1A,$01,$1B,$01
		db $1C,$01,$1D,$01,$1E,$01,$1F,$01,$20,$01,$21,$01,$22,$01,$23,$01
		db $24,$01,$25,$01,$26,$01,$27,$01,$28,$01,$29,$01,$2A,$01,$2B,$01
		db $2C,$01,$2D,$01,$2E,$01,$2F,$01,$30,$01,$31,$01,$32,$01,$33,$01
		db $34,$01,$35,$01,$36,$01,$37,$01,$38,$01,$39,$01,$3A,$01,$3B,$01
