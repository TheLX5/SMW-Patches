;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Sprite Message Box v1.1
; - by Edit1754
; - Modified & fixed by lx5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	lorom
	!sa1 = 0
	!bank = $800000
	!addr = $0000

	!freeram = $7F4000

if read1($00FFD5) == $23	; Detects SA-1.
	sa1rom
	!sa1 = 1
	!bank = $000000
	!addr = $6000
	!freeram = $410000
endif

;;;;;;;;;;;;;;;;
; Defines
;;;;;;;;;;;;;;;;

	!GFXFileNumber			= $02FF				; Graphics file to use
	
	!DMACh				= 0		; Might want to change this to 1 if you use the DMA Remap patch
	!HDMACh				= 7		; Might want to change this to 0 if you use the DMA Remap patch

	; I have no idea what are referring to these two defines below.
	; I left them there because I have no idea how to test them.	
	!SpriteTilesReservedEnabled	= 0		; \ If you use ASM hacks that need full control over
	!RAM_SpriteTilesReserved	= $13E6|!addr	; / a certain amount of tiles at the end of the OAM

	!FREERAM_DecompBuffer		= !freeram			; $1000 bytes (borrows ExAnimation slot)
	!FREERAM_TileBackups		= !freeram+$1000		; 0x1200 bytes (borrows part of stripe RAM)
	!FREERAM_SpriteTilesUsed	= !freeram+$2200		; 0x200 bytes
	!FREERAM_UploadTileNumbers	= !freeram+$2400		; 0x48 bytes
	!FREERAM_MessageBuffer		= !freeram+$2448		; 0x90 bytes
	!FREERAM_OpenFinalizedFlag	= !freeram+$24D8		; 1 byte
	
	!SpriteTileVRAMHalfPtr		= $6000				; VRAM/2 address of start of SP1/2/3/4
	!TileUnused			= $FF				; Unused tile
	!TileReserved			= $FE				; Tile used by what's already in the OAM
	!Message_End			= $FE				; byte to stop copying message text
	!MessageTileCount		= 8*18				; Number of 8x8 tiles in a message
	!MessageIndicesCount		= (!MessageTileCount/4)		; Numbe of 16x16 tiles in a message
	!TileIndicesCount 		= $EA				; Number of tiles in tile index table
	!Tile_Space			= $1F

	!RAM_FrameCounter		= $13
	!RAM_ControllerA		= $15
	!RAM_ControllerAPulse		= $16
	!RAM_ControllerB		= $17
	!RAM_ControllerBPulse		= $18
	!RAM_SpritesLocked		= $9D
	!RAM_LevelNum			= $010B|!addr
	!RAM_OAM			= $0200|!addr
	!RAM_OAM_Entry_X		= !RAM_OAM+0
	!RAM_OAM_Entry_Y		= !RAM_OAM+1
	!RAM_OAM_Entry_Tile		= !RAM_OAM+2
	!RAM_OAM_Entry_Bits		= !RAM_OAM+3
	!RAM_OAMExtraBits		= $0420|!addr
	!RAM_TransLevelNumber		= $13BF|!addr
	!RAM_PlayerFrozen		= $13FB|!addr
	!RAM_MessageBoxTriggerType	= $1426|!addr
	!RAM_OnYoshi			= $187A|!addr
	!RAM_MessageBoxGrowShrinkFlag	= $1B88|!addr
	!RAM_MessageBoxGrowShrinkTimer	= $1B89|!addr
	!RAM_AllowDismissMessageTimer	= $1DF5|!addr


	!ROM_SuperGFXBypassAddr		= read3($0FF7FF)

if read1($009F37) == $5C
	!ROM_SMWWindowingTable		= (read3($009F38)+$14E)
else
	!ROM_SMWWindowingTable		= $00927C
endif

	!ROM_AniAddress			= read3($00A391)

!custom_powerups = 0
if read2($00D067|!bank) == $DEAD
	!custom_powerups = 1
endif

	print "Sprite Message Box v1.1"
	print " "

;;;;;;;;;;;;;;;;
; Macros
;;;;;;;;;;;;;;;;

macro check_level()
	LDA !RAM_LevelNum+1			; \ Get high bit
	LSR					; / into carry flag
	LDA !RAM_LevelNum			; \ Get level number >> 1 (incl. high bit)
	ROR					; / and also get least significant bit into carry
	TAX					; Level number >> 1 (divided by two) -> X
	LDA LevelTable,x			; Get dual-level-represnting byte
	BCS ?e					; If level is odd number (carry set), don't shift even level's bits down
	LSR #4					; Shift even level's bits down
?e:	AND #%00000001				; Narrow our focus to the "Enabled" bit
endmacro
	
macro copy_tile(n)
	LDA !FREERAM_SpriteTilesUsed+<n>,x	; Get source tile number
	AND #$00FF				; We're in 16-bit A, so AND-out the high byte
	ASL #5					; * 32
	;CLC				; Pretty sure we can omit this because 5 ASLs will never carry after AND #$00FF
	ADC.w #!FREERAM_DecompBuffer		; Add this offset to the decompression buffer address
	STA $4302|(!DMACh<<4)			; Set to DMA source address
	LDA #$0020				; \ Copy 0x20 bytes
	STA $4305|(!DMACh<<4)			; / (one tile)
	SEP #%00100000				; 8-bit A
	LDA.b #(1<<!DMACh)			; \ Run DMA
	STA $420B				; / transfer
	REP #%00100000				; back to 16-bit A
endmacro

