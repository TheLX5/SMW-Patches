;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Solid Sprites
;;   by leod
;;   huge thanks to Vitor Vilela for the SA-1 hybrid version!
;;
;; Makes sprites take into account a separate "blocked" byte when checking for wall contact.
;; Then makes all the vanilla SMW platform-type sprites check for sprite contact
;; and set that byte accordingly.
;; In short, sprites won't drop through platforms any more.
;;
;; Should work just fine with any kind of custom sprite, assuming it uses default level
;; and sprite clipping values (most do, bosses might be an exception).
;;
;; Performance takes a huge hit with multiple platform-type sprites on screen at once,
;; so I would really heavily recommend you either don't do that or SA-1 it up.
;; You can find the SA-1 Pack under the following link in SMWC's Patches section:
;; http://www.smwcentral.net/?p=section&a=details&id=12757
;;
;;
;; If you want to change which vanilla sprites interact/fall through platforms,
;; CTRL-F "Object Interaction" and read the info there. Shouldn't really be necessary though.
;;
;; If you're making a custom platform sprite that needs to know how many sprites are on it,
;; $0E contains that number after calling this.
;; Fill the sprite's clipping into slot A before calling the unorthodox version (see asar output)
;; and use the "Make platform passable from below" tweaker bit to make the sprite (non-)solid
;; from the sides.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

incsrc "../../../defs.asm"

; = Defines = ;
!VisualFix = $01
;Whether sprites' hitboxes are adjusted to make them not sink into platforms.
;$01 means yes, $00 means no
;In practice, this expands all hitboxes by a few pixels and makes Mario those few pixels shorter,
;meaning you shouldn't notice any difference in interactions. If you do have issues, turn this off.

!ShellLessFix = $01
;Whether the bug should be fixed, where shell-less Koopas fall down even while $9D is set,
;such as when collecting a power-up or getting hurt.
;$01 means yes, $00 means no
;This is an option because I know some puzzle/kaizo hacks make use of this bug,
;if you aren't making direct use of it, definitely leave this at $01.
;Not fixing it means that Koopas will fall right through sprite platforms during
;hurt/powerup animations.


!SolidP = $01
;Whether P-Switches are solid to sprites (only while not carried)
;$01 means yes, $00 means no

!SolidKey = $01
;Whether Keys are solid to sprites (only while not carried)
;$01 means yes, $00 means no

!SolidInMovement = $00
;Setting this to $00 makes it so P-Switches and Keys are not solid while moving around,
;which makes it easy for them to act like complete shields and knock unusual sprites around

;Turning this off actually acts a lot more intuitive than you might think reading it


!SpriteSpring = $01
;Whether all sprites can bounce off of Springboards
;$01 means yes, $00 means no
;Make sure that this doesn't break anything in your hack, having chucks bouncing all over
;the place where they shouldn't isn't as fun as it sounds

!Bounce = $A8
;how high do sprites get bounced by springboards?
;the lower (closer to 80) the higher it bounced, and vice versa


!SpritePeas = $01
;Whether all sprites can bounce off of wall springboards (the ones made of little green peas)
;$01 means yes, $00 means no
;Careful with placing these, some sprites react very weird to these, like the lava lotus

;If you want to adjust the Peas' bounce speeds, CTRL-F for "PeaSpeeds:" and edit the table below



; = FreeRAM addresses = ;

!SpriteBlockTable	= $7FB300
!SpriteBlockTable_SA1	= $4063A2
;needs 0x27 bytes (0x45 for SA-1) of freeram, default is free in vanilla
;custom sprite table, stores to sprites which sides a sprite platform is blocking them from
;same format as $1588:
;       ????udlr
;       u = up
;       d = down
;       l = left
;       r = right
;       ? = unused

!LastXPosition = !SpriteBlockTable+!SpriteTableSize
;last x position the sprite had, used for $1491

!LastSprite = !LastXPosition+!SpriteTableSize
;contains the ID of one sprite on TOP of the platform, mainly used by the spring since it's not selective

!Sides = !LastSprite+$01
;which sides the sprite is touched from, in case you want to make a platform fall by sprites
;format: ????udlr

!SidesKicked = !Sides+$01
;which sides the sprite is touched from BY A KICKED SPRITE
;used by the message box fix
;format: ????udlr

!OffscreenCopy = !SidesKicked+1
; Keeps a copy of the off-screen status (bit 2) to be restored
; later. Also the last bit holds if a value was saved or not there.

!OffsetFlag = !OffscreenCopy+!SpriteTableSize
; 

!SpriteTableSize = 12

;;;;;
; Addresses ranges
;;;;;

!bank	 = $800000
!addr	 = $0000
!dp	 = $0000

;;;;;
; Sprite tables
;;;;;

!9E	 = $9E
!AA	 = $AA
!B6	 = $B6
!C2	 = $C2
!D8	 = $D8
!E4	 = $E4
!14C8	 = $14C8
!14D4	 = $14D4
!14E0	 = $14E0
!14EC	 = $14EC
!14F8	 = $14F8
!1504	 = $1504
!1510	 = $1510
!151C	 = $151C
!1528	 = $1528
!1534	 = $1534
!1540	 = $1540
!154C	 = $154C
!1558	 = $1558
!1564	 = $1564
!1570	 = $1570
!157C	 = $157C
!1588	 = $1588
!1594	 = $1594
!15A0	 = $15A0
!15AC	 = $15AC
!15B8	 = $15B8
!15C4	 = $15C4
!15D0	 = $15D0
!15DC	 = $15DC
!15EA	 = $15EA
!15F6	 = $15F6
!1602	 = $1602
!160E	 = $160E
!161A	 = $161A
!1626	 = $1626
!1632	 = $1632
!163E	 = $163E
!164A	 = $164A
!1656	 = $1656
!1662	 = $1662
!166E	 = $166E
!167A	 = $167A
!1686	 = $1686
!186C	 = $186C
!187B	 = $187B
!190F	 = $190F
!1FD6	 = $1FD6
!1FE2	 = $1FE2

;;;;;
; SA-1 detection and support
;;;;;

if read1($00FFD5) == $23
	sa1rom
	
	!bank	 = $000000
	!addr	 = $6000
	!dp	 = $3000
	
	!AA	= $9E
	!B6	= $B6
	!C2	= $D8
	!9E	= $3200
	!D8	= $3216
	!E4	= $322C
	!14C8	= $3242
	!14D4	= $3258
	!14E0	= $326E
	!151C	= $3284
	!1528	= $329A
	!1534	= $32B0
	!1540	= $32C6
	!154C	= $32DC
	!1558	= $32F2
	!1564	= $3308
	!1570	= $331E
	!157C	= $3334
	!1588	= $334A
	!1594	= $3360
	!15A0	= $3376
	!15AC	= $338C
	!15EA	= $33A2
	!15F6	= $33B8
	!1602	= $33CE
	!160E	= $33E4
	!163E	= $33FA
	!187B	= $3410
	!14EC	= $74C8
	!14F8	= $74DE
	!1504	= $74F4
	!1510	= $750A
	!15B8	= $7520
	!15C4	= $7536
	!15D0	= $754C
	!15DC	= $7562
	!161A	= $7578
	!1626	= $758E
	!1632	= $75A4
	!190F	= $7658
	!1FD6	= $766E
	!1FE2	= $7FD6
	!164A	= $75BA
	!1656	= $75D0
	!1662	= $75EA
	!166E	= $7600
	!167A	= $7616
	!1686	= $762C
	!186C	= $7642
	
	!SpriteTableSize = 22
	!SpriteBlockTable = !SpriteBlockTable_SA1
