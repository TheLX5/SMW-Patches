;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shaped Fade-in
;
; This replaces the "mosaic" fade-in in the original game with a "horizontally
; convex" shape that either zooms in or zooms out from the center of the screen.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!first_only		= !true			; Whether or not to only have windowing when first entering the level.
!frames 		= $20			; The number of frames in the fade-in.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!false			= 0			; Don't change these.
!true			= 1

org $009F37
		autoclean JML main
		
org $009F66
		RTS
		
org $00A0A3
		LDA #!frames
		
org $00C9EB
		LDX #!frames
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

freecode
reset bytes

direction:
		db $FF,$01
		
end:
		db $FF,!frames+1
		
inv_scales:
		dw $0080,$0084,$0089,$008D,$0092,$0098,$009E,$00A4
		dw $00AB,$00B2,$00BA,$00C3,$00CD,$00D8,$00E4,$00F1
		dw $0100,$0111,$0125,$013B,$0155,$0174,$019A,$01C7
		dw $0200,$0249,$02AB,$0333,$0400,$0555,$0800,$1000
		
scales:
		dw $0200,$01F0,$01E0,$01D0,$01C0,$01B0,$01A0,$0190
		dw $0180,$0170,$0160,$0150,$0140,$0130,$0120,$0110
		dw $0100,$00F0,$00E0,$00D0,$00C0,$00B0,$00A0,$0090
		dw $0080,$0070,$0060,$0050,$0040,$0030,$0020,$0010
		
windowing:
		db $71,$7B,$6B,$80,$68,$84,$65,$87,$62,$8A,$60,$8C,$5F,$8E,$5D,$90
		db $5C,$92,$5A,$94,$59,$96,$58,$97,$57,$98,$55,$9A,$54,$9B,$53,$9D
		db $52,$9E,$51,$9F,$50,$A0,$50,$A1,$4F,$A2,$4E,$A3,$4D,$A4,$4D,$A5
		db $4C,$A6,$4B,$A7,$4B,$A8,$4A,$A9,$4A,$AA,$49,$AB,$49,$AC,$48,$AD
		db $48,$AD,$48,$AE,$47,$AF,$47,$B0,$47,$B0,$46,$B1,$46,$B2,$46,$B3
		db $3A,$B3,$34,$B4,$31,$B5,$2E,$B5,$2C,$B6,$2A,$B7,$29,$B7,$28,$B8
		db $27,$B9,$26,$B9,$25,$BA,$25,$BB,$24,$BB,$24,$BC,$23,$BC,$23,$BD
		db $23,$BD,$23,$BE,$23,$BF,$23,$BF,$23,$C0,$23,$C0,$23,$C1,$23,$C1
		db $23,$C2,$23,$C2,$24,$C3,$24,$C3,$24,$C3,$25,$C4,$25,$C4,$26,$C5
		db $26,$C5,$27,$C5,$27,$C6,$28,$C6,$28,$C6,$29,$C7,$2A,$C7,$2A,$C7
		db $2B,$C7,$2C,$C8,$2D,$C8,$2D,$C8,$2E,$C8,$2F,$C9,$30,$C9,$31,$C9
		db $31,$C9,$32,$CA,$33,$CA,$34,$CA,$35,$CA,$36,$CA,$37,$CA,$38,$CA
		db $39,$CA,$3A,$CB,$3B,$CB,$3C,$CB,$3D,$CB,$3D,$CB,$3C,$CF,$3C,$D2
		db $3C,$D4,$3B,$D6,$3B,$D7,$3B,$D9,$3A,$DA,$3A,$DB,$31,$DC,$2E,$DD
		db $2C,$DE,$2A,$DF,$29,$DF,$27,$E0,$26,$E0,$25,$E1,$24,$E1,$23,$E2
		db $22,$E2,$22,$E2,$21,$E3,$20,$E3,$20,$E3,$20,$E3,$1F,$E3,$1F,$E3
		db $1E,$E3,$1E,$E3,$1E,$E3,$1D,$E3,$1D,$E3,$1D,$E3,$1D,$E3,$1D,$E3
		db $1D,$E3,$1D,$E3,$1D,$E2,$1D,$E2,$1D,$E2,$1D,$E1,$1D,$E1,$1D,$E0
		db $1D,$E0,$1D,$DF,$1E,$DE,$1E,$DE,$1F,$DD,$1F,$DC,$20,$DB,$20,$DA
		db $20,$D9,$20,$D7,$20,$D6,$20,$D4,$20,$D2,$20,$D1,$20,$D1,$20,$D1
		db $21,$D1,$21,$D1,$21,$D1,$22,$D1,$22,$D1,$23,$D1,$24,$D1,$27,$D1
		db $27,$D0,$27,$D0,$28,$D0,$28,$CF,$29,$CF,$2A,$CE,$2B,$CE,$2C,$CD
		db $2C,$CD,$2D,$CC,$2D,$CC,$2D,$CB,$2E,$CB,$2E,$CA,$2F,$C9,$2F,$C8
		db $30,$C7,$30,$C6,$31,$C6,$32,$C5,$32,$C3,$33,$C2,$34,$C1,$35,$BF
		db $36,$BE,$37,$BC,$38,$BA,$3A,$B7,$3B,$B1,$3D,$9E,$3F,$9D,$41,$9C
		db $43,$9B,$46,$9A,$48,$99,$48,$97,$49,$96,$49,$94,$4A,$92,$4A,$90
		db $4B,$8E,$4B,$8B,$4C,$85,$4D,$83,$4E,$82,$4F,$81,$50,$80,$51,$7F
		db $52,$7E,$53,$7D,$55,$7B,$57,$79,$59,$77,$5B,$74,$5F,$71,$65,$6B
		