macro upload(n)
	LDA !FREERAM_UploadTileNumbers+(<n>*2),x	; Get tile destination number
	ASL #4						; * 8
	CLC : ADC #!SpriteTileVRAMHalfPtr		; + Sprite VRAM/2 offset
	STA $2116					; Set VRAM pointer
	STA $00						; Temporarily store to scratch RAM
	LDY $2139					; Dummy read
	LDA #$3981					; \ [$21]39 (VRAM Read) and %10000001
	STA $4300|(!DMACh<<4)				; / (2 regs read once)
	LDA #$0040					; \ Copy 0x40 bytes
	STA $4305|(!DMACh<<4)				; / (two tiles: row)
	TXA : LSR : LSR : XBA				; Get offset to tile backup buffer
	CLC : ADC.w #!FREERAM_TileBackups+(<n>*$80)	; Add to actual memory address of tile backup buffer
	STA $4302|(!DMACh<<4)				; Store to DMA RAM address
	SEP #%00100000					; 8 bit A
	LDA.b #!FREERAM_TileBackups>>16			; \ set DMA
	STA $4304|(!DMACh<<4)				; / bank byte
	LDA.b #(1<<!DMACh)				; \ Run DMA
	STA $420B					; / transfer
	REP #%00100000					; back to 16-bit A
	LDA $00						; Reload VRAM pointer
	CLC : ADC #$0100				; Next line of tiles
	STA $2116					; Set VRAM pointer
	LDA $2139					; Dummy read
	LDA #$0040					; \ Copy 0x40 bytes
	STA $4305|(!DMACh<<4)				; / (two tiles: row)	
	SEP #%00100000					; 8-bit A
	LDA.b #(1<<!DMACh)				; \ Run DMA
	STA $420B					; / transfer
 if !FREERAM_DecompBuffer>>16 != !FREERAM_TileBackups>>16
	LDA.b #!FREERAM_DecompBuffer>>16		; \ set DMA
	STA $4304|(!DMACh<<4)				; / bank byte
 endif
	REP #%00100000					; back to 16-bit A
	LDA $00						; Reload VRAM pointer
	STA $2116					; Set VRAM pointer
	LDA #$1801					; \ [$21]18 (VRAM Write) and %00000001
	STA $4300|(!DMACh<<4)				; / (2 regs read once)
	LDA !FREERAM_UploadTileNumbers+(<n>*2),x	; Get tile destination number
	PHX						; Preserve X (index to tile number table)
	TAX						; Pointer -> X
	%copy_tile($00)				; Copy to top-left tile
	%copy_tile($01)				; Copy to top-right tile
	LDA $00						; Reload VRAM pointer
	CLC : ADC #$0100				; Next line of tiles
	STA $2116					; Set VRAM pointer
	%copy_tile($10)				; Copy to bottom-left tile
	%copy_tile($11)				; Copy to bottom-right tile
	PLX						; Restore X (index to tile number table)
endmacro

macro restore(n)
	LDA !FREERAM_UploadTileNumbers+(<n>*2),x	; Get tile destination number
	ASL #4						; * 8
	CLC : ADC #!SpriteTileVRAMHalfPtr		; + Sprite VRAM/2 offset
	STA $2116					; Set VRAM pointer
	TAY						; Temporarily store in Y
	LDA #$1801					; \ [$21]18 (VRAM Write) and %00000001
	STA $4300|(!DMACh<<4)				; / (2 regs write once)
	LDA #$0040					; \ Copy 0x40 bytes
	STA $4305|(!DMACh<<4)				; / (two tiles: row)
	TXA : LSR : LSR : XBA				; Get offset to tile backup buffer
	CLC : ADC.w #!FREERAM_TileBackups+(<n>*$80)	; Add to actual memory address of tile backup buffer
	STA $4302|(!DMACh<<4)				; Store to DMA RAM address
	SEP #%00100000					; 8 bit A
	LDA.b #!FREERAM_TileBackups>>16			; \ set RAM
	STA $4304|(!DMACh<<4)				; / bamk byte
	LDA.b #(1<<!DMACh)				; \ Run DMA
	STA $420B					; / transfer
	REP #%00100000					; back to 16-bit A
	TYA						; Reload VRAM pointer
	CLC : ADC #$0100				; Next line of tiles
	STA $2116					; Set VRAM pointer
	LDA #$0040					; \ Copy 0x40 bytes
	STA $4305|(!DMACh<<4)				; / (two tiles: row)	
	SEP #%00100000					; 8-bit A
	LDA.b #(1<<!DMACh)				; \ Run DMA
	STA $420B					; / transfer
	REP #%00100000					; back to 16-bit A
endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hijacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org $05B10F
	autoclean jml Main


	!offset = 0
if !custom_powerups == 0
	print hex(read3($00DFE2))
	;if  == $B91ADF
	org $00A300
		autoclean jml NMI
else
	if read1($05B113) != $69
		while read1($00A304+!offset) != $60
			!offset #= !offset+4
		endif
		!end_offset = !offset+4
	else
		!offset = read1($05B114)
	endif

	org $00A304+!offset
	print pc
		autoclean jml NMI
	NMI_end:
		rts
endif

	org $05B113
		db $69
		db !offset

org $00A0B9
	autoclean jsl HandleOWReload
	nop #2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Freespace code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

freecode

HandleOWReload:
	jsl $04DAAD|!bank

	LDA #%01000001				; \
	STA $4300|(!HDMACh<<4)			;  | Reset
	LDA.b #!ROM_SMWWindowingTable		;  | Windowing
	STA $4302|(!HDMACh<<4)			;  | Table
	LDA.b #!ROM_SMWWindowingTable>>8	;  |
	STA $4303|(!HDMACh<<4)			;  | Fixes a Snes9x bug
	LDA.b #!ROM_SMWWindowingTable>>16	;  |
	STA $4304|(!HDMACh<<4)			; /
.Recover:
	stz $0DDA|!addr
	ldx $0DB3|!addr
.Return:
	rtl


;;;;;;;;;;;;;;;;
; Main Code
;;;;;;;;;;;;;;;;

Main:
	PHB : PHK : PLB					; Preserve data bank and put code bank into data bank
	%check_level()					; Check if enabled in this level
	BNE .LetsDoThis					; If so, let's go
	PLB						; Restore databank
	LDX !RAM_MessageBoxGrowShrinkFlag		; \ Hijacked
	LDA !RAM_MessageBoxGrowShrinkTimer		; / code
	JML $05B115|!bank				; Return to regular code

.LetsDoThis
	LDX !RAM_MessageBoxGrowShrinkFlag		; X = flag whether we're growing or shrinking
	LDA !RAM_MessageBoxGrowShrinkTimer		; A = timer for growing/shrinking
	CMP $05B108|!bank,x				; Check if we're in progress of growing or shrinking
	BNE .GrowingShrinking				; If so, then we handle things accordingly
	TXA						; \ Otherwise, we've still got
	BEQ .IsOpen					; / different things to do whether it's open or closed
	
.JustFinished
	PLB						; Restore data bank
	JML $05B11D|!bank				; Return to regular code
	
.IsOpen
	LDA !FREERAM_OpenFinalizedFlag			; \
	BNE +						;  | Only execute once
	INC						;  | (between here and +)
	STA !FREERAM_OpenFinalizedFlag			; /
	REP #%00110000					; \
	LDA $010B|!addr					;  | Restore
	ASL #5						;  | animation
	CLC : ADC #$001A				;  | ExGFX slot
	TAX						;  | in buffer
	LDA.l !ROM_SuperGFXBypassAddr,x			;  |
	JSR UploadGFXFile				;  |
	SEP #%00110000					; /
