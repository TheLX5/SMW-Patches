;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Circular Fade-in
;
; This replaces the "mosaic" fade-in in the original game with a circle
; that either zooms into or zooms out from Mario.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!first_only		= !true			; Whether or not to only have windowing when first entering the level.
!frames 		= $1E			; The number of frames in the fade-in.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!false			= 0			; Don't change these.
!true			= 1

!sa1	= 0			; 0 if LoROM, 1 if SA-1 ROM.
!dp	= $0000			; $0000 if LoROM, $3000 if SA-1 ROM.
!addr	= $0000			; $0000 if LoROM, $6000 if SA-1 ROM.
!bank	= $800000		; $80:0000 if LoROM, $00:0000 if SA-1 ROM.
!bank8	= $80			; $80 if LoROM, $00 if SA-1 ROM.

!sprite_slots = 12		; 12 if LoROM, 22 if SA-1 ROM.

if read1($00ffd5) == $23
	!sa1	= 1
	!dp	= $3000
	!addr	= $6000
	!bank	= $000000
	!bank8	= $00
	
	!sprite_slots = 22
	
	sa1rom
endif

org $009F37
		autoclean JML main
		
org $009F66
		RTS
		
org $00C9EB
		LDX #!frames

org $00A0A3
		LDA #!frames
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

freecode
reset bytes

direction:
		db $FF,$01

end:
		db $FF,!frames+1
		
radii:
		db $F0,$E8,$E0,$D8,$D0,$C8,$C0,$B8
		db $B0,$A8,$A0,$98,$90,$88,$80,$78
		db $70,$68,$60,$58,$50,$48,$40,$38
		db $30,$28,$20,$18,$10,$08
		
sqrt_lookup:
		dw $0100,$0100,$016A,$01BB,$0200,$023C,$0273,$02A5
		dw $02D4,$0300,$032A,$0351,$0377,$039B,$03BE,$03DF
		dw $0400,$0420,$043E,$045C,$0479,$0495,$04B1,$04CC
		dw $04E6,$0500,$0519,$0532,$054B,$0563,$057A,$0591
		dw $05A8,$05BF,$05D5,$05EB,$0600,$0615,$062A,$063F
		dw $0653,$0667,$067B,$068F,$06A2,$06B5,$06C8,$06DB
		dw $06EE,$0700,$0712,$0724,$0736,$0748,$0759,$076B
		dw $077C,$078D,$079E,$07AE,$07BF,$07CF,$07E0,$07F0
		dw $0800,$0810,$0820,$082F,$083F,$084E,$085E,$086D
		dw $087C,$088B,$089A,$08A9,$08B8,$08C6,$08D5,$08E3
		dw $08F2,$0900,$090E,$091C,$092A,$0938,$0946,$0954
		dw $0961,$096F,$097D,$098A,$0997,$09A5,$09B2,$09BF
		dw $09CC,$09D9,$09E6,$09F3,$0A00,$0A0D,$0A19,$0A26
		dw $0A33,$0A3F,$0A4C,$0A58,$0A64,$0A71,$0A7D,$0A89
		dw $0A95,$0AA1,$0AAD,$0AB9,$0AC5,$0AD1,$0ADD,$0AE9
		dw $0AF4,$0B00,$0B0C,$0B17,$0B23,$0B2E,$0B3A,$0B45
		dw $0B50,$0B5C,$0B67,$0B72,$0B7D,$0B88,$0B93,$0B9E
		dw $0BA9,$0BB4,$0BBF,$0BCA,$0BD5,$0BE0,$0BEB,$0BF5
		dw $0C00,$0C0B,$0C15,$0C20,$0C2A,$0C35,$0C3F,$0C4A
		dw $0C54,$0C5F,$0C69,$0C73,$0C7D,$0C88,$0C92,$0C9C
		dw $0CA6,$0CB0,$0CBA,$0CC4,$0CCE,$0CD8,$0CE2,$0CEC
		dw $0CF6,$0D00,$0D0A,$0D14,$0D1D,$0D27,$0D31,$0D3B
		dw $0D44,$0D4E,$0D57,$0D61,$0D6B,$0D74,$0D7E,$0D87
		dw $0D91,$0D9A,$0DA3,$0DAD,$0DB6,$0DBF,$0DC9,$0DD2
		dw $0DDB,$0DE4,$0DEE,$0DF7,$0E00,$0E09,$0E12,$0E1B
		dw $0E24,$0E2D,$0E36,$0E3F,$0E48,$0E51,$0E5A,$0E63
		dw $0E6C,$0E75,$0E7E,$0E87,$0E8F,$0E98,$0EA1,$0EAA
		dw $0EB2,$0EBB,$0EC4,$0ECC,$0ED5,$0EDE,$0EE6,$0EEF
		dw $0EF7,$0F00,$0F09,$0F11,$0F1A,$0F22,$0F2A,$0F33
		dw $0F3B,$0F44,$0F4C,$0F54,$0F5D,$0F65,$0F6D,$0F76
		dw $0F7E,$0F86,$0F8E,$0F97,$0F9F,$0FA7,$0FAF,$0FB7
		dw $0FBF,$0FC8,$0FD0,$0FD8,$0FE0,$0FE8,$0FF0,$0FF8
		
main:		LDY $0DAF|!addr			; Get the fade direction.
if !first_only
		LDA $141A|!addr			; If not entering a sublevel or
		ORA $1B9B|!addr			; in a castle animation, do the circle fade.
		BEQ .window
		JML $009F4C			; Otherwise, do the brightness fade.
