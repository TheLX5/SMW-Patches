;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This file is where you put the BW-RAM addresses that will be saved
;; to BW-RAM and their default values.
;; 
;; How to add a BW-RAM address to save.
;; 1) Select which things you want to save in a save file, for example,
;; Mario and Luigi coins, lives, powerup, item box and yoshi color.
;; 
;; 2) Go to bw_ram_table and add the BW-RAM address AND the amount of
;; bytes to save:
;;
;;		dl $400DB4 : dw $000A
;; 
;; Like SRAM Plus, you need to be sure that those RAM addresses aren't
;; cleared automatically when loading a save file.
;; 
;; 3) Then go to bw_ram_defaults and put the default values of your
;; BW-RAM address when loading a new file. Make sure that the default
;; values are in the same order as bw_ram_table to not get weird values
;; when loading a save file.
;; 
;; There is a maximum amount of bytes that you can save per save file
;; and that value is 2370 bytes.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bw_ram_table:
;Put save ram addresses here, not after .end.
	dl $40B40C : dw $00C0	; $40B40C is the address of !freeram_checkpoint_SA1 defined in retry_table.asm
.end
		
bw_ram_defaults:
;Format: db $xx,$xx,$xx...
;^valid sizes: db (byte), dw (word, meaning 2 bytes: $xxxx), and dl
;(long, 3-bytes: $xxxxxx). The $ (dollar) symbol isn't mandatory,
;just represents hexadecimal type of value.

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