+	PLB						; Restore data bank
	JML $05B132|!bank				; Return to regular code
	
.GrowingShrinking
	CPX #$00					; Check if the box is growing or shinking
	BEQ .Growing					; If growing, then handle accordingly
	JMP .Shrinking					; else, if shrinking, handle accordingly
	
.Growing
	CMP #$00				; \ Perform initial setups
	BEQ .InitialStep			; / when box first opened
	CMP #$4C				; \
	BNE +					;  | Perform final step if we're there
	JMP .FinalStep				; /
+	PLB					; Restore data bank
	JML $05B250|!bank			; Return to regular code
	
.InitialStep
	LDA #$00
	STA !FREERAM_OpenFinalizedFlag

	REP #%00010000				; We need 16-bit X/Y indices for this
	
	LDA #!TileUnused			; \
	LDX #$01FF				;  | Set all tiles unused
-	STA !FREERAM_SpriteTilesUsed,x		;  |
	DEX					;  | 
	BPL -					; /

if !SpriteTilesReservedEnabled

	LDA !RAM_SpriteTilesReserved		; \
	REP #%00100000				;  | Start after
	AND #$00FF				;  | reserved tiles.
	ASL #4					;  | Don't modify
	EOR #$FFFF				;  | reserved tiles.
	CLC : ADC #$01FC+1			;  |
	TAX					;  |
	TAY					;  |
	SEP #%00100000				; /

else

	LDY #$01FC				; Start at end of regular OAM table
	LDX #$01FC				; Start at end of new OAM table

endif

-	LDA !RAM_OAM_Entry_Y,y			; \
	CMP #$E0				;  | If this is not a visible sprite, skip
	BCC +					;  |
	JMP ++					; /
+
	LDA !RAM_OAM_Entry_X,y			; \ Copy X Coordinate
	STA !RAM_OAM_Entry_X,x			; /
	LDA !RAM_OAM_Entry_Y,y			; \ Copy Y Coordinate
	STA !RAM_OAM_Entry_Y,x			; /
	LDA !RAM_OAM_Entry_Tile,y		; \ Copy Tile Number
	STA !RAM_OAM_Entry_Tile,x		; /
	STA $00					; Store tile number into scratch RAM
	LDA !RAM_OAM_Entry_Bits,y		; \ Copy YXPPCCCT bits
	STA !RAM_OAM_Entry_Bits,x		; /
	AND #%00000001				; \ Store tile number high bit into scratch RAM
	STA $01					; / ($00 addressed 16-bit is now full tile number)
	
	PHX					; Preserve X: Index to new OAM table
	
	PHY					; Preserve Y: Index to regular OAM table
	REP #%00100000				; \
	TYA					;  | Divide X and Y
	LSR #2					;  | each by four
	TAY					;  |
	TXA					;  |
	LSR #2					;  |
	TAX					;  |
	SEP #%00100000				; /
	LDA !RAM_OAMExtraBits,y			; \ Copy over the data from
	STA !RAM_OAMExtraBits,x			; / the extra bit table
	PLY					; Restore Y: Index to regular OAM table
	
	AND #%00000010				; \ If 8x8 (not 16x16), then
	BEQ +					; / skip the three extra tiles
	REP #%00100000				; \
	LDA $00					;  | Pointer for 8x8 tile:
	INC					;  | xX
	AND #$01FF				;  | xx
	TAX					;  |
	SEP #%00100000				; /
	LDA #!TileReserved			; \ Mark that tile used
	STA !FREERAM_SpriteTilesUsed,x		; /
	REP #%00100000				; \
	TXA					;  | Pointer for 8x8 tile:
	CLC : ADC #$000F			;  | xx
	AND #$01FF				;  | Xx
	TAX					;  |
	SEP #%00100000				; /
	LDA #!TileReserved			; \ Mark that tile used
	STA !FREERAM_SpriteTilesUsed,x		; /
	REP #%00100000				; \
	TXA					;  | Pointer for 8x8 tile:
	INC					;  | xx
	AND #$01FF				;  | xX
	TAX					;  |
	SEP #%00100000				; /
	LDA #!TileReserved			; \ Mark that tile used
	STA !FREERAM_SpriteTilesUsed,x		; /
+	LDX $00					; Pointer for top-left tile (or only tile if not 16x16)
	LDA #!TileReserved			; \ Mark that tile used
	STA !FREERAM_SpriteTilesUsed,x		; /
	
	PLX					; Restore X: Index to regular OAM table
	
	DEX #4					; X: Next slot down in new OAM table
	
++	DEY #4					; Y: Next slot down in regular OAM table
	BMI +					; \ If we're not finished, loop for next OAM entry
	JMP -					; / 
+
	LDA.b #$F0				; \
-	STA !RAM_OAM_Entry_Y,x			;  | Mark remaining tiles in
	DEX #4					;  | new OAM as unseen
	BPL -					; /
	
	SEP #%00010000				; Return to 8-bit X/Y indices

	LDY !RAM_MessageBoxTriggerType		; Message type
	CPY #$03				; \ Branch if
	BEQ .YoshTh				; / Yoshi Thanks
	LDA !RAM_TransLevelNumber		; Get "translevel" number
	CMP $03BB9B				; \ Yoshi's House message
	BEQ .YoshH				; / if applicable
	DEY					; Message type -= 1
	BNE ++					; If not zero (first message), then go ahead and do message 1
	CMP $03BBA2				; \ Switch Palace 1 message
	BEQ .SWPL				; / if applicable
	INY					; Message type += 1
	CMP $03BBA7				; \ Switch palace 2 message
	BEQ .SWPL				; / if applicable
	INY					; Message type += 1
	CMP $03BBAC				; \ Switch palace 3 message
	BEQ .SWPL				; / if applicable
	INY					; Message type += 1
	CMP $03BBB1				; \ Not switch palace 4 message
	BNE +					; / if not applicable
.SWPL	;TODO Something that puts the [!] blocks on the message. For now, unsupported.
+	LDY #$00				; \ Switch palace
	TAX					; / message stuff
	BRA ++					; Jump over other handlers to get message pointer
.YoshTh	LDA #$00				; \ Yoshi Thanks
	LDY #$01				; / message stuff
	BRA ++					; Jump over other handlers to get message pointer
