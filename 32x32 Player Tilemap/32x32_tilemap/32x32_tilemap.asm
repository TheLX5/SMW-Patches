@asar 1.70
;32×32 player tilemap patch
;by Ladida

print ""
print " 32x32 player tilemap patch v1.5 "
print "            by Ladida            "
print " =============================== "
print ""

math	pri	on	;\ Asar defaults to Xkas settings instead
math	round	off	;/ of proper math rules, this fixes that.

!addr	= $0000			; $0000 if LoROM, $6000 if SA-1 ROM.
!bank	= $800000		; $80:0000 if LoROM, $00:0000 if SA-1 ROM.
!sa1	= 0

if read1($00FFD5) == $23
	!addr	= $6000
	!bank	= $000000
	!sa1	= 1
	sa1rom
endif

;;;;;;;;;
;Defines;
;;;;;;;;;

; Needs to point to freespace as large as PlayerGFX.bin (only used when PlayerGFX.bin is > 64KiB)
!Freedata	= $3C8000

;;;;;;;;;
; DO NOT EDIT THOSE BELOW!!!

!PlayerGFX_size #= select(equal(readfile1("PlayerGFX.bin",$10000,$FF),readfile1("PlayerGFX.bin",$10000,$00)), select(equal(readfile1("PlayerGFX.bin",$20000,$FF),readfile1("PlayerGFX.bin",$20000,$00)),$30000,$20000),$10000)
assert !PlayerGFX_size >= 0, "PlayerGFX.bin not found"
assert !PlayerGFX_size <= $20000, "PlayerGFX.bin is too big, must be at most 128KiB"

assert !Freedata%$8000 == 0, "Freedata must point to the start of a bank"
if !sa1
	assert !Freedata&$7F0000 < $400000, "Freedata is currently unsupported in the SA-1 HiROM area"
endif

assert read1($0FFB51) != $FF, "Please insert ExGFX once to enable some Lunar Magic's ASM hacks."
assert read1($048509) == $22, "Please save the Overworld at least once to enable some Lunar Magic's ASM hacks."

;;;;;;;;;
;Hijacks;
;;;;;;;;;

org $00A300|!bank
autoclean JML MarioGFXDMA
RTS

org $00E370|!bank
BEQ +
org $00E381|!bank
BNE +
org $00E385|!bank
NOP #6
+
LDA #$F8

org $00E3B0|!bank
TAX
LDA.l excharactertilemap,x
STA $0A
STZ $06
BRA +
NOP #5
+

org $00E3E4|!bank
BRA +
org $00E3EC|!bank
+

org $00F636|!bank
JML tilemapmaker

org $00A169|!bank
LDA #$F0
STA $3F

org $0FFB9C|!bank
JML skip_mario_gfx

org $0FFC94|!bank
JML fix_mario_palette

incsrc "hexedits.asm"
incsrc "ow_mario.asm"


;;;;;;;;;;;;;;;;;
;MAIN CODE START;
;;;;;;;;;;;;;;;;;

freecode

if !PlayerGFX_size > $10000
	prot PlayerGFX,PlayerGFX_prot2
else
	prot PlayerGFX
endif

FreecodeStart:

skip_mario_gfx:
LDX #$0140
STX $4325
PLX
STX $2116
STA $420B

LDY #$B180
STY $4322
LDX #$0180
STX $4325
LDX #$6240
STX $2116
STA $420B

LDY #$B380
STY $4322
LDX #$0980
STX $4325
LDX #$6340
JML $0FFBA3|!bank

fix_mario_palette:
PHX
LDY.b #$86
STY $2121
REP #$10
LDX.w #(9*2)
LDY.w #$86*2
-
LDA $213B
STA $0703|!addr,y
LDA $213B
STA $0704|!addr,y
INY #2
DEX #2
BPL -
SEP #$10
PLX
STZ $2121
REP #$30
LDA #$0200
JML $0FFC99|!bank

MarioGFXDMA:
LDY $0D84|!addr
BNE +
JMP .skipall
+

REP #$20
LDY #$04

;;
;Mario's Palette
;;

LDX #$86
STX $2121
LDA #$2200
STA $4320
LDA $0D82|!addr
STA $4322
LDX #$00
STX $4324
LDA #$0014
STA $4325
STY $420B


LDX #$80
STX $2115
LDA #$1801
STA $4320
LDX #$7E
STX $4324

;;
;Misc top tiles (cape, yoshi, podoboo)
;;

LDA #$6040
STA $2116
LDX #$04
-
LDA $0D85|!addr,x
STA $4322
LDA #$0040
STA $4325
STY $420B
INX #2
CPX $0D84|!addr
BCC -

;;
;Misc bottom tiles (cape, yoshi, podoboo)
;;

LDA #$6140
STA $2116
LDX #$04
-
LDA $0D8F|!addr,x
STA $4322
LDA #$0040
STA $4325
STY $420B
INX #2
CPX $0D84|!addr
BCC -

;;
;New player GFX upload
;;

LDX $0D87|!addr
STX $4324
LDA $0D86|!addr : PHA
LDX #$06
-
LDA.l .vramtbl,x
STA $2116
LDA #$0080
STA $4325
LDA $0D85|!addr
STA $4322
STY $420B
INC $0D86|!addr
INC $0D86|!addr
DEX #2 : BPL -
PLA : STA $0D86|!addr
SEP #$20

.skipall
JML $00A304

.vramtbl
dw $6300,$6200,$6100,$6000


tilemapmaker:
REP #$20
LDX #$00
LDA $09
AND #$0300
SEC : ROR
PHA
LDA $09
AND #$3C00
ASL
ORA $01,s
STA $0D85|!addr
LDY.b #PlayerGFX>>16
BIT $09
BPL +
INY #$02
+
BVC +
INY
+
STY $0D87|!addr
PLA
JML $00F674|!bank

incsrc "excharactertilemap.asm"

print "Patch inserted at $",hex(FreecodeStart)," (pc: $",hex(snestopc(FreecodeStart)),"), ",freespaceuse," bytes of free space used."

reset freespaceuse

!PlayerGFX_freespaceuse = freespaceuse
if !PlayerGFX_size <= $10000
	incbin "PlayerGFX.bin" -> PlayerGFX
else
	org (!Freedata-$8008)|!bank
		db $53,$54,$41,$52	;\ Asar complains when `db "STAR"` is encoutered
		dw $FFFF	;| without the file starting with `;@xkas`, even
		dw $0000	;/ when Asar only features are used
	org !Freedata|!bank
		PlayerGFX:
		incbin "PlayerGFX.bin" -> !Freedata|!bank
	org (!Freedata+$20000)|!bank
		db $53,$54,$41,$52
		dw clamp(!PlayerGFX_size-$10009,0,$FFF7)
		dw clamp(!PlayerGFX_size-$10009,0,$FFF7)^$FFFF
		.prot2:
endif

print "PlayerGFX inserted at: $",hex(PlayerGFX)," (pc: $",hex(snestopc(PlayerGFX)),"), !PlayerGFX_size bytes of free space used."
print ""