endif

;# Vanilla interaction defines
    !slot_b_x_lo		= $00
    !slot_b_x_hi		= $08
    !slot_b_y_lo		= $01
    !slot_b_y_hi		= $09
    !slot_b_height		= $03
    !slot_b_width		= $02
    !slot_a_x_lo		= $04
    !slot_a_x_hi		= $0A
    !slot_a_y_lo		= $05
    !slot_a_y_hi		= $0B
    !slot_a_height		= $07
    !slot_a_width		= $06


;;;;;
; clear our sprite table when a new sprite is spawned along with the vanilla ones
;;;;;

org $07F728
JSL ClearTable
NOP

;;;;;
; initiate !LastXPosition on sprite load, so it doesn't warp sprites around that spawn on it
;;;;;

org $07F79A
JSL InitXPos

;;;;;
; make platforms jump to our routine to check for sprites and set the new solid byte
; (and adjust their y position)
; this edits the routine at $01B44F aka InvisBlkMainRt
;;;;;

org $01B457
JSL PlatformHijack
NOP


;;;;;
; make sprites take our new table into consideration
; this edits the routine at $019138
;;;;;

org $0191BE
autoclean JSL AddTable
NOP


;;;;;
; turn block bridge fix
; use their own clipping values, so we gotta call our routine ourselves
;;;;;

org $01B8A7     ;free up some free space for the other hijack
JSL TurnBlkFree


org $01B8AB
TurnFix:
JSL TurnBlockFix
RTS

;repoint old branches to fix instead of just RTS
org $01B855
BNE TurnFix

org $01B85B
BCS TurnFix

org $01B860
BCC TurnFix

org $01B879
BMI TurnFix

;;;;;
; skull raft fix
;;;;;

org $02EE9E         ;reuse turnblk routine, it's the same fix for the same routine
JSL TurnBlkFree

org $02EEA2
RaftFix:

if !VisualFix == $01

  JSL RaftAdjust

endif
if !VisualFix == $00

  JSL BeSolidToSpritesSpecialClip

endif

RTS

;repoint old branches to fix instead of just RTS
org $02EE5B
BCC RaftFix

org $02EE5F
BMI RaftFix

org $02EE94
BNE RaftFix

;;;;;
; mega mole fix
;;;;;

org $038813
JSL TurnBlkFree

org $038817
MoleFix:
JSL megamole_fix
RTS

;repoint old branches to fix instead of just RTS
org $0387DB
BCC MoleFix

org $0387E8
BMI MoleFix

;properly set $1491
org $038793
JSL Mole1491


;;;;;;
; flying ? block fix
; didn't carry sprites
; also adds activation when being hit by a sprite
;;;;;;

org $01B2B6
JSL FlyingSet1491
NOP #2

org $01B4A6
CLC
ADC $94
STA $94
TYA
ADC $95

org $01B49C
BNE $12


;kicked sprite activation
org $01AE01
JSL FlyingBlockFix
NOP

;disable old shell detection
org $01ADF8
NOP #3
org $01ADF8
BRA .SkipJunk
org $01ADFB
  .SkipJunk

;;;;;
; grey rotating platform fix
; they didnt used to move sprites with them
;;;;;

org $02D71E
JSL RotationFix

;;;;;
; brown fix
; the brown spinny platform uses its VERY own interaction, so we hook it up entirely
;;;;;

org $01C9EC
JSL BrownFix

;;;;;
; line guide fix
;;;;;

org $01DB1C
JSL LineFix
NOP

;;;;;
; wooden spike fix
;;;;;

org $039488
JSL WoodFix

;;;;;
; info box fix
; lets kicked sprites activate the message
;;;;;

org $038D6F
JSL InfoFix         ;replace solid routine with a JSL to it of our own and the check for the bottom hit

;;;;;
; dark room switch fix
; lets kicked sprites toggle the light
;;;;;

org $03C1F9
JSL InfoFix         ;uses the same exact code as info box

;;;;;
; hammer bro platform fix
; lets kicked sprites throw off the hammer bro
;;;;;

org $02DBE0
JSL InfoFix         ;uses the same exact code as info box

;;;;;
; volcano lotus fix
; it always acts as if it's in water in smw
;;;;;

org $02DFA4
JSL $01802A|!bank
BRA SkipJunk

org $02DFAF
SkipJunk:

;;;;;
; thwomp fix
; thwomps would stomp the air after rising from a sprite platform, this fixes it
;;;;;

org $01AF38
JSL ThwompFix

;;;;;
; statue fix
; sets $1491
;;;;;

org $038A3F
JML StatueFix

;;;;;;
; yoshi fix
; yoshi is too important to leave buggy
;;;;;;

org $01ECE1
JSL YoshiCheck

org $01ECFB
JSL YoshiFix

;;;;;
; shell-less koopa fix
; fixes the glitch where shell-less koopas keep falling while $9D is set
;;;;;

if !ShellLessFix = $01

  org $018904
  JML NoShellFix

endif
if !ShellLessFix = $00

  org $018904
  LDA $9D
  BEQ $4A

endif

;;;;;
; falling item box sprite fix
; used to interact with objects, set the no-objects byte here
;;;;;

org $02804D
JSL FallingFix


;;;;;
; optional Spring, P-Switch and Key solidness to other sprites
;;;;;

;spring

if !SpriteSpring == $01

  org $01E6F0
  JSL SpringFix
  NOP : NOP

endif
if !SpriteSpring == $00

  org $01E6F0
  LDY !1602,x
  LDA SpringData,y

  org $01E6FD
  SpringData:

endif

;peas

if !SpritePeas == $01

  org $02CDCE
  JSL PeaFix
  NOP

endif
if !SpritePeas == $00

  org $02CDCE
  JSR $CEE0
  LDA $9D

endif

;key

;make mario move with key if he stands on it
org $0195F2
JSL KeySet1491
NOP : NOP

org $01AAD1
JSL KeyMove

;fix other code near that so keys don't disappear during $9D
org $0195F8
Skipped:

org $01956E
JMP $95FC         ;jumps into extremely convenient unused code close

org $0195FC
JSR $A187
BRA Skipped


;;; minor fixes for hitboxes, otherwise they look glitchy as hell

;key
;actually fixes sprite clipping 0C to be 16 pixels high, changing key to another clipping made it bug out
org $03B62C
db $0F

;throw block
org $07F388
db $00

;flying ? blocks (interact with mario every frame)
org $07F54A
db $A2,$A2

;dolphins
org $07F508
db $A2,$A2,$A2

;wall spring pea
;make passable from below
org $07F6C4
db $45,$45

;yoshi
org $03B629
db $18