.YoshH	LDY #$00				; Yoshi's House message thing
	LDX !RAM_OnYoshi			; \
	BEQ ++					;  | Message Type =+ 1 if not on Yoshi
	INY					; /
++	REP #%00110000				; 16-bit A, X/Y
	ASL					; \
	STA $00					;  | Get pointer to
	TYA					;  | table of actual
	CLC					;  | pointers
	ADC $00					;  |
	ASL					;  |
	TAX					; /
	LDA $03BC0C				; \ High byte of table
	STA $01					; / (plus false middle byte that we overwrite)
	LDA $03BE80,x				; Get pointer to message within table
	CLC : ADC $03BC0B			; Offset to start of table
	STA $00					; And set main offset for indirect addressing
	
	SEP #%00100000				; \
	LDX.w #$0000				;  | Copy message over
	LDY.w #$0000				;  | for a maximum of
-	LDA [$00],y				;  | !MessageTileCount
	CMP.b #!Message_End			;  | bytes, and filling
	BEQ +					;  | any remaining tiles
	CPX.w #!MessageTileCount		;  | after a shorter
	BCS ++					;  | message with spaces
	STA !FREERAM_MessageBuffer,x		;  |
	INX					;  |
	INY					;  |
	BRA -					;  |
+	LDA #!Tile_Space			;  |
-	CPX.w #!MessageTileCount		;  |
	BCS ++					;  |
	STA !FREERAM_MessageBuffer,x		;  |
	INX					;  |
	BRA -					;  |
++	REP #%00100000				; /

	LDX.w #$0000				; First source tile
	LDY.w #$0000				; First dest tile candidate
-	PHX					; \
	LDX Data_TileIndices,y			;  | Check if
	LDA !FREERAM_SpriteTilesUsed+$00,x	;  | tiles free
	AND !FREERAM_SpriteTilesUsed+$10,x	;  |
	PLX					; /
	CMP.w #(!TileUnused<<8)|!TileUnused	; \ (AND check ONLY works because !TileUnused is FF)
	BNE ++					; / If any of the tiles have been used already, skip.
	PHX					; \
	LDA Data_MessageIndices,x		;  |
	TAX					;  | Record top-left and top-right
	LDA !FREERAM_MessageBuffer,x		;  | tile source numbers from 16-bit A
	LDX Data_TileIndices,y			;  |
	STA !FREERAM_SpriteTilesUsed+$00,x	;  |
	TXA					;  | \  While we're at it, let's
	PLX					; /   | ...
	STA !FREERAM_UploadTileNumbers,x	;    /  record the tile dest number
	PHX					; \
	LDA Data_MessageIndices,x		;  | Record bottom-left and bottom-right
	CLC : ADC #$0012			;  | tile source numbers from 16-bit A
	TAX					;  |
	LDA !FREERAM_MessageBuffer,x		;  |
	LDX Data_TileIndices,y			;  |
	STA !FREERAM_SpriteTilesUsed+$10,x	;  |
	;PLX					; /
	
	;PHX					; Preserve X: Source tile index
	;TXA					; \
	LDA 1,S		; We can do this instead of the above three instructions, since we don't really need to restore X
	ASL					;  | X *= 2
	TAX					; /
	AND #$00FF				; Need A high to be zero a bit later on
	SEP #%00100000				; 8-bit A
	LDA Data_TileIndices,y			; Get tile number
	STA !RAM_OAM_Entry_Tile,x		; Set to this OAM entry
	
	LDA !RAM_LevelNum+1			; \ 
	LSR					;  | Get palette
	LDA !RAM_LevelNum			;  | as specified
	ROR					;  | in level table
	PHX					;  |
	TAX					;  |
	LDA LevelTable,x			;  |
	BCS +					;  |
	LSR #4					;  |
+	AND #%00001110				;  |
	PLX					; /

	ORA Data_TileIndices+1,y		; Add in tile high bit to the YXPPCCCT format
	STA !RAM_OAM_Entry_Bits,x		; Store to fourth byte of OAM entry

	REP #%00100000				; 16-bit A

	LDA 1,S					; Get back Source tile index on stack, without pulling it
	LSR					; / 2
	TAX					; -> X
	SEP #%00100000				; 8-bit A
	LDA #%00000010				; 16x16. X high bit = 0.
	STA !RAM_OAMExtraBits,x			; Store to extra bits entry
	REP #%00100000				; 16-bit A
	PLX
	
	INX #2					; Next source tile
	CPX.w #!MessageIndicesCount*2		; \ If we finished,
	BCS +					; / then get out
++	INY #2					; Next dest tile candidate
	CPY.w #!TileIndicesCount*2		; \ If we haven't exhausted our possibilities (shouldn't happen generally)
	BCS +					; / then loop
	JMP -					; loop
+

	LDA #!GFXFileNumber			; \ Upload graphics file temporarily
	JSR UploadGFXFile			; / over animation ExGFX

	SEP #%00110000				; 8-bit A, X/Y
	
	LDY #$00				; \
	PHY					;  | Mirrors SMW code
	PLB					;  | Copies ------ab
	LDY #$1E				;  | from $0420-$049F
-	LDX $8475,y				;  | to abababab
	LDA !RAM_OAMExtraBits+3,x		;  | in $0400-$041F
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+2,x		;  |
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+1,x		;  |
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+0,x		;  |
	STA $0400|!addr,y			;  |
	LDA !RAM_OAMExtraBits+7,x		;  |
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+6,x		;  |
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+5,x		;  |
	ASL					;  |
	ASL					;  |
	ORA !RAM_OAMExtraBits+4,x		;  |
	STA $0401|!addr,y			;  |
	DEY #2					;  |
	BPL -					; /
	
	PLB					; \ Back to SMW Code
	JML $05B250|!bank			; /

.FinalStep
	REP #%00110000				; 16-bit A, X/Y
	LDY #$0046				; \
	LDX #$008C				;  | Set all
-	LDA Data_MessageOAM_XY,y		;  | OAM tile
	STA !RAM_OAM_Entry_X,x			;  | positions
	DEY #2					;  | (before this,
	DEX #4					;  | they're offscreen)
	BPL -					; /
	SEP #%00110000				; 8-bit A, X/Y
	PLB					; Restore data bank (next code is copied from SMW with stuff removed)
	;LDX !RAM_MessageBoxGrowShrinkFlag	; \
	;LDA !RAM_MessageBoxGrowShrinkTimer	;  | Advance timer
	;CLC					;  |
	;ADC $B10A,x				;  |
	LDA #$50		; Actually, we know this is going to be #$50
	STA !RAM_MessageBoxGrowShrinkTimer	; /
	PLB					; Restore data bank (original message box routine)
	RTL					; Return to original routine caller

