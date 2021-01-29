@includefrom retry.asm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; global settings                       ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!lose_lives = $00               ; $00 = not lose your lives when you die
                                ; $01 = lose your lives (vanilla)

!initial_lives = 99             ; in decimal

!midway_powerup = $00           ; $00 = small
                                ; $01 = big (vanilla)

!counterbreak_yoshi = $01       ; $00 = no (vanilla), $01 = yes (resets your yoshi status when you die or enter a level)
                                ; set this to $01 if you have a problem of yoshi not respawned in a level with no yoshi intro
                                ; (corresponding to !clear_parked_yoshi in version 2.04 or below)

!counterbreak_powerup = $01     ; $00 = no (vanilla), $01 = yes (resets your powerup status when you die or enter a level)
                                ; (corresponding to !clear_itembox in version 2.04 or below)

!counterbreak_coin = $01        ; $00 = no (vanilla), $01 = yes (resets coins when you die or enter a level)

!default_prompt_type = $01      ; $00 = play the death jingle when players die
                                ; $01 = play only the sfx when players die (music won't be interrupted)
                                ; $02 = play only the sfx & skip the prompt (the fastest option; "yes" is chosen automatically)
                                ;       in this option, you can press start then select to exit the level
                                ; $03 = no retry prompt (as if "no" is chosen automatically, use this if you only want the multi-midway feature)

!sprite_initial_face_fix = $01  ; $00 = fix only when resetting a level
                                ; $01 = always fix (RECOMMENDED)

!reset_rng = $01                ; $00 = do not reset the random number generator when resetting a level
                                ; $01 = reset the random number generator when resetting a level


!midway_sram = $01              ; $00 = no, $01 = yes (install the code that saves the midway states to SRAM)
                                ; this feature does not support SA-1 ROMs, for which this option will be ignored. (you will need BWRAM Plus instead.)
                                ; if you are already using SRAM Plus, this option will be ignored.
                                ; * whenever you change this option and apply the patch, erase the previous srm file from your hard drive.

!use_custom_midway_bar = $01    ; $00 = no, $01 = yes
                                ; if you are already using objectool, set this to $00

!max_custom_midway_num = $08    ; the number of custom midway bars (custom object) allowed in one sublevel
                                ; the bigger, the more free ram address is required


;;; free RAM addresses
!freeram = $7FB400              ; 12 bytes
!freeram_checkpoint = $7FB40C   ; 192 bytes
!freeram_custobjdata = $7FB4CC  ; (!max_custom_midway_num*4)+1 bytes (33 bytes for $08)

; *** in case you're using SA-1 *** (if not, you may skip this)
!freeram_SA1 = $40B400              ; 12 bytes
!freeram_checkpoint_SA1 = $40B40C   ; 192 bytes
!freeram_custobjdata_SA1 = $40B4CC  ; (!max_custom_midway_num*4)+1 bytes (33 bytes for $08)


;;; the below is sfx which may be used instead of the death jingle
;;; for the list of vanilla sfx, check https://www.smwcentral.net/?p=viewthread&t=6665
;;; or use addmusick to insert the custom sfx
!death_sfx = $20                ; $01-$FF: sfx number
!death_sfx_bank = $1DF9         ; $1DF9 or $1DFC

;;; the alternative death jingle which will be played after the death_sfx when "no" is chosen.
;;; (only available when you're using addmusick)
!death_jingle_alt = $FF         ; $01-$FE: custom song number, $FF = do not use this feature

!addmusick_ram_addr = $7FB000   ; don't need to change this in most case

;;; Palettes used by the retry prompt tiles.
;;; Note that they use sprite tiles, so they must use palettes $08-$0F.
;;; Color 2 in the palette should be black, since it's used as the background color for the tiles.
!prompt_letters_palette = $08
!prompt_cursor_palette  = $08

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; local settings (for each translevel)  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; decides the prompt type
;;; $00 = follow the global setting (!default_prompt_type)
;;; $01 = play the death jingle when players die
;;; $02 = play only the sfx when players die (music won't be interrupted)
;;; $03 = play only the sfx & skip the prompt (the fastest option; "yes" is chosen automatically)
;;;       in this option, you can press start then select to exit the level
;;; $04 = no retry (as if "no" is chosen automatically)

.effect
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Levels 000~00F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Levels 010~01F
db $00,$00,$00,$00,$00                                              ;Levels 020~024
db     $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Levels 101~10F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Levels 110~11F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Levels 120~12F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00                  ;Levels 130~13B


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    Multiple Midway Settings     ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; The following table sets the behavior of a midway bar and level entrances(main/secondary/midway) "in each sublevel".
;;; See the figures in the "midway instruction" folder.
;;; $00 = Vanilla. The midway bar in the corresponding sublevel will lead to the midway entrance of the main level.
;;; $01 = The Midway bar in the corresponding sublevel will lead to the midway entrance of this sublevel as a checkpoint.
;;; $02 = Any main/secondary/midway entrance through door/pipe/etc. whose destination is the corresponding sublevel will trigger a checkpoint like midway bars,
;;;       and the checkpoint will lead to this entrance.
;;; $03 = This option enables both the effects of $01(midway bar) and $02(level entrances).
;;;
;;; Correspondence Table: (if you were using ver 2.04, you can ignore this table)
;;;  --------------------------------------------------------------- 
;;; |     (ver 2.04 or above)    <----->    (ver 2.03 or below)     |
;;; |---------------------------------------------------------------|
;;; |         $00 (vanilla)         |            $00 or $01         |
;;; |  $01 (midbar for each sublv)  |                x              |
;;; |   $02 (sublevel entrances)    |               $02             |
;;; |         $03 ($01+$02)         |                x              |
;;;  --------------------------------------------------------------- 

;;; NOTE: The new custom midway objects could do almost everything that you may want without using this.
;;;       However I will leave this for backward compatibility.

.checkpoint
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 000-00F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 010-01F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 020-02F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 030-03F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 040-04F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 050-05F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 060-06F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 070-07F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 080-08F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 090-09F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0A0-0AF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0B0-0BF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0C0-0CF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0D0-0DF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0E0-0EF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 0F0-0FF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 100-10F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 110-11F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 120-12F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 130-13F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 140-14F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 150-15F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 160-16F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 170-17F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 180-18F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 190-19F
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1A0-1AF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1B0-1BF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1C0-1CF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1D0-1DF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1E0-1EF
db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;Sublevels 1F0-1FF