;mole (make non-solid to other sprites and don't turn around from other sprites)
org $07F718
db $21

;turnblockbridges (make solid to other sprites)
org $07F6B2
db $44,$44


;;;;;;;;;;;;
; give all sprites we don't want riding the platforms "don't interact with objects"
;
; if you want to add or remove one, change the |$00 to |$80 to make a sprite ignore
; platforms, and vice versa to make it react to platforms
;;;;;;;;;;;;

org $07F590
ObjectInteraction:
db $00|$00,$00|$00,$00|$00,$00|$00,$02|$00,$02|$00,$02|$00,$02|$00        ;00-07
db $42|$80,$52|$00,$52|$80,$52|$80,$52|$00,$00|$00,$09|$80,$00|$00        ;08-0F
db $40|$00,$00|$00,$01|$00,$00|$00,$00|$00,$10|$80,$10|$80,$90|$00        ;10-17
db $90|$80,$01|$00,$10|$80,$10|$00,$90|$80,$00|$00,$11|$80,$01|$00        ;18-1F
db $01|$00,$08|$00,$00|$00,$00|$00,$00|$00,$00|$00,$01|$00,$01|$00        ;20-27
db $19|$80,$80|$80,$00|$80,$39|$00,$09|$00,$09|$00,$10|$00,$0A|$00        ;28-2F
db $09|$00,$09|$00,$09|$00,$99|$80,$18|$80,$29|$00,$08|$00,$19|$80        ;30-37
db $19|$80,$19|$80,$11|$00,$11|$00,$15|$00,$10|$00,$0A|$00,$40|$00        ;38-3F
db $40|$00,$8D|$80,$8D|$80,$8D|$80,$11|$80,$18|$00,$11|$00,$80|$80        ;40-47
db $00|$00,$29|$80,$29|$00,$10|$80,$10|$80,$10|$00,$10|$00,$00|$00        ;48-4F
db $00|$00,$10|$00,$29|$80,$20|$00,$29|$80,$A9|$80,$A9|$80,$A9|$80        ;50-57
db $A9|$80,$A9|$80,$A9|$80,$A9|$80,$A9|$80,$A9|$80,$A9|$80,$A9|$80        ;58-5F
db $29|$80,$29|$00,$3D|$80,$3D|$80,$3D|$80,$3D|$80,$3D|$80,$3D|$00        ;60-67
db $3D|$00,$29|$00,$19|$00,$29|$80,$29|$80,$59|$80,$59|$00,$18|$00        ;68-6F
db $18|$00,$10|$80,$10|$80,$50|$00,$28|$00,$28|$00,$28|$00,$28|$00        ;70-77
db $08|$00,$29|$00,$29|$00,$39|$80,$39|$00,$29|$80,$28|$80,$28|$80        ;78-7F
db $3A|$00,$28|$00,$29|$00,$31|$80,$31|$80,$29|$00,$00|$00,$29|$00        ;80-87
db $29|$00,$29|$00,$29|$00,$29|$00,$29|$00,$29|$80,$29|$00,$29|$80        ;88-8F
db $11|$80,$11|$00,$11|$00,$11|$00,$11|$00,$11|$00,$11|$00,$11|$00        ;90-97
db $11|$00,$10|$00,$11|$00,$01|$00,$39|$80,$10|$00,$19|$80,$19|$80        ;98-9F
db $19|$00,$19|$00,$01|$00,$29|$80,$98|$80,$14|$00,$14|$00,$10|$00        ;A0-A7
db $18|$80,$18|$00,$18|$80,$00|$00,$19|$80,$19|$80,$19|$80,$19|$80        ;A8-AF
db $19|$00,$1D|$00,$1D|$80,$19|$80,$19|$00,$18|$00,$18|$00,$19|$80        ;B0-B7
db $19|$80,$19|$80,$1D|$80,$19|$80,$18|$00,$00|$00,$10|$80,$00|$00        ;B8-BF
db $99|$80,$99|$80,$10|$00,$90|$00,$A9|$80,$B9|$80,$FF|$80,$39|$80        ;C0-C7
db $19|$80



;;;;;
; optional hitbox height adjustments
; 09 and 0C are changed in the vanilla variant too to fix key and yoshi
;;;;;

if !VisualFix == $01

  !VisualOffset = $02

  org $03B620
  db $0B+!VisualOffset,$15+!VisualOffset,$12+!VisualOffset,$08+!VisualOffset,$0E+!VisualOffset,$0E+!VisualOffset,$18+!VisualOffset,$30+!VisualOffset        ;00-07
  db $10+!VisualOffset,$18,$02+!VisualOffset,$03+!VisualOffset,$0F+!VisualOffset,$10+!VisualOffset,$14+!VisualOffset,$12+!VisualOffset            ;08-0F
  db $20+!VisualOffset,$40+!VisualOffset,$34+!VisualOffset,$74+!VisualOffset,$0C+!VisualOffset,$0E+!VisualOffset,$18+!VisualOffset,$45+!VisualOffset        ;10-17
  db $3A+!VisualOffset,$2A+!VisualOffset,$1A+!VisualOffset,$0A+!VisualOffset,$30+!VisualOffset,$1B+!VisualOffset,$20+!VisualOffset,$12+!VisualOffset        ;18-1F
  db $18+!VisualOffset,$18+!VisualOffset,$10+!VisualOffset,$20+!VisualOffset,$38+!VisualOffset,$14+!VisualOffset,$08+!VisualOffset,$18+!VisualOffset        ;20-27
  db $28+!VisualOffset,$1B+!VisualOffset,$13+!VisualOffset,$4C+!VisualOffset,$10+!VisualOffset,$04+!VisualOffset,$22+!VisualOffset,$20+!VisualOffset        ;28-2F
  db $1C+!VisualOffset,$12+!VisualOffset,$12+!VisualOffset,$12+!VisualOffset,$08+!VisualOffset,$20+!VisualOffset,$2E+!VisualOffset,$14+!VisualOffset        ;30-37
  db $28+!VisualOffset,$0A+!VisualOffset,$10+!VisualOffset,$0D+!VisualOffset                                        ;38-3B


  org $03B65C         ;player y clip disp
  db $05+!VisualOffset,$12,$0F+!VisualOffset,$17+!VisualOffset
  ;db $06+!VisualOffset,$14+!VisualOffset,$10+!VisualOffset,$18+!VisualOffset

  org $03B660         ;player y clip height
  db $1C-!VisualOffset,$0E-!VisualOffset,$22-!VisualOffset,$1A-!VisualOffset
  ;db $1A-!VisualOffset,$0C-!VisualOffset,$20-!VisualOffset,$18-!VisualOffset

endif
if !VisualFix == $00

  org $03B620
  db $0A,$15,$12,$08,$0E,$0E,$18,$30        ;00-07
  db $10,$18,$02,$03,$0F,$10,$14,$12        ;08-0F
  db $20,$40,$34,$74,$0C,$0E,$18,$45        ;10-17
  db $3A,$2A,$1A,$0A,$30,$1B,$20,$12        ;18-1F
  db $18,$18,$10,$20,$38,$14,$08,$18        ;20-27
  db $28,$1B,$13,$4C,$10,$04,$22,$20        ;28-2F
  db $1C,$12,$12,$12,$08,$20,$2E,$14        ;30-37
  db $28,$0A,$10,$0D                        ;38-3B


  org $03B65C         ;player y clip disp
  db $06,$14,$10,$18

  org $03B660         ;player y clip height
  db $1A,$0C,$20,$18

endif


org $01F9EA
  ora #$A0

org $01959D
  jml stunned_sprites_fix

org $01B4E2
  jsl solid_sprite_fix
  nop

org $01ADF8
  nop #3

org $01A269
  jsl baby_yoshi_fix

org $01953C
  jsl baby_yoshi_check


org $02EDDC
  jsr $D017

;org $038CD9
;  jsl TurnBlkFree
;carrot_lift_end:
;  rts
;warnpc $038CE4

;org $038C74
;  bcc carrot_lift_end
;org $038C78
;  bmi carrot_lift_end
;org $038CA5
;  bpl carrot_lift_end

org $03871F
  jsl lava_platform

;;;;;
; all the custom code is below
;;;;;

freecode

  dl BeSolidToSprites
  dl BeSolidToSpritesSpecialClip

lava_platform:
  stz $1491|!addr
  jml $01B44F

megamole_fix:
lda !190F,x
ora #$01
sta !190F,x
jsl BeSolidToSprites
rtl 


TurnBlockFix:
stz $00
stz $01
stz $02
stz $03
lda !C2,x
and #$02
tay 
lda !151C,x
sta.w $00|!dp,y
lsr
sta.w $01|!dp,y
lda !E4,x
sec 
sbc $00
sta $04
lda !14E0,x
sbc #$00
sta $0A
lda $00
asl 
clc 
adc #$10
sta $06
lda !D8,x
sec 
sbc.b #!VisualOffset
sec 
sbc $02
sta $05
lda !14D4,x
sbc #$00
sta $0B
lda $02
asl 
clc 
adc.b #$10+!VisualOffset
sta $07
jml BeSolidToSpritesSpecialClip

baby_yoshi_check:
  lda !9E,x
  cmp #$2D
  beq .fix
.return
  lda !9E,x
  cmp #$2C
  rtl 

.fix
  lda #$00
  sta !Sides
  lda !SpriteBlockTable_SA1,x
  and #$04
  beq .return
  lda #$01
  sta !Sides
  bra .return

baby_yoshi_fix:
  ldy #$00
  lda !Sides
  bne .no_bouncing
  ldy #$F0
.no_bouncing
  tya
  sta !AA,x
  rtl

solid_sprite_fix:
  lda #$0F
  sta !1564,x
  lda $96
  clc 
  adc #$04
  sta $96
  lda $97
  adc #$00
  sta $97
  rtl

stunned_sprites_fix:
  lda #$10
  sta !AA,x
  lda !SpriteBlockTable_SA1,x
  and #$08
  bne .nope
  jml $0195A1
.nope
  jml $0195DB


AddTable:                   ; x is sprite index

LDA !SpriteBlockTable,x
ORA !1588,x
STA !1588,x                 ; add together the layer 1/2 blocked table and our sprite blocked table

LDA #$00
STA !SpriteBlockTable,x   ; zero out the table for next frame

; restore SMW code
LDA !190F,x
BPL CODE_0191ED
RTL

CODE_0191ED:
PLA : PLA : PLA
JML $0191ED|!bank




SprHorzPos:         ;which side the sprite is on is stored in $0F
                    ;platform is in y, sprite in x
STZ $0F
LDA !E4,x
SEC
SBC !E4|!dp,y
LDA !14E0,x
SBC !14E0,y
BPL +
INC $0F
+
RTS





print "Make Sprite solid to other sprites routine is at: $",pc

BeSolidToSprites:    ;platform's id is in x at entry, put into y immediately
                     ;afterwards, $0E holds the # of sprites that stood on this platform this frame
                     ;!LastSprite holds a pretty much randomly chosen ID of a sprite standing on top of it
                     ;!Sides holds which sides the platform is being touched from (1588 format)
                     ;!SidesKicked holds which sides the platform is being touched from BY A KICKED SPRITE
                     ;HAS TO BE CALLED AFTER X/Y POSITION UPDATE (which vanilla sprites all do)
JSL $03B69F|!bank    ;put platform clipping in slot A

BeSolidToSpritesSpecialClip:      ;skips the clip slotting for special sprites (turn block bridge)

print "Version for platforms with non-vanilla hitboxes is at: $",pc
print ""


PHB                       ; Wrapper 
PHK
PLB
JSR SolidCode
PLB
RTL                       ; Return 


SolidCode:
PHP

LDA #$00
STA !Sides
STA !SidesKicked
STA $0E


LDA !14C8,x
CMP #$0B
BNE +
-
JMP .Return               ;carried platforms (keys, springs etc) aren't solid at all
+
cmp #$08                  ; neither dying sprites are valid
bcc -

TXY

BRA .StartLoop

  .DontCheck2
JMP .DontCheck

  .StartLoop
LDX.b #!SpriteTableSize-1     ;loop through all sprites to find a kicked or held one
  .SpriteLoop
PHX

STX $0F
CPY $0F         ;dont make the platform stand on itself
BEQ .DontCheck2

LDA !14C8,x
CMP #$08        ;check if sprite is alive
BCC .DontCheck2
CMP #$0B        ;also dont mess with carried sprites
BEQ .DontCheck2


;filter sprites by tweaker bits, so no platforms ride each other
LDA !1686,x
AND #$80        ;"don't interact with objects" (why interact with this but not with walls)
BNE .DontCheck2



JSL $03B6E5|!bank  ;put sprite's clipping into slot B, platform is still in A


JSL $03B72B|!bank  ;check if the platform and the sprite intersect
BCC .DontCheck2

;do this if sprites intersect (platform = y, sprite = x)
;moved the sprite num checks down here so they aren't all executed 20 times every single frame
phx
lda.w !7FAB10,x
and #$08
beq +
lda.w !7FAB9E,x
tax
lda.w .custom_interaction_table,x
bra ++
+
lda !9E,x
tax 
lda.w .normal_interaction_table,x
++
plx
asl 
clc
adc.b #.interaction_ptrs
sta $8A
lda.b #.interaction_ptrs>>8
adc #$00
sta $8B
lda.b #.interaction_ptrs>>16
sta $8C
rep #$20
lda ($8A)
sta $8A
sep #$20
jml [$008A]

.interaction_ptrs
dw .DoCheck
dw .DontCheck
dw .DoCheckPowerups
dw .DoCheckRaft
dw .DoCheckMontyMole
dw .DoCheckMegaMole

;applies to sprite on platform
.normal_interaction_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01  ;$10
  db $01,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$04,$04,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$03,$00,$00,$00,$01,$01,$01,$01,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$02,$02,$02,$01,$02,$01,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_interaction_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.DoCheckMegaMole
  LDA $01
  SEC
  SBC $05
  cmp #$08
  bpl +
  jmp .SidesL
+ 
  jmp .DontCheck

.DoCheckMontyMole
  lda !C2,x
  cmp #$02
  bcs ..DoCheck
  jmp .DontCheck
..DoCheck
  jmp .DoCheck

  .DoCheckPowerups
  lda !160E,x
  bne ..DontCheck
  lda !1540,x
  beq ..DoCheck
  ..DontCheck
  jmp .DontCheck
  ..DoCheck
  jmp .DoCheck

  .DoCheckRaft

phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.w .custom_leniency_table,x
bra ++
+
lda !9E,y
tax 
lda.w .normal_leniency_table,x
++
plx
sta $0F

LDA $05
CLC
ADC $0F
STA $0F

LDA $01
CLC
ADC $03
SEC             ;sprite bottom edge - platform top edge with leniency
SBC $0F

BPL +
JMP .Top
+
JMP .DontCheck


!Leniency = $05

;applies to platform
.normal_leniency_table
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$00
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$10
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$03  ;$20
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$30
  db !Leniency,!Leniency+$02,!Leniency+$02,!Leniency+$02,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$40
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$02,!Leniency+$02,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$01  ;$50
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$60
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$70
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$80
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$02,!Leniency,!Leniency,!Leniency  ;$90
  db !Leniency,!Leniency,!Leniency,!Leniency+$01,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$A0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$B0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$C0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$D0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$E0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$F0
.custom_leniency_table
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$00
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$10
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$20
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$30
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$40
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$50
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$60
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$70
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$80
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$90
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$A0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$B0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$C0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$D0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$E0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$F0


.normal_leniency_bottom_table
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$00
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$10
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$01  ;$20
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$30
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$40
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency+$02,!Leniency+$02,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$50
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$60
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$70
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$80
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$90
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$A0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$B0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$C0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$D0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$E0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$F0
.custom_leniency_bottom_table
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$00
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$10
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$20
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$30
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$40
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$50
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$60
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$70
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$80
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$90
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$A0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$B0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$C0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$D0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$E0
  db !Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency,!Leniency  ;$F0

  

  .DoCheck

;figure out what side the sprites are touching from
;with ridiculously naive position math
;springs get more leniency with hitbox

phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.w .custom_leniency_table,x
bra ++
+
lda !9E,y
tax 
lda.w .normal_leniency_table,x
++
plx
sta $0F

lda !AA,x
cmp #$10
bmi ..no_extra_leniency
lda !AA,x
bpl +
eor #$FF
inc
+
lsr #4
clc 
adc $0F
sta $0F
..no_extra_leniency

LDA $05
CLC
ADC $0F
STA $0F

LDA $01
CLC
ADC $03
SEC             ;sprite bottom edge - platform top edge with leniency
SBC $0F

BPL +
JMP .Top
+

;dont check bottom or sides if the platform isn't solid there
.SidesL
LDA !190F,y
LSR
BCC .DownOrSides
JMP .DontCheck

  .DownOrSides
;if not top, check if bottom, if not that, just subhorz

phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.w .custom_leniency_bottom_table,x
bra ++
+
lda !9E,y
tax 
lda.w .normal_leniency_bottom_table,x
++
sta $0F
plx 
LDA $05
CLC
ADC $07         ;bottom edge
SEC
sbc $0F
;SBC #!Leniency
STA $0F

LDA $01
SEC
SBC $0F

BMI +
LDA !AA,x
SEC
SBC !AA|!dp,y
BPL +

JMP .Bottom
+


;sides, check which side of the platform's center the sprite's center is at
LDA $06
LSR
STA $0E         ;half width
LDA $04
CLC
ADC $0E         ;platform's center in A
PHA

LDA $02
LSR
STA $0F         ;half width
LDA $00
CLC
ADC $0F         ;sprite's center in A
STA $0F

PLA             
SEC             ;platform - sprite center x
SBC $0F

BMI .Right
jmp .Left






















  .Right
LDA !B6,x
SEC
SBC !B6|!dp,y
BMI +
JMP .SkipTurn2
+
INC $0E              ;increase amount of sprites that were blocked by this platform this frame

LDA !Sides
ORA #$01
STA !Sides

LDA !14C8,x
CMP #$09
BEQ ++
CMP #$0A
BNE +
++
LDA !SidesKicked
ORA #$01
STA !SidesKicked
+

;sprite's x pos = platform x + (platform width + sprite x disp)
phx
lda.w !7FAB10,x
and #$08
beq +
lda.w !7FAB9E,x
tax
lda.w .custom_side_right_push_table,x
bra ++
+
lda !9E,x
tax 
lda.w .normal_side_right_push_table,x
++
plx
cmp #$00
beq .push_right_spr
.push_right_platform
LDA !slot_a_x_lo
SEC
SBC !E4,y       ;x disp get
CLC
ADC $02         ;add x disp and sprite width
CLC
ADC #$04+1      ;+1 to put it one pixel left of the left edge anyway
STA $0F
LDA !slot_b_x_lo
SEC
SBC $0F         ;platform x - (sprite width + disp)
STA !E4,y
LDA !slot_b_x_hi
SBC #$00
STA !14E0,y
bra .push_right_end


.push_right_spr
LDA $00
SEC
SBC !E4,x       ;x disp get
CLC
ADC $06         ;add x disp and platform width
STA $0F

LDA $04
CLC
ADC $0F         ;platform x + (platform width + disp)
STA !E4,x
LDA $0A
ADC #$00
STA !14E0,x
.push_right_end









;turn around the sprite
LDA !14C8,x
CMP #$08
BEQ .NotKickedRight

;kicked sprites don't get told that they're hitting a wall, cause they'll try to activate ? blocks
STZ !157C,x
JSR KickedRt
JMP .DontCheck

  .NotKickedRight
LDA !SpriteBlockTable,x
ORA #$02
STA !SpriteBlockTable,x

JMP .DontCheck

  .SkipTurn2
JMP .SkipTurn





















  .Left
LDA !B6,x
SEC
SBC !B6|!dp,y
BEQ .SkipTurn2
BMI .SkipTurn2
+
INC $0E              ;increase amount of sprites that were blocked by this platform this frame

LDA !Sides
ORA #$02
STA !Sides

LDA !14C8,x
CMP #$09
BEQ ++
CMP #$0A
BNE +
++
LDA !SidesKicked
ORA #$02
STA !SidesKicked
+

phx
lda.w !7FAB10,x
and #$08
beq +
lda.w !7FAB9E,x
tax
lda.w .custom_side_left_push_table,x
bra ++
+
lda !9E,x
tax 
lda.w .normal_side_left_push_table,x
++
plx
cmp #$00
beq .push_left_spr
.push_left_platform
LDA !slot_a_x_lo
SEC
SBC !E4,y       ;x disp get
CLC
ADC !slot_a_width         ;add x disp and platform width
STA $0F

LDA !slot_b_x_lo
CLC
ADC $0F         ;platform x + (platform width + disp)
STA !E4,y
LDA !slot_b_x_hi
ADC #$00
STA !14E0,y
bra .push_left_end


.push_left_spr
LDA $00
SEC
SBC !E4,x       ;x disp get
CLC
ADC $02         ;add x disp and sprite width
CLC
ADC #$04+1      ;+1 to put it one pixel left of the left edge anyway
STA $0F

LDA $04
SEC
SBC $0F         ;platform x - (sprite width + disp)
STA !E4,x
LDA $0A
SBC #$00
STA !14E0,x
.push_left_end














;turn around the sprite
LDA !14C8,x
CMP #$08
BEQ .NotKickedLeft

;kicked sprites don't get told that they're hitting a wall, cause they'll try to activate ? blocks
LDA #$01
STA !157C,x
JSR KickedRt
JMP .DontCheck

   .NotKickedLeft
LDA !SpriteBlockTable,x
ORA #$01
STA !SpriteBlockTable,x

  .SkipTurn
JMP .DontCheck


  .Bottom
LDA !190F,y
AND #$01
BEQ +
JMP .DontCheck
+

LDA !1588,x
AND #$04
BEQ +

JMP .DontCheck

+

INC $0E              ;increase amount of sprites that were blocked by this platform this frame

LDA !Sides
ORA #$04
STA !Sides

LDA !14C8,x
CMP #$09
BEQ ++
CMP #$0A
BNE +
++
LDA !SidesKicked
ORA #$04
STA !SidesKicked
+

LDA !AA|!dp,y
BEQ .NoAdjust
;sprite's y pos = platform y + (platform height + sprite y disp)
LDA $01
SEC
SBC !D8,x       ;y disp get
CLC
ADC $07         ;add y disp and platform height
SEC
SBC #$03
STA $0F

LDA $05
CLC
ADC $0F         ;platform x + (platform width + disp)
STA !D8,x
LDA $0B
ADC #$00
STA !14D4,x

  .NoAdjust


LDA #$10
STA !AA,x

lda !D8,x
clc 
adc #$02
sta !D8,x
lda !14D4,x
adc #$00
sta !14D4,x

LDA !SpriteBlockTable,x
ORA #$08
STA !SpriteBlockTable,x

JMP .DontCheck

  .Top
;touched from above
LDA !AA,x
BPL +
JMP .DontCheck      ;if platform moves down, but sprite isnt, ignore
+

  .TopNoCheck
TXA
STA !LastSprite
INC $0E              ;increase amount of sprites that were blocked by this platform this frame

LDA !Sides
ORA #$08
STA !Sides

LDA !14C8,x
CMP #$09
BEQ ++
CMP #$0A
BNE +
++
LDA !SidesKicked
ORA #$08
STA !SidesKicked
+

;;;  let sprite stand stuff

phx
lda.w !7FAB10,x
and #$08
beq +
lda.w !7FAB9E,x
tax
lda.w .custom_top_collision_table,x
bra ++
+
lda !9E,x
tax 
lda.w .normal_top_collision_table,x
++
plx
asl 
clc
adc.b #.top_collision_ptrs
sta $8A
lda.b #.top_collision_ptrs>>8
adc #$00
sta $8B
lda.b #.top_collision_ptrs>>16
sta $8C
rep #$20
lda ($8A)
sta $8A
sep #$20
jml [$008A]

.top_collision_ptrs
dw .RegularTop
dw .NoYSpd

;applies to sprite on platform
.normal_top_collision_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$02,$03,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_top_collision_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

;applies to platform
.normal_top_sticky_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_top_sticky_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.normal_side_right_push_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_side_right_push_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $01,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0


.normal_side_left_push_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_side_left_push_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.RegularTop
  LDA !190F,x
  AND #$80
  BNE .Carryable

  LDA #$10
  BRA .StoreYSpd

  .Carryable
  phx
  lda.w !7FAB10,y
  and #$08
  beq +
  lda.w !7FAB9E,y
  tax
  lda.w .custom_top_sticky_table,x
  bra ++
  +
  lda !9E,y
  tax 
  lda.w .normal_top_sticky_table,x
  ++
  plx
  cmp #$00
  bne .ZeroYSpd

  LDA !AA|!dp,y
  BEQ .NoYSpd
  .ZeroYSpd
  LDA #$00
  .StoreYSpd
  STA !AA,x

  .NoYSpd
  LDA !SpriteBlockTable,x
  ORA #$04
  STA !SpriteBlockTable,x


LDA !1588,x
AND #$03              ;only move sprite with the platform if no walls are in the way
BEQ .CheckTopStand
jmp .YStand

.CheckTopStand
phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.w .custom_top_wall_table,x
bra ++
+
lda !9E,y
tax 
lda.w .normal_top_wall_table,x
++
plx
asl 
clc
adc.b #.top_wall_ptrs
sta $8A
lda.b #.top_wall_ptrs>>8
adc #$00
sta $8B
lda.b #.top_wall_ptrs>>16
sta $8C
rep #$20
lda ($8A)
sta $8A
sep #$20
jml [$008A]

.top_wall_ptrs
dw .AddX
dw .YStand

;applies to platform
.normal_top_wall_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$01,$01,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.custom_top_wall_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

  .AddX
PHY
LDY #$00
LDA $1491|!addr
BPL .NoNegX
DEY
  .NoNegX

CLC
ADC !E4,x             ;add platform speed to x position
STA !E4,x

TYA
ADC !14E0,x
STA !14E0,x
PLY

  .YStand

!Rigidness = $02
;how many pixels the sprites sink into platforms
;this keeps them from sliding around, $01 stops most sliding, but
;only $02 properly prevents sprites from sliding off rotating platforms and bouncing on ones that go down
;anything above $02 is probably overkill and might even bug out


;calculate new y pos for the sprite based on clipping height and offset from the position

LDA $01
SEC
SBC !D8,x
CLC
ADC $03
SEC
SBC #!Rigidness
STA $0F

LDA $05
SEC
SBC $0F
STA !D8,x
LDA $0B
SBC #$00
STA !14D4,x


  .DontCheck
PLX
DEX
BMI +
JMP .SpriteLoop
+

TYX

;if a sprite is using the platform, process while off-screen
LDA $0E
BEQ .NoProcess

;force process off-screen
;Vivi edit start
LDA !OffscreenCopy,x
BMI +
LDA !167A,x
AND #$04
ORA #$80
STA !OffscreenCopy,x
+
;Vivi edit end
LDA !167A,x
ORA #$04
STA !167A,x

BRA .Return

  .NoProcess

;if not forcing process off-screen, reload tweaker bytes to default
LDA !OffscreenCopy,x
BPL +
AND.b #$04
ORA.b #~$04
AND !167A,x
STA !167A,x
LDA #$00
STA !OffscreenCopy,x
+

;JSL $07F7A0|!bank
;Vivi edit end

  .Return
PLP
RTS



KickedRt:
LDA #$01
STA $1DF9|!addr
KickedRt2:
LDA !B6,x   ;turn around and halve speed
EOR #$FF : INC
PHA

LDA !14C8,x
CMP #$0A
BEQ .StoreY

PLA
BPL +
EOR #$FF : INC
LSR
EOR #$FF : INC
BRA ++
+
LSR
++
PHA
  .StoreY
PLA
STA !B6,x
RTS





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; other important hijacks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


PlatformHijack:       ;the hijack most platforms with standard handling use, returns into ProcessInteract
JSL BeSolidToSprites

; restore SMW code
JSL $01A7DC
BCC .ReturnFar
RTL

  .ReturnFar
PLA : PLA : PLA
JML $01B4B2|!bank





ClearTable:           ;clear our table when other sprite tables are cleared
STZ !C2,x
STZ !151C,x
LDA #$00
STA !SpriteBlockTable,x
STA !LastXPosition,x
STA !OffscreenCopy,x
inc
STA !OffsetFlag,x
RTL



InitXPos:
LDA !E4,x
STA !LastXPosition,x

JML $07F7A0|!bank           ;restore smw code, loads tweaker bytes



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; specific sprite fixes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ThwompFix:      ;clear the blocked table while rising, so it won't stomp the air
LDA #$00
STA !SpriteBlockTable,x

LDA #$F0
STA !AA,x
RTL




StatueFix:
;set $1491|!addr
LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr
STA !1528,x

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x

  .Restore
LDA $9D
BNE .ReturnRTS
JML $038A43|!bank
  .ReturnRTS
JML $038A68|!bank



FlyingSet1491:
;set $1491|!addr
LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr
STA !1528,x

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x
RTL



YoshiCheck:
LDA !SpriteBlockTable,x
AND #$04
BEQ .ClearSides

LDA #$01
STA !Sides

BRA .Restore

  .ClearSides
LDA #$00
STA !Sides

  .Restore
LDA !C2,x
CMP #$01
RTL




YoshiFix:       ;disable yoshi hopping and instead make yoshi turn to mario
STZ !B6,x

LDA !Sides
BNE .DontHop

LDA #$F0
RTL

  .DontHop
LDA #$00
RTL




if !ShellLessFix == $01

  NoShellFix:
  LDA $9D
  BEQ .NotFrozen
  ;if sprites are frozen, instead of running through some blue koopa code, jump to the graphics code
  ;nintendo did this to save 3 bytes (a JMP to $018B03), thanks nintendo
  JML $018B03|!bank

    .NotFrozen
  ;if sprites move, jump to the vanilla location
  JML $018952|!bank

endif


FallingFix:
;restore smw code
JSL $07F7D2|!bank

;set "no-objects" bit
LDA !1686,x
ORA #$80
STA !1686,x
RTL





TurnBlkFree:        ;move some Turn Block Bridge code to freespace to add in our JSL
CLC
ADC $94
STA $94
TYA
ADC $95
STA $95
RTL



RotationFix:
LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x

  lda !D8,x
  pha 
  clc 
  adc #$01
  sta !D8,x
  lda !14D4,x
  pha
  adc #$00
  sta !14D4,x
  jsl $01B44F
  pla 
  sta !14D4,x
  pla 
  sta !D8,x
  rtl 

;JML $01B44F|!bank ;restore



BrownFix:
PHY
LDA $14B8|!addr
STA $04
SEC
SBC !LastXPosition,x
STA $1491|!addr

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA $14B8|!addr
STA !LastXPosition,x


LDA $04
SEC
SBC.b #$18
STA $04
LDA.w $14B9|!addr
SBC.b #$00
STA $0A
LDA.b #$40
STA $06
LDA.w $14BA|!addr
SEC
SBC.b #$0C-!VisualOffset
STA $05
LDA.w $14BB|!addr
SBC.b #$00
STA $0B
LDA.b #$13
STA $07
JSL BeSolidToSpritesSpecialClip
LDA $14B9|!addr
XBA 
PLY
RTL



LineFix:
SBC #$00
STA !14D4,x       ;restore smw code

;store to 1491
LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x
RTL



WoodFix:
JSL $01A7DC|!bank     ;mess with mario
PHP             ;reserve result of interaction for later
JSL BeSolidToSpritesSpecialClip ;mess with sprites
PLP
RTL




InfoFix:
JSL $01B44F|!bank           ;call solidness routine (includes sprite solid)
NoSolidnessInfoFix:
LDA !SidesKicked
AND #$07              ;check if a KICKED sprite hit from below
BEQ .NoBottom         ;if not, return

LDA !C2,x
BNE .NoBottom

INC !C2,x
LDA #$10              ;display message
STA !1558,x

  .NoBottom
RTL


if !VisualFix == $01

  RaftAdjust:
  jsl $03B69F
  LDA $05
  CLC
  ADC #!VisualOffset
  STA $05
  LDA $0B
  ADC #$00
  STA $0B
  JSL BeSolidToSpritesSpecialClip
  RTL

endif




Mole1491:
;restore
JSL $018032|!bank

LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr

lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x
RTL





FlyingBlockFix:
JSL NoSolidnessInfoFix

LDA !1558,x
CMP #$08
RTL




KeySet1491:
LDA !9E,x
CMP #$3E
BEQ .DoSet
CMP #$80
BNE .Restore

  .DoSet
;store to 1491
LDA !E4,x
SEC
SBC !LastXPosition,x
STA $1491|!addr


lda !OffsetFlag,x
beq +
dec 
sta !OffsetFlag,x
stz $1491|!addr
+ 

LDA !E4,x
STA !LastXPosition,x

  .Restore
PHK
PEA.w .jslrtsreturn-1
PEA.w $0180CA-1
JML $018FC1|!bank
.jslrtsreturn

PHK
PEA.w .jslrtsreturn2-1
PEA.w $0180CA-1
JML $01A187|!bank
.jslrtsreturn2
RTL



KeyMove:
STZ $0F

LDA $1491|!addr
BPL .MovesRight
DEC $0F

  .MovesRight
LDA $94
CLC
ADC $1491|!addr
STA $94
LDA $95
ADC $0F
STA $95

  .Restore
STZ $7D
STZ $72
RTL






if !SpriteSpring == $01

  !BounceTimer = !1564
  !SpriteIndex = !1594
  !SaveXSpd = !160E

  SpringFix:
  PHB                       ; Wrapper 
  PHK
  PLB
  JSR SpringCode         
  PLB
  RTL                       ; Return 


  SpringAnim:
  db $00,$01,$01,$01,$02,$02,$02,$02
  db $02,$01,$01,$01,$01,$00,$00,$00

  SpringPos:
  db $F9,$F9,$03,$03,$06,$06,$06,$06
  db $06,$03,$03,$03,$03,$00,$00,$00

  SpringCode:
  LDA !BounceTimer,x               ;sprite bounce timer
  BNE +
  JMP .CheckForSprites

.PreInterrupted
  jmp .Interrupted
.PreNormalBounce
  jmp .NormalBounce

  +


    .Animation
  LDA !SpriteIndex,x
  TAY
  LDA !14C8,y
  CMP #$0B
  BEQ .PreInterrupted
  CMP #$08
  BCC .PreInterrupted

  LDA !BounceTimer,x
  TAY
  LDA SpringAnim,y
  STA !1602,x
  LDA SpringPos,y
  STA $0E


  LDA !BounceTimer,x               ;sprite bounce timer
  CMP #$01
  BNE .PreNormalBounce

  LDA !SpriteIndex,x
  TAY

  
phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.l .custom_springboard_bounce_table,x
bra ++
+
lda !9E,y
tax 
lda.l .normal_springboard_bounce_table,x
++
plx
asl 
clc
adc.b #.springboard_bounce_ptrs
sta $8A
lda.b #.springboard_bounce_ptrs>>8
adc #$00
sta $8B
lda.b #.springboard_bounce_ptrs>>16
sta $8C
rep #$20
lda [$8A]
sta $8A
sep #$20
jml [$008A]

.springboard_bounce_ptrs
dw .RegularBounce
dw .LittleBounce
dw .UrchinNoBounce

;applies to sprite on platform
.normal_springboard_bounce_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$02,$02,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01  ;$40
  db $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.custom_springboard_bounce_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

    .RegularBounce
  LDA #!Bounce              ;throw sprite up
  BRA .DidBounce

    .LittleBounce
  LDA.b #!Bounce+$3C              ;throw sprite up slightly less

    .DidBounce
  STA !AA|!dp,y

  ;catapult less if spring is in water
  LDA !164A,x
  BEQ .UrchinNoBounce

  LDA !AA|!dp,y
  CLC
  ADC.b #!Bounce^$FF-(!Bounce^$FF/4)
  STA !AA|!dp,y

    .UrchinNoBounce
  LDA !SaveXSpd,x
  STA !B6|!dp,y

  LDA #$00                  ;reset animation frame
  STA !1602,x


  LDA !15A0,x               ;if sprite on-screen, do:
  BNE .NoBoing

  LDA #$08                  ;boing
  STA $1DFC|!addr

    .NoBoing

  JMP .Restore

    .Interrupted
  ;if spring gets interrupted, reset
  STZ !BounceTimer,x
  STZ !1602,x
  STZ !SpriteIndex,x
  JMP .Restore

    .NormalBounce
  LDA !SpriteIndex,x
  TAY

  LDA !AA,x
  BNE .NoStick

  PHX
  TYX
  JSL $03B6E5|!bank         ;get sprite's clipping slot B
  TXY
  PLX


  JSL $03B69F|!bank         ;get sprite clipping A for spring

  LDA $01
  SEC
  SBC !D8|!dp,y        ;get y disp
  CLC
  ADC $03              ;add height
  SEC
  SBC $0E              ;and spring animation disp
  STA $0E


  LDA $05
  SEC
  SBC $0E
  STA !D8|!dp,y
  PHP

  LDA $0E
  BPL .PositiveOff
  LDA #$FF
  BRA .NegativeOff
    .PositiveOff
  LDA #$00
    .NegativeOff
  STA $0E

  PLP
  LDA $0B
  SBC $0E
  STA !14D4,y

    .NoStick
  LDA #$00                  ;make it stand still
  STA !B6|!dp,y

  JMP .Restore


    .CheckForSprites
  ;if the spring is moving, don't be solid from the sides

  LDA !AA,x
  ORA !B6,x
  BEQ .Still

  LDA #$C5
  STA !190F,x

  BRA .Moving

    .PreRestore
  jmp .Restore

    .Still
  LDA #$C4
  STA !190F,x

    .Moving
  JSL BeSolidToSprites
  LDA !Sides
  AND #$08
  BEQ .PreRestore

  LDA !LastSprite
  STA !SpriteIndex,x
  TAY


phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.l .custom_springboard_rule_table,x
bra ++
+
lda !9E,y
tax 
lda.l .normal_springboard_rule_table,x
++
plx
asl 
clc
adc.b #.springboard_rule_ptrs
sta $8A
lda.b #.springboard_rule_ptrs>>8
adc #$00
sta $8B
lda.b #.springboard_rule_ptrs>>16
sta $8C
rep #$20
lda [$8A]
sta $8A
sep #$20
jml [$008A]

.springboard_rule_ptrs
dw .EnableRegular
dw .Restore
dw .EnableLittle

;applies to sprite on platform
.normal_springboard_rule_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02  ;$40
  db $02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.custom_springboard_rule_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.EnableRegular
  LDA !14C8,y
  CMP #$0B
  BNE +
  JMP .Restore
  +

  LDA !AA,x         ;if the spring is moving vertically, make it fall down now (SMM does this)
  BEQ .NoDown

  LDA #$10
  STA !AA,x

    .NoDown
  LDA !B6|!dp,y
  STA !SaveXSpd,x
  LDA #$00                  ;make it stand still
  STA !B6|!dp,y
  BRA .NoChange

.EnableLittle
  LDA !14C8,y
  CMP #$0B
  BEQ .Restore

  LDA !AA,x         ;if the spring is moving vertically, make it fall down now (SMM does this)
  BEQ ..NoDown

  LDA #$10
  STA !AA,x

    ..NoDown
  LDA !B6|!dp,y
  STA !SaveXSpd,x
  LDA #$00                  ;make it stand still
  STA !B6|!dp,y

    .LittleChange
  PHX
  TYX
  LDA !SpriteBlockTable,x
  AND.b #$04^$FF            ;tell the sprite that it actually isn't on any floor at all
  STA !SpriteBlockTable,x
  PLX


    .NoChange
  LDA #$0F
  STA !BounceTimer,x

  JMP .Animation


    .Restore2
  LDA !BounceTimer,x
  BEQ .Restore

  LDA !SpriteIndex,x
  TAY
  LDA !SaveXSpd,x
  STA !B6|!dp,y

  LDA.b #!Bounce^$FF+1/2^$FF+1              ;throw sprite up
  STA !AA|!dp,y

  STZ !1602,x               ;reset animation frame



  LDA !15A0,x               ;if sprite on-screen, do:
  BNE .NoBoing2

  LDA #$08                  ;boing
  STA $1DFC|!addr

    .NoBoing2

  STZ !BounceTimer,x
  STZ !SpriteIndex,x

    .Restore
  LDY !1602,x
  LDA .SpringTable,y
  RTS


    .SpringTable
  db $00,$02,$00

endif


if !SpritePeas == $01

  PeaFix:
  LDA !9E,x
  CMP #$6C
  BNE .NoAdjust

  ;if it's a right wall spring, move hitbox left 2 blocks (smw doesn't do this lol)
  LDA !E4,x
  PHA
  SEC
  SBC #$20
  STA !E4,x
  LDA !14E0,x
  PHA
  SBC #$00
  STA !14E0,x

  JSL BeSolidToSprites

  PLA
  STA !14E0,x
  PLA
  STA !E4,x

  BRA .CheckForBounce

    .NoAdjust
  LDA !E4,x
  PHA
  SEC
  SBC #$06
  STA !E4,x
  LDA !14E0,x
  PHA
  SBC #$00
  STA !14E0,x
  JSL BeSolidToSprites
  PLA
  STA !14E0,x
  PLA
  STA !E4,x

    .CheckForBounce
  LDA !Sides        ;if nothing touched the pea from the top, restore smw code
  AND #$08
  BNE +
  JMP .Restore
  +

  PHY
  LDA !LastSprite   ;grab the sprite's index
  TAY


phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.l .custom_pea_bouncer_rule_table,x
bra ++
+
lda !9E,y
tax 
lda.l .normal_pea_bouncer_rule_table,x
++
plx
asl 
clc
adc.b #.pea_bouncer_rule_ptrs
sta $8A
lda.b #.pea_bouncer_rule_ptrs>>8
adc #$00
sta $8B
lda.b #.pea_bouncer_rule_ptrs>>16
sta $8C
rep #$20
lda [$8A]
sta $8A
sep #$20
jml [$008A]

.pea_bouncer_rule_ptrs
  dw .RegularRule
  dw .RestorePLY

.normal_pea_bouncer_rule_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01,$01,$01,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $01,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.custom_pea_bouncer_rule_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.normal_pea_bouncer_bounce_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0

.custom_pea_bouncer_bounce_table
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$00
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$10
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$20
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$30
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$40
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$50
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$60
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$70
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$80
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$90
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$A0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$B0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$C0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$D0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$E0
  db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ;$F0
.RegularRule
  LDA #$02          ;put spring into pimmel mode
  STA !1528,x


  ;LDA !15A0,x               ;if sprite on-screen, do:
  ;BNE .NoBoing

  LDA #$08                  ;boing
  STA $1DFC|!addr

    .NoBoing
  ;calculate bounciness based on how far out the sprite is, then limit it between 01 and 07
  LDA !9E,x
  CMP #$6C
  BNE .NoInvert
  LDA !E4|!dp,y
  SEC
  SBC !E4,x
  CLC
  ADC #$10

  EOR #$FF
  INC
  BRA .DoneInvert

    .NoInvert
  LDA !E4|!dp,y
  SEC
  SBC !E4,x

    .DoneInvert
  BMI .Load01
  LSR : LSR
  BEQ .Load01

  CMP #$08
  BCC .GoodToGo

  LDA #$07

  BRA .GoodToGo

    .Load01
  LDA #$01

    .GoodToGo
  STA !151C,x

  PHB
  PHK
  PLB
  PHX
  TAX
  LDA PeaSpeeds,x         ;load appropriate bounce speed
  PLX
  STA !AA|!dp,y
  PLB

  ;bounce some sprites softer
  

phx
lda.w !7FAB10,y
and #$08
beq +
lda.w !7FAB9E,y
tax
lda.l .custom_pea_bouncer_bounce_table,x
bra ++
+
lda !9E,y
tax 
lda.l .normal_pea_bouncer_bounce_table,x
++
plx
cmp #$00
  BEQ .LittleBounce

  ;catapult less if spring is in water as well
  LDA !164A,x
  BEQ .NoLittle

    .LittleBounce
  LDA !AA|!dp,y
  EOR #$FF
  INC
  LSR
  EOR #$FF
  INC
  STA !AA|!dp,y
    .NoLittle
  PHX
  TYX
  LDA !SpriteBlockTable,x
  AND.b #$04^$FF            ;tell the sprite that it actually isn't on any floor at all
  STA !SpriteBlockTable,x
  PLX

    .RestorePLY
  PLY

    .Restore
  PHK
  PEA.w .jslrtsreturn-1
  PEA.w $02B889-1
  JML $02CEE0|!bank
  .jslrtsreturn

  LDA $9D
  RTL

  PeaSpeeds:
  db $FF,$B5,$AE,$AA,$A6,$A0,$9A,$95

endif
