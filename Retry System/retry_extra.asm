includefrom "retry.asm"

; This routine will be called when the level is reset by the retry system, or entered from the overworld.
; Unlike init routines in uberasm, it's not executed during regular level transitions.

ResetExtra:
    ; feel free to put your code here (e.g. custom ram initialization)

    ; example(currently commented out): set the coin counter to 5
    ;LDA #$05
    ;STA $0DBF	; should be $6DBF, or $0DBF|!addr in case your rom is SA-1


    RTS	; this routine should be ended with RTS




; This routine will be called whenever you die.

DeathRoutine:
    ; feel free to put your code here (e.g. increase death counter)

if !_custom_powerups == 1
    stz.w ($170B|!addr)+$08
    stz.w ($170B|!addr)+$09
    lda #$00
    sta !projectile_do_dma


    ldx #$07
-	
    lda $170B|!addr,x
    cmp #$12
    bne +
    stz $170B|!addr,x
+	
    dex
    bpl -
    
    lda !item_box_disable
    ora #$02
    sta !item_box_disable
endif

    RTS	; this routine should be ended with RTS
