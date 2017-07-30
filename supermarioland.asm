; disassembled by gbdisasm https://github.com/MegaLoler/gbdisasm
; written by megaloler/aardbei <megaloler9000@gmail.com>
; dissasembly of file "supermarioland.gb"

.memorymap
	slotsize $4000
	defaultslot 1
	slot 0 $0000
	slot 1 $4000
.endme

.banksize $4000
.rombanks 4

.gbheader
	name "SUPER MARIOLAND"
	licenseecodeold $01
	cartridgetype $01
	ramsize $00
	countrycode $00
	nintendologo
	romdmg
.endgb

.emptyfill $ff

.include "cgb_hardware.i"
.include "locations.i"

.bank 0 slot 0
.org $0

; rst/interrupt vector table
; rst $00
	jp		INIT			; $0000: $c3 $85 $01 

.org $6

; random nop filler
	nop					; $0006: $00 
	nop					; $0007: $00 
; end random nop filler

.org $8

; rst $08
	jp		INIT			; $0008: $c3 $85 $01 

.org $28

; rst $28
; takes something on a
; and an address on the stack
; which is the return address rom this rst!
; SO: jp to ((pc + a*2))
	; double a
	; so a is a word pointer
	; an address offset, yes?
	add		a			; $0028: $87 
	; grab whatevers on the stack?
	pop		hl			; $0029: $e1 
	; make de with e as double original a
	ld		e, a			; $002a: $5f 
	ld		d, $00			; $002b: $16 $00 
	; and add that to whatever was on the stack
	add		hl, de			; $002d: $19 
	; and grab the word there
	ld		e, (hl)			; $002e: $5e 
	inc		hl			; $002f: $23 
	ld		d, (hl)			; $0030: $56 
	; copy de onto hl
	push		de			; $0031: $d5 
	pop		hl			; $0032: $e1 
	; jump to the address that was that loaded word
	jp		hl			; $0033: $e9 
; end rst routine

.org $40

; vblank
	jp		VBLANK_IRQ		; $0040: $c3 $60 $00 

.org $48

; lcdc stat
	jp		LCDC_STAT_IRQ		; $0048: $c3 $95 $00 

.org $50

; timer
	; the timer irq handler is in bank 03
	; so this just switches to it
	; and calls that handler
	; the timer interrupt is used for sound engine
	push		af			; $0050: $f5 
	ld		a, $03			; $0051: $3e $03 
	ld		($2000), a		; $0053: $ea $00 $20 
	call		TIMER_IRQ_ALIAS		; $0056: $cd $f0 $7f 
	ldh		a, (r_current_bank)	; $0059: $f0 $fd 
	ld		($2000), a		; $005b: $ea $00 $20 
	pop		af			; $005e: $f1 
	reti					; $005f: $d9 

; vblank handler
VBLANK_IRQ:
	; saves all the registers
	push		af			; $0060: $f5 
	push		bc			; $0061: $c5 
	push		de			; $0062: $d5 
	push		hl			; $0063: $e5 

	; call these routines
	call		COPY_MAP0_COLUMN	; $0064: $cd $4f $22 
	; somethin to do with hittin blocks!!!
	; still wonderin how it handles marios actual head collision ? ?
	; probs elsewhere
	call		HANDLE_BLOCKS_AND_COINS	; $0067: $cd $7d $1b 
	; checks if lives need to be updated , if a request has been made for that
	call		HANDLE_LIFE_CHANGES	; $006a: $cd $2a $1c 
	; call the hram routine
	; this is OAM TRANSFER
	call		$ffb6			; $006d: $cd $b6 $ff 
	; draws the score if need be
	call		HANDLE_SCORE_DRAW_REQUEST	; $0070: $cd $24 $3f 
	; counts down the time
	call		HANDLE_DISPLAY_TIME		; $0073: $cd $61 $3d 
	; WHO THE HECK KNOWS
	; does something with some dynamic tiles in tile memory i think????
	call		ROUTINE_19		; $0076: $cd $f8 $23 

	; count up the countupper
	ld		hl, $ffac		; $0079: $21 $ac $ff 
	inc		(hl)			; $007c: $34 

	; if state is 3ah, then enable window
	; that is credits upwards scrolling
	ldh		a, (r_state)		; $007d: $f0 $b3 
	cp		$3a			; $007f: $fe $3a 
	jr		nz, +			; $0081: $20 $05 
	ld		hl, LCDC		; $0083: $21 $40 $ff 
	set		5, (hl)			; $0086: $cb $ee 

	; reset scrolling
+	xor		a			; $0088: $af 
	ldh		(R_SCX), a		; $0089: $e0 $43 
	ldh		(R_SCY), a		; $008b: $e0 $42 
	; and request engine loop iteration
	inc		a			; $008d: $3c 
	ldh		(r_engine_loop_request), a		; $008e: $e0 $85 

	; restores all the registers
	pop		hl			; $0090: $e1 
	pop		de			; $0091: $d1 
	pop		bc			; $0092: $c1 
	pop		af			; $0093: $f1 
	; and done
	reti					; $0094: $d9 
; end routine

; lcdc stat handler
LCDC_STAT_IRQ:
	; push these registers on the stack
	push		af			; $0095: $f5 
	push		hl			; $0096: $e5 

	; make sure that u kno WE SUPOSED TO BE HERE (u kno, lyc is set to somein)
-	ldh		a, ($41)		; $0097: $f0 $41 
	and		$03			; $0099: $e6 $03 
	jr		nz, -			; $009b: $20 $fa 

	; skip down below IF this is set
	ld		a, ($c0a5)		; $009d: $fa $a5 $c0 
	and		a			; $00a0: $a7 
	jr		nz, +			; $00a1: $20 $2c 

	; if it is 0, then we do this freakin stuff:
	; WE BE COPYIN THE scroll to SCX register in the gameboy
	ldh		a, (r_scroll)		; $00a3: $f0 $a4 
	ldh		(R_SCX), a		; $00a5: $e0 $43 
	; IF THE CREDITS BE ROLLIN
	; THEN ROLL THE CREDITS b y how  much they been rollin
	ld		a, (credits)		; $00a7: $fa $de $c0 
	and		a			; $00aa: $a7 
	jr		z, ++			; $00ab: $28 $05 
	ld		a, (credits_scroll)		; $00ad: $fa $df $c0 
	ldh		(R_SCY), a		; $00b0: $e0 $42 
	; if the credits be scrollin up to chill....
++	ldh		a, (r_state)		; $00b2: $f0 $b3 
	cp		$3a			; $00b4: $fe $3a 
	jr		nz, +++			; $00b6: $20 $14 
	; .... then do this SHINANIGINS
	; utterwise, get out below
	; so yeah, this stuff here is if the credits be ROLLIN to chill
	; i think this is the thing that makes the credits CHILL
	ld		hl, $ff4a		; $00b8: $21 $4a $ff 
	ld		a, (hl)			; $00bb: $7e 
	cp		$40			; $00bc: $fe $40 
	jr		z, ++			; $00be: $28 $1e 
	dec		(hl)			; $00c0: $35 
	cp		$87			; $00c1: $fe $87 
	jr		nc, +++			; $00c3: $30 $07 
---	add		$08			; $00c5: $c6 $08 
	ldh		(R_LYC), a		; $00c7: $e0 $45 
	ld		($c0a5), a		; $00c9: $ea $a5 $c0 

	; now grab these registers back and get outta this place
-
+++	pop		hl			; $00cc: $e1 
	pop		af			; $00cd: $f1 
	reti					; $00ce: $d9 

	; this turns off the WINDOW
+	ld		hl, $ff40		; $00cf: $21 $40 $ff 
	res		5, (hl)			; $00d2: $cb $ae 
	ld		a, $0f			; $00d4: $3e $0f 
	ldh		(R_LYC), a		; $00d6: $e0 $45 
	xor		a			; $00d8: $af 
	ld		($c0a5), a		; $00d9: $ea $a5 $c0 
	jr		-			; $00dc: $18 $ee 

	; it goes down here if
	; the credits have been rollin up to line 40h
++	push		af			; $00de: $f5 
	ldh		a, ($fb)		; $00df: $f0 $fb 
	and		a			; $00e1: $a7 
	jr		z, +			; $00e2: $28 $06 
	dec		a			; $00e4: $3d 
	ldh		($fb), a		; $00e5: $e0 $fb 
-	pop		af			; $00e7: $f1 
	jr		---			; $00e8: $18 $db 
+	ld		a, $ff			; $00ea: $3e $ff 
	ld		($c0ad), a		; $00ec: $ea $ad $c0 
	jr		-			; $00ef: $18 $f6 
; end routine

.org $100

; cartridge header
; program entry
	nop					; $0100: $00 
	jp		$0150			; $0101: $c3 $50 $01 

; empty header bytes fill
.org $144
.db $00 $00
.org $149
.db $00
.org $14c
.db $00
; end empty header bytes fill

.org $150

; end of cartridge header
	jp		INIT			; $0150: $c3 $85 $01 

; routine
	call		$3ed1			; $0153: $cd $d1 $3e 
	ldh		a, ($41)		; $0156: $f0 $41 
	and		$03			; $0158: $e6 $03 
	jr		nz, -$06			; $015a: $20 $fa 
	ld		b, (hl)			; $015c: $46 
	ldh		a, ($41)		; $015d: $f0 $41 
	and		$03			; $015f: $e6 $03 
	jr		nz, -$06			; $0161: $20 $fa 
	ld		a, (hl)			; $0163: $7e 
	and		b			; $0164: $a0 
	ret					; $0165: $c9 
; end routine

; routine
; adds numbers to the score
; and converts to decimal
; takes amount de and adds to score
ADD_SCORE:
	ldh		a, ($9f)		; $0166: $f0 $9f 
	and		a			; $0168: $a7 
	ret		nz			; $0169: $c0 
	ld		a, e			; $016a: $7b 
	ld		hl, $c0a0		; $016b: $21 $a0 $c0 
	add		(hl)			; $016e: $86 
	daa					; $016f: $27 
	ldi		(hl), a			; $0170: $22 
	ld		a, d			; $0171: $7a 
	adc		(hl)			; $0172: $8e 
	daa					; $0173: $27 
	ldi		(hl), a			; $0174: $22 
	ld		a, $00			; $0175: $3e $00 
	adc		(hl)			; $0177: $8e 
	daa					; $0178: $27 
	ld		(hl), a			; $0179: $77 
	ld		a, $01			; $017a: $3e $01 
	ldh		($b1), a		; $017c: $e0 $b1 
	ret		nc			; $017e: $d0 
	ld		a, $99			; $017f: $3e $99 
	ldd		(hl), a			; $0181: $32 
	ldd		(hl), a			; $0182: $32 
	ld		(hl), a			; $0183: $77 
	ret					; $0184: $c9 
; end routine

; looks like an init routine
INIT:
	; disable interrupts for now
	; but setup lcd stat and vblank interrupts
	ld		a, $03			; INIT: $3e $03 
	di					; $0187: $f3 
	ldh		(R_IF), a		; $0188: $e0 $0f 
	ldh		(R_IE), a		; $018a: $e0 $ff 
	; and use oam lcd stat interrupt
	ld		a, $40			; $018c: $3e $40 
	ldh		(R_STAT), a		; $018e: $e0 $41 

	; reset scroll y and x
	xor		a			; $0190: $af 
	ldh		(R_SCY), a		; $0191: $e0 $42 
	ldh		(R_SCX), a		; $0193: $e0 $43 

	; reset scroll
	ldh		(r_scroll), a		; $0195: $e0 $a4 

	; keep the lcd on but turn off the layers
	ld		a, $80			; $0197: $3e $80 
	ldh		(R_LCDC), a		; $0199: $e0 $40 

	; wait for lcd
-	ldh		a, (R_LY)		; $019b: $f0 $44 
	cp		$94			; $019d: $fe $94 
	jr		nz, -			; $019f: $20 $fa 

	; turn off the lcd but enable obj and bg layers
	ld		a, $03			; $01a1: $3e $03 
	ldh		(R_LCDC), a		; $01a3: $e0 $40 

	; load a 'normal' pallete for bg and obp0
	ld		a, $e4			; $01a5: $3e $e4 
	ldh		(R_BGP), a		; $01a7: $e0 $47 
	ldh		(R_OBP0), a		; $01a9: $e0 $48 
	; and this single color pallete for obp1
	ld		a, $54			; $01ab: $3e $54 
	ldh		(R_OBP1), a		; $01ad: $e0 $49 

	; init sound control registers
	ld		hl, $ff26		; $01af: $21 $26 $ff 
	ld		a, $80			; $01b2: $3e $80 
	ldd		(hl), a			; $01b4: $32 
	ld		a, $ff			; $01b5: $3e $ff 
	ldd		(hl), a			; $01b7: $32 
	ld		(hl), $77		; $01b8: $36 $77 

	; point stack to top of wram0
	ld		sp, $cfff		; $01ba: $31 $ff $cf 

	; clear all wram and cart sram
	xor		a			; $01bd: $af 
	ld		hl, $dfff		; $01be: $21 $ff $df 
	ld		c, $40			; $01c1: $0e $40 
	ld		b, $00			; $01c3: $06 $00 
-	ldd		(hl), a			; $01c5: $32 
	dec		b			; $01c6: $05 
	jr		nz, -			; $01c7: $20 $fc 
	dec		c			; $01c9: $0d 
	jr		nz, -			; $01ca: $20 $f9 

	; clear vram
	ld		hl, $9fff		; $01cc: $21 $ff $9f 
	ld		c, $20			; $01cf: $0e $20 
	xor		a			; $01d1: $af 
	ld		b, $00			; $01d2: $06 $00 
-	ldd		(hl), a			; $01d4: $32 
	dec		b			; $01d5: $05 
	jr		nz, -			; $01d6: $20 $fc 
	dec		c			; $01d8: $0d 
	jr		nz, -			; $01d9: $20 $f9 

	; clear oam
	ld		hl, $feff		; $01db: $21 $ff $fe 
	ld		b, $00			; $01de: $06 $00 
-	ldd		(hl), a			; $01e0: $32 
	dec		b			; $01e1: $05 
	jr		nz, -			; $01e2: $20 $fc 

	;  clear high ram
	ld		hl, $fffe		; $01e4: $21 $fe $ff 
	ld		b, $80			; $01e7: $06 $80 
-	ldd		(hl), a			; $01e9: $32 
	dec		b			; $01ea: $05 
	jr		nz, -			; $01eb: $20 $fc 

	; copy 12 byte string into hram @b6h
	; from rom @3f7d
	ld		c, $b6			; $01ed: $0e $b6 
	ld		b, $0c			; $01ef: $06 $0c 
	ld		hl, HRAM_ROUTINE_00	; $01f1: $21 $7d $3f 
-	ldi		a, (hl)			; $01f4: $2a 
	ld		($ff00+c), a		; $01f5: $e2 
	inc		c			; $01f6: $0c 
	dec		b			; $01f7: $05 
	jr		nz, -			; $01f8: $20 $fa 

	; init hram and wram vars
	; sets the level to 0
	xor		a			; $01fa: $af 
	ldh		(r_level), a		; $01fb: $e0 $e4 
	; set the world name to world 1-1
	ld		a, $11			; $01fd: $3e $11 
	ldh		(r_world), a		; $01ff: $e0 $b4 
	; still dont know what this place in wram is
	ld		($c0a8), a		; $0201: $ea $a8 $c0 
	; still dont know what this place is either
	ld		a, $02			; $0204: $3e $02 
	ld		($c0dc), a		; $0206: $ea $dc $c0 
	; this is the state var, setting it to init title screen
	ld		a, $0e			; $0209: $3e $0e 
	ldh		(r_state), a		; $020b: $e0 $b3 

	; select rom bank 3!
	ld		a, $03			; $020d: $3e $03 
	ld		($2000), a		; $020f: $ea $00 $20 

	; init more wram and hram vars
	ld		($c0a4), a		; $0212: $ea $a4 $c0 
	ld		a, $00			; $0215: $3e $00 
	ld		($c0e1), a		; $0217: $ea $e1 $c0 
	ldh		($9a), a		; $021a: $e0 $9a 

	; init sound
	call		SOUND_INIT_ALIAS	; $021c: $cd $f3 $7f 

	; switch to rom bank 2
	ld		a, $02			; $021f: $3e $02 
	ld		($2000), a		; $0221: $ea $00 $20 

	; init an hram var
	; still dont kno what it is
	ldh		(r_current_bank), a		; $0224: $e0 $fd 

	; load this var from wram1
	; still dont know
	; this right here is where the looping actually happens
ENGINE_LOOP:
	ld		a, ($da1d)		; $0226: $fa $1d $da 
	cp		$03			; $0229: $fe $03 
	jr		nz, +			; $022b: $20 $0b 
	; skip if that var is not 3
	; so if its 3 do this:
	; init that var to $ff
	ld		a, $ff			; $022d: $3e $ff 
	ld		($da1d), a		; $022f: $ea $1d $da 
	; call these routines
	; this dies if necessary
	call		DEATH			; $0232: $cd $e8 $09 
	; this draws the character enttiies?
	call		ROUTINE_01		; $0235: $cd $2d $17 

	; copy an hram var to another one
+	ldh		a, (r_current_bank)		; $0238: $f0 $fd 
	ldh		(r_previous_bank), a		; $023a: $e0 $e1 
	; then set it to 3
	ld		a, $03			; $023c: $3e $03 
	ldh		(r_current_bank), a		; $023e: $e0 $fd 
	; switch to bank 3 and read the joypad
	ld		($2000), a		; $0240: $ea $00 $20 
	call		READ_JOYPAD		; $0243: $cd $f2 $47 

	; replace the hram var
	ldh		a, (r_previous_bank)		; $0246: $f0 $e1 
	ldh		(r_current_bank), a		; $0248: $e0 $fd 
	; and switch to whatever bank it was!
	ld		($2000), a		; $024a: $ea $00 $20 

	; if 9fh is set, then dont care if paused
	; load an hram var and skip ahead if > 0
	ldh		a, ($9f)		; $024d: $f0 $9f 
	and		a			; $024f: $a7 
	jr		nz, +			; $0250: $20 $08 

	; if in game, handle the in game controls, the pausing and reseting
	; if 0:
	; call this routine
	; it checks some buttons or something
	; this checks for pausing or reseting
	call		PAUSE_OR_RESET		; $0252: $cd $c3 $07 
	; go straight to the halt loop
	; if this hram var is set (not 0)
	; if its PAUSED, then just go to the halt, otherwise do this stuff
	ldh		a, ($b2)		; $0255: $f0 $b2 
	and		a			; $0257: $a7 
	jr		nz, ++			; $0258: $20 $3c 

	; so its not paused, so keep goin

	; these two counters, count them down to 0
	; count down all the 2 bytes starting here to 0
	; point to this hram place
+	ld		hl, $ffa6		; $025a: $21 $a6 $ff 
	; put 2 on the counter
	ld		b, $02			; $025d: $06 $02 
	; grab a byte
-	ld		a, (hl)			; $025f: $7e 
	and		a			; $0260: $a7 
	; if its not 0, then count it down
	jr		z, +			; $0261: $28 $01 
	dec		(hl)			; $0263: $35 
	; and go to the next byte
+	inc		l			; $0264: $2c 
	; and count the counter down
	dec		b			; $0265: $05 
	; next byte, or done
	jr		nz, -			; $0266: $20 $f7 

	; grab this same hram var from before and skip if it = 0 this time
	ldh		a, ($9f)		; $0268: $f0 $9f 
	and		a			; $026a: $a7 
	jr		z, +			; $026b: $28 $26 

	; or if its not in game, if its on the title screen
	; then handle pressing start to start the game, and starting the demo
	; also here if 9fh is clear, skip all of this
	; if > 0:
	; check bit 3 of hram var $80 (start button?)
	ldh		a, (r_pad)		; $026d: $f0 $80 
	bit		3, a			; $026f: $cb $5f 
	jr		nz, +++			; $0271: $20 $10 

	; (start not pressed?):
	; grab this hram var
	; if lower nybble is set, then get outta here
	; basically this hram var counts up
	; and everytime it goes over 15, do the stuff below
	ldh		a, (r_countup)		; $0273: $f0 $ac 
	and		$0f			; $0275: $e6 $0f 
	jr		nz, +			; $0277: $20 $1a 
	; but otherwise:
	; grab this byte from wram
	; this is a countdown until demo!
	ld		hl, demo_counter	; $0279: $21 $d7 $c0 
	ld		a, (hl)			; $027c: $7e 
	and		a			; $027d: $a7 
	; and act like start IS pressed if its 0
	jr		z, +++			; $027e: $28 $03 
	; otherwise, count it down
	; (oh! so, its just a countdown until auto pressing start? probs)
	dec		(hl)			; $0280: $35 
	; and get on with lives
	jr		+			; $0281: $18 $10 

	; if ur in the demo, and u press start, get out of the demo
	; OR if..
	; (start pressed?):
	; grab this one hram var
	; and ignore start being pressed if its set
+++	ldh		a, (r_state)		; $0283: $f0 $b3 
	and		a			; $0285: $a7 
	jr		nz, +			; $0286: $20 $0b 
	; but otherwise!!
	; set bank = 2 and set that var so this only counts for 1 tick
	; RIGHT, so, if start isn't pressed and this is the first tick
	; then we're gonna init the start screen!
	ld		a, $02			; $0288: $3e $02 
	ld		($2000), a		; $028a: $ea $00 $20 
	ldh		(r_current_bank), a		; $028d: $e0 $fd 
	ld		a, $0e			; $028f: $3e $0e 
	ldh		(r_state), a		; $0291: $e0 $b3 

	; alright
	; do a rst_jp to the address index in hram $b3
	; and anyway, do the state's routine
+	call		CALL_STATE_ROUTINE		; $0293: $cd $a3 $02 

-	; halt loop: wait for interrupts
++	halt					; $0296: $76 
	; and stay halted until a vblank occured! ignore non vblank interrupts
	; as long as this var is not set, keep halting
	; this $85 hram var is whether or not a engine loop iteration is queued yet
	ldh		a, (r_engine_loop_request)	; $0297: $f0 $85 
	and		a				; $0299: $a7 
	jr		z, -				; $029a: $28 $fa 
	; otherwise:
	; first reset that flag that triggers this
	; clear that queue
	xor		a				; $029c: $af 
	ldh		(r_engine_loop_request), a	; $029d: $e0 $85 
	; then go back
	jr		ENGINE_LOOP			; $029f: $18 $85 
; end init routine

	; this is an infinite loop, if its ever possible to reach here
-	jr		-			; $02a1: $18 $fe 

; routine
; this routine jumps to the approprate game state handler!!
; this routine jumps to a routine
; given the index of an address to jump to
; in the rst jump address array below
; okay, so i think this routine
; takes the STATE var
; and runs an idle routine based on the state
CALL_STATE_ROUTINE:
	; load the index of the address to jump to from the table rst_jp table below
	ldh		a, (r_state)		; $02a3: $f0 $b3 
	; and call this rst routine with it
	rst		$28			; $02a5: $ef 
; end routine

; here are addresses that get loaded and jumped to by rst $28
; the GAME STATE HANDLER ROUTINES
; mostly main game states
.dw GAME_LOOP
.dw DEATH_RESET		; die?
.dw ROUTINE_0F		; starts level?
.dw PREPARE_DEATH_TOSS	; waits then dies?
.dw DEATH_TOSS		; death toss mario
.dw INIT_LEVEL_WIN	; win, loading time onto score, then next
.dw FINISH_LEVEL	; next level
.dw ROUTINE_1D		; wait, then win
.dw NEXT_LEVEL		; next level also?
.dw ENTER_PIPE_DOWN	; fall through ground, then appear from sky
.dw EXIT_PIPE		; immediately appear from sky
.dw ENTER_PIPE_RIGHT	; exit screen to the right, reappear, then die?
.dw ENTER_PIPE_UP	; exit screen upwards, the fall from sky
.dw ROUTINE_13		; unsure
.dw INIT_TITLE_SCREEN	; indeed, init to the title screen
.dw TITLE_SCREEN_IDLE	; indeed, idleing, for the title screen

; mostly bonus stage states
; also some princess stuff
; bank 02, btw
.dw RETURN		; unsure, seems to freeze everything but sound
.dw ENTER_GAME		; enters game, or demo if start's pressed
.dw ENTER_BONUS		; enter bonus screen
.dw BONUS_IDLE_0	; bonus screen idle
.dw BONUS_IDLE_1_ALIAS	; more bonus idle
.dw BONUS_IDLE_2_ALIAS	; more bonus idle
.dw BONUS_IDLE_3	; more bonus idle
.dw BONUS_CHOOSE_ALIAS	; chooses bonus
.dw BONUS_WAIT_0_ALIAS	; waits then chooses bonus?
.dw BONUS_WAIT_1_ALIAS	; waits then chooses bonus?
.dw BONUS_OUTRO_ALIAS	; bonus screen outro
.dw ROUTINE_1A		; next level
.dw ENTER_PRINCESS	; enter princess
.dw ENTER_PRINCESS_2	; enter princess also
.dw ROUTINE_1B		; infinite loop
.dw START_WALKING_PRINCESS	; start walking princess

; mostly princes stuff
.dw WALK_RIGHT		; start walking to the right forever
.dw START_PRINCESS	; immediatly start princess scene
.dw START_THANK_YOU	; start thank you
.dw WALK_INTO_THANK_YOU	; walk into thank you
.dw POST_THANK_YOU	; post thank you
.dw ENTER_PRINCESS_TRANSFORM	; enter princess transform
.dw PRINCESS_ENEMY_SPAWN; princess enemy spawn
.dw ENTER_PRINCESS_WIN	; enter prince win
.dw WALK_RIGHT		; start walking to right forever (same as above)
.dw ENTER_WIN_THANK_YOU ; enter win thank you
.dw START_THANK_YOU_TEXT	; start typing thank you text
.dw KISS_HEART		; kiss heart
.dw SPAWN_KISS_PARTICLE	; floating particle?
.dw WAIT_THEN_WALK	; wait, then walk
.dw WALK_WITH_PRINCESS	; walk forever right with princess
.dw ENTER_WAIT_THEN_SPEED	; enter wait then speed screen to the right

; mostly credits stuff
.dw WAIT_THEN_SPEED	; wait then speed screen to the right
.dw SPEED_SCREEN_RIGHT	; speed screen right
.dw WIPE_BG		; wipe bg clear
.dw START_CREDITS	; start credits scroll
.dw SCROLL_CREDITS_0	; scrolling credits
.dw SCROLL_CREDITS_1	; scrolling
.dw SCROLL_CREDITS_2	; scrolling
.dw CREDITS_PAUSE	; pause
.dw THE_END		; the end
.dw ENTER_GAME_OVER	; enter gameover
.dw SCROLL_CREDITS_PORTION	; scroll credits up a bit then CHILL
.dw TIME_UP		; display time up, wait, and die restart (lost life)
.dw ROUTINE_1C		; insta die
.dw RETURN_2		; freeze?

; routine
; here is jumped to by a rst
; this probably inits some video stuff
; this inits the title screen
INIT_TITLE_SCREEN:
	; disable lcd
	xor a
	ldh		(R_LCDC), a		; $0323: $e0 $40 
	; disable interrupts
	di					; $0325: $f3 
	; clear this hram var
	; level scroll?
	; i guess it also scrolls the title screen
	ldh		($a4), a		; $0326: $e0 $a4 

	; clear $9f bytes starting at wram
	; this is clearing the OAM copy in wram!!
	; point to start of wram
	ld		hl, $c000		; $0328: $21 $00 $c0 
	; set counter
	ld		b, $9f			; $032b: $06 $9f 
	; clear wram byte
-	ldi		(hl), a			; $032d: $22 
	; dec counter
	dec		b			; $032e: $05 
	jr		nz, -			; $032f: $20 $fc 

	; clear these hram and wram vars
	ldh		($99), a		; $0331: $e0 $99 
	ld		($c0a5), a		; $0333: $ea $a5 $c0 
	ld		($c0ad), a		; $0336: $ea $ad $c0 
	; clear these three wram vars
	ld		hl, $c0d8		; $0339: $21 $d8 $c0 
	ldi		(hl), a			; $033c: $22 
	ldi		(hl), a			; $033d: $22 
	ldi		(hl), a			; $033e: $22 
	; grab this wram var
	ld		a, ($c0e1)		; $033f: $fa $e1 $c0 
	; and put it in this hram var
	ldh		($9a), a		; $0342: $e0 $9a 

	; copy a bunch of data into vram!
	; load the title chr
	ld		hl, TITLE_CHR			; $0344: $21 $1a $79 
	ld		de, $9300			; $0347: $11 $00 $93 
	ld		bc, _sizeof_TITLE_CHR		; $034a: $01 $00 $05 
	call		COPY				; $034d: $cd $c7 $05 
	; load the title bg chr
	ld		hl, TITLE_BG_CHR		; $0350: $21 $1a $7e 
	ld		de, $8800			; $0353: $11 $00 $88 
	ld		bc, _sizeof_TITLE_BG_CHR	; $0356: $01 $70 $01 
	call		COPY				; $0359: $cd $c7 $05 
	; load the selection mushroom tile
	; use this source if that hram var < 1
	ld		hl, (ENTITY_CHR + $83 * $10)	; $035c: $21 $62 $48 
	ldh		a, ($9a)			; $035f: $f0 $9a 
	cp		$01				; $0361: $fe $01 
	jr		c, +				; $0363: $38 $03 
	; otherwise this source
	ld		hl, (ENTITY_CHR + $e4 * $10)	; $0365: $21 $72 $4e 
+	ld		de, $8ac0			; $0368: $11 $c0 $8a 
	ld		bc, $10				; $036b: $01 $10 $00 
	call		COPY				; $036e: $cd $c7 $05 
	; load the font
	ld		hl, FONT_CHR			; $0371: $21 $32 $50 
	ld		de, $9000			; $0374: $11 $00 $90 
	ld		bc, $02c0			; $0377: $01 $c0 $02 
	call		COPY				; $037a: $cd $c7 $05 
	; load the font again
	ld		hl, FONT_CHR			; $037d: $21 $32 $50 
	ld		de, $8000			; $0380: $11 $00 $80 
	ld		bc, $02a0			; $0383: $01 $a0 $02 
	call		COPY				; $0386: $cd $c7 $05 

	; clear the first tile map
	call		CLEAR_MAP_0		; $0389: $cd $b8 $05 

	; clear this hram var
	xor		a			; $038c: $af 
	ldh		($e5), a		; $038d: $e0 $e5 

	; grab this other hram var and save it on the stack
	ldh		a, ($e4)		; $038f: $f0 $e4 
	push		af			; $0391: $f5 

	; this is probably the map to load
	; and replace it with 0ch
	ld		a, $0c			; $0392: $3e $0c 
	ldh		($e4), a		; $0394: $e0 $e4 

	; call this routine with that hram var as 0ch
	; this routine has something to do with loading bg maps
	call		LOAD_MAP		; $0396: $cd $f0 $07 

	; restore that hram var
	pop		af			; $0399: $f1 
	ldh		($e4), a		; $039a: $e0 $e4 

	; fill the first 14h tiles (screenwidth) with tile 3c
	; load 3ch on a
	ld		a, $3c			; $039c: $3e $3c 
	; and point to map0
	ld		hl, $9800		; $039e: $21 $00 $98 
	; and call this
	call		FILL_SCREEN_ROW		; $03a1: $cd $58 $05 

	; this all just puts the upper part of mario where he goes
	ld		hl, $9804		; $03a4: $21 $04 $98 
	ld		(hl), $94		; $03a7: $36 $94 
	ld		hl, $9822		; $03a9: $21 $22 $98 
	ld		(hl), $95		; $03ac: $36 $95 
	inc		l			; $03ae: $2c 
	ld		(hl), $96		; $03af: $36 $96 
	inc		l			; $03b1: $2c 
	ld		(hl), $8c		; $03b2: $36 $8c 
	ld		hl, $982f		; $03b4: $21 $2f $98 
	ld		(hl), $3f		; $03b7: $36 $3f 
	inc		l			; $03b9: $2c 
	ld		(hl), $4c		; $03ba: $36 $4c 
	inc		l			; $03bc: $2c 
	ld		(hl), $4d		; $03bd: $36 $4d 
	
	; point to these two addresse in wram
	ld		hl, $c0a2		; $03bf: $21 $a2 $c0 
	ld		de, $c0c2		; $03c2: $11 $c2 $c0 
	; counter of 3
	ld		b, $03			; $03c5: $06 $03 
	; grab the value at de
	; and if the value at hl is greater
	; then skip below
-	ld		a, (de)			; $03c7: $1a 
	sub		(hl)			; $03c8: $96 
	jr		c, +			; $03c9: $38 $09 
	jr		nz, ++			; $03cb: $20 $15 
	; they are equal:
	; dec both pointers and try again
	; but try a max of 3 times
	dec		e			; $03cd: $1d 
	dec		l			; $03ce: $2d 
	dec		b			; $03cf: $05 
	jr		nz, -			; $03d0: $20 $f5 
	jr		++			; $03d2: $18 $0e 
	; (hl) was greater:
+	ld		hl, $c0a2		; $03d4: $21 $a2 $c0 
	ld		de, $c0c2		; $03d7: $11 $c2 $c0 
	ld		b, $03			; $03da: $06 $03 
	; copy the hl source to the de source
	; three bytes
-	ldd		a, (hl)			; $03dc: $3a 
	ld		(de), a			; $03dd: $12 
	dec		e			; $03de: $1d 
	dec		b			; $03df: $05 
	jr		nz, -			; $03e0: $20 $fa 
	; done, or (dl) was greater:
	; got that de pointer
++	ld		de, $c0c2		; $03e2: $11 $c2 $c0 
	; and this interestingly specificy place in map0
	; THIS IS WHERE THE HIGH SCORE GOES
	ld		hl, $9969		; $03e5: $21 $69 $99 
	; and calling this routine
	; puts 3 certain bytes in map mem?? not sure what it does
	call		DRAW_HIGH_SCORE		; $03e8: $cd $38 $3f 

	; here we are determining whether or not to enable "continue" option
	; put $78 here in wram
	ld		hl, $c004		; $03eb: $21 $04 $c0 
	ld		(hl), $78		; $03ee: $36 $78 
	; grab this wram var
	ld		a, ($c0a6)		; $03f0: $fa $a6 $c0 
	and		a			; $03f3: $a7 
	jr		z, +			; $03f4: $28 $29 

	; if its set, continue:
	; if this hram is < 2...
	ldh		a, ($9a)		; $03f6: $f0 $9a 
	cp		$02			; $03f8: $fe $02 
	jr		c, ++			; $03fa: $38 $02 
	; its not? skip below then
	jr		+			; $03fc: $18 $21 
	; then do this.. that hram is less than 2:
	; COPY "CONTINUE" INTO MAP MEM
	; point to this location in rom
++	ld		hl, CONTINUE_MAP			; $03fe: $21 $46 $04 
	; and this location in map mem
	ld		de, $99c6				; $0401: $11 $c6 $99 
	; we gonna copy $0a bytes from rom to map mem
	ld		b, (CONTINUE_MAP_END - CONTINUE_MAP)	; $0404: $06 $0a 
	; go
-	ldi		a, (hl)			; $0406: $2a 
	ld		(de), a			; $0407: $12 
	inc		e			; $0408: $1c 
	dec		b			; $0409: $05 
	jr		nz, -			; $040a: $20 $fa 

	; done with that
	; filling the first 5 bytes of wram0
	; copy a word at the base of wram0
	ld		hl, $c000		; $040c: $21 $00 $c0 
	ld		(hl), $80		; $040f: $36 $80 
	inc		l			; $0411: $2c 
	ld		(hl), $88		; $0412: $36 $88 
	inc		l			; $0414: $2c 
	; and then copy this wram var after it
	ld		a, ($c0a6)		; $0415: $fa $a6 $c0 
	ld		(hl), a			; $0418: $77 
	; followed by this word
	inc		l			; $0419: $2c 
	ld		(hl), $00		; $041a: $36 $00 
	inc		l			; $041c: $2c 
	ld		(hl), $80		; $041d: $36 $80 

	; skippin here if not gonna draw 'continue'
	; hl pointing at c004h
	; copying another two bytes after it
+	inc		l			; $041f: $2c 
	ld		(hl), $28		; $0420: $36 $28 
	inc		l			; $0422: $2c 
	ld		(hl), $ac		; $0423: $36 $ac 

	; disable all interrupts flags
	xor		a			; $0425: $af 
	ldh		(R_IF), a		; $0426: $e0 $0f 
	; turn on display
	; window map = second map
	; enable bg and obj layers
	ld		a, $c3			; $0428: $3e $c3 
	ldh		($40), a		; $042a: $e0 $40 
	; enable interrupts
	ei					; $042c: $fb 

	; set som hram vars
	; here's setting the STATE VAR to , "done initing, on title screen"
	ld		a, $0f			; $042d: $3e $0f 
	ldh		($b3), a		; $042f: $e0 $b3 
	xor		a			; $0431: $af 
	ldh		($f9), a		; $0432: $e0 $f9 
	; and a wram var
	ld		a, $28			; $0434: $3e $28 
	ld		($c0d7), a		; $0436: $ea $d7 $c0 
	; another hram var
	ldh		($9f), a		; $0439: $e0 $9f 
	; inc this wram var and grab it
	ld		hl, $c0dc		; $043b: $21 $dc $c0 
	inc		(hl)			; $043e: $34 
	ld		a, (hl)			; $043f: $7e 
	; return if its not 3 yet, just go, outta here
	cp		$03			; $0440: $fe $03 
	ret		nz			; $0442: $c0 
	; otherwise, reset it back to 0, then go
	ld		(hl), $00		; $0443: $36 $00 
	ret					; $0445: $c9 
; end routine

CONTINUE_MAP:
.incbin "continue.map"
CONTINUE_MAP_END:

; routine
; ENTRY IS BELOW
; it looks like this happens in the title screen idle state (hram(b3h) = 0fh)
; also, the entry to this routine is down there below
	; start was pressed, i suppose?
	; yes, i tested it
	; if this var is 78h, skip this mess
-	ld		a, ($c004)		; $0450: $fa $04 $c0 
	cp		$78			; $0453: $fe $78 
	jr		z, +			; $0455: $28 $4b 

	; enter: mess:
	; dec this wram var
	; and put back
	ld		a, ($c0a6)		; $0457: $fa $a6 $c0 
	dec		a			; $045a: $3d 
	ld		($c0a6), a		; $045b: $ea $a6 $c0 
	; and copy this wram var to hram
	ld		a, ($c0a8)		; $045e: $fa $a8 $c0 
	ldh		($b4), a		; $0461: $e0 $b4 
	; start a counter at 0
	ld		e, $00			; $0463: $1e $00 
	; now figure out which of these that VAR is
	; 0
	cp		$11			; $0465: $fe $11 
	jr		z, ++			; $0467: $28 $33 
	inc		e			; $0469: $1c 
	; 1
	cp		$12			; $046a: $fe $12 
	jr		z, ++			; $046c: $28 $2e 
	inc		e			; $046e: $1c 
	; 2
	cp		$13			; $046f: $fe $13 
	jr		z, ++			; $0471: $28 $29 
	inc		e			; $0473: $1c 
	; 3
	cp		$21			; $0474: $fe $21 
	jr		z, ++			; $0476: $28 $24 
	inc		e			; $0478: $1c 
	; 4
	cp		$22			; $0479: $fe $22 
	jr		z, ++			; $047b: $28 $1f 
	inc		e			; $047d: $1c 
	; 5
	cp		$23			; $047e: $fe $23 
	jr		z, ++			; $0480: $28 $1a 
	inc		e			; $0482: $1c 
	; 6
	cp		$31			; $0483: $fe $31 
	jr		z, ++			; $0485: $28 $15 
	inc		e			; $0487: $1c 
	; 7
	cp		$32			; $0488: $fe $32 
	jr		z, ++			; $048a: $28 $10 
	inc		e			; $048c: $1c 
	; 8
	cp		$33			; $048d: $fe $33 
	jr		z, ++			; $048f: $28 $0b 
	inc		e			; $0491: $1c 
	; 9
	cp		$41			; $0492: $fe $41 
	jr		z, ++			; $0494: $28 $06 
	inc		e			; $0496: $1c 
	; A
	cp		$42			; $0497: $fe $42 
	jr		z, ++			; $0499: $28 $01 
	inc		e			; $049b: $1c 
	; and else: B
	; anyway, load up that count id
++	ld		a, e			; $049c: $7b 
	; store it here in hram
--	ldh		($e4), a		; $049d: $e0 $e4 
	; and scram to the post start press stuff
	jp		++++			; $049f: $c3 $3d $05 

	; this is the skip stuff
	; clear that wram var
+	xor		a			; $04a2: $af 
	ld		($c0a6), a		; $04a3: $ea $a6 $c0 
	; grab this hram var
	ldh		a, ($9a)		; $04a6: $f0 $9a 
	cp		$02			; $04a8: $fe $02 
	; if its 2 or more, scram to post start press stuff
	jp		nc, ++++		; $04aa: $d2 $3d $05 
	; otherwise, store this in hram var
	ld		a, $11			; $04ad: $3e $11 
	ldh		($b4), a		; $04af: $e0 $b4 
	; and put 0 in hram(e4h) and scram to post start stuff
	xor		a			; $04b1: $af 
	jr		--			; $04b2: $18 $e9 

	; select was pressed, i suppose?
	; yes, i tested it
	; if this var is set, then do this stuff
--	ld		a, ($c0a6)		; $04b4: $fa $a6 $c0 
	and		a			; $04b7: $a7 
	jr		z, +			; $04b8: $28 $14 
	; this stuff:
	; grab this var and flip the top 5 bits?
	; and put it back, and get on with life, below
	ld		hl, $c004		; $04ba: $21 $04 $c0 
	ld		a, (hl)			; $04bd: $7e 
	xor		$f8			; $04be: $ee $f8 
	ld		(hl), a			; $04c0: $77 
	jr		+			; $04c1: $18 $0b 

TITLE_SCREEN_IDLE:
	; i belevie this is where the masked input was stared
	; so i guess this checks if start was pressed, oder?
	ldh		a, ($81)		; $04c3: $f0 $81 
	ld		b, a			; $04c5: $47 
	bit		3, b			; $04c6: $cb $58 
	; and goes up there if so?
	jr		nz, -			; $04c8: $20 $86 
	; and this is if select is pressed
	bit		2, b			; $04ca: $cb $50 
	; so go up there if so
	jr		nz, --			; $04cc: $20 $e6 

	; after select stuff, or no buttons were pressed
	; check hram var
+	ldh		a, ($9a)		; $04ce: $f0 $9a 
	cp		$02			; $04d0: $fe $02 
	jr		c, +			; $04d2: $38 $45 

	; do this ifs at least 2:
	; is a button pressed?
	bit		0, b			; $04d4: $cb $40 
	jr		z, ++			; $04d6: $28 $1d 

	; a is pressed:
	; inc this var and compare the bottom bits with 4
	ldh		a, ($b4)		; $04d8: $f0 $b4 
	inc		a			; $04da: $3c 
	ld		b, a			; $04db: $47 
	and		$0f			; $04dc: $e6 $0f 
	cp		$04			; $04de: $fe $04 
	; then load the unaltered back
	ld		a, b			; $04e0: $78 
	; and if it is 4, add $0d
	jr		nz, +++			; $04e1: $20 $02 
	add		$0d			; $04e3: $c6 $0d 
	; put it back
+++	ldh		($b4), a		; $04e5: $e0 $b4 
	; and then grab and inc this var and compare with $c
	ldh		a, ($e4)		; $04e7: $f0 $e4 
	inc		a			; $04e9: $3c 
	cp		$0c			; $04ea: $fe $0c 
	; if $c then put 11h in this hram var
	jr		nz, +++			; $04ec: $20 $05 
	ld		a, $11			; $04ee: $3e $11 
	ldh		($b4), a		; $04f0: $e0 $b4 
	; and clear this var
	xor		a			; $04f2: $af 
	; and put it back
+++	ldh		($e4), a		; $04f3: $e0 $e4 

	; a was not pressed:
	; point here in wram
++	ld		hl, $c008		; $04f5: $21 $08 $c0 
	; make bc = $7800+($b4)
	ldh		a, ($b4)		; $04f8: $f0 $b4 
	ld		b, $78			; $04fa: $06 $78 
	ld		c, a			; $04fc: $4f 
	; put the top bits on bottom
	and		$f0			; $04fd: $e6 $f0 
	swap		a			; $04ff: $cb $37 
	; store $78
	ld		(hl), b			; $0501: $70 
	inc		l			; $0502: $2c 
	; and again?
	ld		(hl), $78		; $0503: $36 $78 
	inc		l			; $0505: $2c 
	; and then those top bits?
	ldi		(hl), a			; $0506: $22 
	inc		l			; $0507: $2c 
	; and then grab the unalterned var
	ld		a, c			; $0508: $79 
	; and do the bottom bits
	and		$0f			; $0509: $e6 $0f 
	; store $78 again
	ld		(hl), b			; $050b: $70 
	inc		l			; $050c: $2c 
	; then 88h
	ld		(hl), $88		; $050d: $36 $88 
	inc		l			; $050f: $2c 
	; and those bottom bits
	ldi		(hl), a			; $0510: $22 
	inc		l			; $0511: $2c 
	; and $78 again!
	ld		(hl), b			; $0512: $70 
	inc		l			; $0513: $2c 
	; and then $80
	ld		(hl), $80		; $0514: $36 $80 
	inc		l			; $0516: $2c 
	; and then 29h
	ld		(hl), $29		; $0517: $36 $29 
	; not sure what all that's about but
	; anyway
	; skip here if its less than 2
	; if this var is set, leave
+	ld		a, ($c0d7)		; $0519: $fa $d7 $c0 
	and		a			; $051c: $a7 
	ret		nz			; $051d: $c0 

	; else
	; grab this and shift it left
	; times 2 it
	ld		a, ($c0dc)		; $051e: $fa $dc $c0 
	sla		a			; $0521: $cb $27 
	; and make a de word pointer out of it
	; an offset to hl, $552
	ld		e, a			; $0523: $5f 
	ld		d, $00			; $0524: $16 $00 
	ld		hl, $0552		; $0526: $21 $52 $05 
	add		hl, de			; $0529: $19 
	; now we got a pointer to a word on hl
	; load up the two bytes onto these hram places
	ldi		a, (hl)			; $052a: $2a 
	ldh		($b4), a		; $052b: $e0 $b4 
	ld		a, (hl)			; $052d: $7e 
	ldh		($e4), a		; $052e: $e0 $e4 
	; store 50 here, so never coming here next time, leaving early (above)
	ld		a, $50			; $0530: $3e $50 
	ld		($c0d7), a		; $0532: $ea $d7 $c0 
	; and here's setting the STATE to 11h again
	ld		a, $11			; $0535: $3e $11 
	ldh		($b3), a		; $0537: $e0 $b3 
	; and clearing this var
	xor		a			; $0539: $af 
	ldh		($9a), a		; $053a: $e0 $9a 
	; and done
	ret					; $053c: $c9 

	; last thing to do after start button press stuff
	; set the STATE to 11h!
++++	ld		a, $11			; $053d: $3e $11 
	ldh		($b3), a		; $053f: $e0 $b3 
	; make iflags off, still dunno why
	xor		a			; $0541: $af 
	ldh		(R_IF), a		; $0542: $e0 $0f 
	; and clear goes this hram var
	ldh		($9f), a		; $0544: $e0 $9f 
	; and so goes this wram var
	ld		($c0a4), a		; $0546: $ea $a4 $c0 
	; put $ff in this wram1 place
	dec		a			; $0549: $3d 
	ld		($dfe8), a		; $054a: $ea $e8 $df 
	; vblank, stat, and timer interrupts enabled
	ld		a, $07			; $054d: $3e $07 
	ldh		($ff), a		; $054f: $e0 $ff 
	; done
	ret					; $0551: $c9 
; end routine

	ld		de, $1200		; $0552: $11 $00 $12 
	ld		bc, $0833		; $0555: $01 $33 $08 

; routine
; copy a starting at hl for 14h bytes
; which is the width of the screen in tiles
; fill byte: a
; destination start: hl
FILL_SCREEN_ROW:
	ld		b, $14			; $0558: $06 $14 
-	ldi		(hl), a			; $055a: $22 
	dec		b			; $055b: $05 
	jr		nz, -			; $055c: $20 $fc 
	ret					; $055e: $c9 
; end routine 

; routine
; this is probably the state of preparing to enter the game world!
ENTER_GAME:
	; disable lcd
	xor		a			; $055f: $af 
	ldh		(R_LCDC), a		; $0560: $e0 $40 
	; disable interrupts
	di					; $0562: $f3 
	; this hram flag skips
	ldh		a, ($9f)		; $0563: $f0 $9f 
	and		a			; $0565: $a7 
	jr		nz, +			; $0566: $20 $0c 
	; but if its not set,
	; clear all these wram vars and an hram var
	xor		a			; $0568: $af 
	ld		($c0a0), a		; $0569: $ea $a0 $c0 
	ld		($c0a1), a		; $056c: $ea $a1 $c0 
	ld		($c0a2), a		; $056f: $ea $a2 $c0 
	ldh		($fa), a		; $0572: $e0 $fa 
	; call these routines
	; load the game graphics
+	call		LOAD_GAME_CHR		; $0574: $cd $d0 $05 
	; clear map 0 again
	call		CLEAR_MAP_0		; $0577: $cd $b8 $05 
	; copy $2c, i guess blank tile? for 5fh tiles
	; into map1 memory
	ld		hl, $9c00		; $057a: $21 $00 $9c 
	ld		b, $5f			; $057d: $06 $5f 
	ld		a, $2c			; $057f: $3e $2c 
-	ldi		(hl), a			; $0581: $22 
	dec		b			; $0582: $05 
	jr		nz, -			; $0583: $20 $fc 

	; load the hud map
	call		LOAD_HUD		; $0585: $cd $f8 $05 
	; set lyc to compare on line fh
	ld		a, $0f			; $0588: $3e $0f 
	ldh		(R_LYC), a		; $058a: $e0 $45 
	; start timer at 16384hz
	; timer is used for sound engine
	ld		a, $07			; $058c: $3e $07 
	ldh		(R_TAC), a		; $058e: $e0 $07 
	; set window y then x position
	ld		hl, WY			; $0590: $21 $4a $ff 
	ld		(hl), $85		; $0593: $36 $85 
	; next is wx
	inc		l			; $0595: $2c 
	ld		(hl), $60		; $0596: $36 $60 
	; set the timer module (tuning how often it goes off)
	; setting it to 0 tho, hm
	xor		a			; $0598: $af 
	ldh		(R_TMA), a		; $0599: $e0 $06 
	; and again, clearing IF, don't know what the purpose of that is
	; i guess its just discarding any interrupts that might be trying to take place?
	ldh		(R_IF), a		; $059b: $e0 $0f 
	; a = ffh
	dec		a			; $059d: $3d 
	; setting these hram vars
	ldh		($a7), a		; $059e: $e0 $a7 
	ldh		($b1), a		; $05a0: $e0 $b1 
	; and setting this hram var
	ld		a, $5b			; $05a2: $3e $5b 
	ldh		($e9), a		; $05a4: $e0 $e9 
	; call these routines
	; still don't know what this routine does
	call		ROUTINE_0B		; $05a6: $cd $39 $24 
	; here inits game vars and displays some info
	call		INIT_GAME_VARS		; $05a9: $cd $11 $3d 
	call		DISPLAY_COIN_COUNT	; $05ac: $cd $12 $1c 
	call		DISPLAY_LIFE_COUNT	; $05af: $cd $4d $1c 
	; and grab this register, and call this routine with it
	; whatever this is, it loads some specific graphics
	; depending on arg
	; also switches state to 02
	ldh		a, ($b4)		; $05b2: $f0 $b4 
	call		ROUTINE_0D		; $05b4: $cd $64 $0d 
	; and done
RETURN:
	ret					; $05b7: $c9 
; end routine

; routine
; copy tile $2c into the first tile map memory
; looks empty
CLEAR_MAP_0:
	ld		hl, $9bff		; $05b8: $21 $ff $9b 
	ld		bc, $0400		; $05bb: $01 $00 $04 
-	ld		a, $2c			; $05be: $3e $2c 
	ldd		(hl), a			; $05c0: $32 
	dec		bc			; $05c1: $0b 
	ld		a, b			; $05c2: $78 
	or		c			; $05c3: $b1 
	jr		nz, -			; $05c4: $20 $f8 
	ret					; $05c6: $c9 
; end routine

; copy routine
; hl = source
; de = destination
; bc = length
COPY:
-	ldi		a, (hl)			; $05c7: $2a 
	ld		(de), a			; $05c8: $12 
	inc		de			; $05c9: $13 
	dec		bc			; $05ca: $0b 
	ld		a, b			; $05cb: $78 
	or		c			; $05cc: $b1 
	jr		nz, -			; $05cd: $20 $f8 
	ret					; $05cf: $c9 
; end routine

; routine
; load some chr up for the game
LOAD_GAME_CHR:
	; unsure why it couldn't have just copied it all in one go
	; since they are right next to each other in rom
	; shrug
	; this looks like world tiles
	; copy these tiles into the third tile slot
	ld		hl, WORLD_CHR		; $05d0: $21 $32 $50 
	ld		de, $9000		; $05d3: $11 $00 $90 
	ld		bc, _sizeof_WORLD_CHR	; $05d6: $01 $00 $08 
	call		COPY
	; copy these tiles into the first two tile slots
	; this looks like entity tiles
	ld		hl, ENTITY_CHR		; $05dc: $21 $32 $40 
	ld		de, $8000		; $05df: $11 $00 $80 
	ld		bc, _sizeof_ENTITY_CHR	; $05e2: $01 $00 $10 
	call		COPY			; $05e5: $cd $c7 $05 
	; and copy this 8byte string from rom into wram
	; but... actually its 16bytes
	; and its only copying the second byte of each 8 words
	; because its starting on an odd byte (so not first byte)
	; is this... a 1bit conversion of the fire tile? (or whatev it is)
	; unsure
	ld		hl, (WORLD_CHR + $5d * $10 + 1)		; $05e8: $21 $03 $56 
	ld		de, $c600		; $05eb: $11 $00 $c6 
	ld		b, $08			; $05ee: $06 $08 
-	ldi		a, (hl)			; $05f0: $2a 
	ld		(de), a			; $05f1: $12 
	inc		hl			; $05f2: $23 
	inc		de			; $05f3: $13 
	dec		b			; $05f4: $05 
	jr		nz, -			; $05f5: $20 $f9 
	; done
	ret					; $05f7: $c9 
; end routine 

; routine
; to do with setting up the game to enter
; yeah, loads the hud window on the top of the game screen
LOAD_HUD:
	; load up 2 rows of map data onto the screen
	ld		hl, HUD_MAP		; $05f8: $21 $87 $3f 
	ld		de, $9800		; $05fb: $11 $00 $98 
	ld		b, $02			; $05fe: $06 $02 
-	ldi		a, (hl)			; $0600: $2a 
	ld		(de), a			; $0601: $12 
	inc		e			; $0602: $1c 
	ld		a, e			; $0603: $7b 
	and		$1f			; $0604: $e6 $1f 
	; here waits til the end of the screen width
	cp		$14			; $0606: $fe $14 
	jr		nz, -			; $0608: $20 $f6 
	; here's going to the 2nd row
	ld		e, $20			; $060a: $1e $20 
	dec		b			; $060c: $05 
	jr		nz, -			; $060d: $20 $f1 
	ret					; $060f: $c9 
; end routine

; routine
; state 0
; this is one of the possible states (aside from $d)
; after routine_0f
; this is probably the main game loop???????
GAME_LOOP:
	; lots of calls here
	; looks like a game loop
	; anyway
	; this has something to do with loading the level as it comes
	call		ROUTINE_14		; $0610: $cd $8f $21 
	; and here handle entity collisions
	call		ENTITY_COLLISIONS	; $0613: $cd $37 $08 
	; switch to bank 3 (fourth)
	ldh		a, ($fd)		; $0616: $f0 $fd 
	ldh		($e1), a		; $0618: $e0 $e1 
	ld		a, $03			; $061a: $3e $03 
	ldh		($fd), a		; $061c: $e0 $fd 
	ld		($2000), a		; $061e: $ea $00 $20 
	; call this
	; unsure what it does
	; overflows, i think, word at wram(c208h)?
	call		ROUTINE_15		; $0621: $cd $fc $48 
	; what is this series?
	; it might not even be a jumping specific funciton, dunno
	; mario jumping?
	ld		bc, $c208		; $0624: $01 $08 $c2 
	ld		hl, $2164		; $0627: $21 $64 $21 
	call		JUMPING			; $062a: $cd $0d $49 
	; unknown
	ld		bc, $c218		; $062d: $01 $18 $c2 
	ld		hl, $2164		; $0630: $21 $64 $21 
	call		JUMPING			; $0633: $cd $0d $49 
	; unknown
	ld		bc, $c228		; $0636: $01 $28 $c2 
	ld		hl, $2164		; $0639: $21 $64 $21 
	call		JUMPING			; $063c: $cd $0d $49 
	; unknown
	ld		bc, $c238		; $063f: $01 $38 $c2 
	ld		hl, $2164		; $0642: $21 $64 $21 
	call		JUMPING			; $0645: $cd $0d $49 
	; unknown
	ld		bc, $c248		; $0648: $01 $48 $c2 
	ld		hl, $2164		; $064b: $21 $64 $21 
	call		JUMPING			; $064e: $cd $0d $49 

	; now what are these
	; donte know what this is
	call		$4a94			; $0651: $cd $94 $4a 
	; this lets the jump and run buttons work
	call		$498b			; $0654: $cd $8b $49 
	; dunno what this is
	call		$4aea			; $0657: $cd $ea $4a 
	; this has something to do with blocks
	; and moving them
	; and colliding with them
	; and punching them
	call		$4b3c			; $065a: $cd $3c $4b 
	; dont know
	call		$4b6f			; $065d: $cd $6f $4b 
	; this does the grow animation when get mushroom?
	call		$4b8a			; $0660: $cd $8a $4b 
	; this does shrink animation when get hit when big?
	call		$4bb5			; $0663: $cd $b5 $4b 

	; this switches back to old bank
	ldh		a, ($e1)		; $0666: $f0 $e1 
	ldh		($fd), a		; $0668: $e0 $fd 
	ld		($2000), a		; $066a: $ea $00 $20 

	; dont know
	call		$1f24			; $066d: $cd $24 $1f 
	; this spawns shrooms when u hit shroom blocks
	; also spawns enemies and other entities that need spawning!
	call		$2488			; $0670: $cd $88 $24 

	; switch to bank 02 (third)
	ldh		a, ($fd)		; $0673: $f0 $fd 
	ldh		($e1), a		; $0675: $e0 $e1 
	ld		a, $02			; $0677: $3e $02 
	ldh		($fd), a		; $0679: $e0 $fd 
	ld		($2000), a		; $067b: $ea $00 $20 

	; this spawns coins and other particles
	call		$5844			; $067e: $cd $44 $58 

	; switch back to old bank
	ldh		a, ($e1)		; $0681: $f0 $e1 
	ldh		($fd), a		; $0683: $e0 $fd 
	ld		($2000), a		; $0685: $ea $00 $20 

	; this collides with the underside of blocks
	call		$1983			; $0688: $cd $83 $19 
	; shows mario and lets mario move
	call		$16ec			; $068b: $cd $ec $16 
	; jump and moving animation
	call		$17b3			; $068e: $cd $b3 $17 
	; dunno
	call		$0ae1			; $0691: $cd $e1 $0a 
	; dunno
	call		$0a24			; $0694: $cd $24 $0a 
	; dunno
	call		$1efa			; $0697: $cd $fa $1e 

	; only continue if theres still stuff on here
	ld		hl, $c0ce		; $069a: $21 $ce $c0 
	ld		a, (hl)			; $069d: $7e 
	and		a			; $069e: $a7 
	ret		z			; $069f: $c8 
	; and decrement it
	dec		(hl)			; $06a0: $35 
	; then do this
	call		$210a			; $06a1: $cd $0a $21 

	; done for good
RETURN_2:
	ret					; $06a4: $c9 
; end routine

; routine for die? state
; yeah this is a death reset routine
DEATH_RESET:
	; this is one of those countdown timers
	; wait until the time comes to reset the level from death
	ld		hl, $ffa6		; $06a5: $21 $a6 $ff 
	ld		a, (hl)			; $06a8: $7e 
	and		a			; $06a9: $a7 
	ret		nz			; $06aa: $c0 
	; kill all the entities?
	ld		hl, entity_table	; $06ab: $21 $00 $d1 
	ld		de, $0010		; $06ae: $11 $10 $00 
	ld		b, $0a			; $06b1: $06 $0a 
-	ld		(hl), $ff		; $06b3: $36 $ff 
	add		hl, de			; $06b5: $19 
	dec		b			; $06b6: $05 
	jr		nz, -			; $06b7: $20 $fa 
	; clear this reg?
	; oh this makes mario vulnerable like a small mario again
	xor		a			; $06b9: $af 
	ldh		(r_vulnerability), a		; $06ba: $e0 $99 
	; request life loss
	dec		a			; $06bc: $3d 
	ld		(request_life_change), a		; $06bd: $ea $a3 $c0 
	; go into state 02
	ld		a, $02			; $06c0: $3e $02 
	ldh		(r_state), a		; $06c2: $e0 $b3 
	ret					; $06c4: $c9 
; end routine

; routine
; this is after game init
; sets state possibly to $0d or possible $00
; loads pause window map
; displays current world
; rounds down some address i think?
; maybe it has to do with initing the level???
ROUTINE_0F:
	; off go interrupts
	di					; $06c5: $f3 
	; off goes the screen
	ld		a, $00			; $06c6: $3e $00 
	ldh		($40), a		; $06c8: $e0 $40 
	; call these two routines
	; resets some stuff???
	call		RESET_LEVEL_SPRITES	; $06ca: $cd $cb $1e 
	; this has something to do with tht wram map buffer thing?
	call		ROUTINE_11		; $06cd: $cd $55 $16 

	; grab this pointer
	ld		hl, $ffe5		; $06d0: $21 $e5 $ff 
	; anyway, only do the following if this is set
	ldh		a, ($f9)		; $06d3: $f0 $f9 
	and		a			; $06d5: $a7 
	jr		z, +			; $06d6: $28 $08 
	; and that following is
	; clear that var
	xor		a			; $06d8: $af 
	ldh		($f9), a		; $06d9: $e0 $f9 
	; and grab 1+ this other one
	ldh		a, ($f5)		; $06db: $f0 $f5 
	inc		a			; $06dd: $3c 
	jr		++			; $06de: $18 $01 

	; so we're either gonna have (hl)
	; or the hram var + 1
	; aka: hram(e5h) or 1+(f5h)
+	ld		a, (hl)			; $06e0: $7e 

	; unless its 3, make it go down
	; so impossible to have 2!
++	cp		$03			; $06e1: $fe $03 
	jr		z, +			; $06e3: $28 $01 
	dec		a			; $06e5: $3d 

	; if < 7h, 030ch
+	ld		bc, $030c		; $06e6: $01 $0c $03 
	cp		$07			; $06e9: $fe $07 
	jr		c, +			; $06eb: $38 $1f 
	; else if < bh, 0734h
	ld		bc, $0734		; $06ed: $01 $34 $07 
	cp		$0b			; $06f0: $fe $0b 
	jr		c, +			; $06f2: $38 $18 
	; else if < fh, 0b5ch
	ld		bc, $0b5c		; $06f4: $01 $5c $0b 
	cp		$0f			; $06f7: $fe $0f 
	jr		c, +			; $06f9: $38 $11 
	; else if < 13h, 0f84h
	ld		bc, $0f84		; $06fb: $01 $84 $0f 
	cp		$13			; $06fe: $fe $13 
	jr		c, +			; $0700: $38 $0a 
	; else if < 17h, 13ach
	ld		bc, $13ac		; $0702: $01 $ac $13 
	cp		$17			; $0705: $fe $17 
	; else, 17d4h
	jr		c, +			; $0707: $38 $03 
	ld		bc, $17d4		; $0709: $01 $d4 $17 
	; endif
	; store the result back into hram(ffe5)
	; so yeah, its like, its .. . . rounding some addresses down!
+	ld		(hl), b			; $070c: $70 
	; and clear the high bytes
	inc		l			; $070d: $2c 
	ld		(hl), $00		; $070e: $36 $00 
	; but grab the resulting high bytes
	ld		a, c			; $0710: $79 
	; and put here instead
	ld		($c0ab), a		; $0711: $ea $ab $c0 

	; call this
	call		$07f0			; $0714: $cd $f0 $07 
	; clear this tile in map0
	ld		hl, $982b		; $0717: $21 $2b $98 
	ld		(hl), $2c		; $071a: $36 $2c 
	inc		l			; $071c: $2c 

	; AHA, HERE DISPLAYS THE CURRENT WORLD LEVEL!!
	; grab this probably index?
	; the high bytes tho
	; i think thats consistant
	; idk, but store it as a tile...
	; next to the previously cleared tile
	ldh		a, ($b4)		; $071d: $f0 $b4 
	ld		b, a			; $071f: $47 
	and		$f0			; $0720: $e6 $f0 
	swap		a			; $0722: $cb $37 
	ldi		(hl), a			; $0724: $22 
	; and now the lower bytes to the right of that
	; notice its skipping a space
	ld		a, b			; $0725: $78 
	and		$0f			; $0726: $e6 $0f 
	inc		l			; $0728: $2c 
	ld		(hl), a			; $0729: $77 

	; COPY PAUSE BYTES TO WINDOW LAYER
	; copy 9 bytes from this place in rom to this place in map1
	ld		hl, $9c00		; $072a: $21 $00 $9c 
	ld		de, $0783		; $072d: $11 $83 $07 
	ld		b, $09			; $0730: $06 $09 
-	ld		a, (de)			; $0732: $1a 
	ldi		(hl), a			; $0733: $22 
	inc		de			; $0734: $13 
	dec		b			; $0735: $05 
	jr		nz, -			; $0736: $20 $fa 

	; set STATE to 0
	xor		a			; $0738: $af 
	ldh		($b3), a		; $0739: $e0 $b3 
	; also clear this wram var
	ld		($c0d3), a		; $073b: $ea $d3 $c0 
	; lcd on, obj and bg layer on
	ld		a, $c3			; $073e: $3e $c3 
	ldh		($40), a		; $0740: $e0 $40 
	; call this
	call		ROUTINE_10		; $0742: $cd $8c $07 

	; ignore any pending interrupts
	xor		a			; $0745: $af 
	ldh		(R_IF), a		; $0746: $e0 $0f 
	; reset this
	ldh		($a4), a		; $0748: $e0 $a4 
	; again resetting this after interrupts..
	ld		($c0d2), a		; $074a: $ea $d2 $c0 
	; reset this!
	ldh		($ee), a		; $074d: $e0 $ee 
	; and this level var?
	ld		($da1d), a		; $074f: $ea $1d $da 
	; clear timer modulo
	ldh		(R_TMA), a		; $0752: $e0 $06 
	; reset the time remaining
	ld		hl, $da01		; $0754: $21 $01 $da 
	ldi		(hl), a			; $0757: $22 
	ld		(hl), $04		; $0758: $36 $04 
	; reseting this unknown level var
	ld		a, $28			; $075a: $3e $28 
	ld		($da00), a		; $075c: $ea $00 $da 
	; set this hram var?
	ld		a, $5b			; $075f: $3e $5b 
	ldh		($e9), a		; $0761: $e0 $e9 

	; gonna maybe chnge lower bits of (c203h)
	; grab this index
	ldh		a, ($e4)		; $0763: $f0 $e4 
	; if 5, a
	ld		c, $0a			; $0765: $0e $0a 
	cp		$05			; $0767: $fe $05 
	jr		z, +			; $0769: $28 $06 
	; else if b, c
	ld		c, $0c			; $076b: $0e $0c 
	cp		$0b			; $076d: $fe $0b 
	jr		nz, ++			; $076f: $20 $0d 
	; end if

	; set state to $d !!!!!
+	ld		a, $0d			; $0771: $3e $0d 
	ldh		($b3), a		; $0773: $e0 $b3 
	; rplace lower bits with switch result
	ld		a, ($c203)		; $0775: $fa $03 $c2 
	and		$f0			; $0778: $e6 $f0 
	or		c			; $077a: $b1 
	ld		($c203), a		; $077b: $ea $03 $c2 

	; else!! 
	; still donet know what this does but points to a 3byte struct
++	call		ROUTINE_0C		; $077e: $cd $53 $24 
	; interrupts back on 
	ei					; $0781: $fb 
	; and done
	ret					; $0782: $c9 
; end routine

; data
; pause screen
.incbin "pause.map"
; end data

ROUTINE_10:
	ld		a, ($c0d3)		; $078c: $fa $d3 $c0 
	and		a			; $078f: $a7 
	ret		nz			; $0790: $c0 
	ld		a, $03			; $0791: $3e $03 
	ld		($2000), a		; $0793: $ea $00 $20 
	call		$7ff3			; $0796: $cd $f3 $7f 
	ldh		a, ($fd)		; $0799: $f0 $fd 
	ld		($2000), a		; $079b: $ea $00 $20 
	ldh		a, ($f4)		; $079e: $f0 $f4 
	and		a			; $07a0: $a7 
	jr		nz, +			; $07a1: $20 $0e 
	ldh		a, ($e4)		; $07a3: $f0 $e4 
	ld		hl, $07b7		; $07a5: $21 $b7 $07 
	ld		e, a			; $07a8: $5f 
	ld		d, $00			; $07a9: $16 $00 
	add		hl, de			; $07ab: $19 
	ld		a, (hl)			; $07ac: $7e 
	ld		($dfe8), a		; $07ad: $ea $e8 $df 
	ret					; $07b0: $c9 
; end routine

+	ld		a, $04			; $07b1: $3e $04 
	ld		($dfe8), a		; $07b3: $ea $e8 $df 
	ret					; $07b6: $c9 
	rlca					; $07b7: $07 
	rlca					; $07b8: $07 
	inc		bc			; $07b9: $03 
	ld		($0508), sp		; $07ba: $08 $08 $05 
	rlca					; $07bd: $07 
	inc		bc			; $07be: $03 
	inc		bc			; $07bf: $03 
	ld		b, $06			; $07c0: $06 $06 
	dec		b			; $07c2: $05 

; routine
; this routine goes back to the title screen if you are playing the game
; and you press down start select a and b
; also handles pausing and unpausing
; looks like it checks some keys
; restarts if all button keys are down
; and toggles the window layer if start is down
; or.. somethnig vaguely like that
; i dont know yet
PAUSE_OR_RESET:
	; first check and see if all the proper buttons are pressed for this
	; loads this var (joypad?)
	; checks if lower nibble is maxed (all button keys pressed?)
	ldh		a, (r_pad)		; $07c3: $f0 $80 
	and		$0f			; $07c5: $e6 $0f 
	cp		$0f			; $07c7: $fe $0f 
	jr		nz, +			; $07c9: $20 $03 
	; if all button keyso are pressed, then restart! ?
	jp		INIT			; $07cb: $c3 $85 $01 
	; otherwise grab the masked keys?
+	ldh		a, (r_pending_pad)		; $07ce: $f0 $81 
	; if start is pressed (or not masked)
	bit		3, a			; $07d0: $cb $5f 
	; then that's it
	ret		z			; $07d2: $c8 

	; then check and see if its any of the game states of playing the game
	; otherwise... a world of pain awaits u
	; grab this hram var
	; this is the rst jump routine index
	; so leave if its one of the upper ones
	ldh		a, (r_state)		; $07d3: $f0 $b3 
	cp		$0e			; $07d5: $fe $0e 
	; return if its any state starting with the init title screen or higher
	; leave if its not less than $0e
	ret		nc			; $07d7: $d0 

	; and finally 
	; otherwise, if its any state hving to do wih the game
	; load the hl register with register LCDC
	ld		hl, LCDC		; $07d8: $21 $40 $ff 
	; flip bit 0 of this hram var
	ldh		a, (r_paused)		; $07db: $f0 $b2 
	xor		$01			; $07dd: $ee $01 
	ldh		(r_paused), a		; $07df: $e0 $b2 
	; and if that makes it 0 then skip down there
	jr		z, +			; $07e1: $28 $07 
	; otherwise, turn on window layer
	set		5, (hl)			; $07e3: $cb $ee 
	; and store a 1 in this hram var
	; putting a 1 here requests pause
	ld		a, $01			; $07e5: $3e $01 
-	ldh		(r_pause_unpause_request), a		; $07e7: $e0 $df 
	; and be done with it
	ret					; $07e9: $c9 
	; turns off window layer
+	res		5, (hl)			; $07ea: $cb $ae 
	; and putting a 2 here requests unpause
	; and stores a 2 instead of a 1
	ld		a, $02			; $07ec: $3e $02 
	jr		-			; $07ee: $18 $f7 
; end routine

; routine
; i wonder if this routine unpacks some data into ram?
; well i dont know, it looks like it has something to do with maps
; definitely something to do with the bgmap!!
; maybe the map is stored in rom vertically?
LOAD_MAP:
	; grab 51h bytes from 2114h and put it in wram at c200h
	; i wonder if this data is a description of data to be unpacked?
	ld		hl, DATA_0		; $07f0: $21 $14 $21 
	ld		de, $c200		; $07f3: $11 $00 $c2 
	ld		b, (DATA_0_END - DATA_0); $07f6: $06 $51 
-	ldi		a, (hl)			; $07f8: $2a 
	ld		(de), a			; $07f9: $12 
	inc		de			; $07fa: $13 
	dec		b			; $07fb: $05 
	jr		nz, -			; $07fc: $20 $fa 

	; grab this hram var
	ldh		a, ($99)		; $07fe: $f0 $99 
	and		a			; $0800: $a7 
	jr		z, +			; $0801: $28 $05 
	; if its set:
	; then change +3h byte in that loaded data to 10h
	ld		a, $10			; $0803: $3e $10 
	ld		($c203), a		; $0805: $ea $03 $c2 

	; anyway, clear these 6 bytes in hram
+	ld		hl, $ffe6		; $0808: $21 $e6 $ff 
	xor		a			; $080b: $af 
	ld		b, $06			; $080c: $06 $06 
-	ldi		(hl), a			; $080e: $22 
	dec		b			; $080f: $05 
	jr		nz, -			; $0810: $20 $fc 

	; also clear these two vars, an hram one and a wram one
	ldh		($a3), a		; $0812: $e0 $a3 
	ld		($c0aa), a		; $0814: $ea $aa $c0 
	; and set this  one to 40h
	ld		a, $40			; $0817: $3e $40 
	ldh		($e9), a		; $0819: $e0 $e9 
	
	; set counter to this
	ld		b, $14			; $081b: $06 $14 
	; and of this hram var is 0ah, use  this counter
	; this hram var is know as the rst jump routine index
	; probably means sskip ahead if gonna do a certain routine
	ldh		a, ($b3)		; $081d: $f0 $b3 
	cp		$0a			; $081f: $fe $0a 
	jr		z, +			; $0821: $28 $08 
	; orr if this other hram var is 0ch, also use it
	ldh		a, ($e4)		; $0823: $f0 $e4 
	cp		$0c			; $0825: $fe $0c 
	jr		z, +			; $0827: $28 $02 
	; but otherwise, use this counter instead
	ld		b, $1b			; $0829: $06 $1b 
	; here's saving the counter
+
-	push		bc			; $082b: $c5 
	; but yeah, calling these two routines, however many times decided
	; is it to do with compression?
	call		ROUTINE_06		; $082c: $cd $a8 $21 
	call		COPY_MAP0_COLUMN	; $082f: $cd $4f $22 
	; and restoring it
	pop		bc			; $0832: $c1 
	; and looping for that counter amount
	dec		b			; $0833: $05 
	jr		nz, -			; $0834: $20 $f5 
	; done
	ret					; $0836: $c9 
; end routine

; routine
; THIS ROUTINE HANDLES COLLISIONS WITH ENTITIES
ENTITY_COLLISIONS:
	; dec this var if its > 0
	ldh		a, ($9c)		; $0837: $f0 $9c 
	and		a			; $0839: $a7 
	jr		z, +			; $083a: $28 $03 
	dec		a			; $083c: $3d 
	ldh		($9c), a		; $083d: $e0 $9c 
	; negative offset, -10h
+	ld		de, $fff0		; $083f: $11 $f0 $ff 
	; counter
	ld		b, $0a			; $0842: $06 $0a 
	; source
	ld		hl, $d190		; $0844: $21 $90 $d1 
	; skip down by 10h til find not ffh or reach end
	; so, search for the LAST ITEM ON THIS ARRAY
	; i guess
	; and if you didnt find it? then quit !
-	ld		a, (hl)			; $0847: $7e 
	cp		$ff			; $0848: $fe $ff 
	jr		nz, +			; $084a: $20 $05 
	add		hl, de			; $084c: $19 
	dec		b			; $084d: $05 
	jr		nz, -			; $084e: $20 $f7 
	ret					; $0850: $c9 

+	ldh		($fb), a		; $0851: $e0 $fb 
	ld		a, l			; $0853: $7d 
	ldh		($fc), a		; $0854: $e0 $fc 
	push		bc			; $0856: $c5 
	push		hl			; $0857: $e5 
	ld		bc, $000a		; $0858: $01 $0a $00 
	add		hl, bc			; $085b: $09 
	ld		c, (hl)			; $085c: $4e 
	inc		l			; $085d: $2c 
	inc		l			; $085e: $2c 
	ld		a, (hl)			; $085f: $7e 
	ldh		($9b), a		; $0860: $e0 $9b 
	ld		a, ($c201)		; $0862: $fa $01 $c2 
	ld		b, a			; $0865: $47 
	ldh		a, ($99)		; $0866: $f0 $99 
	cp		$02			; $0868: $fe $02 
	jr		nz, $0b			; $086a: $20 $0b 
	ld		a, ($c203)		; $086c: $fa $03 $c2 
	cp		$18			; $086f: $fe $18 
	jr		z, $04			; $0871: $28 $04 
	ld		a, $fe			; $0873: $3e $fe 
	add		b			; $0875: $80 
	ld		b, a			; $0876: $47 
	ld		a, b			; $0877: $78 
	ldh		($a0), a		; $0878: $e0 $a0 
	ld		a, ($c201)		; $087a: $fa $01 $c2 
	add		$06			; $087d: $c6 $06 
	ldh		($a1), a		; $087f: $e0 $a1 
	ld		a, ($c202)		; $0881: $fa $02 $c2 
	ld		b, a			; $0884: $47 
	sub		$03			; $0885: $d6 $03 
	ldh		($a2), a		; $0887: $e0 $a2 
	ld		a, $02			; $0889: $3e $02 
	add		b			; $088b: $80 
	ldh		($8f), a		; $088c: $e0 $8f 
	pop		hl			; $088e: $e1 
	push		hl			; $088f: $e5 
	call		$0aa6			; $0890: $cd $a6 $0a 
	and		a			; $0893: $a7 
	jp		z, $0958		; $0894: $ca $58 $09 
	ldh		a, ($fc)		; $0897: $f0 $fc 
	cp		$90			; $0899: $fe $90 
	jp		z, $096a		; $089b: $ca $6a $09 
	ldh		a, ($fb)		; $089e: $f0 $fb 
	cp		$33			; $08a0: $fe $33 
	jp		z, $09ce		; $08a2: $ca $ce $09 
	ldh		a, ($b3)		; $08a5: $f0 $b3 
	cp		$0d			; $08a7: $fe $0d 
	jr		z, $06			; $08a9: $28 $06 
	ld		a, ($c0d3)		; $08ab: $fa $d3 $c0 
	and		a			; $08ae: $a7 
	jr		z, $04			; $08af: $28 $04 
	dec		l			; $08b1: $2d 
	jp		$0939			; $08b2: $c3 $39 $09 
	ld		a, ($c202)		; $08b5: $fa $02 $c2 
	add		$06			; $08b8: $c6 $06 
	ld		c, (hl)			; $08ba: $4e 
	dec		l			; $08bb: $2d 
	sub		c			; $08bc: $91 
	jr		c, $7a			; $08bd: $38 $7a 
	ld		a, ($c202)		; $08bf: $fa $02 $c2 
	sub		$06			; $08c2: $d6 $06 
	sub		b			; $08c4: $90 
	jr		nc, $72			; $08c5: $30 $72 
	ld		b, (hl)			; $08c7: $46 
	dec		b			; $08c8: $05 
	dec		b			; $08c9: $05 
	dec		b			; $08ca: $05 
	ld		a, ($c201)		; $08cb: $fa $01 $c2 
	sub		b			; $08ce: $90 
	jr		nc, $68			; $08cf: $30 $68 
	dec		l			; $08d1: $2d 
	dec		l			; $08d2: $2d 
	push		hl			; $08d3: $e5 
	ld		bc, $000a		; $08d4: $01 $0a $00 
	add		hl, bc			; $08d7: $09 
	bit		7, (hl)			; $08d8: $cb $7e 
	pop		hl			; $08da: $e1 
	jr		nz, $78			; $08db: $20 $78 
	call		$0a07			; $08dd: $cd $07 $0a 
	call		$29f8			; $08e0: $cd $f8 $29 
	and		a			; $08e3: $a7 
	jr		z, $6f			; $08e4: $28 $6f 
	ld		hl, $c20a		; $08e6: $21 $0a $c2 
	ld		(hl), $00		; $08e9: $36 $00 
	dec		l			; $08eb: $2d 
	dec		l			; $08ec: $2d 
	ld		(hl), $0d		; $08ed: $36 $0d 
	dec		l			; $08ef: $2d 
	ld		(hl), $01		; $08f0: $36 $01 
	ld		hl, $c203		; $08f2: $21 $03 $c2 
	ld		a, (hl)			; $08f5: $7e 
	and		$f0			; $08f6: $e6 $f0 
	or		$04			; $08f8: $f6 $04 
	ld		(hl), a			; $08fa: $77 
	ld		a, $03			; $08fb: $3e $03 
	ld		($dfe0), a		; $08fd: $ea $e0 $df 
	ld		a, ($c202)		; $0900: $fa $02 $c2 
	add		$fc			; $0903: $c6 $fc 
	ldh		($eb), a		; $0905: $e0 $eb 
	ld		a, ($c201)		; $0907: $fa $01 $c2 
	sub		$10			; $090a: $d6 $10 
	ldh		($ec), a		; $090c: $e0 $ec 
	ldh		a, ($9e)		; $090e: $f0 $9e 
	ldh		($ed), a		; $0910: $e0 $ed 
	ldh		a, ($9c)		; $0912: $f0 $9c 
	and		a			; $0914: $a7 
	jr		z, $1d			; $0915: $28 $1d 
	ldh		a, ($9d)		; $0917: $f0 $9d 
	cp		$03			; $0919: $fe $03 
	jr		z, $03			; $091b: $28 $03 
	inc		a			; $091d: $3c 
	ldh		($9d), a		; $091e: $e0 $9d 
	ld		b, a			; $0920: $47 
	ldh		a, ($ed)		; $0921: $f0 $ed 
	cp		$50			; $0923: $fe $50 
	jr		z, $0d			; $0925: $28 $0d 
	sla		a			; $0927: $cb $27 
	dec		b			; $0929: $05 
	jr		nz, -$05			; $092a: $20 $fb 
	ldh		($ed), a		; $092c: $e0 $ed 
	ld		a, $32			; $092e: $3e $32 
	ldh		($9c), a		; $0930: $e0 $9c 
	jr		$21			; $0932: $18 $21 
	xor		a			; $0934: $af 
	ldh		($9d), a		; $0935: $e0 $9d 
	jr		-$0b			; $0937: $18 $f5 
	dec		l			; $0939: $2d 
	dec		l			; $093a: $2d 
	ld		a, ($c0d3)		; $093b: $fa $d3 $c0 
	and		a			; $093e: $a7 
	jr		nz, $21			; $093f: $20 $21 
	ldh		a, ($99)		; $0941: $f0 $99 
	cp		$03			; $0943: $fe $03 
	jr		nc, $0e			; $0945: $30 $0e 
	call		$2a3b			; $0947: $cd $3b $2a 
	and		a			; $094a: $a7 
	jr		z, $08			; $094b: $28 $08 
	ldh		a, ($99)		; $094d: $f0 $99 
	and		a			; $094f: $a7 
	jr		nz, $0b			; $0950: $20 $0b 
	call		$09e8			; $0952: $cd $e8 $09 
	pop		hl			; $0955: $e1 
	pop		bc			; $0956: $c1 
	ret					; $0957: $c9 

	pop		hl			; $0958: $e1 
	pop		bc			; $0959: $c1 
	jp		$084c			; $095a: $c3 $4c $08 
	call		$09d7			; $095d: $cd $d7 $09 
	jr		-$0d			; $0960: $18 $f3 
	call		$2afd			; $0962: $cd $fd $2a 
	and		a			; $0965: $a7 
	jr		z, -$13			; $0966: $28 $ed 
	jr		-$6f			; $0968: $18 $91 
	ldh		a, ($fb)		; $096a: $f0 $fb 
	cp		$29			; $096c: $fe $29 
	jr		z, $32			; $096e: $28 $32 
	cp		$34			; $0970: $fe $34 
	jr		z, $3e			; $0972: $28 $3e 
	cp		$2b			; $0974: $fe $2b 
	jr		z, $46			; $0976: $28 $46 
	cp		$2e			; $0978: $fe $2e 
	jr		nz, -$27			; $097a: $20 $d9 
	ldh		a, ($99)		; $097c: $f0 $99 
	cp		$02			; $097e: $fe $02 
	jr		nz, $26			; $0980: $20 $26 
	ldh		($b5), a		; $0982: $e0 $b5 
	ld		a, $04			; $0984: $3e $04 
	ld		($dfe0), a		; $0986: $ea $e0 $df 
	ld		a, $10			; $0989: $3e $10 
	ldh		($ed), a		; $098b: $e0 $ed 
	ld		a, ($c202)		; $098d: $fa $02 $c2 
	add		$fc			; $0990: $c6 $fc 
	ldh		($eb), a		; $0992: $e0 $eb 
	ld		a, ($c201)		; $0994: $fa $01 $c2 
	sub		$10			; $0997: $d6 $10 
	ldh		($ec), a		; $0999: $e0 $ec 
	dec		l			; $099b: $2d 
	dec		l			; $099c: $2d 
	dec		l			; $099d: $2d 
	ld		(hl), $ff		; $099e: $36 $ff 
	jr		-$4d			; $09a0: $18 $b3 
	ldh		a, ($99)		; $09a2: $f0 $99 
	cp		$02			; $09a4: $fe $02 
	jr		z, -$1f			; $09a6: $28 $e1 
	ld		a, $01			; $09a8: $3e $01 
	ldh		($99), a		; $09aa: $e0 $99 
	ld		a, $50			; $09ac: $3e $50 
	ldh		($a6), a		; $09ae: $e0 $a6 
	jr		-$2e			; $09b0: $18 $d2 
	ld		a, $f8			; $09b2: $3e $f8 
	ld		($c0d3), a		; $09b4: $ea $d3 $c0 
	ld		a, $0c			; $09b7: $3e $0c 
	ld		($dfe8), a		; $09b9: $ea $e8 $df 
	jr		-$35			; $09bc: $18 $cb 
	ld		a, $ff			; $09be: $3e $ff 
	ldh		($ed), a		; $09c0: $e0 $ed 
	ld		a, $08			; $09c2: $3e $08 
	ld		($dfe0), a		; $09c4: $ea $e0 $df 
	ld		a, $01			; $09c7: $3e $01 
	ld		($c0a3), a		; $09c9: $ea $a3 $c0 
	jr		-$41			; $09cc: $18 $bf 
	ldh		($fe), a		; $09ce: $e0 $fe 
	ld		a, $05			; $09d0: $3e $05 
	ld		($dfe0), a		; $09d2: $ea $e0 $df 
	jr		-$3c			; $09d5: $18 $c4 
	ld		a, $03			; $09d7: $3e $03 
	ldh		($99), a		; $09d9: $e0 $99 
	xor		a			; $09db: $af 
	ldh		($b5), a		; $09dc: $e0 $b5 
	ld		a, $50			; $09de: $3e $50 
	ldh		($a6), a		; $09e0: $e0 $a6 
	ld		a, $06			; $09e2: $3e $06 
	ld		($dfe0), a		; $09e4: $ea $e0 $df 
	ret					; $09e7: $c9 
; end routine

; routine
; death?
DEATH:
	; leave if this var > 0
	; i suppose this is a disabling var?
	ld		a, ($d007)		; $09e8: $fa $07 $d0 
	and		a			; $09eb: $a7 
	ret		nz			; $09ec: $c0 

	; put 3 in this hram var
	; b3h is known as the rst routine index??
	; set the state to state 03, wait and die?
	ld		a, $03			; $09ed: $3e $03 
	ldh		(r_state), a		; $09ef: $e0 $b3 

	; clear this hram var and timer module
	; make mario unable to fire
	xor		a			; $09f1: $af 
	ldh		(r_fire), a		; $09f2: $e0 $b5 
	ldh		(R_TMA), a		; $09f4: $e0 $06 

	; set these wram vars
	ld		a, $02			; $09f6: $3e $02 
	ld		($dfe8), a		; $09f8: $ea $e8 $df 
	; set character entity to $80
	; $80 is dead mario?
	ld		a, $80			; $09fb: $3e $80 
	ld		($c200), a		; $09fd: $ea $00 $c2 

	; move/copy this wram var
	; copy mario's y position here?
	; mario's death y position
	ld		a, ($c201)		; $0a00: $fa $01 $c2 
	ld		(death_y), a		; $0a03: $ea $dd $c0 

	; done
	ret					; $0a06: $c9 
; end routine

; routine
ROUTINE_1E:
	push		hl			; $0a07: $e5 
	push		de			; $0a08: $d5 
	ldh		a, ($9b)		; $0a09: $f0 $9b 
	and		$c0			; $0a0b: $e6 $c0 
	swap		a			; $0a0d: $cb $37 
	srl		a			; $0a0f: $cb $3f 
	srl		a			; $0a11: $cb $3f 
	ld		e, a			; $0a13: $5f 
	ld		d, $00			; $0a14: $16 $00 
	ld		hl, $0a20		; $0a16: $21 $20 $0a 
	add		hl, de			; $0a19: $19 
	ld		a, (hl)			; $0a1a: $7e 
	ldh		($9e), a		; $0a1b: $e0 $9e 
	pop		de			; $0a1d: $d1 
	pop		hl			; $0a1e: $e1 
	ret					; $0a1f: $c9 
; end routine

	ld		bc, $0804		; $0a20: $01 $04 $08 
	ld		d, b			; $0a23: $50 
	ldh		a, ($ee)		; $0a24: $f0 $ee 
	and		a			; $0a26: $a7 
	ret		z			; $0a27: $c8 
	cp		$c0			; $0a28: $fe $c0 
	ret		z			; $0a2a: $c8 
	ld		de, $0010		; $0a2b: $11 $10 $00 
	ld		b, $0a			; $0a2e: $06 $0a 
	ld		hl, $d100		; $0a30: $21 $00 $d1 
	ld		a, (hl)			; $0a33: $7e 
	cp		$ff			; $0a34: $fe $ff 
	jr		nz, $05			; $0a36: $20 $05 
	add		hl, de			; $0a38: $19 
	dec		b			; $0a39: $05 
	jr		nz, -$09			; $0a3a: $20 $f7 
	ret					; $0a3c: $c9 
	push		bc			; $0a3d: $c5 
	push		hl			; $0a3e: $e5 
	ld		bc, $000a		; $0a3f: $01 $0a $00 
	add		hl, bc			; $0a42: $09 
	bit		7, (hl)			; $0a43: $cb $7e 
	jr		nz, $5a			; $0a45: $20 $5a 
	ld		c, (hl)			; $0a47: $4e 
	inc		l			; $0a48: $2c 
	inc		l			; $0a49: $2c 
	ld		a, (hl)			; $0a4a: $7e 
	ldh		($9b), a		; $0a4b: $e0 $9b 
	pop		hl			; $0a4d: $e1 
	push		hl			; $0a4e: $e5 
	inc		l			; $0a4f: $2c 
	inc		l			; $0a50: $2c 
	ld		b, (hl)			; $0a51: $46 
	ld		a, ($c201)		; $0a52: $fa $01 $c2 
	sub		b			; $0a55: $90 
	jr		c, $49			; $0a56: $38 $49 
	ld		b, a			; $0a58: $47 
	ld		a, $14			; $0a59: $3e $14 
	sub		b			; $0a5b: $90 
	jr		c, $43			; $0a5c: $38 $43 
	cp		$07			; $0a5e: $fe $07 
	jr		nc, $3f			; $0a60: $30 $3f 
	inc		l			; $0a62: $2c 
	ld		a, c			; $0a63: $79 
	and		$70			; $0a64: $e6 $70 
	swap		a			; $0a66: $cb $37 
	ld		c, a			; $0a68: $4f 
	ld		a, (hl)			; $0a69: $7e 
	add		$08			; $0a6a: $c6 $08 
	dec		c			; $0a6c: $0d 
	jr		nz, -$05			; $0a6d: $20 $fb 
	ld		c, a			; $0a6f: $4f 
	ld		b, (hl)			; $0a70: $46 
	ld		a, ($c202)		; $0a71: $fa $02 $c2 
	sub		$06			; $0a74: $d6 $06 
	sub		c			; $0a76: $91 
	jr		nc, $28			; $0a77: $30 $28 
	ld		a, ($c202)		; $0a79: $fa $02 $c2 
	add		$06			; $0a7c: $c6 $06 
	sub		b			; $0a7e: $90 
	jr		c, $20			; $0a7f: $38 $20 
	dec		l			; $0a81: $2d 
	dec		l			; $0a82: $2d 
	dec		l			; $0a83: $2d 
	push		de			; $0a84: $d5 
	call		$0a07			; $0a85: $cd $07 $0a 
	call		$2a1a			; $0a88: $cd $1a $2a 
	pop		de			; $0a8b: $d1 
	and		a			; $0a8c: $a7 
	jr		z, $12			; $0a8d: $28 $12 
	ld		a, ($c202)		; $0a8f: $fa $02 $c2 
	add		$fc			; $0a92: $c6 $fc 
	ldh		($eb), a		; $0a94: $e0 $eb 
	ld		a, ($c201)		; $0a96: $fa $01 $c2 
	sub		$10			; $0a99: $d6 $10 
	ldh		($ec), a		; $0a9b: $e0 $ec 
	ldh		a, ($9e)		; $0a9d: $f0 $9e 
	ldh		($ed), a		; $0a9f: $e0 $ed 
	pop		hl			; $0aa1: $e1 
	pop		bc			; $0aa2: $c1 
	jp		$0a38			; $0aa3: $c3 $38 $0a 
	inc		l			; $0aa6: $2c 
	inc		l			; $0aa7: $2c 
	ld		a, (hl)			; $0aa8: $7e 
	add		$08			; $0aa9: $c6 $08 
	ld		b, a			; $0aab: $47 
	ldh		a, ($a0)		; $0aac: $f0 $a0 
	sub		b			; $0aae: $90 
	jr		nc, $2e			; $0aaf: $30 $2e 
	ld		a, c			; $0ab1: $79 
	and		$0f			; $0ab2: $e6 $0f 
	ld		b, a			; $0ab4: $47 
	ld		a, (hl)			; $0ab5: $7e 
	dec		b			; $0ab6: $05 
	jr		z, $04			; $0ab7: $28 $04 
	sub		$08			; $0ab9: $d6 $08 
	jr		-$07			; $0abb: $18 $f9 
	ld		b, a			; $0abd: $47 
	ldh		a, ($a1)		; $0abe: $f0 $a1 
	sub		b			; $0ac0: $90 
	jr		c, $1c			; $0ac1: $38 $1c 
	inc		l			; $0ac3: $2c 
	ldh		a, ($8f)		; $0ac4: $f0 $8f 
	ld		b, (hl)			; $0ac6: $46 
	sub		b			; $0ac7: $90 
	jr		c, $15			; $0ac8: $38 $15 
	ld		a, c			; $0aca: $79 
	and		$70			; $0acb: $e6 $70 
	swap		a			; $0acd: $cb $37 
	ld		b, a			; $0acf: $47 
	ld		a, (hl)			; $0ad0: $7e 
	add		$08			; $0ad1: $c6 $08 
	dec		b			; $0ad3: $05 
	jr		nz, -$05			; $0ad4: $20 $fb 
	ld		b, a			; $0ad6: $47 
	ldh		a, ($a2)		; $0ad7: $f0 $a2 
	sub		b			; $0ad9: $90 
	jr		nc, $03			; $0ada: $30 $03 
	ld		a, $01			; $0adc: $3e $01 
	ret					; $0ade: $c9 
	xor		a			; $0adf: $af 
	ret					; $0ae0: $c9 
	ld		a, ($c207)		; $0ae1: $fa $07 $c2 
	cp		$01			; $0ae4: $fe $01 
	ret		z			; $0ae6: $c8 
	ld		de, $0010		; $0ae7: $11 $10 $00 
	ld		b, $0a			; $0aea: $06 $0a 
	ld		hl, $d100		; $0aec: $21 $00 $d1 
	ld		a, (hl)			; $0aef: $7e 
	cp		$ff			; $0af0: $fe $ff 
	jr		nz, $05			; $0af2: $20 $05 
	add		hl, de			; $0af4: $19 
	dec		b			; $0af5: $05 
	jr		nz, -$09			; $0af6: $20 $f7 
	ret					; $0af8: $c9 
	push		bc			; $0af9: $c5 
	push		hl			; $0afa: $e5 
	ld		bc, $000a		; $0afb: $01 $0a $00 
	add		hl, bc			; $0afe: $09 
	bit		7, (hl)			; $0aff: $cb $7e 
	jp		z, $0b7f		; $0b01: $ca $7f $0b 
	ld		a, (hl)			; $0b04: $7e 
	and		$0f			; $0b05: $e6 $0f 
	ldh		($a0), a		; $0b07: $e0 $a0 
	ld		bc, $fff8		; $0b09: $01 $f8 $ff 
	add		hl, bc			; $0b0c: $09 
	ldh		a, ($a0)		; $0b0d: $f0 $a0 
	ld		b, a			; $0b0f: $47 
	ld		a, (hl)			; $0b10: $7e 
	dec		b			; $0b11: $05 
	jr		z, $04			; $0b12: $28 $04 
	sub		$08			; $0b14: $d6 $08 
	jr		-$07			; $0b16: $18 $f9 
	ld		c, a			; $0b18: $4f 
	ldh		($a0), a		; $0b19: $e0 $a0 
	ld		a, ($c201)		; $0b1b: $fa $01 $c2 
	add		$06			; $0b1e: $c6 $06 
	ld		b, a			; $0b20: $47 
	ld		a, c			; $0b21: $79 
	sub		b			; $0b22: $90 
	cp		$07			; $0b23: $fe $07 
	jr		nc, $58			; $0b25: $30 $58 
	inc		l			; $0b27: $2c 
	ld		a, ($c202)		; $0b28: $fa $02 $c2 
	ld		b, a			; $0b2b: $47 
	ld		a, (hl)			; $0b2c: $7e 
	sub		b			; $0b2d: $90 
	jr		c, $04			; $0b2e: $38 $04 
	cp		$03			; $0b30: $fe $03 
	jr		nc, $4b			; $0b32: $30 $4b 
	push		hl			; $0b34: $e5 
	inc		l			; $0b35: $2c 
	inc		l			; $0b36: $2c 
	inc		l			; $0b37: $2c 
	inc		l			; $0b38: $2c 
	inc		l			; $0b39: $2c 
	inc		l			; $0b3a: $2c 
	inc		l			; $0b3b: $2c 
	ld		a, (hl)			; $0b3c: $7e 
	and		$70			; $0b3d: $e6 $70 
	swap		a			; $0b3f: $cb $37 
	ld		b, a			; $0b41: $47 
	pop		hl			; $0b42: $e1 
	ld		a, (hl)			; $0b43: $7e 
	add		$08			; $0b44: $c6 $08 
	dec		b			; $0b46: $05 
	jr		nz, -$05			; $0b47: $20 $fb 
	ld		b, a			; $0b49: $47 
	ld		a, ($c202)		; $0b4a: $fa $02 $c2 
	sub		b			; $0b4d: $90 
	jr		c, $04			; $0b4e: $38 $04 
	cp		$03			; $0b50: $fe $03 
	jr		nc, $2b			; $0b52: $30 $2b 
	dec		l			; $0b54: $2d 
	ldh		a, ($a0)		; $0b55: $f0 $a0 
	sub		$0a			; $0b57: $d6 $0a 
	ld		($c201), a		; $0b59: $ea $01 $c2 
	push		hl			; $0b5c: $e5 
	dec		l			; $0b5d: $2d 
	dec		l			; $0b5e: $2d 
	call		$29f8			; $0b5f: $cd $f8 $29 
	pop		hl			; $0b62: $e1 
	ld		bc, $0009		; $0b63: $01 $09 $00 
	add		hl, bc			; $0b66: $09 
	ld		(hl), $01		; $0b67: $36 $01 
	xor		a			; $0b69: $af 
	ld		hl, $c207		; $0b6a: $21 $07 $c2 
	ldi		(hl), a			; $0b6d: $22 
	ldi		(hl), a			; $0b6e: $22 
	ldi		(hl), a			; $0b6f: $22 
	ld		(hl), $01		; $0b70: $36 $01 
	ld		hl, $c20c		; $0b72: $21 $0c $c2 
	ld		a, (hl)			; $0b75: $7e 
	cp		$07			; $0b76: $fe $07 
	jr		c, $02			; $0b78: $38 $02 
	ld		(hl), $06		; $0b7a: $36 $06 
	pop		hl			; $0b7c: $e1 
	pop		bc			; $0b7d: $c1 
	ret					; $0b7e: $c9 
	pop		hl			; $0b7f: $e1 
	pop		bc			; $0b80: $c1 
	jp		$0af4			; $0b81: $c3 $f4 $0a 

; routine
; wait then die routine
; it probably prepares death
; prepares mario's death sprite
PREPARE_DEATH_TOSS:
	; point to mario's first sprite
	ld		hl, mario_sprite_0	; $0b84: $21 $0c $c0 
	; unsure what this mysterious place is
	; grab where mario died (y)
	; and put mario's sprite there?
	ld		a, (death_y)		; $0b87: $fa $dd $c0 
	ld		c, a			; $0b8a: $4f 
	sub		$08			; $0b8b: $d6 $08 
	ld		d, a			; $0b8d: $57 
	ld		(hl), a			; $0b8e: $77 
	; and then grab mario's x, and subtract 8 and give it to the sprite
	inc		l			; $0b8f: $2c 
	ld		a, ($c202)		; $0b90: $fa $02 $c2 
	add		$f8			; $0b93: $c6 $f8 
	ld		b, a			; $0b95: $47 
	ldi		(hl), a			; $0b96: $22 
	; set the tile
	ld		(hl), $0f		; $0b97: $36 $0f 
	; and no attributes
	inc		l			; $0b99: $2c 
	ld		(hl), $00		; $0b9a: $36 $00 
	; and do the same for marios other 3 sprites that make him up
	inc		l			; $0b9c: $2c 
	ld		(hl), c			; $0b9d: $71 
	inc		l			; $0b9e: $2c 
	ld		(hl), b			; $0b9f: $70 
	inc		l			; $0ba0: $2c 
	ld		(hl), $1f		; $0ba1: $36 $1f 
	inc		l			; $0ba3: $2c 
	ld		(hl), $00		; $0ba4: $36 $00 
	inc		l			; $0ba6: $2c 
	ld		(hl), d			; $0ba7: $72 
	inc		l			; $0ba8: $2c 
	ld		a, b			; $0ba9: $78 
	add		$08			; $0baa: $c6 $08 
	ld		b, a			; $0bac: $47 
	ldi		(hl), a			; $0bad: $22 
	ld		(hl), $0f		; $0bae: $36 $0f 
	; is it doing some coloring for cgb stuff? dunno
	inc		l			; $0bb0: $2c 
	ld		(hl), $20		; $0bb1: $36 $20 
	inc		l			; $0bb3: $2c 
	ld		(hl), c			; $0bb4: $71 
	inc		l			; $0bb5: $2c 
	ld		(hl), b			; $0bb6: $70 
	inc		l			; $0bb7: $2c 
	ld		(hl), $1f		; $0bb8: $36 $1f 
	inc		l			; $0bba: $2c 
	ld		(hl), $20		; $0bbb: $36 $20 
	; go to engine state 04 which tosses marios into the sky
	ld		a, $04			; $0bbd: $3e $04 
	ldh		(r_state), a		; $0bbf: $e0 $b3 
	; reset these things
	xor		a			; $0bc1: $af 
	ld		($c0ac), a		; $0bc2: $ea $ac $c0 
	; this is mario's vulnerability
	ldh		(r_vulnerability), a		; $0bc5: $e0 $99 
	ldh		($f4), a		; $0bc7: $e0 $f4 
	call		RESET_LEVEL_SPRITES	; $0bc9: $cd $cb $1e 
	ret					; $0bcc: $c9 
; routine

; death toss routine
DEATH_TOSS:
	ld		a, ($c0ac)		; $0bcd: $fa $ac $c0 
	ld		e, a			; $0bd0: $5f 
	inc		a			; $0bd1: $3c 
	ld		($c0ac), a		; $0bd2: $ea $ac $c0 
	ld		d, $00			; $0bd5: $16 $00 
	ld		hl, $0c10		; $0bd7: $21 $10 $0c 
	add		hl, de			; $0bda: $19 
	ld		b, (hl)			; $0bdb: $46 
	ld		a, b			; $0bdc: $78 
	cp		$7f			; $0bdd: $fe $7f 
	jr		nz, $09			; $0bdf: $20 $09 
	ld		a, ($c0ac)		; $0be1: $fa $ac $c0 
	dec		a			; $0be4: $3d 
	ld		($c0ac), a		; $0be5: $ea $ac $c0 
	ld		b, $02			; $0be8: $06 $02 
	ld		hl, $c00c		; $0bea: $21 $0c $c0 
	ld		de, $0004		; $0bed: $11 $04 $00 
	ld		c, $04			; $0bf0: $0e $04 
	ld		a, b			; $0bf2: $78 
	add		(hl)			; $0bf3: $86 
	ld		(hl), a			; $0bf4: $77 
	add		hl, de			; $0bf5: $19 
	dec		c			; $0bf6: $0d 
	jr		nz, -$07			; $0bf7: $20 $f9 
	cp		$b4			; $0bf9: $fe $b4 
	ret		c			; $0bfb: $d8 
	ld		a, ($da1d)		; $0bfc: $fa $1d $da 
	cp		$ff			; $0bff: $fe $ff 
	jr		nz, $04			; $0c01: $20 $04 
	ld		a, $3b			; $0c03: $3e $3b 
	jr		$06			; $0c05: $18 $06 
	ld		a, $90			; $0c07: $3e $90 
	ldh		($a6), a		; $0c09: $e0 $a6 
	ld		a, $01			; $0c0b: $3e $01 
	ldh		($b3), a		; $0c0d: $e0 $b3 
	ret					; $0c0f: $c9 
; end routine

; data
; death toss animation? or something?
.incbin "data6.bin"
; end data

; routine:
ROUTINE_1D:
	ld		hl, $ffa6		; $0c37: $21 $a6 $ff 
	ld		a, (hl)			; $0c3a: $7e 
	and		a			; $0c3b: $a7 
	jr		z, $04			; $0c3c: $28 $04 
	call		ROUTINE_01		; $0c3e: $cd $2d $17 
	ret					; $0c41: $c9 
	ld		a, ($d007)		; $0c42: $fa $07 $d0 
	and		a			; $0c45: $a7 
	jr		nz, $04			; $0c46: $20 $04 
	ld		a, $40			; $0c48: $3e $40 
	ldh		($a6), a		; $0c4a: $e0 $a6 
	ld		a, $05			; $0c4c: $3e $05 
	ldh		($b3), a		; $0c4e: $e0 $b3 
	xor		a			; $0c50: $af 
	ld		($da1d), a		; $0c51: $ea $1d $da 
	ldh		($06), a		; $0c54: $e0 $06 
	ldh		a, ($b4)		; $0c56: $f0 $b4 
	and		$0f			; $0c58: $e6 $0f 
	cp		$03			; $0c5a: $fe $03 
	ret		nz			; $0c5c: $c0 
	call		$2b21			; $0c5d: $cd $21 $2b 
	ldh		a, ($b4)		; $0c60: $f0 $b4 
	cp		$43			; $0c62: $fe $43 
	ret		nz			; $0c64: $c0 
	ld		a, $06			; $0c65: $3e $06 
	ldh		($b3), a		; $0c67: $e0 $b3 
	ret					; $0c69: $c9 
; end routine

; routine
; initiates win level?
INIT_LEVEL_WIN:
	ldh		a, ($b4)		; $0c6a: $f0 $b4 
	and		$0f			; $0c6c: $e6 $0f 
	cp		$03			; $0c6e: $fe $03 
	jr		nz, $07			; $0c70: $20 $07 
	xor		a			; $0c72: $af 
	ld		($c0ab), a		; $0c73: $ea $ab $c0 
	call		$2488			; $0c76: $cd $88 $24 
	ldh		a, ($a6)		; $0c79: $f0 $a6 
	and		a			; $0c7b: $a7 
	ret		nz			; $0c7c: $c0 
	ld		hl, $da01		; $0c7d: $21 $01 $da 
	ldi		a, (hl)			; $0c80: $2a 
	ld		b, (hl)			; $0c81: $46 
	or		b			; $0c82: $b0 
	jr		z, $34			; $0c83: $28 $34 
	ld		a, $01			; $0c85: $3e $01 
	ld		($da00), a		; $0c87: $ea $00 $da 
	ldh		a, ($fd)		; $0c8a: $f0 $fd 
	ldh		($e1), a		; $0c8c: $e0 $e1 
	ld		a, $02			; $0c8e: $3e $02 
	ldh		($fd), a		; $0c90: $e0 $fd 
	ld		($2000), a		; $0c92: $ea $00 $20 
	call		$5844			; $0c95: $cd $44 $58 
	ldh		a, ($e1)		; $0c98: $f0 $e1 
	ldh		($fd), a		; $0c9a: $e0 $fd 
	ld		($2000), a		; $0c9c: $ea $00 $20 
	ld		de, $0010		; $0c9f: $11 $10 $00 
	call		$0166			; $0ca2: $cd $66 $01 
	ld		a, $01			; $0ca5: $3e $01 
	ldh		($a6), a		; $0ca7: $e0 $a6 
	xor		a			; $0ca9: $af 
	ld		($da1d), a		; $0caa: $ea $1d $da 
	ld		a, ($da01)		; $0cad: $fa $01 $da 
	and		$01			; $0cb0: $e6 $01 
	ret		nz			; $0cb2: $c0 
	ld		a, $0a			; $0cb3: $3e $0a 
	ld		($dfe0), a		; $0cb5: $ea $e0 $df 
	ret					; $0cb8: $c9 
	ld		a, $06			; $0cb9: $3e $06 
	ldh		($b3), a		; $0cbb: $e0 $b3 
	ld		a, $26			; $0cbd: $3e $26 
	ldh		($a6), a		; $0cbf: $e0 $a6 
	ret					; $0cc1: $c9 
; end routine

; routine
FINISH_LEVEL:
	ldh		a, ($a6)		; $0cc2: $f0 $a6 
	and		a			; $0cc4: $a7 
	ret		nz			; $0cc5: $c0 
	xor		a			; $0cc6: $af 
	ld		($da1d), a		; $0cc7: $ea $1d $da 
	ldh		($06), a		; $0cca: $e0 $06 
	ldh		a, ($b4)		; $0ccc: $f0 $b4 
	and		$0f			; $0cce: $e6 $0f 
	cp		$03			; $0cd0: $fe $03 
	ld		a, $1c			; $0cd2: $3e $1c 
	jr		z, +			; $0cd4: $28 $1b 
	ld		a, ($c201)		; $0cd6: $fa $01 $c2 
	cp		$60			; $0cd9: $fe $60 
	jr		c, $08			; $0cdb: $38 $08 
	cp		$a0			; $0cdd: $fe $a0 
	jr		nc, $04			; $0cdf: $30 $04 
	ld		a, $08			; $0ce1: $3e $08 
	jr		$09			; $0ce3: $18 $09 
	ld		a, $02			; $0ce5: $3e $02 
	ldh		($fd), a		; $0ce7: $e0 $fd 
	ld		($2000), a		; $0ce9: $ea $00 $20 
	ld		a, $12			; $0cec: $3e $12 
	ldh		($b3), a		; $0cee: $e0 $b3 
	ret					; $0cf0: $c9 
+	ldh		($b3), a		; $0cf1: $e0 $b3 
	ld		a, $03			; $0cf3: $3e $03 
	ld		($2000), a		; $0cf5: $ea $00 $20 
	ldh		($fd), a		; $0cf8: $e0 $fd 
	ld		hl, $ffe4		; $0cfa: $21 $e4 $ff 
	ld		a, (hl)			; $0cfd: $7e 
	ldh		($fb), a		; $0cfe: $e0 $fb 
	ld		(hl), $0c		; $0d00: $36 $0c 
	inc		l			; $0d02: $2c 
	xor		a			; $0d03: $af 
	ldi		(hl), a			; $0d04: $22 
	ldi		(hl), a			; $0d05: $22 
	ldh		($a3), a		; $0d06: $e0 $a3 
	inc		l			; $0d08: $2c 
	inc		l			; $0d09: $2c 
	ld		a, (hl)			; $0d0a: $7e 
	ldh		($e0), a		; $0d0b: $e0 $e0 
	ld		a, $06			; $0d0d: $3e $06 
	ldh		($a6), a		; $0d0f: $e0 $a6 
	ldh		a, ($b4)		; $0d11: $f0 $b4 
	and		$f0			; $0d13: $e6 $f0 
	cp		$40			; $0d15: $fe $40 
	ret		nz			; $0d17: $c0 
	xor		a			; $0d18: $af 
	ldh		($fb), a		; $0d19: $e0 $fb 
	ld		a, $01			; $0d1b: $3e $01 
	ld		($c0de), a		; $0d1d: $ea $de $c0 
	ld		a, $bf			; $0d20: $3e $bf 
	ldh		($fc), a		; $0d22: $e0 $fc 
	ld		a, $ff			; $0d24: $3e $ff 
	ldh		($a6), a		; $0d26: $e0 $a6 
	ld		a, $27			; $0d28: $3e $27 
	ldh		($b3), a		; $0d2a: $e0 $b3 
	call		$7ff3			; $0d2c: $cd $f3 $7f 
	ret					; $0d2f: $c9 
; end routine

; routine
; gets called with hram(b4h) loaded onto a
; so a is the argument to this routine
; seems to decide on WHICH GRAPHICS to load
; ENTRY IS BELOW
	; come here if the upper bits of the arg were 1
	; disable interrupts
-	di					; $0d30: $f3 
	; switch bank to 02 from below
	ld		a, c			; $0d31: $79 
	ld		($2000), a		; $0d32: $ea $00 $20 
	ldh		($fd), a		; $0d35: $e0 $fd 

	; disable lcd
	xor		a			; $0d37: $af 
	ldh		($40), a		; $0d38: $e0 $40 

	; load the game graphics
	call		LOAD_GAME_CHR		; $0d3a: $cd $d0 $05 

	; and clean up and go home
	jp		++			; $0d3d: $c3 $ca $0d 

; routine
; i suppose this loads the graphics for the next level?
NEXT_LEVEL:
	ld		hl, $ffa6		; $0d40: $21 $a6 $ff 
	ld		a, (hl)			; $0d43: $7e 
	and		a			; $0d44: $a7 
	ret		nz			; $0d45: $c0 
	ld		a, ($dff9)		; $0d46: $fa $f9 $df 
	and		a			; $0d49: $a7 
	ret		nz			; $0d4a: $c0 
	ldh		a, ($e4)		; $0d4b: $f0 $e4 
	inc		a			; $0d4d: $3c 
	cp		$0c			; $0d4e: $fe $0c 
	jr		nz, $01			; $0d50: $20 $01 
	xor		a			; $0d52: $af 
	ldh		($e4), a		; $0d53: $e0 $e4 
	ldh		a, ($b4)		; $0d55: $f0 $b4 
	inc		a			; $0d57: $3c 
	ld		b, a			; $0d58: $47 
	and		$0f			; $0d59: $e6 $0f 
	cp		$04			; $0d5b: $fe $04 
	ld		a, b			; $0d5d: $78 
	jr		nz, $02			; $0d5e: $20 $02 
	add		$0d			; $0d60: $c6 $0d 
	ldh		($b4), a		; $0d62: $e0 $b4 

ROUTINE_0D:
	; grab the upper bytes
	and		$f0			; $0d64: $e6 $f0 
	swap		a			; $0d66: $cb $37 

	; c = bank to switch to
	; if upper a bits are an index of an address array
	; then this is probably figuring out which bank the address points to
	; if 1, c = 2, and go UP THERE
	; which loads game chr
	cp		$01			; $0d68: $fe $01 
	ld		c, $02			; $0d6a: $0e $02 
	jr		z, -			; $0d6c: $28 $c2 
	; rest loads some kinda something below, only a bank different
	; else if 2, c = 1, and go below
	cp		$02			; $0d6e: $fe $02 
	ld		c, $01			; $0d70: $0e $01 
	jr		z, +			; $0d72: $28 $08 
	; else if 3, c = 3, and go below
	cp		$03			; $0d74: $fe $03 
	ld		c, $03			; $0d76: $0e $03 
	jr		z, +			; $0d78: $28 $02 
	; else: c = 1, and done
	ld		c, $01			; $0d7a: $0e $01 
	; endif

	; down here we use bank 1 or 3, never 2 or 0
	; 2 is used for loading game chr above
	; move the masked a to b, and grab c onto a
+	ld		b, a			; $0d7c: $47 
	; disable interrupts while ur at it
	di					; $0d7d: $f3 
	ld		a, c			; $0d7e: $79 
	; oo, do a bank switch
	; and dont care about switching back either
	ld		($2000), a		; $0d7f: $ea $00 $20 
	ldh		($fd), a		; $0d82: $e0 $fd 

	; disable lcdc
	xor		a			; $0d84: $af 
	ldh		(R_LCDC), a		; $0d85: $e0 $40 
	; grab the masked arg again
	ld		a, b			; $0d87: $78 
	; subtract 2
	dec		a			; $0d88: $3d 
	dec		a			; $0d89: $3d 
	; double it
	sla		a			; $0d8a: $cb $27 
	; form a pointer with it
	; maybe its a word pointer since it was doubled
	; so there's an array of addresses at 0de4h
	ld		d, $00			; $0d8c: $16 $00 
	ld		e, a			; $0d8e: $5f 
	ld		hl, $0de4		; $0d8f: $21 $e4 $0d 
	; save the offset
	push		de			; $0d92: $d5 
	; now we have the address to the address
	add		hl, de			; $0d93: $19 
	; now grab the address from the address onto de
	ld		e, (hl)			; $0d94: $5e 
	inc		hl			; $0d95: $23 
	ld		d, (hl)			; $0d96: $56 
	; so now an address is on de
	; address to some tiles
	; and copy (de) to this 2nd quarter of second chr slot 
	; so here copies some tiles into part of vram
	; this is probably a set of enemies or so?
	ld		hl, $8a00		; $0d97: $21 $00 $8a 
-	ld		a, (de)			; $0d9a: $1a 
	ldi		(hl), a			; $0d9b: $22 
	inc		de			; $0d9c: $13 
	; this interesting means of a counter
	push		hl			; $0d9d: $e5 
	ld		bc, $7230		; $0d9e: $01 $30 $72 
	add		hl, bc			; $0da1: $09 
	pop		hl			; $0da2: $e1 
	jr		nc, -			; $0da3: $30 $f5 
	
	; now get the array offset back
	pop		de			; $0da5: $d1 
	; and this time we're gonna use it on this second array
	ld		hl, $0dea		; $0da6: $21 $ea $0d 
	add		hl, de			; $0da9: $19 
	; grab the address from the second array
	; address to some more tiles
	ld		e, (hl)			; $0daa: $5e 
	inc		hl			; $0dab: $23 
	ld		d, (hl)			; $0dac: $56 
	; save the address
	; the address to tilse
	push		de			; $0dad: $d5 
	; this time copying some tiles to this specific portion of 3rd chr slot
	ld		hl, $9310		; $0dae: $21 $10 $93 
-	ld		a, (de)			; $0db1: $1a 
	ldi		(hl), a			; $0db2: $22 
	inc		de			; $0db3: $13 
	ld		a, h			; $0db4: $7c 
	; go until 96ffh?
	cp		$97			; $0db5: $fe $97 
	jr		nz, -			; $0db7: $20 $f8 

	; grab the address back, this time on hl
	; the address to second set of tiles
	pop		hl			; $0db9: $e1 
	; and offseting it by this much?
	; skipping some tiles?
	; note the odd number tho
	ld		de, $02c1		; $0dba: $11 $c1 $02 
	add		hl, de			; $0dbd: $19 
	; and copying the tiles i guess
	; or whatever data is here
	; to this place in wram
	; yeah see, we're copying a 1bit version of a specific tile!
	ld		de, $c600		; $0dbe: $11 $00 $c6 
	ld		b, $08			; $0dc1: $06 $08 
-	ldi		a, (hl)			; $0dc3: $2a 
	ld		(de), a			; $0dc4: $12 
	inc		hl			; $0dc5: $23 
	inc		de			; $0dc6: $13 
	dec		b			; $0dc7: $05 
	jr		nz, -			; $0dc8: $20 $f9 

	; clean up ad go home
	; cancel any pending interrupts
++	xor		a			; $0dca: $af 
	ldh		(R_IF), a		; $0dcb: $e0 $0f 
	; enable lcd and bg and obj layers
	ld		a, $c3			; $0dcd: $3e $c3 
	ldh		(R_LCDC), a		; $0dcf: $e0 $40 
	; interrupts on
	ei					; $0dd1: $fb 
	; set this var
	ld		a, $03			; $0dd2: $3e $03 
	ldh		($e5), a		; $0dd4: $e0 $e5 
	; clear these vars
	xor		a			; $0dd6: $af 
	ld		($c0d2), a		; $0dd7: $ea $d2 $c0 
	ldh		($f9), a		; $0dda: $e0 $f9 
	; switch to STATE 02h!
	ld		a, $02			; $0ddc: $3e $02 
	ldh		($b3), a		; $0dde: $e0 $b3 
	; call this
	call		ROUTINE_0B		; $0de0: $cd $39 $24 
	; done
	ret					; $0de3: $c9 
; end routine

; address array
.dw $4032
.dw $4032
.dw $47f2
.dw $4402
.dw $4402
.dw $4bc2
; end array

; routine
; some kind of next level???
ROUTINE_1A:
	di					; $0df0: $f3
	xor		a			; $0df1: $af 
	ldh		($40), a		; $0df2: $e0 $40 
	call		$05f8			; $0df4: $cd $f8 $05 
	call		$1c12			; $0df7: $cd $12 $1c 
	call		$1c4d			; $0dfa: $cd $4d $1c 
	xor		a			; $0dfd: $af 
	ldh		($0f), a		; $0dfe: $e0 $0f 
	ld		a, $c3			; $0e00: $3e $c3 
	ldh		($40), a		; $0e02: $e0 $40 
	ei					; $0e04: $fb 
	ld		a, $08			; $0e05: $3e $08 
	ldh		($b3), a		; $0e07: $e0 $b3 
	ldh		($b1), a		; $0e09: $e0 $b1 
	ret					; $0e0b: $c9 
; end routine

; routine
; enter princess
ENTER_PRINCESS:
	ldh		a, ($a6)		; $0e0c: $f0 $a6 
	and		a			; $0e0e: $a7 
	jr		z, $0e			; $0e0f: $28 $0e 
	call		$21a8			; $0e11: $cd $a8 $21 
	xor		a			; $0e14: $af 
	ld		($c0ab), a		; $0e15: $ea $ab $c0 
	call		$2488			; $0e18: $cd $88 $24 
	call		$172d			; $0e1b: $cd $2d $17 
	ret					; $0e1e: $c9 
	ld		a, $40			; $0e1f: $3e $40 
	ldh		($a6), a		; $0e21: $e0 $a6 
	ld		hl, $ffb3		; $0e23: $21 $b3 $ff 
	inc		(hl)			; $0e26: $34 
	ret					; $0e27: $c9 
; end routine

; routine
; enter princess also?
ENTER_PRINCESS_2:
	xor		a			; $0e28: $af 
	ld		($c0ab), a		; $0e29: $ea $ab $c0 
	call		$2488			; $0e2c: $cd $88 $24 
	ldh		a, ($a6)		; $0e2f: $f0 $a6 
	and		a			; $0e31: $a7 
	ret		nz			; $0e32: $c0 
	ldh		a, ($e0)		; $0e33: $f0 $e0 
	sub		$02			; $0e35: $d6 $02 
	cp		$40			; $0e37: $fe $40 
	jr		nc, $02			; $0e39: $30 $02 
	add		$20			; $0e3b: $c6 $20 
	ld		l, a			; $0e3d: $6f 
	ld		h, $98			; $0e3e: $26 $98 
	ld		de, $0120		; $0e40: $11 $20 $01 
	add		hl, de			; $0e43: $19 
	ld		a, l			; $0e44: $7d 
	ldh		($e0), a		; $0e45: $e0 $e0 
	ld		a, $05			; $0e47: $3e $05 
	ldh		($fc), a		; $0e49: $e0 $fc 
	ld		a, $08			; $0e4b: $3e $08 
	ldh		($a6), a		; $0e4d: $e0 $a6 
	ld		hl, $ffb3		; $0e4f: $21 $b3 $ff 
	inc		(hl)			; $0e52: $34 
	ret					; $0e53: $c9 
; end routine

; routine
ROUTINE_1B:
	ldh		a, ($a6)		; $0e54: $f0 $a6 
	and		a			; $0e56: $a7 
	ret		nz			; $0e57: $c0 
	ldh		a, ($fc)		; $0e58: $f0 $fc 
	dec		a			; $0e5a: $3d 
	jr		z, +			; $0e5b: $28 $1d 
	ldh		($fc), a		; $0e5d: $e0 $fc 
	ldh		a, ($e0)		; $0e5f: $f0 $e0 
	ld		l, a			; $0e61: $6f 
	ld		h, $99			; $0e62: $26 $99 
	sub		$20			; $0e64: $d6 $20 
	ldh		($e0), a		; $0e66: $e0 $e0 
	ldh		a, ($41)		; $0e68: $f0 $41 
	and		$03			; $0e6a: $e6 $03 
	jr		nz, -$06			; $0e6c: $20 $fa 
	ld		(hl), $2c		; $0e6e: $36 $2c 
	ld		a, $08			; $0e70: $3e $08 
	ldh		($a6), a		; $0e72: $e0 $a6 
	ld		a, $0b			; $0e74: $3e $0b 
	ld		($dfe0), a		; $0e76: $ea $e0 $df 
	ret					; $0e79: $c9 
+	ld		a, $10			; $0e7a: $3e $10 
	ldh		($a6), a		; $0e7c: $e0 $a6 
	ld		a, $03			; $0e7e: $3e $03 
	ldh		($fd), a		; $0e80: $e0 $fd 
	ld		($2000), a		; $0e82: $ea $00 $20 
	call		$7ff3			; $0e85: $cd $f3 $7f 
	ld		hl, $ffb3		; $0e88: $21 $b3 $ff 
	inc		(hl)			; $0e8b: $34 
	ret					; $0e8c: $c9 
; end routine

; routine
START_WALKING_PRINCESS:
	ldh		a, ($a6)		; $0e8d: $f0 $a6 
	and		a			; $0e8f: $a7 
	ret		nz			; $0e90: $c0 
	xor		a			; $0e91: $af 
	ld		($c0d2), a		; $0e92: $ea $d2 $c0 
	ld		($c207), a		; $0e95: $ea $07 $c2 
	inc		a			; $0e98: $3c 
	ldh		($f9), a		; $0e99: $e0 $f9 
	ld		hl, $ffb3		; $0e9b: $21 $b3 $ff 
	inc		(hl)			; $0e9e: $34 
	ret					; $0e9f: $c9 
; end routine

; routine
; walk to right forever?
WALK_RIGHT:
	call		ROUTINE_1F		; $0ea0: $cd $b2 $0e 
	ld		a, ($c202)		; $0ea3: $fa $02 $c2 
	cp		$c0			; $0ea6: $fe $c0 
	ret		c			; $0ea8: $d8 
	ld		a, $20			; $0ea9: $3e $20 
	ldh		($a6), a		; $0eab: $e0 $a6 
	ld		hl, $ffb3		; $0ead: $21 $b3 $ff 
	inc		(hl)			; $0eb0: $34 
	ret					; $0eb1: $c9 
; end routine

; routine
ROUTINE_1F:
	ld		a, $10			; $0eb2: $3e $10 
	ldh		($80), a		; $0eb4: $e0 $80 
	ld		a, ($c203)		; $0eb6: $fa $03 $c2 
	and		$0f			; $0eb9: $e6 $0f 
	cp		$0a			; $0ebb: $fe $0a 
	call		c, $17b3		; $0ebd: $dc $b3 $17 
	call		$16ec			; $0ec0: $cd $ec $16 
	ret					; $0ec3: $c9 
; end routine

; routine
START_PRINCESS:
	ldh		a, ($a6)		; $0ec4: $f0 $a6 
	and		a			; $0ec6: $a7 
	ret		nz			; $0ec7: $c0 
	call		ROUTINE_20		; $0ec8: $cd $de $0e 
	xor		a			; $0ecb: $af 
	ldh		($ea), a		; $0ecc: $e0 $ea 
	ldh		($a3), a		; $0ece: $e0 $a3 
	ld		a, $a1			; $0ed0: $3e $a1 
	ldh		($a6), a		; $0ed2: $e0 $a6 
	ld		a, $0f			; $0ed4: $3e $0f 
	ld		($dfe8), a		; $0ed6: $ea $e8 $df 
	ld		hl, $ffb3		; $0ed9: $21 $b3 $ff 
	inc		(hl)			; $0edc: $34 
	ret					; $0edd: $c9 
; end routine

; routine
ROUTINE_20:
	ld		hl, $c201		; $0ede: $21 $01 $c2 
	ld		(hl), $7e		; $0ee1: $36 $7e 
	inc		l			; $0ee3: $2c 
	ld		(hl), $b0		; $0ee4: $36 $b0 
	inc		l			; $0ee6: $2c 
	ld		a, (hl)			; $0ee7: $7e 
	and		$f0			; $0ee8: $e6 $f0 
	ld		(hl), a			; $0eea: $77 
	; this is copying a mario? or a princes? idk
	ld		hl, $c210		; $0eeb: $21 $10 $c2 
	ld		de, $2114		; $0eee: $11 $14 $21 
	ld		b, $10			; $0ef1: $06 $10 
	ld		a, (de)			; $0ef3: $1a 
	ldi		(hl), a			; $0ef4: $22 
	inc		de			; $0ef5: $13 
	dec		b			; $0ef6: $05 
	jr		nz, -$06			; $0ef7: $20 $fa 
	ld		hl, $c211		; $0ef9: $21 $11 $c2 
	ld		(hl), $7e		; $0efc: $36 $7e 
	inc		l			; $0efe: $2c 
	ld		(hl), $00		; $0eff: $36 $00 
	inc		l			; $0f01: $2c 
	ld		(hl), $22		; $0f02: $36 $22 
	inc		l			; $0f04: $2c 
	inc		l			; $0f05: $2c 
	ld		(hl), $20		; $0f06: $36 $20 
	ret					; $0f08: $c9 
; end routine

; routine
; start thank you
START_THANK_YOU:
	ldh		a, ($a6)		; $0f09: $f0 $a6 
	and		a			; $0f0b: $a7 
	jr		z, +			; $0f0c: $28 $13 
	ld		hl, $ffa4		; $0f0e: $21 $a4 $ff 
	inc		(hl)			; $0f11: $34 
	call		$218f			; $0f12: $cd $8f $21 
	ld		hl, $c202		; $0f15: $21 $02 $c2 
	dec		(hl)			; $0f18: $35 
	ld		hl, $c212		; $0f19: $21 $12 $c2 
	dec		(hl)			; $0f1c: $35 
	call		$172d			; $0f1d: $cd $2d $17 
	ret					; $0f20: $c9 
+	ldh		a, ($fb)		; $0f21: $f0 $fb 
	ldh		($e4), a		; $0f23: $e0 $e4 
	ld		hl, $ffb3		; $0f25: $21 $b3 $ff 
	inc		(hl)			; $0f28: $34 
	ret					; $0f29: $c9 
; end routine

; routine
; walk into thank you
WALK_INTO_THANK_YOU:
	ld		a, $10			; $0f2a: $3e $10 
	ldh		($80), a		; $0f2c: $e0 $80 
	call		$17b3			; $0f2e: $cd $b3 $17 
	call		$16ec			; $0f31: $cd $ec $16 
	ld		a, ($c202)		; $0f34: $fa $02 $c2 
	cp		$4c			; $0f37: $fe $4c 
	ret		c			; $0f39: $d8 
	ld		a, ($c203)		; $0f3a: $fa $03 $c2 
	and		$f0			; $0f3d: $e6 $f0 
	ld		($c203), a		; $0f3f: $ea $03 $c2 
	ldh		a, ($e0)		; $0f42: $f0 $e0 
	sub		$40			; $0f44: $d6 $40 
	add		$04			; $0f46: $c6 $04 
	ld		b, a			; $0f48: $47 
	and		$f0			; $0f49: $e6 $f0 
	cp		$c0			; $0f4b: $fe $c0 
	ld		a, b			; $0f4d: $78 
	jr		nz, $02			; $0f4e: $20 $02 
	sub		$20			; $0f50: $d6 $20 
	ldh		($e3), a		; $0f52: $e0 $e3 
	ld		a, $98			; $0f54: $3e $98 
	ldh		($e2), a		; $0f56: $e0 $e2 
	xor		a			; $0f58: $af 
	ldh		($fb), a		; $0f59: $e0 $fb 
	ld		hl, $ffb3		; $0f5b: $21 $b3 $ff 
	inc		(hl)			; $0f5e: $34 
	jr		-$44			; $0f5f: $18 $bc 
; end routine

; routine
POST_THANK_YOU:
	ld		hl, $0fd8		; $0f61: $21 $d8 $0f 
	call		ROUTINE_21		; $0f64: $cd $81 $0f 
	cp		$ff			; $0f67: $fe $ff 
	ret		nz			; $0f69: $c0 
	ld		hl, $ffb3		; $0f6a: $21 $b3 $ff 
	inc		(hl)			; $0f6d: $34 
	ld		a, $80			; $0f6e: $3e $80 
	ld		($c210), a		; $0f70: $ea $10 $c2 
	ld		a, $08			; $0f73: $3e $08 
	ldh		($a6), a		; $0f75: $e0 $a6 
	ld		a, $08			; $0f77: $3e $08 
	ldh		($fb), a		; $0f79: $e0 $fb 
	ld		a, $12			; $0f7b: $3e $12 
	ld		($dfe8), a		; $0f7d: $ea $e8 $df 
	ret					; $0f80: $c9 
; end routine

; routine
ROUTINE_21:
	ldh		a, ($a6)		; $0f81: $f0 $a6 
	and		a			; $0f83: $a7 
	ret		nz			; $0f84: $c0 
	ldh		a, ($fb)		; $0f85: $f0 $fb 
	ld		e, a			; $0f87: $5f 
	ld		d, $00			; $0f88: $16 $00 
	add		hl, de			; $0f8a: $19 
	ld		a, (hl)			; $0f8b: $7e 
	ld		b, a			; $0f8c: $47 
	cp		$fe			; $0f8d: $fe $fe 
	jr		z, +			; $0f8f: $28 $34 
	cp		$ff			; $0f91: $fe $ff 
	ret		z			; $0f93: $c8 
	ldh		a, ($e2)		; $0f94: $f0 $e2 
	ld		h, a			; $0f96: $67 
	ldh		a, ($e3)		; $0f97: $f0 $e3 
	ld		l, a			; $0f99: $6f 
	ldh		a, ($41)		; $0f9a: $f0 $41 
	and		$03			; $0f9c: $e6 $03 
	jr		nz, -$06			; $0f9e: $20 $fa 
	ldh		a, ($41)		; $0fa0: $f0 $41 
	and		$03			; $0fa2: $e6 $03 
	jr		nz, -$06			; $0fa4: $20 $fa 
	ld		(hl), b			; $0fa6: $70 
	inc		hl			; $0fa7: $23 
	ld		a, h			; $0fa8: $7c 
	ldh		($e2), a		; $0fa9: $e0 $e2 
	ld		a, l			; $0fab: $7d 
	and		$0f			; $0fac: $e6 $0f 
	jr		nz, $12			; $0fae: $20 $12 
	bit		4, l			; $0fb0: $cb $65 
	jr		nz, $0e			; $0fb2: $20 $0e 
	ld		a, l			; $0fb4: $7d 
	sub		$20			; $0fb5: $d6 $20 
	ldh		($e3), a		; $0fb7: $e0 $e3 
	inc		e			; $0fb9: $1c 
	ld		a, e			; $0fba: $7b 
	ldh		($fb), a		; $0fbb: $e0 $fb 
	ld		a, $0c			; $0fbd: $3e $0c 
	ldh		($a6), a		; $0fbf: $e0 $a6 
	ret					; $0fc1: $c9 
	ld		a, l			; $0fc2: $7d 
	jr		-$0e			; $0fc3: $18 $f2 
+	inc		hl			; $0fc5: $23 
	ldi		a, (hl)			; $0fc6: $2a 
	ld		c, a			; $0fc7: $4f 
	ld		b, $00			; $0fc8: $06 $00 
	ld		a, (hl)			; $0fca: $7e 
	push		af			; $0fcb: $f5 
	ldh		a, ($e2)		; $0fcc: $f0 $e2 
	ld		h, a			; $0fce: $67 
	ldh		a, ($e3)		; $0fcf: $f0 $e3 
	ld		l, a			; $0fd1: $6f 
	add		hl, bc			; $0fd2: $09 
	pop		bc			; $0fd3: $c1 
	inc		de			; $0fd4: $13 
	inc		de			; $0fd5: $13 
	jr		-$3e			; $0fd6: $18 $c2 
; end routine

	dec		e			; $0fd8: $1d 
	ld		de, $170a		; $0fd9: $11 $0a $17 
	inc		d			; $0fdc: $14 
	inc		l			; $0fdd: $2c 
	ldi		(hl), a			; $0fde: $22 
	jr		$1e			; $0fdf: $18 $1e 
	inc		l			; $0fe1: $2c 
	ld		d, $0a			; $0fe2: $16 $0a 
	dec		de			; $0fe4: $1b 
	ld		(de), a			; $0fe5: $12 
	jr		$23			; $0fe6: $18 $23 
	cp		$73			; $0fe8: $fe $73 
	jr		$11			; $0fea: $18 $11 
	jr		z, $2c			; $0fec: $28 $2c 
	dec		c			; $0fee: $0d 
	ld		a, (bc)			; $0fef: $0a 
	ld		(de), a			; $0ff0: $12 
	inc		e			; $0ff1: $1c 
	ldi		(hl), a			; $0ff2: $22 
	rst		$38			; $0ff3: $ff 

; routine
ENTER_PRINCESS_TRANSFORM:
	ldh		a, ($a6)		; $0ff4: $f0 $a6 
	and		a			; $0ff6: $a7 
	ret		nz			; $0ff7: $c0 
	ldh		a, ($fb)		; $0ff8: $f0 $fb 
	dec		a			; $0ffa: $3d 
	jr		z, +			; $0ffb: $28 $19 
	ldh		($fb), a		; $0ffd: $e0 $fb 
	and		$01			; $0fff: $e6 $01 
	ld		hl, $102c		; $1001: $21 $2c $10 
	jr		nz, ++			; $1004: $20 $08 
	ld		hl, $103c		; $1006: $21 $3c $10 
	ld		a, $03			; $1009: $3e $03 
	ld		($dff8), a		; $100b: $ea $f8 $df 
++	call		ROUTINE_22		; $100e: $cd $20 $10 
	ld		a, $08			; $1011: $3e $08 
	ldh		($a6), a		; $1013: $e0 $a6 
	ret					; $1015: $c9 

+	ld		hl, $c210		; $1016: $21 $10 $c2 
	ld		(hl), $00		; $1019: $36 $00 
	ld		hl, $ffb3		; $101b: $21 $b3 $ff 
	inc		(hl)			; $101e: $34 
	ret					; $101f: $c9 
; end routine

; routine
ROUTINE_22:
	ld		de, $c01c		; $1020: $11 $1c $c0 
	ld		b, $10			; $1023: $06 $10 
	ldi		a, (hl)			; $1025: $2a 
	ld		(de), a			; $1026: $12 
	inc		e			; $1027: $1c 
	dec		b			; $1028: $05 
	jr		nz, -$06			; $1029: $20 $fa 
	ret					; $102b: $c9 
; end routine

; data
	ld		a, b			; $102c: $78 
	ld		e, b			; $102d: $58 
	ld		b, $00			; $102e: $06 $00 
	ld		a, b			; $1030: $78 
	ld		h, b			; $1031: $60 
	ld		b, $20			; $1032: $06 $20 
	add		b			; $1034: $80 
	ld		e, b			; $1035: $58 
	ld		b, $40			; $1036: $06 $40 
	add		b			; $1038: $80 
	ld		h, b			; $1039: $60 
	ld		b, $60			; $103a: $06 $60 

	ld		a, b			; $103c: $78 
	ld		e, b			; $103d: $58 
	rlca					; $103e: $07 
	nop					; $103f: $00 
	ld		a, b			; $1040: $78 
	ld		h, b			; $1041: $60 
	rlca					; $1042: $07 
	jr		nz, -$80			; $1043: $20 $80 
	ld		e, b			; $1045: $58 
	rlca					; $1046: $07 
	ld		b, b			; $1047: $40 
	add		b			; $1048: $80 
	ld		h, b			; $1049: $60 
	rlca					; $104a: $07 
	ld		h, b			; $104b: $60 
; end data

; routine
PRINCESS_ENEMY_SPAWN:
	ldh		a, ($a6)		; $104c: $f0 $a6 
	and		a			; $104e: $a7 
	ret		nz			; $104f: $c0 
	ld		hl, $c213		; $1050: $21 $13 $c2 
	ld		(hl), $20		; $1053: $36 $20 
	ld		bc, $c218		; $1055: $01 $18 $c2 
	ld		hl, $2164		; $1058: $21 $64 $21 
	push		bc			; $105b: $c5 
	call		$490d			; $105c: $cd $0d $49 
	pop		hl			; $105f: $e1 
	dec		l			; $1060: $2d 
	ld		a, (hl)			; $1061: $7e 
	and		a			; $1062: $a7 
	jr		nz, $0b			; $1063: $20 $0b 
	ld		(hl), $01		; $1065: $36 $01 
	ld		hl, $c213		; $1067: $21 $13 $c2 
	ld		(hl), $21		; $106a: $36 $21 
	ld		a, $40			; $106c: $3e $40 
	ldh		($a6), a		; $106e: $e0 $a6 
	ldh		a, ($ac)		; $1070: $f0 $ac 
	and		$01			; $1072: $e6 $01 
	jr		nz, $09			; $1074: $20 $09 
	ld		hl, $c212		; $1076: $21 $12 $c2 
	inc		(hl)			; $1079: $34 
	ld		a, (hl)			; $107a: $7e 
	cp		$d0			; $107b: $fe $d0 
	jr		nc, $04			; $107d: $30 $04 
	call		$172d			; $107f: $cd $2d $17 
	ret					; $1082: $c9 
	ld		hl, $ffb3		; $1083: $21 $b3 $ff 
	ld		(hl), $12		; $1086: $36 $12 
	ld		a, $02			; $1088: $3e $02 
	ldh		($fd), a		; $108a: $e0 $fd 
	ld		($2000), a		; $108c: $ea $00 $20 
	ret					; $108f: $c9 
; end routine

; routine
ENTER_PRINCESS_WIN:
	ldh		a, ($a7)		; $1090: $f0 $a7 
	and		a			; $1092: $a7 
	jr		nz, $09			; $1093: $20 $09 
	ld		a, $01			; $1095: $3e $01 
	ld		($dff8), a		; $1097: $ea $f8 $df 
	ld		a, $20			; $109a: $3e $20 
	ldh		($a7), a		; $109c: $e0 $a7 
	xor		a			; $109e: $af 
	ld		($c0ab), a		; $109f: $ea $ab $c0 
	call		$2488			; $10a2: $cd $88 $24 
	ldh		a, ($a6)		; $10a5: $f0 $a6 
	ld		c, a			; $10a7: $4f 
	and		$03			; $10a8: $e6 $03 
	jr		nz, $13			; $10aa: $20 $13 
	ldh		a, ($fb)		; $10ac: $f0 $fb 
	xor		$01			; $10ae: $ee $01 
	ldh		($fb), a		; $10b0: $e0 $fb 
	ld		b, $fc			; $10b2: $06 $fc 
	jr		z, $02			; $10b4: $28 $02 
	ld		b, $04			; $10b6: $06 $04 
	ld		a, ($c0df)		; $10b8: $fa $df $c0 
	add		b			; $10bb: $80 
	ld		($c0df), a		; $10bc: $ea $df $c0 
	ld		a, c			; $10bf: $79 
	cp		$80			; $10c0: $fe $80 
	ret		nc			; $10c2: $d0 
	and		$1f			; $10c3: $e6 $1f 
	ret		nz			; $10c5: $c0 
	ld		hl, $8dd0		; $10c6: $21 $d0 $8d 
	ld		bc, $0220		; $10c9: $01 $20 $02 
	ldh		a, ($fc)		; $10cc: $f0 $fc 
	ld		d, a			; $10ce: $57 
	ldh		a, ($41)		; $10cf: $f0 $41 
	and		$03			; $10d1: $e6 $03 
	jr		nz, -$06			; $10d3: $20 $fa 
	ld		a, (hl)			; $10d5: $7e 
	and		d			; $10d6: $a2 
	ld		e, a			; $10d7: $5f 
	ldh		a, ($41)		; $10d8: $f0 $41 
	and		$03			; $10da: $e6 $03 
	jr		nz, -$06			; $10dc: $20 $fa 
	ld		(hl), e			; $10de: $73 
	inc		hl			; $10df: $23 
	ld		a, h			; $10e0: $7c 
	cp		$8f			; $10e1: $fe $8f 
	jr		nz, $03			; $10e3: $20 $03 
	ld		hl, $9690		; $10e5: $21 $90 $96 
	rrc		d			; $10e8: $cb $0a 
	dec		bc			; $10ea: $0b 
	ld		a, c			; $10eb: $79 
	or		b			; $10ec: $b0 
	jr		nz, -$20			; $10ed: $20 $e0 
	ldh		a, ($fc)		; $10ef: $f0 $fc 
	sla		a			; $10f1: $cb $27 
	jr		z, $09			; $10f3: $28 $09 
	swap		a			; $10f5: $cb $37 
	ldh		($fc), a		; $10f7: $e0 $fc 
	ld		a, $3f			; $10f9: $3e $3f 
	ldh		($a6), a		; $10fb: $e0 $a6 
	ret					; $10fd: $c9 
	xor		a			; $10fe: $af 
	ld		($c0df), a		; $10ff: $ea $df $c0 
	ld		($c0d2), a		; $1102: $ea $d2 $c0 
	inc		a			; $1105: $3c 
	ldh		($f9), a		; $1106: $e0 $f9 
	ld		hl, $ffb3		; $1108: $21 $b3 $ff 
	inc		(hl)			; $110b: $34 
	ret					; $110c: $c9 
; end routine

; routine
ENTER_WIN_THANK_YOU:
	di					; $110d: $f3 
	xor		a			; $110e: $af 
	ldh		($40), a		; $110f: $e0 $40 
	ldh		($f9), a		; $1111: $e0 $f9 
	ld		hl, $9c00		; $1113: $21 $00 $9c 
	ld		bc, $0100		; $1116: $01 $00 $01 
	call		$05be			; $1119: $cd $be $05 
	call		$0808			; $111c: $cd $08 $08 
	call		$0ede			; $111f: $cd $de $0e 
	ld		hl, $c202		; $1122: $21 $02 $c2 
	ld		(hl), $38		; $1125: $36 $38 
	inc		l			; $1127: $2c 
	ld		(hl), $10		; $1128: $36 $10 
	ld		hl, $c212		; $112a: $21 $12 $c2 
	ld		(hl), $78		; $112d: $36 $78 
	xor		a			; $112f: $af 
	ldh		($0f), a		; $1130: $e0 $0f 
	ldh		($a4), a		; $1132: $e0 $a4 
	ld		($c0df), a		; $1134: $ea $df $c0 
	ldh		($fb), a		; $1137: $e0 $fb 
	ld		hl, $c000		; $1139: $21 $00 $c0 
	ld		b, $0c			; $113c: $06 $0c 
	ldi		(hl), a			; $113e: $22 
	dec		b			; $113f: $05 
	jr		nz, -$04			; $1140: $20 $fc 
	call		$172d			; $1142: $cd $2d $17 
	ld		a, $98			; $1145: $3e $98 
	ldh		($e2), a		; $1147: $e0 $e2 
	ld		a, $a5			; $1149: $3e $a5 
	ldh		($e3), a		; $114b: $e0 $e3 
	ld		a, $0f			; $114d: $3e $0f 
	ld		($dfe8), a		; $114f: $ea $e8 $df 
	ld		a, $c3			; $1152: $3e $c3 
	ldh		($40), a		; $1154: $e0 $40 
	ei					; $1156: $fb 
	ld		hl, $ffb3		; $1157: $21 $b3 $ff 
	inc		(hl)			; $115a: $34 
	ret					; $115b: $c9 
; end routine

; routine
START_THANK_YOU_TEXT:
	ld		hl, $117a		; $115c: $21 $7a $11 
	call		$0f81			; $115f: $cd $81 $0f 
	cp		$ff			; $1162: $fe $ff 
	ret		nz			; $1164: $c0 
	xor		a			; $1165: $af 
	ldh		($fb), a		; $1166: $e0 $fb 
	ld		a, $99			; $1168: $3e $99 
	ldh		($e2), a		; $116a: $e0 $e2 
	ld		a, $02			; $116c: $3e $02 
	ldh		($e3), a		; $116e: $e0 $e3 
	ld		a, $23			; $1170: $3e $23 
	ld		($c213), a		; $1172: $ea $13 $c2 
	ld		hl, $ffb3		; $1175: $21 $b3 $ff 
	inc		(hl)			; $1178: $34 
	ret					; $1179: $c9 
; end routine

; data
	jr		$11			; $117a: $18 $11 
	jr		z, $2c			; $117c: $28 $2c 
	dec		c			; $117e: $0d 
	ld		a, (bc)			; $117f: $0a 
	ld		(de), a			; $1180: $12 
	inc		e			; $1181: $1c 
	ldi		(hl), a			; $1182: $22 
	cp		$1b			; $1183: $fe $1b 
	dec		c			; $1185: $0d 
	ld		a, (bc)			; $1186: $0a 
	ld		(de), a			; $1187: $12 
	inc		e			; $1188: $1c 
	ldi		(hl), a			; $1189: $22 
	rst		$38			; $118a: $ff 
; end data

; routine
; kiss heart
KISS_HEART:
	ld		hl, $11b6		; $118b: $21 $b6 $11 
	call		$0f81			; $118e: $cd $81 $0f 
	ldh		a, ($ac)		; $1191: $f0 $ac 
	and		$03			; $1193: $e6 $03 
	ret		nz			; $1195: $c0 
	ld		hl, $c212		; $1196: $21 $12 $c2 
	ld		a, (hl)			; $1199: $7e 
	cp		$44			; $119a: $fe $44 
	jr		c, $05			; $119c: $38 $05 
	dec		(hl)			; $119e: $35 
	call		$172d			; $119f: $cd $2d $17 
	ret					; $11a2: $c9 
	ld		hl, $ffb3		; $11a3: $21 $b3 $ff 
	inc		(hl)			; $11a6: $34 
	ld		hl, $c030		; $11a7: $21 $30 $c0 
	ld		(hl), $70		; $11aa: $36 $70 
	inc		l			; $11ac: $2c 
	ld		(hl), $3a		; $11ad: $36 $3a 
	inc		l			; $11af: $2c 
	ld		(hl), $84		; $11b0: $36 $84 
	inc		l			; $11b2: $2c 
	ld		(hl), $00		; $11b3: $36 $00 
	ret					; $11b5: $c9 
; end routine

; data
	dec		e			; $11b6: $1d 
	ld		de, $170a		; $11b7: $11 $0a $17 
	inc		d			; $11ba: $14 
	inc		l			; $11bb: $2c 
	ldi		(hl), a			; $11bc: $22 
	jr		$1e			; $11bd: $18 $1e 
	inc		l			; $11bf: $2c 
	ld		d, $0a			; $11c0: $16 $0a 
	dec		de			; $11c2: $1b 
	ld		(de), a			; $11c3: $12 
	jr		$23			; $11c4: $18 $23 
	rst		$38			; $11c6: $ff 
; end data

; routine
; kiss particle heart
SPAWN_KISS_PARTICLE:
	ldh		a, ($ac)		; $11c7: $f0 $ac 
	and		$01			; $11c9: $e6 $01 
	ret		nz			; $11cb: $c0 
	ld		hl, $c030		; $11cc: $21 $30 $c0 
	dec		(hl)			; $11cf: $35 
	ldi		a, (hl)			; $11d0: $2a 
	cp		$20			; $11d1: $fe $20 
	jr		c, $14			; $11d3: $38 $14 
	ldh		a, ($fb)		; $11d5: $f0 $fb 
	and		a			; $11d7: $a7 
	ld		a, (hl)			; $11d8: $7e 
	jr		nz, $07			; $11d9: $20 $07 
	dec		(hl)			; $11db: $35 
	cp		$30			; $11dc: $fe $30 
	ret		nc			; $11de: $d0 
	ldh		($fb), a		; $11df: $e0 $fb 
	ret					; $11e1: $c9 
	inc		(hl)			; $11e2: $34 
	cp		$50			; $11e3: $fe $50 
	ret		c			; $11e5: $d8 
	xor		a			; $11e6: $af 
	jr		-$0a			; $11e7: $18 $f6 
	ld		(hl), $f0		; $11e9: $36 $f0 
	ld		b, $6d			; $11eb: $06 $6d 
	ld		hl, $98a5		; $11ed: $21 $a5 $98 
	ldh		a, ($41)		; $11f0: $f0 $41 
	and		$03			; $11f2: $e6 $03 
	jr		nz, -$06			; $11f4: $20 $fa 
	ldh		a, ($41)		; $11f6: $f0 $41 
	and		$03			; $11f8: $e6 $03 
	jr		nz, -$06			; $11fa: $20 $fa 
	ld		(hl), $2c		; $11fc: $36 $2c 
	inc		hl			; $11fe: $23 
	dec		b			; $11ff: $05 
	jr		nz, -$12			; $1200: $20 $ee 
	xor		a			; $1202: $af 
	ldh		($fb), a		; $1203: $e0 $fb 
	ld		a, $99			; $1205: $3e $99 
	ldh		($e2), a		; $1207: $e0 $e2 
	ld		a, $00			; $1209: $3e $00 
	ldh		($e3), a		; $120b: $e0 $e3 
	ld		hl, $ffb3		; $120d: $21 $b3 $ff 
	inc		(hl)			; $1210: $34 
	ret					; $1211: $c9 
; end rotuine

; rotuine
; wait then walk
WAIT_THEN_WALK:
	ld		hl, $1236		; $1212: $21 $36 $12 
	call		$0f81			; $1215: $cd $81 $0f 
	cp		$ff			; $1218: $fe $ff 
	ret		nz			; $121a: $c0 
	ld		hl, $c213		; $121b: $21 $13 $c2 
	ld		(hl), $24		; $121e: $36 $24 
	inc		l			; $1220: $2c 
	inc		l			; $1221: $2c 
	ld		(hl), $00		; $1222: $36 $00 
	ld		hl, $c241		; $1224: $21 $41 $c2 
	ld		(hl), $7e		; $1227: $36 $7e 
	inc		l			; $1229: $2c 
	inc		l			; $122a: $2c 
	ld		(hl), $28		; $122b: $36 $28 
	inc		l			; $122d: $2c 
	inc		l			; $122e: $2c 
	ld		(hl), $00		; $122f: $36 $00 
	ld		hl, $ffb3		; $1231: $21 $b3 $ff 
	inc		(hl)			; $1234: $34 
	ret					; $1235: $c9 
; end routine

; data
	add		hl, hl			; $1236: $29 
	ldi		(hl), a			; $1237: $22 
	jr		$1e			; $1238: $18 $1e 
	dec		de			; $123a: $1b 
	inc		l			; $123b: $2c 
	ld		a, (de)			; $123c: $1a 
	ld		e, $0e			; $123d: $1e $0e 
	inc		e			; $123f: $1c 
	dec		e			; $1240: $1d 
	inc		l			; $1241: $2c 
	ld		(de), a			; $1242: $12 
	inc		e			; $1243: $1c 
	inc		l			; $1244: $2c 
	jr		$1f			; $1245: $18 $1f 
	ld		c, $1b			; $1247: $0e $1b 
	add		hl, hl			; $1249: $29 
	rst		$38			; $124a: $ff 
; end data

; routine
; walks right with the princess
WALK_WITH_PRINCESS:
	ldh		a, ($ac)		; $124b: $f0 $ac 
	and		$03			; $124d: $e6 $03 
	jr		nz, $07			; $124f: $20 $07 
	ld		hl, $c213		; $1251: $21 $13 $c2 
	ld		a, (hl)			; $1254: $7e 
	xor		$01			; $1255: $ee $01 
	ld		(hl), a			; $1257: $77 
	ld		hl, $c240		; $1258: $21 $40 $c2 
	ld		a, (hl)			; $125b: $7e 
	and		a			; $125c: $a7 
	jr		nz, $20			; $125d: $20 $20 
	inc		l			; $125f: $2c 
	inc		l			; $1260: $2c 
	dec		(hl)			; $1261: $35 
	ld		a, (hl)			; $1262: $7e 
	cp		$50			; $1263: $fe $50 
	jr		nz, $07			; $1265: $20 $07 
	ld		a, $80			; $1267: $3e $80 
	ld		($c200), a		; $1269: $ea $00 $c2 
	jr		$11			; $126c: $18 $11 
	cp		$40			; $126e: $fe $40 
	jr		nz, $0d			; $1270: $20 $0d 
	ld		a, $80			; $1272: $3e $80 
	ld		($c210), a		; $1274: $ea $10 $c2 
	ld		a, $40			; $1277: $3e $40 
	ldh		($a6), a		; $1279: $e0 $a6 
	ld		hl, $ffb3		; $127b: $21 $b3 $ff 
	inc		(hl)			; $127e: $34 
	call		$0eb2			; $127f: $cd $b2 $0e 
	call		$218f			; $1282: $cd $8f $21 
	ldh		a, ($e5)		; $1285: $f0 $e5 
	cp		$03			; $1287: $fe $03 
	ret		nz			; $1289: $c0 
	ldh		a, ($e6)		; $128a: $f0 $e6 
	and		a			; $128c: $a7 
	ret		nz			; $128d: $c0 
	ld		hl, $c240		; $128e: $21 $40 $c2 
	ld		(hl), $00		; $1291: $36 $00 
	inc		l			; $1293: $2c 
	inc		l			; $1294: $2c 
	ld		(hl), $c0		; $1295: $36 $c0 
	ret					; $1297: $c9 
; end routine

; routine
ENTER_WAIT_THEN_SPEED:
	ldh		a, ($a6)		; $1298: $f0 $a6 
	and		a			; $129a: $a7 
	ret		nz			; $129b: $c0 
	ld		hl, $c240		; $129c: $21 $40 $c2 
	ld		de, $c200		; $129f: $11 $00 $c2 
	ld		b, $06			; $12a2: $06 $06 
	ldi		a, (hl)			; $12a4: $2a 
	ld		(de), a			; $12a5: $12 
	inc		e			; $12a6: $1c 
	dec		b			; $12a7: $05 
	jr		nz, -$06			; $12a8: $20 $fa 
	ld		hl, $c203		; $12aa: $21 $03 $c2 
	ld		(hl), $26		; $12ad: $36 $26 
	ld		hl, $c241		; $12af: $21 $41 $c2 
	ld		(hl), $f0		; $12b2: $36 $f0 
	ld		hl, $ffb3		; $12b4: $21 $b3 $ff 
	inc		(hl)			; $12b7: $34 
	ret					; $12b8: $c9 
; end routine

; routine
WAIT_THEN_SPEED:
	call		$172d			; $12b9: $cd $2d $17 
	ldh		a, ($ac)		; $12bc: $f0 $ac 
	ld		b, a			; $12be: $47 
	and		$01			; $12bf: $e6 $01 
	ret		nz			; $12c1: $c0 
	ld		hl, $c240		; $12c2: $21 $40 $c2 
	ld		(hl), $ff		; $12c5: $36 $ff 
	ld		hl, $c201		; $12c7: $21 $01 $c2 
	dec		(hl)			; $12ca: $35 
	ldi		a, (hl)			; $12cb: $2a 
	cp		$58			; $12cc: $fe $58 
	jr		z, $04			; $12ce: $28 $04 
	call		ROUTINE_23		; $12d0: $cd $dd $12 
	ret					; $12d3: $c9 
	ld		hl, $ffb3		; $12d4: $21 $b3 $ff 
	inc		(hl)			; $12d7: $34 
	ld		a, $04			; $12d8: $3e $04 
	ldh		($fb), a		; $12da: $e0 $fb 
	ret					; $12dc: $c9 
; end routine

; routine
ROUTINE_23:
	ldh		a, ($ac)		; $12dd: $f0 $ac 
	and		$03			; $12df: $e6 $03 
	ret		nz			; $12e1: $c0 
	inc		l			; $12e2: $2c 
	ld		a, (hl)			; $12e3: $7e 
	xor		$01			; $12e4: $ee $01 
	ld		(hl), a			; $12e6: $77 
	ret					; $12e7: $c9 
; end routine

; routine
SPEED_SCREEN_RIGHT:
	call		ROUTINE_24		; $12e8: $cd $05 $13 
	call		$218f			; $12eb: $cd $8f $21 
	ldh		a, ($a4)		; $12ee: $f0 $a4 
	inc		a			; $12f0: $3c 
	call		z, ROUTINE_25		; $12f1: $cc $0f $13 
	inc		a			; $12f4: $3c 
	call		z, ROUTINE_25		; $12f5: $cc $0f $13 
	ldh		($a4), a		; $12f8: $e0 $a4 
	ld		a, ($dfe9)		; $12fa: $fa $e9 $df 
	and		a			; $12fd: $a7 
	ret		nz			; $12fe: $c0 
	ld		a, $11			; $12ff: $3e $11 
	ld		($dfe8), a		; $1301: $ea $e8 $df 
	ret					; $1304: $c9 
; end routine

; routine
ROUTINE_24:
	ld		hl, $c202		; $1305: $21 $02 $c2 
	call		ROUTINE_23		; $1308: $cd $dd $12 
	call		$172d			; $130b: $cd $2d $17 
	ret					; $130e: $c9 
; end routine

; routine
ROUTINE_25:
	push		af			; $130f: $f5 
	ldh		a, ($fb)		; $1310: $f0 $fb 
	dec		a			; $1312: $3d 
	ldh		($fb), a		; $1313: $e0 $fb 
	jr		nz, $2c			; $1315: $20 $2c 
	ldh		($45), a		; $1317: $e0 $45 
	ld		a, $21			; $1319: $3e $21 
	ldh		($fb), a		; $131b: $e0 $fb 
	ld		a, $54			; $131d: $3e $54 
	ldh		($e9), a		; $131f: $e0 $e9 
	call		ROUTINE_26		; $1321: $cd $45 $13 
	ld		hl, $c210		; $1324: $21 $10 $c2 
	ld		de, $1376		; $1327: $11 $76 $13 
	call		ROUTINE_27		; $132a: $cd $6d $13 
	ld		hl, $c220		; $132d: $21 $20 $c2 
	ld		de, $137b		; $1330: $11 $7b $13 
	call		ROUTINE_27		; $1333: $cd $6d $13 
	ld		hl, $c230		; $1336: $21 $30 $c2 
	ld		de, $1380		; $1339: $11 $80 $13 
	call		ROUTINE_27		; $133c: $cd $6d $13 
	ld		hl, $ffb3		; $133f: $21 $b3 $ff 
	inc		(hl)			; $1342: $34 
	pop		af			; $1343: $f1 
	ret					; $1344: $c9 
; end routine

; routine
ROUTINE_26:
	ld		hl, $c0b0		; $1345: $21 $b0 $c0 
	ld		b, $10			; $1348: $06 $10 
	ld		a, $2c			; $134a: $3e $2c 
	ldi		(hl), a			; $134c: $22 
	dec		b			; $134d: $05 
	jr		nz, -$04			; $134e: $20 $fc 
	ld		a, $01			; $1350: $3e $01 
	ldh		($ea), a		; $1352: $e0 $ea 
	ld		b, $02			; $1354: $06 $02 
	ldh		a, ($e9)		; $1356: $f0 $e9 
	sub		$20			; $1358: $d6 $20 
	ld		l, a			; $135a: $6f 
	ld		h, $98			; $135b: $26 $98 
	ldh		a, ($41)		; $135d: $f0 $41 
	and		$03			; $135f: $e6 $03 
	jr		nz, -$06			; $1361: $20 $fa 
	ld		(hl), $2c		; $1363: $36 $2c 
	ld		a, l			; $1365: $7d 
	sub		$20			; $1366: $d6 $20 
	ld		l, a			; $1368: $6f 
	dec		b			; $1369: $05 
	jr		nz, -$0f			; $136a: $20 $f1 
	ret					; $136c: $c9 
; end routine

; routine
ROUTINE_27:
	ld		b, $05			; $136d: $06 $05 
	ld		a, (de)			; $136f: $1a 
	ldi		(hl), a			; $1370: $22 
	inc		de			; $1371: $13 
	dec		b			; $1372: $05 
	jr		nz, -$06			; $1373: $20 $fa 
	ret					; $1375: $c9 
; end routine

; data
.db $00 $30 $d0 $29 $80
.db $80 $70 $10 $2a $80
.db $80 $40 $70 $29 $80
; end data

; routine
; wipse the bg clear for credits
WIPE_BG:
	call		$1547			; $1385: $cd $47 $15 
	ldh		a, ($a4)		; $1388: $f0 $a4 
	inc		a			; $138a: $3c 
	inc		a			; $138b: $3c 
	ldh		($a4), a		; $138c: $e0 $a4 
	and		$08			; $138e: $e6 $08 
	ld		b, a			; $1390: $47 
	ldh		a, ($a3)		; $1391: $f0 $a3 
	cp		b			; $1393: $b8 
	ret		nz			; $1394: $c0 
	xor		$08			; $1395: $ee $08 
	ldh		($a3), a		; $1397: $e0 $a3 
	call		ROUTINE_26		; $1399: $cd $45 $13 
	ldh		a, ($fb)		; $139c: $f0 $fb 
	dec		a			; $139e: $3d 
	ldh		($fb), a		; $139f: $e0 $fb 
	ret		nz			; $13a1: $c0 
	xor		a			; $13a2: $af 
	ldh		($a4), a		; $13a3: $e0 $a4 
	ld		a, $60			; $13a5: $3e $60 
	ldh		($45), a		; $13a7: $e0 $45 
	ld		hl, $154e		; $13a9: $21 $4e $15 
	ld		a, h			; $13ac: $7c 
	ldh		($e2), a		; $13ad: $e0 $e2 
	ld		a, l			; $13af: $7d 
	ldh		($e3), a		; $13b0: $e0 $e3 
	ld		a, $f0			; $13b2: $3e $f0 
	ldh		($a6), a		; $13b4: $e0 $a6 
	ld		hl, $ffb3		; $13b6: $21 $b3 $ff 
	inc		(hl)			; $13b9: $34 
	ret					; $13ba: $c9 
; end routine

; routine
ROUTINE_2A:
	ld		hl, $c212		; $13bb: $21 $12 $c2 
	ld		de, $0010		; $13be: $11 $10 $00 
	ld		b, $03			; $13c1: $06 $03 
	dec		(hl)			; $13c3: $35 
	ld		a, (hl)			; $13c4: $7e 
	cp		$01			; $13c5: $fe $01 
	jr		nz, $04			; $13c7: $20 $04 
	ld		(hl), $fe		; $13c9: $36 $fe 
	jr		$15			; $13cb: $18 $15 
	cp		$e0			; $13cd: $fe $e0 
	jr		nz, $11			; $13cf: $20 $11 
	push		hl			; $13d1: $e5 
	ldh		a, ($04)		; $13d2: $f0 $04 
	dec		l			; $13d4: $2d 
	add		(hl)			; $13d5: $86 
	and		$7f			; $13d6: $e6 $7f 
	cp		$68			; $13d8: $fe $68 
	jr		nc, $02			; $13da: $30 $02 
	and		$3f			; $13dc: $e6 $3f 
	ldd		(hl), a			; $13de: $32 
	ld		(hl), $00		; $13df: $36 $00 
	pop		hl			; $13e1: $e1 
	add		hl, de			; $13e2: $19 
	dec		b			; $13e3: $05 
	jr		nz, -$23			; $13e4: $20 $dd 
	ret					; $13e6: $c9 
; end routine

; routine
START_CREDITS:
	call		$1547			; $13e7: $cd $47 $15 
	ldh		a, ($a6)		; $13ea: $f0 $a6 
	and		a			; $13ec: $a7 
	ret		nz			; $13ed: $c0 
	ldh		a, ($e2)		; $13ee: $f0 $e2 
	ld		h, a			; $13f0: $67 
	ldh		a, ($e3)		; $13f1: $f0 $e3 
	ld		l, a			; $13f3: $6f 
	ld		de, $9a42		; $13f4: $11 $42 $9a 
	ld		a, (hl)			; $13f7: $7e 
	cp		$fe			; $13f8: $fe $fe 
	jr		z, $1c			; $13fa: $28 $1c 
	inc		hl			; $13fc: $23 
	ld		b, a			; $13fd: $47 
	ldh		a, ($41)		; $13fe: $f0 $41 
	and		$03			; $1400: $e6 $03 
	jr		nz, -$06			; $1402: $20 $fa 
	ldh		a, ($41)		; $1404: $f0 $41 
	and		$03			; $1406: $e6 $03 
	jr		nz, -$06			; $1408: $20 $fa 
	ld		a, b			; $140a: $78 
	ld		(de), a			; $140b: $12 
	inc		de			; $140c: $13 
	ld		a, e			; $140d: $7b 
	cp		$54			; $140e: $fe $54 
	jr		z, $0a			; $1410: $28 $0a 
	cp		$93			; $1412: $fe $93 
	jr		z, $0c			; $1414: $28 $0c 
	jr		-$21			; $1416: $18 $df 
	ld		b, $2c			; $1418: $06 $2c 
	jr		-$1e			; $141a: $18 $e2 
	ld		de, $9a87		; $141c: $11 $87 $9a 
	inc		hl			; $141f: $23 
	jr		-$2b			; $1420: $18 $d5 
	inc		hl			; $1422: $23 
	ld		a, (hl)			; $1423: $7e 
	cp		$ff			; $1424: $fe $ff 
	jr		nz, $05			; $1426: $20 $05 
	ld		a, $ff			; $1428: $3e $ff 
	ld		($c0de), a		; $142a: $ea $de $c0 
	ld		a, h			; $142d: $7c 
	ldh		($e2), a		; $142e: $e0 $e2 
	ld		a, l			; $1430: $7d 
	ldh		($e3), a		; $1431: $e0 $e3 
	ld		hl, $ffb3		; $1433: $21 $b3 $ff 
	inc		(hl)			; $1436: $34 
	ret					; $1437: $c9 
; end routine

; routine
SCROLL_CREDITS_0:
	call		$1547			; $1438: $cd $47 $15 
	ldh		a, ($ac)		; $143b: $f0 $ac 
	and		$03			; $143d: $e6 $03 
	ret		nz			; $143f: $c0 
	ld		hl, $c0df		; $1440: $21 $df $c0 
	inc		(hl)			; $1443: $34 
	ld		a, (hl)			; $1444: $7e 
	cp		$20			; $1445: $fe $20 
	ret		nz			; $1447: $c0 
	ld		hl, $ffb3		; $1448: $21 $b3 $ff 
	inc		(hl)			; $144b: $34 
	ld		a, $50			; $144c: $3e $50 
	ldh		($a6), a		; $144e: $e0 $a6 
	ret					; $1450: $c9 
; end routine

; routine
; still scrolling??
SCROLL_CREDITS_1:
	call		$1547			; $1451: $cd $47 $15 
	ldh		a, ($a6)		; $1454: $f0 $a6 
	and		a			; $1456: $a7 
	ret		nz			; $1457: $c0 
	ld		hl, $ffb3		; $1458: $21 $b3 $ff 
	inc		(hl)			; $145b: $34 
	ret					; $145c: $c9 
; end routine

; routine
; still scrolling???
SCROLL_CREDITS_2:
	call		$1547			; $145d: $cd $47 $15 
	ldh		a, ($ac)		; $1460: $f0 $ac 
	and		$03			; $1462: $e6 $03 
	ret		nz			; $1464: $c0 
	ld		hl, $c0df		; $1465: $21 $df $c0 
	inc		(hl)			; $1468: $34 
	ld		a, (hl)			; $1469: $7e 
	cp		$50			; $146a: $fe $50 
	ret		nz			; $146c: $c0 
	xor		a			; $146d: $af 
	ld		($c0df), a		; $146e: $ea $df $c0 
	ld		a, ($c0de)		; $1471: $fa $de $c0 
	cp		$ff			; $1474: $fe $ff 
	ld		a, $33			; $1476: $3e $33 
	jr		nz, $02			; $1478: $20 $02 
	ld		a, $37			; $147a: $3e $37 
	ldh		($b3), a		; $147c: $e0 $b3 
	ret					; $147e: $c9 
; end routine

; routine
; pause before THE END
CREDITS_PAUSE:
	call		$1547			; $147f: $cd $47 $15 
	ld		hl, $c202		; $1482: $21 $02 $c2 
	inc		(hl)			; $1485: $34 
	ld		a, (hl)			; $1486: $7e 
	cp		$d0			; $1487: $fe $d0 
	ret		nz			; $1489: $c0 
	dec		l			; $148a: $2d 
	ld		(hl), $f0		; $148b: $36 $f0 
	push		hl			; $148d: $e5 
	call		$172d			; $148e: $cd $2d $17 
	pop		hl			; $1491: $e1 
	dec		l			; $1492: $2d 
	ld		(hl), $ff		; $1493: $36 $ff 
	ld		hl, $c070		; $1495: $21 $70 $c0 
	ld		de, $14bb		; $1498: $11 $bb $14 
	ld		b, $18			; $149b: $06 $18 
	ld		a, (de)			; $149d: $1a 
	ldi		(hl), a			; $149e: $22 
	inc		de			; $149f: $13 
	dec		b			; $14a0: $05 
	jr		nz, -$06			; $14a1: $20 $fa 
	ld		b, $18			; $14a3: $06 $18 
	xor		a			; $14a5: $af 
	ldi		(hl), a			; $14a6: $22 
	dec		b			; $14a7: $05 
	jr		nz, -$04			; $14a8: $20 $fc 
	ld		a, $90			; $14aa: $3e $90 
	ldh		($a6), a		; $14ac: $e0 $a6 
	ldh		a, ($9a)		; $14ae: $f0 $9a 
	inc		a			; $14b0: $3c 
	ldh		($9a), a		; $14b1: $e0 $9a 
	ld		($c0e1), a		; $14b3: $ea $e1 $c0 
	ld		hl, $ffb3		; $14b6: $21 $b3 $ff 
	inc		(hl)			; $14b9: $34 
	ret					; $14ba: $c9 
; end routine

; data
.db $4e $cc $52 $00
.db $4e $d4 $53 $00
.db $4e $dc $54 $00
.db $4e $ec $54 $00
.db $4e $f4 $55 $00
.db $4e $fc $56 $00
; end data

; routine
; displays THE END
THE_END:
	call		$1547			; $14d3: $cd $47 $15 
	ldh		a, ($a6)		; $14d6: $f0 $a6 
	and		a			; $14d8: $a7 
	ret		nz			; $14d9: $c0 
	ld		hl, $c071		; $14da: $21 $71 $c0 
	ld		a, (hl)			; $14dd: $7e 
	cp		$3c			; $14de: $fe $3c 
	jr		z, $04			; $14e0: $28 $04 
	dec		(hl)			; $14e2: $35 
	dec		(hl)			; $14e3: $35 
	dec		(hl)			; $14e4: $35 
	ret					; $14e5: $c9 
	ld		hl, $c075		; $14e6: $21 $75 $c0 
	ld		a, (hl)			; $14e9: $7e 
	cp		$44			; $14ea: $fe $44 
	jr		nz, -$0c			; $14ec: $20 $f4 
	ld		hl, $c079		; $14ee: $21 $79 $c0 
	ld		a, (hl)			; $14f1: $7e 
	cp		$4c			; $14f2: $fe $4c 
	jr		nz, -$14			; $14f4: $20 $ec 
	ld		hl, $c07d		; $14f6: $21 $7d $c0 
	ld		a, (hl)			; $14f9: $7e 
	cp		$5c			; $14fa: $fe $5c 
	jr		nz, -$1c			; $14fc: $20 $e4 
	ld		hl, $c081		; $14fe: $21 $81 $c0 
	ld		a, (hl)			; $1501: $7e 
	cp		$64			; $1502: $fe $64 
	jr		nz, -$24			; $1504: $20 $dc 
	ld		hl, $c085		; $1506: $21 $85 $c0 
	ld		a, (hl)			; $1509: $7e 
	cp		$6c			; $150a: $fe $6c 
	jr		nz, -$2c			; $150c: $20 $d4 
	call		ROUTINE_28		; $150e: $cd $20 $15 
	xor		a			; $1511: $af 
	ldh		($e4), a		; $1512: $e0 $e4 
	ldh		($99), a		; $1514: $e0 $99 
	ldh		($b5), a		; $1516: $e0 $b5 
	ld		($c0a6), a		; $1518: $ea $a6 $c0 
	ld		a, $11			; $151b: $3e $11 
	ldh		($b4), a		; $151d: $e0 $b4 
	ret					; $151f: $c9 
; end routine

; routine
ROUTINE_28:
	ldh		a, ($81)		; $1520: $f0 $81 
	and		a			; $1522: $a7 
	ret		z			; $1523: $c8 
	call		$7ff3			; $1524: $cd $f3 $7f 
	ld		a, $02			; $1527: $3e $02 
	ldh		($fd), a		; $1529: $e0 $fd 
	ld		($2000), a		; $152b: $ea $00 $20 
	ld		($c0dc), a		; $152e: $ea $dc $c0 
	ld		($c0a4), a		; $1531: $ea $a4 $c0 
	xor		a			; $1534: $af 
	ld		($da00), a		; $1535: $ea $00 $da 
	ld		($c0a5), a		; $1538: $ea $a5 $c0 
	ld		($c0ad), a		; $153b: $ea $ad $c0 
	ld		a, $03			; $153e: $3e $03 
	ldh		($ff), a		; $1540: $e0 $ff 
	ld		a, $0e			; $1542: $3e $0e 
	ldh		($b3), a		; $1544: $e0 $b3 
	ret					; $1546: $c9 
; end routine

; routine
ROUTINE_29:
	call		ROUTINE_24		; $1547: $cd $05 $13 
	call		ROUTINE_2A		; $154a: $cd $bb $13 
	ret					; $154d: $c9 
; end routine

	add		hl, de			; $154e: $19 
	dec		de			; $154f: $1b 
	jr		$0d			; $1550: $18 $0d 
	ld		e, $0c			; $1552: $1e $0c 
	ld		c, $1b			; $1554: $0e $1b 
	cp		$10			; $1556: $fe $10 
	inc		hl			; $1558: $23 
	ldi		(hl), a			; $1559: $22 
	jr		$14			; $155a: $18 $14 
	jr		$12			; $155c: $18 $12 
	cp		$0d			; $155e: $fe $0d 
	ld		(de), a			; $1560: $12 
	dec		de			; $1561: $1b 
	ld		c, $0c			; $1562: $0e $0c 
	dec		e			; $1564: $1d 
	jr		$1b			; $1565: $18 $1b 
	cp		$1c			; $1567: $fe $1c 
	inc		hl			; $1569: $23 
	jr		$14			; $156a: $18 $14 
	ld		a, (bc)			; $156c: $0a 
	dec		c			; $156d: $0d 
	ld		a, (bc)			; $156e: $0a 
	cp		$19			; $156f: $fe $19 
	dec		de			; $1571: $1b 
	jr		$10			; $1572: $18 $10 
	dec		de			; $1574: $1b 
	ld		a, (bc)			; $1575: $0a 
	ld		d, $16			; $1576: $16 $16 
	ld		c, $1b			; $1578: $0e $1b 
	cp		$16			; $157a: $fe $16 
	inc		hl			; $157c: $23 
	ldi		(hl), a			; $157d: $22 
	ld		a, (bc)			; $157e: $0a 
	ld		d, $0a			; $157f: $16 $0a 
	ld		d, $18			; $1581: $16 $18 
	dec		e			; $1583: $1d 
	jr		-$02			; $1584: $18 $fe 
	add		hl, de			; $1586: $19 
	dec		de			; $1587: $1b 
	jr		$10			; $1588: $18 $10 
	dec		de			; $158a: $1b 
	ld		a, (bc)			; $158b: $0a 
	ld		d, $16			; $158c: $16 $16 
	ld		c, $1b			; $158e: $0e $1b 
	cp		$1d			; $1590: $fe $1d 
	inc		hl			; $1592: $23 
	ld		de, $1b0a		; $1593: $11 $0a $1b 
	ld		a, (bc)			; $1596: $0a 
	dec		c			; $1597: $0d 
	ld		a, (bc)			; $1598: $0a 
	cp		$0d			; $1599: $fe $0d 
	ld		c, $1c			; $159b: $0e $1c 
	ld		(de), a			; $159d: $12 
	stop					; $159e: $10 
	rla					; $159f: $17 
	cp		$11			; $15a0: $fe $11 
	inc		hl			; $15a2: $23 
	ld		d, $0a			; $15a3: $16 $0a 
	dec		e			; $15a5: $1d 
	inc		e			; $15a6: $1c 
	ld		e, $18			; $15a7: $1e $18 
	inc		d			; $15a9: $14 
	ld		a, (bc)			; $15aa: $0a 
	cp		$1c			; $15ab: $fe $1c 
	jr		$1e			; $15ad: $18 $1e 
	rla					; $15af: $17 
	dec		c			; $15b0: $0d 
	cp		$11			; $15b1: $fe $11 
	inc		hl			; $15b3: $23 
	dec		e			; $15b4: $1d 
	ld		a, (bc)			; $15b5: $0a 
	rla					; $15b6: $17 
	ld		a, (bc)			; $15b7: $0a 
	inc		d			; $15b8: $14 
	ld		a, (bc)			; $15b9: $0a 
	cp		$0a			; $15ba: $fe $0a 
	ld		d, $12			; $15bc: $16 $12 
	dec		c			; $15be: $0d 
	ld		a, (bc)			; $15bf: $0a 
	cp		$16			; $15c0: $fe $16 
	inc		hl			; $15c2: $23 
	ldi		(hl), a			; $15c3: $22 
	ld		a, (bc)			; $15c4: $0a 
	ld		d, $0a			; $15c5: $16 $0a 
	rla					; $15c7: $17 
	ld		a, (bc)			; $15c8: $0a 
	inc		d			; $15c9: $14 
	ld		a, (bc)			; $15ca: $0a 
	cp		$0d			; $15cb: $fe $0d 
	ld		c, $1c			; $15cd: $0e $1c 
	ld		(de), a			; $15cf: $12 
	stop					; $15d0: $10 
	rla					; $15d1: $17 
	cp		$16			; $15d2: $fe $16 
	ld		a, (bc)			; $15d4: $0a 
	inc		e			; $15d5: $1c 
	ld		de, $1612		; $15d6: $11 $12 $16 
	jr		-$02			; $15d9: $18 $fe 
	inc		e			; $15db: $1c 
	add		hl, de			; $15dc: $19 
	ld		c, $0c			; $15dd: $0e $0c 
	ld		(de), a			; $15df: $12 
	ld		a, (bc)			; $15e0: $0a 
	dec		d			; $15e1: $15 
	inc		l			; $15e2: $2c 
	dec		e			; $15e3: $1d 
	ld		de, $170a		; $15e4: $11 $0a $17 
	inc		d			; $15e7: $14 
	inc		e			; $15e8: $1c 
	inc		l			; $15e9: $2c 
	dec		e			; $15ea: $1d 
	jr		$25			; $15eb: $18 $25 
	cp		$1d			; $15ed: $fe $1d 
	ld		a, (bc)			; $15ef: $0a 
	inc		d			; $15f0: $14 
	ld		(de), a			; $15f1: $12 
	cp		$12			; $15f2: $fe $12 
	daa					; $15f4: $27 
	ld		e, $1c			; $15f5: $1e $1c 
	ld		de, $fe12		; $15f7: $11 $12 $fe 
	rla					; $15fa: $17 
	ld		a, (bc)			; $15fb: $0a 
	stop					; $15fc: $10 
	ld		a, (bc)			; $15fd: $0a 
	dec		e			; $15fe: $1d 
	ld		a, (bc)			; $15ff: $0a 
	cp		$14			; $1600: $fe $14 
	ld		a, (bc)			; $1602: $0a 
	rla					; $1603: $17 
	jr		$11			; $1604: $18 $11 
	cp		$17			; $1606: $fe $17 
	ld		(de), a			; $1608: $12 
	inc		e			; $1609: $1c 
	ld		de, $2712		; $160a: $11 $12 $27 
	ld		a, (bc)			; $160d: $0a 
	jr		nz, $0a			; $160e: $20 $0a 
	cp		$ff			; $1610: $fe $ff 

; routine
ENTER_PIPE_DOWN:
	ld		hl, $c201		; $1612: $21 $01 $c2 
	ldh		a, ($f8)		; $1615: $f0 $f8 
	cp		(hl)			; $1617: $be 
	jr		z, $05			; $1618: $28 $05 
	inc		(hl)			; $161a: $34 
	call		$16ec			; $161b: $cd $ec $16 
	ret					; $161e: $c9 
	ld		a, $0a			; $161f: $3e $0a 
	ldh		($b3), a		; $1621: $e0 $b3 
	ldh		($f9), a		; $1623: $e0 $f9 
	ret					; $1625: $c9 
; end routine

; routine
; exit pipe?
EXIT_PIPE:
	di					; $1626: $f3 
	xor		a			; $1627: $af 
	ldh		($40), a		; $1628: $e0 $40 
	ldh		($e6), a		; $162a: $e0 $e6 
	call		$1ecb			; $162c: $cd $cb $1e 
	call		$1655			; $162f: $cd $55 $16 
	ldh		a, ($f4)		; $1632: $f0 $f4 
	ldh		($e5), a		; $1634: $e0 $e5 
	call		$07f0			; $1636: $cd $f0 $07 
	call		$2453			; $1639: $cd $53 $24 
	ld		hl, $c201		; $163c: $21 $01 $c2 
	ld		(hl), $20		; $163f: $36 $20 
	inc		l			; $1641: $2c 
	ld		(hl), $1d		; $1642: $36 $1d 
	inc		l			; $1644: $2c 
	inc		l			; $1645: $2c 
	ld		(hl), $00		; $1646: $36 $00 
	xor		a			; $1648: $af 
	ldh		($0f), a		; $1649: $e0 $0f 
	ldh		($b3), a		; $164b: $e0 $b3 
	ldh		($a4), a		; $164d: $e0 $a4 
	ld		a, $c3			; $164f: $3e $c3 
	ldh		($40), a		; $1651: $e0 $40 
	ei					; $1653: $fb 
	ret					; $1654: $c9 
; end routine

; routine
; clears wram from c800h to ca3f
; which seems like its that map buffer correspondant thing????
ROUTINE_11:
	ld		hl, $ca3f		; $1655: $21 $3f $ca 
	ld		bc, $0240		; $1658: $01 $40 $02 
-	xor		a			; $165b: $af 
	ldd		(hl), a			; $165c: $32 
	dec		bc			; $165d: $0b 
	ld		a, b			; $165e: $78 
	or		c			; $165f: $b1 
	jr		nz, -			; $1660: $20 $f9 
	ret					; $1662: $c9 
; end routine

; routine
ENTER_PIPE_RIGHT:
	ldh		a, ($ac)		; $1663: $f0 $ac 
	and		$01			; $1665: $e6 $01 
	ret		z			; $1667: $c8 
	ld		hl, $c202		; $1668: $21 $02 $c2 
	ldh		a, ($f8)		; $166b: $f0 $f8 
	cp		(hl)			; $166d: $be 
	jr		c, $09			; $166e: $38 $09 
	inc		(hl)			; $1670: $34 
	ld		hl, $c20b		; $1671: $21 $0b $c2 
	inc		(hl)			; $1674: $34 
	call		$16ec			; $1675: $cd $ec $16 
	ret					; $1678: $c9 

	di					; $1679: $f3 
	ldh		a, ($f5)		; $167a: $f0 $f5 
	ldh		($e5), a		; $167c: $e0 $e5 
	xor		a			; $167e: $af 
	ldh		($40), a		; $167f: $e0 $40 
	ldh		($e6), a		; $1681: $e0 $e6 
	call		$1655			; $1683: $cd $55 $16 
	ld		hl, $fff4		; $1686: $21 $f4 $ff 
	ldi		(hl), a			; $1689: $22 
	ldi		(hl), a			; $168a: $22 
	ldh		a, ($f7)		; $168b: $f0 $f7 
	ld		d, a			; $168d: $57 
	ldh		a, ($f6)		; $168e: $f0 $f6 
	ld		e, a			; $1690: $5f 
	push		de			; $1691: $d5 
	call		$07f0			; $1692: $cd $f0 $07 
	pop		de			; $1695: $d1 
	ld		a, $80			; $1696: $3e $80 
	ld		($c204), a		; $1698: $ea $04 $c2 
	ld		hl, $c201		; $169b: $21 $01 $c2 
	ld		a, d			; $169e: $7a 
	ldi		(hl), a			; $169f: $22 
	sub		$12			; $16a0: $d6 $12 
	ldh		($f8), a		; $16a2: $e0 $f8 
	ld		a, e			; $16a4: $7b 
	ld		(hl), a			; $16a5: $77 
	ldh		a, ($e5)		; $16a6: $f0 $e5 
	sub		$04			; $16a8: $d6 $04 
	ld		b, a			; $16aa: $47 
	rlca					; $16ab: $07 
	rlca					; $16ac: $07 
	rlca					; $16ad: $07 
	add		b			; $16ae: $80 
	add		b			; $16af: $80 
	add		$0c			; $16b0: $c6 $0c 
	ld		($c0ab), a		; $16b2: $ea $ab $c0 
	xor		a			; $16b5: $af 
	ldh		($0f), a		; $16b6: $e0 $0f 
	ldh		($a4), a		; $16b8: $e0 $a4 
	ld		a, $5b			; $16ba: $3e $5b 
	ldh		($e9), a		; $16bc: $e0 $e9 
	call		$2453			; $16be: $cd $53 $24 
	call		$1ecb			; $16c1: $cd $cb $1e 
	ld		a, $c3			; $16c4: $3e $c3 
	ldh		($40), a		; $16c6: $e0 $40 
	ld		a, $0c			; $16c8: $3e $0c 
	ldh		($b3), a		; $16ca: $e0 $b3 
	call		$078c			; $16cc: $cd $8c $07 
	ei					; $16cf: $fb 
	ret					; $16d0: $c9 
; end routine

; routine
ENTER_PIPE_UP:
	ldh		a, ($ac)		; $16d1: $f0 $ac 
	and		$01			; $16d3: $e6 $01 
	ret		z			; $16d5: $c8 
	ld		hl, $c201		; $16d6: $21 $01 $c2 
	ldh		a, ($f8)		; $16d9: $f0 $f8 
	cp		(hl)			; $16db: $be 
	jr		z, $05			; $16dc: $28 $05 
	dec		(hl)			; $16de: $35 
	call		$16ec			; $16df: $cd $ec $16 
	ret					; $16e2: $c9 
	xor		a			; $16e3: $af 
	ldh		($b3), a		; $16e4: $e0 $b3 
	ld		($c204), a		; $16e6: $ea $04 $c2 
	ldh		($f9), a		; $16e9: $e0 $f9 
	ret					; $16eb: $c9 
; end routine

; routine
ROUTINE_2B:
	call		ROUTINE_01		; $16ec: $cd $2d $17 
	ld		a, ($c20a)		; $16ef: $fa $0a $c2 
	and		a			; $16f2: $a7 
	jr		z, $2e			; $16f3: $28 $2e 
	ld		a, ($c203)		; $16f5: $fa $03 $c2 
	and		$0f			; $16f8: $e6 $0f 
	cp		$0a			; $16fa: $fe $0a 
	jr		nc, $25			; $16fc: $30 $25 
	ld		hl, $c20b		; $16fe: $21 $0b $c2 
	ld		a, ($c20e)		; $1701: $fa $0e $c2 
	cp		$23			; $1704: $fe $23 
	ld		a, (hl)			; $1706: $7e 
	jr		z, $1e			; $1707: $28 $1e 
	and		$03			; $1709: $e6 $03 
	jr		nz, $16			; $170b: $20 $16 
	ld		hl, $c203		; $170d: $21 $03 $c2 
	ld		a, (hl)			; $1710: $7e 
	cp		$18			; $1711: $fe $18 
	jr		z, $0e			; $1713: $28 $0e 
	inc		(hl)			; $1715: $34 
	ld		a, (hl)			; $1716: $7e 
	and		$0f			; $1717: $e6 $0f 
	cp		$04			; $1719: $fe $04 
	jr		c, $06			; $171b: $38 $06 
	ld		a, (hl)			; $171d: $7e 
	and		$f0			; $171e: $e6 $f0 
	or		$01			; $1720: $f6 $01 
	ld		(hl), a			; $1722: $77 
	call		$1d1d			; $1723: $cd $1d $1d 
	ret					; $1726: $c9 
	and		$01			; $1727: $e6 $01 
	jr		nz, -$08			; $1729: $20 $f8 
	jr		-$20			; $172b: $18 $e0 
; end routine

; routine
; this routine calls the general routine below with certain arguments
; this just wraps the draw character entity routine, with the 
; locations for the table and where to put the output
ROUTINE_01:
	; these hram vars are arguments for the below routine
	; set an hram var
	; hram($8d-$8e) is the destination address
	; that the draw_character_entity routine puts the tiles onto
	; and this destination is where marios 4 tiles in oam in wram go
	ld		a, $0c			; $172d: $3e $0c 
	ldh		($8e), a		; $172f: $e0 $8e 
	; point here in wram0?
	; THIS POINTS TO THE TABLE the below routine works on
	; this is the character entity table
	ld		hl, character_entity_table		; $1731: $21 $00 $c2 
	; set another 2 hram vars
	ld		a, $c0			; $1734: $3e $c0 
	ldh		($8d), a		; $1736: $e0 $8d 
	; this is the length of the table
	ld		a, $05			; $1738: $3e $05 
	ldh		($8f), a		; $173a: $e0 $8f 
	; switch to bank 3
	; saving the old bank to go back to
	ldh		a, (r_current_bank)		; $173c: $f0 $fd 
	ldh		(r_previous_bank), a		; $173e: $e0 $e1 
	ld		a, $03			; $1740: $3e $03 
	ldh		(r_current_bank), a		; $1742: $e0 $fd 
	ld		($2000), a		; $1744: $ea $00 $20 
	; call this routine
	; i dont know what it does but it does some
	; calculations on some complicated system of tables!
	call		DRAW_CHARACTER_ENTITY		; $1747: $cd $23 $48 
	; switching back to old bank
	; copy thta hram var BACK
	ldh		a, (r_previous_bank)		; $174a: $f0 $e1 
	ldh		(r_current_bank), a		; $174c: $e0 $fd 
	; switch to whatever bank was in hram e1!!
	ld		($2000), a		; $174e: $ea $00 $20 
	; done
	ret					; $1751: $c9 
; end routine

	ldh		a, ($b3)		; $1752: $f0 $b3 
	cp		$0e			; $1754: $fe $0e 
	jp		nc, $1815		; $1756: $d2 $15 $18 
	jp		$1b3c			; $1759: $c3 $3c $1b 
	ldh		a, ($80)		; $175c: $f0 $80 
	bit		7, a			; $175e: $cb $7f 
	jp		z, $1854		; $1760: $ca $54 $18 
	ld		bc, $ffe0		; $1763: $01 $e0 $ff 
	ld		a, h			; $1766: $7c 
	ldh		($b0), a		; $1767: $e0 $b0 
	ld		a, l			; $1769: $7d 
	ldh		($af), a		; $176a: $e0 $af 
	ld		a, h			; $176c: $7c 
	add		$30			; $176d: $c6 $30 
	ld		h, a			; $176f: $67 
	ld		de, $fff4		; $1770: $11 $f4 $ff 
	ld		a, (hl)			; $1773: $7e 
	and		a			; $1774: $a7 
	jp		z, $1854		; $1775: $ca $54 $18 
	ld		(de), a			; $1778: $12 
	inc		e			; $1779: $1c 
	add		hl, bc			; $177a: $09 
	ld		a, (hl)			; $177b: $7e 
	ld		(de), a			; $177c: $12 
	inc		e			; $177d: $1c 
	add		hl, bc			; $177e: $09 
	ld		a, (hl)			; $177f: $7e 
	ld		(de), a			; $1780: $12 
	inc		e			; $1781: $1c 
	add		hl, bc			; $1782: $09 
	ld		a, (hl)			; $1783: $7e 
	ld		(de), a			; $1784: $12 
	inc		e			; $1785: $1c 
	push		de			; $1786: $d5 
	call		$3efe			; $1787: $cd $fe $3e 
	pop		de			; $178a: $d1 
	ld		hl, $c201		; $178b: $21 $01 $c2 
	ldi		a, (hl)			; $178e: $2a 
	add		$10			; $178f: $c6 $10 
	ld		(de), a			; $1791: $12 
	ldh		a, ($a4)		; $1792: $f0 $a4 
	ld		b, a			; $1794: $47 
	ldh		a, ($ae)		; $1795: $f0 $ae 
	sub		b			; $1797: $90 
	add		$08			; $1798: $c6 $08 
	ldi		(hl), a			; $179a: $22 
	inc		l			; $179b: $2c 
	ld		(hl), $80		; $179c: $36 $80 
	ld		a, $09			; $179e: $3e $09 
	ldh		($b3), a		; $17a0: $e0 $b3 
	ld		a, ($c0d3)		; $17a2: $fa $d3 $c0 
	and		a			; $17a5: $a7 
	jr		nz, $05			; $17a6: $20 $05 
	ld		a, $04			; $17a8: $3e $04 
	ld		($dfe8), a		; $17aa: $ea $e8 $df 
	call		$1ecb			; $17ad: $cd $cb $1e 
	jp		$1854			; $17b0: $c3 $54 $18 
	ld		hl, $c207		; $17b3: $21 $07 $c2 
	ld		a, (hl)			; $17b6: $7e 
	cp		$01			; $17b7: $fe $01 
	ret		z			; $17b9: $c8 
	ld		hl, $c201		; $17ba: $21 $01 $c2 
	ldi		a, (hl)			; $17bd: $2a 
	add		$0b			; $17be: $c6 $0b 
	ldh		($ad), a		; $17c0: $e0 $ad 
	ldh		a, ($a4)		; $17c2: $f0 $a4 
	ld		b, a			; $17c4: $47 
	ld		a, (hl)			; $17c5: $7e 
	add		b			; $17c6: $80 
	add		$fe			; $17c7: $c6 $fe 
	ldh		($ae), a		; $17c9: $e0 $ae 
	call		$0153			; $17cb: $cd $53 $01 
	cp		$70			; $17ce: $fe $70 
	jr		z, -$76			; $17d0: $28 $8a 
	cp		$e1			; $17d2: $fe $e1 
	jp		z, $1752		; $17d4: $ca $52 $17 
	cp		$60			; $17d7: $fe $60 
	jr		nc, $3a			; $17d9: $30 $3a 
	ld		a, ($c20e)		; $17db: $fa $0e $c2 
	ld		b, $04			; $17de: $06 $04 
	cp		$04			; $17e0: $fe $04 
	jr		nz, $08			; $17e2: $20 $08 
	ld		a, ($c207)		; $17e4: $fa $07 $c2 
	and		a			; $17e7: $a7 
	jr		nz, $02			; $17e8: $20 $02 
	ld		b, $08			; $17ea: $06 $08 
	ldh		a, ($ae)		; $17ec: $f0 $ae 
	add		b			; $17ee: $80 
	ldh		($ae), a		; $17ef: $e0 $ae 
	call		$0153			; $17f1: $cd $53 $01 
	cp		$60			; $17f4: $fe $60 
	jr		nc, $1d			; $17f6: $30 $1d 
	ld		hl, $c207		; $17f8: $21 $07 $c2 
	ld		a, (hl)			; $17fb: $7e 
	cp		$02			; $17fc: $fe $02 
	ret		z			; $17fe: $c8 
	ld		hl, $c201		; $17ff: $21 $01 $c2 
	inc		(hl)			; $1802: $34 
	inc		(hl)			; $1803: $34 
	inc		(hl)			; $1804: $34 
	ld		hl, $c20a		; $1805: $21 $0a $c2 
	ld		(hl), $00		; $1808: $36 $00 
	ld		a, ($c20e)		; $180a: $fa $0e $c2 
	and		a			; $180d: $a7 
	ret		nz			; $180e: $c0 
	ld		a, $02			; $180f: $3e $02 
	ld		($c20e), a		; $1811: $ea $0e $c2 
	ret					; $1814: $c9 
	cp		$ed			; $1815: $fe $ed 
	push		af			; $1817: $f5 
	jr		nz, $1f			; $1818: $20 $1f 
	ld		a, ($c0d3)		; $181a: $fa $d3 $c0 
	and		a			; $181d: $a7 
	jr		nz, $19			; $181e: $20 $19 
	ldh		a, ($99)		; $1820: $f0 $99 
	and		a			; $1822: $a7 
	jr		z, $0e			; $1823: $28 $0e 
	cp		$04			; $1825: $fe $04 
	jr		z, $10			; $1827: $28 $10 
	cp		$02			; $1829: $fe $02 
	jr		nz, $0c			; $182b: $20 $0c 
	pop		af			; $182d: $f1 
	call		$09d7			; $182e: $cd $d7 $09 
	jr		$21			; $1831: $18 $21 
	pop		af			; $1833: $f1 
	call		$09e8			; $1834: $cd $e8 $09 
	jr		$1b			; $1837: $18 $1b 
	pop		af			; $1839: $f1 
	cp		$f4			; $183a: $fe $f4 
	jr		nz, $16			; $183c: $20 $16 
	push		hl			; $183e: $e5 
	pop		de			; $183f: $d1 
	ld		hl, $ffee		; $1840: $21 $ee $ff 
	ld		a, (hl)			; $1843: $7e 
	and		a			; $1844: $a7 
	jr		nz, -$4f			; $1845: $20 $b1 
	ld		(hl), $c0		; $1847: $36 $c0 
	inc		l			; $1849: $2c 
	ld		(hl), d			; $184a: $72 
	inc		l			; $184b: $2c 
	ld		(hl), e			; $184c: $73 
	ld		a, $05			; $184d: $3e $05 
	ld		($dfe0), a		; $184f: $ea $e0 $df 
	jr		-$5c			; $1852: $18 $a4 
	ld		hl, $c201		; $1854: $21 $01 $c2 
	ld		a, (hl)			; $1857: $7e 
	dec		a			; $1858: $3d 
	dec		a			; $1859: $3d 
	and		$fc			; $185a: $e6 $fc 
	or		$06			; $185c: $f6 $06 
	ld		(hl), a			; $185e: $77 
	xor		a			; $185f: $af 
	ld		hl, $c207		; $1860: $21 $07 $c2 
	ldi		(hl), a			; $1863: $22 
	ldi		(hl), a			; $1864: $22 
	ldi		(hl), a			; $1865: $22 
	ld		(hl), $01		; $1866: $36 $01 
	ld		hl, $c20c		; $1868: $21 $0c $c2 
	ld		a, (hl)			; $186b: $7e 
	cp		$07			; $186c: $fe $07 
	ret		c			; $186e: $d8 
	ld		(hl), $06		; $186f: $36 $06 
	ret					; $1871: $c9 
	ldh		a, ($ee)		; $1872: $f0 $ee 
	and		a			; $1874: $a7 
	ret		nz			; $1875: $c0 
	push		hl			; $1876: $e5 
	ld		a, h			; $1877: $7c 
	add		$30			; $1878: $c6 $30 
	ld		h, a			; $187a: $67 
	ld		a, (hl)			; $187b: $7e 
	pop		hl			; $187c: $e1 
	and		a			; $187d: $a7 
	ret		z			; $187e: $c8 
	ldh		a, ($ee)		; $187f: $f0 $ee 
	and		a			; $1881: $a7 
	ret		nz			; $1882: $c0 
	push		hl			; $1883: $e5 
	ld		a, h			; $1884: $7c 
	add		$30			; $1885: $c6 $30 
	ld		h, a			; $1887: $67 
	ld		a, (hl)			; $1888: $7e 
	pop		hl			; $1889: $e1 
	and		a			; $188a: $a7 
	jp		z, $19d8		; $188b: $ca $d8 $19 
	cp		$f0			; $188e: $fe $f0 
	jr		z, $25			; $1890: $28 $25 
	cp		$c0			; $1892: $fe $c0 
	jr		nz, $28			; $1894: $20 $28 
	ld		a, $ff			; $1896: $3e $ff 
	ld		($c0ce), a		; $1898: $ea $ce $c0 
	ldh		a, ($ee)		; $189b: $f0 $ee 
	and		a			; $189d: $a7 
	ret		nz			; $189e: $c0 
	ld		a, $05			; $189f: $3e $05 
	ld		($dfe0), a		; $18a1: $ea $e0 $df 
	ld		a, ($c201)		; $18a4: $fa $01 $c2 
	sub		$10			; $18a7: $d6 $10 
	ldh		($ec), a		; $18a9: $e0 $ec 
	ld		a, $c0			; $18ab: $3e $c0 
	ldh		($ed), a		; $18ad: $e0 $ed 
	ldh		($fe), a		; $18af: $e0 $fe 
	ld		a, ($c0ce)		; $18b1: $fa $ce $c0 
	and		a			; $18b4: $a7 
	jr		nz, $63			; $18b5: $20 $63 
	ld		a, $80			; $18b7: $3e $80 
	ld		($c02e), a		; $18b9: $ea $2e $c0 
	jr		$70			; $18bc: $18 $70 
	ldh		($a0), a		; $18be: $e0 $a0 
	ld		a, $80			; $18c0: $3e $80 
	ld		($c02e), a		; $18c2: $ea $2e $c0 
	ld		a, $07			; $18c5: $3e $07 
	ld		($dfe0), a		; $18c7: $ea $e0 $df 
	push		hl			; $18ca: $e5 
	pop		de			; $18cb: $d1 
	ld		hl, $ffee		; $18cc: $21 $ee $ff 
	ld		a, (hl)			; $18cf: $7e 
	and		a			; $18d0: $a7 
	ret		nz			; $18d1: $c0 
	ld		(hl), $02		; $18d2: $36 $02 
	inc		l			; $18d4: $2c 
	ld		(hl), d			; $18d5: $72 
	inc		l			; $18d6: $2c 
	ld		(hl), e			; $18d7: $73 
	ld		a, d			; $18d8: $7a 
	ldh		($b0), a		; $18d9: $e0 $b0 
	ld		a, e			; $18db: $7b 
	ldh		($af), a		; $18dc: $e0 $af 
	ld		a, d			; $18de: $7a 
	add		$30			; $18df: $c6 $30 
	ld		d, a			; $18e1: $57 
	ld		a, (de)			; $18e2: $1a 
	ldh		($a0), a		; $18e3: $e0 $a0 
	call		$3efe			; $18e5: $cd $fe $3e 
	ld		hl, $c02c		; $18e8: $21 $2c $c0 
	ld		a, ($c201)		; $18eb: $fa $01 $c2 
	sub		$0b			; $18ee: $d6 $0b 
	ldi		(hl), a			; $18f0: $22 
	ldh		($c2), a		; $18f1: $e0 $c2 
	ldh		($f1), a		; $18f3: $e0 $f1 
	ldh		a, ($a4)		; $18f5: $f0 $a4 
	ld		b, a			; $18f7: $47 
	ldh		a, ($ae)		; $18f8: $f0 $ae 
	ldh		($f2), a		; $18fa: $e0 $f2 
	sub		b			; $18fc: $90 
	ldi		(hl), a			; $18fd: $22 
	ldh		($c3), a		; $18fe: $e0 $c3 
	inc		l			; $1900: $2c 
	ld		(hl), $00		; $1901: $36 $00 
	ldh		a, ($a0)		; $1903: $f0 $a0 
	cp		$f0			; $1905: $fe $f0 
	ret		z			; $1907: $c8 
	cp		$28			; $1908: $fe $28 
	jr		nz, $0a			; $190a: $20 $0a 
	ldh		a, ($99)		; $190c: $f0 $99 
	cp		$02			; $190e: $fe $02 
	ld		a, $28			; $1910: $3e $28 
	jr		nz, $02			; $1912: $20 $02 
	ld		a, $2d			; $1914: $3e $2d 
	call		$2544			; $1916: $cd $44 $25 
	ret					; $1919: $c9 
	ldh		a, ($ee)		; $191a: $f0 $ee 
	and		a			; $191c: $a7 
	ret		nz			; $191d: $c0 
	ld		a, $82			; $191e: $3e $82 
	ld		($c02e), a		; $1920: $ea $2e $c0 
	ld		a, ($dfe0)		; $1923: $fa $e0 $df 
	and		a			; $1926: $a7 
	jr		nz, $05			; $1927: $20 $05 
	ld		a, $07			; $1929: $3e $07 
	ld		($dfe0), a		; $192b: $ea $e0 $df 
	push		hl			; $192e: $e5 
	pop		de			; $192f: $d1 
	ld		hl, $ffee		; $1930: $21 $ee $ff 
	ld		(hl), $02		; $1933: $36 $02 
	inc		l			; $1935: $2c 
	ld		(hl), d			; $1936: $72 
	inc		l			; $1937: $2c 
	ld		(hl), e			; $1938: $73 
	ld		a, d			; $1939: $7a 
	ldh		($b0), a		; $193a: $e0 $b0 
	ld		a, e			; $193c: $7b 
	ldh		($af), a		; $193d: $e0 $af 
	call		$3efe			; $193f: $cd $fe $3e 
	ld		hl, $c02c		; $1942: $21 $2c $c0 
	ld		a, ($c201)		; $1945: $fa $01 $c2 
	sub		$0b			; $1948: $d6 $0b 
	ldi		(hl), a			; $194a: $22 
	ldh		($f1), a		; $194b: $e0 $f1 
	ldh		a, ($a4)		; $194d: $f0 $a4 
	ld		b, a			; $194f: $47 
	ldh		a, ($ae)		; $1950: $f0 $ae 
	ld		c, a			; $1952: $4f 
	ldh		($f2), a		; $1953: $e0 $f2 
	sub		b			; $1955: $90 
	ldi		(hl), a			; $1956: $22 
	inc		l			; $1957: $2c 
	ld		(hl), $00		; $1958: $36 $00 
	ldh		($eb), a		; $195a: $e0 $eb 
	ret					; $195c: $c9 
	ldh		a, ($ee)		; $195d: $f0 $ee 
	and		a			; $195f: $a7 
	ret		nz			; $1960: $c0 
	push		hl			; $1961: $e5 
	ld		a, h			; $1962: $7c 
	add		$30			; $1963: $c6 $30 
	ld		h, a			; $1965: $67 
	ld		a, (hl)			; $1966: $7e 
	pop		hl			; $1967: $e1 
	and		a			; $1968: $a7 
	jp		nz, $1892		; $1969: $c2 $92 $18 
	ld		a, $05			; $196c: $3e $05 
	ld		($dfe0), a		; $196e: $ea $e0 $df 
	ld		a, $81			; $1971: $3e $81 
	ld		($c02e), a		; $1973: $ea $2e $c0 
	ld		a, ($c201)		; $1976: $fa $01 $c2 
	sub		$10			; $1979: $d6 $10 
	ldh		($ec), a		; $197b: $e0 $ec 
	ld		a, $c0			; $197d: $3e $c0 
	ldh		($ed), a		; $197f: $e0 $ed 
	jr		-$55			; $1981: $18 $ab 
	ld		a, ($c207)		; $1983: $fa $07 $c2 
	cp		$01			; $1986: $fe $01 
	ret		nz			; $1988: $c0 
	ld		hl, $c201		; $1989: $21 $01 $c2 
	ldi		a, (hl)			; $198c: $2a 
	add		$fd			; $198d: $c6 $fd 
	ldh		($ad), a		; $198f: $e0 $ad 
	ldh		a, ($a4)		; $1991: $f0 $a4 
	ld		b, (hl)			; $1993: $46 
	add		b			; $1994: $80 
	add		$02			; $1995: $c6 $02 
	ldh		($ae), a		; $1997: $e0 $ae 
	call		$0153			; $1999: $cd $53 $01 
	cp		$5f			; $199c: $fe $5f 
	jp		z, $1872		; $199e: $ca $72 $18 
	cp		$60			; $19a1: $fe $60 
	jr		nc, $11			; $19a3: $30 $11 
	ldh		a, ($ae)		; $19a5: $f0 $ae 
	add		$fc			; $19a7: $c6 $fc 
	ldh		($ae), a		; $19a9: $e0 $ae 
	call		$0153			; $19ab: $cd $53 $01 
	cp		$5f			; $19ae: $fe $5f 
	jp		z, $1872		; $19b0: $ca $72 $18 
	cp		$60			; $19b3: $fe $60 
	ret		c			; $19b5: $d8 
	call		$1a62			; $19b6: $cd $62 $1a 
	and		a			; $19b9: $a7 
	ret		z			; $19ba: $c8 
	cp		$82			; $19bb: $fe $82 
	jr		z, $19			; $19bd: $28 $19 
	cp		$f4			; $19bf: $fe $f4 
	jp		z, $1a4e		; $19c1: $ca $4e $1a 
	cp		$81			; $19c4: $fe $81 
	jr		z, -$6b			; $19c6: $28 $95 
	cp		$80			; $19c8: $fe $80 
	jp		z, $187f		; $19ca: $ca $7f $18 
	ld		a, $02			; $19cd: $3e $02 
	ld		($c207), a		; $19cf: $ea $07 $c2 
	ld		a, $07			; $19d2: $3e $07 
	ld		($dfe0), a		; $19d4: $ea $e0 $df 
	ret					; $19d7: $c9 
	push		hl			; $19d8: $e5 
	ld		a, h			; $19d9: $7c 
	add		$30			; $19da: $c6 $30 
	ld		h, a			; $19dc: $67 
	ld		a, (hl)			; $19dd: $7e 
	pop		hl			; $19de: $e1 
	cp		$c0			; $19df: $fe $c0 
	jp		z, $189b		; $19e1: $ca $9b $18 
	ldh		a, ($99)		; $19e4: $f0 $99 
	cp		$02			; $19e6: $fe $02 
	jp		nz, $191a		; $19e8: $c2 $1a $19 
	push		hl			; $19eb: $e5 
	pop		de			; $19ec: $d1 
	ld		hl, $ffee		; $19ed: $21 $ee $ff 
	ld		a, (hl)			; $19f0: $7e 
	and		a			; $19f1: $a7 
	ret		nz			; $19f2: $c0 
	ld		(hl), $01		; $19f3: $36 $01 
	inc		l			; $19f5: $2c 
	ld		(hl), d			; $19f6: $72 
	inc		l			; $19f7: $2c 
	ld		(hl), e			; $19f8: $73 
	ld		hl, $c210		; $19f9: $21 $10 $c2 
	ld		de, $0010		; $19fc: $11 $10 $00 
	ld		b, $04			; $19ff: $06 $04 
	push		hl			; $1a01: $e5 
	ld		(hl), $00		; $1a02: $36 $00 
	inc		l			; $1a04: $2c 
	ld		a, ($c201)		; $1a05: $fa $01 $c2 
	add		$f3			; $1a08: $c6 $f3 
	ld		(hl), a			; $1a0a: $77 
	inc		l			; $1a0b: $2c 
	ld		a, ($c202)		; $1a0c: $fa $02 $c2 
	add		$02			; $1a0f: $c6 $02 
	ld		(hl), a			; $1a11: $77 
	inc		l			; $1a12: $2c 
	inc		l			; $1a13: $2c 
	inc		l			; $1a14: $2c 
	inc		l			; $1a15: $2c 
	inc		l			; $1a16: $2c 
	ld		(hl), $01		; $1a17: $36 $01 
	inc		l			; $1a19: $2c 
	ld		(hl), $07		; $1a1a: $36 $07 
	pop		hl			; $1a1c: $e1 
	add		hl, de			; $1a1d: $19 
	dec		b			; $1a1e: $05 
	jr		nz, -$20			; $1a1f: $20 $e0 
	ld		hl, $c222		; $1a21: $21 $22 $c2 
	ld		a, (hl)			; $1a24: $7e 
	sub		$04			; $1a25: $d6 $04 
	ld		(hl), a			; $1a27: $77 
	ld		hl, $c242		; $1a28: $21 $42 $c2 
	ld		a, (hl)			; $1a2b: $7e 
	sub		$04			; $1a2c: $d6 $04 
	ld		(hl), a			; $1a2e: $77 
	ld		hl, $c238		; $1a2f: $21 $38 $c2 
	ld		(hl), $0b		; $1a32: $36 $0b 
	ld		hl, $c248		; $1a34: $21 $48 $c2 
	ld		(hl), $0b		; $1a37: $36 $0b 
	ldh		a, ($a4)		; $1a39: $f0 $a4 
	ldh		($f3), a		; $1a3b: $e0 $f3 
	ld		a, $02			; $1a3d: $3e $02 
	ld		($dff8), a		; $1a3f: $ea $f8 $df 
	ld		de, $0050		; $1a42: $11 $50 $00 
	call		$0166			; $1a45: $cd $66 $01 
	ld		a, $02			; $1a48: $3e $02 
	ld		($c207), a		; $1a4a: $ea $07 $c2 
	ret					; $1a4d: $c9 
	push		hl			; $1a4e: $e5 
	pop		de			; $1a4f: $d1 
	ld		hl, $ffee		; $1a50: $21 $ee $ff 
	ld		a, (hl)			; $1a53: $7e 
	and		a			; $1a54: $a7 
	ret		nz			; $1a55: $c0 
	ld		(hl), $c0		; $1a56: $36 $c0 
	inc		l			; $1a58: $2c 
	ld		(hl), d			; $1a59: $72 
	inc		l			; $1a5a: $2c 
	ld		(hl), e			; $1a5b: $73 
	ld		a, $05			; $1a5c: $3e $05 
	ld		($dfe0), a		; $1a5e: $ea $e0 $df 
	ret					; $1a61: $c9 
	push		hl			; $1a62: $e5 
	push		af			; $1a63: $f5 
	ld		b, a			; $1a64: $47 
	ldh		a, ($b4)		; $1a65: $f0 $b4 
	and		$f0			; $1a67: $e6 $f0 
	swap		a			; $1a69: $cb $37 
	dec		a			; $1a6b: $3d 
	sla		a			; $1a6c: $cb $27 
	ld		e, a			; $1a6e: $5f 
	ld		d, $00			; $1a6f: $16 $00 
	ld		hl, $1a8a		; $1a71: $21 $8a $1a 
	add		hl, de			; $1a74: $19 
	ld		e, (hl)			; $1a75: $5e 
	inc		hl			; $1a76: $23 
	ld		d, (hl)			; $1a77: $56 
	ld		a, (de)			; $1a78: $1a 
	cp		$fd			; $1a79: $fe $fd 
	jr		z, $06			; $1a7b: $28 $06 
	cp		b			; $1a7d: $b8 
	jr		z, $06			; $1a7e: $28 $06 
	inc		de			; $1a80: $13 
	jr		-$0b			; $1a81: $18 $f5 
	pop		af			; $1a83: $f1 
	pop		hl			; $1a84: $e1 
	ret					; $1a85: $c9 
	pop		af			; $1a86: $f1 
	pop		hl			; $1a87: $e1 
	xor		a			; $1a88: $af 
	ret					; $1a89: $c9 
	sub		h			; $1a8a: $94 
	ld		a, (de)			; $1a8b: $1a 
	sbc		c			; $1a8c: $99 
	ld		a, (de)			; $1a8d: $1a 
	sbc		(hl)			; $1a8e: $9e 
	ld		a, (de)			; $1a8f: $1a 
	and		b			; $1a90: $a0 
	ld		a, (de)			; $1a91: $1a 
	and		d			; $1a92: $a2 
	ld		a, (de)			; $1a93: $1a 
	ld		l, b			; $1a94: $68 
	ld		l, c			; $1a95: $69 
	ld		l, d			; $1a96: $6a 
	ld		a, h			; $1a97: $7c 
.db $fd
	ld		h, b			; $1a99: $60 
	ld		h, c			; $1a9a: $61 
	ld		h, e			; $1a9b: $63 
	ld		a, h			; $1a9c: $7c 
.db $fd
	ld		a, h			; $1a9e: $7c 
.db $fd
	ld		a, h			; $1aa0: $7c 
.db $fd
	ld		a, h			; $1aa2: $7c 
.db $fd
	ldh		a, ($b3)		; $1aa4: $f0 $b3 
	cp		$0e			; $1aa6: $fe $0e 
	jr		nc, $59			; $1aa8: $30 $59 
	ld		de, $0701		; $1aaa: $11 $01 $07 
	ldh		a, ($99)		; $1aad: $f0 $99 
	cp		$02			; $1aaf: $fe $02 
	jr		nz, $0a			; $1ab1: $20 $0a 
	ld		a, ($c203)		; $1ab3: $fa $03 $c2 
	cp		$18			; $1ab6: $fe $18 
	jr		z, $03			; $1ab8: $28 $03 
	ld		de, $0702		; $1aba: $11 $02 $07 
	ld		hl, $c201		; $1abd: $21 $01 $c2 
	ldi		a, (hl)			; $1ac0: $2a 
	add		d			; $1ac1: $82 
	ldh		($ad), a		; $1ac2: $e0 $ad 
	ld		a, ($c205)		; $1ac4: $fa $05 $c2 
	ld		b, (hl)			; $1ac7: $46 
	ld		c, $fa			; $1ac8: $0e $fa 
	and		a			; $1aca: $a7 
	jr		nz, $02			; $1acb: $20 $02 
	ld		c, $06			; $1acd: $0e $06 
	ld		a, c			; $1acf: $79 
	add		b			; $1ad0: $80 
	ld		b, a			; $1ad1: $47 
	ldh		a, ($a4)		; $1ad2: $f0 $a4 
	add		b			; $1ad4: $80 
	ldh		($ae), a		; $1ad5: $e0 $ae 
	push		de			; $1ad7: $d5 
	call		$0153			; $1ad8: $cd $53 $01 
	call		$1a62			; $1adb: $cd $62 $1a 
	pop		de			; $1ade: $d1 
	and		a			; $1adf: $a7 
	jr		z, $1c			; $1ae0: $28 $1c 
	cp		$60			; $1ae2: $fe $60 
	jr		c, $18			; $1ae4: $38 $18 
	cp		$f4			; $1ae6: $fe $f4 
	jr		z, $1b			; $1ae8: $28 $1b 
	cp		$77			; $1aea: $fe $77 
	jr		z, $2c			; $1aec: $28 $2c 
	cp		$f2			; $1aee: $fe $f2 
	jr		z, $4a			; $1af0: $28 $4a 
	ld		hl, $c20b		; $1af2: $21 $0b $c2 
	inc		(hl)			; $1af5: $34 
	ld		a, $02			; $1af6: $3e $02 
	ld		($c20e), a		; $1af8: $ea $0e $c2 
	ld		a, $ff			; $1afb: $3e $ff 
	ret					; $1afd: $c9 
	ld		d, $fc			; $1afe: $16 $fc 
	dec		e			; $1b00: $1d 
	jr		nz, -$46			; $1b01: $20 $ba 
	xor		a			; $1b03: $af 
	ret					; $1b04: $c9 
	push		hl			; $1b05: $e5 
	pop		de			; $1b06: $d1 
	ld		hl, $ffee		; $1b07: $21 $ee $ff 
	ld		a, (hl)			; $1b0a: $7e 
	and		a			; $1b0b: $a7 
	ret		nz			; $1b0c: $c0 
	ld		(hl), $c0		; $1b0d: $36 $c0 
	inc		l			; $1b0f: $2c 
	ld		(hl), d			; $1b10: $72 
	inc		l			; $1b11: $2c 
	ld		(hl), e			; $1b12: $73 
	ld		a, $05			; $1b13: $3e $05 
	ld		($dfe0), a		; $1b15: $ea $e0 $df 
	xor		a			; $1b18: $af 
	ret					; $1b19: $c9 
	ldh		a, ($f9)		; $1b1a: $f0 $f9 
	and		a			; $1b1c: $a7 
	jr		z, -$2d			; $1b1d: $28 $d3 
	ld		a, $0b			; $1b1f: $3e $0b 
	ldh		($b3), a		; $1b21: $e0 $b3 
	ld		a, $80			; $1b23: $3e $80 
	ld		($c204), a		; $1b25: $ea $04 $c2 
	ld		hl, $c202		; $1b28: $21 $02 $c2 
	ldd		a, (hl)			; $1b2b: $3a 
	add		$18			; $1b2c: $c6 $18 
	ldh		($f8), a		; $1b2e: $e0 $f8 
	ld		a, (hl)			; $1b30: $7e 
	and		$f8			; $1b31: $e6 $f8 
	add		$06			; $1b33: $c6 $06 
	ld		(hl), a			; $1b35: $77 
	call		$1ecb			; $1b36: $cd $cb $1e 
	ld		a, $ff			; $1b39: $3e $ff 
	ret					; $1b3b: $c9 
	ldh		a, ($99)		; $1b3c: $f0 $99 
	cp		$02			; $1b3e: $fe $02 
	ld		b, $ff			; $1b40: $06 $ff 
	jr		z, $05			; $1b42: $28 $05 
	ld		b, $0f			; $1b44: $06 $0f 
	xor		a			; $1b46: $af 
	ldh		($99), a		; $1b47: $e0 $99 
	ld		a, ($c203)		; $1b49: $fa $03 $c2 
	and		b			; $1b4c: $a0 
	ld		($c203), a		; $1b4d: $ea $03 $c2 
	ld		b, a			; $1b50: $47 
	and		$0f			; $1b51: $e6 $0f 
	cp		$0a			; $1b53: $fe $0a 
	jr		nc, $06			; $1b55: $30 $06 
	ld		a, b			; $1b57: $78 
	and		$f0			; $1b58: $e6 $f0 
	ld		($c203), a		; $1b5a: $ea $03 $c2 
	ld		a, $07			; $1b5d: $3e $07 
	ldh		($b3), a		; $1b5f: $e0 $b3 
	ld		a, ($d007)		; $1b61: $fa $07 $d0 
	and		a			; $1b64: $a7 
	jr		nz, $09			; $1b65: $20 $09 
	ld		a, $01			; $1b67: $3e $01 
	ld		($dfe8), a		; $1b69: $ea $e8 $df 
	ld		a, $f0			; $1b6c: $3e $f0 
	ldh		($a6), a		; $1b6e: $e0 $a6 
	call		$1ecb			; $1b70: $cd $cb $1e 
	xor		a			; $1b73: $af 
	ld		($c200), a		; $1b74: $ea $00 $c2 
	ld		($da1d), a		; $1b77: $ea $1d $da 
	ldh		($06), a		; $1b7a: $e0 $06 
	ret					; $1b7c: $c9 

; routine
; somethin to do with hittig blocks
; and getting coins from them
HANDLE_BLOCKS_AND_COINS:
	; clears it
	xor		a			; $1b7d: $af 
	ld		($c0e2), a		; $1b7e: $ea $e2 $c0 
	; fe is request get coin???
	ldh		a, (r_get_coin_request)		; $1b81: $f0 $fe 
	and		a			; $1b83: $a7 
	call		nz, GET_COIN		; $1b84: $c4 $f6 $1b 
	; grabs this thing from hram
	; this is BLOCK UPDATE REQUEST
	ld		hl, $ffee		; $1b87: $21 $ee $ff 
	ld		a, (hl)			; $1b8a: $7e 
	; coin block?
	cp		$01			; $1b8b: $fe $01 
	jr		z, ++			; $1b8d: $28 $22 
	; break block?
	cp		$02			; $1b8f: $fe $02 
	jp		z, +++			; $1b91: $ca $ee $1b 
	cp		$c0			; $1b94: $fe $c0 
	jr		z, ++			; $1b96: $28 $19 
	cp		$04			; $1b98: $fe $04 
	ret		nz			; $1b9a: $c0 

	; go here if ffee in hram is 04
	; reset ffee
	ld		(hl), $00		; $1b9b: $36 $00 
	; get the address to the block to update
	inc		l			; $1b9d: $2c 
	ld		d, (hl)			; $1b9e: $56 
	inc		l			; $1b9f: $2c 
	ld		e, (hl)			; $1ba0: $5e 
	; this checks to see what kinda block it is?
	; so i guess it transforms the bg tile into a sprite for this
	; probably then for animation
	; by checking the sprite in the oam, to see what chr it uses?
	; this is oam address
	; for tile no used by the animated block sprite
	ld		a, ($c02e)		; $1ba1: $fa $2e $c0 
	; if brick block, dont change it, use brick tile
	cp		$82			; $1ba4: $fe $82 
	jr		z, +			; $1ba6: $28 $07 
	; if coin block, get coin, and set to gotten coin block
	cp		$81			; $1ba8: $fe $81 
	call		z, GET_COIN		; $1baa: $cc $f6 $1b 
	ld		a, $7f			; $1bad: $3e $7f 
+	ld		(de), a			; $1baf: $12 
	ret					; $1bb0: $c9 

	; go here if ffee in hram is 1 or c0
	; so i guess this is breaking a block
	; reset ffee
	; (and save it)
++	ld		b, (hl)			; $1bb1: $46 
	ld		(hl), $00		; $1bb2: $36 $00 
	; grab an address from ffef and fff0 ? ?  onto de
-	inc		l			; $1bb4: $2c 
	ld		d, (hl)			; $1bb5: $56 
	inc		l			; $1bb6: $2c 
	ld		e, (hl)			; $1bb7: $5e 
	; make it blank!!
	ld		a, $2c			; $1bb8: $3e $2c 
	ld		(de), a			; $1bba: $12 
	; get coin if it has coin ? ? idk what block this sposed to be
	ld		a, b			; $1bbb: $78 
	cp		$c0			; $1bbc: $fe $c0 
	jr		z, +			; $1bbe: $28 $32 
	; subtract a a row!! go up a tile!!
	ld		hl, $ffe0		; $1bc0: $21 $e0 $ff 
	add		hl, de			; $1bc3: $19 
	; grab that!!
	ld		a, (hl)			; $1bc4: $7e 
	cp		$f4			; $1bc5: $fe $f4 
	ret		nz			; $1bc7: $c0 
	; only continue if its tile f4!! which is coin!!!
	; so this is for if there's a coin on top of the block?
	; get rid of it
	ld		(hl), $2c		; $1bc8: $36 $2c 
	; and play the coin get sound
	ld		a, $05			; $1bca: $3e $05 
	ld		($dfe0), a		; $1bcc: $ea $e0 $df 
	; copy the coin address onto af-b0
	ld		a, h			; $1bcf: $7c 
	ldh		($b0), a		; $1bd0: $e0 $b0 
	ld		a, l			; $1bd2: $7d 
	ldh		($af), a		; $1bd3: $e0 $af 
	; and call this routine with the coin address on HL
	; is this to align to grid?
	call		ALIGN_TO_GRID		; $1bd5: $cd $fe $3e 
	; ill figure this stuff out later thn
	ldh		a, ($a4)		; $1bd8: $f0 $a4 
	ld		b, a			; $1bda: $47 
	ldh		a, ($ae)		; $1bdb: $f0 $ae 
	sub		b			; $1bdd: $90 
	ldh		($eb), a		; $1bde: $e0 $eb 
	ldh		a, ($ad)		; $1be0: $f0 $ad 
	add		$14			; $1be2: $c6 $14 
	ldh		($ec), a		; $1be4: $e0 $ec 
	ld		a, $c0			; $1be6: $3e $c0 
	ldh		($ed), a		; $1be8: $e0 $ed 
	call		GET_COIN		; $1bea: $cd $f6 $1b 
	ret					; $1bed: $c9 

	; go here if ffee in hram is 2
	; reset ffee to 03
+++	ld		(hl), $03		; $1bee: $36 $03 
	jr		-			; $1bf0: $18 $c2 

	; if c0
+	call		GET_COIN		; $1bf2: $cd $f6 $1b 
	ret					; $1bf5: $c9 
; end routine

; routine
; this INCREMENTS the coin count, and then goes on to redisplay it
GET_COIN:
	; in game? better be
	ldh		a, ($9f)		; $1bf6: $f0 $9f 
	and		a			; $1bf8: $a7 
	ret		nz			; $1bf9: $c0 
	; save regs
	push		de			; $1bfa: $d5 
	push		hl			; $1bfb: $e5 
	; add to the score
	ld		de, $0100		; $1bfc: $11 $00 $01 
	call		ADD_SCORE		; $1bff: $cd $66 $01 
	; restort regs
	pop		hl			; $1c02: $e1 
	pop		de			; $1c03: $d1 
	; add to the coin counter
	ldh		a, ($fa)		; $1c04: $f0 $fa 
	add		$01			; $1c06: $c6 $01 
	daa					; $1c08: $27 
	ldh		($fa), a		; $1c09: $e0 $fa 
	; if it overflowed, request a 1up
	and		a			; $1c0b: $a7 
	jr		nz, $04			; $1c0c: $20 $04 
	inc		a			; $1c0e: $3c 
	ld		(request_life_change), a	; $1c0f: $ea $a3 $c0 

; routine
; display coin count?
DISPLAY_COIN_COUNT:
	; grab coint count
	ldh		a, (r_coins)		; $1c12: $f0 $fa 
	ld		b, a			; $1c14: $47 
	; display lower digit
	and		$0f			; $1c15: $e6 $0f 
	ld		($982a), a		; $1c17: $ea $2a $98 
	; display upper digit
	ld		a, b			; $1c1a: $78 
	and		$f0			; $1c1b: $e6 $f0 
	swap		a			; $1c1d: $cb $37 
	ld		($9829), a		; $1c1f: $ea $29 $98 
	; reset the request coin var
	xor		a			; $1c22: $af 
	ldh		($fe), a		; $1c23: $e0 $fe 
	; unsure what this is
	inc		a			; $1c25: $3c 
	ld		($c0e2), a		; $1c26: $ea $e2 $c0 
	ret					; $1c29: $c9 
; end routine

; routine
; checks for 1ups or deaths
; if requst_life_change is FF, lose life, and anythinge lse not 0, 1up
HANDLE_LIFE_CHANGES:
	; if not in game, quit
	ldh		a, ($9f)		; $1c2a: $f0 $9f 
	and		a			; $1c2c: $a7 
	ret		nz			; $1c2d: $c0 

	; if theres no requests.....
	; then theres no point in bein here
	; so get the heck outta here
	ld		a, (request_life_change)		; $1c2e: $fa $a3 $c0 
	or		a			; $1c31: $b7 
	ret		z			; $1c32: $c8 

	; otherwise u kno
	; LOSE A FRIGGIN LIFE
	cp		$ff			; $1c33: $fe $ff 
	ld		a, (lives)		; $1c35: $fa $15 $da 
	jr		z, ++			; $1c38: $28 $32 
	; if lives is max.. just get out
	cp		$99			; $1c3a: $fe $99 
	jr		z, +			; $1c3c: $28 $20 
	; otherwise if life ISNT max. . . .
	push		af			; $1c3e: $f5 
	; play sound affect
	ld		a, $08			; $1c3f: $3e $08 
	ld		(play_sfx), a		; $1c41: $ea $e0 $df 
	ldh		(r_request_sfx), a		; $1c44: $e0 $d3 
	pop		af			; $1c46: $f1 
	; adds 1 to lives, and saves it, and convert to dec
	add		$01			; $1c47: $c6 $01 
---	daa					; $1c49: $27 
	ld		(lives), a		; $1c4a: $ea $15 $da 

; routine
DISPLAY_LIFE_COUNT:
	; grab lives
	ld		a, (lives)		; $1c4d: $fa $15 $da 
	; display lower digit (rightmost)
	ld		b, a			; $1c50: $47 
	and		$0f			; $1c51: $e6 $0f 
	ld		($9807), a		; $1c53: $ea $07 $98 
	; display upper digit (leftmost)
	ld		a, b			; $1c56: $78 
	and		$f0			; $1c57: $e6 $f0 
	swap		a			; $1c59: $cb $37 
	ld		($9806), a		; $1c5b: $ea $06 $98 
	; clear this var
--
+	xor		a			; $1c5e: $af 
	ld		(request_life_change), a		; $1c5f: $ea $a3 $c0 
	ret					; $1c62: $c9 
; end routine

	; enter game over state
-	ld		a, $39			; $1c63: $3e $39 
	ldh		(r_state), a		; $1c65: $e0 $b3 
	; putting a state in c0a4 ? ? ? ? ? ? ? ? ? 
	ld		($c0a4), a		; $1c67: $ea $a4 $c0 
	jr		--			; $1c6a: $18 $f2 

	; this is if life LOSE is requested
	; if 0 lives? ? ?
++	and		a			; $1c6c: $a7 
	jr		z, -			; $1c6d: $28 $f4 

	; if not quite 0 lives:
	; then subtract a life
	sub		$01			; $1c6f: $d6 $01 
	jr		---			; $1c71: $18 $d6 
; end routine

; routine
; enters game over
ENTER_GAME_OVER:
	ld		hl, $9c00		; $1c73: $21 $00 $9c 
	ld		de, $1cce		; $1c76: $11 $ce $1c 
	ld		b, $11			; $1c79: $06 $11 
	ld		a, (de)			; $1c7b: $1a 
	ld		c, a			; $1c7c: $4f 
	ldh		a, ($41)		; $1c7d: $f0 $41 
	and		$03			; $1c7f: $e6 $03 
	jr		nz, -$06			; $1c81: $20 $fa 
	ldh		a, ($41)		; $1c83: $f0 $41 
	and		$03			; $1c85: $e6 $03 
	jr		nz, -$06			; $1c87: $20 $fa 
	ld		(hl), c			; $1c89: $71 
	inc		l			; $1c8a: $2c 
	inc		de			; $1c8b: $13 
	dec		b			; $1c8c: $05 
	jr		nz, -$14			; $1c8d: $20 $ec 
	ld		a, $10			; $1c8f: $3e $10 
	ld		($dfe8), a		; $1c91: $ea $e8 $df 
	ldh		a, ($b4)		; $1c94: $f0 $b4 
	ld		($c0a8), a		; $1c96: $ea $a8 $c0 
	ld		a, ($c0a2)		; $1c99: $fa $a2 $c0 
	and		$f0			; $1c9c: $e6 $f0 
	swap		a			; $1c9e: $cb $37 
	ld		b, a			; $1ca0: $47 
	ld		a, ($c0a6)		; $1ca1: $fa $a6 $c0 
	add		b			; $1ca4: $80 
	cp		$0a			; $1ca5: $fe $0a 
	jr		c, $02			; $1ca7: $38 $02 
	ld		a, $09			; $1ca9: $3e $09 
	ld		($c0a6), a		; $1cab: $ea $a6 $c0 
	ld		hl, $c000		; $1cae: $21 $00 $c0 
	xor		a			; $1cb1: $af 
	ld		b, $a0			; $1cb2: $06 $a0 
	ldi		(hl), a			; $1cb4: $22 
	dec		b			; $1cb5: $05 
	jr		nz, -$04			; $1cb6: $20 $fc 
	ld		($da1d), a		; $1cb8: $ea $1d $da 
	ldh		($06), a		; $1cbb: $e0 $06 
	ld		hl, $ff4a		; $1cbd: $21 $4a $ff 
	ld		(hl), $8f		; $1cc0: $36 $8f 
	inc		hl			; $1cc2: $23 
	ld		(hl), $07		; $1cc3: $36 $07 
	ld		a, $ff			; $1cc5: $3e $ff 
	ldh		($fb), a		; $1cc7: $e0 $fb 
	ld		hl, $ffb3		; $1cc9: $21 $b3 $ff 
	inc		(hl)			; $1ccc: $34 
	ret					; $1ccd: $c9 
; end routine

; data
; game over map
GAMEOVER_MAP:
.incbin "gameover.map"
; end data

; routine
; scrolss the credits then chills out for a bit
SCROLL_CREDITS_PORTION:
	ld		a, ($c0ad)		; $1cdf: $fa $ad $c0 
	and		a			; $1ce2: $a7 
	call		nz, $1527		; $1ce3: $c4 $27 $15 
	ret					; $1ce6: $c9 
; end routine

; routine
TIME_UP:
	ld		hl, $9c00		; $1ce7: $21 $00 $9c 
	ld		de, $1d0b		; $1cea: $11 $0b $1d 
	ld		c, $09			; $1ced: $0e $09 
	ld		a, (de)			; $1cef: $1a 
	ld		b, a			; $1cf0: $47 
	ldh		a, ($41)		; $1cf1: $f0 $41 
	and		$03			; $1cf3: $e6 $03 
	jr		nz, -$06			; $1cf5: $20 $fa 
	ld		(hl), b			; $1cf7: $70 
	inc		l			; $1cf8: $2c 
	inc		de			; $1cf9: $13 
	dec		c			; $1cfa: $0d 
	jr		nz, -$0e			; $1cfb: $20 $f2 
	ld		hl, $ff40		; $1cfd: $21 $40 $ff 
	set		5, (hl)			; $1d00: $cb $ee 
	ld		a, $a0			; $1d02: $3e $a0 
	ldh		($a6), a		; $1d04: $e0 $a6 
	ld		hl, $ffb3		; $1d06: $21 $b3 $ff 
	inc		(hl)			; $1d09: $34 
	ret					; $1d0a: $c9 
; end routine

; data
; time up map
.incbin "timeup.map"
; end data

; routine
; some kind of death routine?
ROUTINE_1C:
	ldh		a, ($a6)		; $1d14: $f0 $a6 
	and		a			; $1d16: $a7 
	ret		nz			; $1d17: $c0 
	ld		a, $01			; $1d18: $3e $01 
	ldh		($b3), a		; $1d1a: $e0 $b3 
	ret					; $1d1c: $c9 
	ld		hl, $c20d		; $1d1d: $21 $0d $c2 
	ld		a, (hl)			; $1d20: $7e 
	cp		$01			; $1d21: $fe $01 
	jr		nz, $0c			; $1d23: $20 $0c 
	dec		l			; $1d25: $2d 
	ld		a, (hl)			; $1d26: $7e 
	and		a			; $1d27: $a7 
	jr		nz, $05			; $1d28: $20 $05 
	inc		l			; $1d2a: $2c 
	ld		(hl), $00		; $1d2b: $36 $00 
	jr		$39			; $1d2d: $18 $39 
	dec		(hl)			; $1d2f: $35 
	ret					; $1d30: $c9 
	ld		hl, $c20c		; $1d31: $21 $0c $c2 
	ldi		a, (hl)			; $1d34: $2a 
	cp		$06			; $1d35: $fe $06 
	jr		nz, $07			; $1d37: $20 $07 
	inc		l			; $1d39: $2c 
	ld		a, (hl)			; $1d3a: $7e 
	and		a			; $1d3b: $a7 
	jr		nz, $02			; $1d3c: $20 $02 
	ld		(hl), $02		; $1d3e: $36 $02 
	ld		de, $c207		; $1d40: $11 $07 $c2 
	ldh		a, ($80)		; $1d43: $f0 $80 
	bit		7, a			; $1d45: $cb $7f 
	jr		nz, $35			; $1d47: $20 $35 
	bit		4, a			; $1d49: $cb $67 
	jr		nz, $56			; $1d4b: $20 $56 
	bit		5, a			; $1d4d: $cb $6f 
	jp		nz, $1e37		; $1d4f: $c2 $37 $1e 
	ld		hl, $c20c		; $1d52: $21 $0c $c2 
	ld		a, (hl)			; $1d55: $7e 
	and		a			; $1d56: $a7 
	jr		z, $09			; $1d57: $28 $09 
	xor		a			; $1d59: $af 
	ld		($c20e), a		; $1d5a: $ea $0e $c2 
	dec		(hl)			; $1d5d: $35 
	inc		l			; $1d5e: $2c 
	ld		a, (hl)			; $1d5f: $7e 
	jr		-$19			; $1d60: $18 $e7 
	inc		l			; $1d62: $2c 
	ld		(hl), $00		; $1d63: $36 $00 
	ld		a, (de)			; $1d65: $1a 
	and		a			; $1d66: $a7 
	ret		nz			; $1d67: $c0 
	ld		a, ($c207)		; $1d68: $fa $07 $c2 
	and		a			; $1d6b: $a7 
	ret		nz			; $1d6c: $c0 
	ld		hl, $c203		; $1d6d: $21 $03 $c2 
	ld		a, (hl)			; $1d70: $7e 
	and		$f0			; $1d71: $e6 $f0 
	ld		(hl), a			; $1d73: $77 
	ld		a, $01			; $1d74: $3e $01 
	ld		($c20b), a		; $1d76: $ea $0b $c2 
	xor		a			; $1d79: $af 
	ld		($c20e), a		; $1d7a: $ea $0e $c2 
	ret					; $1d7d: $c9 
	push		af			; $1d7e: $f5 
	ldh		a, ($99)		; $1d7f: $f0 $99 
	cp		$02			; $1d81: $fe $02 
	jr		nz, $15			; $1d83: $20 $15 
	ld		a, (de)			; $1d85: $1a 
	and		a			; $1d86: $a7 
	jr		nz, $11			; $1d87: $20 $11 
	ld		a, $18			; $1d89: $3e $18 
	ld		($c203), a		; $1d8b: $ea $03 $c2 
	ldh		a, ($80)		; $1d8e: $f0 $80 
	and		$30			; $1d90: $e6 $30 
	jr		nz, $09			; $1d92: $20 $09 
	ld		a, ($c20c)		; $1d94: $fa $0c $c2 
	and		a			; $1d97: $a7 
	jr		z, $03			; $1d98: $28 $03 
	pop		af			; $1d9a: $f1 
	jr		-$54			; $1d9b: $18 $ac 
	xor		a			; $1d9d: $af 
	ld		($c20c), a		; $1d9e: $ea $0c $c2 
	pop		af			; $1da1: $f1 
	ret					; $1da2: $c9 
; end routine

	ld		hl, $c20d		; $1da3: $21 $0d $c2 
	ld		a, (hl)			; $1da6: $7e 
	cp		$20			; $1da7: $fe $20 
	jr		nz, $03			; $1da9: $20 $03 
	jp		$1e3f			; $1dab: $c3 $3f $1e 
	ld		hl, $c205		; $1dae: $21 $05 $c2 
	ld		(hl), $00		; $1db1: $36 $00 
	call		$1aa4			; $1db3: $cd $a4 $1a 
	and		a			; $1db6: $a7 
	ret		nz			; $1db7: $c0 
	ldh		a, ($80)		; $1db8: $f0 $80 
	bit		4, a			; $1dba: $cb $67 
	jr		z, $1d			; $1dbc: $28 $1d 
	ld		a, ($c203)		; $1dbe: $fa $03 $c2 
	cp		$18			; $1dc1: $fe $18 
	jr		nz, $0a			; $1dc3: $20 $0a 
	ld		a, ($c203)		; $1dc5: $fa $03 $c2 
	and		$f0			; $1dc8: $e6 $f0 
	or		$01			; $1dca: $f6 $01 
	ld		($c203), a		; $1dcc: $ea $03 $c2 
	ld		hl, $c20c		; $1dcf: $21 $0c $c2 
	ld		a, (hl)			; $1dd2: $7e 
	cp		$06			; $1dd3: $fe $06 
	jr		z, $04			; $1dd5: $28 $04 
	inc		(hl)			; $1dd7: $34 
	inc		l			; $1dd8: $2c 
	ld		(hl), $10		; $1dd9: $36 $10 
	ld		hl, $c202		; $1ddb: $21 $02 $c2 
	ldh		a, ($f9)		; $1dde: $f0 $f9 
	and		a			; $1de0: $a7 
	jr		nz, $35			; $1de1: $20 $35 
	ld		a, ($c0d2)		; $1de3: $fa $d2 $c0 
	cp		$07			; $1de6: $fe $07 
	jr		c, $06			; $1de8: $38 $06 
	ldh		a, ($a4)		; $1dea: $f0 $a4 
	and		$0c			; $1dec: $e6 $0c 
	jr		z, $28			; $1dee: $28 $28 
	ld		a, $50			; $1df0: $3e $50 
	cp		(hl)			; $1df2: $be 
	jr		nc, $23			; $1df3: $30 $23 
	call		$1eab			; $1df5: $cd $ab $1e 
	ld		b, a			; $1df8: $47 
	ld		hl, $ffa4		; $1df9: $21 $a4 $ff 
	add		(hl)			; $1dfc: $86 
	ld		(hl), a			; $1dfd: $77 
	call		$1e9b			; $1dfe: $cd $9b $1e 
	call		$2c96			; $1e01: $cd $96 $2c 
	ld		hl, $c001		; $1e04: $21 $01 $c0 
	ld		de, $0004		; $1e07: $11 $04 $00 
	ld		c, $03			; $1e0a: $0e $03 
	ld		a, (hl)			; $1e0c: $7e 
	sub		b			; $1e0d: $90 
	ld		(hl), a			; $1e0e: $77 
	add		hl, de			; $1e0f: $19 
	dec		c			; $1e10: $0d 
	jr		nz, -$07			; $1e11: $20 $f9 
	ld		hl, $c20b		; $1e13: $21 $0b $c2 
	inc		(hl)			; $1e16: $34 
	ret					; $1e17: $c9 
	call		$1eab			; $1e18: $cd $ab $1e 
	add		(hl)			; $1e1b: $86 
	ld		(hl), a			; $1e1c: $77 
	ldh		a, ($b3)		; $1e1d: $f0 $b3 
	cp		$0d			; $1e1f: $fe $0d 
	jr		z, -$10			; $1e21: $28 $f0 
	ld		a, ($c0d2)		; $1e23: $fa $d2 $c0 
	and		a			; $1e26: $a7 
	jr		z, -$16			; $1e27: $28 $ea 
	ldh		a, ($a4)		; $1e29: $f0 $a4 
	and		$fc			; $1e2b: $e6 $fc 
	ldh		($a4), a		; $1e2d: $e0 $a4 
	ld		a, (hl)			; $1e2f: $7e 
	cp		$a0			; $1e30: $fe $a0 
	jr		c, -$21			; $1e32: $38 $df 
	jp		$1b3c			; $1e34: $c3 $3c $1b 
	ld		hl, $c20d		; $1e37: $21 $0d $c2 
	ld		a, (hl)			; $1e3a: $7e 
	cp		$10			; $1e3b: $fe $10 
	jr		nz, $19			; $1e3d: $20 $19 
	ld		(hl), $01		; $1e3f: $36 $01 
	dec		l			; $1e41: $2d 
	ld		(hl), $08		; $1e42: $36 $08 
	ld		a, ($c207)		; $1e44: $fa $07 $c2 
	and		a			; $1e47: $a7 
	ret		nz			; $1e48: $c0 
	ld		hl, $c203		; $1e49: $21 $03 $c2 
	ld		a, (hl)			; $1e4c: $7e 
	and		$f0			; $1e4d: $e6 $f0 
	or		$05			; $1e4f: $f6 $05 
	ld		(hl), a			; $1e51: $77 
	ld		a, $01			; $1e52: $3e $01 
	ld		($c20b), a		; $1e54: $ea $0b $c2 
	ret					; $1e57: $c9 
	ld		hl, $c205		; $1e58: $21 $05 $c2 
	ld		(hl), $20		; $1e5b: $36 $20 
	call		$1aa4			; $1e5d: $cd $a4 $1a 
	and		a			; $1e60: $a7 
	ret		nz			; $1e61: $c0 
	ld		hl, $c202		; $1e62: $21 $02 $c2 
	ld		a, (hl)			; $1e65: $7e 
	cp		$0f			; $1e66: $fe $0f 
	jr		c, $2c			; $1e68: $38 $2c 
	push		hl			; $1e6a: $e5 
	ldh		a, ($80)		; $1e6b: $f0 $80 
	bit		5, a			; $1e6d: $cb $6f 
	jr		z, $1d			; $1e6f: $28 $1d 
	ld		a, ($c203)		; $1e71: $fa $03 $c2 
	cp		$18			; $1e74: $fe $18 
	jr		nz, $0a			; $1e76: $20 $0a 
	ld		a, ($c203)		; $1e78: $fa $03 $c2 
	and		$f0			; $1e7b: $e6 $f0 
	or		$01			; $1e7d: $f6 $01 
	ld		($c203), a		; $1e7f: $ea $03 $c2 
	ld		hl, $c20c		; $1e82: $21 $0c $c2 
	ld		a, (hl)			; $1e85: $7e 
	cp		$06			; $1e86: $fe $06 
	jr		z, $04			; $1e88: $28 $04 
	inc		(hl)			; $1e8a: $34 
	inc		l			; $1e8b: $2c 
	ld		(hl), $20		; $1e8c: $36 $20 
	pop		hl			; $1e8e: $e1 
	call		$1eab			; $1e8f: $cd $ab $1e 
	cpl					; $1e92: $2f 
	inc		a			; $1e93: $3c 
	add		(hl)			; $1e94: $86 
	ld		(hl), a			; $1e95: $77 
	ld		hl, $c20b		; $1e96: $21 $0b $c2 
	dec		(hl)			; $1e99: $35 
	ret					; $1e9a: $c9 
	ld		hl, $c031		; $1e9b: $21 $31 $c0 
	ld		de, $0004		; $1e9e: $11 $04 $00 
	ld		c, $08			; $1ea1: $0e $08 
	ld		a, (hl)			; $1ea3: $7e 
	sub		b			; $1ea4: $90 
	ld		(hl), a			; $1ea5: $77 
	add		hl, de			; $1ea6: $19 
	dec		c			; $1ea7: $0d 
	jr		nz, -$07			; $1ea8: $20 $f9 
	ret					; $1eaa: $c9 
	push		de			; $1eab: $d5 
	push		hl			; $1eac: $e5 
	ld		hl, $1ec5		; $1ead: $21 $c5 $1e 
	ld		a, ($c20e)		; $1eb0: $fa $0e $c2 
	ld		e, a			; $1eb3: $5f 
	ld		d, $00			; $1eb4: $16 $00 
	ld		a, ($c20f)		; $1eb6: $fa $0f $c2 
	xor		$01			; $1eb9: $ee $01 
	ld		($c20f), a		; $1ebb: $ea $0f $c2 
	add		e			; $1ebe: $83 
	ld		e, a			; $1ebf: $5f 
	add		hl, de			; $1ec0: $19 
	ld		a, (hl)			; $1ec1: $7e 
	pop		hl			; $1ec2: $e1 
	pop		de			; $1ec3: $d1 
	ret					; $1ec4: $c9 
	nop					; $1ec5: $00 
	ld		bc, $0101		; $1ec6: $01 $01 $01 
.db $01
.db $02

; routine
; looks like it inits/clears/resets some stuff???
RESET_LEVEL_SPRITES:
	; save the regs
	push		hl			; $1ecb
	push		bc			; $1ecc: $c5 
	push		de			; $1ecd: $d5 

	; clear the $34 bytes in wram
	; from c01ch to c04fh
	; this is the sprites in oam after mario, i think
	ld		hl, $c01c		; $1ece: $21 $1c $c0 
	ld		b, $34			; $1ed1: $06 $34 
	xor		a			; $1ed3: $af 
-	ldi		(hl), a			; $1ed4: $22 
	dec		b			; $1ed5: $05 
	jr		nz, -			; $1ed6: $20 $fc 

	;  clear first eleven bytes of wram0
	; then clear the first 3 oam sprites, whatever the are
	ld		hl, $c000		; $1ed8: $21 $00 $c0 
	ld		b, $0b			; $1edb: $06 $0b 
-	ldi		(hl), a			; $1edd: $22 
	dec		b			; $1ede: $05 
	jr		nz, -			; $1edf: $20 $fc 

	; clear these vars?
	; still dont kno what these are
	ldh		($a9), a		; $1ee1: $e0 $a9 
	ldh		($aa), a		; $1ee3: $e0 $aa 
	ldh		($ab), a		; $1ee5: $e0 $ab 

	; this kills some character entities?
	ld		hl, $c210		; $1ee7: $21 $10 $c2 
	ld		de, $0010		; $1eea: $11 $10 $00 
	ld		b, $04			; $1eed: $06 $04 
	ld		a, $80			; $1eef: $3e $80 
-	ld		(hl), a			; $1ef1: $77 
	add		hl, de			; $1ef2: $19 
	dec		b			; $1ef3: $05 
	jr		nz, -			; $1ef4: $20 $fb 

	; restore the regs and done
	pop		de			; $1ef6: $d1 
	pop		bc			; $1ef7: $c1 
	pop		hl			; $1ef8: $e1 
	ret					; $1ef9: $c9 
; end routine

	ldh		a, ($ac)		; $1efa: $f0 $ac 
	and		$03			; $1efc: $e6 $03 
	ret		nz			; $1efe: $c0 
	ld		a, ($c0d3)		; $1eff: $fa $d3 $c0 
	and		a			; $1f02: $a7 
	ret		z			; $1f03: $c8 
	cp		$01			; $1f04: $fe $01 
	jr		z, $11			; $1f06: $28 $11 
	dec		a			; $1f08: $3d 
	ld		($c0d3), a		; $1f09: $ea $d3 $c0 
	ld		a, ($c200)		; $1f0c: $fa $00 $c2 
	xor		$80			; $1f0f: $ee $80 
	ld		($c200), a		; $1f11: $ea $00 $c2 
	ld		a, ($dfe9)		; $1f14: $fa $e9 $df 
	and		a			; $1f17: $a7 
	ret		nz			; $1f18: $c0 
	xor		a			; $1f19: $af 
	ld		($c0d3), a		; $1f1a: $ea $d3 $c0 
	ld		($c200), a		; $1f1d: $ea $00 $c2 
	call		$078c			; $1f20: $cd $8c $07 
	ret					; $1f23: $c9 
	ld		b, $01			; $1f24: $06 $01 
	ld		hl, $ffa9		; $1f26: $21 $a9 $ff 
	ld		de, $c001		; $1f29: $11 $01 $c0 
	ldi		a, (hl)			; $1f2c: $2a 
	and		a			; $1f2d: $a7 
	jr		nz, $08			; $1f2e: $20 $08 
	inc		e			; $1f30: $1c 
	inc		e			; $1f31: $1c 
	inc		e			; $1f32: $1c 
	inc		e			; $1f33: $1c 
	dec		b			; $1f34: $05 
	jr		nz, -$0b			; $1f35: $20 $f5 
	ret					; $1f37: $c9 
	push		hl			; $1f38: $e5 
	push		de			; $1f39: $d5 
	push		bc			; $1f3a: $c5 
	dec		l			; $1f3b: $2d 
	ld		a, ($c0a9)		; $1f3c: $fa $a9 $c0 
	and		a			; $1f3f: $a7 
	jr		z, $10			; $1f40: $28 $10 
	dec		a			; $1f42: $3d 
	ld		($c0a9), a		; $1f43: $ea $a9 $c0 
	bit		0, (hl)			; $1f46: $cb $46 
	jr		z, $62			; $1f48: $28 $62 
	ld		a, (de)			; $1f4a: $1a 
	inc		a			; $1f4b: $3c 
	inc		a			; $1f4c: $3c 
	ld		(de), a			; $1f4d: $12 
	cp		$a2			; $1f4e: $fe $a2 
	jr		c, $07			; $1f50: $38 $07 
	xor		a			; $1f52: $af 
	res		0, e			; $1f53: $cb $83 
	ld		(de), a			; $1f55: $12 
	ld		(hl), a			; $1f56: $77 
	jr		$30			; $1f57: $18 $30 
	add		$03			; $1f59: $c6 $03 
	push		af			; $1f5b: $f5 
	dec		e			; $1f5c: $1d 
	ld		a, (de)			; $1f5d: $1a 
	ldh		($ad), a		; $1f5e: $e0 $ad 
	pop		af			; $1f60: $f1 
	call		$1fc9			; $1f61: $cd $c9 $1f 
	jr		c, $06			; $1f64: $38 $06 
	ld		a, (hl)			; $1f66: $7e 
	and		$fc			; $1f67: $e6 $fc 
	or		$02			; $1f69: $f6 $02 
	ld		(hl), a			; $1f6b: $77 
	bit		2, (hl)			; $1f6c: $cb $56 
	jr		z, $21			; $1f6e: $28 $21 
	ld		a, (de)			; $1f70: $1a 
	dec		a			; $1f71: $3d 
	dec		a			; $1f72: $3d 
	ld		(de), a			; $1f73: $12 
	cp		$10			; $1f74: $fe $10 
	jr		c, -$26			; $1f76: $38 $da 
	sub		$01			; $1f78: $d6 $01 
	ldh		($ad), a		; $1f7a: $e0 $ad 
	inc		e			; $1f7c: $1c 
	ld		a, (de)			; $1f7d: $1a 
	call		$1fc9			; $1f7e: $cd $c9 $1f 
	jr		c, $06			; $1f81: $38 $06 
	ld		a, (hl)			; $1f83: $7e 
	and		$f3			; $1f84: $e6 $f3 
	or		$08			; $1f86: $f6 $08 
	ld		(hl), a			; $1f88: $77 
	pop		bc			; $1f89: $c1 
	pop		de			; $1f8a: $d1 
	pop		hl			; $1f8b: $e1 
	call		$2001			; $1f8c: $cd $01 $20 
	jr		-$61			; $1f8f: $18 $9f 
	ld		a, (de)			; $1f91: $1a 
	inc		a			; $1f92: $3c 
	inc		a			; $1f93: $3c 
	ld		(de), a			; $1f94: $12 
	cp		$a8			; $1f95: $fe $a8 
	jr		nc, -$47			; $1f97: $30 $b9 
	add		$04			; $1f99: $c6 $04 
	ldh		($ad), a		; $1f9b: $e0 $ad 
	inc		e			; $1f9d: $1c 
	ld		a, (de)			; $1f9e: $1a 
	call		$1fc9			; $1f9f: $cd $c9 $1f 
	jr		c, -$1b			; $1fa2: $38 $e5 
	ld		a, (hl)			; $1fa4: $7e 
	and		$f3			; $1fa5: $e6 $f3 
	or		$04			; $1fa7: $f6 $04 
	ld		(hl), a			; $1fa9: $77 
	jr		-$23			; $1faa: $18 $dd 
	ld		a, (de)			; $1fac: $1a 
	dec		a			; $1fad: $3d 
	dec		a			; $1fae: $3d 
	ld		(de), a			; $1faf: $12 
	cp		$04			; $1fb0: $fe $04 
	jr		c, -$62			; $1fb2: $38 $9e 
	sub		$02			; $1fb4: $d6 $02 
	push		af			; $1fb6: $f5 
	dec		e			; $1fb7: $1d 
	ld		a, (de)			; $1fb8: $1a 
	ldh		($ad), a		; $1fb9: $e0 $ad 
	pop		af			; $1fbb: $f1 
	call		$1fc9			; $1fbc: $cd $c9 $1f 
	jr		c, -$55			; $1fbf: $38 $ab 
	ld		a, (hl)			; $1fc1: $7e 
	and		$fc			; $1fc2: $e6 $fc 
	or		$01			; $1fc4: $f6 $01 
	ld		(hl), a			; $1fc6: $77 
	jr		-$5d			; $1fc7: $18 $a3 
	ld		b, a			; $1fc9: $47 
	ldh		a, ($a4)		; $1fca: $f0 $a4 
	add		b			; $1fcc: $80 
	ldh		($ae), a		; $1fcd: $e0 $ae 
	push		de			; $1fcf: $d5 
	push		hl			; $1fd0: $e5 
	call		$0153			; $1fd1: $cd $53 $01 
	cp		$f4			; $1fd4: $fe $f4 
	jr		nz, $1a			; $1fd6: $20 $1a 
	ldh		a, ($b3)		; $1fd8: $f0 $b3 
	cp		$0d			; $1fda: $fe $0d 
	jr		z, $1e			; $1fdc: $28 $1e 
	push		hl			; $1fde: $e5 
	pop		de			; $1fdf: $d1 
	ld		hl, $ffee		; $1fe0: $21 $ee $ff 
	ld		a, (hl)			; $1fe3: $7e 
	and		a			; $1fe4: $a7 
	jr		nz, $15			; $1fe5: $20 $15 
	ld		(hl), $c0		; $1fe7: $36 $c0 
	inc		l			; $1fe9: $2c 
	ld		(hl), d			; $1fea: $72 
	inc		l			; $1feb: $2c 
	ld		(hl), e			; $1fec: $73 
	ld		a, $05			; $1fed: $3e $05 
	ld		($dfe0), a		; $1fef: $ea $e0 $df 
	cp		$82			; $1ff2: $fe $82 
	call		z, $208e		; $1ff4: $cc $8e $20 
	cp		$80			; $1ff7: $fe $80 
	call		z, $208e		; $1ff9: $cc $8e $20 
	pop		hl			; $1ffc: $e1 
	pop		de			; $1ffd: $d1 
	cp		$60			; $1ffe: $fe $60 
	ret					; $2000: $c9 
	push		hl			; $2001: $e5 
	push		de			; $2002: $d5 
	push		bc			; $2003: $c5 
	ld		b, $0a			; $2004: $06 $0a 
	ld		hl, $d100		; $2006: $21 $00 $d1 
	ld		a, (hl)			; $2009: $7e 
	cp		$ff			; $200a: $fe $ff 
	jr		nz, $12			; $200c: $20 $12 
	push		de			; $200e: $d5 
	ld		de, $0010		; $200f: $11 $10 $00 
	add		hl, de			; $2012: $19 
	pop		de			; $2013: $d1 
	dec		b			; $2014: $05 
	jr		nz, -$0e			; $2015: $20 $f2 
	pop		bc			; $2017: $c1 
	pop		de			; $2018: $d1 
	pop		hl			; $2019: $e1 
	ret					; $201a: $c9 
	pop		hl			; $201b: $e1 
	pop		de			; $201c: $d1 
	pop		bc			; $201d: $c1 
	jr		-$12			; $201e: $18 $ee 
	push		bc			; $2020: $c5 
	push		de			; $2021: $d5 
	push		hl			; $2022: $e5 
	ld		bc, $000a		; $2023: $01 $0a $00 
	add		hl, bc			; $2026: $09 
	bit		7, (hl)			; $2027: $cb $7e 
	jr		nz, -$10			; $2029: $20 $f0 
	ld		c, (hl)			; $202b: $4e 
	inc		l			; $202c: $2c 
	inc		l			; $202d: $2c 
	ld		a, (hl)			; $202e: $7e 
	ldh		($9b), a		; $202f: $e0 $9b 
	ld		a, (de)			; $2031: $1a 
	ldh		($a2), a		; $2032: $e0 $a2 
	add		$04			; $2034: $c6 $04 
	ldh		($8f), a		; $2036: $e0 $8f 
	dec		e			; $2038: $1d 
	ld		a, (de)			; $2039: $1a 
	ldh		($a0), a		; $203a: $e0 $a0 
	ld		a, (de)			; $203c: $1a 
	add		$03			; $203d: $c6 $03 
	ldh		($a1), a		; $203f: $e0 $a1 
	pop		hl			; $2041: $e1 
	push		hl			; $2042: $e5 
	call		$0aa6			; $2043: $cd $a6 $0a 
	and		a			; $2046: $a7 
	jr		z, -$2e			; $2047: $28 $d2 
	dec		l			; $2049: $2d 
	dec		l			; $204a: $2d 
	dec		l			; $204b: $2d 
	call		$0a07			; $204c: $cd $07 $0a 
	push		de			; $204f: $d5 
	ldh		a, ($b3)		; $2050: $f0 $b3 
	cp		$0d			; $2052: $fe $0d 
	jr		nz, $05			; $2054: $20 $05 
	call		$2aa4			; $2056: $cd $a4 $2a 
	jr		$03			; $2059: $18 $03 
	call		$2a5f			; $205b: $cd $5f $2a 
	pop		de			; $205e: $d1 
	and		a			; $205f: $a7 
	jr		z, -$47			; $2060: $28 $b9 
	push		af			; $2062: $f5 
	ld		a, (de)			; $2063: $1a 
	sub		$08			; $2064: $d6 $08 
	ldh		($ec), a		; $2066: $e0 $ec 
	inc		e			; $2068: $1c 
	ld		a, (de)			; $2069: $1a 
	ldh		($eb), a		; $206a: $e0 $eb 
	pop		af			; $206c: $f1 
	cp		$ff			; $206d: $fe $ff 
	jr		nz, $09			; $206f: $20 $09 
	ld		a, $03			; $2071: $3e $03 
	ld		($dfe0), a		; $2073: $ea $e0 $df 
	ldh		a, ($9e)		; $2076: $f0 $9e 
	ldh		($ed), a		; $2078: $e0 $ed 
	xor		a			; $207a: $af 
	ld		(de), a			; $207b: $12 
	dec		e			; $207c: $1d 
	ld		(de), a			; $207d: $12 
	ld		hl, $ffab		; $207e: $21 $ab $ff 
	bit		3, e			; $2081: $cb $5b 
	jr		nz, $06			; $2083: $20 $06 
	dec		l			; $2085: $2d 
	bit		2, e			; $2086: $cb $53 
	jr		nz, $01			; $2088: $20 $01 
	dec		l			; $208a: $2d 
	ld		(hl), a			; $208b: $77 
	jr		-$73			; $208c: $18 $8d 
	push		hl			; $208e: $e5 
	push		bc			; $208f: $c5 
	push		de			; $2090: $d5 
	push		af			; $2091: $f5 
	ldh		a, ($b3)		; $2092: $f0 $b3 
	cp		$0d			; $2094: $fe $0d 
	jr		nz, $6d			; $2096: $20 $6d 
	push		hl			; $2098: $e5 
	pop		de			; $2099: $d1 
	ld		hl, $ffee		; $209a: $21 $ee $ff 
	ld		a, (hl)			; $209d: $7e 
	and		a			; $209e: $a7 
	jr		nz, $64			; $209f: $20 $64 
	ld		(hl), $01		; $20a1: $36 $01 
	inc		l			; $20a3: $2c 
	ld		(hl), d			; $20a4: $72 
	inc		l			; $20a5: $2c 
	ld		(hl), e			; $20a6: $73 
	pop		af			; $20a7: $f1 
	push		af			; $20a8: $f5 
	cp		$80			; $20a9: $fe $80 
	jr		nz, $0b			; $20ab: $20 $0b 
	ld		a, d			; $20ad: $7a 
	add		$30			; $20ae: $c6 $30 
	ld		d, a			; $20b0: $57 
	ld		a, (de)			; $20b1: $1a 
	and		a			; $20b2: $a7 
	jr		z, $03			; $20b3: $28 $03 
	call		$2544			; $20b5: $cd $44 $25 
	ld		hl, $c210		; $20b8: $21 $10 $c2 
	ld		de, $0010		; $20bb: $11 $10 $00 
	ld		b, $04			; $20be: $06 $04 
	push		hl			; $20c0: $e5 
	ld		(hl), $00		; $20c1: $36 $00 
	inc		l			; $20c3: $2c 
	ldh		a, ($ad)		; $20c4: $f0 $ad 
	add		$00			; $20c6: $c6 $00 
	ld		(hl), a			; $20c8: $77 
	inc		l			; $20c9: $2c 
	ldh		a, ($a1)		; $20ca: $f0 $a1 
	add		$00			; $20cc: $c6 $00 
	ld		(hl), a			; $20ce: $77 
	inc		l			; $20cf: $2c 
	inc		l			; $20d0: $2c 
	inc		l			; $20d1: $2c 
	inc		l			; $20d2: $2c 
	inc		l			; $20d3: $2c 
	ld		(hl), $01		; $20d4: $36 $01 
	inc		l			; $20d6: $2c 
	ld		(hl), $07		; $20d7: $36 $07 
	pop		hl			; $20d9: $e1 
	add		hl, de			; $20da: $19 
	dec		b			; $20db: $05 
	jr		nz, -$1e			; $20dc: $20 $e2 
	ld		hl, $c222		; $20de: $21 $22 $c2 
	ld		a, (hl)			; $20e1: $7e 
	sub		$04			; $20e2: $d6 $04 
	ld		(hl), a			; $20e4: $77 
	ld		hl, $c242		; $20e5: $21 $42 $c2 
	ld		a, (hl)			; $20e8: $7e 
	sub		$04			; $20e9: $d6 $04 
	ld		(hl), a			; $20eb: $77 
	ld		hl, $c238		; $20ec: $21 $38 $c2 
	ld		(hl), $0b		; $20ef: $36 $0b 
	ld		hl, $c248		; $20f1: $21 $48 $c2 
	ld		(hl), $0b		; $20f4: $36 $0b 
	ldh		a, ($a4)		; $20f6: $f0 $a4 
	ldh		($f3), a		; $20f8: $e0 $f3 
	ld		de, $0050		; $20fa: $11 $50 $00 
	call		$0166			; $20fd: $cd $66 $01 
	ld		a, $02			; $2100: $3e $02 
	ld		($dff8), a		; $2102: $ea $f8 $df 
	pop		af			; $2105: $f1 
	pop		de			; $2106: $d1 
	pop		bc			; $2107: $c1 
	pop		hl			; $2108: $e1 
	ret					; $2109: $c9 
	ldh		a, ($9f)		; $210a: $f0 $9f 
	and		a			; $210c: $a7 
	ret		z			; $210d: $c8 
	ld		a, ($c0db)		; $210e: $fa $db $c0 
	ldh		($80), a		; $2111: $e0 $80 
	ret					; $2113: $c9 

; data
; this is data to be copied to the game character entity memory
DATA_0:
.incbin "data0.bin"
DATA_0_END:
; end data

	inc		b			; $2165: $04 
	inc		bc			; $2166: $03 
	inc		bc			; $2167: $03 
	ld		(bc), a			; $2168: $02 
	ld		(bc), a			; $2169: $02 
	ld		(bc), a			; $216a: $02 
	ld		(bc), a			; $216b: $02 
	ld		(bc), a			; $216c: $02 
	ld		(bc), a			; $216d: $02 
	ld		(bc), a			; $216e: $02 
	ld		(bc), a			; $216f: $02 
	ld		(bc), a			; $2170: $02 
	ld		bc, $0101		; $2171: $01 $01 $01 
	ld		bc, $0101		; $2174: $01 $01 $01 
	ld		bc, $0100		; $2177: $01 $00 $01 
	nop					; $217a: $00 
	ld		bc, $0000		; $217b: $01 $00 $00 
	ld		a, a			; $217e: $7f 

; routine
; leads into routine below?
; this routine has something to do with loading the level as you travel it
; ENTRY BELOW
	; come here if that var was set
	; setting this var either to 3, or 0 if the below vars dont match
	; set this var
-	ld		a, $03			; $217f: $3e $03 
	ldh		($ea), a		; $2181: $e0 $ea 
	; compare these vars
	ldh		a, ($a4)		; $2183: $f0 $a4 
	ld		b, a			; $2185: $47 
	ld		a, ($c0aa)		; $2186: $fa $aa $c0 
	cp		b			; $2189: $b8 
	ret		z			; $218a: $c8 
	; if they dont match, clear the var just set to 3
	xor		a			; $218b: $af 
	ldh		($ea), a		; $218c: $e0 $ea 
	ret					; $218e: $c9 

ROUTINE_14:
	; check this hram var
	; go above if its set
	ldh		a, ($ea)		; $218f: $f0 $ea 
	and		a			; $2191: $a7 
	jr		nz, -			; $2192: $20 $eb 
	; and go here if its cleared
	; grab this and mask bit 3 only
	ldh		a, ($a4)		; $2194: $f0 $a4 
	and		$08			; $2196: $e6 $08 
	; does it match this hram var?
	ld		hl, $ffa3		; $2198: $21 $a3 $ff 
	cp		(hl)			; $219b: $be 
	; leave if not
	ret		nz			; $219c: $c0 
	; only continue here if it matches
	; grab the matched thing, and flip that bit that was clearly matched
	; and put it back
	ld		a, (hl)			; $219d: $7e 
	xor		$08			; $219e: $ee $08 
	ld		(hl), a			; $21a0: $77 
	; and if it matches 4 (i cant imagine how?)
	; then inc this certain wram var
	and		a			; $21a1: $a7 
	jr		nz, $04			; $21a2: $20 $04 
	ld		hl, $c0ab		; $21a4: $21 $ab $c0 
	inc		(hl)			; $21a7: $34 
	; anyway, moving on:

; routine
; does this have to do with compression?
; or does it have to do with tiles?
; this definitely has something to do with loading the maps
ROUTINE_06:
	; clear the 10h bytes with 2ch at this wram0 place
	ld		b, $10			; $21a8: $06 $10 
	ld		hl, $c0b0		; $21aa: $21 $b0 $c0 
	ld		a, $2c			; $21ad: $3e $2c 
-	ldi		(hl), a			; $21af: $22 
	dec		b			; $21b0: $05 
	jr		nz, -			; $21b1: $20 $fc 

	; is this hram var set?
	ldh		a, ($e6)		; $21b3: $f0 $e6 
	and		a			; $21b5: $a7 
	jr		z, +			; $21b6: $28 $08 
	; yes? then:
	; grab this address from hram
	ldh		a, ($e7)		; $21b8: $f0 $e7 
	ld		h, a			; $21ba: $67 
	ldh		a, ($e8)		; $21bb: $f0 $e8 
	ld		l, a			; $21bd: $6f 
	jr		++			; $21be: $18 $1f 
	; else:
	; use word offset hram var from 4000h
+	ld		hl, $4000		; $21c0: $21 $00 $40 
	ldh		a, ($e4)		; $21c3: $f0 $e4 
	add		a			; $21c5: $87 
	ld		e, a			; $21c6: $5f 
	ld		d, $00			; $21c7: $16 $00 
	add		hl, de			; $21c9: $19 
	; and grab the byte that it points to, in rom, for whichever bank this is
	; apparently bank 02 (third bank)
	ld		e, (hl)			; $21ca: $5e 
	inc		hl			; $21cb: $23 
	ld		d, (hl)			; $21cc: $56 
	; and move it to hl
	; so is there a table of addresses starting at bank 02?
	; addresses that point to word tables?
	; possibly addresses, but not if it starts with ff?
	push		de			; $21cd: $d5 
	pop		hl			; $21ce: $e1 
	; and here's another word offset var in hram
	ldh		a, ($e5)		; $21cf: $f0 $e5 
	add		a			; $21d1: $87 
	ld		e, a			; $21d2: $5f 
	ld		d, $00			; $21d3: $16 $00 
	add		hl, de			; $21d5: $19 
	; if the first byte there is $ff
	; jump ahead
	; i guess just skip this procedure
	ldi		a, (hl)			; $21d6: $2a 
	cp		$ff			; $21d7: $fe $ff 
	jr		z, +++			; $21d9: $28 $47 
	; otherwise, its another address i suppose
	ld		e, a			; $21db: $5f 
	ld		d, (hl)			; $21dc: $56 
	push		de			; $21dd: $d5 
	pop		hl			; $21de: $e1 
	
	; here! hl points to a structure
	; first byte is length, and ram destination offset
	; rest of the bytes, get copied to that ram place
	; and also switch some possible routines
	; also, these structs are in a table, so one follows the tail
	; table is terminated with FEh
	; so here we have an address on hl,
	; either loaded from that table
	; or taken straight from hram
	; the first byte we load is wram address offset + counter
--	; if the first byte there is feh, branch elsewhere
++	ldi		a, (hl)			; $21df: $2a 
	cp		$fe			; $21e0: $fe $fe 
	jr		z, +			; $21e2: $28 $43 

	; but otherwise:
	; here we get a wram address from the high bits of the byte, put on de
	; point here in wram
	ld		de, $c0b0		; $21e4: $11 $b0 $c0 
	; and basiccally use the high bits of that byte
	; as byte offset for this wram location
	; and copy the grabbed byte on b
	ld		b, a			; $21e7: $47 
	; only caring about high bits
	and		$f0			; $21e8: $e6 $f0 
	; make them low
	swap		a			; $21ea: $cb $37 
	; add b0h to it?
	add		e			; $21ec: $83 
	; and save it on e
	ld		e, a			; $21ed: $5f 

	; and here we get a counter from the lower bits, put on b
	; now grab the original byte again
	ld		a, b			; $21ee: $78 
	; this time only caring about the low bits
	and		$0f			; $21ef: $e6 $0f 
	; if its 0 make it 10h
	; (because counter)
	jr		nz, ++			; $21f1: $20 $02 
	ld		a, $10			; $21f3: $3e $10 
	; save it on b
++	ld		b, a			; $21f5: $47 

	; and the second byte (and rest) is data to save to the wram adress
	; and also used as a switch below
	; except fdh does something different
	; grab the next byte
-	ldi		a, (hl)			; $21f6: $2a 
	; go forth if its fdh
	cp		$fd			; $21f7: $fe $fd 
	jr		z, ++			; $21f9: $28 $4a 
	; otherwise:
	; put that 2nd byte onto the wram offset by the high bits of the first byte
	ld		(de), a			; $21fb: $12 

	; if block:
	; im guessing these are tile indicies
	; and if its 70h, call this
	cp		$70			; $21fc: $fe $70 
	jr		nz, ++++		; $21fe: $20 $05 
	call		ROUTINE_07		; $2200: $cd $a0 $22 
	jr		+++++			; $2203: $18 $17 
	; else if 80h, 5fh, or 81h, call this
	; else if 80h, call this
++++	cp		$80			; $2205: $fe $80 
	jr		nz, ++++		; $2207: $20 $05 
	call		ROUTINE_08		; $2209: $cd $18 $23 
	jr		+++++			; $220c: $18 $0e 
	; else if 5fh, call this
++++	cp		$5f			; $220e: $fe $5f 
	jr		nz, ++++		; $2210: $20 $05 
	call		ROUTINE_08		; $2212: $cd $18 $23 
	jr		+++++			; $2215: $18 $05 
	; else if 81h, call this
++++	cp		$81			; $2217: $fe $81 
	call		z, ROUTINE_08		; $2219: $cc $18 $23 
	; end if

	; and now, the wram pointer goes up
	; and the counter goes down
+++++	inc		e			; $221c: $1c 
	dec		b			; $221d: $05 
	; and keep looping through the bytes at the tail of this hl structure
	jr		nz, -			; $221e: $20 $d6 
	; then when done, next struct!
	jr		--			; $2220: $18 $bd 

	; skipped here if didnt get get a proper address (i guess)
+++	ld		hl, $c0d2		; $2222: $21 $d2 $c0 
	inc		(hl)			; $2225: $34 
	ret					; $2226: $c9 

	; here if that first byte is feh
	; that is, this TABLE is FEh terminated
+	ld		a, h			; $2227: $7c 
	ldh		($e7), a		; $2228: $e0 $e7 
	ld		a, l			; $222a: $7d 
	ldh		($e8), a		; $222b: $e0 $e8 
	ldh		a, ($e6)		; $222d: $f0 $e6 
	inc		a			; $222f: $3c 
	cp		$14			; $2230: $fe $14 
	jr		nz, $05			; $2232: $20 $05 
	ld		hl, $ffe5		; $2234: $21 $e5 $ff 
	inc		(hl)			; $2237: $34 
	xor		a			; $2238: $af 
	ldh		($e6), a		; $2239: $e0 $e6 
	ldh		a, ($a4)		; $223b: $f0 $a4 
	ld		($c0aa), a		; $223d: $ea $aa $c0 
	ld		a, $01			; $2240: $3e $01 
	ldh		($ea), a		; $2242: $e0 $ea 
	ret					; $2244: $c9 

	; here if that second byte is fdh
	; this prematurely terminates the struct in the table
	; and it copies the following byte for the rest of the 'length'
	; and without routines being called
	; is this some kind of compression?
++	ld		a, (hl)			; $2245: $7e 
-	ld		(de), a			; $2246: $12 
	inc		e			; $2247: $1c 
	dec		b			; $2248: $05 
	jr		nz, -			; $2249: $20 $fb 
	inc		hl			; $224b: $23 
	jp		--			; $224c: $c3 $df $21 
; end routine

; routine
; i guess this is putting the map in place as its loaded up
; this routine copies a 16 tile string from wram $c0b0
; and places it vertically at some place in vram bg map 0
; given by hram(e9h)
; also incs that for next time? next column?
; and clears correpsonding bgmap tiles in wram with 0s
; also calls certain routines for certain tiles as they are copied
; i guess ea is like a request to copy?
COPY_MAP0_COLUMN:
	; enable flag of sorts
	; return if hram(eah) != 1
	ldh		a, ($ea)		; $224f: $f0 $ea 
	cp		$01			; $2251: $fe $01 
	ret		nz			; $2253: $c0 

	; form hl pointer to map0 vram with offset
	; grab offset from here
	ldh		a, (r_map_load_dest)		; $2254: $f0 $e9 
	ld		l, a			; $2256: $6f 
	; if offset+1 = 60h, then store back as 40h (prob for next load?)
	; oh, its probably to prevent overflow?
	; keeps it between these 20 tiles, ie, keeps it on the 3rd row?
	inc		a			; $2257: $3c 
	cp		$60			; $2258: $fe $60 
	jr		nz, +			; $225a: $20 $02 
	ld		a, $40			; $225c: $3e $40 
	; but either way, inc it, and restore it
+	ldh		(r_map_load_dest), a		; $225e: $e0 $e9 
	ld		h, $98			; $2260: $26 $98 

	; point de to here in wram
	; where the source data is
	ld		de, $c0b0		; $2262: $11 $b0 $c0 
	; gonna copy 16 tiles
	; set counter to 10h
	ld		b, $10			; $2265: $06 $10 

	; loop
	; save mapram0 pointer
-	push		hl			; $2267: $e5 
	; write a 0 to the corresponding place in wram0
	; so what, a map of map0 at c800h?
	ld		a, h			; $2268: $7c 
	add		$30			; $2269: $c6 $30 
	ld		h, a			; $226b: $67 
	ld		(hl), $00		; $226c: $36 $00 
	; retrieve it
	pop		hl			; $226e: $e1 
	; copy from place in wram into specified place in vram
	ld		a, (de)			; $226f: $1a 
	ld		(hl), a			; $2270: $77 

	; call switch depending on the tile
	; if tile is $70
	cp		$70			; $2271: $fe $70 
	jr		nz, +			; $2273: $20 $05 
	call		ROUTINE_09		; $2275: $cd $f4 $22 
	jr		++			; $2278: $18 $17 
	; else if its any of these, call this
	; else if tile is $80
+	cp		$80			; $227a: $fe $80 
	jr		nz, +			; $227c: $20 $05 
	call		ROUTINE_0A		; $227e: $cd $5a $23 
	jr		++			; $2281: $18 $0e 
	; else if tile is $5f
+	cp		$5f			; $2283: $fe $5f 
	jr		nz, +			; $2285: $20 $05 
	call		ROUTINE_0A		; $2287: $cd $5a $23 
	jr		++			; $228a: $18 $05 
	; else if tile is $81
+	cp		$81			; $228c: $fe $81 
	call		z, ROUTINE_0A		; $228e: $cc $5a $23 
	; end if

	; next wram place to load from
++	inc		e			; $2291: $1c 
	push		de			; $2292: $d5 
	; and point to the next row in vram
	ld		de, $0020		; $2293: $11 $20 $00 
	add		hl, de			; $2296: $19 
	pop		de			; $2297: $d1 
	; keep loopin, for a whole 10 tiles of the map
	dec		b			; $2298: $05 
	jr		nz, -			; $2299: $20 $cc 
	; end loop

	; make original hram var set to 2h, disabling this routine next time!
	ld		a, $02			; $229b: $3e $02 
	ldh		($ea), a		; $229d: $e0 $ea 
	ret					; $229f: $c9 
; end routine

; routine
; called for a tile? tile $70
; hl points to the current byte on the current struct in the table
; given index in array by hram(e4h)
; array of references to series of 6 byte structs
; that array is at $651c, in bank 03 (fourth bank)
; searches for the 6 byte struct starting with whats given by hram(e5h)+hram(e6h)
; copies the last 4 bytes to hram at fff4h
ROUTINE_07:
	; save registers
	push		hl			; $22a0: $e5 
	push		de			; $22a1: $d5 
	push		bc			; $22a2: $c5 
	; if this hram var is set, quit the routine
	ldh		a, ($f9)		; $22a3: $f0 $f9 
	and		a			; $22a5: $a7 
	jr		nz, +			; $22a6: $20 $48 
	; move this hram var to this other one, and replace with 3
	; oh i see, fdh holds current bank
	; and e1 holds previous bank
	ldh		a, ($fd)		; $22a8: $f0 $fd 
	ldh		($e1), a		; $22aa: $e0 $e1 
	ld		a, $03			; $22ac: $3e $03 
	ldh		($fd), a		; $22ae: $e0 $fd 
	; switch to bank 03 (4th bank)
	ld		($2000), a		; $22b0: $ea $00 $20 
	; load up this word index offset
	ldh		a, ($e4)		; $22b3: $f0 $e4 
	add		a			; $22b5: $87 
	; and make hl point to 651ch + word offset
	ld		e, a			; $22b6: $5f 
	ld		d, $00			; $22b7: $16 $00 
	ld		hl, $651c		; $22b9: $21 $1c $65 
	add		hl, de			; $22bc: $19 
	; and, whatdya know, its a table of addresses again
	; grab this addres from the table
	ld		e, (hl)			; $22bd: $5e 
	inc		hl			; $22be: $23 
	ld		d, (hl)			; $22bf: $56 
	; and put it on hl
	push		de			; $22c0: $d5 
	pop		hl			; $22c1: $e1 

	; now we are going to check out the byte pointd to by hl
	; search until we find a matching byte with e5
	; or ff, in which case, quit
	; if this hram var does not = what is at the address...
-	ldh		a, ($e5)		; $22c2: $f0 $e5 
	cp		(hl)			; $22c4: $be 
	jr		z, ++			; $22c5: $28 $0d 
	; different:
	; check for ffh
	ld		a, (hl)			; $22c7: $7e 
	cp		$ff			; $22c8: $fe $ff 
	jr		z, +++			; $22ca: $28 $1d 
	; it doesnt = ffh either:
	; skip 6 bytes, and check all over again
	inc		hl			; $22cc: $23 
--	inc		hl			; $22cd: $23 
	inc		hl			; $22ce: $23 
	inc		hl			; $22cf: $23 
	inc		hl			; $22d0: $23 
	inc		hl			; $22d1: $23 
	jr		-			; $22d2: $18 $ee 

	; here if pointed value = hram(e5h)
	; basically, we found our matching byte!
	; but, now check the second byte, match hram(e6h)?
++	ldh		a, ($e6)		; $22d4: $f0 $e6 
	inc		hl			; $22d6: $23 
	cp		(hl)			; $22d7: $be 
	; if not, then, skip the rest of these 5 remaining bytes, keep lookin
	jr		nz, --			; $22d8: $20 $f3 

	; okay, found the one?
	; then, copy the last 4 bytes
	; to hrma starting at fff4h
	inc		hl			; $22da: $23 
	ld		de, $fff4		; $22db: $11 $f4 $ff 
	ldi		a, (hl)			; $22de: $2a 
	ld		(de), a			; $22df: $12 
	inc		e			; $22e0: $1c 
	ldi		a, (hl)			; $22e1: $2a 
	ld		(de), a			; $22e2: $12 
	inc		e			; $22e3: $1c 
	ldi		a, (hl)			; $22e4: $2a 
	ld		(de), a			; $22e5: $12 
	inc		e			; $22e6: $1c 
	ld		a, (hl)			; $22e7: $7e 
	ld		(de), a			; $22e8: $12 

	; here if pointed value = ffh
	; basically skip, ff ignores
	; switch back to the previous bank
+++	ldh		a, ($e1)		; $22e9: $f0 $e1 
	ldh		($fd), a		; $22eb: $e0 $fd 
	ld		($2000), a		; $22ed: $ea $00 $20 

	; restore registers and done
+	pop		bc			; $22f0: $c1 
	pop		de			; $22f1: $d1 
	pop		hl			; $22f2: $e1 
	ret					; $22f3: $c9 
; end routine

; routine
; called for tile $70 in the SECOND mysterious routine
; hl points to the tile in vram
ROUTINE_09:
	; this hram var is a flag whether to enable this
	; also used below
	ldh		a, ($f4)		; $22f4: $f0 $f4 
	and		a			; $22f6: $a7 
	ret		z			; $22f7: $c8 
	; save hl and de
	push		hl			; $22f8: $e5 
	push		de			; $22f9: $d5 

	; load de with a (signed) offset (its -20h)
	; ie, previous row in map memory
	ld		de, $ffe0		; $22fa: $11 $e0 $ff 
	; save the loaded hram var
	push		af			; $22fd: $f5 
	; point to the corresponding tile in wram
	ld		a, h			; $22fe: $7c 
	add		$30			; $22ff: $c6 $30 
	ld		h, a			; $2301: $67 
	; restore the loded hram var
	pop		af			; $2302: $f1 
	; and copy it to the corresponding wram place
	ld		(hl), a			; $2303: $77 
	; and copy /this/ hram var to wram tile above
	ldh		a, ($f5)		; $2304: $f0 $f5 
	add		hl, de			; $2306: $19 
	ld		(hl), a			; $2307: $77 
	; and this one too
	ldh		a, ($f6)		; $2308: $f0 $f6 
	add		hl, de			; $230a: $19 
	ld		(hl), a			; $230b: $77 
	; and this one yet above that one
	ldh		a, ($f7)		; $230c: $f0 $f7 
	add		hl, de			; $230e: $19 
	ld		(hl), a			; $230f: $77 
	; then clear those first two hram vars
	xor		a			; $2310: $af 
	ldh		($f4), a		; $2311: $e0 $f4 
	ldh		($f5), a		; $2313: $e0 $f5 

	; restore hl and de and done
	pop		de			; $2315: $d1 
	pop		hl			; $2316: $e1 
	ret					; $2317: $c9 
; end routine

; routine
; called for $80 $81 and $5f tiles?
ROUTINE_08:
	; save the registers!
	push		hl			; $2318: $e5 
	push		de			; $2319: $d5 
	push		bc			; $231a: $c5 
	; save the current bank and switch to bank 3 (fourth)
	ldh		a, ($fd)		; $231b: $f0 $fd 
	ldh		($e1), a		; $231d: $e0 $e1 
	ld		a, $03			; $231f: $3e $03 
	ldh		($fd), a		; $2321: $e0 $fd 
	ld		($2000), a		; $2323: $ea $00 $20 

	; point to address in array
	; array at 6526h in bank 03
	; array index is hram(e4h)
	; addresses point to series of 3 byte structs
	; first two bytes identify, lookin for the one maching hram(e5h+e6h)
	; series is terminated with ffh
	ldh		a, ($e4)		; $2326: $f0 $e4 
	add		a			; $2328: $87 
	ld		e, a			; $2329: $5f 
	ld		d, $00			; $232a: $16 $00 
	ld		hl, $6536		; $232c: $21 $36 $65 
	add		hl, de			; $232f: $19 
	; grab the address in that array on hl
	ld		e, (hl)			; $2330: $5e 
	inc		hl			; $2331: $23 
	ld		d, (hl)			; $2332: $56 
	push		de			; $2333: $d5 
	pop		hl			; $2334: $e1 

	; now check the structs in the series pointed to
	; first byte match?
-	ldh		a, ($e5)		; $2335: $f0 $e5 
	cp		(hl)			; $2337: $be 
	jr		z, +			; $2338: $28 $0a 
	; no? then is this the end? (ffh)
	ld		a, (hl)			; $233a: $7e 
	cp		$ff			; $233b: $fe $ff 
	jr		z, ++			; $233d: $28 $10 
	; get out if it is
	; otherwise, skip to the next 3 byte struct
	inc		hl			; $233f: $23 
--	inc		hl			; $2340: $23 
	inc		hl			; $2341: $23 
	; and check again
	jr		-			; $2342: $18 $f1 
	; first byte matched, now check second
+	ldh		a, ($e6)		; $2344: $f0 $e6 
	inc		hl			; $2346: $23 
	cp		(hl)			; $2347: $be 
	jr		nz, --			; $2348: $20 $f6 
	; if not match, then skip the last bytes and try again on the next one
	; if matched though, we found our match
	; so get the last byte, and copy it to this place in wram
	inc		hl			; $234a: $23 
	ld		a, (hl)			; $234b: $7e 
	ld		($c0cd), a		; $234c: $ea $cd $c0 

	; everything's done
	; switch back to the old bank
++	ldh		a, ($e1)		; $234f: $f0 $e1 
	ldh		($fd), a		; $2351: $e0 $fd 
	ld		($2000), a		; $2353: $ea $00 $20 
	; restore the registers and done!
	pop		bc			; $2356: $c1 
	pop		de			; $2357: $d1 
	pop		hl			; $2358: $e1 
	ret					; $2359: $c9 
; end routine

; routine
; called for $80 $5f and $81 in the second mysterious routine
; hl points to the tile in vram
ROUTINE_0A:
	; this wram var is enable flag for this routine
	; also tile for copying to wram map
	ld		a, ($c0cd)		; $235a: $fa $cd $c0 
	and		a			; $235d: $a7 
	ret		z			; $235e: $c8 
	; save hl and af
	push		hl			; $235f: $e5 
	push		af			; $2360: $f5 
	; point to correpsnding wram tile
	ld		a, h			; $2361: $7c 
	add		$30			; $2362: $c6 $30 
	ld		h, a			; $2364: $67 
	; grab that var back
	pop		af			; $2365: $f1 
	; and put it in corresponding wram tile
	ld		(hl), a			; $2366: $77 
	; and disable this routine by nulling the tile to put in wram
	xor		a			; $2367: $af 
	ld		($c0cd), a		; $2368: $ea $cd $c0 
	; restore hl and done
	pop		hl			; $236b: $e1 
	ret					; $236c: $c9 
; end routine

; routine
; state $0D
ROUTINE_13:
	; if this is set, quit
	; i wonder if its a timer divider?
	ldh		a, ($b2)		; $236d: $f0 $b2 
	and		a			; $236f: $a7 
	ret		nz			; $2370: $c0 
	call		$218f			; $2371: $cd $8f $21 
	call		ROUTINE_2E		; $2374: $cd $b2 $4f 
	ld		a, ($d007)		; $2377: $fa $07 $d0 
	and		a			; $237a: $a7 
	call		nz, $1b3c		; $237b: $c4 $3c $1b 
	call		$0837			; $237e: $cd $37 $08 
	call		$4fec			; $2381: $cd $ec $4f 
	call		$5118			; $2384: $cd $18 $51 
	ldh		a, ($fd)		; $2387: $f0 $fd 
	ldh		($e1), a		; $2389: $e0 $e1 
	ld		a, $03			; $238b: $3e $03 
	ldh		($fd), a		; $238d: $e0 $fd 
	ld		($2000), a		; $238f: $ea $00 $20 
	call		$498b			; $2392: $cd $8b $49 
	ld		bc, $c218		; $2395: $01 $18 $c2 
	ld		hl, $2164		; $2398: $21 $64 $21 
	call		$490d			; $239b: $cd $0d $49 
	ld		bc, $c228		; $239e: $01 $28 $c2 
	ld		hl, $2164		; $23a1: $21 $64 $21 
	call		$490d			; $23a4: $cd $0d $49 
	ld		bc, $c238		; $23a7: $01 $38 $c2 
	ld		hl, $2164		; $23aa: $21 $64 $21 
	call		$490d			; $23ad: $cd $0d $49 
	ld		bc, $c248		; $23b0: $01 $48 $c2 
	ld		hl, $2164		; $23b3: $21 $64 $21 
	call		$490d			; $23b6: $cd $0d $49 
	call		$4aea			; $23b9: $cd $ea $4a 
	call		$4b8a			; $23bc: $cd $8a $4b 
	call		$4bb5			; $23bf: $cd $b5 $4b 
	ldh		a, ($e1)		; $23c2: $f0 $e1 
	ldh		($fd), a		; $23c4: $e0 $fd 
	ld		($2000), a		; $23c6: $ea $00 $20 
	call		$2488			; $23c9: $cd $88 $24 
	ldh		a, ($fd)		; $23cc: $f0 $fd 
	ldh		($e1), a		; $23ce: $e0 $e1 
	ld		a, $02			; $23d0: $3e $02 
	ldh		($fd), a		; $23d2: $e0 $fd 
	ld		($2000), a		; $23d4: $ea $00 $20 
	call		$5844			; $23d7: $cd $44 $58 
	ldh		a, ($e1)		; $23da: $f0 $e1 
	ldh		($fd), a		; $23dc: $e0 $fd 
	ld		($2000), a		; $23de: $ea $00 $20 
	call		$172d			; $23e1: $cd $2d $17 
	call		$515e			; $23e4: $cd $5e $51 
	call		$1efa			; $23e7: $cd $fa $1e 
	ldh		a, ($ac)		; $23ea: $f0 $ac 
	and		$03			; $23ec: $e6 $03 
	ret		nz			; $23ee: $c0 
	ld		a, ($c203)		; $23ef: $fa $03 $c2 
	xor		$01			; $23f2: $ee $01 
	ld		($c203), a		; $23f4: $ea $03 $c2 
	ret					; $23f7: $c9 
; end routine

; routine
; there are some tiles that get redrawn and suff
; this might have to do with it i dont know
ROUTINE_19:
	; what is d014h?
	; anywho, it controls whether this happens
	ld		a, ($d014)		; $23f8: $fa $14 $d0 
	and		a			; $23fb: $a7 
	ret		z			; $23fc: $c8 
	; only continue if in one of the game play states?
	ldh		a, (r_state)		; $23fd: $f0 $b3 
	cp		$0d			; $23ff: $fe $0d 
	ret		nc			; $2401: $d0 
	; checks to see if the upcounting timer is where it should be
	ldh		a, (r_countup)		; $2402: $f0 $ac 
	and		$07			; $2404: $e6 $07 
	ret		nz			; $2406: $c0 
	; all good to go
	; use whats already in mem or.. else
	; depending on timer ?? ? 
	ldh		a, (r_countup)		; $2407: $f0 $ac 
	bit		3, a			; $2409: $cb $5f 
	jr		z, +			; $240b: $28 $05 
	ld		hl, $c600		; $240d: $21 $00 $c6 
	jr		++			; $2410: $18 $0e 
+	ld		hl, $3faf		; $2412: $21 $af $3f 
	; figure out which source to use, based on the world??
	ldh		a, (r_world)		; $2415: $f0 $b4 
	and		$f0			; $2417: $e6 $f0 
	sub		$10			; $2419: $d6 $10 
	rrca					; $241b: $0f 
	ld		d, $00			; $241c: $16 $00 
	ld		e, a			; $241e: $5f 
	add		hl, de			; $241f: $19 
	; copy 1bit tile data into tile memory
++	ld		de, $95d1		; $2420: $11 $d1 $95 
	ld		b, $08			; $2423: $06 $08 
-	ldi		a, (hl)			; $2425: $2a 
	ld		(de), a			; $2426: $12 
	inc		de			; $2427: $13 
	inc		de			; $2428: $13 
	dec		b			; $2429: $05 
	jr		nz, -			; $242a: $20 $f9 
	ret					; $242c: $c9 
; end routine

; byte array
; looks like bool values?
BYTE_ARRAY_00:
.db $00 $00 $01 $01 $01 $00 $00 $01 $01 $00 $01 $00
; end byte array

; routine
; called after turning lcd on and enabling interrupts?
ROUTINE_0B:
	; set this wram var to $c
	ld		a, $0c			; $2439:
	ld		($c0ab), a		; $243b: $ea $ab $c0 

	; call the routine below
	call		ROUTINE_0C		; $243e: $cd $53 $24 

	; clear this var
	xor		a			; $2441: $af 
	ld		($d007), a		; $2442: $ea $07 $d0 

	; grab an item ($e4) outta this byte array
	ld		hl, BYTE_ARRAY_00	; $2445: $21 $2d $24 
	ldh		a, ($e4)		; $2448: $f0 $e4 
	ld		d, $00			; $244a: $16 $00 
	ld		e, a			; $244c: $5f 
	add		hl, de			; $244d: $19 
	ld		a, (hl)			; $244e: $7e 
	; and copy it here
	ld		($d014), a		; $244f: $ea $14 $d0 

	; done
	ret					; $2452: $c9 
; end routine

; routine
; loops through a series of 3 byte structs
; looks for a certain one and saves it
; the address of the series is picked with index hram(e4h)
; then something happens in wram1 below
ROUTINE_0C:
	; point here to this WORD array and grab this array index
	ld		hl, $401a		; $2453: $21 $1a $40 
	ldh		a, ($e4)		; $2456: $f0 $e4 
	; and rotated it left, double it?
	rlca					; $2458: $07 
	; and again use as offset
	ld		d, $00			; $2459: $16 $00 
	ld		e, a			; $245b: $5f 
	add		hl, de			; $245c: $19 
	; i suppose that means theres a correpsonding WORD array
	; to the BYTE array above
	; and here we are getting the corresponding WORD value
	; and this word array has an address on it:
	; these addresses point to a series of 3byte structs
	; load it and put it on de
	ldi		a, (hl)			; $245d: $2a 
	ld		e, a			; $245e: $5f 
	ld		a, (hl)			; $245f: $7e 
	ld		d, a			; $2460: $57 
	; and put it on hl
	ld		h, d			; $2461: $62 
	ld		l, e			; $2462: $6b 
	; now we have an address on HL picked by the array index
	; compare (hl) with this wram var
	ld		a, ($c0ab)		; $2463: $fa $ab $c0 
	ld		b, a			; $2466: $47 
-	ld		a, (hl)			; $2467: $7e 
	cp		b			; $2468: $b8 
	; jump if wram var is less than or = (hl)
	jr		nc, +			; $2469: $30 $05 
	; if wram is greater than (hl): skip 3 bytes, next struct object
	inc		hl			; $246b: $23 
	inc		hl			; $246c: $23 
	inc		hl			; $246d: $23 
	jr		-			; $246e: $18 $f7 
	; found the right 3byte struct object
	; saving the address of this 3 byte struct
+	ld		a, l			; $2470: $7d 
	ld		($d010), a		; $2471: $ea $10 $d0 
	ld		a, h			; $2474: $7c 
	ld		($d011), a		; $2475: $ea $11 $d0 
	
	; starting at wram d100,
	; set every 10hth byte until $a0
	; wonder if there is a secret vram buffer in wram
	ld		hl, $d100		; $2478: $21 $00 $d1 
	ld		de, $0010		; $247b: $11 $10 $00 
-	ld		(hl), $ff		; $247e: $36 $ff 
	add		hl, de			; $2480: $19 
	ld		a, l			; $2481: $7d 
	cp		$a0			; $2482: $fe $a0 
	jp		nz, -			; $2484: $c2 $7e $24 
	
	; done
	ret					; $2487: $c9 
; end routine

; routine
ROUTINE_2C:
	call		$2492			; $2488: $cd $92 $24 
	call		$263f			; $248b: $cd $3f $26 
	call		$255f			; $248e: $cd $5f $25 
	ret					; $2491: $c9 
; end routine

; routine
ROUTINE_2D:
	ld		a, ($d010)		; $2492: $fa $10 $d0 
	ld		l, a			; $2495: $6f 
	ld		a, ($d011)		; $2496: $fa $11 $d0 
	ld		h, a			; $2499: $67 
	ld		a, (hl)			; $249a: $7e 
	ld		b, a			; $249b: $47 
	ld		a, ($c0ab)		; $249c: $fa $ab $c0 
	sub		b			; $249f: $90 
	ret		z			; $24a0: $c8 
	ret		c			; $24a1: $d8 
	ld		c, a			; $24a2: $4f 
	swap		c			; $24a3: $cb $31 
	push		hl			; $24a5: $e5 
	inc		hl			; $24a6: $23 
	ld		a, (hl)			; $24a7: $7e 
	and		$1f			; $24a8: $e6 $1f 
	rlca					; $24aa: $07 
	rlca					; $24ab: $07 
	rlca					; $24ac: $07 
	add		$10			; $24ad: $c6 $10 
	ldh		($c2), a		; $24af: $e0 $c2 
	ldi		a, (hl)			; $24b1: $2a 
	and		$c0			; $24b2: $e6 $c0 
	swap		a			; $24b4: $cb $37 
	add		$d0			; $24b6: $c6 $d0 
	sub		c			; $24b8: $91 
	ldh		($c3), a		; $24b9: $e0 $c3 
	call		$24e6			; $24bb: $cd $e6 $24 
	pop		hl			; $24be: $e1 
	ld		de, $0003		; $24bf: $11 $03 $00 
	add		hl, de			; $24c2: $19 
	ld		a, l			; $24c3: $7d 
	ld		($d010), a		; $24c4: $ea $10 $d0 
	ld		a, h			; $24c7: $7c 
	ld		($d011), a		; $24c8: $ea $11 $d0 
	jr		-$3b			; $24cb: $18 $c5 
	ld		a, ($d003)		; $24cd: $fa $03 $d0 
	ldh		($c0), a		; $24d0: $e0 $c0 
	cp		$ff			; $24d2: $fe $ff 
	ret		z			; $24d4: $c8 
	ld		d, $00			; $24d5: $16 $00 
	ld		e, a			; $24d7: $5f 
	rlca					; $24d8: $07 
	add		e			; $24d9: $83 
	rl		d			; $24da: $cb $12 
	ld		e, a			; $24dc: $5f 
	ld		hl, $336c		; $24dd: $21 $6c $33 
	add		hl, de			; $24e0: $19 
	ldi		a, (hl)			; $24e1: $2a 
	ldh		($c7), a		; $24e2: $e0 $c7 
	jr		$1c			; $24e4: $18 $1c 
	ldh		a, ($9a)		; $24e6: $f0 $9a 
	and		a			; $24e8: $a7 
	jr		nz, $03			; $24e9: $20 $03 
	bit		7, (hl)			; $24eb: $cb $7e 
	ret		nz			; $24ed: $c0 
	ld		a, (hl)			; $24ee: $7e 
	and		$7f			; $24ef: $e6 $7f 
	ldh		($c0), a		; $24f1: $e0 $c0 
	ld		d, $00			; $24f3: $16 $00 
	ld		e, a			; $24f5: $5f 
	rlca					; $24f6: $07 
	add		e			; $24f7: $83 
	rl		d			; $24f8: $cb $12 
	ld		e, a			; $24fa: $5f 
	ld		hl, $336c		; $24fb: $21 $6c $33 
	add		hl, de			; $24fe: $19 
	ld		a, (hl)			; $24ff: $7e 
	ldh		($c7), a		; $2500: $e0 $c7 
	xor		a			; $2502: $af 
	ldh		($c4), a		; $2503: $e0 $c4 
	ldh		($c5), a		; $2505: $e0 $c5 
	ldh		($c8), a		; $2507: $e0 $c8 
	ldh		($c9), a		; $2509: $e0 $c9 
	ldh		($cb), a		; $250b: $e0 $cb 
	ldh		a, ($c0)		; $250d: $f0 $c0 
	ld		d, $00			; $250f: $16 $00 
	ld		e, a			; $2511: $5f 
	rlca					; $2512: $07 
	add		e			; $2513: $83 
	rl		d			; $2514: $cb $12 
	ld		e, a			; $2516: $5f 
	ld		hl, $336c		; $2517: $21 $6c $33 
	add		hl, de			; $251a: $19 
	inc		hl			; $251b: $23 
	ldi		a, (hl)			; $251c: $2a 
	ldh		($ca), a		; $251d: $e0 $ca 
	ld		a, (hl)			; $251f: $7e 
	ldh		($cc), a		; $2520: $e0 $cc 
	cp		$c0			; $2522: $fe $c0 
	jr		c, $05			; $2524: $38 $05 
	ld		a, $0b			; $2526: $3e $0b 
	ld		($dfe8), a		; $2528: $ea $e8 $df 
	ld		de, $0010		; $252b: $11 $10 $00 
	ld		b, $00			; $252e: $06 $00 
	ld		hl, $d100		; $2530: $21 $00 $d1 
	ld		a, (hl)			; $2533: $7e 
	inc		a			; $2534: $3c 
	jr		z, $08			; $2535: $28 $08 
	inc		b			; $2537: $04 
	add		hl, de			; $2538: $19 
	ld		a, l			; $2539: $7d 
	cp		$90			; $253a: $fe $90 
	jr		nz, -$0b			; $253c: $20 $f5 
	ret					; $253e: $c9 
	ld		a, b			; $253f: $78 
	call		$2cee			; $2540: $cd $ee $2c 
	ret					; $2543: $c9 
; end routine

; routine
	ld		hl, $d190		; $2544: $21 $90 $d1 
	ld		(hl), a			; $2547: $77 
	ldh		a, ($c2)		; $2548: $f0 $c2 
	and		$f8			; $254a: $e6 $f8 
	add		$07			; $254c: $c6 $07 
	ld		($d192), a		; $254e: $ea $92 $d1 
	ldh		a, ($c3)		; $2551: $f0 $c3 
	ld		($d193), a		; $2553: $ea $93 $d1 
	call		$2cb2			; $2556: $cd $b2 $2c 
	ld		a, $0b			; $2559: $3e $0b 
	ld		($dfe0), a		; $255b: $ea $e0 $df 
	ret					; $255e: $c9 
; end routine

; routine
	xor		a			; $255f: $af 
	ld		($d013), a		; $2560: $ea $13 $d0 
	ld		c, $00			; $2563: $0e $00 
	ld		a, ($d013)		; $2565: $fa $13 $d0 
	cp		$14			; $2568: $fe $14 
	ret		nc			; $256a: $d0 
	push		bc			; $256b: $c5 
	ld		a, c			; $256c: $79 
	swap		a			; $256d: $cb $37 
	ld		hl, $d100		; $256f: $21 $00 $d1 
	ld		l, a			; $2572: $6f 
	ld		a, (hl)			; $2573: $7e 
	inc		a			; $2574: $3c 
	jr		z, $1d			; $2575: $28 $1d 
	ld		a, c			; $2577: $79 
	call		$2cdc			; $2578: $cd $dc $2c 
	ldh		a, ($c3)		; $257b: $f0 $c3 
	cp		$e0			; $257d: $fe $e0 
	jr		c, $0a			; $257f: $38 $0a 
	ld		a, $ff			; $2581: $3e $ff 
	ldh		($c0), a		; $2583: $e0 $c0 
	ld		a, c			; $2585: $79 
	call		$2cee			; $2586: $cd $ee $2c 
	jr		$09			; $2589: $18 $09 
	ldh		a, ($c2)		; $258b: $f0 $c2 
	cp		$c0			; $258d: $fe $c0 
	jr		nc, -$10			; $258f: $30 $f0 
	call		$25b7			; $2591: $cd $b7 $25 
	pop		bc			; $2594: $c1 
	inc		c			; $2595: $0c 
	ld		a, c			; $2596: $79 
	cp		$0a			; $2597: $fe $0a 
	jr		nz, -$36			; $2599: $20 $ca 
	ld		hl, $c050		; $259b: $21 $50 $c0 
	ld		a, ($d013)		; $259e: $fa $13 $d0 
	rlca					; $25a1: $07 
	rlca					; $25a2: $07 
	ld		d, $00			; $25a3: $16 $00 
	ld		e, a			; $25a5: $5f 
	add		hl, de			; $25a6: $19 
	ld		a, l			; $25a7: $7d 
	cp		$a0			; $25a8: $fe $a0 
	jp		nc, $25b6		; $25aa: $d2 $b6 $25 
	ld		a, $b4			; $25ad: $3e $b4 
	ld		(hl), a			; $25af: $77 
	inc		hl			; $25b0: $23 
	inc		hl			; $25b1: $23 
	inc		hl			; $25b2: $23 
	inc		hl			; $25b3: $23 
	jr		-$0f			; $25b4: $18 $f1 
	ret					; $25b6: $c9 
; end routine

; routine
	xor		a			; $25b7: $af 
	ld		($d000), a		; $25b8: $ea $00 $d0 
	ld		hl, $c050		; $25bb: $21 $50 $c0 
	ld		a, ($d013)		; $25be: $fa $13 $d0 
	rlca					; $25c1: $07 
	rlca					; $25c2: $07 
	ld		d, $00			; $25c3: $16 $00 
	ld		e, a			; $25c5: $5f 
	add		hl, de			; $25c6: $19 
	ld		b, h			; $25c7: $44 
	ld		c, l			; $25c8: $4d 
	ld		hl, $2fd9		; $25c9: $21 $d9 $2f 
	ldh		a, ($c5)		; $25cc: $f0 $c5 
	and		$01			; $25ce: $e6 $01 
	jr		nz, $03			; $25d0: $20 $03 
	ld		hl, $30ab		; $25d2: $21 $ab $30 
	ldh		a, ($c6)		; $25d5: $f0 $c6 
	rlca					; $25d7: $07 
	ld		d, $00			; $25d8: $16 $00 
	ld		e, a			; $25da: $5f 
	add		hl, de			; $25db: $19 
	ldi		a, (hl)			; $25dc: $2a 
	ld		e, a			; $25dd: $5f 
	ld		a, (hl)			; $25de: $7e 
	ld		d, a			; $25df: $57 
	ld		h, d			; $25e0: $62 
	ld		l, e			; $25e1: $6b 
	ld		a, ($d013)		; $25e2: $fa $13 $d0 
	cp		$14			; $25e5: $fe $14 
	ret		nc			; $25e7: $d0 
	ld		a, (hl)			; $25e8: $7e 
	cp		$ff			; $25e9: $fe $ff 
	ret		z			; $25eb: $c8 
	bit		7, a			; $25ec: $cb $7f 
	jr		nz, $35			; $25ee: $20 $35 
	rlca					; $25f0: $07 
	res		4, a			; $25f1: $cb $a7 
	ld		($d000), a		; $25f3: $ea $00 $d0 
	ld		a, (hl)			; $25f6: $7e 
	bit		3, a			; $25f7: $cb $5f 
	jr		z, $07			; $25f9: $28 $07 
	ldh		a, ($c2)		; $25fb: $f0 $c2 
	sub		$08			; $25fd: $d6 $08 
	ldh		($c2), a		; $25ff: $e0 $c2 
	ld		a, (hl)			; $2601: $7e 
	bit		2, a			; $2602: $cb $57 
	jr		z, $07			; $2604: $28 $07 
	ldh		a, ($c2)		; $2606: $f0 $c2 
	add		$08			; $2608: $c6 $08 
	ldh		($c2), a		; $260a: $e0 $c2 
	ld		a, (hl)			; $260c: $7e 
	bit		1, a			; $260d: $cb $4f 
	jr		z, $07			; $260f: $28 $07 
	ldh		a, ($c3)		; $2611: $f0 $c3 
	sub		$08			; $2613: $d6 $08 
	ldh		($c3), a		; $2615: $e0 $c3 
	ld		a, (hl)			; $2617: $7e 
	bit		0, a			; $2618: $cb $47 
	jr		z, $06			; $261a: $28 $06 
	ldh		a, ($c3)		; $261c: $f0 $c3 
	add		$08			; $261e: $c6 $08 
	ldh		($c3), a		; $2620: $e0 $c3 
	inc		hl			; $2622: $23 
	jr		-$3d			; $2623: $18 $c3 
	ldh		a, ($c2)		; $2625: $f0 $c2 
	ld		(bc), a			; $2627: $02 
	inc		bc			; $2628: $03 
	ldh		a, ($c3)		; $2629: $f0 $c3 
	ld		(bc), a			; $262b: $02 
	inc		bc			; $262c: $03 
	ld		a, (hl)			; $262d: $7e 
	ld		(bc), a			; $262e: $02 
	inc		bc			; $262f: $03 
	ld		a, ($d000)		; $2630: $fa $00 $d0 
	ld		(bc), a			; $2633: $02 
	inc		bc			; $2634: $03 
	inc		hl			; $2635: $23 
	ld		a, ($d013)		; $2636: $fa $13 $d0 
	inc		a			; $2639: $3c 
	ld		($d013), a		; $263a: $ea $13 $d0 
	jr		-$5d			; $263d: $18 $a3 
	ld		hl, $d100		; $263f: $21 $00 $d1 
	ld		a, (hl)			; $2642: $7e 
	inc		a			; $2643: $3c 
	jr		z, $1d			; $2644: $28 $1d 
	push		hl			; $2646: $e5 
	call		$2ce2			; $2647: $cd $e2 $2c 
	ld		hl, $3495		; $264a: $21 $95 $34 
	ldh		a, ($c0)		; $264d: $f0 $c0 
	rlca					; $264f: $07 
	ld		d, $00			; $2650: $16 $00 
	ld		e, a			; $2652: $5f 
	add		hl, de			; $2653: $19 
	ldi		a, (hl)			; $2654: $2a 
	ld		e, a			; $2655: $5f 
	ld		a, (hl)			; $2656: $7e 
	ld		d, a			; $2657: $57 
	ld		h, d			; $2658: $62 
	ld		l, e			; $2659: $6b 
	call		$266d			; $265a: $cd $6d $26 
	pop		hl			; $265d: $e1 
	push		hl			; $265e: $e5 
	call		$2cf4			; $265f: $cd $f4 $2c 
	pop		hl			; $2662: $e1 
	ld		a, l			; $2663: $7d 
	add		$10			; $2664: $c6 $10 
	ld		l, a			; $2666: $6f 
	cp		$a0			; $2667: $fe $a0 
	jp		nz, $2642		; $2669: $c2 $42 $26 
	ret					; $266c: $c9 
; end routine

; routine
	ldh		a, ($c8)		; $266d: $f0 $c8 
	and		a			; $266f: $a7 
	jr		z, $3a			; $2670: $28 $3a 
	ldh		a, ($c7)		; $2672: $f0 $c7 
	bit		1, a			; $2674: $cb $4f 
	jr		z, $11			; $2676: $28 $11 
	call		$2bb2			; $2678: $cd $b2 $2b 
	jr		nc, $06			; $267b: $30 $06 
	ldh		a, ($c2)		; $267d: $f0 $c2 
	inc		a			; $267f: $3c 
	ldh		($c2), a		; $2680: $e0 $c2 
	ret					; $2682: $c9 
	ldh		a, ($c2)		; $2683: $f0 $c2 
	and		$f8			; $2685: $e6 $f8 
	ldh		($c2), a		; $2687: $e0 $c2 
	ldh		a, ($c9)		; $2689: $f0 $c9 
	and		$f0			; $268b: $e6 $f0 
	swap		a			; $268d: $cb $37 
	ld		b, a			; $268f: $47 
	ldh		a, ($c9)		; $2690: $f0 $c9 
	and		$0f			; $2692: $e6 $0f 
	cp		b			; $2694: $b8 
	jr		z, $07			; $2695: $28 $07 
	inc		b			; $2697: $04 
	swap		b			; $2698: $cb $30 
	or		b			; $269a: $b0 
	ldh		($c9), a		; $269b: $e0 $c9 
	ret					; $269d: $c9 
	ldh		a, ($c9)		; $269e: $f0 $c9 
	and		$0f			; $26a0: $e6 $0f 
	ldh		($c9), a		; $26a2: $e0 $c9 
	ldh		a, ($c8)		; $26a4: $f0 $c8 
	dec		a			; $26a6: $3d 
	ldh		($c8), a		; $26a7: $e0 $c8 
	jp		$2870			; $26a9: $c3 $70 $28 
	push		hl			; $26ac: $e5 
	ld		d, $00			; $26ad: $16 $00 
	ldh		a, ($c4)		; $26af: $f0 $c4 
	ld		e, a			; $26b1: $5f 
	add		hl, de			; $26b2: $19 
	ld		a, (hl)			; $26b3: $7e 
	ld		($d002), a		; $26b4: $ea $02 $d0 
	cp		$ff			; $26b7: $fe $ff 
	jr		nz, $06			; $26b9: $20 $06 
	xor		a			; $26bb: $af 
	ldh		($c4), a		; $26bc: $e0 $c4 
	pop		hl			; $26be: $e1 
	jr		-$15			; $26bf: $18 $eb 
	ldh		a, ($c4)		; $26c1: $f0 $c4 
	inc		a			; $26c3: $3c 
	ldh		($c4), a		; $26c4: $e0 $c4 
	ld		a, ($d002)		; $26c6: $fa $02 $d0 
	and		$f0			; $26c9: $e6 $f0 
	cp		$f0			; $26cb: $fe $f0 
	jr		z, $20			; $26cd: $28 $20 
	ld		a, ($d002)		; $26cf: $fa $02 $d0 
	and		$e0			; $26d2: $e6 $e0 
	cp		$e0			; $26d4: $fe $e0 
	jr		nz, $0a			; $26d6: $20 $0a 
	ld		a, ($d002)		; $26d8: $fa $02 $d0 
	and		$0f			; $26db: $e6 $0f 
	ldh		($c8), a		; $26dd: $e0 $c8 
	pop		hl			; $26df: $e1 
	jr		-$75			; $26e0: $18 $8b 
	ld		a, ($d002)		; $26e2: $fa $02 $d0 
	ldh		($c1), a		; $26e5: $e0 $c1 
	ld		a, $01			; $26e7: $3e $01 
	ldh		($c8), a		; $26e9: $e0 $c8 
	pop		hl			; $26eb: $e1 
	jp		$266d			; $26ec: $c3 $6d $26 
	ldh		a, ($c4)		; $26ef: $f0 $c4 
	inc		a			; $26f1: $3c 
	ldh		($c4), a		; $26f2: $e0 $c4 
	inc		hl			; $26f4: $23 
	ld		a, (hl)			; $26f5: $7e 
	ld		($d003), a		; $26f6: $ea $03 $d0 
	ld		a, ($d002)		; $26f9: $fa $02 $d0 
	cp		$f8			; $26fc: $fe $f8 
	jr		nz, $08			; $26fe: $20 $08 
	ld		a, ($d003)		; $2700: $fa $03 $d0 
	ldh		($c6), a		; $2703: $e0 $c6 
	pop		hl			; $2705: $e1 
	jr		-$5c			; $2706: $18 $a4 
	cp		$f0			; $2708: $fe $f0 
	jr		nz, $78			; $270a: $20 $78 
	ld		a, ($d003)		; $270c: $fa $03 $d0 
	and		$c0			; $270f: $e6 $c0 
	jr		z, $38			; $2711: $28 $38 
	bit		7, a			; $2713: $cb $7f 
	jr		z, $13			; $2715: $28 $13 
	ldh		a, ($c5)		; $2717: $f0 $c5 
	and		$fd			; $2719: $e6 $fd 
	ld		b, a			; $271b: $47 
	ld		a, ($c201)		; $271c: $fa $01 $c2 
	ld		c, a			; $271f: $4f 
	ldh		a, ($c2)		; $2720: $f0 $c2 
	sub		c			; $2722: $91 
	rla					; $2723: $17 
	rlca					; $2724: $07 
	and		$02			; $2725: $e6 $02 
	or		b			; $2727: $b0 
	ldh		($c5), a		; $2728: $e0 $c5 
	ld		a, ($d003)		; $272a: $fa $03 $d0 
	bit		6, a			; $272d: $cb $77 
	jr		z, $1a			; $272f: $28 $1a 
	ld		a, ($c202)		; $2731: $fa $02 $c2 
	ld		c, a			; $2734: $4f 
	ldh		a, ($c3)		; $2735: $f0 $c3 
	ld		b, a			; $2737: $47 
	ldh		a, ($ca)		; $2738: $f0 $ca 
	and		$70			; $273a: $e6 $70 
	rrca					; $273c: $0f 
	rrca					; $273d: $0f 
	add		b			; $273e: $80 
	sub		c			; $273f: $91 
	rla					; $2740: $17 
	and		$01			; $2741: $e6 $01 
	ld		b, a			; $2743: $47 
	ldh		a, ($c5)		; $2744: $f0 $c5 
	and		$fe			; $2746: $e6 $fe 
	or		b			; $2748: $b0 
	ldh		($c5), a		; $2749: $e0 $c5 
	ld		a, ($d003)		; $274b: $fa $03 $d0 
	and		$0c			; $274e: $e6 $0c 
	jr		z, $08			; $2750: $28 $08 
	rra					; $2752: $1f 
	rra					; $2753: $1f 
	ld		b, a			; $2754: $47 
	ldh		a, ($c5)		; $2755: $f0 $c5 
	xor		b			; $2757: $a8 
	ldh		($c5), a		; $2758: $e0 $c5 
	ld		a, ($d003)		; $275a: $fa $03 $d0 
	bit		5, a			; $275d: $cb $6f 
	jr		z, $0c			; $275f: $28 $0c 
	and		$02			; $2761: $e6 $02 
	or		$fd			; $2763: $f6 $fd 
	ld		b, a			; $2765: $47 
	ldh		a, ($c5)		; $2766: $f0 $c5 
	set		1, a			; $2768: $cb $cf 
	and		b			; $276a: $a0 
	ldh		($c5), a		; $276b: $e0 $c5 
	ld		a, ($d003)		; $276d: $fa $03 $d0 
	bit		4, a			; $2770: $cb $67 
	jr		z, $0c			; $2772: $28 $0c 
	and		$01			; $2774: $e6 $01 
	or		$fe			; $2776: $f6 $fe 
	ld		b, a			; $2778: $47 
	ldh		a, ($c5)		; $2779: $f0 $c5 
	set		0, a			; $277b: $cb $c7 
	and		b			; $277d: $a0 
	ldh		($c5), a		; $277e: $e0 $c5 
	pop		hl			; $2780: $e1 
	jp		$26ac			; $2781: $c3 $ac $26 
	cp		$f1			; $2784: $fe $f1 
	jr		nz, $11			; $2786: $20 $11 
	ld		a, $0a			; $2788: $3e $0a 
	call		$2cee			; $278a: $cd $ee $2c 
	call		$24cd			; $278d: $cd $cd $24 
	ld		a, $0a			; $2790: $3e $0a 
	call		$2cdc			; $2792: $cd $dc $2c 
	pop		hl			; $2795: $e1 
	jp		$26ac			; $2796: $c3 $ac $26 
	cp		$f2			; $2799: $fe $f2 
	jr		nz, $09			; $279b: $20 $09 
	ld		a, ($d003)		; $279d: $fa $03 $d0 
	ldh		($c7), a		; $27a0: $e0 $c7 
	pop		hl			; $27a2: $e1 
	jp		$26ac			; $27a3: $c3 $ac $26 
	cp		$f3			; $27a6: $fe $f3 
	jr		nz, $24			; $27a8: $20 $24 
	ld		a, ($d003)		; $27aa: $fa $03 $d0 
	ldh		($c0), a		; $27ad: $e0 $c0 
	cp		$ff			; $27af: $fe $ff 
	jp		z, $286e		; $27b1: $ca $6e $28 
	ld		hl, $ffc0		; $27b4: $21 $c0 $ff 
	call		$2cb2			; $27b7: $cd $b2 $2c 
	pop		hl			; $27ba: $e1 
	ld		hl, $3495		; $27bb: $21 $95 $34 
	ldh		a, ($c0)		; $27be: $f0 $c0 
	rlca					; $27c0: $07 
	ld		d, $00			; $27c1: $16 $00 
	ld		e, a			; $27c3: $5f 
	add		hl, de			; $27c4: $19 
	ldi		a, (hl)			; $27c5: $2a 
	ld		e, a			; $27c6: $5f 
	ld		a, (hl)			; $27c7: $7e 
	ld		d, a			; $27c8: $57 
	ld		h, d			; $27c9: $62 
	ld		l, e			; $27ca: $6b 
	jp		$26ac			; $27cb: $c3 $ac $26 
	cp		$f4			; $27ce: $fe $f4 
	jr		nz, $09			; $27d0: $20 $09 
	ld		a, ($d003)		; $27d2: $fa $03 $d0 
	ldh		($c9), a		; $27d5: $e0 $c9 
	pop		hl			; $27d7: $e1 
	jp		$26ac			; $27d8: $c3 $ac $26 
	cp		$f5			; $27db: $fe $f5 
	jr		nz, $0c			; $27dd: $20 $0c 
	ldh		a, ($04)		; $27df: $f0 $04 
	and		$03			; $27e1: $e6 $03 
	ld		a, $f1			; $27e3: $3e $f1 
	jr		z, -$63			; $27e5: $28 $9d 
	pop		hl			; $27e7: $e1 
	jp		$26ac			; $27e8: $c3 $ac $26 
	cp		$f6			; $27eb: $fe $f6 
	jr		nz, $20			; $27ed: $20 $20 
	ld		a, ($c202)		; $27ef: $fa $02 $c2 
	ld		b, a			; $27f2: $47 
	ldh		a, ($c3)		; $27f3: $f0 $c3 
	sub		b			; $27f5: $90 
	add		$14			; $27f6: $c6 $14 
	cp		$20			; $27f8: $fe $20 
	ld		a, ($d003)		; $27fa: $fa $03 $d0 
	dec		a			; $27fd: $3d 
	jr		z, $01			; $27fe: $28 $01 
	ccf					; $2800: $3f 
	jr		c, $08			; $2801: $38 $08 
	ldh		a, ($c4)		; $2803: $f0 $c4 
	dec		a			; $2805: $3d 
	dec		a			; $2806: $3d 
	ldh		($c4), a		; $2807: $e0 $c4 
	pop		hl			; $2809: $e1 
	ret					; $280a: $c9 
	pop		hl			; $280b: $e1 
	jp		$26ac			; $280c: $c3 $ac $26 
	cp		$f7			; $280f: $fe $f7 
	jr		nz, $05			; $2811: $20 $05 
	call		$2b21			; $2813: $cd $21 $2b 
	pop		hl			; $2816: $e1 
	ret					; $2817: $c9 
	cp		$f9			; $2818: $fe $f9 
	jr		nz, $08			; $281a: $20 $08 
	ld		a, ($d003)		; $281c: $fa $03 $d0 
	ld		($dff8), a		; $281f: $ea $f8 $df 
	pop		hl			; $2822: $e1 
	ret					; $2823: $c9 
	cp		$fa			; $2824: $fe $fa 
	jr		nz, $08			; $2826: $20 $08 
	ld		a, ($d003)		; $2828: $fa $03 $d0 
	ld		($dfe0), a		; $282b: $ea $e0 $df 
	pop		hl			; $282e: $e1 
	ret					; $282f: $c9 
	cp		$fb			; $2830: $fe $fb 
	jr		nz, $19			; $2832: $20 $19 
	ld		a, ($d003)		; $2834: $fa $03 $d0 
	ld		c, a			; $2837: $4f 
	ld		a, ($c202)		; $2838: $fa $02 $c2 
	ld		b, a			; $283b: $47 
	ldh		a, ($c3)		; $283c: $f0 $c3 
	sub		b			; $283e: $90 
	cp		c			; $283f: $b9 
	jr		c, $07			; $2840: $38 $07 
	xor		a			; $2842: $af 
	ldh		($c4), a		; $2843: $e0 $c4 
	pop		hl			; $2845: $e1 
	jp		$26ac			; $2846: $c3 $ac $26 
	pop		hl			; $2849: $e1 
	jp		$26ac			; $284a: $c3 $ac $26 
	cp		$fc			; $284d: $fe $fc 
	jr		nz, $0d			; $284f: $20 $0d 
	ld		a, ($d003)		; $2851: $fa $03 $d0 
	ldh		($c2), a		; $2854: $e0 $c2 
	ld		a, $70			; $2856: $3e $70 
	ldh		($c3), a		; $2858: $e0 $c3 
	pop		hl			; $285a: $e1 
	jp		$26ac			; $285b: $c3 $ac $26 
	cp		$fd			; $285e: $fe $fd 
	jr		nz, $08			; $2860: $20 $08 
	ld		a, ($d003)		; $2862: $fa $03 $d0 
	ld		($dfe8), a		; $2865: $ea $e8 $df 
	pop		hl			; $2868: $e1 
	ret					; $2869: $c9 
	pop		hl			; $286a: $e1 
	jp		$26ac			; $286b: $c3 $ac $26 
	pop		hl			; $286e: $e1 
	ret					; $286f: $c9 

	ldh		a, ($c1)		; $2870: $f0 $c1 
	and		$0f			; $2872: $e6 $0f 
	jp		z, $296c		; $2874: $ca $6c $29 
	ldh		a, ($c5)		; $2877: $f0 $c5 
	bit		0, a			; $2879: $cb $47 
	jr		nz, $6a			; $287b: $20 $6a 
	call		$2b7b			; $287d: $cd $7b $2b 
	jr		nc, $43			; $2880: $30 $43 
	ldh		a, ($c7)		; $2882: $f0 $c7 
	bit		0, a			; $2884: $cb $47 
	jr		z, $05			; $2886: $28 $05 
	call		$2bdb			; $2888: $cd $db $2b 
	jr		c, $44			; $288b: $38 $44 
	ldh		a, ($c1)		; $288d: $f0 $c1 
	and		$0f			; $288f: $e6 $0f 
	ld		b, a			; $2891: $47 
	ldh		a, ($c3)		; $2892: $f0 $c3 
	sub		b			; $2894: $90 
	ldh		($c3), a		; $2895: $e0 $c3 
	ldh		a, ($cb)		; $2897: $f0 $cb 
	and		a			; $2899: $a7 
	jp		z, $296c		; $289a: $ca $6c $29 
	ld		a, ($c205)		; $289d: $fa $05 $c2 
	ld		c, a			; $28a0: $4f 
	push		bc			; $28a1: $c5 
	ld		a, $20			; $28a2: $3e $20 
	ld		($c205), a		; $28a4: $ea $05 $c2 
	call		$1aa4			; $28a7: $cd $a4 $1a 
	pop		bc			; $28aa: $c1 
	and		a			; $28ab: $a7 
	jr		nz, $10			; $28ac: $20 $10 
	ld		a, ($c202)		; $28ae: $fa $02 $c2 
	sub		b			; $28b1: $90 
	ld		($c202), a		; $28b2: $ea $02 $c2 
	cp		$0f			; $28b5: $fe $0f 
	jr		nc, $05			; $28b7: $30 $05 
	ld		a, $0f			; $28b9: $3e $0f 
	ld		($c202), a		; $28bb: $ea $02 $c2 
	ld		a, c			; $28be: $79 
	ld		($c205), a		; $28bf: $ea $05 $c2 
	jp		$296c			; $28c2: $c3 $6c $29 
	ldh		a, ($c7)		; $28c5: $f0 $c7 
	and		$0c			; $28c7: $e6 $0c 
	cp		$00			; $28c9: $fe $00 
	jr		z, -$40			; $28cb: $28 $c0 
	cp		$04			; $28cd: $fe $04 
	jr		nz, $09			; $28cf: $20 $09 
	ldh		a, ($c5)		; $28d1: $f0 $c5 
	set		0, a			; $28d3: $cb $c7 
	ldh		($c5), a		; $28d5: $e0 $c5 
	jp		$296c			; $28d7: $c3 $6c $29 
	cp		$0c			; $28da: $fe $0c 
	jp		nz, $296c		; $28dc: $c2 $6c $29 
	xor		a			; $28df: $af 
	ldh		($c4), a		; $28e0: $e0 $c4 
	ldh		($c8), a		; $28e2: $e0 $c8 
	jp		$296c			; $28e4: $c3 $6c $29 
	call		$2b91			; $28e7: $cd $91 $2b 
	jr		nc, $63			; $28ea: $30 $63 
	ldh		a, ($c7)		; $28ec: $f0 $c7 
	bit		0, a			; $28ee: $cb $47 
	jr		z, $05			; $28f0: $28 $05 
	call		$2bf5			; $28f2: $cd $f5 $2b 
	jr		c, $64			; $28f5: $38 $64 
	ldh		a, ($c1)		; $28f7: $f0 $c1 
	and		$0f			; $28f9: $e6 $0f 
	ld		b, a			; $28fb: $47 
	ldh		a, ($c3)		; $28fc: $f0 $c3 
	add		b			; $28fe: $80 
	ldh		($c3), a		; $28ff: $e0 $c3 
	ldh		a, ($cb)		; $2901: $f0 $cb 
	and		a			; $2903: $a7 
	jr		z, $66			; $2904: $28 $66 
	ld		a, ($c205)		; $2906: $fa $05 $c2 
	ld		c, a			; $2909: $4f 
	push		bc			; $290a: $c5 
	xor		a			; $290b: $af 
	ld		($c205), a		; $290c: $ea $05 $c2 
	call		$1aa4			; $290f: $cd $a4 $1a 
	pop		bc			; $2912: $c1 
	and		a			; $2913: $a7 
	jr		nz, $25			; $2914: $20 $25 
	ld		a, ($c202)		; $2916: $fa $02 $c2 
	add		b			; $2919: $80 
	ld		($c202), a		; $291a: $ea $02 $c2 
	cp		$51			; $291d: $fe $51 
	jr		c, $1a			; $291f: $38 $1a 
	ld		a, ($c0d2)		; $2921: $fa $d2 $c0 
	cp		$07			; $2924: $fe $07 
	jr		nc, $19			; $2926: $30 $19 
	ld		a, ($c202)		; $2928: $fa $02 $c2 
	sub		$50			; $292b: $d6 $50 
	ld		b, a			; $292d: $47 
	ld		a, $50			; $292e: $3e $50 
	ld		($c202), a		; $2930: $ea $02 $c2 
	ldh		a, ($a4)		; $2933: $f0 $a4 
	add		b			; $2935: $80 
	ldh		($a4), a		; $2936: $e0 $a4 
	call		$2c96			; $2938: $cd $96 $2c 
	ld		a, c			; $293b: $79 
	ld		($c205), a		; $293c: $ea $05 $c2 
	jr		$2b			; $293f: $18 $2b 
	ldh		a, ($a4)		; $2941: $f0 $a4 
	and		$0c			; $2943: $e6 $0c 
	jr		nz, -$1f			; $2945: $20 $e1 
	ldh		a, ($a4)		; $2947: $f0 $a4 
	and		$fc			; $2949: $e6 $fc 
	ldh		($a4), a		; $294b: $e0 $a4 
	jr		-$14			; $294d: $18 $ec 
	ldh		a, ($c7)		; $294f: $f0 $c7 
	and		$0c			; $2951: $e6 $0c 
	cp		$00			; $2953: $fe $00 
	jr		z, -$60			; $2955: $28 $a0 
	cp		$04			; $2957: $fe $04 
	jr		nz, $08			; $2959: $20 $08 
	ldh		a, ($c5)		; $295b: $f0 $c5 
	res		0, a			; $295d: $cb $87 
	ldh		($c5), a		; $295f: $e0 $c5 
	jr		$09			; $2961: $18 $09 
	cp		$0c			; $2963: $fe $0c 
	jr		nz, $05			; $2965: $20 $05 
	xor		a			; $2967: $af 
	ldh		($c4), a		; $2968: $e0 $c4 
	ldh		($c8), a		; $296a: $e0 $c8 
	ldh		a, ($c1)		; $296c: $f0 $c1 
	and		$f0			; $296e: $e6 $f0 
	jp		z, $29f4		; $2970: $ca $f4 $29 
	ldh		a, ($c5)		; $2973: $f0 $c5 
	bit		1, a			; $2975: $cb $4f 
	jr		nz, $3f			; $2977: $20 $3f 
	call		$2c18			; $2979: $cd $18 $2c 
	jr		nc, $1a			; $297c: $30 $1a 
	ldh		a, ($c1)		; $297e: $f0 $c1 
	and		$f0			; $2980: $e6 $f0 
	swap		a			; $2982: $cb $37 
	ld		b, a			; $2984: $47 
	ldh		a, ($c2)		; $2985: $f0 $c2 
	sub		b			; $2987: $90 
	ldh		($c2), a		; $2988: $e0 $c2 
	ldh		a, ($cb)		; $298a: $f0 $cb 
	and		a			; $298c: $a7 
	jr		z, $65			; $298d: $28 $65 
	ld		a, ($c201)		; $298f: $fa $01 $c2 
	sub		b			; $2992: $90 
	ld		($c201), a		; $2993: $ea $01 $c2 
	jr		$5c			; $2996: $18 $5c 
	ldh		a, ($c7)		; $2998: $f0 $c7 
	and		$c0			; $299a: $e6 $c0 
	cp		$00			; $299c: $fe $00 
	jr		z, -$22			; $299e: $28 $de 
	cp		$40			; $29a0: $fe $40 
	jp		nz, $29ad		; $29a2: $c2 $ad $29 
	ldh		a, ($c5)		; $29a5: $f0 $c5 
	set		1, a			; $29a7: $cb $cf 
	ldh		($c5), a		; $29a9: $e0 $c5 
	jr		$47			; $29ab: $18 $47 
	cp		$c0			; $29ad: $fe $c0 
	jr		nz, $43			; $29af: $20 $43 
	xor		a			; $29b1: $af 
	ldh		($c4), a		; $29b2: $e0 $c4 
	ldh		($c8), a		; $29b4: $e0 $c8 
	jr		$3c			; $29b6: $18 $3c 
	call		$2bb2			; $29b8: $cd $b2 $2b 
	jr		nc, $1a			; $29bb: $30 $1a 
	ldh		a, ($c1)		; $29bd: $f0 $c1 
	and		$f0			; $29bf: $e6 $f0 
	swap		a			; $29c1: $cb $37 
	ld		b, a			; $29c3: $47 
	ldh		a, ($c2)		; $29c4: $f0 $c2 
	add		b			; $29c6: $80 
	ldh		($c2), a		; $29c7: $e0 $c2 
	ldh		a, ($cb)		; $29c9: $f0 $cb 
	and		a			; $29cb: $a7 
	jr		z, $26			; $29cc: $28 $26 
	ld		a, ($c201)		; $29ce: $fa $01 $c2 
	add		b			; $29d1: $80 
	ld		($c201), a		; $29d2: $ea $01 $c2 
	jr		$1d			; $29d5: $18 $1d 
	ldh		a, ($c7)		; $29d7: $f0 $c7 
	and		$30			; $29d9: $e6 $30 
	cp		$00			; $29db: $fe $00 
	jr		z, -$22			; $29dd: $28 $de 
	cp		$10			; $29df: $fe $10 
	jr		nz, $08			; $29e1: $20 $08 
	ldh		a, ($c5)		; $29e3: $f0 $c5 
	res		1, a			; $29e5: $cb $8f 
	ldh		($c5), a		; $29e7: $e0 $c5 
	jr		$09			; $29e9: $18 $09 
	cp		$30			; $29eb: $fe $30 
	jr		nz, $05			; $29ed: $20 $05 
	xor		a			; $29ef: $af 
	ldh		($c4), a		; $29f0: $e0 $c4 
	ldh		($c8), a		; $29f2: $e0 $c8 
	xor		a			; $29f4: $af 
	ldh		($cb), a		; $29f5: $e0 $cb 
	ret					; $29f7: $c9 
; end routine

; routine
	push		hl			; $29f8: $e5 
	ld		a, (hl)			; $29f9: $7e 
	ld		e, a			; $29fa: $5f 
	ld		d, $00			; $29fb: $16 $00 
	ld		l, a			; $29fd: $6f 
	ld		h, $00			; $29fe: $26 $00 
	sla		e			; $2a00: $cb $23 
	rl		d			; $2a02: $cb $12 
	sla		e			; $2a04: $cb $23 
	rl		d			; $2a06: $cb $12 
	add		hl, de			; $2a08: $19 
	ld		de, $317d		; $2a09: $11 $7d $31 
	add		hl, de			; $2a0c: $19 
	ld		a, (hl)			; $2a0d: $7e 
	pop		hl			; $2a0e: $e1 
	and		a			; $2a0f: $a7 
	ret		z			; $2a10: $c8 
	push		hl			; $2a11: $e5 
	ld		(hl), a			; $2a12: $77 
	call		$2cb2			; $2a13: $cd $b2 $2c 
	ld		a, $ff			; $2a16: $3e $ff 
	pop		hl			; $2a18: $e1 
	ret					; $2a19: $c9 
; end routine

; routine
	push		hl			; $2a1a: $e5 
	ld		a, (hl)			; $2a1b: $7e 
	ld		e, a			; $2a1c: $5f 
	ld		d, $00			; $2a1d: $16 $00 
	ld		l, a			; $2a1f: $6f 
	ld		h, $00			; $2a20: $26 $00 
	sla		e			; $2a22: $cb $23 
	rl		d			; $2a24: $cb $12 
	sla		e			; $2a26: $cb $23 
	rl		d			; $2a28: $cb $12 
	add		hl, de			; $2a2a: $19 
	ld		de, $317d		; $2a2b: $11 $7d $31 
	add		hl, de			; $2a2e: $19 
	inc		hl			; $2a2f: $23 
	ld		a, (hl)			; $2a30: $7e 
	pop		hl			; $2a31: $e1 
	and		a			; $2a32: $a7 
	ret		z			; $2a33: $c8 
	ld		(hl), a			; $2a34: $77 
	call		$2cb2			; $2a35: $cd $b2 $2c 
	ld		a, $ff			; $2a38: $3e $ff 
	ret					; $2a3a: $c9 
; end routine

; routine
	push		hl			; $2a3b: $e5 
	ld		a, (hl)			; $2a3c: $7e 
	ld		e, a			; $2a3d: $5f 
	ld		d, $00			; $2a3e: $16 $00 
	ld		l, a			; $2a40: $6f 
	ld		h, $00			; $2a41: $26 $00 
	sla		e			; $2a43: $cb $23 
	rl		d			; $2a45: $cb $12 
	sla		e			; $2a47: $cb $23 
	rl		d			; $2a49: $cb $12 
	add		hl, de			; $2a4b: $19 
	ld		de, $317d		; $2a4c: $11 $7d $31 
	add		hl, de			; $2a4f: $19 
	inc		hl			; $2a50: $23 
	inc		hl			; $2a51: $23 
	ld		a, (hl)			; $2a52: $7e 
	pop		hl			; $2a53: $e1 
	cp		$ff			; $2a54: $fe $ff 
	ret		z			; $2a56: $c8 
	and		a			; $2a57: $a7 
	ret		z			; $2a58: $c8 
	ld		(hl), a			; $2a59: $77 
	call		$2cb2			; $2a5a: $cd $b2 $2c 
	xor		a			; $2a5d: $af 
	ret					; $2a5e: $c9 
; end routine

; routine
	push		hl			; $2a5f: $e5 
	ld		a, l			; $2a60: $7d 
	add		$0c			; $2a61: $c6 $0c 
	ld		l, a			; $2a63: $6f 
	ld		a, (hl)			; $2a64: $7e 
	and		$3f			; $2a65: $e6 $3f 
	jr		z, +			; $2a67: $28 $17 
	ld		a, (hl)			; $2a69: $7e 
	dec		a			; $2a6a: $3d 
	ld		(hl), a			; $2a6b: $77 
	pop		hl			; $2a6c: $e1 
	ld		a, (hl)			; $2a6d: $7e 
	cp		$32			; $2a6e: $fe $32 
	jr		z, $06			; $2a70: $28 $06 
	cp		$08			; $2a72: $fe $08 
	jr		z, $02			; $2a74: $28 $02 
	jr		$05			; $2a76: $18 $05 
	ld		a, $01			; $2a78: $3e $01 
	ld		($dff0), a		; $2a7a: $ea $f0 $df 
	ld		a, $fe			; $2a7d: $3e $fe 
	ret					; $2a7f: $c9 

+	pop		hl			; $2a80: $e1 
	push		hl			; $2a81: $e5 
	ld		a, (hl)			; $2a82: $7e 
	ld		e, a			; $2a83: $5f 
	ld		d, $00			; $2a84: $16 $00 
	ld		l, a			; $2a86: $6f 
	ld		h, $00			; $2a87: $26 $00 
	sla		e			; $2a89: $cb $23 
	rl		d			; $2a8b: $cb $12 
	sla		e			; $2a8d: $cb $23 
	rl		d			; $2a8f: $cb $12 
	add		hl, de			; $2a91: $19 
	ld		de, $317d		; $2a92: $11 $7d $31 
	add		hl, de			; $2a95: $19 
	inc		hl			; $2a96: $23 
	inc		hl			; $2a97: $23 
	inc		hl			; $2a98: $23 
	ld		a, (hl)			; $2a99: $7e 
	pop		hl			; $2a9a: $e1 
	and		a			; $2a9b: $a7 
	ret		z			; $2a9c: $c8 
	ld		(hl), a			; $2a9d: $77 
	call		$2cb2			; $2a9e: $cd $b2 $2c 
	ld		a, $ff			; $2aa1: $3e $ff 
	ret					; $2aa3: $c9 
; end routine

; routine
	push		hl			; $2aa4: $e5 
	ld		a, l			; $2aa5: $7d 
	add		$0c			; $2aa6: $c6 $0c 
	ld		l, a			; $2aa8: $6f 
	ld		a, (hl)			; $2aa9: $7e 
	and		$3f			; $2aaa: $e6 $3f 
	jr		z, +			; $2aac: $28 $22 
	ld		a, (hl)			; $2aae: $7e 
	dec		a			; $2aaf: $3d 
	ld		(hl), a			; $2ab0: $77 
	pop		hl			; $2ab1: $e1 
	ld		a, (hl)			; $2ab2: $7e 
	cp		$1a			; $2ab3: $fe $1a 
	jr		z, $11			; $2ab5: $28 $11 
	cp		$61			; $2ab7: $fe $61 
	jr		z, $0d			; $2ab9: $28 $0d 
	cp		$60			; $2abb: $fe $60 
	jr		z, $02			; $2abd: $28 $02 
	jr		$0c			; $2abf: $18 $0c 
	ld		a, $01			; $2ac1: $3e $01 
	ld		($dff8), a		; $2ac3: $ea $f8 $df 
	jr		$05			; $2ac6: $18 $05 
	ld		a, $01			; $2ac8: $3e $01 
	ld		($dff0), a		; $2aca: $ea $f0 $df 
	ld		a, $fe			; $2acd: $3e $fe 
	ret					; $2acf: $c9 

+	pop		hl			; $2ad0: $e1 
	push		hl			; $2ad1: $e5 
	ld		a, (hl)			; $2ad2: $7e 
	cp		$60			; $2ad3: $fe $60 
	jr		nz, $03			; $2ad5: $20 $03 
	ld		($d007), a		; $2ad7: $ea $07 $d0 
	ld		a, (hl)			; $2ada: $7e 
	ld		e, a			; $2adb: $5f 
	ld		d, $00			; $2adc: $16 $00 
	ld		l, a			; $2ade: $6f 
	ld		h, $00			; $2adf: $26 $00 
	sla		e			; $2ae1: $cb $23 
	rl		d			; $2ae3: $cb $12 
	sla		e			; $2ae5: $cb $23 
	rl		d			; $2ae7: $cb $12 
	add		hl, de			; $2ae9: $19 
	ld		de, $317d		; $2aea: $11 $7d $31 
	add		hl, de			; $2aed: $19 
	inc		hl			; $2aee: $23 
	inc		hl			; $2aef: $23 
	inc		hl			; $2af0: $23 
	inc		hl			; $2af1: $23 
	ld		a, (hl)			; $2af2: $7e 
	pop		hl			; $2af3: $e1 
	and		a			; $2af4: $a7 
	ret		z			; $2af5: $c8 
	ld		(hl), a			; $2af6: $77 
	call		$2cb2			; $2af7: $cd $b2 $2c 
	ld		a, $ff			; $2afa: $3e $ff 
	ret					; $2afc: $c9 
; end routine

; routine
	push		hl			; $2afd: $e5 
	ld		a, (hl)			; $2afe: $7e 
	ld		e, a			; $2aff: $5f 
	ld		d, $00			; $2b00: $16 $00 
	ld		l, a			; $2b02: $6f 
	ld		h, $00			; $2b03: $26 $00 
	sla		e			; $2b05: $cb $23 
	rl		d			; $2b07: $cb $12 
	sla		e			; $2b09: $cb $23 
	rl		d			; $2b0b: $cb $12 
	add		hl, de			; $2b0d: $19 
	ld		de, $317d		; $2b0e: $11 $7d $31 
	add		hl, de			; $2b11: $19 
	inc		hl			; $2b12: $23 
	inc		hl			; $2b13: $23 
	inc		hl			; $2b14: $23 
	inc		hl			; $2b15: $23 
	ld		a, (hl)			; $2b16: $7e 
	pop		hl			; $2b17: $e1 
	and		a			; $2b18: $a7 
	ret		z			; $2b19: $c8 
	ld		(hl), a			; $2b1a: $77 
	call		$2cb2			; $2b1b: $cd $b2 $2c 
	ld		a, $ff			; $2b1e: $3e $ff 
	ret					; $2b20: $c9 
; end routine

; routine
	ld		hl, $d100		; $2b21: $21 $00 $d1 
	ld		a, (hl)			; $2b24: $7e 
	cp		$ff			; $2b25: $fe $ff 
	jr		z, $15			; $2b27: $28 $15 
	push		hl			; $2b29: $e5 
	ld		(hl), $27		; $2b2a: $36 $27 
	inc		hl			; $2b2c: $23 
	inc		hl			; $2b2d: $23 
	inc		hl			; $2b2e: $23 
	inc		hl			; $2b2f: $23 
	ld		(hl), $00		; $2b30: $36 $00 
	inc		hl			; $2b32: $23 
	inc		hl			; $2b33: $23 
	inc		hl			; $2b34: $23 
	inc		hl			; $2b35: $23 
	inc		hl			; $2b36: $23 
	ld		(hl), $00		; $2b37: $36 $00 
	inc		hl			; $2b39: $23 
	inc		hl			; $2b3a: $23 
	ld		(hl), $00		; $2b3b: $36 $00 
	pop		hl			; $2b3d: $e1 
	ld		a, l			; $2b3e: $7d 
	add		$10			; $2b3f: $c6 $10 
	ld		l, a			; $2b41: $6f 
	cp		$a0			; $2b42: $fe $a0 
	jr		c, -$22			; $2b44: $38 $de 
	ld		a, $27			; $2b46: $3e $27 
	ldh		($c0), a		; $2b48: $e0 $c0 
	xor		a			; $2b4a: $af 
	ldh		($c4), a		; $2b4b: $e0 $c4 
	ldh		($c7), a		; $2b4d: $e0 $c7 
	inc		a			; $2b4f: $3c 
	ld		($dff8), a		; $2b50: $ea $f8 $df 
	ret					; $2b53: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2b54: $f0 $c3 
	ld		c, a			; $2b56: $4f 
	ldh		a, ($a4)		; $2b57: $f0 $a4 
	add		c			; $2b59: $81 
	add		$04			; $2b5a: $c6 $04 
	ldh		($ae), a		; $2b5c: $e0 $ae 
	ld		c, a			; $2b5e: $4f 
	ldh		a, ($c5)		; $2b5f: $f0 $c5 
	bit		0, a			; $2b61: $cb $47 
	jr		$08			; $2b63: $18 $08 
	ldh		a, ($ca)		; $2b65: $f0 $ca 
	and		$70			; $2b67: $e6 $70 
	rrca					; $2b69: $0f 
	add		c			; $2b6a: $81 
	ldh		($ae), a		; $2b6b: $e0 $ae 
	ldh		a, ($c2)		; $2b6d: $f0 $c2 
	ldh		($ad), a		; $2b6f: $e0 $ad 
	call		$0153			; $2b71: $cd $53 $01 
	cp		$5f			; $2b74: $fe $5f 
	ret		c			; $2b76: $d8 
	cp		$f0			; $2b77: $fe $f0 
	ccf					; $2b79: $3f 
	ret					; $2b7a: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2b7b: $f0 $c3 
	ld		c, a			; $2b7d: $4f 
	ldh		a, ($a4)		; $2b7e: $f0 $a4 
	add		c			; $2b80: $81 
	ldh		($ae), a		; $2b81: $e0 $ae 
	ldh		a, ($c2)		; $2b83: $f0 $c2 
	ldh		($ad), a		; $2b85: $e0 $ad 
	call		$0153			; $2b87: $cd $53 $01 
	cp		$5f			; $2b8a: $fe $5f 
	ret		c			; $2b8c: $d8 
	cp		$f0			; $2b8d: $fe $f0 
	ccf					; $2b8f: $3f 
	ret					; $2b90: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2b91: $f0 $c3 
	ld		c, a			; $2b93: $4f 
	ldh		a, ($a4)		; $2b94: $f0 $a4 
	add		c			; $2b96: $81 
	add		$08			; $2b97: $c6 $08 
	ld		c, a			; $2b99: $4f 
	ldh		a, ($ca)		; $2b9a: $f0 $ca 
	and		$70			; $2b9c: $e6 $70 
	rrca					; $2b9e: $0f 
	add		c			; $2b9f: $81 
	sub		$08			; $2ba0: $d6 $08 
	ldh		($ae), a		; $2ba2: $e0 $ae 
	ldh		a, ($c2)		; $2ba4: $f0 $c2 
	ldh		($ad), a		; $2ba6: $e0 $ad 
	call		$0153			; $2ba8: $cd $53 $01 
	cp		$5f			; $2bab: $fe $5f 
	ret		c			; $2bad: $d8 
	cp		$f0			; $2bae: $fe $f0 
	ccf					; $2bb0: $3f 
	ret					; $2bb1: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2bb2: $f0 $c3 
	ld		c, a			; $2bb4: $4f 
	ldh		a, ($a4)		; $2bb5: $f0 $a4 
	add		c			; $2bb7: $81 
	add		$04			; $2bb8: $c6 $04 
	ldh		($ae), a		; $2bba: $e0 $ae 
	ld		c, a			; $2bbc: $4f 
	ldh		a, ($c5)		; $2bbd: $f0 $c5 
	bit		0, a			; $2bbf: $cb $47 
	jr		$08			; $2bc1: $18 $08 
	ldh		a, ($ca)		; $2bc3: $f0 $ca 
	and		$70			; $2bc5: $e6 $70 
	rrca					; $2bc7: $0f 
	add		c			; $2bc8: $81 
	ldh		($ae), a		; $2bc9: $e0 $ae 
	ldh		a, ($c2)		; $2bcb: $f0 $c2 
	add		$08			; $2bcd: $c6 $08 
	ldh		($ad), a		; $2bcf: $e0 $ad 
	call		$0153			; $2bd1: $cd $53 $01 
	cp		$5f			; $2bd4: $fe $5f 
	ret		c			; $2bd6: $d8 
	cp		$f0			; $2bd7: $fe $f0 
	ccf					; $2bd9: $3f 
	ret					; $2bda: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2bdb: $f0 $c3 
	ld		c, a			; $2bdd: $4f 
	ldh		a, ($a4)		; $2bde: $f0 $a4 
	add		c			; $2be0: $81 
	add		$03			; $2be1: $c6 $03 
	ldh		($ae), a		; $2be3: $e0 $ae 
	ldh		a, ($c2)		; $2be5: $f0 $c2 
	add		$08			; $2be7: $c6 $08 
	ldh		($ad), a		; $2be9: $e0 $ad 
	call		$0153			; $2beb: $cd $53 $01 
	cp		$5f			; $2bee: $fe $5f 
	ret		c			; $2bf0: $d8 
	cp		$f0			; $2bf1: $fe $f0 
	ccf					; $2bf3: $3f 
	ret					; $2bf4: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2bf5: $f0 $c3 
	ld		c, a			; $2bf7: $4f 
	ldh		a, ($a4)		; $2bf8: $f0 $a4 
	add		c			; $2bfa: $81 
	add		$05			; $2bfb: $c6 $05 
	ld		c, a			; $2bfd: $4f 
	ldh		a, ($ca)		; $2bfe: $f0 $ca 
	and		$70			; $2c00: $e6 $70 
	rrca					; $2c02: $0f 
	add		c			; $2c03: $81 
	sub		$08			; $2c04: $d6 $08 
	ldh		($ae), a		; $2c06: $e0 $ae 
	ldh		a, ($c2)		; $2c08: $f0 $c2 
	add		$08			; $2c0a: $c6 $08 
	ldh		($ad), a		; $2c0c: $e0 $ad 
	call		$0153			; $2c0e: $cd $53 $01 
	cp		$5f			; $2c11: $fe $5f 
	ret		c			; $2c13: $d8 
	cp		$f0			; $2c14: $fe $f0 
	ccf					; $2c16: $3f 
	ret					; $2c17: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2c18: $f0 $c3 
	ld		c, a			; $2c1a: $4f 
	ldh		a, ($a4)		; $2c1b: $f0 $a4 
	add		c			; $2c1d: $81 
	add		$04			; $2c1e: $c6 $04 
	ldh		($ae), a		; $2c20: $e0 $ae 
	ld		c, a			; $2c22: $4f 
	ldh		a, ($c5)		; $2c23: $f0 $c5 
	bit		0, a			; $2c25: $cb $47 
	jr		$08			; $2c27: $18 $08 
	ldh		a, ($ca)		; $2c29: $f0 $ca 
	and		$70			; $2c2b: $e6 $70 
	rrca					; $2c2d: $0f 
	add		c			; $2c2e: $81 
	ldh		($ae), a		; $2c2f: $e0 $ae 
	ldh		a, ($ca)		; $2c31: $f0 $ca 
	and		$07			; $2c33: $e6 $07 
	dec		a			; $2c35: $3d 
	swap		a			; $2c36: $cb $37 
	rrca					; $2c38: $0f 
	ld		c, a			; $2c39: $4f 
	ldh		a, ($c2)		; $2c3a: $f0 $c2 
	sub		c			; $2c3c: $91 
	ldh		($ad), a		; $2c3d: $e0 $ad 
	call		$0153			; $2c3f: $cd $53 $01 
	cp		$5f			; $2c42: $fe $5f 
	ret		c			; $2c44: $d8 
	cp		$f0			; $2c45: $fe $f0 
	ccf					; $2c47: $3f 
	ret					; $2c48: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2c49: $f0 $c3 
	ld		c, a			; $2c4b: $4f 
	ldh		a, ($a4)		; $2c4c: $f0 $a4 
	add		c			; $2c4e: $81 
	add		$03			; $2c4f: $c6 $03 
	ldh		($ae), a		; $2c51: $e0 $ae 
	ldh		a, ($ca)		; $2c53: $f0 $ca 
	and		$07			; $2c55: $e6 $07 
	dec		a			; $2c57: $3d 
	swap		a			; $2c58: $cb $37 
	rrca					; $2c5a: $0f 
	ld		c, a			; $2c5b: $4f 
	ldh		a, ($c2)		; $2c5c: $f0 $c2 
	sub		c			; $2c5e: $91 
	ldh		($ad), a		; $2c5f: $e0 $ad 
	call		$0153			; $2c61: $cd $53 $01 
	cp		$5f			; $2c64: $fe $5f 
	ret		c			; $2c66: $d8 
	cp		$f0			; $2c67: $fe $f0 
	ccf					; $2c69: $3f 
	ret					; $2c6a: $c9 
; end routine

; routine
	ldh		a, ($c3)		; $2c6b: $f0 $c3 
	ld		c, a			; $2c6d: $4f 
	ldh		a, ($a4)		; $2c6e: $f0 $a4 
	add		c			; $2c70: $81 
	add		$05			; $2c71: $c6 $05 
	ld		c, a			; $2c73: $4f 
	ldh		a, ($ca)		; $2c74: $f0 $ca 
	and		$70			; $2c76: $e6 $70 
	rrca					; $2c78: $0f 
	sub		c			; $2c79: $91 
	sub		$08			; $2c7a: $d6 $08 
	ldh		($ae), a		; $2c7c: $e0 $ae 
	ldh		a, ($ca)		; $2c7e: $f0 $ca 
	and		$07			; $2c80: $e6 $07 
	dec		a			; $2c82: $3d 
	swap		a			; $2c83: $cb $37 
	rrca					; $2c85: $0f 
	ld		c, a			; $2c86: $4f 
	ldh		a, ($c2)		; $2c87: $f0 $c2 
	sub		c			; $2c89: $91 
	ldh		($ad), a		; $2c8a: $e0 $ad 
	call		$0153			; $2c8c: $cd $53 $01 
	cp		$5f			; $2c8f: $fe $5f 
	ret		c			; $2c91: $d8 
	cp		$f0			; $2c92: $fe $f0 
	ccf					; $2c94: $3f 
	ret					; $2c95: $c9 
; end routine

; routine
	ld		a, b			; $2c96: $78 
	and		a			; $2c97: $a7 
	ret		z			; $2c98: $c8 
	ldh		a, ($c3)		; $2c99: $f0 $c3 
	sub		b			; $2c9b: $90 
	ldh		($c3), a		; $2c9c: $e0 $c3 
	push		hl			; $2c9e: $e5 
	push		de			; $2c9f: $d5 
	ld		hl, $d103		; $2ca0: $21 $03 $d1 
	ld		de, $0010		; $2ca3: $11 $10 $00 
	ld		a, (hl)			; $2ca6: $7e 
	sub		b			; $2ca7: $90 
	ld		(hl), a			; $2ca8: $77 
	add		hl, de			; $2ca9: $19 
	ld		a, l			; $2caa: $7d 
	cp		$a0			; $2cab: $fe $a0 
	jr		c, -$09			; $2cad: $38 $f7 
	pop		de			; $2caf: $d1 
	pop		hl			; $2cb0: $e1 
	ret					; $2cb1: $c9 
; end routine

; routine
	push		hl			; $2cb2: $e5 
	ld		a, (hl)			; $2cb3: $7e 
	ld		d, $00			; $2cb4: $16 $00 
	ld		e, a			; $2cb6: $5f 
	rlca					; $2cb7: $07 
	add		e			; $2cb8: $83 
	rl		d			; $2cb9: $cb $12 
	ld		e, a			; $2cbb: $5f 
	ld		hl, $336c		; $2cbc: $21 $6c $33 
	add		hl, de			; $2cbf: $19 
	ldi		a, (hl)			; $2cc0: $2a 
	ld		b, a			; $2cc1: $47 
	ldi		a, (hl)			; $2cc2: $2a 
	ld		d, a			; $2cc3: $57 
	ld		a, (hl)			; $2cc4: $7e 
	pop		hl			; $2cc5: $e1 
	inc		hl			; $2cc6: $23 
	inc		hl			; $2cc7: $23 
	inc		hl			; $2cc8: $23 
	inc		hl			; $2cc9: $23 
	ld		(hl), $00		; $2cca: $36 $00 
	inc		hl			; $2ccc: $23 
	inc		hl			; $2ccd: $23 
	inc		hl			; $2cce: $23 
	ld		(hl), b			; $2ccf: $70 
	inc		hl			; $2cd0: $23 
	ld		(hl), $00		; $2cd1: $36 $00 
	inc		hl			; $2cd3: $23 
	ld		(hl), $00		; $2cd4: $36 $00 
	inc		hl			; $2cd6: $23 
	ld		(hl), d			; $2cd7: $72 
	inc		hl			; $2cd8: $23 
	inc		hl			; $2cd9: $23 
	ld		(hl), a			; $2cda: $77 
	ret					; $2cdb: $c9 
; end routine

; routine
	swap		a			; $2cdc: $cb $37 
	ld		hl, $d100		; $2cde: $21 $00 $d1 
	ld		l, a			; $2ce1: $6f 
	ld		de, $ffc0		; $2ce2: $11 $c0 $ff 
	ld		b, $0d			; $2ce5: $06 $0d 
	ldi		a, (hl)			; $2ce7: $2a 
	ld		(de), a			; $2ce8: $12 
	inc		de			; $2ce9: $13 
	dec		b			; $2cea: $05 
	jr		nz, -$06			; $2ceb: $20 $fa 
	ret					; $2ced: $c9 
; end routine

; routine
	swap		a			; $2cee: $cb $37 
	ld		hl, $d100		; $2cf0: $21 $00 $d1 
	ld		l, a			; $2cf3: $6f 
	ld		de, $ffc0		; $2cf4: $11 $c0 $ff 
	ld		b, $0d			; $2cf7: $06 $0d 
	ld		a, (de)			; $2cf9: $1a 
	ldi		(hl), a			; $2cfa: $22 
	inc		de			; $2cfb: $13 
	dec		b			; $2cfc: $05 
	jr		nz, -$06			; $2cfd: $20 $fa 
	ret					; $2cff: $c9 
; end routine

; data i suppose
; entity data!!!
.incbin "data1.bin"
; end data

; routine
; clears 20h bytes in wram
; and 2Ah bytes in nother wram place
; looks  like it initiallizes the level vars??
; sets time remaining and other stuff, so!!
INIT_GAME_VARS:
	; clear $20 bytes starting here in wram
	; this is some oam
	ld		hl, $c030		; $3d11: $21 $30 $c0 
	ld		b, $20			; $3d14: $06 $20 
	xor		a			; $3d16: $af 
-	ldi		(hl), a			; $3d17: $22 
	dec		b			; $3d18: $05 
	jr		nz, -			; $3d19: $20 $fc 

	; set 3 vars starting here in wram
	; reset time remaining divider
	ld		hl, time_remaining_divider	; $3d1b: $21 $00 $da 
	ld		a, $28			; $3d1e: $3e $28 
	ldi		(hl), a			; $3d20: $22 
	; set the time remaining to 0400
	xor		a			; $3d21: $af 
	ldi		(hl), a			; $3d22: $22 
	ld		a, $04			; $3d23: $3e $04 
	ldi		(hl), a			; $3d25: $22 

	; display the time remaining
	call		DISPLAY_TIME_REMAINING	; $3d26: $cd $75 $3d 

	; set 4 more vars
	ld		a, $20			; $3d29: $3e $20 
	ldi		(hl), a			; $3d2b: $22 
	ldi		(hl), a			; $3d2c: $22 
	ldi		(hl), a			; $3d2d: $22 
	ldi		(hl), a			; $3d2e: $22 
	; and 4 more
	ld		a, $f6			; $3d2f: $3e $f6 
	ldi		(hl), a			; $3d31: $22 
	ldi		(hl), a			; $3d32: $22 
	ldi		(hl), a			; $3d33: $22 
	ldi		(hl), a			; $3d34: $22 
	; and another
	ld		a, $30			; $3d35: $3e $30 
	ldi		(hl), a			; $3d37: $22 

	; and clear 9 more
	xor		a			; $3d38: $af 
	ld		b, $09			; $3d39: $06 $09 
-	ldi		(hl), a			; $3d3b: $22 
	dec		b			; $3d3c: $05 
	jr		nz, -			; $3d3d: $20 $fc 

	; set the life counter
	ld		a, $02			; $3d3f: $3e $02 
	ldi		(hl), a			; $3d41: $22 
	; set 10 more
	dec		a			; $3d42: $3d 
	ldi		(hl), a			; $3d43: $22 
	xor		a			; $3d44: $af 
	ldi		(hl), a			; $3d45: $22 
	ldi		(hl), a			; $3d46: $22 
	ldi		(hl), a			; $3d47: $22 
	ldi		(hl), a			; $3d48: $22 
	ld		a, $40			; $3d49: $3e $40 
	ldi		(hl), a			; $3d4b: $22 
	xor		a			; $3d4c: $af 
	ldi		(hl), a			; $3d4d: $22 
	ldi		(hl), a			; $3d4e: $22 
	ldi		(hl), a			; $3d4f: $22 
	ld		a, $40			; $3d50: $3e $40 
	ldi		(hl), a			; $3d52: $22 

	; clear 8 more
	xor		a			; $3d53: $af 
	ld		b, $08			; $3d54: $06 $08 
-	ldi		(hl), a			; $3d56: $22 
	dec		b			; $3d57: $05 
	jr		nz, -			; $3d58: $20 $fc 

	; and 2 more
	ld		a, $04			; $3d5a: $3e $04 
	ldi		(hl), a			; $3d5c: $22 
	ld		a, $11			; $3d5d: $3e $11 
	ld		(hl), a			; $3d5f: $77 

	; done
	ret					; $3d60: $c9 
; end routine

; routine
; displayes time remaining, only if it should
HANDLE_DISPLAY_TIME:
	; copy of the state?????
	; so not in game state then leave???
	ld		a, ($c0a4)		; $3d61: $fa $a4 $c0 
	and		a			; $3d64: $a7 
	ret		nz			; $3d65: $c0 
	; only if in any of the game play states
	ldh		a, (r_state)		; $3d66: $f0 $b3 
	cp		$12			; $3d68: $fe $12 
	ret		nc			; $3d6a: $d0 
	; this checks to see if the time remaining divider is at theright position
	ld		a, ($da00)		; $3d6b: $fa $00 $da 
	cp		$28			; $3d6e: $fe $28 
	ret		nz			; $3d70: $c0 
	call		DISPLAY_TIME_REMAINING	; $3d71: $cd $75 $3d 
	ret					; $3d74: $c9 
; end routine

; routine
; is this copying the time????
; yes this routine displayes the time
DISPLAY_TIME_REMAINING:
	; DISPLAY THE RIGHTMOST TIME DIGIT
	; point to a place in map0
	ld		de, $9833		; $3d75: $11 $33 $98 
	; grab a tile from wram
	ld		a, ($da01)		; $3d78: $fa $01 $da 
	; save it
	ld		b, a			; $3d7b: $47 
	; and mask it
	and		$0f			; $3d7c: $e6 $0f 
	; copy that masked tileno into map0
	ld		(de), a			; $3d7e: $12 

	; DISPLAY THE MIDDLE TIME DIGIT
	; and now the lower place in map0
	dec		e			; $3d7f: $1d 
	; and this time git the upper bits
	ld		a, b			; $3d80: $78 
	and		$f0			; $3d81: $e6 $f0 
	swap		a			; $3d83: $cb $37 
	; and copy that there
	ld		(de), a			; $3d85: $12 
	
	; DISPLAY THE LEFTMOST TIME DIGIT
	; and now yet the lower place
	dec		e			; $3d86: $1d 
	; but grab the lower bytes of this place instead
	ld		a, ($da02)		; $3d87: $fa $02 $da 
	and		$0f			; $3d8a: $e6 $0f 
	; put the tile in place
	ld		(de), a			; $3d8c: $12 

	; done
	ret					; $3d8d: $c9 
; end routine

; routine
ENTER_BONUS:
	ld		hl, $dfe8		; $3d8e: $21 $e8 $df 
	ld		a, $09			; $3d91: $3e $09 
	ld		(hl), a			; $3d93: $77 
	xor		a			; $3d94: $af 
	ldh		($40), a		; $3d95: $e0 $40 
	ldh		($a4), a		; $3d97: $e0 $a4 
	ld		hl, $c000		; $3d99: $21 $00 $c0 
	ld		b, $a0			; $3d9c: $06 $a0 
	ldi		(hl), a			; $3d9e: $22 
	dec		b			; $3d9f: $05 
	jr		nz, -$04			; $3da0: $20 $fc 
	ld		hl, $9800		; $3da2: $21 $00 $98 
	ld		b, $ff			; $3da5: $06 $ff 
	ld		c, $03			; $3da7: $0e $03 
	ld		a, $2c			; $3da9: $3e $2c 
	ldi		(hl), a			; $3dab: $22 
	dec		b			; $3dac: $05 
	jr		nz, -$04			; $3dad: $20 $fc 
	ld		b, $ff			; $3daf: $06 $ff 
	dec		c			; $3db1: $0d 
	jr		nz, -$09			; $3db2: $20 $f7 
	ld		de, $988b		; $3db4: $11 $8b $98 
	ld		a, ($da15)		; $3db7: $fa $15 $da 
	ld		b, a			; $3dba: $47 
	and		$0f			; $3dbb: $e6 $0f 
	ld		(de), a			; $3dbd: $12 
	dec		e			; $3dbe: $1d 
	ld		a, b			; $3dbf: $78 
	and		$f0			; $3dc0: $e6 $f0 
	swap		a			; $3dc2: $cb $37 
	ld		(de), a			; $3dc4: $12 
	ld		a, $83			; $3dc5: $3e $83 
	ldh		($40), a		; $3dc7: $e0 $40 
	ld		a, $13			; $3dc9: $3e $13 
	ldh		($b3), a		; $3dcb: $e0 $b3 
	ret					; $3dcd: $c9 
; end routine

; routine
; BONUS IDLE 0
BONUS_IDLE_0:
	xor		a			; $3dce: $af 
	ldh		($40), a		; $3dcf: $e0 $40 
	ld		hl, $9800		; $3dd1: $21 $00 $98 
	ld		a, $f5			; $3dd4: $3e $f5 
	ldi		(hl), a			; $3dd6: $22 
	ld		b, $12			; $3dd7: $06 $12 
	ld		a, $9f			; $3dd9: $3e $9f 
	ldi		(hl), a			; $3ddb: $22 
	dec		b			; $3ddc: $05 
	jr		nz, -$04			; $3ddd: $20 $fc 
	ld		a, $fc			; $3ddf: $3e $fc 
	ld		(hl), a			; $3de1: $77 
	ld		de, $0020		; $3de2: $11 $20 $00 
	ld		l, e			; $3de5: $6b 
	ld		b, $10			; $3de6: $06 $10 
	ld		c, $02			; $3de8: $0e $02 
	ld		a, $f8			; $3dea: $3e $f8 
	ld		(hl), a			; $3dec: $77 
	add		hl, de			; $3ded: $19 
	dec		b			; $3dee: $05 
	jr		nz, -$05			; $3def: $20 $fb 
	ld		l, $33			; $3df1: $2e $33 
	dec		h			; $3df3: $25 
	dec		h			; $3df4: $25 
	ld		b, $10			; $3df5: $06 $10 
	dec		c			; $3df7: $0d 
	jr		nz, -$0e			; $3df8: $20 $f2 
	ld		hl, $9a20		; $3dfa: $21 $20 $9a 
	ld		a, $ff			; $3dfd: $3e $ff 
	ldi		(hl), a			; $3dff: $22 
	ld		b, $12			; $3e00: $06 $12 
	ld		a, $9f			; $3e02: $3e $9f 
	ldi		(hl), a			; $3e04: $22 
	dec		b			; $3e05: $05 
	jr		nz, -$04			; $3e06: $20 $fc 
	ld		a, $e9			; $3e08: $3e $e9 
	ld		(hl), a			; $3e0a: $77 
	ld		hl, $9845		; $3e0b: $21 $45 $98 
	ld		a, $0b			; $3e0e: $3e $0b 
	ldi		(hl), a			; $3e10: $22 
	ld		a, $18			; $3e11: $3e $18 
	ldi		(hl), a			; $3e13: $22 
	dec		a			; $3e14: $3d 
	ldi		(hl), a			; $3e15: $22 
	ld		a, $1e			; $3e16: $3e $1e 
	ldi		(hl), a			; $3e18: $22 
	ld		a, $1c			; $3e19: $3e $1c 
	ldi		(hl), a			; $3e1b: $22 
	inc		l			; $3e1c: $2c 
	ld		a, $10			; $3e1d: $3e $10 
	ldi		(hl), a			; $3e1f: $22 
	ld		a, $0a			; $3e20: $3e $0a 
	ldi		(hl), a			; $3e22: $22 
	ld		a, $16			; $3e23: $3e $16 
	ldi		(hl), a			; $3e25: $22 
	ld		a, $0e			; $3e26: $3e $0e 
	ld		(hl), a			; $3e28: $77 
	ld		hl, $9887		; $3e29: $21 $87 $98 
	ld		a, $e4			; $3e2c: $3e $e4 
	ldi		(hl), a			; $3e2e: $22 
	inc		l			; $3e2f: $2c 
	ld		a, $2b			; $3e30: $3e $2b 
	ld		(hl), a			; $3e32: $77 
	ld		l, $e1			; $3e33: $2e $e1 
	ld		a, $2d			; $3e35: $3e $2d 
	ld		b, $12			; $3e37: $06 $12 
	ldi		(hl), a			; $3e39: $22 
	dec		b			; $3e3a: $05 
	jr		nz, -$04			; $3e3b: $20 $fc 
	ld		l, $d1			; $3e3d: $2e $d1 
	ld		a, $2b			; $3e3f: $3e $2b 
	ldi		(hl), a			; $3e41: $22 
	ld		l, $41			; $3e42: $2e $41 
	inc		h			; $3e44: $24 
	ld		a, $2d			; $3e45: $3e $2d 
	ld		b, $12			; $3e47: $06 $12 
	ldi		(hl), a			; $3e49: $22 
	dec		b			; $3e4a: $05 
	jr		nz, -$04			; $3e4b: $20 $fc 
	ld		l, $31			; $3e4d: $2e $31 
	ld		a, $2b			; $3e4f: $3e $2b 
	ldi		(hl), a			; $3e51: $22 
	ld		l, $a1			; $3e52: $2e $a1 
	ld		a, $2d			; $3e54: $3e $2d 
	ld		b, $12			; $3e56: $06 $12 
	ldi		(hl), a			; $3e58: $22 
	dec		b			; $3e59: $05 
	jr		nz, -$04			; $3e5a: $20 $fc 
	ld		l, $91			; $3e5c: $2e $91 
	ld		a, $2b			; $3e5e: $3e $2b 
	ldi		(hl), a			; $3e60: $22 
	ld		l, $01			; $3e61: $2e $01 
	inc		h			; $3e63: $24 
	ld		a, $2d			; $3e64: $3e $2d 
	ld		b, $12			; $3e66: $06 $12 
	ldi		(hl), a			; $3e68: $22 
	dec		b			; $3e69: $05 
	jr		nz, -$04			; $3e6a: $20 $fc 
	ld		l, $f1			; $3e6c: $2e $f1 
	dec		h			; $3e6e: $25 
	ld		a, $2b			; $3e6f: $3e $2b 
	ldi		(hl), a			; $3e71: $22 
	nop					; $3e72: $00 
	ld		bc, $e502		; $3e73: $01 $02 $e5 
	inc		bc			; $3e76: $03 
	ld		bc, $e502		; $3e77: $01 $02 $e5 
	ld		de, $3e72		; $3e7a: $11 $72 $3e 
	ldh		a, ($04)		; $3e7d: $f0 $04 
	and		$03			; $3e7f: $e6 $03 
	inc		a			; $3e81: $3c 
	inc		de			; $3e82: $13 
	dec		a			; $3e83: $3d 
	jr		nz, -$04			; $3e84: $20 $fc 
	ld		hl, $98d2		; $3e86: $21 $d2 $98 
	ld		bc, $0060		; $3e89: $01 $60 $00 
	ld		a, (de)			; $3e8c: $1a 
	ld		(hl), a			; $3e8d: $77 
	inc		de			; $3e8e: $13 
	add		hl, bc			; $3e8f: $09 
	ld		a, l			; $3e90: $7d 
	cp		$52			; $3e91: $fe $52 
	jr		nz, -$09			; $3e93: $20 $f7 
	ld		a, $83			; $3e95: $3e $83 
	ldh		($40), a		; $3e97: $e0 $40 
	ld		a, $14			; $3e99: $3e $14 
	ldh		($b3), a		; $3e9b: $e0 $b3 
	ret					; $3e9d: $c9 
; end routine

; routine
BONUS_IDLE_3:
	ld		bc, $0020		; $3e9e: $01 $20 $00 
	ld		de, $da23		; $3ea1: $11 $23 $da 
	ld		a, ($da18)		; $3ea4: $fa $18 $da 
	ld		h, a			; $3ea7: $67 
	ld		a, ($da19)		; $3ea8: $fa $19 $da 
	ld		l, a			; $3eab: $6f 
	ld		a, (de)			; $3eac: $1a 
	ld		(hl), a			; $3ead: $77 
	inc		de			; $3eae: $13 
	add		hl, bc			; $3eaf: $09 
	ld		a, ($da28)		; $3eb0: $fa $28 $da 
	dec		a			; $3eb3: $3d 
	ld		($da28), a		; $3eb4: $ea $28 $da 
	jr		nz, -$0d			; $3eb7: $20 $f3 
	ld		a, $04			; $3eb9: $3e $04 
	ld		($da28), a		; $3ebb: $ea $28 $da 
	ld		a, ($da29)		; $3ebe: $fa $29 $da 
	dec		a			; $3ec1: $3d 
	ld		($da29), a		; $3ec2: $ea $29 $da 
	jr		nz, -$26			; $3ec5: $20 $da 
	ld		a, $11			; $3ec7: $3e $11 
	ld		($da29), a		; $3ec9: $ea $29 $da 
	ld		a, $15			; $3ecc: $3e $15 
	ldh		($b3), a		; $3ece: $e0 $b3 
	ret					; $3ed0: $c9 
; end routine

	ldh		a, ($ad)		; $3ed1: $f0 $ad 
	sub		$10			; $3ed3: $d6 $10 
	srl		a			; $3ed5: $cb $3f 
	srl		a			; $3ed7: $cb $3f 
	srl		a			; $3ed9: $cb $3f 
	ld		de, $0000		; $3edb: $11 $00 $00 
	ld		e, a			; $3ede: $5f 
	ld		hl, $9800		; $3edf: $21 $00 $98 
	ld		b, $20			; $3ee2: $06 $20 
	add		hl, de			; $3ee4: $19 
	dec		b			; $3ee5: $05 
	jr		nz, -$04			; $3ee6: $20 $fc 
	ldh		a, ($ae)		; $3ee8: $f0 $ae 
	sub		$08			; $3eea: $d6 $08 
	srl		a			; $3eec: $cb $3f 
	srl		a			; $3eee: $cb $3f 
	srl		a			; $3ef0: $cb $3f 
	ld		de, $0000		; $3ef2: $11 $00 $00 
	ld		e, a			; $3ef5: $5f 
	add		hl, de			; $3ef6: $19 
	ld		a, h			; $3ef7: $7c 
	ldh		($b0), a		; $3ef8: $e0 $b0 
	ld		a, l			; $3efa: $7d 
	ldh		($af), a		; $3efb: $e0 $af 
	ret					; $3efd: $c9 

; routine
; takes coin address on af(low) and b0(high)
; has somethin to do with putting hit blocks and coins in their right place?
; is this ALIGN TO GRID?
; that would explain the division!!!
ALIGN_TO_GRID:
	; put the address on de
	ldh		a, ($b0)		; $3efe: $f0 $b0 
	ld		d, a			; $3f00: $57 
	ldh		a, ($af)		; $3f01: $f0 $af 
	ld		e, a			; $3f03: $5f 
	; divid by 2^4=16?
	ld		b, $04			; $3f04: $06 $04 
-	rr		d			; $3f06: $cb $1a 
	rr		e			; $3f08: $cb $1b 
	dec		b			; $3f0a: $05 
	jr		nz, -			; $3f0b: $20 $f9 
	; what kinda math is this?
	; and what are registers ad, af, and ae?
	; apparently it puts the results there
	ld		a, e			; $3f0d: $7b 
	sub		$84			; $3f0e: $d6 $84 
	and		$fe			; $3f10: $e6 $fe 
	rlca					; $3f12: $07 
	rlca					; $3f13: $07 
	add		$08			; $3f14: $c6 $08 
	ldh		($ad), a		; $3f16: $e0 $ad 
	ldh		a, ($af)		; $3f18: $f0 $af 
	and		$1f			; $3f1a: $e6 $1f 
	rla					; $3f1c: $17 
	rla					; $3f1d: $17 
	rla					; $3f1e: $17 
	add		$08			; $3f1f: $c6 $08 
	ldh		($ae), a		; $3f21: $e0 $ae 
	ret					; $3f23: $c9 
; end routine

; routine
; wraps drawing the high score
HANDLE_SCORE_DRAW_REQUEST:
	; update requested?
	ldh		a, (r_update_score)		; $3f24: $f0 $b1 
	and		a			; $3f26: $a7 
	ret		z			; $3f27: $c8 
	; get past this mysterious var
	ld		a, ($c0e2)		; $3f28: $fa $e2 $c0 
	and		a			; $3f2b: $a7 
	ret		nz			; $3f2c: $c0 
	; and this one...??
	ldh		a, ($ea)		; $3f2d: $f0 $ea 
	cp		$02			; $3f2f: $fe $02 
	ret		z			; $3f31: $c8 
	; point to the top of the score, and the score place in video mem
	ld		de, (score + 2)		; $3f32: $11 $a2 $c0 
	ld		hl, $9820		; $3f35: $21 $20 $98 

; routine
; de points to a var in wram, used as control var
; hl points to map memory
; i dont know what this does
; its a maze
; but it looks like it copies some stuff into tile memory
; 3 bytes
; according to some wram vars
; ok.. so it just draws the high score
; it still looks like a mess, and it was hard to follow
; but now i basically know what it does
DRAW_HIGH_SCORE:
	; reset the score update var
	xor		a			; $3f38: $af 
	ldh		(r_update_score), a	; $3f39: $e0 $b1 
	; c is 3
	ld		c, $03			; $3f3b: $0e $03 

	; grab wram var
-	ld		a, (de)			; $3f3d: $1a 
	; bc = WRAMVAR+03
	ld		b, a			; $3f3e: $47 
	; get the top bits of the var
	swap		a			; $3f3f: $cb $37 
	and		$0f			; $3f41: $e6 $0f 
	; check em
	jr		nz, +			; $3f43: $20 $28 

	; 0? heres ur place:
	; grab that cleared hram var
	ldh		a, ($b1)		; $3f45: $f0 $b1 
	and		a			; $3f47: $a7 
	ld		a, $00			; $3f48: $3e $00 
	jr		nz, ++			; $3f4a: $20 $02 
	; hram var is 0:
	ld		a, $2c			; $3f4c: $3e $2c 
	; skip checking the hram var if the wram var is 0
	; (after jumping back from below)
	; do this if wram was not 0, or both were 0
	; so basically, do this if wram var no matter what!
	; but otherwise, only do it if it hasnt been done yet
	; but when we do it, somethin differents gonna be on a accordingly
	; and anyway, put it on map memory
--
++	ldi		(hl), a			; $3f4e: $22 
	; and grab the bottom bits of the original wram var
	ld		a, b			; $3f4f: $78 
	and		$0f			; $3f50: $e6 $0f 
	; not 0? act like hram var isnt 0
	jr		nz, ++			; $3f52: $20 $21 
	; otherwise, load the hram var again
	ldh		a, ($b1)		; $3f54: $f0 $b1 
	and		a			; $3f56: $a7 
	ld		a, $00			; $3f57: $3e $00 
	; and if its not 0, skip ahead, without setting it tho
	jr		nz, +++			; $3f59: $20 $09 
	; otherwise, if c is 1, skip ahead
	ld		a, $01			; $3f5b: $3e $01 
	cp		c			; $3f5d: $b9 
	ld		a, $00			; $3f5e: $3e $00 
	jr		z, +++			; $3f60: $28 $02 
	; otherwise, get this tile ready
	ld		a, $2c			; $3f62: $3e $2c 
	; do this no matter what cnofiguration
	; and copy another tile onto map data accordingly
---
+++	ldi		(hl), a			; $3f64: $22 
	; next (down) wram var
	dec		e			; $3f65: $1d 
	; countdown
	dec		c			; $3f66: $0d 
	; keep looping for the count of 3
	jr		nz, -			; $3f67: $20 $d4 
	
	; and finally
	xor		a			; $3f69: $af 
	; empy that hram var
	ldh		($b1), a		; $3f6a: $e0 $b1 
	; and leave
	ret					; $3f6c: $c9 

	; do this thing, if either wram var is not 0
	; or the hram var is not 0
	; and it just, sets the hram var
	; not 0? heres ur place
+	push		af			; $3f6d: $f5 
	ld		a, $01			; $3f6e: $3e $01 
	ldh		($b1), a		; $3f70: $e0 $b1 
	pop		af			; $3f72: $f1 
	jr		--			; $3f73: $18 $d9 

	; that hram var is not 0:
++	push		af			; $3f75: $f5 
	ld		a, $01			; $3f76: $3e $01 
	ldh		($b1), a		; $3f78: $e0 $b1 
	pop		af			; $3f7a: $f1 
	jr		---			; $3f7b: $18 $e7 
; end routine

; routine to copy into hram
; this copies oam from wram to oam
HRAM_ROUTINE_00:
	; initiate dma transfer
	ld		a, $c0			; HRAM_ROUTINE_00: $3e $c0 
	ldh		(R_DMA), a		; $3f7f: $e0 $46 
	ld		a, $28			; $3f81: $3e $28 
	; wait a bit
-	dec		a			; $3f83: $3d 
	jr		nz, -			; $3f84: $20 $fd 
	ret					; $3f86: $c9 
; end routine

; top two rows of game screen map
HUD_MAP:
.incbin "hud.map"
HUD_MAP_END:

; the rest of this is some kind of data
.incbin "data7.bin"
; end data

.bank 1 slot 1
.org $0

; data
; i dont know what it is ? ?
.incbin "data2.bin"
; data end

; routine
ROUTINE_2E:
	ldh		a, ($ac)		; $4fb2: $f0 $ac 
	and		$01			; $4fb4: $e6 $01 
	ret		nz			; $4fb6: $c0 
	ld		a, ($c0d2)		; $4fb7: $fa $d2 $c0 
	cp		$07			; $4fba: $fe $07 
	jr		c, $0d			; $4fbc: $38 $0d 
	ldh		a, ($a4)		; $4fbe: $f0 $a4 
	and		$0c			; $4fc0: $e6 $0c 
	jr		nz, $07			; $4fc2: $20 $07 
	ldh		a, ($a4)		; $4fc4: $f0 $a4 
	and		$fc			; $4fc6: $e6 $fc 
	ldh		($a4), a		; $4fc8: $e0 $a4 
	ret					; $4fca: $c9 

	ldh		a, ($a4)		; $4fcb: $f0 $a4 
	inc		a			; $4fcd: $3c 
	ldh		($a4), a		; $4fce: $e0 $a4 
	ld		b, $01			; $4fd0: $06 $01 
	call		$1e9b			; $4fd2: $cd $9b $1e 
	call		$2c96			; $4fd5: $cd $96 $2c 
	ld		hl, $c202		; $4fd8: $21 $02 $c2 
	dec		(hl)			; $4fdb: $35 
	ld		a, (hl)			; $4fdc: $7e 
	and		a			; $4fdd: $a7 
	jr		nz, $02			; $4fde: $20 $02 
	ld		(hl), $f0		; $4fe0: $36 $f0 
	ld		c, $08			; $4fe2: $0e $08 
	call		$50cc			; $4fe4: $cd $cc $50 
	ld		hl, $c202		; $4fe7: $21 $02 $c2 
	inc		(hl)			; $4fea: $34 
	ret					; $4feb: $c9 
; end routine

; routine
	ldh		a, ($80)		; $4fec: $f0 $80 
	bit		6, a			; $4fee: $cb $77 
	jr		nz, $42			; $4ff0: $20 $42 
	bit		7, a			; $4ff2: $cb $7f 
	jr		nz, $2c			; $4ff4: $20 $2c 
	ldh		a, ($80)		; $4ff6: $f0 $80 
	bit		4, a			; $4ff8: $cb $67 
	jr		nz, $18			; $4ffa: $20 $18 
	bit		5, a			; $4ffc: $cb $6f 
	ret		z			; $4ffe: $c8 
	ld		c, $fa			; $4fff: $0e $fa 
	call		$50cc			; $5001: $cd $cc $50 
	ld		hl, $c202		; $5004: $21 $02 $c2 
	ld		a, (hl)			; $5007: $7e 
	cp		$10			; $5008: $fe $10 
	ret		c			; $500a: $d8 
	dec		(hl)			; $500b: $35 
	ld		a, ($c0d2)		; $500c: $fa $d2 $c0 
	cp		$07			; $500f: $fe $07 
	ret		nc			; $5011: $d0 
	dec		(hl)			; $5012: $35 
	ret					; $5013: $c9 
	ld		c, $08			; $5014: $0e $08 
	call		$50cc			; $5016: $cd $cc $50 
	ld		hl, $c202		; $5019: $21 $02 $c2 
	ld		a, (hl)			; $501c: $7e 
	cp		$a0			; $501d: $fe $a0 
	ret		nc			; $501f: $d0 
	inc		(hl)			; $5020: $34 
	ret					; $5021: $c9 

	call		$5089			; $5022: $cd $89 $50 
	cp		$ff			; $5025: $fe $ff 
	jr		z, -$33			; $5027: $28 $cd 
	ld		hl, $c201		; $5029: $21 $01 $c2 
	ld		a, (hl)			; $502c: $7e 
	cp		$94			; $502d: $fe $94 
	jr		nc, -$3b			; $502f: $30 $c5 
	inc		(hl)			; $5031: $34 
	jr		-$3e			; $5032: $18 $c2 
	call		$5046			; $5034: $cd $46 $50 
	cp		$ff			; $5037: $fe $ff 
	jr		z, -$45			; $5039: $28 $bb 
	ld		hl, $c201		; $503b: $21 $01 $c2 
	ld		a, (hl)			; $503e: $7e 
	cp		$30			; $503f: $fe $30 
	jr		c, -$4d			; $5041: $38 $b3 
	dec		(hl)			; $5043: $35 
	jr		-$50			; $5044: $18 $b0 
	ld		hl, $c201		; $5046: $21 $01 $c2 
	ldh		a, ($99)		; $5049: $f0 $99 
	ld		b, $fd			; $504b: $06 $fd 
	and		a			; $504d: $a7 
	jr		z, $02			; $504e: $28 $02 
	ld		b, $fc			; $5050: $06 $fc 
	ldi		a, (hl)			; $5052: $2a 
	add		b			; $5053: $80 
	ldh		($ad), a		; $5054: $e0 $ad 
	ldh		a, ($a4)		; $5056: $f0 $a4 
	ld		b, (hl)			; $5058: $46 
	add		b			; $5059: $80 
	add		$02			; $505a: $c6 $02 
	ldh		($ae), a		; $505c: $e0 $ae 
	call		$0153			; $505e: $cd $53 $01 
	cp		$60			; $5061: $fe $60 
	jr		nc, $0c			; $5063: $30 $0c 
	ldh		a, ($ae)		; $5065: $f0 $ae 
	add		$fa			; $5067: $c6 $fa 
	ldh		($ae), a		; $5069: $e0 $ae 
	call		$0153			; $506b: $cd $53 $01 
	cp		$60			; $506e: $fe $60 
	ret		c			; $5070: $d8 
	cp		$f4			; $5071: $fe $f4 
	jr		z, $03			; $5073: $28 $03 
	ld		a, $ff			; $5075: $3e $ff 
	ret					; $5077: $c9 

	push		hl			; $5078: $e5 
	pop		de			; $5079: $d1 
	ld		hl, $ffee		; $507a: $21 $ee $ff 
	ld		(hl), $c0		; $507d: $36 $c0 
	inc		l			; $507f: $2c 
	ld		(hl), d			; $5080: $72 
	inc		l			; $5081: $2c 
	ld		(hl), e			; $5082: $73 
	ld		a, $05			; $5083: $3e $05 
	ld		($dfe0), a		; $5085: $ea $e0 $df 
	ret					; $5088: $c9 
; end routine

; routine
	ld		hl, $c201		; $5089: $21 $01 $c2 
	ldi		a, (hl)			; $508c: $2a 
	add		$0a			; $508d: $c6 $0a 
	ldh		($ad), a		; $508f: $e0 $ad 
	ldh		a, ($a4)		; $5091: $f0 $a4 
	ld		b, a			; $5093: $47 
	ld		a, (hl)			; $5094: $7e 
	add		b			; $5095: $80 
	add		$fe			; $5096: $c6 $fe 
	ldh		($ae), a		; $5098: $e0 $ae 
	call		$0153			; $509a: $cd $53 $01 
	cp		$60			; $509d: $fe $60 
	jr		nc, $13			; $509f: $30 $13 
	ldh		a, ($ae)		; $50a1: $f0 $ae 
	add		$04			; $50a3: $c6 $04 
	ldh		($ae), a		; $50a5: $e0 $ae 
	call		$0153			; $50a7: $cd $53 $01 
	cp		$e1			; $50aa: $fe $e1 
	jp		z, $1b3c		; $50ac: $ca $3c $1b 
	cp		$60			; $50af: $fe $60 
	jr		nc, $01			; $50b1: $30 $01 
	ret					; $50b3: $c9 
	cp		$f4			; $50b4: $fe $f4 
	jr		nz, $11			; $50b6: $20 $11 
	push		hl			; $50b8: $e5 
	pop		de			; $50b9: $d1 
	ld		hl, $ffee		; $50ba: $21 $ee $ff 
	ld		(hl), $c0		; $50bd: $36 $c0 
	inc		l			; $50bf: $2c 
	ld		(hl), d			; $50c0: $72 
	inc		l			; $50c1: $2c 
	ld		(hl), e			; $50c2: $73 
	ld		a, $05			; $50c3: $3e $05 
	ld		($dfe0), a		; $50c5: $ea $e0 $df 
	ret					; $50c8: $c9 
	ld		a, $ff			; $50c9: $3e $ff 
	ret					; $50cb: $c9 
; end routine

; routine
	ld		de, $0502		; $50cc: $11 $02 $05 
	ldh		a, ($99)		; $50cf: $f0 $99 
	cp		$02			; $50d1: $fe $02 
	jr		z, $03			; $50d3: $28 $03 
	ld		de, $0501		; $50d5: $11 $01 $05 
	ld		hl, $c201		; $50d8: $21 $01 $c2 
	ldi		a, (hl)			; $50db: $2a 
	add		d			; $50dc: $82 
	ldh		($ad), a		; $50dd: $e0 $ad 
	ld		b, (hl)			; $50df: $46 
	ld		a, c			; $50e0: $79 
	add		b			; $50e1: $80 
	ld		b, a			; $50e2: $47 
	ldh		a, ($a4)		; $50e3: $f0 $a4 
	add		b			; $50e5: $80 
	ldh		($ae), a		; $50e6: $e0 $ae 
	push		de			; $50e8: $d5 
	call		$0153			; $50e9: $cd $53 $01 
	pop		de			; $50ec: $d1 
	cp		$60			; $50ed: $fe $60 
	jr		c, $10			; $50ef: $38 $10 
	cp		$f4			; $50f1: $fe $f4 
	jr		z, $12			; $50f3: $28 $12 
	cp		$e1			; $50f5: $fe $e1 
	jp		z, $1b3c		; $50f7: $ca $3c $1b 
	cp		$83			; $50fa: $fe $83 
	jp		z, $1b3c		; $50fc: $ca $3c $1b 
	pop		hl			; $50ff: $e1 
	ret					; $5100: $c9 
	ld		d, $fd			; $5101: $16 $fd 
	dec		e			; $5103: $1d 
	jr		nz, -$2e			; $5104: $20 $d2 
	ret					; $5106: $c9 
	push		hl			; $5107: $e5 
	pop		de			; $5108: $d1 
	ld		hl, $ffee		; $5109: $21 $ee $ff 
	ld		(hl), $c0		; $510c: $36 $c0 
	inc		l			; $510e: $2c 
	ld		(hl), d			; $510f: $72 
	inc		l			; $5110: $2c 
	ld		(hl), e			; $5111: $73 
	ld		a, $05			; $5112: $3e $05 
	ld		($dfe0), a		; $5114: $ea $e0 $df 
	ret					; $5117: $c9 
; end routine

; routine
	ld		b, $03			; $5118: $06 $03 
	ld		hl, $ffa9		; $511a: $21 $a9 $ff 
	ld		de, $c001		; $511d: $11 $01 $c0 
	ldi		a, (hl)			; $5120: $2a 
	and		a			; $5121: $a7 
	jr		nz, $08			; $5122: $20 $08 
	inc		e			; $5124: $1c 
	inc		e			; $5125: $1c 
	inc		e			; $5126: $1c 
	inc		e			; $5127: $1c 
	dec		b			; $5128: $05 
	jr		nz, -$0b			; $5129: $20 $f5 
	ret					; $512b: $c9 
	push		hl			; $512c: $e5 
	push		de			; $512d: $d5 
	push		bc			; $512e: $c5 
	dec		l			; $512f: $2d 
	ld		a, (de)			; $5130: $1a 
	inc		a			; $5131: $3c 
	inc		a			; $5132: $3c 
	ld		(de), a			; $5133: $12 
	ldh		($a1), a		; $5134: $e0 $a1 
	ldh		($c3), a		; $5136: $e0 $c3 
	cp		$a9			; $5138: $fe $a9 
	jr		c, $07			; $513a: $38 $07 
	xor		a			; $513c: $af 
	res		0, e			; $513d: $cb $83 
	ld		(de), a			; $513f: $12 
	ld		(hl), a			; $5140: $77 
	jr		$13			; $5141: $18 $13 
	add		$02			; $5143: $c6 $02 
	push		af			; $5145: $f5 
	dec		e			; $5146: $1d 
	ld		a, (de)			; $5147: $1a 
	ldh		($c2), a		; $5148: $e0 $c2 
	add		$06			; $514a: $c6 $06 
	ldh		($ad), a		; $514c: $e0 $ad 
	pop		af			; $514e: $f1 
	call		$1fc9			; $514f: $cd $c9 $1f 
	jr		c, $02			; $5152: $38 $02 
	jr		-$1a			; $5154: $18 $e6 
	pop		bc			; $5156: $c1 
	pop		de			; $5157: $d1 
	pop		hl			; $5158: $e1 
	call		$2001			; $5159: $cd $01 $20 
	jr		-$3a			; $515c: $18 $c6 
	ld		a, ($c202)		; $515e: $fa $02 $c2 
	cp		$01			; $5161: $fe $01 
	jr		c, $03			; $5163: $38 $03 
	cp		$f0			; $5165: $fe $f0 
	ret		c			; $5167: $d8 
	xor		a			; $5168: $af 
	ldh		($99), a		; $5169: $e0 $99 
	ldh		($b5), a		; $516b: $e0 $b5 
	inc		a			; $516d: $3c 
	ldh		($b3), a		; $516e: $e0 $b3 
	inc		a			; $5170: $3c 
	ld		($dfe8), a		; $5171: $ea $e8 $df 
	ld		a, $90			; $5174: $3e $90 
	ldh		($a6), a		; $5176: $e0 $a6 
	ret					; $5178: $c9 
; end routine

; the rest of this bank is highly likely to be data
.incbin "data3.bin"
; end data

.bank 2 slot 1
.org $0

; this is likely some kind of data as wellll
; 50 bytes
; this is a directory of maps!!
; at least a think.. . . . . i wonder why its so repetitive
; looks like its sorted per level? maybe?
MAP_DIRECTORY:
.dw $6192
.dw $61b7
.dw $61da
.dw $6192
.dw $61b7
.dw $61da
.dw $6192
.dw $61b7
.dw $61da
.dw $6192
.dw $61b7
.dw $61da
.dw $6190
.dw $6002
.dw $6073
.dw $60fe
.dw $6002
.dw $6073
.dw $60fe
.dw $6002
.dw $6073
.dw $60fe
.dw $6002
.dw $6073
.dw $60fe
; end data

; entity tiles
ENTITY_CHR:
.incbin "entity.chr"
ENTITY_CHR_END:

; world chr
; also has font up front
FONT_CHR:
WORLD_CHR:
.incbin "world.chr"
WORLD_CHR_END:

; routine
BONUS_IDLE_1_ALIAS:
	jp		BONUS_IDLE_1		; $5832: $c3 $72 $5a 
; end routine

; routine
BONUS_IDLE_2_ALIAS:
	jp		BONUS_IDLE_2		; $5835: $c3 $bb $5a 
; end routine

; routine
BONUS_CHOOSE_ALIAS:
	jp		BONUS_CHOOSE		; $5838: $c3 $65 $5b 
; end routine

; routine
BONUS_WAIT_0_ALIAS:
	jp		BONUS_WAIT_0		; $583b: $c3 $eb $5b 
; end routine

; routine
BONUS_WAIT_1_ALIAS:
	jp		BONUS_WAIT_1		; $583e: $c3 $44 $5c 
; end routine

; routine
BONUS_OUTRO_ALIAS:
	jp		BONUS_OUTRO		; $5841: $c3 $de $5c 
; end routine

; routine
	call		$584b			; $5844: $cd $4b $58 
	call		$5892			; $5847: $cd $92 $58 
	ret					; $584a: $c9 
; end routine

; routine
	ld		a, ($da1d)		; $584b: $fa $1d $da 
	cp		$03			; $584e: $fe $03 
	ret		z			; $5850: $c8 
	ld		hl, $da00		; $5851: $21 $00 $da 
	ld		a, (hl)			; $5854: $7e 
	dec		a			; $5855: $3d 
	ld		(hl), a			; $5856: $77 
	ret		nz			; $5857: $c0 
	ld		a, $28			; $5858: $3e $28 
	ld		(hl), a			; $585a: $77 
	inc		hl			; $585b: $23 
	ldi		a, (hl)			; $585c: $2a 
	ld		c, (hl)			; $585d: $4e 
	dec		hl			; $585e: $2b 
	sub		$01			; $585f: $d6 $01 
	daa					; $5861: $27 
	ldi		(hl), a			; $5862: $22 
	cp		$99			; $5863: $fe $99 
	jr		nz, $04			; $5865: $20 $04 
	dec		c			; $5867: $0d 
	ld		a, c			; $5868: $79 
	ld		(hl), a			; $5869: $77 
	ret					; $586a: $c9 
	ld		hl, $da1d		; $586b: $21 $1d $da 
	cp		$50			; $586e: $fe $50 
	jr		z, $09			; $5870: $28 $09 
	and		a			; $5872: $a7 
	ret		nz			; $5873: $c0 
	or		c			; $5874: $b1 
	jr		nz, $0f			; $5875: $20 $0f 
	ld		a, $03			; $5877: $3e $03 
	ld		(hl), a			; $5879: $77 
	ret					; $587a: $c9 
	ld		a, c			; $587b: $79 
	and		a			; $587c: $a7 
	ret		nz			; $587d: $c0 
	ld		a, $02			; $587e: $3e $02 
	ld		(hl), a			; $5880: $77 
	ld		a, $50			; $5881: $3e $50 
	ldh		($06), a		; $5883: $e0 $06 
	ret					; $5885: $c9 
	ld		a, c			; $5886: $79 
	cp		$01			; $5887: $fe $01 
	ret		nz			; $5889: $c0 
	ld		a, $01			; $588a: $3e $01 
	ld		(hl), a			; $588c: $77 
	ld		a, $30			; $588d: $3e $30 
	ldh		($06), a		; $588f: $e0 $06 
	ret					; $5891: $c9 
; end routine

; routine
	ldh		a, ($ed)		; $5892: $f0 $ed 
	ld		b, a			; $5894: $47 
	and		a			; $5895: $a7 
	jp		z, $59a5		; $5896: $ca $a5 $59 
	ld		a, ($da0b)		; $5899: $fa $0b $da 
	ld		l, a			; $589c: $6f 
	ld		h, $c0			; $589d: $26 $c0 
	ld		de, $0008		; $589f: $11 $08 $00 
	push		hl			; $58a2: $e5 
	add		hl, de			; $58a3: $19 
	ld		a, l			; $58a4: $7d 
	ld		($da0b), a		; $58a5: $ea $0b $da 
	cp		$50			; $58a8: $fe $50 
	jr		nz, $05			; $58aa: $20 $05 
	ld		a, $30			; $58ac: $3e $30 
	ld		($da0b), a		; $58ae: $ea $0b $da 
	pop		hl			; $58b1: $e1 
	ld		c, $20			; $58b2: $0e $20 
	ld		d, $f6			; $58b4: $16 $f6 
	ld		a, l			; $58b6: $7d 
	cp		$30			; $58b7: $fe $30 
	jr		nz, $12			; $58b9: $20 $12 
	ld		a, c			; $58bb: $79 
	ld		($da03), a		; $58bc: $ea $03 $da 
	ld		a, d			; $58bf: $7a 
	ld		($da07), a		; $58c0: $ea $07 $da 
	ld		a, b			; $58c3: $78 
	cp		$c0			; $58c4: $fe $c0 
	jr		nz, $41			; $58c6: $20 $41 
	ld		($da0c), a		; $58c8: $ea $0c $da 
	jr		$3c			; $58cb: $18 $3c 
	cp		$38			; $58cd: $fe $38 
	jr		nz, $12			; $58cf: $20 $12 
	ld		a, c			; $58d1: $79 
	ld		($da04), a		; $58d2: $ea $04 $da 
	ld		a, d			; $58d5: $7a 
	ld		($da08), a		; $58d6: $ea $08 $da 
	ld		a, b			; $58d9: $78 
	cp		$c0			; $58da: $fe $c0 
	jr		nz, $2b			; $58dc: $20 $2b 
	ld		($da0d), a		; $58de: $ea $0d $da 
	jr		$26			; $58e1: $18 $26 
	cp		$40			; $58e3: $fe $40 
	jr		nz, $12			; $58e5: $20 $12 
	ld		a, c			; $58e7: $79 
	ld		($da05), a		; $58e8: $ea $05 $da 
	ld		a, d			; $58eb: $7a 
	ld		($da09), a		; $58ec: $ea $09 $da 
	ld		a, b			; $58ef: $78 
	cp		$c0			; $58f0: $fe $c0 
	jr		nz, $15			; $58f2: $20 $15 
	ld		($da0e), a		; $58f4: $ea $0e $da 
	jr		$10			; $58f7: $18 $10 
	ld		a, c			; $58f9: $79 
	ld		($da06), a		; $58fa: $ea $06 $da 
	ld		a, d			; $58fd: $7a 
	ld		($da0a), a		; $58fe: $ea $0a $da 
	ld		a, b			; $5901: $78 
	cp		$c0			; $5902: $fe $c0 
	jr		nz, $03			; $5904: $20 $03 
	ld		($da0f), a		; $5906: $ea $0f $da 
	ldh		a, ($ec)		; $5909: $f0 $ec 
	ldi		(hl), a			; $590b: $22 
	ldh		a, ($eb)		; $590c: $f0 $eb 
	ldi		(hl), a			; $590e: $22 
	ld		a, b			; $590f: $78 
	ld		de, $5958		; $5910: $11 $58 $59 
	cp		$01			; $5913: $fe $01 
	jr		z, $39			; $5915: $28 $39 
	inc		d			; $5917: $14 
	cp		$02			; $5918: $fe $02 
	jr		z, $34			; $591a: $28 $34 
	inc		d			; $591c: $14 
	cp		$04			; $591d: $fe $04 
	jr		z, $2f			; $591f: $28 $2f 
	inc		d			; $5921: $14 
	cp		$05			; $5922: $fe $05 
	jr		z, $2a			; $5924: $28 $2a 
	inc		d			; $5926: $14 
	cp		$08			; $5927: $fe $08 
	jr		z, $25			; $5929: $28 $25 
	ld		d, $59			; $592b: $16 $59 
	dec		e			; $592d: $1d 
	cp		$10			; $592e: $fe $10 
	jr		z, $1e			; $5930: $28 $1e 
	inc		d			; $5932: $14 
	cp		$20			; $5933: $fe $20 
	jr		z, $19			; $5935: $28 $19 
	inc		d			; $5937: $14 
	cp		$40			; $5938: $fe $40 
	jr		z, $14			; $593a: $28 $14 
	inc		d			; $593c: $14 
	cp		$50			; $593d: $fe $50 
	jr		z, $0f			; $593f: $28 $0f 
	inc		d			; $5941: $14 
	cp		$80			; $5942: $fe $80 
	jr		z, $0a			; $5944: $28 $0a 
	inc		d			; $5946: $14 
	ld		e, $5f			; $5947: $1e $5f 
	cp		$ff			; $5949: $fe $ff 
	jr		z, $03			; $594b: $28 $03 
	ld		de, $f6fe		; $594d: $11 $fe $f6 
	ld		a, d			; $5950: $7a 
	ldi		(hl), a			; $5951: $22 
	inc		hl			; $5952: $23 
	ldh		a, ($ec)		; $5953: $f0 $ec 
	ldi		(hl), a			; $5955: $22 
	ldh		a, ($eb)		; $5956: $f0 $eb 
	add		$08			; $5958: $c6 $08 
	ldi		(hl), a			; $595a: $22 
	ld		a, e			; $595b: $7b 
	ld		(hl), a			; $595c: $77 
	xor		a			; $595d: $af 
	ldh		($ed), a		; $595e: $e0 $ed 
	ldh		($ec), a		; $5960: $e0 $ec 
	ldh		($eb), a		; $5962: $e0 $eb 
	ld		a, b			; $5964: $78 
	ld		de, $0100		; $5965: $11 $00 $01 
	cp		$01			; $5968: $fe $01 
	jr		z, $36			; $596a: $28 $36 
	inc		d			; $596c: $14 
	cp		$02			; $596d: $fe $02 
	jr		z, $31			; $596f: $28 $31 
	inc		d			; $5971: $14 
	inc		d			; $5972: $14 
	cp		$04			; $5973: $fe $04 
	jr		z, $2b			; $5975: $28 $2b 
	inc		d			; $5977: $14 
	cp		$05			; $5978: $fe $05 
	jr		z, $26			; $597a: $28 $26 
	ld		d, $08			; $597c: $16 $08 
	cp		$08			; $597e: $fe $08 
	jr		z, $20			; $5980: $28 $20 
	ld		d, $10			; $5982: $16 $10 
	cp		$10			; $5984: $fe $10 
	jr		z, $1a			; $5986: $28 $1a 
	ld		d, $20			; $5988: $16 $20 
	cp		$20			; $598a: $fe $20 
	jr		z, $14			; $598c: $28 $14 
	ld		d, $40			; $598e: $16 $40 
	cp		$40			; $5990: $fe $40 
	jr		z, $0e			; $5992: $28 $0e 
	ld		d, $50			; $5994: $16 $50 
	cp		$50			; $5996: $fe $50 
	jr		z, $08			; $5998: $28 $08 
	ld		d, $80			; $599a: $16 $80 
	cp		$80			; $599c: $fe $80 
	jr		z, $02			; $599e: $28 $02 
	jr		$03			; $59a0: $18 $03 
	call		$0166			; $59a2: $cd $66 $01 
	ld		hl, $c030		; $59a5: $21 $30 $c0 
	push		hl			; $59a8: $e5 
	ld		a, (hl)			; $59a9: $7e 
	and		a			; $59aa: $a7 
	jp		z, $5a66		; $59ab: $ca $66 $5a 
	ld		a, l			; $59ae: $7d 
	ld		bc, $da06		; $59af: $01 $06 $da 
	ld		de, $da0a		; $59b2: $11 $0a $da 
	ld		hl, $da13		; $59b5: $21 $13 $da 
	cp		$48			; $59b8: $fe $48 
	jr		z, $49			; $59ba: $28 $49 
	dec		c			; $59bc: $0d 
	dec		e			; $59bd: $1d 
	dec		l			; $59be: $2d 
	cp		$40			; $59bf: $fe $40 
	jr		z, $30			; $59c1: $28 $30 
	dec		c			; $59c3: $0d 
	dec		e			; $59c4: $1d 
	dec		l			; $59c5: $2d 
	cp		$38			; $59c6: $fe $38 
	jr		z, $16			; $59c8: $28 $16 
	dec		c			; $59ca: $0d 
	dec		e			; $59cb: $1d 
	dec		l			; $59cc: $2d 
	ld		a, ($da0c)		; $59cd: $fa $0c $da 
	cp		$c0			; $59d0: $fe $c0 
	jr		z, $41			; $59d2: $28 $41 
	ld		a, (hl)			; $59d4: $7e 
	inc		a			; $59d5: $3c 
	ld		(hl), a			; $59d6: $77 
	cp		$02			; $59d7: $fe $02 
	jp		nz, $5a66		; $59d9: $c2 $66 $5a 
	xor		a			; $59dc: $af 
	ld		(hl), a			; $59dd: $77 
	jr		$35			; $59de: $18 $35 
	ld		a, ($da0d)		; $59e0: $fa $0d $da 
	cp		$c0			; $59e3: $fe $c0 
	jr		z, $2e			; $59e5: $28 $2e 
	ld		a, (hl)			; $59e7: $7e 
	inc		a			; $59e8: $3c 
	ld		(hl), a			; $59e9: $77 
	cp		$02			; $59ea: $fe $02 
	jp		nz, $5a66		; $59ec: $c2 $66 $5a 
	xor		a			; $59ef: $af 
	ld		(hl), a			; $59f0: $77 
	jr		$22			; $59f1: $18 $22 
	ld		a, ($da0e)		; $59f3: $fa $0e $da 
	cp		$c0			; $59f6: $fe $c0 
	jr		z, $1b			; $59f8: $28 $1b 
	ld		a, (hl)			; $59fa: $7e 
	inc		a			; $59fb: $3c 
	ld		(hl), a			; $59fc: $77 
	cp		$02			; $59fd: $fe $02 
	jr		nz, $65			; $59ff: $20 $65 
	xor		a			; $5a01: $af 
	ld		(hl), a			; $5a02: $77 
	jr		$10			; $5a03: $18 $10 
	ld		a, ($da0f)		; $5a05: $fa $0f $da 
	cp		$c0			; $5a08: $fe $c0 
	jr		z, $09			; $5a0a: $28 $09 
	ld		a, (hl)			; $5a0c: $7e 
	inc		a			; $5a0d: $3c 
	ld		(hl), a			; $5a0e: $77 
	cp		$02			; $5a0f: $fe $02 
	jr		nz, $53			; $5a11: $20 $53 
	xor		a			; $5a13: $af 
	ld		(hl), a			; $5a14: $77 
	pop		hl			; $5a15: $e1 
	push		hl			; $5a16: $e5 
	dec		(hl)			; $5a17: $35 
	inc		l			; $5a18: $2c 
	inc		l			; $5a19: $2c 
	inc		l			; $5a1a: $2c 
	inc		l			; $5a1b: $2c 
	dec		(hl)			; $5a1c: $35 
	dec		l			; $5a1d: $2d 
	dec		l			; $5a1e: $2d 
	ld		a, (hl)			; $5a1f: $7e 
	cp		$f6			; $5a20: $fe $f6 
	jr		c, $13			; $5a22: $38 $13 
	ld		a, (de)			; $5a24: $1a 
	inc		a			; $5a25: $3c 
	ld		(de), a			; $5a26: $12 
	ld		(hl), a			; $5a27: $77 
	cp		$f9			; $5a28: $fe $f9 
	jr		c, $0b			; $5a2a: $38 $0b 
	dec		a			; $5a2c: $3d 
	dec		a			; $5a2d: $3d 
	ld		(hl), a			; $5a2e: $77 
	cp		$f7			; $5a2f: $fe $f7 
	jr		z, $04			; $5a31: $28 $04 
	dec		a			; $5a33: $3d 
	dec		a			; $5a34: $3d 
	ld		(de), a			; $5a35: $12 
	ld		(hl), a			; $5a36: $77 
	ld		a, (bc)			; $5a37: $0a 
	dec		a			; $5a38: $3d 
	ld		(bc), a			; $5a39: $02 
	jr		nz, $2a			; $5a3a: $20 $2a 
	ld		a, $20			; $5a3c: $3e $20 
	ld		(bc), a			; $5a3e: $02 
	ld		a, $f6			; $5a3f: $3e $f6 
	ld		(de), a			; $5a41: $12 
	xor		a			; $5a42: $af 
	ldd		(hl), a			; $5a43: $32 
	ldd		(hl), a			; $5a44: $32 
	ldi		(hl), a			; $5a45: $22 
	inc		l			; $5a46: $2c 
	inc		l			; $5a47: $2c 
	inc		l			; $5a48: $2c 
	ldi		(hl), a			; $5a49: $22 
	ldi		(hl), a			; $5a4a: $22 
	ld		(hl), a			; $5a4b: $77 
	ld		a, l			; $5a4c: $7d 
	ld		hl, $da0c		; $5a4d: $21 $0c $da 
	ld		bc, $0004		; $5a50: $01 $04 $00 
	cp		$36			; $5a53: $fe $36 
	jr		z, $0b			; $5a55: $28 $0b 
	inc		l			; $5a57: $2c 
	cp		$3e			; $5a58: $fe $3e 
	jr		z, $06			; $5a5a: $28 $06 
	inc		l			; $5a5c: $2c 
	cp		$46			; $5a5d: $fe $46 
	jr		z, $01			; $5a5f: $28 $01 
	inc		l			; $5a61: $2c 
	xor		a			; $5a62: $af 
	ld		(hl), a			; $5a63: $77 
	add		hl, bc			; $5a64: $09 
	ld		(hl), a			; $5a65: $77 
	pop		hl			; $5a66: $e1 
	ld		de, $0008		; $5a67: $11 $08 $00 
	add		hl, de			; $5a6a: $19 
	ld		a, l			; $5a6b: $7d 
	cp		$50			; $5a6c: $fe $50 
	jp		nz, $59a8		; $5a6e: $c2 $a8 $59 
	ret					; $5a71: $c9 
; end routine

; routine
BONUS_IDLE_1:
	ld		hl, $c030		; $5a72: $21 $30 $c0 
	ldh		a, ($04)		; $5a75: $f0 $04 
	and		$03			; $5a77: $e6 $03 
	inc		a			; $5a79: $3c 
	ld		b, a			; $5a7a: $47 
	ld		a, $20			; $5a7b: $3e $20 
	add		$18			; $5a7d: $c6 $18 
	dec		b			; $5a7f: $05 
	jr		nz, -$05			; $5a80: $20 $fb 
	ld		b, a			; $5a82: $47 
	ldi		(hl), a			; $5a83: $22 
	ld		a, $10			; $5a84: $3e $10 
	ld		c, a			; $5a86: $4f 
	ldi		(hl), a			; $5a87: $22 
	xor		a			; $5a88: $af 
	ld		d, a			; $5a89: $57 
	ldh		a, ($99)		; $5a8a: $f0 $99 
	cp		$02			; $5a8c: $fe $02 
	jr		nz, $03			; $5a8e: $20 $03 
	ld		a, $20			; $5a90: $3e $20 
	ld		d, a			; $5a92: $57 
	ld		a, d			; $5a93: $7a 
	ldi		(hl), a			; $5a94: $22 
	inc		l			; $5a95: $2c 
	ld		a, b			; $5a96: $78 
	ldi		(hl), a			; $5a97: $22 
	ld		a, c			; $5a98: $79 
	add		$08			; $5a99: $c6 $08 
	ldi		(hl), a			; $5a9b: $22 
	ld		a, d			; $5a9c: $7a 
	inc		a			; $5a9d: $3c 
	ldi		(hl), a			; $5a9e: $22 
	inc		l			; $5a9f: $2c 
	ld		a, b			; $5aa0: $78 
	add		$08			; $5aa1: $c6 $08 
	ld		b, a			; $5aa3: $47 
	ldi		(hl), a			; $5aa4: $22 
	ld		a, c			; $5aa5: $79 
	ldi		(hl), a			; $5aa6: $22 
	ld		a, d			; $5aa7: $7a 
	add		$10			; $5aa8: $c6 $10 
	ld		d, a			; $5aaa: $57 
	ldi		(hl), a			; $5aab: $22 
	inc		l			; $5aac: $2c 
	ld		a, b			; $5aad: $78 
	ldi		(hl), a			; $5aae: $22 
	ld		a, c			; $5aaf: $79 
	add		$08			; $5ab0: $c6 $08 
	ldi		(hl), a			; $5ab2: $22 
	inc		d			; $5ab3: $14 
	ld		a, d			; $5ab4: $7a 
	ld		(hl), a			; $5ab5: $77 
	ld		a, $15			; $5ab6: $3e $15 
	ldh		($b3), a		; $5ab8: $e0 $b3 
	ret					; $5aba: $c9 
; end routine

; routine
BONUS_IDLE_2:
	ld		a, ($da27)		; $5abb: $fa $27 $da 
	bit		0, a			; $5abe: $cb $47 
	jr		z, $07			; $5ac0: $28 $07 
	ldh		a, ($80)		; $5ac2: $f0 $80 
	bit		0, a			; $5ac4: $cb $47 
	jp		nz, $5b56		; $5ac6: $c2 $56 $5b 
	ld		hl, $da22		; $5ac9: $21 $22 $da 
	ld		a, (hl)			; $5acc: $7e 
	inc		a			; $5acd: $3c 
	ld		(hl), a			; $5ace: $77 
	cp		$03			; $5acf: $fe $03 
	ret		nz			; $5ad1: $c0 
	xor		a			; $5ad2: $af 
	ld		(hl), a			; $5ad3: $77 
	ld		a, ($da27)		; $5ad4: $fa $27 $da 
	bit		0, a			; $5ad7: $cb $47 
	jr		z, $2c			; $5ad9: $28 $2c 
	ld		hl, $c030		; $5adb: $21 $30 $c0 
	ld		b, $04			; $5ade: $06 $04 
	ld		a, (hl)			; $5ae0: $7e 
	cp		$80			; $5ae1: $fe $80 
	jr		z, $0c			; $5ae3: $28 $0c 
	ld		a, $18			; $5ae5: $3e $18 
	add		(hl)			; $5ae7: $86 
	ldi		(hl), a			; $5ae8: $22 
	inc		l			; $5ae9: $2c 
	inc		l			; $5aea: $2c 
	inc		l			; $5aeb: $2c 
	dec		b			; $5aec: $05 
	jr		nz, -$0a			; $5aed: $20 $f6 
	jr		$16			; $5aef: $18 $16 
	ld		b, $02			; $5af1: $06 $02 
	ld		a, $38			; $5af3: $3e $38 
	ldi		(hl), a			; $5af5: $22 
	inc		l			; $5af6: $2c 
	inc		l			; $5af7: $2c 
	inc		l			; $5af8: $2c 
	dec		b			; $5af9: $05 
	jr		nz, -$07			; $5afa: $20 $f9 
	ld		b, $02			; $5afc: $06 $02 
	ld		a, $40			; $5afe: $3e $40 
	ldi		(hl), a			; $5b00: $22 
	inc		l			; $5b01: $2c 
	inc		l			; $5b02: $2c 
	inc		l			; $5b03: $2c 
	dec		b			; $5b04: $05 
	jr		nz, -$07			; $5b05: $20 $f9 
	ld		hl, $98ea		; $5b07: $21 $ea $98 
	ld		bc, $0060		; $5b0a: $01 $60 $00 
	ld		de, $da27		; $5b0d: $11 $27 $da 
	ld		a, (de)			; $5b10: $1a 
	inc		a			; $5b11: $3c 
	ld		(de), a			; $5b12: $12 
	cp		$03			; $5b13: $fe $03 
	jr		c, $10			; $5b15: $38 $10 
	add		hl, bc			; $5b17: $09 
	cp		$05			; $5b18: $fe $05 
	jr		c, $0b			; $5b1a: $38 $0b 
	add		hl, bc			; $5b1c: $09 
	cp		$07			; $5b1d: $fe $07 
	jr		c, $06			; $5b1f: $38 $06 
	ld		hl, $98ea		; $5b21: $21 $ea $98 
	xor		a			; $5b24: $af 
	inc		a			; $5b25: $3c 
	ld		(de), a			; $5b26: $12 
	ld		a, h			; $5b27: $7c 
	ld		($da18), a		; $5b28: $ea $18 $da 
	ld		a, l			; $5b2b: $7d 
	ld		($da19), a		; $5b2c: $ea $19 $da 
	ld		hl, $da23		; $5b2f: $21 $23 $da 
	ld		a, (de)			; $5b32: $1a 
	bit		0, a			; $5b33: $cb $47 
	jr		z, $0e			; $5b35: $28 $0e 
	ld		a, $2e			; $5b37: $3e $2e 
	ldi		(hl), a			; $5b39: $22 
	ld		a, $2f			; $5b3a: $3e $2f 
	ldi		(hl), a			; $5b3c: $22 
	ld		a, $2f			; $5b3d: $3e $2f 
	ldi		(hl), a			; $5b3f: $22 
	ld		a, $30			; $5b40: $3e $30 
	ld		(hl), a			; $5b42: $77 
	jr		$0c			; $5b43: $18 $0c 
	ld		a, $2d			; $5b45: $3e $2d 
	ldi		(hl), a			; $5b47: $22 
	ld		a, $2c			; $5b48: $3e $2c 
	ldi		(hl), a			; $5b4a: $22 
	ld		a, $2c			; $5b4b: $3e $2c 
	ldi		(hl), a			; $5b4d: $22 
	ld		a, $2d			; $5b4e: $3e $2d 
	ld		(hl), a			; $5b50: $77 
	ld		a, $16			; $5b51: $3e $16 
	ldh		($b3), a		; $5b53: $e0 $b3 
	ret					; $5b55: $c9 

	xor		a			; $5b56: $af 
	ld		($da22), a		; $5b57: $ea $22 $da 
	ld		($da27), a		; $5b5a: $ea $27 $da 
	ld		($da1a), a		; $5b5d: $ea $1a $da 
	ld		a, $17			; $5b60: $3e $17 
	ldh		($b3), a		; $5b62: $e0 $b3 
	ret					; $5b64: $c9 
; end routine

; routine
BONUS_CHOOSE:
	ld		hl, $da1c		; $5b65: $21 $1c $da 
	ld		a, (hl)			; $5b68: $7e 
	and		a			; $5b69: $a7 
	jr		nz, $07			; $5b6a: $20 $07 
	inc		(hl)			; $5b6c: $34 
	ld		hl, $dfe8		; $5b6d: $21 $e8 $df 
	ld		a, $0a			; $5b70: $3e $0a 
	ld		(hl), a			; $5b72: $77 
	ld		hl, $c031		; $5b73: $21 $31 $c0 
	ld		de, $5c9d		; $5b76: $11 $9d $5c 
	ld		b, $04			; $5b79: $06 $04 
	ld		a, ($da14)		; $5b7b: $fa $14 $da 
	and		a			; $5b7e: $a7 
	jr		z, $04			; $5b7f: $28 $04 
	inc		de			; $5b81: $13 
	dec		a			; $5b82: $3d 
	jr		nz, -$04			; $5b83: $20 $fc 
	inc		(hl)			; $5b85: $34 
	inc		l			; $5b86: $2c 
	ld		a, (de)			; $5b87: $1a 
	ld		c, a			; $5b88: $4f 
	cp		$ff			; $5b89: $fe $ff 
	jr		nz, $09			; $5b8b: $20 $09 
	ld		de, $5c9d		; $5b8d: $11 $9d $5c 
	xor		a			; $5b90: $af 
	ld		($da14), a		; $5b91: $ea $14 $da 
	ld		a, (de)			; $5b94: $1a 
	ld		c, a			; $5b95: $4f 
	ldh		a, ($99)		; $5b96: $f0 $99 
	cp		$02			; $5b98: $fe $02 
	jr		nz, $04			; $5b9a: $20 $04 
	ld		a, c			; $5b9c: $79 
	add		$20			; $5b9d: $c6 $20 
	ld		c, a			; $5b9f: $4f 
	ld		a, c			; $5ba0: $79 
	ldi		(hl), a			; $5ba1: $22 
	inc		de			; $5ba2: $13 
	inc		l			; $5ba3: $2c 
	inc		l			; $5ba4: $2c 
	dec		b			; $5ba5: $05 
	jr		nz, -$23			; $5ba6: $20 $dd 
	ld		a, ($da14)		; $5ba8: $fa $14 $da 
	add		$04			; $5bab: $c6 $04 
	ld		($da14), a		; $5bad: $ea $14 $da 
	ld		hl, $c031		; $5bb0: $21 $31 $c0 
	ldd		a, (hl)			; $5bb3: $3a 
	cp		$80			; $5bb4: $fe $80 
	jr		nc, $2a			; $5bb6: $30 $2a 
	add		$04			; $5bb8: $c6 $04 
	ldh		($ae), a		; $5bba: $e0 $ae 
	ld		a, (hl)			; $5bbc: $7e 
	add		$10			; $5bbd: $c6 $10 
	ldh		($ad), a		; $5bbf: $e0 $ad 
	ld		bc, $da16		; $5bc1: $01 $16 $da 
	ld		a, (bc)			; $5bc4: $0a 
	dec		a			; $5bc5: $3d 
	ld		(bc), a			; $5bc6: $02 
	ret		nz			; $5bc7: $c0 
	ld		a, $01			; $5bc8: $3e $01 
	ld		(bc), a			; $5bca: $02 
	call		$0153			; $5bcb: $cd $53 $01 
	ld		a, (hl)			; $5bce: $7e 
	cp		$2e			; $5bcf: $fe $2e 
	jr		z, $05			; $5bd1: $28 $05 
	cp		$30			; $5bd3: $fe $30 
	jr		z, $06			; $5bd5: $28 $06 
	ret					; $5bd7: $c9 
	ld		a, $18			; $5bd8: $3e $18 
	ldh		($b3), a		; $5bda: $e0 $b3 
	ret					; $5bdc: $c9 
	ld		a, $19			; $5bdd: $3e $19 
	ldh		($b3), a		; $5bdf: $e0 $b3 
	ret					; $5be1: $c9 

	xor		a			; $5be2: $af 
	ld		($da1c), a		; $5be3: $ea $1c $da 
	ld		a, $1a			; $5be6: $3e $1a 
	ldh		($b3), a		; $5be8: $e0 $b3 
	ret					; $5bea: $c9 
; end routine

; routine
BONUS_WAIT_0:
	ld		hl, $c030		; $5beb: $21 $30 $c0 
	ld		b, $04			; $5bee: $06 $04 
	ld		de, $5c9d		; $5bf0: $11 $9d $5c 
	ld		a, ($da14)		; $5bf3: $fa $14 $da 
	and		a			; $5bf6: $a7 
	jr		z, $05			; $5bf7: $28 $05 
	ld		c, a			; $5bf9: $4f 
	inc		de			; $5bfa: $13 
	dec		c			; $5bfb: $0d 
	jr		nz, -$04			; $5bfc: $20 $fc 
	inc		(hl)			; $5bfe: $34 
	inc		l			; $5bff: $2c 
	inc		l			; $5c00: $2c 
	ld		a, (de)			; $5c01: $1a 
	ld		c, a			; $5c02: $4f 
	cp		$ff			; $5c03: $fe $ff 
	jr		nz, $09			; $5c05: $20 $09 
	ld		de, $5c9d		; $5c07: $11 $9d $5c 
	xor		a			; $5c0a: $af 
	ld		($da14), a		; $5c0b: $ea $14 $da 
	ld		a, (de)			; $5c0e: $1a 
	ld		c, a			; $5c0f: $4f 
	ldh		a, ($99)		; $5c10: $f0 $99 
	cp		$02			; $5c12: $fe $02 
	jr		nz, $04			; $5c14: $20 $04 
	ld		a, c			; $5c16: $79 
	add		$20			; $5c17: $c6 $20 
	ld		c, a			; $5c19: $4f 
	ld		a, c			; $5c1a: $79 
	ldi		(hl), a			; $5c1b: $22 
	inc		de			; $5c1c: $13 
	inc		l			; $5c1d: $2c 
	dec		b			; $5c1e: $05 
	jr		nz, -$23			; $5c1f: $20 $dd 
	ld		a, ($da14)		; $5c21: $fa $14 $da 
	add		$04			; $5c24: $c6 $04 
	ld		($da14), a		; $5c26: $ea $14 $da 
	ld		hl, $c030		; $5c29: $21 $30 $c0 
	ld		a, (hl)			; $5c2c: $7e 
	cp		$50			; $5c2d: $fe $50 
	jr		z, $09			; $5c2f: $28 $09 
	cp		$68			; $5c31: $fe $68 
	jr		z, $05			; $5c33: $28 $05 
	cp		$80			; $5c35: $fe $80 
	jr		z, $01			; $5c37: $28 $01 
	ret					; $5c39: $c9 
	ld		a, $08			; $5c3a: $3e $08 
	ld		($da16), a		; $5c3c: $ea $16 $da 
	ld		a, $17			; $5c3f: $3e $17 
	ldh		($b3), a		; $5c41: $e0 $b3 
	ret					; $5c43: $c9 
; end routine

; routine
BONUS_WAIT_1:
	ld		hl, $c030		; $5c44: $21 $30 $c0 
	ld		b, $04			; $5c47: $06 $04 
	ld		de, $5c9d		; $5c49: $11 $9d $5c 
	ld		a, ($da14)		; $5c4c: $fa $14 $da 
	and		a			; $5c4f: $a7 
	jr		z, $05			; $5c50: $28 $05 
	ld		c, a			; $5c52: $4f 
	inc		de			; $5c53: $13 
	dec		c			; $5c54: $0d 
	jr		nz, -$04			; $5c55: $20 $fc 
	dec		(hl)			; $5c57: $35 
	inc		l			; $5c58: $2c 
	inc		l			; $5c59: $2c 
	ld		a, (de)			; $5c5a: $1a 
	ld		c, a			; $5c5b: $4f 
	cp		$ff			; $5c5c: $fe $ff 
	jr		nz, $09			; $5c5e: $20 $09 
	ld		de, $5c9d		; $5c60: $11 $9d $5c 
	xor		a			; $5c63: $af 
	ld		($da14), a		; $5c64: $ea $14 $da 
	ld		a, (de)			; $5c67: $1a 
	ld		c, a			; $5c68: $4f 
	ldh		a, ($99)		; $5c69: $f0 $99 
	cp		$02			; $5c6b: $fe $02 
	jr		nz, $04			; $5c6d: $20 $04 
	ld		a, c			; $5c6f: $79 
	add		$20			; $5c70: $c6 $20 
	ld		c, a			; $5c72: $4f 
	ld		a, c			; $5c73: $79 
	ldi		(hl), a			; $5c74: $22 
	inc		de			; $5c75: $13 
	inc		l			; $5c76: $2c 
	dec		b			; $5c77: $05 
	jr		nz, -$23			; $5c78: $20 $dd 
	ld		a, ($da14)		; $5c7a: $fa $14 $da 
	add		$04			; $5c7d: $c6 $04 
	ld		($da14), a		; $5c7f: $ea $14 $da 
	ld		hl, $c030		; $5c82: $21 $30 $c0 
	ld		a, (hl)			; $5c85: $7e 
	cp		$38			; $5c86: $fe $38 
	jr		z, $09			; $5c88: $28 $09 
	cp		$50			; $5c8a: $fe $50 
	jr		z, $05			; $5c8c: $28 $05 
	cp		$68			; $5c8e: $fe $68 
	jr		z, $01			; $5c90: $28 $01 
	ret					; $5c92: $c9 
	ld		a, $08			; $5c93: $3e $08 
	ld		($da16), a		; $5c95: $ea $16 $da 
	ld		a, $17			; $5c98: $3e $17 
	ldh		($b3), a		; $5c9a: $e0 $b3 
	ret					; $5c9c: $c9 
; end routine

; data
; looks like bonus screen oam?
; its probably like, animation data???
; 65 bytes! or 41h bytes
; its terminated u see
.incbin "data5.bin"
.db $ff ; terminates
; end data

; routine
BONUS_OUTRO:
	ld		a, ($da17)		; $5cde: $fa $17 $da 
	and		a			; $5ce1: $a7 
	jp		nz, $5d69		; $5ce2: $c2 $69 $5d 
	ld		c, $02			; $5ce5: $0e $02 
	ld		hl, $98d1		; $5ce7: $21 $d1 $98 
	ld		de, $0060		; $5cea: $11 $60 $00 
	ld		a, ($c030)		; $5ced: $fa $30 $c0 
	ld		b, a			; $5cf0: $47 
	cp		$38			; $5cf1: $fe $38 
	jr		z, $04			; $5cf3: $28 $04 
	ld		a, $2c			; $5cf5: $3e $2c 
	ldi		(hl), a			; $5cf7: $22 
	ldd		(hl), a			; $5cf8: $32 
	add		hl, de			; $5cf9: $19 
	ld		a, b			; $5cfa: $78 
	cp		$50			; $5cfb: $fe $50 
	jr		z, $04			; $5cfd: $28 $04 
	ld		a, $2c			; $5cff: $3e $2c 
	ldi		(hl), a			; $5d01: $22 
	ldd		(hl), a			; $5d02: $32 
	add		hl, de			; $5d03: $19 
	ld		a, b			; $5d04: $78 
	cp		$68			; $5d05: $fe $68 
	jr		z, $04			; $5d07: $28 $04 
	ld		a, $2c			; $5d09: $3e $2c 
	ldi		(hl), a			; $5d0b: $22 
	ldd		(hl), a			; $5d0c: $32 
	add		hl, de			; $5d0d: $19 
	ld		a, b			; $5d0e: $78 
	cp		$80			; $5d0f: $fe $80 
	jr		z, $04			; $5d11: $28 $04 
	ld		a, $2c			; $5d13: $3e $2c 
	ldi		(hl), a			; $5d15: $22 
	ld		(hl), a			; $5d16: $77 
	dec		c			; $5d17: $0d 
	jr		nz, -$33			; $5d18: $20 $cd 
	ld		hl, $c031		; $5d1a: $21 $31 $c0 
	ldd		a, (hl)			; $5d1d: $3a 
	add		$18			; $5d1e: $c6 $18 
	ldh		($ae), a		; $5d20: $e0 $ae 
	ld		a, (hl)			; $5d22: $7e 
	add		$08			; $5d23: $c6 $08 
	ldh		($ad), a		; $5d25: $e0 $ad 
	call		$0153			; $5d27: $cd $53 $01 
	ld		a, (hl)			; $5d2a: $7e 
	cp		$03			; $5d2b: $fe $03 
	jr		z, $1b			; $5d2d: $28 $1b 
	cp		$e5			; $5d2f: $fe $e5 
	jr		z, $1e			; $5d31: $28 $1e 
	cp		$02			; $5d33: $fe $02 
	jr		z, $0c			; $5d35: $28 $0c 
	ld		a, $02			; $5d37: $3e $02 
	ld		($da17), a		; $5d39: $ea $17 $da 
	ld		hl, $dfe8		; $5d3c: $21 $e8 $df 
	ld		a, $0d			; $5d3f: $3e $0d 
	ld		(hl), a			; $5d41: $77 
	ret					; $5d42: $c9 
	ld		a, $03			; $5d43: $3e $03 
	ld		($da17), a		; $5d45: $ea $17 $da 
	jr		-$0e			; $5d48: $18 $f2 
	ld		a, $04			; $5d4a: $3e $04 
	ld		($da17), a		; $5d4c: $ea $17 $da 
	jr		-$15			; $5d4f: $18 $eb 
	ldh		a, ($b5)		; $5d51: $f0 $b5 
	and		a			; $5d53: $a7 
	jr		z, $0c			; $5d54: $28 $0c 
	ld		hl, $dfe8		; $5d56: $21 $e8 $df 
	ld		a, $0e			; $5d59: $3e $0e 
	ld		(hl), a			; $5d5b: $77 
	ld		a, $01			; $5d5c: $3e $01 
	ld		($da17), a		; $5d5e: $ea $17 $da 
	ret					; $5d61: $c9 
	ld		a, $10			; $5d62: $3e $10 
	ld		($da17), a		; $5d64: $ea $17 $da 
	jr		-$2d			; $5d67: $18 $d3 
	ld		a, ($da17)		; $5d69: $fa $17 $da 
	cp		$10			; $5d6c: $fe $10 
	jr		nc, $30			; $5d6e: $30 $30 
	cp		$02			; $5d70: $fe $02 
	jp		nc, $5e02		; $5d72: $d2 $02 $5e 
	ld		a, ($da1b)		; $5d75: $fa $1b $da 
	dec		a			; $5d78: $3d 
	ld		($da1b), a		; $5d79: $ea $1b $da 
	ret		nz			; $5d7c: $c0 
	ld		a, $40			; $5d7d: $3e $40 
	ld		($da1b), a		; $5d7f: $ea $1b $da 
	xor		a			; $5d82: $af 
	ld		($da17), a		; $5d83: $ea $17 $da 
	ld		($da14), a		; $5d86: $ea $14 $da 
	ld		($da1c), a		; $5d89: $ea $1c $da 
	ld		($da1e), a		; $5d8c: $ea $1e $da 
	ld		($da20), a		; $5d8f: $ea $20 $da 
	inc		a			; $5d92: $3c 
	ld		($da16), a		; $5d93: $ea $16 $da 
	ld		a, $40			; $5d96: $3e $40 
	ld		($da1f), a		; $5d98: $ea $1f $da 
	ld		a, $1b			; $5d9b: $3e $1b 
	ldh		($b3), a		; $5d9d: $e0 $b3 
	ret					; $5d9f: $c9 
	ld		a, ($da1f)		; $5da0: $fa $1f $da 
	dec		a			; $5da3: $3d 
	ld		($da1f), a		; $5da4: $ea $1f $da 
	ret		nz			; $5da7: $c0 
	ld		a, $03			; $5da8: $3e $03 
	ld		($da1f), a		; $5daa: $ea $1f $da 
	ld		a, ($da17)		; $5dad: $fa $17 $da 
	inc		a			; $5db0: $3c 
	ld		($da17), a		; $5db1: $ea $17 $da 
	cp		$28			; $5db4: $fe $28 
	jr		z, $3f			; $5db6: $28 $3f 
	ld		a, ($da1c)		; $5db8: $fa $1c $da 
	and		a			; $5dbb: $a7 
	jr		nz, $10			; $5dbc: $20 $10 
	inc		a			; $5dbe: $3c 
	ld		($da1c), a		; $5dbf: $ea $1c $da 
	ld		hl, $dfe0		; $5dc2: $21 $e0 $df 
	ld		a, $04			; $5dc5: $3e $04 
	ld		(hl), a			; $5dc7: $77 
	ldh		a, ($99)		; $5dc8: $f0 $99 
	cp		$02			; $5dca: $fe $02 
	jr		z, ++			; $5dcc: $28 $29 
	ld		hl, $c032		; $5dce: $21 $32 $c0 
	ld		b, $04			; $5dd1: $06 $04 
	ld		a, ($da1e)		; $5dd3: $fa $1e $da 
	and		a			; $5dd6: $a7 
	jr		nz, +			; $5dd7: $20 $0f 
	inc		a			; $5dd9: $3c 
	ld		($da1e), a		; $5dda: $ea $1e $da 
	ld		a, (hl)			; $5ddd: $7e 
	add		$20			; $5dde: $c6 $20 
	ldi		(hl), a			; $5de0: $22 
	inc		l			; $5de1: $2c 
	inc		l			; $5de2: $2c 
	inc		l			; $5de3: $2c 
	dec		b			; $5de4: $05 
	jr		nz, -$0a			; $5de5: $20 $f6 
	ret					; $5de7: $c9 

+	dec		a			; $5de8: $3d 
	ld		($da1e), a		; $5de9: $ea $1e $da 
	ld		a, (hl)			; $5dec: $7e 
	sub		$20			; $5ded: $d6 $20 
	ldi		(hl), a			; $5def: $22 
	inc		l			; $5df0: $2c 
	inc		l			; $5df1: $2c 
	inc		l			; $5df2: $2c 
	dec		b			; $5df3: $05 
	jr		nz, -$0a			; $5df4: $20 $f6 
	ret					; $5df6: $c9 

++	ld		a, $01			; $5df7: $3e $01 
	ld		($da17), a		; $5df9: $ea $17 $da 
	inc		a			; $5dfc: $3c 
	ldh		($99), a		; $5dfd: $e0 $99 
	ldh		($b5), a		; $5dff: $e0 $b5 
	ret					; $5e01: $c9 

	ld		a, ($da1f)		; $5e02: $fa $1f $da 
	dec		a			; $5e05: $3d 
	ld		($da1f), a		; $5e06: $ea $1f $da 
	ret		nz			; $5e09: $c0 
	ld		a, $04			; $5e0a: $3e $04 
	ld		($da1f), a		; $5e0c: $ea $1f $da 
	ld		a, ($da20)		; $5e0f: $fa $20 $da 
	and		a			; $5e12: $a7 
	jr		nz, +			; $5e13: $20 $2a 
	ld		hl, $c030		; $5e15: $21 $30 $c0 
	ld		a, $38			; $5e18: $3e $38 
	ld		b, a			; $5e1a: $47 
	ldi		(hl), a			; $5e1b: $22 
	ld		a, $58			; $5e1c: $3e $58 
	ld		c, a			; $5e1e: $4f 
	ldi		(hl), a			; $5e1f: $22 
	inc		l			; $5e20: $2c 
	inc		l			; $5e21: $2c 
	ld		a, b			; $5e22: $78 
	ldi		(hl), a			; $5e23: $22 
	ld		a, c			; $5e24: $79 
	add		$08			; $5e25: $c6 $08 
	ldi		(hl), a			; $5e27: $22 
	inc		l			; $5e28: $2c 
	inc		l			; $5e29: $2c 
	ld		a, b			; $5e2a: $78 
	add		$08			; $5e2b: $c6 $08 
	ld		b, a			; $5e2d: $47 
	ldi		(hl), a			; $5e2e: $22 
	ld		a, c			; $5e2f: $79 
	ldi		(hl), a			; $5e30: $22 
	inc		l			; $5e31: $2c 
	inc		l			; $5e32: $2c 
	ld		a, b			; $5e33: $78 
	ldi		(hl), a			; $5e34: $22 
	ld		a, c			; $5e35: $79 
	add		$08			; $5e36: $c6 $08 
	ldi		(hl), a			; $5e38: $22 
	xor		a			; $5e39: $af 
	inc		a			; $5e3a: $3c 
	ld		($da20), a		; $5e3b: $ea $20 $da 
	ret					; $5e3e: $c9 

+	ld		hl, $c030		; $5e3f: $21 $30 $c0 
	ld		a, ($da21)		; $5e42: $fa $21 $da 
	cp		$02			; $5e45: $fe $02 
	jp		z, $5eda		; $5e47: $ca $da $5e 
	and		a			; $5e4a: $a7 
	jr		nz, +			; $5e4b: $20 $65 
	ld		a, (hl)			; $5e4d: $7e 
	dec		a			; $5e4e: $3d 
	ldi		(hl), a			; $5e4f: $22 
	inc		l			; $5e50: $2c 
	ld		a, $08			; $5e51: $3e $08 
	ld		b, a			; $5e53: $47 
	ldh		a, ($99)		; $5e54: $f0 $99 
	cp		$02			; $5e56: $fe $02 
	jr		nz, $04			; $5e58: $20 $04 
	ld		a, b			; $5e5a: $78 
	add		$20			; $5e5b: $c6 $20 
	ld		b, a			; $5e5d: $47 
	ld		a, b			; $5e5e: $78 
	ldi		(hl), a			; $5e5f: $22 
	inc		l			; $5e60: $2c 
	ld		a, (hl)			; $5e61: $7e 
	dec		a			; $5e62: $3d 
	ldi		(hl), a			; $5e63: $22 
	inc		l			; $5e64: $2c 
	ld		a, b			; $5e65: $78 
	inc		a			; $5e66: $3c 
	ldi		(hl), a			; $5e67: $22 
	inc		l			; $5e68: $2c 
	ld		a, (hl)			; $5e69: $7e 
	dec		a			; $5e6a: $3d 
	ldi		(hl), a			; $5e6b: $22 
	inc		l			; $5e6c: $2c 
	ld		a, b			; $5e6d: $78 
	add		$10			; $5e6e: $c6 $10 
	ld		b, a			; $5e70: $47 
	ldi		(hl), a			; $5e71: $22 
	inc		l			; $5e72: $2c 
	ld		a, (hl)			; $5e73: $7e 
	dec		a			; $5e74: $3d 
	ldi		(hl), a			; $5e75: $22 
	inc		l			; $5e76: $2c 
	ld		a, b			; $5e77: $78 
	inc		a			; $5e78: $3c 
	ld		(hl), a			; $5e79: $77 
	ld		a, ($da20)		; $5e7a: $fa $20 $da 
	inc		a			; $5e7d: $3c 
	ld		($da20), a		; $5e7e: $ea $20 $da 
	cp		$06			; $5e81: $fe $06 
	ret		nz			; $5e83: $c0 
	ld		hl, $dfe0		; $5e84: $21 $e0 $df 
	ld		a, $08			; $5e87: $3e $08 
	ld		(hl), a			; $5e89: $77 
	ld		a, ($da15)		; $5e8a: $fa $15 $da 
	and		a			; $5e8d: $a7 
	cp		$99			; $5e8e: $fe $99 
	jr		nc, $17			; $5e90: $30 $17 
	add		$01			; $5e92: $c6 $01 
	daa					; $5e94: $27 
	ld		($da15), a		; $5e95: $ea $15 $da 
	ld		de, $988b		; $5e98: $11 $8b $98 
	ld		a, ($da15)		; $5e9b: $fa $15 $da 
	ld		b, a			; $5e9e: $47 
	and		$0f			; $5e9f: $e6 $0f 
	ld		(de), a			; $5ea1: $12 
	dec		e			; $5ea2: $1d 
	ld		a, b			; $5ea3: $78 
	and		$f0			; $5ea4: $e6 $f0 
	swap		a			; $5ea6: $cb $37 
	ld		(de), a			; $5ea8: $12 
	ld		a, $01			; $5ea9: $3e $01 
	ld		($da20), a		; $5eab: $ea $20 $da 
	ld		($da21), a		; $5eae: $ea $21 $da 
	ret					; $5eb1: $c9 

+	ld		a, (hl)			; $5eb2: $7e 
	inc		a			; $5eb3: $3c 
	ldi		(hl), a			; $5eb4: $22 
	inc		l			; $5eb5: $2c 
	inc		l			; $5eb6: $2c 
	inc		l			; $5eb7: $2c 
	ld		a, (hl)			; $5eb8: $7e 
	inc		a			; $5eb9: $3c 
	ldi		(hl), a			; $5eba: $22 
	inc		l			; $5ebb: $2c 
	inc		l			; $5ebc: $2c 
	inc		l			; $5ebd: $2c 
	ld		a, (hl)			; $5ebe: $7e 
	inc		a			; $5ebf: $3c 
	ldi		(hl), a			; $5ec0: $22 
	inc		l			; $5ec1: $2c 
	inc		l			; $5ec2: $2c 
	inc		l			; $5ec3: $2c 
	ld		a, (hl)			; $5ec4: $7e 
	inc		a			; $5ec5: $3c 
	ld		(hl), a			; $5ec6: $77 
	ld		a, ($da20)		; $5ec7: $fa $20 $da 
	inc		a			; $5eca: $3c 
	ld		($da20), a		; $5ecb: $ea $20 $da 
	cp		$05			; $5ece: $fe $05 
	ret		nz			; $5ed0: $c0 
	ld		hl, $dfe0		; $5ed1: $21 $e0 $df 
	ld		a, $02			; $5ed4: $3e $02 
	ld		($da21), a		; $5ed6: $ea $21 $da 
	ret					; $5ed9: $c9 

	ld		a, (hl)			; $5eda: $7e 
	inc		a			; $5edb: $3c 
	ldi		(hl), a			; $5edc: $22 
	inc		l			; $5edd: $2c 
	xor		a			; $5ede: $af 
	ld		b, a			; $5edf: $47 
	ldh		a, ($99)		; $5ee0: $f0 $99 
	cp		$02			; $5ee2: $fe $02 
	jr		nz, $04			; $5ee4: $20 $04 
	ld		a, b			; $5ee6: $78 
	add		$20			; $5ee7: $c6 $20 
	ld		b, a			; $5ee9: $47 
	ld		a, b			; $5eea: $78 
	ldi		(hl), a			; $5eeb: $22 
	inc		l			; $5eec: $2c 
	ld		a, (hl)			; $5eed: $7e 
	inc		a			; $5eee: $3c 
	ldi		(hl), a			; $5eef: $22 
	inc		l			; $5ef0: $2c 
	ld		a, b			; $5ef1: $78 
	inc		a			; $5ef2: $3c 
	ldi		(hl), a			; $5ef3: $22 
	inc		l			; $5ef4: $2c 
	ld		a, (hl)			; $5ef5: $7e 
	inc		a			; $5ef6: $3c 
	ldi		(hl), a			; $5ef7: $22 
	inc		l			; $5ef8: $2c 
	ld		a, b			; $5ef9: $78 
	add		$10			; $5efa: $c6 $10 
	ld		b, a			; $5efc: $47 
	ldi		(hl), a			; $5efd: $22 
	inc		l			; $5efe: $2c 
	ld		a, (hl)			; $5eff: $7e 
	inc		a			; $5f00: $3c 
	ldi		(hl), a			; $5f01: $22 
	inc		l			; $5f02: $2c 
	ld		a, b			; $5f03: $78 
	inc		a			; $5f04: $3c 
	ld		(hl), a			; $5f05: $77 
	xor		a			; $5f06: $af 
	ld		($da20), a		; $5f07: $ea $20 $da 
	ld		($da21), a		; $5f0a: $ea $21 $da 
	ld		a, ($da17)		; $5f0d: $fa $17 $da 
	dec		a			; $5f10: $3d 
	ld		($da17), a		; $5f11: $ea $17 $da 
	ret					; $5f14: $c9 
; end routine

; data?
; map data! this has the maps in the game
.incbin "maps.map"
; end data?

.org $391a

; title tile data
TITLE_CHR:
.incbin "title.chr"
TITLE_CHR_END:

; title background tile data
TITLE_BG_CHR:
.incbin "title_bg.chr"
TITLE_BG_CHR_END:

.bank 3 slot 1
.org $0

; straight away looks like data

	ccf					; $4000: $3f 
	ld		d, b			; $4001: $50 
	ld		(hl), h			; $4002: $74 
	ld		d, b			; $4003: $50 
	sbc		e			; $4004: $9b 
	ld		d, b			; $4005: $50 
	ccf					; $4006: $3f 
	ld		d, b			; $4007: $50 
	ld		(hl), h			; $4008: $74 
	ld		d, b			; $4009: $50 
	sbc		e			; $400a: $9b 
	ld		d, b			; $400b: $50 
	ccf					; $400c: $3f 
	ld		d, b			; $400d: $50 
	ld		(hl), h			; $400e: $74 
	ld		d, b			; $400f: $50 
	sbc		e			; $4010: $9b 
	ld		d, b			; $4011: $50 
	ccf					; $4012: $3f 
	ld		d, b			; $4013: $50 
	ld		(hl), h			; $4014: $74 
	ld		d, b			; $4015: $50 
	sbc		e			; $4016: $9b 
	ld		d, b			; $4017: $50 
	ret		nz			; $4018: $c0 
	ld		d, b			; $4019: $50 
	ld		(hl), h			; $401a: $74 
	ld		c, (hl)			; $401b: $4e 
	dec		e			; $401c: $1d 
	ld		c, a			; $401d: $4f 
	ret		c			; $401e: $d8 
	ld		c, a			; $401f: $4f 
	ld		(hl), h			; $4020: $74 
	ld		c, (hl)			; $4021: $4e 
	dec		e			; $4022: $1d 
	ld		c, a			; $4023: $4f 
	ret		c			; $4024: $d8 
	ld		c, a			; $4025: $4f 
	ld		(hl), h			; $4026: $74 
	ld		c, (hl)			; $4027: $4e 
	dec		e			; $4028: $1d 
	ld		c, a			; $4029: $4f 
	ret		c			; $402a: $d8 
	ld		c, a			; $402b: $4f 
	ld		(hl), h			; $402c: $74 
	ld		c, (hl)			; $402d: $4e 
	dec		e			; $402e: $1d 
	ld		c, a			; $402f: $4f 
	ret		c			; $4030: $d8 
	ld		c, a			; $4031: $4f 
	nop					; $4032: $00 
	nop					; $4033: $00 
	nop					; $4034: $00 
	nop					; $4035: $00 
	nop					; $4036: $00 
	nop					; $4037: $00 
	nop					; $4038: $00 
	nop					; $4039: $00 
	inc		e			; $403a: $1c 
	inc		e			; $403b: $1c 
	ld		a, $22			; $403c: $3e $22 
	ccf					; $403e: $3f 
	dec		sp			; $403f: $3b 
	ld		a, a			; $4040: $7f 
	ld		b, a			; $4041: $47 
	nop					; $4042: $00 
	nop					; $4043: $00 
	nop					; $4044: $00 
	nop					; $4045: $00 
	nop					; $4046: $00 
	nop					; $4047: $00 
	nop					; $4048: $00 
	nop					; $4049: $00 
	jr		c, $38			; $404a: $38 $38 
	ld		a, h			; $404c: $7c 
	ld		b, h			; $404d: $44 
.db $fc
	call		c, $e2fe		; $404f: $dc $fe $e2 
	nop					; $4052: $00 
	nop					; $4053: $00 
	nop					; $4054: $00 
	nop					; $4055: $00 
	jr		$18			; $4056: $18 $18 
	inc		a			; $4058: $3c 
	inc		h			; $4059: $24 
	ld		a, (hl)			; $405a: $7e 
	ld		d, d			; $405b: $52 
	ld		a, a			; $405c: $7f 
	ld		e, e			; $405d: $5b 
	ccf					; $405e: $3f 
	cpl					; $405f: $2f 
	ld		a, l			; $4060: $7d 
	ld		b, l			; $4061: $45 
	nop					; $4062: $00 
	nop					; $4063: $00 
	nop					; $4064: $00 
	nop					; $4065: $00 
	jr		$18			; $4066: $18 $18 
	inc		a			; $4068: $3c 
	inc		h			; $4069: $24 
	ld		a, (hl)			; $406a: $7e 
	ld		c, d			; $406b: $4a 
	cp		$da			; $406c: $fe $da 
.db $fc
.db $f4
	cp		(hl)			; $4070: $be 
	and		d			; $4071: $a2 
	nop					; $4072: $00 
	nop					; $4073: $00 
	ld		bc, $1b01		; $4074: $01 $01 $1b 
	dec		de			; $4077: $1b 
	daa					; $4078: $27 
	daa					; $4079: $27 
	cpl					; $407a: $2f 
	jr		z, $3f			; $407b: $28 $3f 
	jr		nc, $3f			; $407d: $30 $3f 
	jr		nz, $3f			; $407f: $20 $3f 
	ld		a, $f8			; $4081: $3e $f8 
	ld		hl, sp-$14		; $4083: $f8 $ec 
	inc		e			; $4085: $1c 
.db $e4
	call		c, $1ce4		; $4087: $dc $e4 $1c 
.db $e4
	inc		e			; $408b: $1c 
	call		nz, $843c		; $408c: $c4 $3c $84 
	ld		a, h			; $408f: $7c 
	add		h			; $4090: $84 
	ld		a, h			; $4091: $7c 
	nop					; $4092: $00 
	nop					; $4093: $00 
	ld		bc, $0301		; $4094: $01 $01 $03 
	ld		(bc), a			; $4097: $02 
	rlca					; $4098: $07 
	rlca					; $4099: $07 
	rrca					; $409a: $0f 
	ld		c, $1f			; $409b: $0e $1f 
	stop					; $409d: $10 
	ld		a, a			; $409e: $7f 
	ld		a, b			; $409f: $78 
	adc		a			; $40a0: $8f 
	adc		b			; $40a1: $88 
	nop					; $40a2: $00 
	nop					; $40a3: $00 
	ldh		a, ($f0)		; $40a4: $f0 $f0 
	ret		c			; $40a6: $d8 
	jr		c, -$38			; $40a7: $38 $c8 
	cp		b			; $40a9: $b8 
	ret		z			; $40aa: $c8 
	jr		c, -$38			; $40ab: $38 $c8 
	jr		c, -$72			; $40ad: $38 $8e 
	ld		a, (hl)			; $40af: $7e 
	dec		bc			; $40b0: $0b 
	ei					; $40b1: $fb 
	nop					; $40b2: $00 
	nop					; $40b3: $00 
	inc		bc			; $40b4: $03 
	inc		bc			; $40b5: $03 
	rrca					; $40b6: $0f 
	rrca					; $40b7: $0f 
	ld		a, c			; $40b8: $79 
	ld		a, c			; $40b9: $79 
	rst		$38			; $40ba: $ff 
	sbc		a			; $40bb: $9f 
	rst		$38			; $40bc: $ff 
	and		l			; $40bd: $a5 
	rst		$38			; $40be: $ff 
	xor		c			; $40bf: $a9 
	ld		d, (hl)			; $40c0: $56 
	ld		d, (hl)			; $40c1: $56 
	nop					; $40c2: $00 
	nop					; $40c3: $00 
	ret		nz			; $40c4: $c0 
	ret		nz			; $40c5: $c0 
	ldh		a, ($f0)		; $40c6: $f0 $f0 
	sbc		(hl)			; $40c8: $9e 
	sbc		(hl)			; $40c9: $9e 
	rst		$38			; $40ca: $ff 
	ld		sp, hl			; $40cb: $f9 
	rst		$38			; $40cc: $ff 
	and		l			; $40cd: $a5 
	rst		$38			; $40ce: $ff 
	sub		l			; $40cf: $95 
	ld		l, d			; $40d0: $6a 
	ld		l, d			; $40d1: $6a 
	jr		c, $38			; $40d2: $38 $38 
	ld		b, h			; $40d4: $44 
	ld		b, h			; $40d5: $44 
	add		d			; $40d6: $82 
	add		d			; $40d7: $82 
	xor		c			; $40d8: $a9 
	xor		c			; $40d9: $a9 
	xor		d			; $40da: $aa 
	xor		d			; $40db: $aa 
	xor		l			; $40dc: $ad 
	xor		l			; $40dd: $ad 
	or		b			; $40de: $b0 
	or		b			; $40df: $b0 
	ld		b, b			; $40e0: $40 
	ld		b, b			; $40e1: $40 
	nop					; $40e2: $00 
	ld		a, (hl)			; $40e3: $7e 
	nop					; $40e4: $00 
	push		hl			; $40e5: $e5 
	nop					; $40e6: $00 
	rst		$38			; $40e7: $ff 
	ld		a, (hl)			; $40e8: $7e 
	add		c			; $40e9: $81 
	ld		a, (hl)			; $40ea: $7e 
	rst		$20			; $40eb: $e7 
	ld		a, (hl)			; $40ec: $7e 
	rst		$20			; $40ed: $e7 
	jr		-$19			; $40ee: $18 $e7 
	jr		-$19			; $40f0: $18 $e7 
	nop					; $40f2: $00 
	nop					; $40f3: $00 
	nop					; $40f4: $00 
	nop					; $40f5: $00 
	nop					; $40f6: $00 
	nop					; $40f7: $00 
	inc		bc			; $40f8: $03 
	inc		bc			; $40f9: $03 
	inc		c			; $40fa: $0c 
	inc		c			; $40fb: $0c 
	ld		(hl), c			; $40fc: $71 
	ld		(hl), c			; $40fd: $71 
	add		d			; $40fe: $82 
	add		d			; $40ff: $82 
	ld		a, h			; $4100: $7c 
	ld		a, h			; $4101: $7c 
	nop					; $4102: $00 
	ld		a, (hl)			; $4103: $7e 
	ld		h, h			; $4104: $64 
	add		c			; $4105: $81 
	ld		a, (hl)			; $4106: $7e 
	rst		$20			; $4107: $e7 
	jr		-$19			; $4108: $18 $e7 
	jr		-$01			; $410a: $18 $ff 
	ld		a, (hl)			; $410c: $7e 
	add		c			; $410d: $81 
	ld		a, (hl)			; $410e: $7e 
	rst		$38			; $410f: $ff 
	jr		$7e			; $4110: $18 $7e 
	nop					; $4112: $00 
	nop					; $4113: $00 
	ld		a, b			; $4114: $78 
	ld		a, b			; $4115: $78 
	call		nz, $82c4		; $4116: $c4 $c4 $82 
	add		d			; $4119: $82 
	xor		c			; $411a: $a9 
	xor		c			; $411b: $a9 
	ld		(hl), l			; $411c: $75 
	ld		(hl), l			; $411d: $75 
	inc		bc			; $411e: $03 
	inc		bc			; $411f: $03 
	rlca					; $4120: $07 
	rlca					; $4121: $07 
	nop					; $4122: $00 
	nop					; $4123: $00 
	nop					; $4124: $00 
	nop					; $4125: $00 
	nop					; $4126: $00 
	nop					; $4127: $00 
	ld		a, b			; $4128: $78 
	ld		a, b			; $4129: $78 
	adc		h			; $412a: $8c 
	sbc		h			; $412b: $9c 
	ld		h, h			; $412c: $64 
	inc		e			; $412d: $1c 
.db $e4
	call		c, $1ce4		; $412f: $dc $e4 $1c 
	ld		a, a			; $4132: $7f 
	ld		(hl), a			; $4133: $77 
	ld		a, a			; $4134: $7f 
	ld		c, a			; $4135: $4f 
	rst		$38			; $4136: $ff 
	add		a			; $4137: $87 
	rst		$38			; $4138: $ff 
	or		l			; $4139: $b5 
	rst		$28			; $413a: $ef 
	xor		l			; $413b: $ad 
	rst		$20			; $413c: $e7 
	and		l			; $413d: $a5 
	ld		b, e			; $413e: $43 
	ld		b, d			; $413f: $42 
	ld		bc, $fe01		; $4140: $01 $01 $fe 
	xor		$fe			; $4143: $ee $fe 
	ld		a, ($ff00+c)		; $4145: $f2 
	rst		$38			; $4146: $ff 
	pop		hl			; $4147: $e1 
	rst		$38			; $4148: $ff 
	xor		l			; $4149: $ad 
	rst		$30			; $414a: $f7 
	or		l			; $414b: $b5 
	rst		$20			; $414c: $e7 
	and		l			; $414d: $a5 
	jp		nz, $8042		; $414e: $c2 $42 $80 
	add		b			; $4151: $80 
	ld		a, l			; $4152: $7d 
	ld		d, l			; $4153: $55 
	ld		a, a			; $4154: $7f 
	ld		e, a			; $4155: $5f 
	ccf					; $4156: $3f 
	add		hl, hl			; $4157: $29 
	ld		a, a			; $4158: $7f 
	ld		c, e			; $4159: $4b 
	ld		a, (hl)			; $415a: $7e 
	ld		e, d			; $415b: $5a 
	cp		$9a			; $415c: $fe $9a 
.db $e4
	and		h			; $415f: $a4 
	ld		b, b			; $4160: $40 
	ld		b, b			; $4161: $40 
	cp		(hl)			; $4162: $be 
	xor		d			; $4163: $aa 
	cp		$fa			; $4164: $fe $fa 
.db $fc
	sub		h			; $4167: $94 
	cp		$d2			; $4168: $fe $d2 
	ld		a, (hl)			; $416a: $7e 
	ld		e, d			; $416b: $5a 
	ld		a, a			; $416c: $7f 
	ld		e, c			; $416d: $59 
	daa					; $416e: $27 
	dec		h			; $416f: $25 
	ld		(bc), a			; $4170: $02 
	ld		(bc), a			; $4171: $02 
	rrca					; $4172: $0f 
	ld		($101f), sp		; $4173: $08 $1f $10 
	rra					; $4176: $1f 
	jr		$07			; $4177: $18 $07 
	inc		b			; $4179: $04 
	ld		e, $19			; $417a: $1e $19 
	inc		e			; $417c: $1c 
	inc		de			; $417d: $13 
	rrca					; $417e: $0f 
	rrca					; $417f: $0f 
	nop					; $4180: $00 
	nop					; $4181: $00 
.db $fc
	ld		a, h			; $4183: $7c 
	cp		$0e			; $4184: $fe $0e 
	jp		nz, $31c2		; $4186: $c2 $c2 $31 
	pop		af			; $4189: $f1 
	ld		hl, $61e1		; $418a: $21 $e1 $61 
	pop		hl			; $418d: $e1 
	xor		e			; $418e: $ab 
	xor		e			; $418f: $ab 
	ld		a, $3e			; $4190: $3e $3e 
	rst		$8			; $4192: $cf 
	call		z, $8c8f		; $4193: $cc $8f $8c 
	ld		b, a			; $4196: $47 
	ld		b, a			; $4197: $47 
	ld		h, b			; $4198: $60 
	ld		h, b			; $4199: $60 
	ccf					; $419a: $3f 
	ccf					; $419b: $3f 
	inc		a			; $419c: $3c 
	inc		sp			; $419d: $33 
	jr		c, $27			; $419e: $38 $27 
	rra					; $41a0: $1f 
	rra					; $41a1: $1f 
	add		hl, bc			; $41a2: $09 
	ld		sp, hl			; $41a3: $f9 
	sbc		c			; $41a4: $99 
	ld		sp, hl			; $41a5: $f9 
	cp		$9e			; $41a6: $fe $9e 
	stop					; $41a8: $10 
	stop					; $41a9: $10 
	ldh		a, ($f0)		; $41aa: $f0 $f0 
	ld		h, b			; $41ac: $60 
	ldh		($c0), a		; $41ad: $e0 $c0 
	ret		nz			; $41af: $c0 
	add		b			; $41b0: $80 
	add		b			; $41b1: $80 
	ld		bc, $0701		; $41b2: $01 $01 $07 
	rlca					; $41b5: $07 
	rra					; $41b6: $1f 
	rra					; $41b7: $1f 
	ld		a, a			; $41b8: $7f 
	ld		h, b			; $41b9: $60 
	rst		$38			; $41ba: $ff 
	add		b			; $41bb: $80 
	rst		$38			; $41bc: $ff 
.db $fc
	rra					; $41be: $1f 
	stop					; $41bf: $10 
	rra					; $41c0: $1f 
	rra					; $41c1: $1f 
.db $fc
.db $fc
	cp		$06			; $41c4: $fe $06 
	ld		a, ($f2c6)		; $41c6: $fa $c6 $f2 
	ld		c, $f2			; $41c9: $0e $f2 
	ld		c, $f3			; $41cb: $0e $f3 
	rrca					; $41cd: $0f 
	pop		hl			; $41ce: $e1 
	rra					; $41cf: $1f 
	rst		$38			; $41d0: $ff 
	rst		$38			; $41d1: $ff 
	nop					; $41d2: $00 
	nop					; $41d3: $00 
	jr		c, $38			; $41d4: $38 $38 
	ld		b, (hl)			; $41d6: $46 
	ld		b, (hl)			; $41d7: $46 
	add		c			; $41d8: $81 
	add		c			; $41d9: $81 
	sub		h			; $41da: $94 
	sub		h			; $41db: $94 
	xor		e			; $41dc: $ab 
	xor		e			; $41dd: $ab 
	ld		b, b			; $41de: $40 
	ld		b, b			; $41df: $40 
	nop					; $41e0: $00 
	nop					; $41e1: $00 
	jr		-$01			; $41e2: $18 $ff 
	jr		-$01			; $41e4: $18 $ff 
	ld		a, (hl)			; $41e6: $7e 
	add		c			; $41e7: $81 
	ld		a, (hl)			; $41e8: $7e 
	rst		$38			; $41e9: $ff 
	jr		-$01			; $41ea: $18 $ff 
	add		c			; $41ec: $81 
	rst		$38			; $41ed: $ff 
	ld		a, (hl)			; $41ee: $7e 
	ld		a, (hl)			; $41ef: $7e 
	ld		a, (hl)			; $41f0: $7e 
	ld		a, (hl)			; $41f1: $7e 
	nop					; $41f2: $00 
	nop					; $41f3: $00 
	nop					; $41f4: $00 
	nop					; $41f5: $00 
	nop					; $41f6: $00 
	nop					; $41f7: $00 
	ld		bc, $0101		; $41f8: $01 $01 $01 
	ld		bc, $0303		; $41fb: $01 $03 $03 
	rlca					; $41fe: $07 
	rlca					; $41ff: $07 
	rrca					; $4200: $0f 
	ld		($0000), sp		; $4201: $08 $00 $00 
	ld		e, $1e			; $4204: $1e $1e 
	ld		a, c			; $4206: $79 
	ld		a, c			; $4207: $79 
	adc		l			; $4208: $8d 
	sbc		l			; $4209: $9d 
	ld		h, l			; $420a: $65 
	dec		e			; $420b: $1d 
	and		$de			; $420c: $e6 $de 
.db $e4
	inc		e			; $420f: $1c 
.db $e4
	inc		e			; $4211: $1c 
	rrca					; $4212: $0f 
	ld		($101f), sp		; $4213: $08 $1f $10 
	ccf					; $4216: $3f 
	ld		hl, $3e3f		; $4217: $21 $3f $3e 
	rra					; $421a: $1f 
	stop					; $421b: $10 
	ccf					; $421c: $3f 
	jr		nz, $3f			; $421d: $20 $3f 
	inc		a			; $421f: $3c 
	rlca					; $4220: $07 
	inc		b			; $4221: $04 
.db $e4
	inc		e			; $4223: $1c 
	call		nz, $c43c		; $4224: $c4 $3c $c4 
	inc		a			; $4227: $3c 
	add		h			; $4228: $84 
	ld		a, h			; $4229: $7c 
.db $fc
	ld		a, h			; $422b: $7c 
	cp		$0e			; $422c: $fe $0e 
	jp		nz, $b142		; $422e: $c2 $42 $b1 
	ld		(hl), c			; $4231: $71 
	nop					; $4232: $00 
	nop					; $4233: $00 
	nop					; $4234: $00 
	nop					; $4235: $00 
	nop					; $4236: $00 
	nop					; $4237: $00 
	nop					; $4238: $00 
	nop					; $4239: $00 
	nop					; $423a: $00 
	nop					; $423b: $00 
	nop					; $423c: $00 
	nop					; $423d: $00 
	nop					; $423e: $00 
	nop					; $423f: $00 
	nop					; $4240: $00 
	nop					; $4241: $00 
	nop					; $4242: $00 
	nop					; $4243: $00 
	nop					; $4244: $00 
	nop					; $4245: $00 
	nop					; $4246: $00 
	nop					; $4247: $00 
	nop					; $4248: $00 
	nop					; $4249: $00 
	nop					; $424a: $00 
	nop					; $424b: $00 
	nop					; $424c: $00 
	nop					; $424d: $00 
	nop					; $424e: $00 
	nop					; $424f: $00 
	nop					; $4250: $00 
	nop					; $4251: $00 
	nop					; $4252: $00 
	nop					; $4253: $00 
	rlca					; $4254: $07 
	rlca					; $4255: $07 
	rra					; $4256: $1f 
	inc		e			; $4257: $1c 
	rra					; $4258: $1f 
	stop					; $4259: $10 
	ld		a, $31			; $425a: $3e $31 
	ld		a, b			; $425c: $78 
	ld		h, a			; $425d: $67 
	ld		sp, hl			; $425e: $f9 
	add		$f3			; $425f: $c6 $f3 
	adc		h			; $4261: $8c 
	nop					; $4262: $00 
	nop					; $4263: $00 
	ldh		a, ($f0)		; $4264: $f0 $f0 
.db $fc
	inc		e			; $4267: $1c 
	or		$0e			; $4268: $f6 $0e 
	ldd		a, (hl)			; $426a: $3a 
	add		$3a			; $426b: $c6 $3a 
	add		$7b			; $426d: $c6 $7b 
	add		a			; $426f: $87 
	ld		a, e			; $4270: $7b 
	add		a			; $4271: $87 
	ld		b, c			; $4272: $41 
	ld		b, c			; $4273: $41 
	ld		hl, $1222		; $4274: $21 $22 $12 
	inc		d			; $4277: $14 
	dec		c			; $4278: $0d 
	ld		c, $96			; $4279: $0e $96 
	sbc		b			; $427b: $98 
	ld		e, l			; $427c: $5d 
	ld		e, (hl)			; $427d: $5e 
	ld		h, $38			; $427e: $26 $38 
	dec		e			; $4280: $1d 
	ld		e, $04			; $4281: $1e $04 
	inc		b			; $4283: $04 
	ld		($9088), sp		; $4284: $08 $88 $90 
	ld		d, b			; $4287: $50 
	ld		h, b			; $4288: $60 
	ldh		($d2), a		; $4289: $e0 $d2 
	ldd		(hl), a			; $428b: $32 
	ld		(hl), h			; $428c: $74 
.db $f4
	ret		z			; $428e: $c8 
	jr		c, $70			; $428f: $38 $70 
	ldh		a, ($21)		; $4291: $f0 $21 
	ldi		(hl), a			; $4293: $22 
	ldi		(hl), a			; $4294: $22 
	inc		h			; $4295: $24 
	dec		l			; $4296: $2d 
	ld		l, $96			; $4297: $2e $96 
	sbc		b			; $4299: $98 
	sbc		l			; $429a: $9d 
	sbc		(hl)			; $429b: $9e 
	ld		h, (hl)			; $429c: $66 
	ld		a, b			; $429d: $78 
	dec		e			; $429e: $1d 
	ld		e, $62			; $429f: $1e $62 
	ld		l, h			; $42a1: $6c 
	ld		($8888), sp		; $42a2: $08 $88 $88 
	ld		c, b			; $42a5: $48 
	ld		l, b			; $42a6: $68 
	add		sp, -$2e			; $42a7: $e8 $d2 
	ldd		(hl), a			; $42a9: $32 
	ld		(hl), d			; $42aa: $72 
	ld		a, ($ff00+c)		; $42ab: $f2 
	call		z, $703c		; $42ac: $cc $3c $70 
	ldh		a, ($8c)		; $42af: $f0 $8c 
	ld		l, h			; $42b1: $6c 
	nop					; $42b2: $00 
	nop					; $42b3: $00 
	nop					; $42b4: $00 
	nop					; $42b5: $00 
	nop					; $42b6: $00 
	nop					; $42b7: $00 
	nop					; $42b8: $00 
	nop					; $42b9: $00 
	nop					; $42ba: $00 
	nop					; $42bb: $00 
	nop					; $42bc: $00 
	nop					; $42bd: $00 
	nop					; $42be: $00 
	nop					; $42bf: $00 
	nop					; $42c0: $00 
	nop					; $42c1: $00 
	nop					; $42c2: $00 
	nop					; $42c3: $00 
	nop					; $42c4: $00 
	nop					; $42c5: $00 
	nop					; $42c6: $00 
	nop					; $42c7: $00 
	nop					; $42c8: $00 
	nop					; $42c9: $00 
	nop					; $42ca: $00 
	nop					; $42cb: $00 
	nop					; $42cc: $00 
	nop					; $42cd: $00 
	nop					; $42ce: $00 
	nop					; $42cf: $00 
	nop					; $42d0: $00 
	nop					; $42d1: $00 
	add		b			; $42d2: $80 
	add		b			; $42d3: $80 
	add		e			; $42d4: $83 
	add		e			; $42d5: $83 
	add		(hl)			; $42d6: $86 
	add		(hl)			; $42d7: $86 
	ld		c, d			; $42d8: $4a 
	ld		c, d			; $42d9: $4a 
	ld		(hl), c			; $42da: $71 
	ld		(hl), c			; $42db: $71 
	ld		(bc), a			; $42dc: $02 
	ld		(bc), a			; $42dd: $02 
	ld		(bc), a			; $42de: $02 
	ld		(bc), a			; $42df: $02 
	inc		bc			; $42e0: $03 
	inc		bc			; $42e1: $03 
	ld		(hl), b			; $42e2: $70 
	ld		(hl), b			; $42e3: $70 
	ret		nc			; $42e4: $d0 
	ret		nc			; $42e5: $d0 
	stop					; $42e6: $10 
	stop					; $42e7: $10 
	ld		($8808), sp		; $42e8: $08 $08 $88 
	adc		b			; $42eb: $88 
	ld		($0808), sp		; $42ec: $08 $08 $08 
	ld		($f0f0), sp		; $42ef: $08 $f0 $f0 
	rra					; $42f2: $1f 
	stop					; $42f3: $10 
	ccf					; $42f4: $3f 
	ld		hl, $3e3f		; $42f5: $21 $3f $3e 
	rrca					; $42f8: $0f 
	dec		bc			; $42f9: $0b 
	inc		e			; $42fa: $1c 
	inc		d			; $42fb: $14 
	inc		e			; $42fc: $1c 
	inc		d			; $42fd: $14 
	ld		a, (hl)			; $42fe: $7e 
	ld		a, (hl)			; $42ff: $7e 
	sub		c			; $4300: $91 
	sub		c			; $4301: $91 
.db $e4
	inc		e			; $4303: $1c 
	call		nz, $8c3c		; $4304: $c4 $3c $8c 
	ld		a, h			; $4307: $7c 
	xor		b			; $4308: $a8 
	ld		l, b			; $4309: $68 
	ret		z			; $430a: $c8 
	ret		z			; $430b: $c8 
	jr		$18			; $430c: $18 $18 
	ld		(hl), b			; $430e: $70 
	ld		(hl), b			; $430f: $70 
	and		b			; $4310: $a0 
	ldh		($3e), a		; $4311: $e0 $3e 
	ldd		a, (hl)			; $4313: $3a 
	inc		a			; $4314: $3c 
	inc		(hl)			; $4315: $34 
	jr		$18			; $4316: $18 $18 
	ld		($0c08), sp		; $4318: $08 $08 $0c 
	inc		c			; $431b: $0c 
	stop					; $431c: $10 
	stop					; $431d: $10 
	stop					; $431e: $10 
	stop					; $431f: $10 
	rra					; $4320: $1f 
	rra					; $4321: $1f 
	ld		hl, $2161		; $4322: $21 $61 $21 
	ld		hl, $6b6b		; $4325: $21 $6b $6b 
	rst		$38			; $4328: $ff 
	rst		$38			; $4329: $ff 
	pop		hl			; $432a: $e1 
	pop		hl			; $432b: $e1 
	ld		e, c			; $432c: $59 
	ld		e, c			; $432d: $59 
	ld		b, a			; $432e: $47 
	ld		b, a			; $432f: $47 
	add		b			; $4330: $80 
	add		b			; $4331: $80 
	nop					; $4332: $00 
	nop					; $4333: $00 
	nop					; $4334: $00 
	nop					; $4335: $00 
	nop					; $4336: $00 
	nop					; $4337: $00 
	nop					; $4338: $00 
	nop					; $4339: $00 
	nop					; $433a: $00 
	nop					; $433b: $00 
	nop					; $433c: $00 
	nop					; $433d: $00 
	nop					; $433e: $00 
	nop					; $433f: $00 
	nop					; $4340: $00 
	nop					; $4341: $00 
	nop					; $4342: $00 
	nop					; $4343: $00 
	nop					; $4344: $00 
	nop					; $4345: $00 
	nop					; $4346: $00 
	nop					; $4347: $00 
	nop					; $4348: $00 
	nop					; $4349: $00 
	nop					; $434a: $00 
	nop					; $434b: $00 
	nop					; $434c: $00 
	nop					; $434d: $00 
	nop					; $434e: $00 
	nop					; $434f: $00 
	nop					; $4350: $00 
	nop					; $4351: $00 
	ld		a, ($ff00+c)		; $4352: $f2 
	adc		l			; $4353: $8d 
	di					; $4354: $f3 
	adc		h			; $4355: $8c 
.db $fd
	jp		nz, $407f		; $4357: $c2 $7f $40 
	ld		a, a			; $435a: $7f 
	ld		b, b			; $435b: $40 
	dec		a			; $435c: $3d 
	ldi		(hl), a			; $435d: $22 
	ld		sp, $1f3f		; $435e: $31 $3f $1f 
	rra					; $4361: $1f 
	di					; $4362: $f3 
	rrca					; $4363: $0f 
	ld		($ff00+c), a		; $4364: $e2 
	ld		e, $f2			; $4365: $1e $f2 
	ld		e, $f6			; $4367: $1e $f6 
	ld		e, $c6			; $4369: $1e $c6 
	ld		a, $8e			; $436b: $3e $8e 
	cp		$3c			; $436d: $fe $3c 
.db $fc
	ldh		a, ($f0)		; $4370: $f0 $f0 
	ldi		(hl), a			; $4372: $22 
	inc		l			; $4373: $2c 
	ld		c, a			; $4374: $4f 
	ld		c, a			; $4375: $4f 
	sub		a			; $4376: $97 
	sub		a			; $4377: $97 
	add		hl, hl			; $4378: $29 
	add		hl, hl			; $4379: $29 
	ld		c, d			; $437a: $4a 
	ld		c, d			; $437b: $4a 
	add		a			; $437c: $87 
	add		a			; $437d: $87 
	adc		h			; $437e: $8c 
	adc		h			; $437f: $8c 
	ld		b, h			; $4380: $44 
	ld		b, h			; $4381: $44 
	adc		b			; $4382: $88 
	ld		l, b			; $4383: $68 
.db $e4
.db $e4
	jp		nc, $28d2		; $4386: $d2 $d2 $28 
	jr		z, -$5c			; $4389: $28 $a4 
	and		h			; $438b: $a4 
	jp		nz, $62c2		; $438c: $c2 $c2 $62 
	ld		h, d			; $438f: $62 
	ld		b, h			; $4390: $44 
	ld		b, h			; $4391: $44 
	adc		a			; $4392: $8f 
	adc		a			; $4393: $8f 
	scf					; $4394: $37 
	scf					; $4395: $37 
	ld		c, c			; $4396: $49 
	ld		c, c			; $4397: $49 
	ld		c, d			; $4398: $4a 
	ld		c, d			; $4399: $4a 
	ld		b, a			; $439a: $47 
	ld		b, a			; $439b: $47 
	ld		b, (hl)			; $439c: $46 
	ld		b, (hl)			; $439d: $46 
	ldi		(hl), a			; $439e: $22 
	ldi		(hl), a			; $439f: $22 
	nop					; $43a0: $00 
	nop					; $43a1: $00 
	ld		($ff00+c), a		; $43a2: $e2 
	ld		($ff00+c), a		; $43a3: $e2 
	ret		c			; $43a4: $d8 
	ret		c			; $43a5: $d8 
	inc		h			; $43a6: $24 
	inc		h			; $43a7: $24 
	and		h			; $43a8: $a4 
	and		h			; $43a9: $a4 
	call		nz, $c4c4		; $43aa: $c4 $c4 $c4 
	call		nz, $8888		; $43ad: $c4 $88 $88 
	nop					; $43b0: $00 
	nop					; $43b1: $00 
	ld		b, c			; $43b2: $41 
	ld		b, d			; $43b3: $42 
	ld		(hl), $36		; $43b4: $36 $36 
	rlca					; $43b6: $07 
	ld		($7e76), sp		; $43b7: $08 $76 $7e 
	sbc		c			; $43ba: $99 
	sbc		c			; $43bb: $99 
	cpl					; $43bc: $2f 
	cpl					; $43bd: $2f 
	ld		b, h			; $43be: $44 
	ld		b, h			; $43bf: $44 
	ldi		(hl), a			; $43c0: $22 
	ldi		(hl), a			; $43c1: $22 
	inc		b			; $43c2: $04 
	add		h			; $43c3: $84 
	ret		c			; $43c4: $d8 
	ret		c			; $43c5: $d8 
	ret		nz			; $43c6: $c0 
	jr		nz, -$24			; $43c7: $20 $dc 
.db $fc
	ldd		(hl), a			; $43ca: $32 
	ldd		(hl), a			; $43cb: $32 
	add		sp, -$18			; $43cc: $e8 $e8 
	ld		b, h			; $43ce: $44 
	ld		b, h			; $43cf: $44 
	adc		b			; $43d0: $88 
	adc		b			; $43d1: $88 
	nop					; $43d2: $00 
	nop					; $43d3: $00 
	nop					; $43d4: $00 
	nop					; $43d5: $00 
	ld		a, b			; $43d6: $78 
	ld		a, b			; $43d7: $78 
.db $fc
	call		nz, $83e3		; $43d9: $c4 $e3 $83 
.db $fc
	call		nz, $7878		; $43dd: $c4 $78 $78 
	nop					; $43e0: $00 
	nop					; $43e1: $00 
	jp		$3dc3			; $43e2: $c3 $c3 $3d 
	dec		a			; $43e5: $3d 
	jp		$ffc3			; $43e6: $c3 $c3 $ff 
	rst		$38			; $43e9: $ff 
	rst		$38			; $43ea: $ff 
	rst		$38			; $43eb: $ff 
	rst		$28			; $43ec: $ef 
	rst		$20			; $43ed: $e7 
	rst		$38			; $43ee: $ff 
	rst		$38			; $43ef: $ff 
.db $db
.db $db
	inc		a			; $43f2: $3c 
	inc		a			; $43f3: $3c 
	jr		nz, $4e			; $43f4: $20 $4e 
	rst		$38			; $43f6: $ff 
	rst		$38			; $43f7: $ff 
	rst		$38			; $43f8: $ff 
	cp		l			; $43f9: $bd 
	rst		$38			; $43fa: $ff 
	rst		$38			; $43fb: $ff 
	rst		$38			; $43fc: $ff 
	rst		$38			; $43fd: $ff 
	rst		$38			; $43fe: $ff 
	cp		l			; $43ff: $bd 
	rst		$38			; $4400: $ff 
	rst		$38			; $4401: $ff 
	nop					; $4402: $00 
	nop					; $4403: $00 
	nop					; $4404: $00 
	nop					; $4405: $00 
	inc		bc			; $4406: $03 
	inc		bc			; $4407: $03 
	inc		c			; $4408: $0c 
	inc		c			; $4409: $0c 
	stop					; $440a: $10 
	stop					; $440b: $10 
	jr		nz, $20			; $440c: $20 $20 
	jr		nz, $20			; $440e: $20 $20 
	ld		b, b			; $4410: $40 
	ld		b, b			; $4411: $40 
	nop					; $4412: $00 
	nop					; $4413: $00 
	nop					; $4414: $00 
	nop					; $4415: $00 
	add		b			; $4416: $80 
	add		b			; $4417: $80 
	ld		b, b			; $4418: $40 
	ld		b, b			; $4419: $40 
	inc		h			; $441a: $24 
	inc		h			; $441b: $24 
	ld		a, (de)			; $441c: $1a 
	ld		a, (de)			; $441d: $1a 
	ld		bc, $0601		; $441e: $01 $01 $06 
	nop					; $4421: $00 
	nop					; $4422: $00 
	nop					; $4423: $00 
	nop					; $4424: $00 
	nop					; $4425: $00 
	nop					; $4426: $00 
	nop					; $4427: $00 
	nop					; $4428: $00 
	nop					; $4429: $00 
	nop					; $442a: $00 
	nop					; $442b: $00 
	nop					; $442c: $00 
	nop					; $442d: $00 
	add		b			; $442e: $80 
	add		b			; $442f: $80 
	ld		b, b			; $4430: $40 
	ld		b, b			; $4431: $40 
	ld		bc, $0201		; $4432: $01 $01 $02 
	ld		(bc), a			; $4435: $02 
	inc		b			; $4436: $04 
	inc		b			; $4437: $04 
	rrca					; $4438: $0f 
	ld		($0407), sp		; $4439: $08 $07 $04 
	inc		bc			; $443c: $03 
	ld		(bc), a			; $443d: $02 
	ld		bc, $0001		; $443e: $01 $01 $00 
	nop					; $4441: $00 
	add		b			; $4442: $80 
	add		b			; $4443: $80 
	nop					; $4444: $00 
	nop					; $4445: $00 
	pop		bc			; $4446: $c1 
	nop					; $4447: $00 
	rst		$30			; $4448: $f7 
	nop					; $4449: $00 
	rst		$38			; $444a: $ff 
	nop					; $444b: $00 
	rst		$38			; $444c: $ff 
	ld		b, b			; $444d: $40 
	rst		$38			; $444e: $ff 
.db $e3
	ld		a, $3e			; $4450: $3e $3e 
	inc		de			; $4452: $13 
	nop					; $4453: $00 
	sbc		c			; $4454: $99 
	nop					; $4455: $00 
	pop		bc			; $4456: $c1 
	nop					; $4457: $00 
.db $e3
	nop					; $4459: $00 
	rst		$38			; $445a: $ff 
	nop					; $445b: $00 
	rst		$38			; $445c: $ff 
	add		b			; $445d: $80 
	ld		a, a			; $445e: $7f 
	ld		b, c			; $445f: $41 
	ld		a, $3e			; $4460: $3e $3e 
	ld		b, b			; $4462: $40 
	ld		b, b			; $4463: $40 
	and		b			; $4464: $a0 
	jr		nz, -$20			; $4465: $20 $e0 
	jr		nz, -$40			; $4467: $20 $c0 
	ld		b, b			; $4469: $40 
	ret		nz			; $446a: $c0 
	ld		b, b			; $446b: $40 
	add		b			; $446c: $80 
	add		b			; $446d: $80 
	nop					; $446e: $00 
	nop					; $446f: $00 
	nop					; $4470: $00 
	nop					; $4471: $00 
	nop					; $4472: $00 
	nop					; $4473: $00 
	nop					; $4474: $00 
	nop					; $4475: $00 
	nop					; $4476: $00 
	ld		bc, $0200		; $4477: $01 $00 $02 
	nop					; $447a: $00 
	inc		bc			; $447b: $03 
	nop					; $447c: $00 
	rlca					; $447d: $07 
	nop					; $447e: $00 
	rrca					; $447f: $0f 
	nop					; $4480: $00 
	ldd		(hl), a			; $4481: $32 
	nop					; $4482: $00 
	ld		a, b			; $4483: $78 
	nop					; $4484: $00 
	add		h			; $4485: $84 
	nop					; $4486: $00 
	ld		(bc), a			; $4487: $02 
	nop					; $4488: $00 
	ld		(bc), a			; $4489: $02 
	nop					; $448a: $00 
	add		d			; $448b: $82 
	nop					; $448c: $00 
	jp		nz, $0400		; $448d: $c2 $00 $04 
	nop					; $4490: $00 
	inc		b			; $4491: $04 
	nop					; $4492: $00 
	nop					; $4493: $00 
	nop					; $4494: $00 
	nop					; $4495: $00 
	nop					; $4496: $00 
	ld		bc, $0200		; $4497: $01 $00 $02 
	nop					; $449a: $00 
	inc		b			; $449b: $04 
	nop					; $449c: $00 
	ld		($1000), sp		; $449d: $08 $00 $10 
	nop					; $44a0: $00 
	jr		nz, $00			; $44a1: $20 $00 
	ld		b, b			; $44a3: $40 
	nop					; $44a4: $00 
	add		b			; $44a5: $80 
	nop					; $44a6: $00 
	ld		(bc), a			; $44a7: $02 
	nop					; $44a8: $00 
	inc		b			; $44a9: $04 
	nop					; $44aa: $00 
	ld		($0800), sp		; $44ab: $08 $00 $08 
	nop					; $44ae: $00 
	nop					; $44af: $00 
	nop					; $44b0: $00 
	stop					; $44b1: $10 
	nop					; $44b2: $00 
	inc		b			; $44b3: $04 
	nop					; $44b4: $00 
	inc		b			; $44b5: $04 
	nop					; $44b6: $00 
	inc		b			; $44b7: $04 
	nop					; $44b8: $00 
	ld		($0800), sp		; $44b9: $08 $00 $08 
	nop					; $44bc: $00 
	ld		($0800), sp		; $44bd: $08 $00 $08 
	nop					; $44c0: $00 
	ld		($2000), sp		; $44c1: $08 $00 $20 
	nop					; $44c4: $00 
	jr		c, $00			; $44c5: $38 $00 
	ld		e, $00			; $44c7: $1e $00 
	rrca					; $44c9: $0f 
	nop					; $44ca: $00 
	ld		b, $00			; $44cb: $06 $00 
	inc		b			; $44cd: $04 
	nop					; $44ce: $00 
	ld		b, $00			; $44cf: $06 $00 
	rlca					; $44d1: $07 
	nop					; $44d2: $00 
	stop					; $44d3: $10 
	nop					; $44d4: $00 
	stop					; $44d5: $10 
	nop					; $44d6: $00 
	nop					; $44d7: $00 
	nop					; $44d8: $00 
	add		b			; $44d9: $80 
	nop					; $44da: $00 
	nop					; $44db: $00 
	nop					; $44dc: $00 
	nop					; $44dd: $00 
	nop					; $44de: $00 
	nop					; $44df: $00 
	nop					; $44e0: $00 
	nop					; $44e1: $00 
	nop					; $44e2: $00 
	ld		($1000), sp		; $44e3: $08 $00 $10 
	nop					; $44e6: $00 
	sub		b			; $44e7: $90 
	nop					; $44e8: $00 
	sub		b			; $44e9: $90 
	nop					; $44ea: $00 
	and		b			; $44eb: $a0 
	nop					; $44ec: $00 
	and		b			; $44ed: $a0 
	nop					; $44ee: $00 
	ldh		($00), a		; $44ef: $e0 $00 
	ld		b, b			; $44f1: $40 
	nop					; $44f2: $00 
	ld		b, $00			; $44f3: $06 $00 
	ld		($0800), sp		; $44f5: $08 $00 $08 
	nop					; $44f8: $00 
	stop					; $44f9: $10 
	nop					; $44fa: $00 
	nop					; $44fb: $00 
	nop					; $44fc: $00 
	ld		hl, $2700		; $44fd: $21 $00 $27 
	nop					; $4500: $00 
	rra					; $4501: $1f 
	nop					; $4502: $00 
	add		b			; $4503: $80 
	nop					; $4504: $00 
	nop					; $4505: $00 
	nop					; $4506: $00 
	nop					; $4507: $00 
	nop					; $4508: $00 
	stop					; $4509: $10 
	nop					; $450a: $00 
	ld		h, b			; $450b: $60 
	nop					; $450c: $00 
	ret		nz			; $450d: $c0 
	nop					; $450e: $00 
	add		d			; $450f: $82 
	nop					; $4510: $00 
	inc		b			; $4511: $04 
	nop					; $4512: $00 
	ld		b, b			; $4513: $40 
	nop					; $4514: $00 
	ld		b, b			; $4515: $40 
	nop					; $4516: $00 
	ld		h, b			; $4517: $60 
	nop					; $4518: $00 
	jr		nz, $00			; $4519: $20 $00 
	jr		nz, $00			; $451b: $20 $00 
	ldh		($00), a		; $451d: $e0 $00 
	stop					; $451f: $10 
	nop					; $4520: $00 
	ld		($0100), sp		; $4521: $08 $00 $01 
	nop					; $4524: $00 
	nop					; $4525: $00 
	nop					; $4526: $00 
	nop					; $4527: $00 
	nop					; $4528: $00 
	nop					; $4529: $00 
	nop					; $452a: $00 
	ld		bc, $0200		; $452b: $01 $00 $02 
	nop					; $452e: $00 
	ld		(bc), a			; $452f: $02 
	nop					; $4530: $00 
	inc		b			; $4531: $04 
	nop					; $4532: $00 
	ld		($8000), sp		; $4533: $08 $00 $80 
	nop					; $4536: $00 
	sub		b			; $4537: $90 
	nop					; $4538: $00 
	ret		nc			; $4539: $d0 
	nop					; $453a: $00 
	stop					; $453b: $10 
	nop					; $453c: $00 
	jr		nz, $00			; $453d: $20 $00 
	jr		nz, $00			; $453f: $20 $00 
	jr		nz, $00			; $4541: $20 $00 
	inc		b			; $4543: $04 
	nop					; $4544: $00 
	inc		b			; $4545: $04 
	nop					; $4546: $00 
	inc		b			; $4547: $04 
	nop					; $4548: $00 
	inc		b			; $4549: $04 
	nop					; $454a: $00 
	ld		(bc), a			; $454b: $02 
	nop					; $454c: $00 
	ld		(bc), a			; $454d: $02 
	nop					; $454e: $00 
	ld		(bc), a			; $454f: $02 
	nop					; $4550: $00 
	ld		(bc), a			; $4551: $02 
	nop					; $4552: $00 
	jr		c, $00			; $4553: $38 $00 
	call		nz, $0100		; $4555: $c4 $00 $01 
	nop					; $4558: $00 
	ld		(bc), a			; $4559: $02 
	nop					; $455a: $00 
	add		e			; $455b: $83 
	nop					; $455c: $00 
	rlca					; $455d: $07 
	nop					; $455e: $00 
	rrca					; $455f: $0f 
	nop					; $4560: $00 
	ldd		(hl), a			; $4561: $32 
	nop					; $4562: $00 
	ld		b, b			; $4563: $40 
	nop					; $4564: $00 
	add		b			; $4565: $80 
	nop					; $4566: $00 
	ld		bc, $0200		; $4567: $01 $00 $02 
	nop					; $456a: $00 
	inc		b			; $456b: $04 
	nop					; $456c: $00 
	ld		($1000), sp		; $456d: $08 $00 $10 
	nop					; $4570: $00 
	jr		nz, -$03			; $4571: $20 $fd 
	ei					; $4573: $fb 
.db $fd
	ei					; $4575: $fb 
.db $fd
	ei					; $4577: $fb 
.db $fd
	ei					; $4579: $fb 
.db $fd
	ei					; $457b: $fb 
.db $fd
	ei					; $457d: $fb 
.db $fd
	ei					; $457f: $fb 
.db $fd
	inc		bc			; $4581: $03 
	nop					; $4582: $00 
	sbc		c			; $4583: $99 
	nop					; $4584: $00 
	sbc		c			; $4585: $99 
	nop					; $4586: $00 
	add		c			; $4587: $81 
	nop					; $4588: $00 
	rst		$38			; $4589: $ff 
	nop					; $458a: $00 
	sbc		c			; $458b: $99 
	nop					; $458c: $00 
	pop		bc			; $458d: $c1 
	nop					; $458e: $00 
	ld		b, d			; $458f: $42 
	nop					; $4590: $00 
	ld		a, (hl)			; $4591: $7e 
	nop					; $4592: $00 
	nop					; $4593: $00 
	nop					; $4594: $00 
	nop					; $4595: $00 
	nop					; $4596: $00 
	nop					; $4597: $00 
	ld		($1c00), sp		; $4598: $08 $00 $1c 
	nop					; $459b: $00 
	ld		(hl), $00		; $459c: $36 $00 
	ld		l, e			; $459e: $6b 
	nop					; $459f: $00 
.db $dd
	nop					; $45a1: $00 
	rst		$38			; $45a2: $ff 
	nop					; $45a3: $00 
	rst		$38			; $45a4: $ff 
	nop					; $45a5: $00 
	cp		$00			; $45a6: $fe $00 
	ld		a, l			; $45a8: $7d 
	nop					; $45a9: $00 
	cp		e			; $45aa: $bb 
	nop					; $45ab: $00 
	rst		$38			; $45ac: $ff 
	nop					; $45ad: $00 
	rst		$38			; $45ae: $ff 
	nop					; $45af: $00 
	rst		$38			; $45b0: $ff 
	nop					; $45b1: $00 
	nop					; $45b2: $00 
	nop					; $45b3: $00 
	nop					; $45b4: $00 
	inc		b			; $45b5: $04 
	nop					; $45b6: $00 
	ld		(bc), a			; $45b7: $02 
	nop					; $45b8: $00 
	ld		(bc), a			; $45b9: $02 
	nop					; $45ba: $00 
	rla					; $45bb: $17 
	nop					; $45bc: $00 
	sub		a			; $45bd: $97 
	ld		(bc), a			; $45be: $02 
	ld		l, l			; $45bf: $6d 
	ld		(bc), a			; $45c0: $02 
	dec		a			; $45c1: $3d 
	nop					; $45c2: $00 
	nop					; $45c3: $00 
	nop					; $45c4: $00 
	nop					; $45c5: $00 
	nop					; $45c6: $00 
	nop					; $45c7: $00 
	nop					; $45c8: $00 
	nop					; $45c9: $00 
	nop					; $45ca: $00 
	jr		nz, $00			; $45cb: $20 $00 
	ld		b, b			; $45cd: $40 
	nop					; $45ce: $00 
	ret		nz			; $45cf: $c0 
	nop					; $45d0: $00 
	and		b			; $45d1: $a0 
	rlca					; $45d2: $07 
	ld		a, b			; $45d3: $78 
	dec		c			; $45d4: $0d 
	ld		(hl), b			; $45d5: $70 
	jr		-$60			; $45d6: $18 $a0 
	jr		$60			; $45d8: $18 $60 
	jr		$60			; $45da: $18 $60 
	add		hl, bc			; $45dc: $09 
	jr		nc, $05			; $45dd: $30 $05 
	jr		$00			; $45df: $18 $00 
	rrca					; $45e1: $0f 
	nop					; $45e2: $00 
	add		sp, -$80			; $45e3: $e8 $80 
	ld		(hl), b			; $45e5: $70 
	add		b			; $45e6: $80 
	ld		(hl), b			; $45e7: $70 
	ret		nz			; $45e8: $c0 
	jr		nc, -$80			; $45e9: $30 $80 
	ld		h, b			; $45eb: $60 
	add		b			; $45ec: $80 
	ld		h, b			; $45ed: $60 
	nop					; $45ee: $00 
	ret		nz			; $45ef: $c0 
	nop					; $45f0: $00 
	nop					; $45f1: $00 
	nop					; $45f2: $00 
	rrca					; $45f3: $0f 
	nop					; $45f4: $00 
	ld		($0800), sp		; $45f5: $08 $00 $08 
	nop					; $45f8: $00 
	rlca					; $45f9: $07 
	nop					; $45fa: $00 
	ld		(bc), a			; $45fb: $02 
	nop					; $45fc: $00 
	ld		bc, $0000		; $45fd: $01 $00 $00 
	nop					; $4600: $00 
	nop					; $4601: $00 
	nop					; $4602: $00 
	rst		$38			; $4603: $ff 
	nop					; $4604: $00 
	nop					; $4605: $00 
	nop					; $4606: $00 
	nop					; $4607: $00 
	nop					; $4608: $00 
	or		a			; $4609: $b7 
	nop					; $460a: $00 
	nop					; $460b: $00 
	nop					; $460c: $00 
	rst		$38			; $460d: $ff 
	nop					; $460e: $00 
	jr		nz, $00			; $460f: $20 $00 
	ld		sp, $fe00		; $4611: $31 $00 $fe 
	nop					; $4614: $00 
	ld		(bc), a			; $4615: $02 
	nop					; $4616: $00 
	ld		(bc), a			; $4617: $02 
	nop					; $4618: $00 
.db $fc
	nop					; $461a: $00 
	ld		($f000), sp		; $461b: $08 $00 $f0 
	nop					; $461e: $00 
	add		b			; $461f: $80 
	nop					; $4620: $00 
	add		b			; $4621: $80 
	nop					; $4622: $00 
	rra					; $4623: $1f 
	nop					; $4624: $00 
	jr		nz, $00			; $4625: $20 $00 
	jr		nz, $00			; $4627: $20 $00 
	jr		nz, $00			; $4629: $20 $00 
	jr		nz, $00			; $462b: $20 $00 
	ld		a, a			; $462d: $7f 
	nop					; $462e: $00 
	add		b			; $462f: $80 
	nop					; $4630: $00 
	rst		$38			; $4631: $ff 
	nop					; $4632: $00 
	nop					; $4633: $00 
	nop					; $4634: $00 
	add		b			; $4635: $80 
	nop					; $4636: $00 
	add		b			; $4637: $80 
	nop					; $4638: $00 
	add		b			; $4639: $80 
	nop					; $463a: $00 
	add		b			; $463b: $80 
	nop					; $463c: $00 
	ret		nz			; $463d: $c0 
	nop					; $463e: $00 
	jr		nz, $00			; $463f: $20 $00 
	ldh		($ff), a		; $4641: $e0 $ff 
	rst		$38			; $4643: $ff 
	rst		$38			; $4644: $ff 
	rst		$38			; $4645: $ff 
	nop					; $4646: $00 
	rst		$38			; $4647: $ff 
	rst		$38			; $4648: $ff 
	nop					; $4649: $00 
	nop					; $464a: $00 
	nop					; $464b: $00 
	rst		$38			; $464c: $ff 
	nop					; $464d: $00 
	nop					; $464e: $00 
	nop					; $464f: $00 
	rst		$38			; $4650: $ff 
	nop					; $4651: $00 
	nop					; $4652: $00 
	add		c			; $4653: $81 
	nop					; $4654: $00 
	ld		b, d			; $4655: $42 
	nop					; $4656: $00 
	inc		h			; $4657: $24 
	nop					; $4658: $00 
	jr		$00			; $4659: $18 $00 
	nop					; $465b: $00 
	nop					; $465c: $00 
	nop					; $465d: $00 
	nop					; $465e: $00 
	nop					; $465f: $00 
	nop					; $4660: $00 
	nop					; $4661: $00 
	nop					; $4662: $00 
	ld		b, d			; $4663: $42 
	nop					; $4664: $00 
	ld		e, d			; $4665: $5a 
	nop					; $4666: $00 
	ld		h, (hl)			; $4667: $66 
	nop					; $4668: $00 
	jp		$8100			; $4669: $c3 $00 $81 
	nop					; $466c: $00 
	rst		$20			; $466d: $e7 
	nop					; $466e: $00 
	rst		$20			; $466f: $e7 
	nop					; $4670: $00 
	sbc		c			; $4671: $99 
	nop					; $4672: $00 
	sbc		c			; $4673: $99 
	nop					; $4674: $00 
	sbc		c			; $4675: $99 
	nop					; $4676: $00 
	cp		l			; $4677: $bd 
	nop					; $4678: $00 
	and		l			; $4679: $a5 
	nop					; $467a: $00 
	sbc		c			; $467b: $99 
	nop					; $467c: $00 
	ld		b, d			; $467d: $42 
	nop					; $467e: $00 
	ld		h, (hl)			; $467f: $66 
	nop					; $4680: $00 
	ld		e, d			; $4681: $5a 
	nop					; $4682: $00 
	inc		de			; $4683: $13 
	nop					; $4684: $00 
	dec		d			; $4685: $15 
	nop					; $4686: $00 
	add		hl, de			; $4687: $19 
	nop					; $4688: $00 
	ld		de, $1100		; $4689: $11 $00 $11 
	nop					; $468c: $00 
	inc		de			; $468d: $13 
	nop					; $468e: $00 
	dec		d			; $468f: $15 
	nop					; $4690: $00 
	add		hl, de			; $4691: $19 
	nop					; $4692: $00 
	jr		c, $00			; $4693: $38 $00 
	ld		b, h			; $4695: $44 
	nop					; $4696: $00 
	add		d			; $4697: $82 
	nop					; $4698: $00 
	xor		c			; $4699: $a9 
	nop					; $469a: $00 
	xor		d			; $469b: $aa 
	nop					; $469c: $00 
	xor		l			; $469d: $ad 
	nop					; $469e: $00 
	or		b			; $469f: $b0 
	nop					; $46a0: $00 
	ld		b, b			; $46a1: $40 
	nop					; $46a2: $00 
	ld		a, (hl)			; $46a3: $7e 
	nop					; $46a4: $00 
	pop		bc			; $46a5: $c1 
	nop					; $46a6: $00 
	add		c			; $46a7: $81 
	nop					; $46a8: $00 
	add		c			; $46a9: $81 
	nop					; $46aa: $00 
	rst		$20			; $46ab: $e7 
	nop					; $46ac: $00 
	rst		$20			; $46ad: $e7 
	nop					; $46ae: $00 
	sbc		c			; $46af: $99 
	nop					; $46b0: $00 
	sbc		c			; $46b1: $99 
	nop					; $46b2: $00 
	inc		e			; $46b3: $1c 
	nop					; $46b4: $00 
	ldi		(hl), a			; $46b5: $22 
	nop					; $46b6: $00 
	ld		b, c			; $46b7: $41 
	nop					; $46b8: $00 
	sub		l			; $46b9: $95 
	nop					; $46ba: $00 
	ld		d, l			; $46bb: $55 
	nop					; $46bc: $00 
	or		l			; $46bd: $b5 
	nop					; $46be: $00 
	dec		c			; $46bf: $0d 
	nop					; $46c0: $00 
	ld		(bc), a			; $46c1: $02 
	nop					; $46c2: $00 
	nop					; $46c3: $00 
	nop					; $46c4: $00 
	add		c			; $46c5: $81 
	nop					; $46c6: $00 
	ld		b, d			; $46c7: $42 
	nop					; $46c8: $00 
	and		l			; $46c9: $a5 
	nop					; $46ca: $00 
	ld		a, (hl)			; $46cb: $7e 
	nop					; $46cc: $00 
	inc		a			; $46cd: $3c 
	nop					; $46ce: $00 
	jr		$00			; $46cf: $18 $00 
	nop					; $46d1: $00 
	nop					; $46d2: $00 
	ld		b, d			; $46d3: $42 
	nop					; $46d4: $00 
	ld		b, (hl)			; $46d5: $46 
	nop					; $46d6: $00 
	ld		b, d			; $46d7: $42 
	nop					; $46d8: $00 
	ld		b, (hl)			; $46d9: $46 
	nop					; $46da: $00 
	ld		b, d			; $46db: $42 
	nop					; $46dc: $00 
	ld		b, (hl)			; $46dd: $46 
	nop					; $46de: $00 
	ld		b, d			; $46df: $42 
	nop					; $46e0: $00 
	inc		a			; $46e1: $3c 
	nop					; $46e2: $00 
	nop					; $46e3: $00 
	nop					; $46e4: $00 
	nop					; $46e5: $00 
	nop					; $46e6: $00 
	nop					; $46e7: $00 
	nop					; $46e8: $00 
	nop					; $46e9: $00 
	nop					; $46ea: $00 
	nop					; $46eb: $00 
	nop					; $46ec: $00 
	nop					; $46ed: $00 
	nop					; $46ee: $00 
	nop					; $46ef: $00 
	nop					; $46f0: $00 
	nop					; $46f1: $00 
	rst		$38			; $46f2: $ff 
	rst		$38			; $46f3: $ff 
	rst		$38			; $46f4: $ff 
	ccf					; $46f5: $3f 
	rst		$38			; $46f6: $ff 
	ld		e, $ff			; $46f7: $1e $ff 
.db $fc
	rst		$38			; $46fa: $ff 
	rst		$38			; $46fb: $ff 
	rst		$38			; $46fc: $ff 
	rst		$38			; $46fd: $ff 
	rst		$38			; $46fe: $ff 
	rst		$8			; $46ff: $cf 
	rst		$38			; $4700: $ff 
	add		a			; $4701: $87 
	rst		$38			; $4702: $ff 
	rst		$38			; $4703: $ff 
	rst		$38			; $4704: $ff 
	rst		$38			; $4705: $ff 
	rst		$38			; $4706: $ff 
	ld		a, (hl)			; $4707: $7e 
	rst		$38			; $4708: $ff 
	ccf					; $4709: $3f 
	rst		$38			; $470a: $ff 
	rst		$38			; $470b: $ff 
	rst		$38			; $470c: $ff 
	di					; $470d: $f3 
	rst		$38			; $470e: $ff 
	pop		hl			; $470f: $e1 
	rst		$38			; $4710: $ff 
	rst		$38			; $4711: $ff 
	ld		a, (hl)			; $4712: $7e 
	ld		a, (hl)			; $4713: $7e 
	rst		$38			; $4714: $ff 
	add		e			; $4715: $83 
	rst		$38			; $4716: $ff 
	cp		e			; $4717: $bb 
	rst		$38			; $4718: $ff 
	and		e			; $4719: $a3 
	rst		$38			; $471a: $ff 
	and		e			; $471b: $a3 
	rst		$38			; $471c: $ff 
	add		a			; $471d: $87 
	rst		$38			; $471e: $ff 
	rst		$38			; $471f: $ff 
	ld		a, (hl)			; $4720: $7e 
	ld		a, (hl)			; $4721: $7e 
	ld		a, (hl)			; $4722: $7e 
	ld		a, (hl)			; $4723: $7e 
.db $fd
	jp		$83fd			; $4725: $c3 $fd $83 
	ei					; $4728: $fb 
	add		a			; $4729: $87 
	rst		$38			; $472a: $ff 
	adc		(hl)			; $472b: $8e 
	xor		b			; $472c: $a8 
	rst		$18			; $472d: $df 
	rst		$18			; $472e: $df 
	rst		$38			; $472f: $ff 
	ld		a, l			; $4730: $7d 
	ld		a, l			; $4731: $7d 
	halt					; $4732: $76 
	halt					; $4733: $76 
	rst		$38			; $4734: $ff 
	set		7, l			; $4735: $cb $fd 
	ld		h, e			; $4737: $63 
.db $fd
	inc		sp			; $4739: $33 
.db $db
	scf					; $473b: $37 
	sub		e			; $473c: $93 
	ld		a, a			; $473d: $7f 
	ld		a, a			; $473e: $7f 
	rst		$38			; $473f: $ff 
	and		$e6			; $4740: $e6 $e6 
	ld		a, a			; $4742: $7f 
	ld		a, a			; $4743: $7f 
	ret		nz			; $4744: $c0 
	ret		nz			; $4745: $c0 
	sbc		a			; $4746: $9f 
	sbc		a			; $4747: $9f 
	cp		e			; $4748: $bb 
	cp		e			; $4749: $bb 
	cp		a			; $474a: $bf 
	cp		a			; $474b: $bf 
	cp		a			; $474c: $bf 
	cp		a			; $474d: $bf 
	or		a			; $474e: $b7 
	or		a			; $474f: $b7 
	cp		a			; $4750: $bf 
	cp		a			; $4751: $bf 
	cp		$fe			; $4752: $fe $fe 
	inc		bc			; $4754: $03 
	inc		bc			; $4755: $03 
.db $fd
.db $fd
	rst		$28			; $4758: $ef 
	rst		$28			; $4759: $ef 
.db $fd
.db $fd
	ld		a, a			; $475c: $7f 
	ld		a, a			; $475d: $7f 
	rst		$38			; $475e: $ff 
	rst		$38			; $475f: $ff 
	ei					; $4760: $fb 
	ei					; $4761: $fb 
	cp		a			; $4762: $bf 
	cp		a			; $4763: $bf 
	cp		l			; $4764: $bd 
	cp		l			; $4765: $bd 
	cp		a			; $4766: $bf 
	cp		a			; $4767: $bf 
	xor		a			; $4768: $af 
	xor		a			; $4769: $af 
	cp		a			; $476a: $bf 
	cp		a			; $476b: $bf 
	cp		(hl)			; $476c: $be 
	cp		(hl)			; $476d: $be 
	rst		$18			; $476e: $df 
	rst		$18			; $476f: $df 
	ld		a, a			; $4770: $7f 
	ld		a, a			; $4771: $7f 
	rst		$38			; $4772: $ff 
	rst		$38			; $4773: $ff 
	rst		$18			; $4774: $df 
	rst		$18			; $4775: $df 
.db $fd
.db $fd
	rst		$38			; $4778: $ff 
	rst		$38			; $4779: $ff 
	rst		$30			; $477a: $f7 
	rst		$30			; $477b: $f7 
	rst		$38			; $477c: $ff 
	rst		$38			; $477d: $ff 
	rst		$38			; $477e: $ff 
	rst		$38			; $477f: $ff 
	cp		$fe			; $4780: $fe $fe 
	rst		$38			; $4782: $ff 
.db $db
	rst		$38			; $4784: $ff 
	adc		c			; $4785: $89 
	rst		$38			; $4786: $ff 
	adc		l			; $4787: $8d 
	rst		$38			; $4788: $ff 
	rst		$18			; $4789: $df 
	ld		a, d			; $478a: $7a 
	ld		e, d			; $478b: $5a 
	ld		(hl), d			; $478c: $72 
	ld		(hl), d			; $478d: $72 
	jr		nc, $30			; $478e: $30 $30 
	jr		nz, $20			; $4790: $20 $20 
	ld		a, (hl)			; $4792: $7e 
	ld		a, (hl)			; $4793: $7e 
	ei					; $4794: $fb 
	rst		$0			; $4795: $c7 
.db $fd
	add		e			; $4797: $83 
.db $fd
	jp		$f3fd			; $4799: $c3 $fd $f3 
.db $fd
	bit		7, c			; $479d: $cb $79 
	ld		c, a			; $479f: $4f 
	cp		$ce			; $47a0: $fe $ce 
	ld		a, ($ff00+c)		; $47a2: $f2 
	adc		(hl)			; $47a3: $8e 
	rst		$20			; $47a4: $e7 
	rst		$18			; $47a5: $df 
	call		$7dff			; $47a6: $cd $ff $7d 
	ld		(hl), e			; $47a9: $73 
	ld		a, (hl)			; $47aa: $7e 
	ld		h, d			; $47ab: $62 
	ld		sp, hl			; $47ac: $f9 
	rst		$0			; $47ad: $c7 
	di					; $47ae: $f3 
	rst		$38			; $47af: $ff 
	ld		a, (hl)			; $47b0: $7e 
	ld		a, (hl)			; $47b1: $7e 
	ld		a, a			; $47b2: $7f 
	ld		a, a			; $47b3: $7f 
	rst		$30			; $47b4: $f7 
	rst		$0			; $47b5: $c7 
	xor		$8e			; $47b6: $ee $8e 
.db $dd
	sbc		h			; $47b9: $9c 
	cp		e			; $47ba: $bb 
	cp		b			; $47bb: $b8 
	or		$f0			; $47bc: $f6 $f0 
	rst		$38			; $47be: $ff 
	rst		$38			; $47bf: $ff 
	ld		a, a			; $47c0: $7f 
	ld		a, a			; $47c1: $7f 
	cp		$fe			; $47c2: $fe $fe 
	ld		l, a			; $47c4: $6f 
	rrca					; $47c5: $0f 
	rst		$18			; $47c6: $df 
	rra					; $47c7: $1f 
	cp		e			; $47c8: $bb 
	dec		sp			; $47c9: $3b 
	ld		(hl), a			; $47ca: $77 
	ld		(hl), e			; $47cb: $73 
	rst		$28			; $47cc: $ef 
	rst		$20			; $47cd: $e7 
	rst		$38			; $47ce: $ff 
	rst		$38			; $47cf: $ff 
	cp		$fe			; $47d0: $fe $fe 
	ld		a, (hl)			; $47d2: $7e 
	ld		a, (hl)			; $47d3: $7e 
	rst		$28			; $47d4: $ef 
	rst		$8			; $47d5: $cf 
	rst		$18			; $47d6: $df 
	sbc		a			; $47d7: $9f 
	cp		e			; $47d8: $bb 
	cp		e			; $47d9: $bb 
	rst		$30			; $47da: $f7 
	di					; $47db: $f3 
	rst		$28			; $47dc: $ef 
	rst		$20			; $47dd: $e7 
	rst		$38			; $47de: $ff 
	rst		$38			; $47df: $ff 
	ld		a, (hl)			; $47e0: $7e 
	ld		a, (hl)			; $47e1: $7e 
	nop					; $47e2: $00 
	nop					; $47e3: $00 
	nop					; $47e4: $00 
	nop					; $47e5: $00 
	nop					; $47e6: $00 
	nop					; $47e7: $00 
	nop					; $47e8: $00 
	nop					; $47e9: $00 
	nop					; $47ea: $00 
	nop					; $47eb: $00 
	nop					; $47ec: $00 
	nop					; $47ed: $00 
	nop					; $47ee: $00 
	nop					; $47ef: $00 
	nop					; $47f0: $00 
	nop					; $47f1: $00 
; end data?

; routine
; looks like it gets joypad input
; input: hram $80 = mask
; output: hram $80 = unmasked button presses
; output: hram $81 = masked button presses
READ_JOYPAD:
	; select the direction keys
	ld		a, $20			; $47f2: $3e $20 
	ldh		(R_P1), a		; $47f4: $e0 $00 
	; read the results
	ldh		a, (R_P1)		; $47f6: $f0 $00 
	ldh		a, (R_P1)		; $47f8: $f0 $00 
	; invert them so 1 = pressed
	cpl					; $47fa: $2f 
	; only care about the button bits
	and		$0f			; $47fb: $e6 $0f 
	; but the direction bits as the high nybble
	swap		a			; $47fd: $cb $37 
	; save on b
	ld		b, a			; $47ff: $47 

	; select the button keys
	ld		a, $10			; $4800: $3e $10 
	ldh		(R_P1), a		; $4802: $e0 $00 
	; read the results
	; (debounching amirite?)
	ldh		a, (R_P1)		; $4804: $f0 $00 
	ldh		a, (R_P1)		; $4806: $f0 $00 
	ldh		a, (R_P1)		; $4808: $f0 $00 
	ldh		a, (R_P1)		; $480a: $f0 $00 
	ldh		a, (R_P1)		; $480c: $f0 $00 
	ldh		a, (R_P1)		; $480e: $f0 $00 
	; invert so 1 = pressed again
	cpl					; $4810: $2f 
	; only care about the button bits
	and		$0f			; $4811: $e6 $0f 
	; and merge it with the direction button bits
	or		b			; $4813: $b0 

	; mask result says
	; if its 0, then the cared about buttons are pressed
	; mask the button presses with hram $80
	ld		c, a			; $4814: $4f 
	ldh		a, ($80)		; $4815: $f0 $80 
	xor		c			; $4817: $a9 
	and		c			; $4818: $a1 
	; and stored the masked result in hram $81
	ldh		($81), a		; $4819: $e0 $81 

	; load back the unmasked
	ld		a, c			; $481b: $79 
	; save it on hram $80
	ldh		($80), a		; $481c: $e0 $80 
	; disable direction and button key reading
	ld		a, $30			; $481e: $3e $30 
	ldh		(R_P1), a		; $4820: $e0 $00 

	; done
	ret					; $4822: $c9 
; end routine

; routine
; takes hl: pointer to first TABLE_1 row
; takes pointer to character entity table
; pose drawing routine
DRAW_CHARACTER_ENTITY:
	; this is checking the first byte of every row starting at hl
	; store hl in hram here
-	ld		a, h			; $4823: $7c 
	ldh		($96), a		; $4824: $e0 $96 
	ld		a, l			; $4826: $7d 
	ldh		($97), a		; $4827: $e0 $97 

	; so basiccally, looking for character entities 0 or 80h
	; skip the rest
	; skip if the first byte of this row is not 0 or $80
	; grab the byte pointed to
	; and use it as a flag for doing this next part
	; that is, skip if 0
	ld		a, (hl)			; $4829: $7e 
	and		a			; $482a: $a7 
	jr		z, +			; $482b: $28 $1d 

	; skip this part also if bit 7 is set
	; also skip entity 80h
	cp		$80			; $482d: $fe $80 
	jr		z, ++			; $482f: $28 $17 

	; here is going to the next row
	; here we prepare to go to the next row
	; grab original hl
--	ldh		a, ($96)		; $4831: $f0 $96 
	ld		h, a			; $4833: $67 
	ldh		a, ($97)		; $4834: $f0 $97 
	ld		l, a			; $4836: $6f 

	; add $10 to hl
	; point to the next row, that is
	ld		de, $0010		; $4837: $11 $10 $00 
	add		hl, de			; $483a: $19 

	; decrement this hram counter var and return if its 0
	; quit if its the end of the amount of rows
	ldh		a, ($8f)		; $483b: $f0 $8f 
	dec		a			; $483d: $3d 
	ldh		($8f), a		; $483e: $e0 $8f 
	ret		z			; $4840: $c8 
	; otherwile go back to the begin of this routine
	; which saves +10 hl, and checks the new byte!
	; do this check for the amount of rows stored in counter var $ff8f
	jr		-			; $4841: $18 $e0 

	; hram(95h) stores the entity for this character row
	; and store a 0 in $95
---	xor		a			; $4843: $af 
	ldh		($95), a		; $4844: $e0 $95 
	; and continue off to the next row
	jr		--			; $4846: $18 $e9 

	; for this hl row that starts with $80 or $0...
	; skip here if $80
	; stores $80 here
++	ldh		($95), a		; $4848: $e0 $95 
	; skip here if 0
	; copy 7 bytes from the hl row to here in hram
+	ld		b, $07			; $484a: $06 $07 
	ld		de, $ff86		; $484c: $11 $86 $ff 
-	ldi		a, (hl)			; $484f: $2a 
	ld		(de), a			; $4850: $12 
	inc		de			; $4851: $13 
	dec		b			; $4852: $05 
	jr		nz, -			; $4853: $20 $fa 

	; grab the 4th byte from that string
	; which points to a WORD!
	; pose?????
	ldh		a, ($89)		; $4855: $f0 $89 
	; point here
	; a series of addresses?
	; i wonder if this is tiles for poses?
	; which point to more addresses? follewed by series of data
	; so this address in rom
	; points to an array of addresses
	; which probably point to a series of tiles for that pose
	ld		hl, $4c37		; $4857: $21 $37 $4c 
	; rotate that byte left?
	; multiply by 2?
	rlca					; $485a: $07 
	; form an offset on de with that 4th byte * 2
	ld		e, a			; $485b: $5f 
	ld		d, $00			; $485c: $16 $00 
	; and add it to hl
	add		hl, de			; $485e: $19 
	; and grab a word the new hl, put on de
	ld		e, (hl)			; $485f: $5e 
	inc		hl			; $4860: $23 
	ld		d, (hl)			; $4861: $56 
	; which is an address
	; and grab whatevers at that address
	ld		a, (de)			; $4862: $1a 
	; and put it on the lower bits of hl
	ld		l, a			; $4863: $6f 
	; go to the next byte and grab it
	inc		de			; $4864: $13 
	ld		a, (de)			; $4865: $1a 
	; and put it on the upper bits
	ld		h, a			; $4866: $67 
	; and next 2 byte grab! and store in hram var
	inc		de			; $4867: $13 
	ld		a, (de)			; $4868: $1a 
	ldh		($90), a		; $4869: $e0 $90 
	inc		de			; $486b: $13 
	ld		a, (de)			; $486c: $1a 
	ldh		($91), a		; $486d: $e0 $91 
	; grab whatever is at the address which was the first word
	; which is another word, address
	ld		e, (hl)			; $486f: $5e 
	inc		hl			; $4870: $23 
	ld		d, (hl)			; $4871: $56 
	; next command
NEXT_CMD:
-	inc		hl			; $4872: $23 
	; copy last byte of original hl row here
	; (unflipped bit 4)
	ldh		a, ($8c)		; $4873: $f0 $8c 
	ldh		($94), a		; $4875: $e0 $94 
	; grab whatever is at that yet another address!!
	ld		a, (hl)			; $4877: $7e 
	; and if its maxed out $ff , go back
	; and thats the end of this row
	cp		$ff			; $4878: $fe $ff 
	jr		z, ---			; $487a: $28 $c7 
	; and skip ahead if its not $fd
	cp		$fd			; $487c: $fe $fd 
	jr		nz, +			; $487e: $20 $0c 
	; $fd goes here
	; copy last byte of original hl row here
	; flip bit 4, and store it back in the place from before
	ldh		a, ($8c)		; $4880: $f0 $8c 
	xor		$10			; $4882: $ee $10 
	ldh		($94), a		; $4884: $e0 $94 
	; then jump back, with next var command
	jr		-			; $4886: $18 $ea 

	; don't know how to get here yet
	; but it goes to the next var
	; after incing the word pointing address
--	inc		de			; $4888: $13 
	inc		de			; $4889: $13 
	jr		-			; $488a: $18 $e6 

	; if its $fe, then inc the word address, skip to the next var
+	cp		$fe			; $488c: $fe $fe 
	jr		z, --			; $488e: $28 $f8 
	; save the var
	; as a new index in the original hl row!! (4th byte)
	ldh		($89), a		; $4890: $e0 $89 
	; and grab the second byte from the hl row
	; and put it on b
	ldh		a, ($87)		; $4892: $f0 $87 
	ld		b, a			; $4894: $47 
	; then load whats pointed to by the latest struct's address
	; and put it on c
	ld		a, (de)			; $4895: $1a 
	ld		c, a			; $4896: $4f 
	; check bit 6 of hl 6th hlrow byte
	ldh		a, ($8b)		; $4897: $f0 $8b 
	bit		6, a			; $4899: $cb $77 
	jr		nz, +			; $489b: $20 $06 

	; if that bit is 0:
	; grab the 2nd var in struct
	ldh		a, ($90)		; $489d: $f0 $90 
	; add hlrow 2nd byte to it
	add		b			; $489f: $80 
	; and also first byte of pointed by latest stuct address
	adc		c			; $48a0: $89 
	jr		++			; $48a1: $18 $0a 

	; if that bit is 1:
	; grab hlrow 2nd byte
+	ld		a, b			; $48a3: $78 
	; savin it
	push		af			; $48a4: $f5 
	; put 2nd var in struct on b
	ldh		a, ($90)		; $48a5: $f0 $90 
	ld		b, a			; $48a7: $47 
	; get a back
	pop		af			; $48a8: $f1 
	; subtract struct var 2
	sub		b			; $48a9: $90 
	; and also first byte of pointed by latest struct address
	sbc		c			; $48aa: $99 
	; and some more
	sbc		$08			; $48ab: $de $08 

	; whew
	; save the result of whichiver of those operations
++	ldh		($93), a		; $48ad: $e0 $93 

	; now look, we're doin the exact same thing
	; this time using bit 5
	; and all the 3 bytes to the right of the previous ones
	; grab 3rd byte of hlrow onto b
	ldh		a, ($88)		; $48af: $f0 $88 
	ld		b, a			; $48b1: $47 
	; grab the second byte pointed to
	; put on c
	; and have de pointing to the next word
	inc		de			; $48b2: $13 
	ld		a, (de)			; $48b3: $1a 
	inc		de			; $48b4: $13 
	ld		c, a			; $48b5: $4f 
	; grab next to last byte of hlrow again
	; and this time checking bit 5!
	ldh		a, ($8b)		; $48b6: $f0 $8b 
	bit		5, a			; $48b8: $cb $6f 
	jr		nz, $06			; $48ba: $20 $06 

	; if its 0:
	ldh		a, ($91)		; $48bc: $f0 $91 
	add		b			; $48be: $80 
	adc		c			; $48bf: $89 
	jr		$0a			; $48c0: $18 $0a 

	; if its 1:
	ld		a, b			; $48c2: $78 
	push		af			; $48c3: $f5 
	ldh		a, ($91)		; $48c4: $f0 $91 
	ld		b, a			; $48c6: $47 
	pop		af			; $48c7: $f1 
	sub		b			; $48c8: $90 
	sbc		c			; $48c9: $99 
	sbc		$08			; $48ca: $de $08 

	; done with whichever of those two operations
	; and storing _this_ result to the left of the other one
	ldh		($92), a		; $48cc: $e0 $92 

	; save whichever cmd we're on
	push		hl			; $48ce: $e5 
	; and load up this address from hram
	ldh		a, ($8d)		; $48cf: $f0 $8d 
	ld		h, a			; $48d1: $67 
	ldh		a, ($8e)		; $48d2: $f0 $8e 
	; and load this var to do with the hlrow
	; if it was set to 0, then skip
	ld		l, a			; $48d4: $6f 
	ldh		a, ($95)		; $48d5: $f0 $95 
	and		a			; $48d7: $a7 
	jr		z, +			; $48d8: $28 $04 
	; not 0? load up $ff instead of the first operations result
	ld		a, $ff			; $48da: $3e $ff 
	jr		++			; $48dc: $18 $02 
	; if it was 0:
	; load up the first operations result
+	ldh		a, ($93)		; $48de: $f0 $93 
	; and then continue:
	; and save whichever, at that just loaded address
++	ldi		(hl), a			; $48e0: $22 
	; then grab the second operations result
	ldh		a, ($92)		; $48e1: $f0 $92 
	; and save it to the right of that address
	ldi		(hl), a			; $48e3: $22 
	; grab the original index
	ldh		a, ($89)		; $48e4: $f0 $89 
	; and save it to the right
	ldi		(hl), a			; $48e6: $22 

	; or the last three hlrow bytes (the manip of the last one tho)
	; grab the manipulation of the last hlrow byte
	; and put it on b
	ldh		a, ($94)		; $48e7: $f0 $94 
	ld		b, a			; $48e9: $47 
	; then grab the next to last hlrow byte
	ldh		a, ($8b)		; $48ea: $f0 $8b 
	; or them together
	or		b			; $48ec: $b0 
	; and put on b
	ld		b, a			; $48ed: $47 
	; grab the so far untouched 5th hlrow byte
	ldh		a, ($8a)		; $48ee: $f0 $8a 
	; and or it as well
	or		b			; $48f0: $b0 
	; and put that result as the 4th byte of the save results
	ldi		(hl), a			; $48f1: $22 
	
	; and save the result pointer, ready for the next save
	ld		a, h			; $48f2: $7c 
	ldh		($8d), a		; $48f3: $e0 $8d 
	ld		a, l			; $48f5: $7d 
	ldh		($8e), a		; $48f6: $e0 $8e 

	; and grab the cmd pointer again
	pop		hl			; $48f8: $e1 
	jp		NEXT_CMD		; $48f9: $c3 $72 $48 
; end routine

; this must be another routine
; looks like it checks a word in ram, and catches an overflow
; and resets
; somethin like that?
ROUTINE_15:
	; leave if this var is 0
	ld		hl, $c209		; $48fc: $21 $09 $c2 
	ld		a, (hl)			; $48ff: $7e 
	ld		b, a			; $4900: $47 
	and		a			; $4901: $a7 
	ret		z			; $4902: $c8 
	; otherwise grab the var to the left
	dec		l			; $4903: $2d 
	ld		a, (hl)			; $4904: $7e 
	; and leav if its at least fh
	cp		$0f			; $4905: $fe $0f 
	ret		nc			; $4907: $d0 
	; but if its less than fh
	; replace it with the iniaally grabbed var
	ld		(hl), b			; $4908: $70 
	; and clear the upper one
	inc		l			; $4909: $2c 
	ld		(hl), $00		; $490a: $36 $00 
	ret					; $490c: $c9 
; end routine

; routine
; takes bc and hl
; this does jumping?
; ill come back and finish going through it later
JUMPING:
	; make de = 00__ + (bc)
	; store (bc) on e
	ld		a, (bc)			; $490d: $0a 
	ld		e, a			; $490e: $5f 
	; and 0 on d
	ld		d, $00			; $490f: $16 $00 
	; and grab the byte left of that one
	dec		c			; $4911: $0d 
	ld		a, (bc)			; $4912: $0a 
	; and go 6 bytes left
	dec		c			; $4913: $0d 
	dec		c			; $4914: $0d 
	dec		c			; $4915: $0d 
	dec		c			; $4916: $0d 
	dec		c			; $4917: $0d 
	dec		c			; $4918: $0d 
	; anyway, leave if the second byte was 0
	and		a			; $4919: $a7 
	ret		z			; $491a: $c8 
	cp		$02			; $491b: $fe $02 
	jr		z, $14			; $491d: $28 $14 
	add		hl, de			; $491f: $19 
	ld		a, (hl)			; $4920: $7e 
	cp		$7f			; $4921: $fe $7f 
	jr		z, $23			; $4923: $28 $23 
	ld		a, (bc)			; $4925: $0a 
	sub		(hl)			; $4926: $96 
	ld		(bc), a			; $4927: $02 
	inc		e			; $4928: $1c 
	ld		a, e			; $4929: $7b 
	inc		c			; $492a: $0c 
	inc		c			; $492b: $0c 
	inc		c			; $492c: $0c 
	inc		c			; $492d: $0c 
	inc		c			; $492e: $0c 
	inc		c			; $492f: $0c 
	inc		c			; $4930: $0c 
	ld		(bc), a			; $4931: $02 
	ret					; $4932: $c9 

	ld		a, e			; $4933: $7b 
	cp		$ff			; $4934: $fe $ff 
	jr		z, $23			; $4936: $28 $23 
	add		hl, de			; $4938: $19 
	ld		a, (hl)			; $4939: $7e 
	cp		$7f			; $493a: $fe $7f 
	jr		z, $06			; $493c: $28 $06 
	ld		a, (bc)			; $493e: $0a 
	add		(hl)			; $493f: $86 
	ld		(bc), a			; $4940: $02 
	dec		e			; $4941: $1d 
	jr		-$1b			; $4942: $18 $e5 
	dec		hl			; $4944: $2b 
	dec		e			; $4945: $1d 
	jr		-$0a			; $4946: $18 $f6 
	dec		de			; $4948: $1b 
	dec		hl			; $4949: $2b 
	ld		a, $02			; $494a: $3e $02 
	inc		c			; $494c: $0c 
	inc		c			; $494d: $0c 
	inc		c			; $494e: $0c 
	inc		c			; $494f: $0c 
	inc		c			; $4950: $0c 
	inc		c			; $4951: $0c 
	ld		(bc), a			; $4952: $02 
	dec		c			; $4953: $0d 
	dec		c			; $4954: $0d 
	dec		c			; $4955: $0d 
	dec		c			; $4956: $0d 
	dec		c			; $4957: $0d 
	dec		c			; $4958: $0d 
	jr		-$1d			; $4959: $18 $e3 
	xor		a			; $495b: $af 
	inc		c			; $495c: $0c 
	inc		c			; $495d: $0c 
	inc		c			; $495e: $0c 
	inc		c			; $495f: $0c 
	inc		c			; $4960: $0c 
	inc		c			; $4961: $0c 
	ld		(bc), a			; $4962: $02 
	inc		c			; $4963: $0c 
	ld		(bc), a			; $4964: $02 
	ret					; $4965: $c9 
 
	inc		e			; $4966: $1c 
	ld		a, (de)			; $4967: $1a 
	cp		$0f			; $4968: $fe $0f 
	jr		nc, $49			; $496a: $30 $49 
	inc		e			; $496c: $1c 
	dec		a			; $496d: $3d 
	ld		(de), a			; $496e: $12 
	dec		e			; $496f: $1d 
	ld		a, $0f			; $4970: $3e $0f 
	ld		(de), a			; $4972: $12 
	jr		$40			; $4973: $18 $40 
	push		af			; $4975: $f5 
	ld		a, (de)			; $4976: $1a 
	and		a			; $4977: $a7 
	jr		nz, $0e			; $4978: $20 $0e 
	ld		a, ($c20c)		; $497a: $fa $0c $c2 
	cp		$03			; $497d: $fe $03 
	ld		a, $02			; $497f: $3e $02 
	jr		c, $02			; $4981: $38 $02 
	ld		a, $04			; $4983: $3e $04 
	ld		($c20e), a		; $4985: $ea $0e $c2 
	pop		af			; $4988: $f1 
	jr		$21			; $4989: $18 $21 
	ldh		a, ($b3)		; $498b: $f0 $b3 
	cp		$0d			; $498d: $fe $0d 
	jp		z, $4a7f		; $498f: $ca $7f $4a 
	ld		de, $c207		; $4992: $11 $07 $c2 
	ldh		a, ($81)		; $4995: $f0 $81 
	ld		b, a			; $4997: $47 
	ldh		a, ($80)		; $4998: $f0 $80 
	bit		1, a			; $499a: $cb $4f 
	jr		nz, -$29			; $499c: $20 $d7 
	push		af			; $499e: $f5 
	ld		a, ($c20e)		; $499f: $fa $0e $c2 
	cp		$04			; $49a2: $fe $04 
	jr		nz, $05			; $49a4: $20 $05 
	ld		a, $02			; $49a6: $3e $02 
	ld		($c20e), a		; $49a8: $ea $0e $c2 
	pop		af			; $49ab: $f1 
	bit		0, a			; $49ac: $cb $47 
	jr		nz, $0f			; $49ae: $20 $0f 
	ld		a, (de)			; $49b0: $1a 
	cp		$01			; $49b1: $fe $01 
	jr		z, -$4f			; $49b3: $28 $b1 
	bit		7, b			; $49b5: $cb $78 
	jp		nz, $4a77		; $49b7: $c2 $77 $4a 
	bit		1, b			; $49ba: $cb $48 
	jr		nz, $3f			; $49bc: $20 $3f 
	ret					; $49be: $c9 
	ld		a, (de)			; $49bf: $1a 
	and		a			; $49c0: $a7 
	jr		nz, -$0e			; $49c1: $20 $f2 
	ld		hl, $c20a		; $49c3: $21 $0a $c2 
	ld		a, (hl)			; $49c6: $7e 
	and		a			; $49c7: $a7 
	jr		z, -$15			; $49c8: $28 $eb 
	bit		0, b			; $49ca: $cb $40 
	jr		z, -$19			; $49cc: $28 $e7 
	ld		(hl), $00		; $49ce: $36 $00 
	ld		hl, $c203		; $49d0: $21 $03 $c2 
	push		hl			; $49d3: $e5 
	ld		a, (hl)			; $49d4: $7e 
	cp		$18			; $49d5: $fe $18 
	jr		z, $19			; $49d7: $28 $19 
	and		$f0			; $49d9: $e6 $f0 
	or		$04			; $49db: $f6 $04 
	ld		(hl), a			; $49dd: $77 
	ld		a, ($c20e)		; $49de: $fa $0e $c2 
	cp		$04			; $49e1: $fe $04 
	jr		z, $08			; $49e3: $28 $08 
	ld		a, $02			; $49e5: $3e $02 
	ld		($c20e), a		; $49e7: $ea $0e $c2 
	ld		($c208), a		; $49ea: $ea $08 $c2 
	ld		hl, $c20c		; $49ed: $21 $0c $c2 
	ld		(hl), $30		; $49f0: $36 $30 
	ld		hl, $dfe0		; $49f2: $21 $e0 $df 
	ld		(hl), $01		; $49f5: $36 $01 
	ld		a, $01			; $49f7: $3e $01 
	ld		(de), a			; $49f9: $12 
	pop		hl			; $49fa: $e1 
	jr		-$48			; $49fb: $18 $b8 
	ld		hl, $c20c		; $49fd: $21 $0c $c2 
	ld		a, (hl)			; $4a00: $7e 
	cp		$06			; $4a01: $fe $06 
	jr		nz, $07			; $4a03: $20 $07 
	ldh		a, ($9f)		; $4a05: $f0 $9f 
	and		a			; $4a07: $a7 
	jr		nz, $02			; $4a08: $20 $02 
	ld		(hl), $00		; $4a0a: $36 $00 
	ldh		a, ($b3)		; $4a0c: $f0 $b3 
	cp		$0d			; $4a0e: $fe $0d 
	ld		b, $03			; $4a10: $06 $03 
	jr		z, $06			; $4a12: $28 $06 
	ldh		a, ($b5)		; $4a14: $f0 $b5 
	and		a			; $4a16: $a7 
	ret		z			; $4a17: $c8 
	ld		b, $01			; $4a18: $06 $01 
	ld		hl, $ffa9		; $4a1a: $21 $a9 $ff 
	ld		de, $c000		; $4a1d: $11 $00 $c0 
	ldi		a, (hl)			; $4a20: $2a 
	and		a			; $4a21: $a7 
	jr		z, $08			; $4a22: $28 $08 
	inc		e			; $4a24: $1c 
	inc		e			; $4a25: $1c 
	inc		e			; $4a26: $1c 
	inc		e			; $4a27: $1c 
	dec		b			; $4a28: $05 
	jr		nz, -$0b			; $4a29: $20 $f5 
	ret					; $4a2b: $c9 

	push		hl			; $4a2c: $e5 
	ld		hl, $c205		; $4a2d: $21 $05 $c2 
	ld		b, (hl)			; $4a30: $46 
	ld		hl, $c201		; $4a31: $21 $01 $c2 
	ldi		a, (hl)			; $4a34: $2a 
	add		$fe			; $4a35: $c6 $fe 
	ld		(de), a			; $4a37: $12 
	inc		e			; $4a38: $1c 
	ld		c, $02			; $4a39: $0e $02 
	bit		5, b			; $4a3b: $cb $68 
	jr		z, $02			; $4a3d: $28 $02 
	ld		c, $f8			; $4a3f: $0e $f8 
	ldi		a, (hl)			; $4a41: $2a 
	add		c			; $4a42: $81 
	ld		(de), a			; $4a43: $12 
	ld		c, $60			; $4a44: $0e $60 
	inc		e			; $4a46: $1c 
	ldh		a, ($b3)		; $4a47: $f0 $b3 
	cp		$0d			; $4a49: $fe $0d 
	jr		nz, $0a			; $4a4b: $20 $0a 
	ld		c, $7a			; $4a4d: $0e $7a 
	ldh		a, ($e4)		; $4a4f: $f0 $e4 
	cp		$0b			; $4a51: $fe $0b 
	jr		nz, $02			; $4a53: $20 $02 
	ld		c, $6e			; $4a55: $0e $6e 
	ld		a, c			; $4a57: $79 
	ld		(de), a			; $4a58: $12 
	inc		e			; $4a59: $1c 
	xor		a			; $4a5a: $af 
	ld		(de), a			; $4a5b: $12 
	pop		hl			; $4a5c: $e1 
	dec		l			; $4a5d: $2d 
	ld		c, $0a			; $4a5e: $0e $0a 
	bit		5, b			; $4a60: $cb $68 
	jr		nz, $02			; $4a62: $20 $02 
	ld		c, $09			; $4a64: $0e $09 
	ld		(hl), c			; $4a66: $71 
	ld		hl, $dfe0		; $4a67: $21 $e0 $df 
	ld		(hl), $02		; $4a6a: $36 $02 
	ld		a, $0c			; $4a6c: $3e $0c 
	ld		($c0ae), a		; $4a6e: $ea $ae $c0 
	ld		a, $ff			; $4a71: $3e $ff 
	ld		($c0a9), a		; $4a73: $ea $a9 $c0 
	ret					; $4a76: $c9 

	ld		hl, $c20c		; $4a77: $21 $0c $c2 
	ld		(hl), $20		; $4a7a: $36 $20 
	jp		$49ba			; $4a7c: $c3 $ba $49 
	ldh		a, ($81)		; $4a7f: $f0 $81 
	and		$03			; $4a81: $e6 $03 
	jr		nz, -$79			; $4a83: $20 $87 
	ldh		a, ($80)		; $4a85: $f0 $80 
	bit		0, a			; $4a87: $cb $47 
	ret		z			; $4a89: $c8 
	ld		hl, $c0ae		; $4a8a: $21 $ae $c0 
	ld		a, (hl)			; $4a8d: $7e 
	and		a			; $4a8e: $a7 
	jp		z, $4a0c		; $4a8f: $ca $0c $4a 
	dec		(hl)			; $4a92: $35 
	ret					; $4a93: $c9 
; end routine
 
; routine
	ldh		a, ($9f)		; $4a94: $f0 $9f 
	and		a			; $4a96: $a7 
	ret		z			; $4a97: $c8 
	cp		$ff			; $4a98: $fe $ff 
	ret		z			; $4a9a: $c8 
	ld		a, ($c0d8)		; $4a9b: $fa $d8 $c0 
	and		a			; $4a9e: $a7 
	jr		z, $06			; $4a9f: $28 $06 
	dec		a			; $4aa1: $3d 
	ld		($c0d8), a		; $4aa2: $ea $d8 $c0 
	jr		$2a			; $4aa5: $18 $2a 
	ld		a, ($c0dc)		; $4aa7: $fa $dc $c0 
	sla		a			; $4aaa: $cb $27 
	ld		e, a			; $4aac: $5f 
	ld		d, $00			; $4aad: $16 $00 
	ld		hl, $4ae4		; $4aaf: $21 $e4 $4a 
	add		hl, de			; $4ab2: $19 
	ld		e, (hl)			; $4ab3: $5e 
	inc		hl			; $4ab4: $23 
	ld		d, (hl)			; $4ab5: $56 
	push		de			; $4ab6: $d5 
	pop		hl			; $4ab7: $e1 
	ld		a, ($c0d9)		; $4ab8: $fa $d9 $c0 
	ld		d, $00			; $4abb: $16 $00 
	ld		e, a			; $4abd: $5f 
	add		hl, de			; $4abe: $19 
	ldi		a, (hl)			; $4abf: $2a 
	cp		$ff			; $4ac0: $fe $ff 
	jr		z, +			; $4ac2: $28 $1a 
	ld		($c0da), a		; $4ac4: $ea $da $c0 
	ld		a, (hl)			; $4ac7: $7e 
	ld		($c0d8), a		; $4ac8: $ea $d8 $c0 
	inc		e			; $4acb: $1c 
	inc		e			; $4acc: $1c 
	ld		a, e			; $4acd: $7b 
	ld		($c0d9), a		; $4ace: $ea $d9 $c0 
	ldh		a, ($80)		; $4ad1: $f0 $80 
	ld		($c0db), a		; $4ad3: $ea $db $c0 
	ld		a, ($c0da)		; $4ad6: $fa $da $c0 
	ldh		($80), a		; $4ad9: $e0 $80 
	ldh		($81), a		; $4adb: $e0 $81 
	ret					; $4add: $c9 
+	xor		a			; $4ade: $af 
	ld		($c0da), a		; $4adf: $ea $da $c0 
	jr		-$13			; $4ae2: $18 $ed 
	ld		d, b			; $4ae4: $50 
	ld		h, l			; $4ae5: $65 
	ldh		($65), a		; $4ae6: $e0 $65 
	ld		(hl), b			; $4ae8: $70 
	ld		h, (hl)			; $4ae9: $66 
	ld		b, $04			; $4aea: $06 $04 
	ld		de, $0010		; $4aec: $11 $10 $00 
	ld		hl, $c210		; $4aef: $21 $10 $c2 
	push		hl			; $4af2: $e5 
	ld		a, (hl)			; $4af3: $7e 
	cp		$80			; $4af4: $fe $80 
	jr		nz, $02			; $4af6: $20 $02 
	ld		(hl), $ff		; $4af8: $36 $ff 
	and		a			; $4afa: $a7 
	jr		nz, $1e			; $4afb: $20 $1e 
	push		de			; $4afd: $d5 
	ld		de, $0007		; $4afe: $11 $07 $00 
	add		hl, de			; $4b01: $19 
	pop		de			; $4b02: $d1 
	ld		a, (hl)			; $4b03: $7e 
	and		a			; $4b04: $a7 
	jr		z, $2b			; $4b05: $28 $2b 
	dec		l			; $4b07: $2d 
	dec		l			; $4b08: $2d 
	ld		a, (hl)			; $4b09: $7e 
	dec		l			; $4b0a: $2d 
	dec		l			; $4b0b: $2d 
	dec		l			; $4b0c: $2d 
	and		a			; $4b0d: $a7 
	jr		nz, +			; $4b0e: $20 $15 
	inc		(hl)			; $4b10: $34 
	ldh		a, ($f3)		; $4b11: $f0 $f3 
	ld		c, a			; $4b13: $4f 
	ldh		a, ($a4)		; $4b14: $f0 $a4 
	sub		c			; $4b16: $91 
	ld		c, a			; $4b17: $4f 
	ld		a, (hl)			; $4b18: $7e 
	sub		c			; $4b19: $91 
	ld		(hl), a			; $4b1a: $77 
	pop		hl			; $4b1b: $e1 
	add		hl, de			; $4b1c: $19 
	dec		b			; $4b1d: $05 
	jr		nz, -$2e			; $4b1e: $20 $d2 
	ldh		a, ($a4)		; $4b20: $f0 $a4 
	ldh		($f3), a		; $4b22: $e0 $f3 
	ret					; $4b24: $c9 
+	dec		(hl)			; $4b25: $35 
	ldh		a, ($f3)		; $4b26: $f0 $f3 
	ld		c, a			; $4b28: $4f 
	ldh		a, ($a4)		; $4b29: $f0 $a4 
	sub		c			; $4b2b: $91 
	ld		c, a			; $4b2c: $4f 
	ld		a, (hl)			; $4b2d: $7e 
	sub		c			; $4b2e: $91 
	ld		(hl), a			; $4b2f: $77 
	jr		-$17			; $4b30: $18 $e9 
	pop		hl			; $4b32: $e1 
	push		hl			; $4b33: $e5 
	ld		(hl), $80		; $4b34: $36 $80 
	inc		l			; $4b36: $2c 
	inc		l			; $4b37: $2c 
	ld		(hl), $ff		; $4b38: $36 $ff 
	jr		-$21			; $4b3a: $18 $df 
	ldh		a, ($ee)		; $4b3c: $f0 $ee 
	cp		$03			; $4b3e: $fe $03 
	ret		nz			; $4b40: $c0 
	ld		hl, $c02d		; $4b41: $21 $2d $c0 
	ldh		a, ($a4)		; $4b44: $f0 $a4 
	ld		b, a			; $4b46: $47 
	ldh		a, ($f2)		; $4b47: $f0 $f2 
	sub		b			; $4b49: $90 
	ldd		(hl), a			; $4b4a: $32 
	ld		a, ($c201)		; $4b4b: $fa $01 $c2 
	sub		$0b			; $4b4e: $d6 $0b 
	ld		(hl), a			; $4b50: $77 
	ld		a, ($c20a)		; $4b51: $fa $0a $c2 
	and		a			; $4b54: $a7 
	jr		nz, $0b			; $4b55: $20 $0b 
	ldh		a, ($f1)		; $4b57: $f0 $f1 
	ld		b, a			; $4b59: $47 
	sub		$04			; $4b5a: $d6 $04 
	cp		(hl)			; $4b5c: $be 
	jr		nc, $0a			; $4b5d: $30 $0a 
	ld		a, b			; $4b5f: $78 
	cp		(hl)			; $4b60: $be 
	ret		nc			; $4b61: $d0 
	ld		(hl), $00		; $4b62: $36 $00 
	ld		a, $04			; $4b64: $3e $04 
	ldh		($ee), a		; $4b66: $e0 $ee 
	ret					; $4b68: $c9 
	ld		a, $02			; $4b69: $3e $02 
	ld		($c207), a		; $4b6b: $ea $07 $c2 
	ret					; $4b6e: $c9 
	ld		hl, $c201		; $4b6f: $21 $01 $c2 
	ld		a, (hl)			; $4b72: $7e 
	cp		$b4			; $4b73: $fe $b4 
	ret		c			; $4b75: $d8 
	cp		$c0			; $4b76: $fe $c0 
	ret		nc			; $4b78: $d0 
	xor		a			; $4b79: $af 
	ldh		($99), a		; $4b7a: $e0 $99 
	ldh		($b5), a		; $4b7c: $e0 $b5 
	inc		a			; $4b7e: $3c 
	ldh		($b3), a		; $4b7f: $e0 $b3 
	inc		a			; $4b81: $3c 
	ld		($dfe8), a		; $4b82: $ea $e8 $df 
	ld		a, $90			; $4b85: $3e $90 
	ldh		($a6), a		; $4b87: $e0 $a6 
	ret					; $4b89: $c9 
; end routine

; routine
	ldh		a, ($99)		; $4b8a: $f0 $99 
	cp		$01			; $4b8c: $fe $01 
	ret		nz			; $4b8e: $c0 
	ldh		a, ($a6)		; $4b8f: $f0 $a6 
	and		a			; $4b91: $a7 
	jr		z, $10			; $4b92: $28 $10 
	and		$03			; $4b94: $e6 $03 
	ret		nz			; $4b96: $c0 
	xor		a			; $4b97: $af 
	ld		($c200), a		; $4b98: $ea $00 $c2 
	ld		a, ($c203)		; $4b9b: $fa $03 $c2 
	xor		$10			; $4b9e: $ee $10 
	ld		($c203), a		; $4ba0: $ea $03 $c2 
	ret					; $4ba3: $c9 
	ld		a, $02			; $4ba4: $3e $02 
	ldh		($99), a		; $4ba6: $e0 $99 
	xor		a			; $4ba8: $af 
	ld		($c200), a		; $4ba9: $ea $00 $c2 
	ld		a, ($c203)		; $4bac: $fa $03 $c2 
	or		$10			; $4baf: $f6 $10 
	ld		($c203), a		; $4bb1: $ea $03 $c2 
	ret					; $4bb4: $c9 
; end routine

; routine
	ldh		a, ($99)		; $4bb5: $f0 $99 
	cp		$04			; $4bb7: $fe $04 
	jr		z, $25			; $4bb9: $28 $25 
	cp		$03			; $4bbb: $fe $03 
	ret		nz			; $4bbd: $c0 
	ldh		a, ($a6)		; $4bbe: $f0 $a6 
	and		a			; $4bc0: $a7 
	jr		z, $0c			; $4bc1: $28 $0c 
	and		$03			; $4bc3: $e6 $03 
	ret		nz			; $4bc5: $c0 
	ld		a, ($c203)		; $4bc6: $fa $03 $c2 
	xor		$10			; $4bc9: $ee $10 
	ld		($c203), a		; $4bcb: $ea $03 $c2 
	ret					; $4bce: $c9 
	ld		a, $04			; $4bcf: $3e $04 
	ldh		($99), a		; $4bd1: $e0 $99 
	ld		a, $40			; $4bd3: $3e $40 
	ldh		($a6), a		; $4bd5: $e0 $a6 
	ld		a, ($c203)		; $4bd7: $fa $03 $c2 
	and		$0f			; $4bda: $e6 $0f 
	ld		($c203), a		; $4bdc: $ea $03 $c2 
	ret					; $4bdf: $c9 
	ldh		a, ($a6)		; $4be0: $f0 $a6 
	and		a			; $4be2: $a7 
	jr		z, $0c			; $4be3: $28 $0c 
	and		$03			; $4be5: $e6 $03 
	ret		nz			; $4be7: $c0 
	ld		a, ($c200)		; $4be8: $fa $00 $c2 
	xor		$80			; $4beb: $ee $80 
	ld		($c200), a		; $4bed: $ea $00 $c2 
	ret					; $4bf0: $c9 
	xor		a			; $4bf1: $af 
	ldh		($99), a		; $4bf2: $e0 $99 
	ld		($c200), a		; $4bf4: $ea $00 $c2 
	ld		a, ($c203)		; $4bf7: $fa $03 $c2 
	and		$0f			; $4bfa: $e6 $0f 
	ld		($c203), a		; $4bfc: $ea $03 $c2 
	ret					; $4bff: $c9 

	ldh		a, ($9f)		; $4c00: $f0 $9f 
	cp		$ff			; $4c02: $fe $ff 
	ret		nz			; $4c04: $c0 
	ldh		a, ($80)		; $4c05: $f0 $80 
	ld		b, a			; $4c07: $47 
	ld		a, ($c0da)		; $4c08: $fa $da $c0 
	cp		b			; $4c0b: $b8 
	jr		z, $21			; $4c0c: $28 $21 
	ld		hl, $c300		; $4c0e: $21 $00 $c3 
	ld		a, ($c0d9)		; $4c11: $fa $d9 $c0 
	ld		e, a			; $4c14: $5f 
	ld		d, $00			; $4c15: $16 $00 
	add		hl, de			; $4c17: $19 
	ld		a, ($c0da)		; $4c18: $fa $da $c0 
	ldi		(hl), a			; $4c1b: $22 
	ld		a, ($c0d8)		; $4c1c: $fa $d8 $c0 
	ld		(hl), a			; $4c1f: $77 
	inc		e			; $4c20: $1c 
	inc		e			; $4c21: $1c 
	ld		a, e			; $4c22: $7b 
	ld		($c0d9), a		; $4c23: $ea $d9 $c0 
	ld		a, b			; $4c26: $78 
	ld		($c0da), a		; $4c27: $ea $da $c0 
	xor		a			; $4c2a: $af 
	ld		($c0d8), a		; $4c2b: $ea $d8 $c0 
	ret					; $4c2e: $c9 
	ld		a, ($c0d8)		; $4c2f: $fa $d8 $c0 
	inc		a			; $4c32: $3c 
	ld		($c0d8), a		; $4c33: $ea $d8 $c0 
	ret					; $4c36: $c9 
; end routine

; data
; i think its animation data?
; or like... entity specific data and coding ? ? or somethgin idk ! ! !
; unsure
.incbin "data8.bin"
; end data

.org $251c

; data array of addresses
	jp		z, $d650		; $651c: $ca $50 $d6 
	ld		d, b			; $651f: $50 
	rst		$10			; $6520: $d7 
	ld		d, b			; $6521: $50 
.db $e4
	ld		d, b			; $6523: $50 
	pop		af			; $6524: $f1 
	ld		d, b			; $6525: $50 
.db $fd
	ld		d, b			; $6527: $50 
	cp		$50			; $6528: $fe $50 
	dec		bc			; $652a: $0b 
	ld		d, c			; $652b: $51 
	jr		$51			; $652c: $18 $51 
	dec		h			; $652e: $25 
	ld		d, c			; $652f: $51 
	ldd		(hl), a			; $6530: $32 
	ld		d, c			; $6531: $51 
	ld		a, $51			; $6532: $3e $51 
	ld		a, $51			; $6534: $3e $51 
	ccf					; $6536: $3f 
	ld		d, c			; $6537: $51 
	ld		c, a			; $6538: $4f 
	ld		d, c			; $6539: $51 
	ld		e, h			; $653a: $5c 
	ld		d, c			; $653b: $51 
	ld		(hl), l			; $653c: $75 
	ld		d, c			; $653d: $51 
	sub		c			; $653e: $91 
	ld		d, c			; $653f: $51 
	and		a			; $6540: $a7 
	ld		d, c			; $6541: $51 
	or		a			; $6542: $b7 
	ld		d, c			; $6543: $51 
	call		nz, $d751		; $6544: $c4 $51 $d7 
	ld		d, c			; $6547: $51 
	ld		($0651), a		; $6548: $ea $51 $06 
	ld		d, d			; $654b: $52 
	add		hl, de			; $654c: $19 
	ld		d, d			; $654d: $52 
	dec		hl			; $654e: $2b 
	ld		d, d			; $654f: $52 
; end ? start of aother?
	nop					; $6550: $00 
	ld		b, c			; $6551: $41 
	ld		bc, $0007		; $6552: $01 $07 $00 
	jr		$10			; $6555: $18 $10 
	ld		e, e			; $6557: $5b 
	ld		de, $100a		; $6558: $11 $0a $10 
	rlca					; $655b: $07 
	nop					; $655c: $00 
	ld		c, e			; $655d: $4b 
	ld		bc, $000a		; $655e: $01 $0a $00 
	dec		l			; $6561: $2d 
	stop					; $6562: $10 
	inc		d			; $6563: $14 
	nop					; $6564: $00 
	halt					; $6565: $76 
	stop					; $6566: $10 
	ld		bc, $1011		; $6567: $01 $11 $10 
	stop					; $656a: $10 
	inc		h			; $656b: $24 
	ld		de, $100b		; $656c: $11 $0b $10 
	nop					; $656f: $00 
	nop					; $6570: $00 
	dec		hl			; $6571: $2b 
	ld		bc, $000f		; $6572: $01 $0f $00 
	inc		l			; $6575: $2c 
	stop					; $6576: $10 
	rra					; $6577: $1f 
	ld		de, $100b		; $6578: $11 $0b $10 
	daa					; $657b: $27 
	ld		de, $0101		; $657c: $11 $01 $01 
	add		hl, bc			; $657f: $09 
	nop					; $6580: $00 
	jr		nz, $10			; $6581: $20 $10 
	ld		e, l			; $6583: $5d 
	ld		de, $1014		; $6584: $11 $14 $10 
	add		hl, de			; $6587: $19 
	nop					; $6588: $00 
	daa					; $6589: $27 
	stop					; $658a: $10 
	ld		a, (bc)			; $658b: $0a 
	ld		de, $1006		; $658c: $11 $06 $10 
	ldi		a, (hl)			; $658f: $2a 
	nop					; $6590: $00 
	ld		d, c			; $6591: $51 
	stop					; $6592: $10 
	ld		c, $11			; $6593: $0e $11 
	ld		b, $10			; $6595: $06 $10 
	ld		(bc), a			; $6597: $02 
	nop					; $6598: $00 
	ld		h, e			; $6599: $63 
	ld		bc, $110f		; $659a: $01 $0f $11 
	rlca					; $659d: $07 
	stop					; $659e: $10 
	ld		b, $ff			; $659f: $06 $ff 
; end of that

	rst		$38			; $65a1: $ff 
	rst		$38			; $65a2: $ff 
	rst		$38			; $65a3: $ff 
	rst		$38			; $65a4: $ff 
	rst		$38			; $65a5: $ff 
	rst		$38			; $65a6: $ff 
	rst		$38			; $65a7: $ff 
	rst		$38			; $65a8: $ff 
	rst		$38			; $65a9: $ff 
	rst		$38			; $65aa: $ff 
	rst		$38			; $65ab: $ff 
	rst		$38			; $65ac: $ff 
	rst		$38			; $65ad: $ff 
	rst		$38			; $65ae: $ff 
	rst		$38			; $65af: $ff 
	rst		$38			; $65b0: $ff 
	rst		$38			; $65b1: $ff 
	rst		$38			; $65b2: $ff 
	rst		$38			; $65b3: $ff 
	rst		$38			; $65b4: $ff 
	rst		$38			; $65b5: $ff 
	rst		$38			; $65b6: $ff 
	rst		$38			; $65b7: $ff 
	rst		$38			; $65b8: $ff 
	rst		$38			; $65b9: $ff 
	rst		$38			; $65ba: $ff 
	rst		$38			; $65bb: $ff 
	rst		$38			; $65bc: $ff 
	rst		$38			; $65bd: $ff 
	rst		$38			; $65be: $ff 
	rst		$38			; $65bf: $ff 
	rst		$38			; $65c0: $ff 
	rst		$38			; $65c1: $ff 
	rst		$38			; $65c2: $ff 
	rst		$38			; $65c3: $ff 
	rst		$38			; $65c4: $ff 
	rst		$38			; $65c5: $ff 
	rst		$38			; $65c6: $ff 
	rst		$38			; $65c7: $ff 
	rst		$38			; $65c8: $ff 
	rst		$38			; $65c9: $ff 
	rst		$38			; $65ca: $ff 
	rst		$38			; $65cb: $ff 
	rst		$38			; $65cc: $ff 
	rst		$38			; $65cd: $ff 
	rst		$38			; $65ce: $ff 
	rst		$38			; $65cf: $ff 
	rst		$38			; $65d0: $ff 
	rst		$38			; $65d1: $ff 
	rst		$38			; $65d2: $ff 
	rst		$38			; $65d3: $ff 
	rst		$38			; $65d4: $ff 
	rst		$38			; $65d5: $ff 
	rst		$38			; $65d6: $ff 
	rst		$38			; $65d7: $ff 
	rst		$38			; $65d8: $ff 
	rst		$38			; $65d9: $ff 
	rst		$38			; $65da: $ff 
	rst		$38			; $65db: $ff 
	rst		$38			; $65dc: $ff 
	rst		$38			; $65dd: $ff 
	rst		$38			; $65de: $ff 
	rst		$38			; $65df: $ff 

; more?
	nop					; $65e0: $00 
	jr		z, $10			; $65e1: $28 $10 
	ld		a, (bc)			; $65e3: $0a 
	ld		de, $100b		; $65e4: $11 $0b $10 
	dec		h			; $65e7: $25 
	ld		de, $1011		; $65e8: $11 $11 $10 
	ld		de, $0811		; $65eb: $11 $11 $08 
	stop					; $65ee: $10 
	inc		b			; $65ef: $04 
	nop					; $65f0: $00 
	inc		e			; $65f1: $1c 
	stop					; $65f2: $10 
	inc		b			; $65f3: $04 
	ld		de, $0104		; $65f4: $11 $04 $01 
	inc		bc			; $65f7: $03 
	nop					; $65f8: $00 
	rra					; $65f9: $1f 
	stop					; $65fa: $10 
	ld		(bc), a			; $65fb: $02 
	ld		de, $100d		; $65fc: $11 $0d $10 
	rlca					; $65ff: $07 
	nop					; $6600: $00 
	cpl					; $6601: $2f 
	stop					; $6602: $10 
	ld		bc, $0d11		; $6603: $01 $11 $0d 
	stop					; $6606: $10 
	inc		b			; $6607: $04 
	nop					; $6608: $00 
	dec		e			; $6609: $1d 
	ld		bc, $000c		; $660a: $01 $0c $00 
	ld		e, c			; $660d: $59 
	stop					; $660e: $10 
	inc		bc			; $660f: $03 
	ld		de, $000f		; $6610: $11 $0f $00 
	rra					; $6613: $1f 
	jr		nz, $0a			; $6614: $20 $0a 
	nop					; $6616: $00 
	ldi		(hl), a			; $6617: $22 
	stop					; $6618: $10 
	nop					; $6619: $00 
	ld		de, $1016		; $661a: $11 $16 $10 
	dec		a			; $661d: $3d 
	ld		de, $101a		; $661e: $11 $1a $10 
	nop					; $6621: $00 
	nop					; $6622: $00 
	dec		de			; $6623: $1b 
	stop					; $6624: $10 
	cpl					; $6625: $2f 
	ld		de, $010f		; $6626: $11 $0f $01 
	ld		bc, $2900		; $6629: $01 $00 $29 
	stop					; $662c: $10 
	inc		b			; $662d: $04 
	ld		de, $100d		; $662e: $11 $0d $10 
	ld		a, (bc)			; $6631: $0a 
	nop					; $6632: $00 
	ld		b, b			; $6633: $40 
	ld		bc, $210c		; $6634: $01 $0c $21 
	ld		bc, $0820		; $6637: $01 $20 $08 
	nop					; $663a: $00 
	add		hl, hl			; $663b: $29 
	jr		nz, $17			; $663c: $20 $17 
	nop					; $663e: $00 
	ld		b, a			; $663f: $47 
	stop					; $6640: $10 
	rla					; $6641: $17 
	ld		de, $1018		; $6642: $11 $18 $10 
	ld		a, (de)			; $6645: $1a 
	nop					; $6646: $00 
	ld		(de), a			; $6647: $12 
	stop					; $6648: $10 
	rlca					; $6649: $07 
	ld		de, $100c		; $664a: $11 $0c $10 
	ld		bc, $1500		; $664d: $01 $00 $15 
	stop					; $6650: $10 
	add		hl, bc			; $6651: $09 
	ld		de, $100b		; $6652: $11 $0b $10 
	jr		nz, $00			; $6655: $20 $00 
	dec		e			; $6657: $1d 
	ld		bc, $0001		; $6658: $01 $01 $00 
	nop					; $665b: $00 
	nop					; $665c: $00 
	nop					; $665d: $00 
	nop					; $665e: $00 
	nop					; $665f: $00 
; end dof that

	rst		$38			; $6660: $ff 
	rst		$38			; $6661: $ff 
	rst		$38			; $6662: $ff 
	rst		$38			; $6663: $ff 
	rst		$38			; $6664: $ff 
	rst		$38			; $6665: $ff 
	rst		$38			; $6666: $ff 
	rst		$38			; $6667: $ff 
	rst		$38			; $6668: $ff 
	rst		$38			; $6669: $ff 
	rst		$38			; $666a: $ff 
	rst		$38			; $666b: $ff 
	rst		$38			; $666c: $ff 
	rst		$38			; $666d: $ff 
	rst		$38			; $666e: $ff 
	rst		$38			; $666f: $ff 

; onther ?
	nop					; $6670: $00 
	ld		h, $10			; $6671: $26 $10 
	inc		bc			; $6673: $03 
	ld		de, $100d		; $6674: $11 $0d $10 
	add		hl, bc			; $6677: $09 
	nop					; $6678: $00 
	ld		($0c10), sp		; $6679: $08 $10 $0c 
	ld		de, $100d		; $667c: $11 $0d $10 
	ld		a, (bc)			; $667f: $0a 
	nop					; $6680: $00 
	jr		$10			; $6681: $18 $10 
	inc		b			; $6683: $04 
	ld		de, $100b		; $6684: $11 $0b $10 
	inc		b			; $6687: $04 
	nop					; $6688: $00 
	ldi		(hl), a			; $6689: $22 
	stop					; $668a: $10 
	ld		bc, $1111		; $668b: $01 $11 $11 
	stop					; $668e: $10 
	ld		(bc), a			; $668f: $02 
	nop					; $6690: $00 
	dec		a			; $6691: $3d 
	stop					; $6692: $10 
	ld		($0c11), sp		; $6693: $08 $11 $0c 
	stop					; $6696: $10 
	dec		c			; $6697: $0d 
	nop					; $6698: $00 
	ld		(hl), b			; $6699: $70 
	ld		bc, $1105		; $669a: $01 $05 $11 
	rlca					; $669d: $07 
	stop					; $669e: $10 
	inc		b			; $669f: $04 
	nop					; $66a0: $00 
	jr		nz, $10			; $66a1: $20 $10 
	dec		c			; $66a3: $0d 
	ld		de, $101c		; $66a4: $11 $1c $10 
	ld		a, (de)			; $66a7: $1a 
	nop					; $66a8: $00 
	dec		h			; $66a9: $25 
	ld		bc, $1110		; $66aa: $01 $10 $11 
	dec		b			; $66ad: $05 
	stop					; $66ae: $10 
	ld		b, $00			; $66af: $06 $00 
	inc		l			; $66b1: $2c 
	stop					; $66b2: $10 
	inc		bc			; $66b3: $03 
	ld		de, $1011		; $66b4: $11 $11 $10 
	ld		c, $00			; $66b7: $0e $00 
	ld		h, $10			; $66b9: $26 $10 
	stop					; $66bb: $10 
	ld		de, $1017		; $66bc: $11 $17 $10 
	inc		bc			; $66bf: $03 
	nop					; $66c0: $00 
	inc		d			; $66c1: $14 
	ld		bc, $000d		; $66c2: $01 $0d $00 
	dec		de			; $66c5: $1b 
	stop					; $66c6: $10 
	ld		a, (bc)			; $66c7: $0a 
	nop					; $66c8: $00 
	ldi		a, (hl)			; $66c9: $2a 
	ld		de, $100d		; $66ca: $11 $0d $10 
	inc		bc			; $66cd: $03 
	nop					; $66ce: $00 
	ld		c, $20			; $66cf: $0e $20 
	ld		b, $00			; $66d1: $06 $00 
	ld		a, (de)			; $66d3: $1a 
	stop					; $66d4: $10 
	inc		bc			; $66d5: $03 
	ld		de, $1009		; $66d6: $11 $09 $10 
	ld		($1700), sp		; $66d9: $08 $00 $17 
	stop					; $66dc: $10 
	ld		($0501), sp		; $66dd: $08 $01 $05 
	ld		de, $0004		; $66e0: $11 $04 $00 
	inc		d			; $66e3: $14 
	jr		nz, $06			; $66e4: $20 $06 
	nop					; $66e6: $00 
	sbc		b			; $66e7: $98 
	ld		bc, $1109		; $66e8: $01 $09 $11 
	ld		b, $10			; $66eb: $06 $10 
	ld		(bc), a			; $66ed: $02 
	nop					; $66ee: $00 
	dec		l			; $66ef: $2d 
; end

	rst		$38			; $66f0: $ff 
	rst		$38			; $66f1: $ff 
	rst		$38			; $66f2: $ff 
	rst		$38			; $66f3: $ff 
	rst		$38			; $66f4: $ff 
	rst		$38			; $66f5: $ff 
	rst		$38			; $66f6: $ff 
	rst		$38			; $66f7: $ff 
	rst		$38			; $66f8: $ff 
	rst		$38			; $66f9: $ff 
	rst		$38			; $66fa: $ff 
	rst		$38			; $66fb: $ff 
	rst		$38			; $66fc: $ff 
	rst		$38			; $66fd: $ff 
	rst		$38			; $66fe: $ff 
	rst		$38			; $66ff: $ff 

; more
	xor		(hl)			; $6700: $ae 
	ld		l, b			; $6701: $68 
.db $e3
	ld		l, b			; $6703: $68 
	ld		(hl), $69		; $6704: $36 $69 
	ld		(hl), e			; $6706: $73 
	ld		l, c			; $6707: $69 
	inc		c			; $6708: $0c 
	ld		l, c			; $6709: $69 
	cp		l			; $670a: $bd 
	ld		l, c			; $670b: $69 
	sbc		(hl)			; $670c: $9e 
	ld		l, c			; $670d: $69 
	jp		hl			; $670e: $e9 
	ld		l, c			; $670f: $69 
	ld		a, d			; $6710: $7a 
	ld		l, b			; $6711: $68 
	ld		l, l			; $6712: $6d 
	ld		l, b			; $6713: $68 
	ld		h, c			; $6714: $61 
	ld		l, c			; $6715: $69 
	jp		$ef68			; $6716: $c3 $68 $ef 
	ld		l, b			; $6719: $68 
	ld		b, d			; $671a: $42 
	ld		l, c			; $671b: $69 
	add		b			; $671c: $80 
	ld		l, c			; $671d: $69 
	ld		d, $69			; $671e: $16 $69 
	bit		5, c			; $6720: $cb $69 
	rst		$28			; $6722: $ef 
	ld		l, b			; $6723: $68 
	rrca					; $6724: $0f 
	ld		l, d			; $6725: $6a 
	rst		$28			; $6726: $ef 
	ld		l, b			; $6727: $68 
	rst		$28			; $6728: $ef 
	ld		l, b			; $6729: $68 
	add		b			; $672a: $80 
	ld		l, c			; $672b: $69 
	ld		d, b			; $672c: $50 
	ld		l, d			; $672d: $6a 
	sbc		h			; $672e: $9c 
	ld		l, d			; $672f: $6a 
	ld		l, c			; $6730: $69 
	ld		l, d			; $6731: $6a 
	sub		b			; $6732: $90 
	ld		l, d			; $6733: $6a 
	xor		b			; $6734: $a8 
	ld		l, d			; $6735: $6a 
	xor		b			; $6736: $a8 
	ld		l, d			; $6737: $6a 
	ld		(hl), l			; $6738: $75 
	ld		l, d			; $6739: $6a 
	xor		b			; $673a: $a8 
	ld		l, d			; $673b: $6a 
	sub		h			; $673c: $94 
	ld		(hl), b			; $673d: $70 
	sbc		a			; $673e: $9f 
	ld		(hl), b			; $673f: $70 
	xor		d			; $6740: $aa 
	ld		(hl), b			; $6741: $70 
	or		l			; $6742: $b5 
	ld		(hl), b			; $6743: $70 
	ret		nz			; $6744: $c0 
	ld		(hl), b			; $6745: $70 
	bit		6, b			; $6746: $cb $70 
	sub		$70			; $6748: $d6 $70 
	pop		hl			; $674a: $e1 
	ld		(hl), b			; $674b: $70 
	pop		bc			; $674c: $c1 
	ld		a, c			; $674d: $79 
	call		z, $d779		; $674e: $cc $79 $d7 
	ld		a, c			; $6751: $79 
	ld		($ff00+c), a		; $6752: $e2 
	ld		a, c			; $6753: $79 
.db $ed
	ld		a, c			; $6755: $79 
	ld		hl, sp+$79		; $6756: $f8 $79 
	inc		bc			; $6758: $03 
	ld		a, d			; $6759: $7a 
	ld		c, $7a			; $675a: $0e $7a 
	ld		c, a			; $675c: $4f 
	ld		a, (hl)			; $675d: $7e 
	add		hl, de			; $675e: $19 
	ld		a, d			; $675f: $7a 
	inc		h			; $6760: $24 
	ld		a, d			; $6761: $7a 
; end

; timer irq handler routine
TIMER_IRQ:
	push		af			; $6762: $f5 
	push		bc			; $6763: $c5 
	push		de			; $6764: $d5 
	push		hl			; $6765: $e5 
	ld		a, $03			; $6766: $3e $03 
	ldh		($ff), a		; $6768: $e0 $ff 
	ei					; $676a: $fb 
	ldh		a, ($df)		; $676b: $f0 $df 
	cp		$01			; $676d: $fe $01 
	jr		z, $40			; $676f: $28 $40 
	cp		$02			; $6771: $fe $02 
	jr		z, $5a			; $6773: $28 $5a 
	ldh		a, ($de)		; $6775: $f0 $de 
	and		a			; $6777: $a7 
	jr		nz, $5a			; $6778: $20 $5a 
	ld		c, $d3			; $677a: $0e $d3 
	ld		a, ($ff00+c)		; $677c: $f2 
	and		a			; $677d: $a7 
	jr		z, $07			; $677e: $28 $07 
	xor		a			; $6780: $af 
	ld		($ff00+c), a		; $6781: $e2 
	ld		a, $08			; $6782: $3e $08 
	ld		($dfe0), a		; $6784: $ea $e0 $df 
	call		$6b59			; $6787: $cd $59 $6b 
	call		$6b79			; $678a: $cd $79 $6b 
	call		$67f4			; $678d: $cd $f4 $67 
	call		$6b9d			; $6790: $cd $9d $6b 
	call		$6db8			; $6793: $cd $b8 $6d 
	call		$6bef			; $6796: $cd $ef $6b 
	xor		a			; $6799: $af 
	ld		($dfe0), a		; $679a: $ea $e0 $df 
	ld		($dfe8), a		; $679d: $ea $e8 $df 
	ld		($dff0), a		; $67a0: $ea $f0 $df 
	ld		($dff8), a		; $67a3: $ea $f8 $df 
	ldh		($df), a		; $67a6: $e0 $df 
	ld		a, $07			; $67a8: $3e $07 
	ldh		($ff), a		; $67aa: $e0 $ff 
	pop		hl			; $67ac: $e1 
	pop		de			; $67ad: $d1 
	pop		bc			; $67ae: $c1 
	pop		af			; $67af: $f1 
	reti					; $67b0: $d9 

	call		$6b4b			; $67b1: $cd $4b $6b 
	xor		a			; $67b4: $af 
	ld		($dfe1), a		; $67b5: $ea $e1 $df 
	ld		($dff1), a		; $67b8: $ea $f1 $df 
	ld		($dff9), a		; $67bb: $ea $f9 $df 
	ld		a, $30			; $67be: $3e $30 
	ldh		($de), a		; $67c0: $e0 $de 
	ld		hl, $67ec		; $67c2: $21 $ec $67 
	call		$6adf			; $67c5: $cd $df $6a 
	jr		-$31			; $67c8: $18 $cf 
	ld		hl, $67f0		; $67ca: $21 $f0 $67 
	jr		-$0a			; $67cd: $18 $f6 
	xor		a			; $67cf: $af 
	ldh		($de), a		; $67d0: $e0 $de 
	jr		-$4d			; $67d2: $18 $b3 
	ld		hl, $ffde		; $67d4: $21 $de $ff 
	dec		(hl)			; $67d7: $35 
	ld		a, (hl)			; $67d8: $7e 
	cp		$28			; $67d9: $fe $28 
	jr		z, -$13			; $67db: $28 $ed 
	cp		$20			; $67dd: $fe $20 
	jr		z, -$1f			; $67df: $28 $e1 
	cp		$18			; $67e1: $fe $18 
	jr		z, -$1b			; $67e3: $28 $e5 
	cp		$10			; $67e5: $fe $10 
	jr		nz, -$50			; $67e7: $20 $b0 
	inc		(hl)			; $67e9: $34 
	jr		-$53			; $67ea: $18 $ad 
; end routine

; data
	or		d			; $67ec: $b2 
.db $e3
	add		e			; $67ee: $83 
	rst		$0			; $67ef: $c7 
	or		d			; $67f0: $b2 
.db $e3
	pop		bc			; $67f2: $c1 
	rst		$0			; $67f3: $c7 
; end data

; routine
	ld		a, ($dff0)		; $67f4: $fa $f0 $df 
	cp		$01			; $67f7: $fe $01 
	jr		z, $0d			; $67f9: $28 $0d 
	ld		a, ($dff1)		; $67fb: $fa $f1 $df 
	cp		$01			; $67fe: $fe $01 
	jr		z, $2b			; $6800: $28 $2b 
	ret					; $6802: $c9 
; end routine

; data??
	add		b			; $6803: $80 
	ldd		a, (hl)			; $6804: $3a 
	jr		nz, -$50			; $6805: $20 $b0 
.db $c6
; end data ? ? ?

; routine
	ld		($dff1), a
	ld		hl, $df3f		; $680b: $21 $3f $df 
	set		7, (hl)			; $680e: $cb $fe 
	xor		a			; $6810: $af 
	ld		($dff4), a		; $6811: $ea $f4 $df 
	ldh		($1a), a		; $6814: $e0 $1a 
	ld		hl, $7047		; $6816: $21 $47 $70 
	call		$6b19			; $6819: $cd $19 $6b 
	ldh		a, ($04)		; $681c: $f0 $04 
	and		$1f			; $681e: $e6 $1f 
	ld		b, a			; $6820: $47 
	ld		a, $d0			; $6821: $3e $d0 
	add		b			; $6823: $80 
	ld		($dff5), a		; $6824: $ea $f5 $df 
	ld		hl, $6803		; $6827: $21 $03 $68 
	jp		$6ae6			; $682a: $c3 $e6 $6a 
	ldh		a, ($04)		; $682d: $f0 $04 
	and		$07			; $682f: $e6 $07 
	ld		b, a			; $6831: $47 
	ld		hl, $dff4		; $6832: $21 $f4 $df 
	inc		(hl)			; $6835: $34 
	ld		a, (hl)			; $6836: $7e 
	ld		hl, $dff5		; $6837: $21 $f5 $df 
	cp		$0e			; $683a: $fe $0e 
	jr		nc, $0a			; $683c: $30 $0a 
	inc		(hl)			; $683e: $34 
	inc		(hl)			; $683f: $34 
	ld		a, (hl)			; $6840: $7e 
	and		$f8			; $6841: $e6 $f8 
	or		b			; $6843: $b0 
	ld		c, $1d			; $6844: $0e $1d 
	ld		($ff00+c), a		; $6846: $e2 
	ret					; $6847: $c9 
	cp		$1e			; $6848: $fe $1e 
	jr		z, $05			; $684a: $28 $05 
	dec		(hl)			; $684c: $35 
	dec		(hl)			; $684d: $35 
	dec		(hl)			; $684e: $35 
	jr		-$11			; $684f: $18 $ef 
	xor		a			; $6851: $af 
	ld		($dff1), a		; $6852: $ea $f1 $df 
	ldh		($1a), a		; $6855: $e0 $1a 
	ld		hl, $df3f		; $6857: $21 $3f $df 
	res		7, (hl)			; $685a: $cb $be 
	ld		bc, $df36		; $685c: $01 $36 $df 
	ld		a, (bc)			; $685f: $0a 
	ld		l, a			; $6860: $6f 
	inc		c			; $6861: $0c 
	ld		a, (bc)			; $6862: $0a 
	ld		h, a			; $6863: $67 
	call		$6b19			; $6864: $cd $19 $6b 
	ret					; $6867: $c9 
; end routine

; data
	nop					; $6868: $00 
	or		b			; $6869: $b0 
	ld		d, e			; $686a: $53 
	add		b			; $686b: $80 
	rst		$0			; $686c: $c7 
; end ? ? ?? 
	ld		a, $03			; $686d: $3e $03 
	ld		hl, $6868		; $686f: $21 $68 $68 
	jp		$6ab9			; $6872: $c3 $b9 $6a 
	inc		a			; $6875: $3c 
	add		b			; $6876: $80 
	and		b			; $6877: $a0 
	ld		d, b			; $6878: $50 
	add		h			; $6879: $84 
	call		$689b			; $687a: $cd $9b $68 
	ret		z			; $687d: $c8 
	ld		a, $0e			; $687e: $3e $0e 
	ld		hl, $6875		; $6880: $21 $75 $68 
	jp		$6ab9			; $6883: $c3 $b9 $6a 
; data ? ?
	nop					; $6886: $00 
	add		b			; $6887: $80 
	jp		nc, $860a		; $6888: $d2 $0a $86 
	dec		a			; $688b: $3d 
	add		b			; $688c: $80 
	and		e			; $688d: $a3 
	add		hl, bc			; $688e: $09 
	add		a			; $688f: $87 
	ld		a, ($dfe1)		; $6890: $fa $e1 $df 
	jr		$0c			; $6893: $18 $0c 
	ld		a, ($dfe1)		; $6895: $fa $e1 $df 
	cp		$03			; $6898: $fe $03 
	ret		z			; $689a: $c8 
	ld		a, ($dfe1)		; $689b: $fa $e1 $df 
	cp		$05			; $689e: $fe $05 
	ret		z			; $68a0: $c8 
	cp		$04			; $68a1: $fe $04 
	ret		z			; $68a3: $c8 
	cp		$06			; $68a4: $fe $06 
	ret		z			; $68a6: $c8 
	cp		$08			; $68a7: $fe $08 
	ret		z			; $68a9: $c8 
	cp		$0b			; $68aa: $fe $0b 
	ret		z			; $68ac: $c8 
	ret					; $68ad: $c9 
	call		$6895			; $68ae: $cd $95 $68 
	ret		z			; $68b1: $c8 
	ld		a, $10			; $68b2: $3e $10 
	ld		hl, $6886		; $68b4: $21 $86 $68 
	call		$6ab9			; $68b7: $cd $b9 $6a 
	ld		hl, $dfe4		; $68ba: $21 $e4 $df 
	ld		(hl), $0a		; $68bd: $36 $0a 
	inc		l			; $68bf: $2c 
	ld		(hl), $86		; $68c0: $36 $86 
	ret					; $68c2: $c9 
	call		$6b0c			; $68c3: $cd $0c $6b 
	and		a			; $68c6: $a7 
	jp		z, $68f4		; $68c7: $ca $f4 $68 
	ld		hl, $dfe4		; $68ca: $21 $e4 $df 
	ld		e, (hl)			; $68cd: $5e 
	inc		l			; $68ce: $2c 
	ld		d, (hl)			; $68cf: $56 
	push		hl			; $68d0: $e5 
	ld		hl, $000f		; $68d1: $21 $0f $00 
	add		hl, de			; $68d4: $19 
	ld		c, $13			; $68d5: $0e $13 
	ld		a, l			; $68d7: $7d 
	ld		($ff00+c), a		; $68d8: $e2 
	ld		b, a			; $68d9: $47 
	inc		c			; $68da: $0c 
	ld		a, h			; $68db: $7c 
	and		$3f			; $68dc: $e6 $3f 
	ld		($ff00+c), a		; $68de: $e2 
	pop		hl			; $68df: $e1 
	ldd		(hl), a			; $68e0: $32 
	ld		(hl), b			; $68e1: $70 
	ret					; $68e2: $c9 
	call		$6895			; $68e3: $cd $95 $68 
	ret		z			; $68e6: $c8 
	ld		a, $03			; $68e7: $3e $03 
	ld		hl, $688b		; $68e9: $21 $8b $68 
	jp		$6ab9			; $68ec: $c3 $b9 $6a 
	call		$6b0c			; $68ef: $cd $0c $6b 
	and		a			; $68f2: $a7 
	ret		nz			; $68f3: $c0 
	xor		a			; $68f4: $af 
	ld		($dfe1), a		; $68f5: $ea $e1 $df 
	ldh		($10), a		; $68f8: $e0 $10 
	ldh		($12), a		; $68fa: $e0 $12 
	ld		hl, $df1f		; $68fc: $21 $1f $df 
	res		7, (hl)			; $68ff: $cb $be 
	ret					; $6901: $c9 
	nop					; $6902: $00 
	add		b			; $6903: $80 
	ld		($ff00+c), a		; $6904: $e2 
	ld		b, $87			; $6905: $06 $87 
	nop					; $6907: $00 
	add		b			; $6908: $80 
	ld		($ff00+c), a		; $6909: $e2 
	add		e			; $690a: $83 
	add		a			; $690b: $87 
	call		$6890			; $690c: $cd $90 $68 
	ret		z			; $690f: $c8 
	ld		hl, $6902		; $6910: $21 $02 $69 
	jp		$6ab9			; $6913: $c3 $b9 $6a 
	ld		hl, $dfe4		; $6916: $21 $e4 $df 
	inc		(hl)			; $6919: $34 
	ld		a, (hl)			; $691a: $7e 
	cp		$04			; $691b: $fe $04 
	jr		z, $06			; $691d: $28 $06 
	cp		$18			; $691f: $fe $18 
	jp		z, $68f4		; $6921: $ca $f4 $68 
	ret					; $6924: $c9 
	ld		hl, $6907		; $6925: $21 $07 $69 
	call		$6ad8			; $6928: $cd $d8 $6a 
	ret					; $692b: $c9 
	ld		d, a			; $692c: $57 
	sub		(hl)			; $692d: $96 
	adc		h			; $692e: $8c 
	jr		nc, -$39			; $692f: $30 $c7 
	ld		d, a			; $6931: $57 
	sub		(hl)			; $6932: $96 
	adc		h			; $6933: $8c 
	dec		(hl)			; $6934: $35 
	rst		$0			; $6935: $c7 
	call		$689b			; $6936: $cd $9b $68 
	ret		z			; $6939: $c8 
	ld		a, $08			; $693a: $3e $08 
	ld		hl, $692c		; $693c: $21 $2c $69 
	jp		$6ab9			; $693f: $c3 $b9 $6a 
	call		$6b0c			; $6942: $cd $0c $6b 
	and		a			; $6945: $a7 
	ret		nz			; $6946: $c0 
	ld		hl, $dfe4		; $6947: $21 $e4 $df 
	ld		a, (hl)			; $694a: $7e 
	inc		(hl)			; $694b: $34 
	cp		$00			; $694c: $fe $00 
	jr		z, $06			; $694e: $28 $06 
	cp		$01			; $6950: $fe $01 
	jp		z, $68f4		; $6952: $ca $f4 $68 
	ret					; $6955: $c9 
	ld		hl, $6931		; $6956: $21 $31 $69 
	jp		$6ad8			; $6959: $c3 $d8 $6a 
	ld		d, h			; $695c: $54 
	nop					; $695d: $00 
	sbc		d			; $695e: $9a 
	jr		nz, -$79			; $695f: $20 $87 
	ld		a, $60			; $6961: $3e $60 
	ld		($dfe6), a		; $6963: $ea $e6 $df 
	ld		a, $05			; $6966: $3e $05 
	ld		hl, $695c		; $6968: $21 $5c $69 
	jp		$6ab9			; $696b: $c3 $b9 $6a 
	daa					; $696e: $27 
	add		b			; $696f: $80 
	adc		d			; $6970: $8a 
	stop					; $6971: $10 
	add		(hl)			; $6972: $86 
	ld		a, $10			; $6973: $3e $10 
	ld		($dfe6), a		; $6975: $ea $e6 $df 
	ld		a, $05			; $6978: $3e $05 
	ld		hl, $696e		; $697a: $21 $6e $69 
	jp		$6ab9			; $697d: $c3 $b9 $6a 
	call		$6b0c			; $6980: $cd $0c $6b 
	and		a			; $6983: $a7 
	ret		nz			; $6984: $c0 
	ld		hl, $dfe6		; $6985: $21 $e6 $df 
	ld		a, $10			; $6988: $3e $10 
	add		(hl)			; $698a: $86 
	ld		(hl), a			; $698b: $77 
	cp		$e0			; $698c: $fe $e0 
	jp		z, $68f4		; $698e: $ca $f4 $68 
	ld		c, $13			; $6991: $0e $13 
	ld		($ff00+c), a		; $6993: $e2 
	inc		c			; $6994: $0c 
	ld		a, $86			; $6995: $3e $86 
	ld		($ff00+c), a		; $6997: $e2 
	ret					; $6998: $c9 
	inc		l			; $6999: $2c 
	add		b			; $699a: $80 
.db $d3
	ld		b, b			; $699c: $40 
	add		h			; $699d: $84 
	call		$689b			; $699e: $cd $9b $68 
	ret		z			; $69a1: $c8 
	ld		a, $08			; $69a2: $3e $08 
	ld		hl, $6999		; $69a4: $21 $99 $69 
	jp		$6ab9			; $69a7: $c3 $b9 $6a 
	ldd		a, (hl)			; $69aa: $3a 
	add		b			; $69ab: $80 
.db $e3
	jr		nz, -$7a			; $69ad: $20 $86 
	di					; $69af: $f3 
	or		e			; $69b0: $b3 
	and		e			; $69b1: $a3 
	sub		e			; $69b2: $93 
	add		e			; $69b3: $83 
	ld		(hl), e			; $69b4: $73 
	ld		h, e			; $69b5: $63 
	ld		d, e			; $69b6: $53 
	ld		b, e			; $69b7: $43 
	inc		sp			; $69b8: $33 
	inc		hl			; $69b9: $23 
	inc		hl			; $69ba: $23 
	inc		de			; $69bb: $13 
	nop					; $69bc: $00 
	ld		a, ($dfe1)		; $69bd: $fa $e1 $df 
	cp		$08			; $69c0: $fe $08 
	ret		z			; $69c2: $c8 
	ld		a, $06			; $69c3: $3e $06 
	ld		hl, $69aa		; $69c5: $21 $aa $69 
	jp		$6ab9			; $69c8: $c3 $b9 $6a 
	call		$6b0c			; $69cb: $cd $0c $6b 
	and		a			; $69ce: $a7 
	ret		nz			; $69cf: $c0 
	ld		hl, $dfe4		; $69d0: $21 $e4 $df 
	ld		c, (hl)			; $69d3: $4e 
	inc		(hl)			; $69d4: $34 
	ld		b, $00			; $69d5: $06 $00 
	ld		hl, $69af		; $69d7: $21 $af $69 
	add		hl, bc			; $69da: $09 
	ld		a, (hl)			; $69db: $7e 
	and		a			; $69dc: $a7 
	jp		z, $68f4		; $69dd: $ca $f4 $68 
	ld		c, $12			; $69e0: $0e $12 
	ld		($ff00+c), a		; $69e2: $e2 
	inc		c			; $69e3: $0c 
	inc		c			; $69e4: $0c 
	ld		a, $87			; $69e5: $3e $87 
	ld		($ff00+c), a		; $69e7: $e2 
	ret					; $69e8: $c9 
	ld		a, $06			; $69e9: $3e $06 
	ld		hl, $69f1		; $69eb: $21 $f1 $69 
	jp		$6ab9			; $69ee: $c3 $b9 $6a 
	nop					; $69f1: $00 
	jr		nc, -$10			; $69f2: $30 $f0 
	and		a			; $69f4: $a7 
	rst		$0			; $69f5: $c7 
	nop					; $69f6: $00 
	jr		nc, -$10			; $69f7: $30 $f0 
	or		c			; $69f9: $b1 
	rst		$0			; $69fa: $c7 
	nop					; $69fb: $00 
	jr		nc, -$10			; $69fc: $30 $f0 
	cp		d			; $69fe: $ba 
	rst		$0			; $69ff: $c7 
	nop					; $6a00: $00 
	jr		nc, -$10			; $6a01: $30 $f0 
	call		nz, $00c7		; $6a03: $c4 $c7 $00 
	jr		nc, -$10			; $6a06: $30 $f0 
	call		nc, $00c7		; $6a08: $d4 $c7 $00 
	jr		nc, -$10			; $6a0b: $30 $f0 
	set		0, a			; $6a0d: $cb $c7 
	call		$6b0c			; $6a0f: $cd $0c $6b 
	and		a			; $6a12: $a7 
	ret		nz			; $6a13: $c0 
	ld		a, ($dfe4)		; $6a14: $fa $e4 $df 
	inc		a			; $6a17: $3c 
	ld		($dfe4), a		; $6a18: $ea $e4 $df 
	cp		$01			; $6a1b: $fe $01 
	jr		z, $13			; $6a1d: $28 $13 
	cp		$02			; $6a1f: $fe $02 
	jr		z, $14			; $6a21: $28 $14 
	cp		$03			; $6a23: $fe $03 
	jr		z, $15			; $6a25: $28 $15 
	cp		$04			; $6a27: $fe $04 
	jr		z, $16			; $6a29: $28 $16 
	cp		$05			; $6a2b: $fe $05 
	jr		z, $17			; $6a2d: $28 $17 
	jp		$68f4			; $6a2f: $c3 $f4 $68 
	ld		hl, $69f6		; $6a32: $21 $f6 $69 
	jr		$12			; $6a35: $18 $12 
	ld		hl, $69fb		; $6a37: $21 $fb $69 
	jr		$0d			; $6a3a: $18 $0d 
	ld		hl, $6a00		; $6a3c: $21 $00 $6a 
	jr		$08			; $6a3f: $18 $08 
	ld		hl, $6a05		; $6a41: $21 $05 $6a 
	jr		$03			; $6a44: $18 $03 
	ld		hl, $6a0a		; $6a46: $21 $0a $6a 
	jp		$6ad8			; $6a49: $c3 $d8 $6a 
	nop					; $6a4c: $00 
.db $f4
	ld		d, a			; $6a4e: $57 
	add		b			; $6a4f: $80 
	ld		a, $30			; $6a50: $3e $30 
	ld		hl, $6a4c		; $6a52: $21 $4c $6a 
	jp		$6ab9			; $6a55: $c3 $b9 $6a 
	ld		a, ($dff9)		; $6a58: $fa $f9 $df 
	cp		$01			; $6a5b: $fe $01 
	ret		z			; $6a5d: $c8 
	ret					; $6a5e: $c9 
	nop					; $6a5f: $00 
	inc		l			; $6a60: $2c 
	ld		e, $80			; $6a61: $1e $80 
	rra					; $6a63: $1f 
	dec		l			; $6a64: $2d 
	cpl					; $6a65: $2f 
	dec		a			; $6a66: $3d 
	ccf					; $6a67: $3f 
	nop					; $6a68: $00 
	call		$6a58			; $6a69: $cd $58 $6a 
	ret		z			; $6a6c: $c8 
	ld		a, $06			; $6a6d: $3e $06 
	ld		hl, $6a5f		; $6a6f: $21 $5f $6a 
	jp		$6ab9			; $6a72: $c3 $b9 $6a 
	call		$6b0c			; $6a75: $cd $0c $6b 
	and		a			; $6a78: $a7 
	ret		nz			; $6a79: $c0 
	ld		hl, $dffc		; $6a7a: $21 $fc $df 
	ld		c, (hl)			; $6a7d: $4e 
	inc		(hl)			; $6a7e: $34 
	ld		b, $00			; $6a7f: $06 $00 
	ld		hl, $6a63		; $6a81: $21 $63 $6a 
	add		hl, bc			; $6a84: $09 
	ld		a, (hl)			; $6a85: $7e 
	and		a			; $6a86: $a7 
	jr		z, $24			; $6a87: $28 $24 
	ldh		($22), a		; $6a89: $e0 $22 
	ret					; $6a8b: $c9 
	nop					; $6a8c: $00 
	ld		l, l			; $6a8d: $6d 
	ld		d, h			; $6a8e: $54 
	add		b			; $6a8f: $80 
	ld		a, $16			; $6a90: $3e $16 
	ld		hl, $6a8c		; $6a92: $21 $8c $6a 
	jp		$6ab9			; $6a95: $c3 $b9 $6a 
	nop					; $6a98: $00 
	ld		a, ($ff00+c)		; $6a99: $f2 
	ld		d, l			; $6a9a: $55 
	add		b			; $6a9b: $80 
	call		$6a58			; $6a9c: $cd $58 $6a 
	ret		z			; $6a9f: $c8 
	ld		a, $15			; $6aa0: $3e $15 
	ld		hl, $6a98		; $6aa2: $21 $98 $6a 
	jp		$6ab9			; $6aa5: $c3 $b9 $6a 
	call		$6b0c			; $6aa8: $cd $0c $6b 
	and		a			; $6aab: $a7 
	ret		nz			; $6aac: $c0 
	xor		a			; $6aad: $af 
	ld		($dff9), a		; $6aae: $ea $f9 $df 
	ldh		($21), a		; $6ab1: $e0 $21 
	ld		hl, $df4f		; $6ab3: $21 $4f $df 
	res		7, (hl)			; $6ab6: $cb $be 
	ret					; $6ab8: $c9 

; routine
	push		af			; $6ab9: $f5 
	dec		e			; $6aba: $1d 
	ldh		a, ($d1)		; $6abb: $f0 $d1 
	ld		(de), a			; $6abd: $12 
	inc		e			; $6abe: $1c 
	pop		af			; $6abf: $f1 
	inc		e			; $6ac0: $1c 
	ld		(de), a			; $6ac1: $12 
	dec		e			; $6ac2: $1d 
	xor		a			; $6ac3: $af 
	ld		(de), a			; $6ac4: $12 
	inc		e			; $6ac5: $1c 
	inc		e			; $6ac6: $1c 
	ld		(de), a			; $6ac7: $12 
	inc		e			; $6ac8: $1c 
	ld		(de), a			; $6ac9: $12 
	ld		a, e			; $6aca: $7b 
	cp		$e5			; $6acb: $fe $e5 
	jr		z, $09			; $6acd: $28 $09 
	cp		$f5			; $6acf: $fe $f5 
	jr		z, $13			; $6ad1: $28 $13 
	cp		$fd			; $6ad3: $fe $fd 
	jr		z, $16			; $6ad5: $28 $16 
	ret					; $6ad7: $c9 

	push		bc			; $6ad8: $c5 
	ld		c, $10			; $6ad9: $0e $10 
	ld		b, $05			; $6adb: $06 $05 
	jr		$13			; $6add: $18 $13 
	push		bc			; $6adf: $c5 
	ld		c, $16			; $6ae0: $0e $16 
	ld		b, $04			; $6ae2: $06 $04 
	jr		$0c			; $6ae4: $18 $0c 
	push		bc			; $6ae6: $c5 
	ld		c, $1a			; $6ae7: $0e $1a 
	ld		b, $05			; $6ae9: $06 $05 
	jr		$05			; $6aeb: $18 $05 
	push		bc			; $6aed: $c5 
	ld		c, $20			; $6aee: $0e $20 
	ld		b, $04			; $6af0: $06 $04 
	ldi		a, (hl)			; $6af2: $2a 
	ld		($ff00+c), a		; $6af3: $e2 
	inc		c			; $6af4: $0c 
	dec		b			; $6af5: $05 
	jr		nz, -$06			; $6af6: $20 $fa 
	pop		bc			; $6af8: $c1 
	ret					; $6af9: $c9 
	inc		e			; $6afa: $1c 
	ldh		($d1), a		; $6afb: $e0 $d1 
	inc		e			; $6afd: $1c 
	dec		a			; $6afe: $3d 
	sla		a			; $6aff: $cb $27 
	ld		c, a			; $6b01: $4f 
	ld		b, $00			; $6b02: $06 $00 
	add		hl, bc			; $6b04: $09 
	ld		c, (hl)			; $6b05: $4e 
	inc		hl			; $6b06: $23 
	ld		b, (hl)			; $6b07: $46 
	ld		l, c			; $6b08: $69 
	ld		h, b			; $6b09: $60 
	ld		a, h			; $6b0a: $7c 
	ret					; $6b0b: $c9 
	push		de			; $6b0c: $d5 
	ld		l, e			; $6b0d: $6b 
	ld		h, d			; $6b0e: $62 
	inc		(hl)			; $6b0f: $34 
	ldi		a, (hl)			; $6b10: $2a 
	cp		(hl)			; $6b11: $be 
	jr		nz, $03			; $6b12: $20 $03 
	dec		l			; $6b14: $2d 
	xor		a			; $6b15: $af 
	ld		(hl), a			; $6b16: $77 
	pop		de			; $6b17: $d1 
	ret					; $6b18: $c9 
	push		bc			; $6b19: $c5 
	ld		c, $30			; $6b1a: $0e $30 
	ldi		a, (hl)			; $6b1c: $2a 
	ld		($ff00+c), a		; $6b1d: $e2 
	inc		c			; $6b1e: $0c 
	ld		a, c			; $6b1f: $79 
	cp		$40			; $6b20: $fe $40 
	jr		nz, -$08			; $6b22: $20 $f8 
	pop		bc			; $6b24: $c1 
	ret					; $6b25: $c9 

; routine_00 jumps here
; this is probably sound init
SOUND_INIT:
	; init some wram1 and hram vars
	xor		a			; $6b26: $af 
	ld		($dfe1), a		; $6b27: $ea $e1 $df 
	ld		($dfe9), a		; $6b2a: $ea $e9 $df 
	ld		($dff1), a		; $6b2d: $ea $f1 $df 
	ld		($dff9), a		; $6b30: $ea $f9 $df 
	ld		($df1f), a		; $6b33: $ea $1f $df 
	ld		($df2f), a		; $6b36: $ea $2f $df 
	ld		($df3f), a		; $6b39: $ea $3f $df 
	ld		($df4f), a		; $6b3c: $ea $4f $df 
	ldh		($df), a		; $6b3f: $e0 $df 
	ldh		($de), a		; $6b41: $e0 $de 

	; output all oscilattors to all output terminals
	ld		a, $ff			; $6b43: $3e $ff 
	ldh		($25), a		; $6b45: $e0 $25 

	; init another hram var
	ld		a, $03			; $6b47: $3e $03 
	ldh		($d8), a		; $6b49: $e0 $d8 

	; init some more sound io registers
	ld		a, $01			; $6b4b: $3e $01 
	ldh		($12), a		; $6b4d: $e0 $12 
	ldh		($17), a		; $6b4f: $e0 $17 
	ldh		($21), a		; $6b51: $e0 $21 
	xor		a			; $6b53: $af 
	ldh		($10), a		; $6b54: $e0 $10 
	ldh		($1a), a		; $6b56: $e0 $1a 
	ret					; $6b58: $c9 
; end

; routine
	ld		de, $dfe0		; $6b59: $11 $e0 $df 
	ld		a, (de)			; $6b5c: $1a 
	and		a			; $6b5d: $a7 
	jr		z, $0c			; $6b5e: $28 $0c 
	ld		hl, $df1f		; $6b60: $21 $1f $df 
	set		7, (hl)			; $6b63: $cb $fe 
	ld		hl, $6700		; $6b65: $21 $00 $67 
	call		$6afa			; $6b68: $cd $fa $6a 
	jp		hl			; $6b6b: $e9 
	inc		e			; $6b6c: $1c 
	ld		a, (de)			; $6b6d: $1a 
	and		a			; $6b6e: $a7 
	jr		z, $07			; $6b6f: $28 $07 
	ld		hl, $6716		; $6b71: $21 $16 $67 
	call		$6afd			; $6b74: $cd $fd $6a 
	jp		hl			; $6b77: $e9 
	ret					; $6b78: $c9 

; routine
	ld		de, $dff8		; $6b79: $11 $f8 $df 
	ld		a, (de)			; $6b7c: $1a 
	and		a			; $6b7d: $a7 
	jr		z, $0c			; $6b7e: $28 $0c 
	ld		hl, $df4f		; $6b80: $21 $4f $df 
	set		7, (hl)			; $6b83: $cb $fe 
	ld		hl, $672c		; $6b85: $21 $2c $67 
	call		$6afa			; $6b88: $cd $fa $6a 
	jp		hl			; $6b8b: $e9 
	inc		e			; $6b8c: $1c 
	ld		a, (de)			; $6b8d: $1a 
	and		a			; $6b8e: $a7 
	jr		z, $07			; $6b8f: $28 $07 
	ld		hl, $6734		; $6b91: $21 $34 $67 
	call		$6afd			; $6b94: $cd $fd $6a 
	jp		hl			; $6b97: $e9 
	ret					; $6b98: $c9 
	call		$6b26			; $6b99: $cd $26 $6b 
	ret					; $6b9c: $c9 

; routine
	ld		hl, $dfe8		; $6b9d: $21 $e8 $df 
	ldi		a, (hl)			; $6ba0: $2a 
	and		a			; $6ba1: $a7 
	ret		z			; $6ba2: $c8 
	ld		(hl), a			; $6ba3: $77 
	cp		$ff			; $6ba4: $fe $ff 
	jr		z, -$0f			; $6ba6: $28 $f1 
	ld		b, a			; $6ba8: $47 
	ld		hl, $673c		; $6ba9: $21 $3c $67 
	ld		a, b			; $6bac: $78 
	and		$1f			; $6bad: $e6 $1f 
	call		$6afd			; $6baf: $cd $fd $6a 
	call		$6c88			; $6bb2: $cd $88 $6c 
	call		$6bb9			; $6bb5: $cd $b9 $6b 
	ret					; $6bb8: $c9 
	ld		a, ($dfe9)		; $6bb9: $fa $e9 $df 
	and		a			; $6bbc: $a7 
	ret		z			; $6bbd: $c8 
	ld		hl, $6c2b		; $6bbe: $21 $2b $6c 
	dec		a			; $6bc1: $3d 
	jr		z, $06			; $6bc2: $28 $06 
	inc		hl			; $6bc4: $23 
	inc		hl			; $6bc5: $23 
	inc		hl			; $6bc6: $23 
	inc		hl			; $6bc7: $23 
	jr		-$09			; $6bc8: $18 $f7 
	ldi		a, (hl)			; $6bca: $2a 
	ldh		($d8), a		; $6bcb: $e0 $d8 
	ldi		a, (hl)			; $6bcd: $2a 
	ldh		($d6), a		; $6bce: $e0 $d6 
	ldi		a, (hl)			; $6bd0: $2a 
	; set the alternating pannings
	ldh		($d9), a		; $6bd1: $e0 $d9 
	ldi		a, (hl)			; $6bd3: $2a 
	ldh		($da), a		; $6bd4: $e0 $da 
	xor		a			; $6bd6: $af 
	ldh		($d5), a		; $6bd7: $e0 $d5 
	ldh		($d7), a		; $6bd9: $e0 $d7 
	ret					; $6bdb: $c9 
	ld		a, ($dff9)		; $6bdc: $fa $f9 $df 
	cp		$01			; $6bdf: $fe $01 
	ret		nz			; $6be1: $c0 
	ld		a, (hl)			; $6be2: $7e 
	bit		1, a			; $6be3: $cb $4f 
	ld		a, $f7			; $6be5: $3e $f7 
	jr		z, $02			; $6be7: $28 $02 
	ld		a, $7f			; $6be9: $3e $7f 
	call		$6c1f			; $6beb: $cd $1f $6c 
	ret					; $6bee: $c9 

; routine
	ld		a, ($dfe9)		; $6bef: $fa $e9 $df 
	and		a			; $6bf2: $a7 
	jr		z, $2e			; $6bf3: $28 $2e 
	ld		hl, $ffd5		; $6bf5: $21 $d5 $ff 
	call		$6bdc			; $6bf8: $cd $dc $6b 
	ld		a, ($ffb3)		; $6bfb: $fa $b3 $ff 
	cp		$05			; $6bfe: $fe $05 
	jr		z, $21			; $6c00: $28 $21 
	ldh		a, ($d8)		; $6c02: $f0 $d8 
	cp		$01			; $6c04: $fe $01 
	jr		z, $1f			; $6c06: $28 $1f 
	cp		$03			; $6c08: $fe $03 
	jr		z, $17			; $6c0a: $28 $17 
	inc		(hl)			; $6c0c: $34 
	ldi		a, (hl)			; $6c0d: $2a 
	cp		(hl)			; $6c0e: $be 
	ret		nz			; $6c0f: $c0 
	dec		l			; $6c10: $2d 
	ld		(hl), $00		; $6c11: $36 $00 
	inc		l			; $6c13: $2c 
	inc		l			; $6c14: $2c 
	inc		(hl)			; $6c15: $34 
	ldh		a, ($d9)		; $6c16: $f0 $d9 
	bit		0, (hl)			; $6c18: $cb $46 
	jp		z, $6c1f		; $6c1a: $ca $1f $6c 
	ldh		a, ($da)		; $6c1d: $f0 $da 
	ld		c, $25			; $6c1f: $0e $25 
	ld		($ff00+c), a		; $6c21: $e2 
	ret					; $6c22: $c9 
	ld		a, $ff			; $6c23: $3e $ff 
	jr		-$08			; $6c25: $18 $f8 
	ldh		a, ($d9)		; $6c27: $f0 $d9 
	jr		-$0c			; $6c29: $18 $f4 
; end routine ???

; data here?
	ld		(bc), a			; $6c2b: $02 
	inc		h			; $6c2c: $24 
	ld		h, l			; $6c2d: $65 
	ld		d, (hl)			; $6c2e: $56 
	ld		bc, $bd00		; $6c2f: $01 $00 $bd 
	nop					; $6c32: $00 
	ld		(bc), a			; $6c33: $02 
	jr		nz, $7f			; $6c34: $20 $7f 
	or		a			; $6c36: $b7 
	ld		bc, $ed00		; $6c37: $01 $00 $ed 
	nop					; $6c3a: $00 
	ld		(bc), a			; $6c3b: $02 
.db $18
.db $7f
.db $f7
	ld		(bc), a			; $6c3f: $02 
.db $40
.db $7f
.db $f7
	ld		(bc), a			; $6c43: $02 
.db $40
; this is panning bytes for level 1
; for my custom music i prefer $ef $fe
.db $7f
.db $f7
	inc		bc			; $6c47: $03 
.db $18
.db $7f
.db $f7
	inc		bc			; $6c4b: $03 
	stop					; $6c4c: $10 
	ld		e, d			; $6c4d: $5a 
	and		l			; $6c4e: $a5 
	ld		bc, $6500		; $6c4f: $01 $00 $65 
	nop					; $6c52: $00 
	inc		bc			; $6c53: $03 
	nop					; $6c54: $00 
	nop					; $6c55: $00 
	nop					; $6c56: $00 
	ld		(bc), a			; $6c57: $02 
	ld		($b57f), sp		; $6c58: $08 $7f $b5 
	ld		bc, $ed00		; $6c5b: $01 $00 $ed 
	nop					; $6c5e: $00 
	ld		bc, $ed00		; $6c5f: $01 $00 $ed 
	nop					; $6c62: $00 
	inc		bc			; $6c63: $03 
	nop					; $6c64: $00 
	nop					; $6c65: $00 
	nop					; $6c66: $00 
	ld		bc, $ed00		; $6c67: $01 $00 $ed 
	nop					; $6c6a: $00 
	ld		(bc), a			; $6c6b: $02 
	jr		$7e			; $6c6c: $18 $7e 
	rst		$20			; $6c6e: $e7 
	ld		bc, $ed18		; $6c6f: $01 $18 $ed 
	rst		$20			; $6c72: $e7 
	ld		bc, $de00		; $6c73: $01 $00 $de 
	nop					; $6c76: $00 
	ldi		a, (hl)			; $6c77: $2a 
	ld		c, a			; $6c78: $4f 
	ld		a, (hl)			; $6c79: $7e 
	ld		b, a			; $6c7a: $47 
	ld		a, (bc)			; $6c7b: $0a 
	ld		(de), a			; $6c7c: $12 
	inc		e			; $6c7d: $1c 
	inc		bc			; $6c7e: $03 
	ld		a, (bc)			; $6c7f: $0a 
	ld		(de), a			; $6c80: $12 
	ret					; $6c81: $c9 
	ldi		a, (hl)			; $6c82: $2a 
	ld		(de), a			; $6c83: $12 
	inc		e			; $6c84: $1c 
	ldi		a, (hl)			; $6c85: $2a 
	ld		(de), a			; $6c86: $12 
	ret					; $6c87: $c9 
	call		$6b4b			; $6c88: $cd $4b $6b 
	xor		a			; $6c8b: $af 
	ld		($ffd5), a		; $6c8c: $ea $d5 $ff 
	ld		($ffd7), a		; $6c8f: $ea $d7 $ff 
	ld		de, $df00		; $6c92: $11 $00 $df 
	ld		b, $00			; $6c95: $06 $00 
	ldi		a, (hl)			; $6c97: $2a 
	ld		(de), a			; $6c98: $12 
	inc		e			; $6c99: $1c 
	call		$6c82			; $6c9a: $cd $82 $6c 
	ld		de, $df10		; $6c9d: $11 $10 $df 
	call		$6c82			; $6ca0: $cd $82 $6c 
	ld		de, $df20		; $6ca3: $11 $20 $df 
	call		$6c82			; $6ca6: $cd $82 $6c 
	ld		de, $df30		; $6ca9: $11 $30 $df 
	call		$6c82			; $6cac: $cd $82 $6c 
	ld		de, $df40		; $6caf: $11 $40 $df 
	call		$6c82			; $6cb2: $cd $82 $6c 
	ld		hl, $df10		; $6cb5: $21 $10 $df 
	ld		de, $df14		; $6cb8: $11 $14 $df 
	call		$6c77			; $6cbb: $cd $77 $6c 
	ld		hl, $df20		; $6cbe: $21 $20 $df 
	ld		de, $df24		; $6cc1: $11 $24 $df 
	call		$6c77			; $6cc4: $cd $77 $6c 
	ld		hl, $df30		; $6cc7: $21 $30 $df 
	ld		de, $df34		; $6cca: $11 $34 $df 
	call		$6c77			; $6ccd: $cd $77 $6c 
	ld		hl, $df40		; $6cd0: $21 $40 $df 
	ld		de, $df44		; $6cd3: $11 $44 $df 
	call		$6c77			; $6cd6: $cd $77 $6c 
	ld		bc, $0410		; $6cd9: $01 $10 $04 
	ld		hl, $df12		; $6cdc: $21 $12 $df 
	ld		(hl), $01		; $6cdf: $36 $01 
	ld		a, c			; $6ce1: $79 
	add		l			; $6ce2: $85 
	ld		l, a			; $6ce3: $6f 
	dec		b			; $6ce4: $05 
	jr		nz, -$08			; $6ce5: $20 $f8 
	xor		a			; $6ce7: $af 
	ld		($df1e), a		; $6ce8: $ea $1e $df 
	ld		($df2e), a		; $6ceb: $ea $2e $df 
	ld		($df3e), a		; $6cee: $ea $3e $df 
	ret					; $6cf1: $c9 
	push		hl			; $6cf2: $e5 
	xor		a			; $6cf3: $af 
	ldh		($1a), a		; $6cf4: $e0 $1a 
	ld		l, e			; $6cf6: $6b 
	ld		h, d			; $6cf7: $62 
	call		$6b19			; $6cf8: $cd $19 $6b 
	pop		hl			; $6cfb: $e1 
	jr		$2a			; $6cfc: $18 $2a 
	call		$6d2e			; $6cfe: $cd $2e $6d 
	call		$6d43			; $6d01: $cd $43 $6d 
	ld		e, a			; $6d04: $5f 
	call		$6d2e			; $6d05: $cd $2e $6d 
	call		$6d43			; $6d08: $cd $43 $6d 
	ld		d, a			; $6d0b: $57 
	call		$6d2e			; $6d0c: $cd $2e $6d 
	call		$6d43			; $6d0f: $cd $43 $6d 
	ld		c, a			; $6d12: $4f 
	inc		l			; $6d13: $2c 
	inc		l			; $6d14: $2c 
	ld		(hl), e			; $6d15: $73 
	inc		l			; $6d16: $2c 
	ld		(hl), d			; $6d17: $72 
	inc		l			; $6d18: $2c 
	ld		(hl), c			; $6d19: $71 
	dec		l			; $6d1a: $2d 
	dec		l			; $6d1b: $2d 
	dec		l			; $6d1c: $2d 
	dec		l			; $6d1d: $2d 
	push		hl			; $6d1e: $e5 
	ld		hl, $ffd0		; $6d1f: $21 $d0 $ff 
	ld		a, (hl)			; $6d22: $7e 
	pop		hl			; $6d23: $e1 
	cp		$03			; $6d24: $fe $03 
	jr		z, -$36			; $6d26: $28 $ca 
	call		$6d2e			; $6d28: $cd $2e $6d 
	jp		$6dd1			; $6d2b: $c3 $d1 $6d 
	push		de			; $6d2e: $d5 
	ldi		a, (hl)			; $6d2f: $2a 
	ld		e, a			; $6d30: $5f 
	ldd		a, (hl)			; $6d31: $3a 
	ld		d, a			; $6d32: $57 
	inc		de			; $6d33: $13 
	ld		a, e			; $6d34: $7b 
	ldi		(hl), a			; $6d35: $22 
	ld		a, d			; $6d36: $7a 
	ldd		(hl), a			; $6d37: $32 
	pop		de			; $6d38: $d1 
	ret					; $6d39: $c9 
	push		de			; $6d3a: $d5 
	ldi		a, (hl)			; $6d3b: $2a 
	ld		e, a			; $6d3c: $5f 
	ldd		a, (hl)			; $6d3d: $3a 
	ld		d, a			; $6d3e: $57 
	inc		de			; $6d3f: $13 
	inc		de			; $6d40: $13 
	jr		-$0f			; $6d41: $18 $f1 
	ldi		a, (hl)			; $6d43: $2a 
	ld		c, a			; $6d44: $4f 
	ldd		a, (hl)			; $6d45: $3a 
	ld		b, a			; $6d46: $47 
	ld		a, (bc)			; $6d47: $0a 
	ld		b, a			; $6d48: $47 
	ret					; $6d49: $c9 
	pop		hl			; $6d4a: $e1 
	jr		$2b			; $6d4b: $18 $2b 
	ldh		a, ($d0)		; $6d4d: $f0 $d0 
	cp		$03			; $6d4f: $fe $03 
	jr		nz, $10			; $6d51: $20 $10 
	ld		a, ($df38)		; $6d53: $fa $38 $df 
	bit		7, a			; $6d56: $cb $7f 
	jr		z, $09			; $6d58: $28 $09 
	ld		a, (hl)			; $6d5a: $7e 
	cp		$06			; $6d5b: $fe $06 
	jr		nz, $04			; $6d5d: $20 $04 
	ld		a, $40			; $6d5f: $3e $40 
	ldh		($1c), a		; $6d61: $e0 $1c 
	push		hl			; $6d63: $e5 
	ld		a, l			; $6d64: $7d 
	add		$09			; $6d65: $c6 $09 
	ld		l, a			; $6d67: $6f 
	ld		a, (hl)			; $6d68: $7e 
	and		a			; $6d69: $a7 
	jr		nz, -$22			; $6d6a: $20 $de 
	ld		a, l			; $6d6c: $7d 
	add		$04			; $6d6d: $c6 $04 
	ld		l, a			; $6d6f: $6f 
	bit		7, (hl)			; $6d70: $cb $7e 
	jr		nz, -$2a			; $6d72: $20 $d6 
	pop		hl			; $6d74: $e1 
	call		$6ed8			; $6d75: $cd $d8 $6e 
	dec		l			; $6d78: $2d 
	dec		l			; $6d79: $2d 
	jp		$6eaa			; $6d7a: $c3 $aa $6e 
	dec		l			; $6d7d: $2d 
	dec		l			; $6d7e: $2d 
	dec		l			; $6d7f: $2d 
	dec		l			; $6d80: $2d 
	call		$6d3a			; $6d81: $cd $3a $6d 
	ld		a, l			; $6d84: $7d 
	add		$04			; $6d85: $c6 $04 
	ld		e, a			; $6d87: $5f 
	ld		d, h			; $6d88: $54 
	call		$6c77			; $6d89: $cd $77 $6c 
	cp		$00			; $6d8c: $fe $00 
	jr		z, $1f			; $6d8e: $28 $1f 
	cp		$ff			; $6d90: $fe $ff 
	jr		z, $04			; $6d92: $28 $04 
	inc		l			; $6d94: $2c 
	jp		$6dcf			; $6d95: $c3 $cf $6d 
	dec		l			; $6d98: $2d 
	push		hl			; $6d99: $e5 
	call		$6d3a			; $6d9a: $cd $3a $6d 
	call		$6d43			; $6d9d: $cd $43 $6d 
	ld		e, a			; $6da0: $5f 
	call		$6d2e			; $6da1: $cd $2e $6d 
	call		$6d43			; $6da4: $cd $43 $6d 
	ld		d, a			; $6da7: $57 
	pop		hl			; $6da8: $e1 
	ld		a, e			; $6da9: $7b 
	ldi		(hl), a			; $6daa: $22 
	ld		a, d			; $6dab: $7a 
	ldd		(hl), a			; $6dac: $32 
	jr		-$2b			; $6dad: $18 $d5 
	ld		hl, $dfe9		; $6daf: $21 $e9 $df 
	ld		(hl), $00		; $6db2: $36 $00 
	call		$6b4b			; $6db4: $cd $4b $6b 
	ret					; $6db7: $c9 

; routine
	ld		hl, $dfe9		; $6db8: $21 $e9 $df 
	ld		a, (hl)			; $6dbb: $7e 
	and		a			; $6dbc: $a7 
	ret		z			; $6dbd: $c8 
	ld		a, $01			; $6dbe: $3e $01 
	ldh		($d0), a		; $6dc0: $e0 $d0 
	ld		hl, $df10		; $6dc2: $21 $10 $df 
	inc		l			; $6dc5: $2c 
	ldi		a, (hl)			; $6dc6: $2a 
	and		a			; $6dc7: $a7 
	jp		z, $6d78		; $6dc8: $ca $78 $6d 
	dec		(hl)			; $6dcb: $35 
	jp		nz, $6d4d		; $6dcc: $c2 $4d $6d 
	inc		l			; $6dcf: $2c 
	inc		l			; $6dd0: $2c 
	call		$6d43			; $6dd1: $cd $43 $6d 
	cp		$00			; $6dd4: $fe $00 
	jp		z, $6d7d		; $6dd6: $ca $7d $6d 
	cp		$9d			; $6dd9: $fe $9d 
	jp		z, $6cfe		; $6ddb: $ca $fe $6c 
	and		$f0			; $6dde: $e6 $f0 
	cp		$a0			; $6de0: $fe $a0 
	jr		nz, $1a			; $6de2: $20 $1a 
	ld		a, b			; $6de4: $78 
	and		$0f			; $6de5: $e6 $0f 
	ld		c, a			; $6de7: $4f 
	ld		b, $00			; $6de8: $06 $00 
	push		hl			; $6dea: $e5 
	ld		de, $df01		; $6deb: $11 $01 $df 
	ld		a, (de)			; $6dee: $1a 
	ld		l, a			; $6def: $6f 
	inc		de			; $6df0: $13 
	ld		a, (de)			; $6df1: $1a 
	ld		h, a			; $6df2: $67 
	add		hl, bc			; $6df3: $09 
	ld		a, (hl)			; $6df4: $7e 
	pop		hl			; $6df5: $e1 
	dec		l			; $6df6: $2d 
	ldi		(hl), a			; $6df7: $22 
	call		$6d2e			; $6df8: $cd $2e $6d 
	call		$6d43			; $6dfb: $cd $43 $6d 
	ld		a, b			; $6dfe: $78 
	ld		c, a			; $6dff: $4f 
	ld		b, $00			; $6e00: $06 $00 
	call		$6d2e			; $6e02: $cd $2e $6d 
	ldh		a, ($d0)		; $6e05: $f0 $d0 
	cp		$04			; $6e07: $fe $04 
	jp		z, $6e2e		; $6e09: $ca $2e $6e 
	push		hl			; $6e0c: $e5 
	ld		a, l			; $6e0d: $7d 
	add		$05			; $6e0e: $c6 $05 
	ld		l, a			; $6e10: $6f 
	ld		e, l			; $6e11: $5d 
	ld		d, h			; $6e12: $54 
	inc		l			; $6e13: $2c 
	inc		l			; $6e14: $2c 
	ld		a, c			; $6e15: $79 
	cp		$01			; $6e16: $fe $01 
	jr		z, $0f			; $6e18: $28 $0f 
	ld		(hl), $00		; $6e1a: $36 $00 
	ld		hl, $6f70		; $6e1c: $21 $70 $6f 
	add		hl, bc			; $6e1f: $09 
	ldi		a, (hl)			; $6e20: $2a 
	ld		(de), a			; $6e21: $12 
	inc		e			; $6e22: $1c 
	ld		a, (hl)			; $6e23: $7e 
	ld		(de), a			; $6e24: $12 
	pop		hl			; $6e25: $e1 
	jp		$6e45			; $6e26: $c3 $45 $6e 
	ld		(hl), $01		; $6e29: $36 $01 
	pop		hl			; $6e2b: $e1 
	jr		$17			; $6e2c: $18 $17 
	push		hl			; $6e2e: $e5 
	ld		de, $df46		; $6e2f: $11 $46 $df 
	ld		hl, $7002		; $6e32: $21 $02 $70 
	add		hl, bc			; $6e35: $09 
	ldi		a, (hl)			; $6e36: $2a 
	ld		(de), a			; $6e37: $12 
	inc		e			; $6e38: $1c 
	ld		a, e			; $6e39: $7b 
	cp		$4b			; $6e3a: $fe $4b 
	jr		nz, -$08			; $6e3c: $20 $f8 
	ld		c, $20			; $6e3e: $0e $20 
	ld		hl, $df44		; $6e40: $21 $44 $df 
	jr		$2d			; $6e43: $18 $2d 
	push		hl			; $6e45: $e5 
	ldh		a, ($d0)		; $6e46: $f0 $d0 
	cp		$01			; $6e48: $fe $01 
	jr		z, $21			; $6e4a: $28 $21 
	cp		$02			; $6e4c: $fe $02 
	jr		z, $19			; $6e4e: $28 $19 
	ld		c, $1a			; $6e50: $0e $1a 
	ld		a, ($df3f)		; $6e52: $fa $3f $df 
	bit		7, a			; $6e55: $cb $7f 
	jr		nz, $05			; $6e57: $20 $05 
	xor		a			; $6e59: $af 
	ld		($ff00+c), a		; $6e5a: $e2 
	ld		a, $80			; $6e5b: $3e $80 
	ld		($ff00+c), a		; $6e5d: $e2 
	inc		c			; $6e5e: $0c 
	inc		l			; $6e5f: $2c 
	inc		l			; $6e60: $2c 
	inc		l			; $6e61: $2c 
	inc		l			; $6e62: $2c 
	ldi		a, (hl)			; $6e63: $2a 
	ld		e, a			; $6e64: $5f 
	ld		d, $00			; $6e65: $16 $00 
	jr		$15			; $6e67: $18 $15 
	ld		c, $16			; $6e69: $0e $16 
	jr		$05			; $6e6b: $18 $05 
	ld		c, $10			; $6e6d: $0e $10 
	ld		a, $00			; $6e6f: $3e $00 
	inc		c			; $6e71: $0c 
	inc		l			; $6e72: $2c 
	inc		l			; $6e73: $2c 
	inc		l			; $6e74: $2c 
	ldd		a, (hl)			; $6e75: $3a 
	and		a			; $6e76: $a7 
	jr		nz, +			; $6e77: $20 $4f 
	ldi		a, (hl)			; $6e79: $2a 
	ld		e, a			; $6e7a: $5f 
	inc		l			; $6e7b: $2c 
	ldi		a, (hl)			; $6e7c: $2a 
	ld		d, a			; $6e7d: $57 
	push		hl			; $6e7e: $e5 
	inc		l			; $6e7f: $2c 
	inc		l			; $6e80: $2c 
	ldi		a, (hl)			; $6e81: $2a 
	and		a			; $6e82: $a7 
	jr		z, $02			; $6e83: $28 $02 
	ld		e, $01			; $6e85: $1e $01 
	inc		l			; $6e87: $2c 
	inc		l			; $6e88: $2c 
	ld		(hl), $00		; $6e89: $36 $00 
	inc		l			; $6e8b: $2c 
	ld		a, (hl)			; $6e8c: $7e 
	pop		hl			; $6e8d: $e1 
	bit		7, a			; $6e8e: $cb $7f 
	jr		nz, $13			; $6e90: $20 $13 
	ld		a, d			; $6e92: $7a 
	ld		($ff00+c), a		; $6e93: $e2 
	inc		c			; $6e94: $0c 
	ld		a, e			; $6e95: $7b 
	ld		($ff00+c), a		; $6e96: $e2 
	inc		c			; $6e97: $0c 
	ldi		a, (hl)			; $6e98: $2a 
	ld		($ff00+c), a		; $6e99: $e2 
	inc		c			; $6e9a: $0c 
	ld		a, (hl)			; $6e9b: $7e 
	or		$80			; $6e9c: $f6 $80 
	ld		($ff00+c), a		; $6e9e: $e2 
	ld		a, l			; $6e9f: $7d 
	or		$05			; $6ea0: $f6 $05 
	ld		l, a			; $6ea2: $6f 
	res		0, (hl)			; $6ea3: $cb $86 
	pop		hl			; $6ea5: $e1 
	dec		l			; $6ea6: $2d 
	ldd		a, (hl)			; $6ea7: $3a 
	ldd		(hl), a			; $6ea8: $32 
	dec		l			; $6ea9: $2d 
	ld		de, $ffd0		; $6eaa: $11 $d0 $ff 
	ld		a, (de)			; $6ead: $1a 
	cp		$04			; $6eae: $fe $04 
	jr		z, $09			; $6eb0: $28 $09 
	inc		a			; $6eb2: $3c 
	ld		(de), a			; $6eb3: $12 
	ld		de, $0010		; $6eb4: $11 $10 $00 
	add		hl, de			; $6eb7: $19 
	jp		$6dc5			; $6eb8: $c3 $c5 $6d 
	ld		hl, $df1e		; $6ebb: $21 $1e $df 
	inc		(hl)			; $6ebe: $34 
	ld		hl, $df2e		; $6ebf: $21 $2e $df 
	inc		(hl)			; $6ec2: $34 
	ld		hl, $df3e		; $6ec3: $21 $3e $df 
	inc		(hl)			; $6ec6: $34 
	ret					; $6ec7: $c9 

+	ld		b, $00			; $6ec8: $06 $00 
	push		hl			; $6eca: $e5 
	pop		hl			; $6ecb: $e1 
	inc		l			; $6ecc: $2c 
	jr		-$54			; $6ecd: $18 $ac 
; end routine

; routine
	ld		a, b			; $6ecf: $78 
	srl		a			; $6ed0: $cb $3f 
	ld		l, a			; $6ed2: $6f 
	ld		h, $00			; $6ed3: $26 $00 
	add		hl, de			; $6ed5: $19 
	ld		e, (hl)			; $6ed6: $5e 
	ret					; $6ed7: $c9 
; end routine

; routine
	push		hl			; $6ed8: $e5 
	ld		a, l			; $6ed9: $7d 
	add		$06			; $6eda: $c6 $06 
	ld		l, a			; $6edc: $6f 
	ld		a, (hl)			; $6edd: $7e 
	and		$0f			; $6ede: $e6 $0f 
	jr		z, $16			; $6ee0: $28 $16 
	ldh		($d1), a		; $6ee2: $e0 $d1 
	ldh		a, ($d0)		; $6ee4: $f0 $d0 
	ld		c, $13			; $6ee6: $0e $13 
	cp		$01			; $6ee8: $fe $01 
	jr		z, $0e			; $6eea: $28 $0e 
	ld		c, $18			; $6eec: $0e $18 
	cp		$02			; $6eee: $fe $02 
	jr		z, $08			; $6ef0: $28 $08 
	ld		c, $1d			; $6ef2: $0e $1d 
	cp		$03			; $6ef4: $fe $03 
	jr		z, $02			; $6ef6: $28 $02 
	pop		hl			; $6ef8: $e1 
	ret					; $6ef9: $c9 

	inc		l			; $6efa: $2c 
	ldi		a, (hl)			; $6efb: $2a 
	ld		e, a			; $6efc: $5f 
	ld		a, (hl)			; $6efd: $7e 
	ld		d, a			; $6efe: $57 
	push		de			; $6eff: $d5 
	ld		a, l			; $6f00: $7d 
	add		$04			; $6f01: $c6 $04 
	ld		l, a			; $6f03: $6f 
	ld		b, (hl)			; $6f04: $46 
	ldh		a, ($d1)		; $6f05: $f0 $d1 
	cp		$01			; $6f07: $fe $01 
	jr		$09			; $6f09: $18 $09 
	cp		$03			; $6f0b: $fe $03 
	jr		$00			; $6f0d: $18 $00 
	ld		hl, $ffff		; $6f0f: $21 $ff $ff 
	jr		$1c			; $6f12: $18 $1c 
	ld		de, $6f39		; $6f14: $11 $39 $6f 
	call		$6ecf			; $6f17: $cd $cf $6e 
	bit		0, b			; $6f1a: $cb $40 
	jr		nz, $02			; $6f1c: $20 $02 
	swap		e			; $6f1e: $cb $33 
	ld		a, e			; $6f20: $7b 
	and		$0f			; $6f21: $e6 $0f 
	bit		3, a			; $6f23: $cb $5f 
	jr		z, $06			; $6f25: $28 $06 
	ld		h, $ff			; $6f27: $26 $ff 
	or		$f0			; $6f29: $f6 $f0 
	jr		$02			; $6f2b: $18 $02 
	ld		h, $00			; $6f2d: $26 $00 
	ld		l, a			; $6f2f: $6f 
	pop		de			; $6f30: $d1 
	add		hl, de			; $6f31: $19 
	ld		a, l			; $6f32: $7d 
	ld		($ff00+c), a		; $6f33: $e2 
	inc		c			; $6f34: $0c 
	ld		a, h			; $6f35: $7c 
	ld		($ff00+c), a		; $6f36: $e2 
	jr		-$41			; $6f37: $18 $bf 
; end routine

; data?
; yee, music data
;.incbin "data9.bin"
.include "music.asm"
; end data

.org $3ff0

TIMER_IRQ_ALIAS:
	jp		TIMER_IRQ		; $7ff0: $c3 $62 $67 

SOUND_INIT_ALIAS:
	jp		SOUND_INIT		; $7ff3: $c3 $26 $6b 
