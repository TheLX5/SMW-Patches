;##################################################################################################
;# Wiggler unrestrictor v1.0
;# by lx5
;# 
;# This patch lets the user decide how many wigglers are supported on screen at any given time.
;# It also makes them not reliant on sprite header 0A in order to work.

;##########################################################
;# Customization

!wiggler_amount         = 4         ;# Number of wigglers that can be active on screen at any time.
                                    ;# Each wiggler requires 128 bytes of RAM.
                                    ;# Note: If you're on a SA-1 ROM, you will want to change the 
                                    ;# buffer location, otherwise you will corrupt other data!

!wiggler_buffer         = $7F9A7B   ;# Buffer for wiggler's segments on non SA-1 ROMs.
!wiggler_buffer_sa1     = $418800   ;# Buffer for wiggler's segments on SA-1 ROMs.

;##########################################################
;# Internal stuff, do not move anything below

if read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!sa1 = 1
    !sprite_size = 22
    !1504 = $74F4
    !14C8 = $3242
    !9E = $3200
    !wiggler_buffer = !wiggler_buffer_sa1
else
    lorom
    !dp = $0000
    !addr = $0000
    !bank = $800000
    !sa1 = 0
    !sprite_size = 12
    !1504 = $1504
    !14C8 = $14C8
    !9E = $9E
endif

;##########################################################
;# Hijacks

org $02F011|!bank
	autoclean jml wiggler_get_ptr
org $02F015|!bank
	lda.b #!wiggler_buffer
org $02F01D|!bank
	lda.b #!wiggler_buffer/$100
org $02F024|!bank
	lda.b #!wiggler_buffer/$10000
org $02F0F0|!bank
	mvp !wiggler_buffer/$10000,!wiggler_buffer/$10000

;##########################################################
;# Code

freecode

wiggler_get_ptr:
	lda !1504,x
	bne .already_set
    ldx.b #$00
.init
	inc 
	sta $00,x
    inx 
    cpx.b #!wiggler_amount
    bne .init
	ldy.b #!sprite_size-1
.loop
	cpy $15E9|!addr
	beq .next
	lda !14C8,y	
	cmp #$02		; ignore dead and initialized sprites
	bcc .next
	lda.w !9E,y
	cmp #$86		; only accept wigglers
	bne .next
	lda !1504,y
	dec 
	tax 
	stz $00,x
.next
	dey 
	bpl .loop
	ldx.b #!wiggler_amount-1
.not_free
	lda $00,x
	bne .free
	dex 
	bpl .not_free
	ldx $15E9|!addr
    stz !14C8,x     ; kill if no free wiggler slots
	pla 
	pla 
	jml $02F00F|!bank
.free
	ldx $15E9|!addr
	sta !1504,x
.already_set
	dec 
	tay 
	jml $02F015|!bank