.Shrinking
	CMP #$50				; \ If first shrinking frame,
	BEQ .HideTextTiles			; / then hide sprite tiles
	PLB					; Restore data bank
	JML $05B250|!bank			; Return to regular code
	
.HideTextTiles
	LDA #$F0				; \ Y=F0 (offscreen)
	STA !RAM_OAM+$01			;  |
	STA !RAM_OAM+$05			;  |
	STA !RAM_OAM+$09			;  |
	STA !RAM_OAM+$0D			;  |
	STA !RAM_OAM+$11			;  |
	STA !RAM_OAM+$15			;  |
	STA !RAM_OAM+$19			;  |
	STA !RAM_OAM+$1D			;  |
	STA !RAM_OAM+$21			;  |
	STA !RAM_OAM+$25			;  |
	STA !RAM_OAM+$29			;  |
	STA !RAM_OAM+$2D			;  |
	STA !RAM_OAM+$31			;  |
	STA !RAM_OAM+$35			;  |
	STA !RAM_OAM+$39			;  |
	STA !RAM_OAM+$3D			;  |
	STA !RAM_OAM+$41			;  |
	STA !RAM_OAM+$45			;  |
	STA !RAM_OAM+$49			;  |
	STA !RAM_OAM+$4D			;  |
	STA !RAM_OAM+$51			;  |
	STA !RAM_OAM+$55			;  |
	STA !RAM_OAM+$59			;  |
	STA !RAM_OAM+$5D			;  |
	STA !RAM_OAM+$61			;  |
	STA !RAM_OAM+$65			;  |
	STA !RAM_OAM+$69			;  |
	STA !RAM_OAM+$6D			;  |
	STA !RAM_OAM+$71			;  |
	STA !RAM_OAM+$75			;  |
	STA !RAM_OAM+$79			;  |
	STA !RAM_OAM+$7D			;  |
	STA !RAM_OAM+$81			;  |
	STA !RAM_OAM+$85			;  |
	STA !RAM_OAM+$89			;  |
	STA !RAM_OAM+$8D			; /
	PLB					; Restore data bank
	JML $05B250|!bank			; Return to regular code
	
;;;;;;;;;;;;;;;;
; NMI Stuff
;;;;;;;;;;;;;;;;

macro NMI_Return()
if !custom_powerups == 1
	JML NMI_end
else
	REP #$20
	LDX #$04
	JML $00A304|!bank
endif
endmacro

NMI:
	LDA $0100|!addr				; \
	CMP #$14				;  | Only if we're
	BEQ +					;  | in a level,
	CMP #$07				;  | consider skipping
	BNE ++					; /
+	LDA !RAM_MessageBoxTriggerType		; \ Do Message Box NMI
	BNE NMICommon				; / routine if message box
	LDA !RAM_PlayerFrozen			; \
	ORA !RAM_SpritesLocked			;  | Skip entirely if these
	BNE +++					; /
++	
+++	%NMI_Return()

NMICommon:
	LDA #%10000000				; \ Increment after
	STA $2115				; / $2119/$213A
	PHB : PHK : PLB				; Preserve data bank and put code bank into data bank
	%check_level()				; \ Return if not enabled
	BNE .LetsDoThis				; / in this level
	PLB					; Restore data bank
+	%NMI_Return()

.LetsDoThis
	LDX !RAM_MessageBoxGrowShrinkFlag	; X = flag whether we're growing or shrinking
	LDA !RAM_MessageBoxGrowShrinkTimer	; A = timer for growing/shrinking
	CMP $05B108|!bank,x			; Check if we're in progress of growing or shrinking
	BNE .GrowingShrinking			; If so, then we handle things accordingly
	CMP #$50				; \ Else, if currently open
	BEQ .Open				; / then handle things accordingly
	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code
	
.GrowingShrinking
	CPX #$00				; Check if growing
	BEQ .Growing				; If so, handle accordingly
	JMP .Shrinking				; else, handle accordingly
	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code
	
.Growing
	CMP #$04				; \
	BCC +					;  | 0x04 <= t < 0x4C is range
	CMP #$4C				;  | where we upload tiles
	BCC .TileUpload				; /
+	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code

.Open
	LDA !FREERAM_OpenFinalizedFlag		; \ If not first frame of being open,
	BNE +					; / then don't execute this code
	LDA #%00000100				; \
	STA $4300|(!HDMACh<<4)			;  | Change a few
	LDA.b #Data_WindowingTable		;  | things about
	STA $4302|(!HDMACh<<4)			;  | the Windowing
	LDA.b #Data_WindowingTable>>8		;  | HDMA
	STA $4303|(!HDMACh<<4)			;  |
	LDA.b #Data_WindowingTable>>16		;  |
	STA $4304|(!HDMACh<<4)			; /
	LDA #%00100010				; \
	STA $41					;  | Set some
	STA $2123				;  | windowing
	STA $42					;  | registers
	STA $2124				;  |
	LDA #%00101010				;  |
	STA $43					;  |
	STA $2125				;  |
	LDA #%10101010				;  |
	STA $212A				;  |
	STA $212B				; /
+	PLB					; Restore databank
	%NMI_Return()				; Retturn to regular code

.TileUpload
	SEC : SBC #$04				; \ Get index
	TAX					; / to tiles
	REP #%00110000				; 16-bit A, X/Y
	%upload(0)				; Upload a 16x16
	%upload(1)				; Upload another 16x16
	SEP #%00110000				; 8-bit A, X/Y
	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code
	
.Shrinking
	CMP #$00				; \
	BCC +					;  | 0x04 <= t < 0x4C is range
	CMP #$4C				;  | where we upload tiles
	BCC .TileRestore			; /
+	CMP #$50				; \ 
	BNE +					; /
	LDA #%01000001				; \
	STA $4300|(!HDMACh<<4)			;  | Reset
	LDA.b #!ROM_SMWWindowingTable		;  | Windowing
	STA $4302|(!HDMACh<<4)			;  | Table
	LDA.b #!ROM_SMWWindowingTable>>8	;  |
	STA $4303|(!HDMACh<<4)			;  |
	LDA.b #!ROM_SMWWindowingTable>>16	;  |
	STA $4304|(!HDMACh<<4)			; /