endif	
	.window
	if !sa1 == 0
		JSL .window_code
	else	
		LDA.b #.window_code
		STA $3180
		LDA.b #.window_code>>8
		STA $3181
		LDA.b #.window_code>>16
		STA $3182
		JSR $1E80
	endif	
		LDA $0D9F|!addr
		BPL +
		JML $009F6E
	+	
		JML $009F5B

	.window_code
		PHB
		PHK
		PLB
		
		LDA #$0F			; Force highest brightness.
		STA $0DAE|!addr
		
		LDY $0DAF|!addr
		LDA $0DB0|!addr
		TAX
		CLC
		ADC direction,y			; Get the next value for the fade timer.
		CMP end,y			; If it's not an ending value, continue.
		BNE .no_end
		
		REP #$30
		LDA #$00FF
		LDY #$0000
	-	STA $04A0|!addr,y		; Clear the windowing table.
		INY
		INY
		CPY #$01C0
		BNE -
		SEP #$30
		
		LDA #$80			; Disable HDMA on channel 7.
		TRB $0D9F|!addr
		PLB
		RTL
		
	.no_end
		STA $0DB0|!addr			; Set the fade timer.
		STZ $0F
		DEC $0F
		SED
		LDA #$FF
		CLC
		ADC #$FF
		CLD
		CMP #$64
		BNE +
		DEC $0F				; Detect ZSNES because of a stupid bug with it.
	+	REP #$20
		CPY #$00			; If it's fading out,
		BNE +
		CPX #$01			; and it's the last frame,
		BNE +
		STZ $41				; pre-emptively disable windowing. This will take effect
		LDA #$0200			; on the next frame.
		BRA ++
	+	LDA #$0333			; Otherwise, enable windowing.
		STA $41
		LDA #$1223
	++	STA $43
		SEP #$20
		
	if !sa1 == 0
		LDA radii,x
		STA $04
		STA $4202
		STA $4203			; Compute radius^2.
	else
		STZ $2250
		LDA radii,x
		STA $04
		STA $2251
		STA $2253			; Compute radius^2.
		STY $2252
		STY $2254
	endif
		
		LDA $0D9B|!addr
		CMP #$02
		REP #$20
		SEC
		BNE .level			; If in-level, use $94 and $96.
		LDY $0DD6|!addr			; Otherwise, use $1F17 and $1F19.
		LDA $1F17|!addr,y
		SBC $1A
		STA $00
		LDA $1F19|!addr,y
		SEC
		SBC #$0004
		BRA +
	.level	LDA $94
		SBC $1A
		CLC
		ADC #$0008
		STA $00
		LDA $96
		CLC
		ADC #$0010
	+	SEC
		SBC $1C
		STA $02
	
	if !sa1 == 0
		LDA $4216
	else
		LDA $2306
	endif
		STA $05				; Get radius^2.
		
		REP #$10
		LDY #$0000
	.loop	TYA
		LSR
		SEC
		SBC $02
		BPL .pos			; Force the Y difference to be positive.
		EOR #$FFFF
		INC
	.pos	SEP #$20
	
		CMP $04
		BCC +				; If it's > radius, clear the scanline.
		REP #$20
		JMP .clr
		
	+
	if !sa1 == 0
		STA $4202
		STA $4203
		REP #$20
		LDA $05
		SEC
		SBC $4216			; Compute sqrt(radius^2 - dy^2).
	else
		STA $2251
		STA $2253
		STZ $2250
		STZ $2252
		STZ $2254
		
		REP #$20
		LDA $05
		SEC
		SBC $2306			; Compute sqrt(radius^2 - dy^2).
	endif
		CMP #$4000
		BCS .4000
		CMP #$1000
		BCS .1000
		CMP #$0400
		BCS .0400
		CMP #$0100
		BCS .0100
		BRA .0000
		
	.4000	XBA
		AND #$00FE
		ASL
		TAX
		LDA sqrt_lookup,x
		ASL
		ASL
		ASL
		ASL
		BRA .done
	
	.1000	XBA
		ROL
		ROL
		AND #$00FE
		ASL
		TAX
		LDA sqrt_lookup,x
		ASL
		ASL
		ASL
		BRA .done
	
	.0400	LSR
		LSR
		LSR
		AND #$FFFE
		TAX
		LDA sqrt_lookup,x
		ASL
		ASL
		BRA .done
	
	.0100	LSR
		AND #$FFFE
		TAX
		LDA sqrt_lookup,x
		ASL
		BRA .done
	
	.0000	ASL
		TAX
		LDA sqrt_lookup,x
	.done	XBA
		AND #$00FF
		STA $07
		CLC
		ADC $00
		BMI .clr			; If the right bound is beyond the left side of the screen, stop.
		CMP #$0100
		SEP #$20
		BCC +				; Clamp values > $FF to $FF, or $FE is ZSNES is being used.
		LDA $0F
	+	STA $04A1|!addr,y		; Set the right bound for the scanline.
		
		REP #$20
		LDA $00
		SEC
		SBC $07
		CMP #$0100
		BPL .clr			; If the left bound is beyond the right side of the screen, clear the scanline.
		SEP #$20
		BCC +				; Clamp values < $00 to $00.
		LDA #$00
	+	STA $04A0|!addr,y		; Set the left bound for the scanline.
		
		REP #$20
	.next	INY
		INY
		CPY #$01C0
		BEQ +				; Go to the next scanline.
		JMP .loop
		
	.clr	LDA #$00FF
		STA $04A0|!addr,y
		BRA .next
	+	SEP #$30
		
		LDA #$80			; Enable HDMA on channel 7.
		TSB $0D9F|!addr
		PLB
		RTL

		
print "Bytes inserted: ", bytes