main:		LDY $0DAF			; Get the fade direction.
if !first_only
		LDA $141A			; If not entering a sublevel or
		ORA $1B9B			; in a castle animation,
		BEQ .window			; do the windowing fade.
		JML $009F4C			; Otherwise, do the brightness fade.
endif	
	.window	PHB
		PHK
		PLB
		LDA #$0F			; Force highest brightness.
		STA $0DAE
		
		LDA $0DB0
		TAX
		CLC
		ADC direction,y			; Get the next value for the fade timer.
		CMP end,y			; If it's not an ending value, continue.
		BNE .no_end
		
		REP #$30
		LDA #$00FF
		LDY #$0000
	-	STA $04A0,y			; Clear the windowing table.
		INY
		INY
		CPY #$01C0
		BNE -
		SEP #$30
		
		LDA #$80			; Disable HDMA on channel 7.
		TRB $0D9F
		PLB
		JML $009F5B
		
	.no_end	STA $0DB0			; Set the fade timer.
		TXA
		ASL
		TAX
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
		LDA inv_scales,x
		STA $00				; Get the inverse windowing scale.
		LDA scales,x
		STA $02				; Get the windowing scale.
		LSR
		SEC
		SBC #$0080			; Divide by 2 and subtract #$0080 for the windowing X offset.
		STA $06
		
		CPY #$00			; If it's fading out,
		BNE +
		CPX #$02			; and it's the last frame,
		BNE +
		STZ $41				; pre-emptively disable windowing. This will take effect on the next frame.
		LDA #$0200
		BRA ++
	+	LDA #$0333			; Otherwise, enable windowing.
		STA $41
		LDA #$1223
	++	STA $43
		
		REP #$10
		LDY #$0000			; On each scanline,
	.loop	TYA
		LSR
		SEP #$21
		SBC #$6F			; find the distance from the middle,
		STA $211C
		LDA $00
		STA $211B
		LDA $01
		STA $211B			; and multiply that distance by the inverse scale.
		REP #$21
		LDA $2135
		ADC #$0070
		CMP #$00E0			; If this product isn't within the screen boundary,
		BCS .clear			; go onto the next scanline.
		ASL
		TAX
		
		SEP #$20
		LDA $02
		STA $211B
		LDA $03
		STA $211B
		LDA windowing,x
		STA $211C			; Multiply the left boundary of the window by the windowing scale.
		REP #$21
		LDA $2135			; Because mode 7 multiplication is signed, we must check
		BPL +				; for negative values and fix them.
		ADC $02
	+	SEC
		SBC $06
		CMP #$0100
		BPL .clear			; If the left bound is beyond the right part of the screen, clear the scanline.
		SEP #$20
		BCC +
		LDA #$00
	+	STA $04A0,y			; Set the left bound for the scanline.
		
		LDA windowing+1,x		; Multiply the right boundary of the window by the
		STA $211C			; windowing scale.
		REP #$21
		LDA $2135
		BPL +
		ADC $02
	+	SEC
		SBC $06
		BMI .clear			; If the right bound is beyond the left part of the screen, clear the scanline.
		CMP #$0100
		SEP #$20
		BCC +				; Clamp values > $FF to $FF, or $FE is ZSNES is being used.
		LDA $0F
	+	STA $04A1,y			; Set the right bound for the scanline.
		REP #$20
		BRA .next
		
	.clear	LDA #$00FF			; Clear the scanline.
		STA $04A0,y
	.next	INY
		INY
		CPY #$01C0
		BNE .loop
	+	SEP #$30
		
		LDA #$80			; Enable HDMA on channel 7.
		TSB $0D9F
		PLB
		JML $009F6E
		
print "Bytes inserted: ", bytes