+	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code
	
.TileRestore
	SEC : SBC #$04				; \ Get index
	TAX					; / to tiles
	REP #%00110000				; 16-bit A, X/Y
	%restore(0)				; Restore a 16x16
	%restore(1)				; Restore another 16x16
	SEP #%00110000				; 8-bit A, X/Y
	PLB					; Restore data bank
	%NMI_Return()				; Return to regular code
	
;;;;;;;;;;;;;;;;
; Upload GFX File to buffer
;;;;;;;;;;;;;;;;

UploadGFXFile:
	phx
	phy
	pha
	lda.w #!FREERAM_DecompBuffer
	sta $00
	lda.w #!FREERAM_DecompBuffer/$100
	sta $01
	pla
	jsl $0FF900|!bank
	ply
	plx
	rts
	
;;;;;;;;;;;;;;;;
; Tables not to modify
;;;;;;;;;;;;;;;;
Data:
	
.TileIndices		; Omits indices at which a 16x16 tile would wrap around past tile 1FF. Makes addition easier.
	;dw $000A,$000E
	;dw $0020,$0022,$0024,$0026		;Omits to ensure Custom Powerups compatibility.

	dw $0028,$002A,$002C,$002E
	dw $0040,$0042,$0044,$0046,$0048,$004A,$004C,$004E
	dw $0060,$0062,$0064,$0066,$0068,$006A,$006C
	dw $0080,$0082,$0084,$0086,$0088,$008A,$008C,$008E
	dw $00A0,$00A2,$00A4,$00A6,$00A8,$00AA,$00AC,$00AE
	dw $00C0,$00C2,$00C4,$00C6,$00C8,$00CA,$00CC,$00CE
	dw $00E0,$00E2,$00E4,$00E6,$00E8,$00EA,$00EC,$00EE
	dw $0100,$0102,$0104,$0106,$0108,$010A,$010C,$010E
	dw $0120,$0122,$0124,$0126,$0128,$012A,$012C,$012E
	dw $0140,$0142,$0144,$0146,$0148,$014A,$014C,$014E
	dw $0160,$0162,$0164,$0166,$0168,$016A,$016C,$016E
	dw $0180,$0182,$0184,$0186,$0188,$018A,$018C,$018E
	dw $01A0,$01A2,$01A4,$01A6,$01A8,$01AA,$01AC,$01AE
	dw $01C0,$01C2,$01C4,$01C6,$01C8,$01CA,$01CC,$01CE
	dw $01E0,$01E2,$01E4,$01E6,$01E8,$01EA,$01EC,$01EE
	
	;dw $001D
	;dw $0031,$0033,$0035
	dw $0037,$0039,$003B,$003D
	dw $0051,$0053,$0055,$0057,$0059,$005B,$005D
	dw $0071,$0073,$0075,$0077,$0079,$007B,$007D
	dw $0091,$0093,$0095,$0097,$0099,$009B,$009D
	dw $00B1,$00B3,$00B5,$00B7,$00B9,$00BB,$00BD
	dw $00D1,$00D3,$00D5,$00D7,$00D9,$00DB,$00DD
	dw $00F1,$00F3,$00F5,$00F7,$00F9,$00FB,$00FD
	dw $0111,$0113,$0115,$0117,$0119,$011B,$011D
	dw $0131,$0133,$0135,$0137,$0139,$013B,$013D
	dw $0151,$0153,$0155,$0157,$0159,$015B,$015D
	dw $0171,$0173,$0175,$0177,$0179,$017B,$017D
	dw $0191,$0193,$0195,$0197,$0199,$019B,$019D
	dw $01B1,$01B3,$01B5,$01B7,$01B9,$01BB,$01BD
	dw $01D1,$01D3,$01D5,$01D7,$01D9,$01DB,$01DD
	
	dw $001F,$003F,$005F,$009F,$00BF,$00DF,$00FF
	dw $011F,$013F,$015F,$017F,$019F,$01BF,$01DF
	
.MessageIndices
	dw $0000,$0002,$0004,$0006,$0008,$000A,$000C,$000E,$0010
	dw $0024,$0026,$0028,$002A,$002C,$002E,$0030,$0032,$0034
	dw $0048,$004A,$004C,$004E,$0050,$0052,$0054,$0056,$0058
	dw $006C,$006E,$0070,$0072,$0074,$0076,$0078,$007A,$007C
	
.MessageOAM_XY
	dw $2F38,$2F48,$2F58,$2F68,$2F78,$2F88,$2F98,$2FA8,$2FB8
	dw $3F38,$3F48,$3F58,$3F68,$3F78,$3F88,$3F98,$3FA8,$3FB8
	dw $4F38,$4F48,$4F58,$4F68,$4F78,$4F88,$4F98,$4FA8,$4FB8
	dw $5F38,$5F48,$5F58,$5F68,$5F78,$5F88,$5F98,$5FA8,$5FB8

.WindowingTable
	db $27,$FF,$00,$FF,$00		; scanlines with no windowing
	db $08,$30,$D0,$FF,$00		; scanlines windowing pixels 0x30-0xCF
	db $40,$30,$D0,$38,$C7		; scanlines windowing 0x30-0xCF but not 0x38-0xC7
	db $07,$30,$D0,$FF,$00		; scanlines windowing pixels 0x30-0xCF
	db $6A,$FF,$00,$FF,$00		; scanlines with no windowing
	db $FF
	
;;;;;;;;;;;;;;;;
; Level Table
;
; Format Details:
; - Each set of 8 bits represents two levels. The high nybble (leftmost 4 bits)
;   represents the lower (and even) level number, and the low nybble (rightmost
;   4 bits) represents the higher (and odd) level number.
; - Each level is formatted as: %CCCE, where CCC is the palette number 0-7
;   (corresponds to 8-F in the SNES and in LM) to be used for the tiles if
;   Sprite Message Box is enabled for the level, and E actually handles the
;   enabling of Sprite Message Box in the first place -- being 0 for disabled,
;   and 1 for enabled.
;;;;;;;;;;;;;;;;
	
LevelTable:
        db %01110111    ; Levels 000 & 001
        db %01110111    ; Levels 002 & 003
        db %01110111    ; Levels 004 & 005
        db %01110111    ; Levels 006 & 007
        db %01110111    ; Levels 008 & 009
        db %01110111    ; Levels 00A & 00B
        db %01110111    ; Levels 00C & 00D
        db %01110111    ; Levels 00E & 00F
        db %01110111    ; Levels 010 & 011
        db %01110111    ; Levels 012 & 013
        db %01110111    ; Levels 014 & 015
        db %01110111    ; Levels 016 & 017
        db %01110111    ; Levels 018 & 019
        db %01110111    ; Levels 01A & 01B
        db %01110111    ; Levels 01C & 01D
        db %01110111    ; Levels 01E & 01F
        db %01110111    ; Levels 020 & 021
        db %01110111    ; Levels 022 & 023
        db %01110111    ; Levels 024 & 025
        db %01110111    ; Levels 026 & 027
        db %01110111    ; Levels 028 & 029
        db %01110111    ; Levels 02A & 02B
        db %01110111    ; Levels 02C & 02D
        db %01110111    ; Levels 02E & 02F
        db %01110111    ; Levels 030 & 031
        db %01110111    ; Levels 032 & 033
        db %01110111    ; Levels 034 & 035
        db %01110111    ; Levels 036 & 037
        db %01110111    ; Levels 038 & 039
        db %01110111    ; Levels 03A & 03B
        db %01110111    ; Levels 03C & 03D
        db %01110111    ; Levels 03E & 03F
        db %01110111    ; Levels 040 & 041
        db %01110111    ; Levels 042 & 043
        db %01110111    ; Levels 044 & 045
        db %01110111    ; Levels 046 & 047
        db %01110111    ; Levels 048 & 049
        db %01110111    ; Levels 04A & 04B
        db %01110111    ; Levels 04C & 04D
        db %01110111    ; Levels 04E & 04F
        db %01110111    ; Levels 050 & 051
        db %01110111    ; Levels 052 & 053
        db %01110111    ; Levels 054 & 055
        db %01110111    ; Levels 056 & 057
        db %01110111    ; Levels 058 & 059
        db %01110111    ; Levels 05A & 05B
        db %01110111    ; Levels 05C & 05D
        db %01110111    ; Levels 05E & 05F
        db %01110111    ; Levels 060 & 061
        db %01110111    ; Levels 062 & 063
        db %01110111    ; Levels 064 & 065
        db %01110111    ; Levels 066 & 067
        db %01110111    ; Levels 068 & 069
        db %01110111    ; Levels 06A & 06B
        db %01110111    ; Levels 06C & 06D
        db %01110111    ; Levels 06E & 06F
        db %01110111    ; Levels 070 & 071
        db %01110111    ; Levels 072 & 073
        db %01110111    ; Levels 074 & 075
        db %01110111    ; Levels 076 & 077
        db %01110111    ; Levels 078 & 079
        db %01110111    ; Levels 07A & 07B
        db %01110111    ; Levels 07C & 07D
        db %01110111    ; Levels 07E & 07F
        db %01110111    ; Levels 080 & 081
        db %01110111    ; Levels 082 & 083
        db %01110111    ; Levels 084 & 085
        db %01110111    ; Levels 086 & 087
        db %01110111    ; Levels 088 & 089
        db %01110111    ; Levels 08A & 08B
        db %01110111    ; Levels 08C & 08D
        db %01110111    ; Levels 08E & 08F
        db %01110111    ; Levels 090 & 091
        db %01110111    ; Levels 092 & 093
        db %01110111    ; Levels 094 & 095
        db %01110111    ; Levels 096 & 097
        db %01110111    ; Levels 098 & 099
        db %01110111    ; Levels 09A & 09B
        db %01110111    ; Levels 09C & 09D
        db %01110111    ; Levels 09E & 09F
        db %01110111    ; Levels 0A0 & 0A1
        db %01110111    ; Levels 0A2 & 0A3
        db %01110111    ; Levels 0A4 & 0A5
        db %01110111    ; Levels 0A6 & 0A7
        db %01110111    ; Levels 0A8 & 0A9
        db %01110111    ; Levels 0AA & 0AB
        db %01110111    ; Levels 0AC & 0AD
        db %01110111    ; Levels 0AE & 0AF
        db %01110111    ; Levels 0B0 & 0B1
        db %01110111    ; Levels 0B2 & 0B3
        db %01110111    ; Levels 0B4 & 0B5
        db %01110111    ; Levels 0B6 & 0B7
        db %01110111    ; Levels 0B8 & 0B9
        db %01110111    ; Levels 0BA & 0BB
        db %01110111    ; Levels 0BC & 0BD
        db %01110111    ; Levels 0BE & 0BF
        db %01110111    ; Levels 0C0 & 0C1
        db %01110111    ; Levels 0C2 & 0C3
        db %01110111    ; Levels 0C4 & 0C5
        db %01110111    ; Levels 0C6 & 0C7
        db %01110111    ; Levels 0C8 & 0C9
        db %01110111    ; Levels 0CA & 0CB
        db %01110111    ; Levels 0CC & 0CD
        db %01110111    ; Levels 0CE & 0CF
        db %01110111    ; Levels 0D0 & 0D1
        db %01110111    ; Levels 0D2 & 0D3
        db %01110111    ; Levels 0D4 & 0D5
        db %01110111    ; Levels 0D6 & 0D7
        db %01110111    ; Levels 0D8 & 0D9
        db %01110111    ; Levels 0DA & 0DB
        db %01110111    ; Levels 0DC & 0DD
        db %01110111    ; Levels 0DE & 0DF
        db %01110111    ; Levels 0E0 & 0E1
        db %01110111    ; Levels 0E2 & 0E3
        db %01110111    ; Levels 0E4 & 0E5
        db %01110111    ; Levels 0E6 & 0E7
        db %01110111    ; Levels 0E8 & 0E9
        db %01110111    ; Levels 0EA & 0EB
        db %01110111    ; Levels 0EC & 0ED
        db %01110111    ; Levels 0EE & 0EF
        db %01110111    ; Levels 0F0 & 0F1
        db %01110111    ; Levels 0F2 & 0F3
        db %01110111    ; Levels 0F4 & 0F5
        db %01110111    ; Levels 0F6 & 0F7
        db %01110111    ; Levels 0F8 & 0F9
        db %01110111    ; Levels 0FA & 0FB
        db %01110111    ; Levels 0FC & 0FD
        db %01110111    ; Levels 0FE & 0FF
        db %01110111    ; Levels 100 & 101
        db %01110111    ; Levels 102 & 103
        db %01110111    ; Levels 104 & 105
        db %01110111    ; Levels 106 & 107
        db %01110111    ; Levels 108 & 109
        db %01110111    ; Levels 10A & 10B
        db %01110111    ; Levels 10C & 10D
        db %01110111    ; Levels 10E & 10F
        db %01110111    ; Levels 110 & 111
        db %01110111    ; Levels 112 & 113
        db %01110111    ; Levels 114 & 115
        db %01110111    ; Levels 116 & 117
        db %01110111    ; Levels 118 & 119
        db %01110111    ; Levels 11A & 11B
        db %01110111    ; Levels 11C & 11D
        db %01110111    ; Levels 11E & 11F
        db %01110111    ; Levels 120 & 121
        db %01110111    ; Levels 122 & 123
        db %01110111    ; Levels 124 & 125
        db %01110111    ; Levels 126 & 127
        db %01110111    ; Levels 128 & 129
        db %01110111    ; Levels 12A & 12B
        db %01110111    ; Levels 12C & 12D
        db %01110111    ; Levels 12E & 12F
        db %01110111    ; Levels 130 & 131
        db %01110111    ; Levels 132 & 133
        db %01110111    ; Levels 134 & 135
        db %01110111    ; Levels 136 & 137
        db %01110111    ; Levels 138 & 139
        db %01110111    ; Levels 13A & 13B
        db %01110111    ; Levels 13C & 13D
        db %01110111    ; Levels 13E & 13F
        db %01110111    ; Levels 140 & 141
        db %01110111    ; Levels 142 & 143
        db %01110111    ; Levels 144 & 145
        db %01110111    ; Levels 146 & 147
        db %01110111    ; Levels 148 & 149
        db %01110111    ; Levels 14A & 14B
        db %01110111    ; Levels 14C & 14D
        db %01110111    ; Levels 14E & 14F
        db %01110111    ; Levels 150 & 151
        db %01110111    ; Levels 152 & 153
        db %01110111    ; Levels 154 & 155
        db %01110111    ; Levels 156 & 157
        db %01110111    ; Levels 158 & 159
        db %01110111    ; Levels 15A & 15B
        db %01110111    ; Levels 15C & 15D
        db %01110111    ; Levels 15E & 15F
        db %01110111    ; Levels 160 & 161
        db %01110111    ; Levels 162 & 163
        db %01110111    ; Levels 164 & 165
        db %01110111    ; Levels 166 & 167
        db %01110111    ; Levels 168 & 169
        db %01110111    ; Levels 16A & 16B
        db %01110111    ; Levels 16C & 16D
        db %01110111    ; Levels 16E & 16F
        db %01110111    ; Levels 170 & 171
        db %01110111    ; Levels 172 & 173
        db %01110111    ; Levels 174 & 175
        db %01110111    ; Levels 176 & 177
        db %01110111    ; Levels 178 & 179
        db %01110111    ; Levels 17A & 17B
        db %01110111    ; Levels 17C & 17D
        db %01110111    ; Levels 17E & 17F
        db %01110111    ; Levels 180 & 181
        db %01110111    ; Levels 182 & 183
        db %01110111    ; Levels 184 & 185
        db %01110111    ; Levels 186 & 187
        db %01110111    ; Levels 188 & 189
        db %01110111    ; Levels 18A & 18B
        db %01110111    ; Levels 18C & 18D
        db %01110111    ; Levels 18E & 18F
        db %01110111    ; Levels 190 & 191
        db %01110111    ; Levels 192 & 193
        db %01110111    ; Levels 194 & 195
        db %01110111    ; Levels 196 & 197
        db %01110111    ; Levels 198 & 199
        db %01110111    ; Levels 19A & 19B
        db %01110111    ; Levels 19C & 19D
        db %01110111    ; Levels 19E & 19F
        db %01110111    ; Levels 1A0 & 1A1
        db %01110111    ; Levels 1A2 & 1A3
        db %01110111    ; Levels 1A4 & 1A5
        db %01110111    ; Levels 1A6 & 1A7
        db %01110111    ; Levels 1A8 & 1A9
        db %01110111    ; Levels 1AA & 1AB
        db %01110111    ; Levels 1AC & 1AD
        db %01110111    ; Levels 1AE & 1AF
        db %01110111    ; Levels 1B0 & 1B1
        db %01110111    ; Levels 1B2 & 1B3
        db %01110111    ; Levels 1B4 & 1B5
        db %01110111    ; Levels 1B6 & 1B7
        db %01110111    ; Levels 1B8 & 1B9
        db %01110111    ; Levels 1BA & 1BB
        db %01110111    ; Levels 1BC & 1BD
        db %01110111    ; Levels 1BE & 1BF
        db %01110111    ; Levels 1C0 & 1C1
        db %01110111    ; Levels 1C2 & 1C3
        db %01110111    ; Levels 1C4 & 1C5
        db %01110111    ; Levels 1C6 & 1C7
        db %01110111    ; Levels 1C8 & 1C9
        db %01110111    ; Levels 1CA & 1CB
        db %01110111    ; Levels 1CC & 1CD
        db %01110111    ; Levels 1CE & 1CF
        db %01110111    ; Levels 1D0 & 1D1
        db %01110111    ; Levels 1D2 & 1D3
        db %01110111    ; Levels 1D4 & 1D5
        db %01110111    ; Levels 1D6 & 1D7
        db %01110111    ; Levels 1D8 & 1D9
        db %01110111    ; Levels 1DA & 1DB
        db %01110111    ; Levels 1DC & 1DD
        db %01110111    ; Levels 1DE & 1DF
        db %01110111    ; Levels 1E0 & 1E1
        db %01110111    ; Levels 1E2 & 1E3
        db %01110111    ; Levels 1E4 & 1E5
        db %01110111    ; Levels 1E6 & 1E7
        db %01110111    ; Levels 1E8 & 1E9
        db %01110111    ; Levels 1EA & 1EB
        db %01110111    ; Levels 1EC & 1ED
        db %01110111    ; Levels 1EE & 1EF
        db %01110111    ; Levels 1F0 & 1F1
        db %01110111    ; Levels 1F2 & 1F3
        db %01110111    ; Levels 1F4 & 1F5
        db %01110111    ; Levels 1F6 & 1F7
        db %01110111    ; Levels 1F8 & 1F9
        db %01110111    ; Levels 1FA & 1FB
        db %01110111    ; Levels 1FC & 1FD
        db %01110111    ; Levels 1FE & 1FF


	print "Inserted ",freespaceuse," bytes."