; Apple ][ Dead Test RAM Diagnostic ROM
; Copyright (C) 2023  David Giller

; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License along
; with this program; if not, write to the Free Software Foundation, Inc.,
; 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

.scope	ZPSP
; print "TEST ZERO PAGE"
		inline_print zp_msg, TXTLINE21+((40-(zp_end-zp_msg-1))/2)
start:	
		LDX #(tst_tbl_end-tst_tbl-1)	; initialize the pointer to the table of values - start from end of the table

; step 0; up - w0
; write the test value to zero page and stack
marchU:	
		inline_print zp_step0, TXTLINE22+16 ; print "STEP 0: ", A and Y will be used 
		LDA tst_tbl,X	; get the test value from tst_tbl into A
		TXS				; save the pointer index of the test value into SP
		TAX				; move the test value into X
		inline_hex_x TXTLINE22+24 ; print test value in X to screen, A and Y will be used by inline routine
		TXA				; restore test value back to A
		LDY #$27		; write value at bottom of screen
loopy:	STA TXTLINE24,Y
		DEY
		BPL loopy

		LDY #$00
marchU0:
		STA $00,Y		; w0 - write the test value
		STA $0100,Y		;    - also to stack page
		INY				; count up
		BNE marchU0		; repeat until Y overflows back to zero

; step 1; up - r0,w1,r1,w0
; A and X contains test value
		inline_print zp_step1, TXTLINE22+16 ; print "STEP 1: ", A and Y will be used 
		TXA  			; restore test value to A
		LDY #$00
marchU1:EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		EOR $00,Y		; r1 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $0100,Y		; w1s - also stack page
		EOR $0100,Y		; r1s
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $00,Y		; w0 - write the test value to the memory location
		STA $0100,Y		; w0s - also stack page
		INY				; count up
		BNE marchU1		; repeat until Y overflows back to zero

; 100ms delay for finding bit rot
marchU1delay:
		inline_delay_cycles_ay 10000; A and Y will be used
		inline_print zp_step2, TXTLINE22+16; print "STEP 2: ", A and Y will be used 
		LDY #$00		; reset Y to 0
; step 2; up - r0,w1
; X contains test value from prev step
marchU2:TXA				; recover test value
		EOR $00,Y		; r0 - read and compare with test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR $0100,Y		; r0s  - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		INY				; count up
		BNE marchU2		; repeat until Y overflows back to zero

; 100ms delay for finding bit rot
marchU2delay:
		inline_delay_cycles_ay 10000; A and Y will be used
		inline_print zp_step3, TXTLINE22+16; print "STEP 3: ", A and Y will be used 
		JMP continue

zp_bad: 	JMP zp_error; 

continue:
; step 3; down - r1,w0,r0,w1
; X contains test value from prev step		
		LDY #$FF		; reset Y to $FF and count down
		TXA				; recover test value
		EOR #$FF		; invert
marchU3:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		EOR $0100,Y		; r1s - also stack page
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		EOR $00,Y		; r0 - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		STA $0100,Y		; w0s - write the test value
		EOR $0100,Y		; r0s - read the same value back and compare using XOR
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get a fresh copy of the test value
		EOR #$FF		; invert
		STA $00,Y		; w1 - write the inverted test value
		STA $0100,Y		; w1s - also stack page
		DEY				; count down
		CPY #$FF		; did we wrap?
		BNE marchU3		; repeat until Y overflows back to FF

; step 4; down - r1,w0
; X contains test value from prev step		
		inline_print zp_step4, TXTLINE22+16; print "STEP 4: ", Akku and Y will be used 
		TXA				; get the test value
		EOR #$FF		; invert
		LDY #$00
marchU4:EOR $00,Y		; r1 - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		EOR #$FF		; invert
		EOR $0100,Y		; r1s - read and compare with inverted test value (by XOR'ing with accumulator)
		BNE zp_bad		; if bits differ, location is bad
		TXA				; get the test value
		STA $00,Y		; w0 - write the test value
		STA $0100,Y		; w0s - also stack page
		EOR #$FF
		DEY				; count down
		CPY #$FF		; did we wrap?
		BNE marchU4		; repeat until Y overflows back to FF

		TSX				; recover the test value index from SP
		DEX				; choose the next one
		CPX #$FF		; see if we've wrapped
		BNE marchup		; start again with next value

		JMP zp_good

marchup:
		JMP marchU





; A contains the bits (as 1) that were found to be bad
; Y contains the address (offset) of the address where bad bit(s) were found


.proc zp_error
		TAX						; move EOR-result to X
		TXS  					; then save it in the SP
		TYA						; move adresse from Y to A
		TAX						; and from A to X
		inline_hex_x 	TXTLINE23+14  ; print adress in X to screen;
		STA TXTSET				; text mode
		STA MIXSET				; mixed mode on
		STA LOWSCR				; page 2 off

		inline_print bad_msg, TXTLINE23; print bad_msg to screen, A and Y will be used
		inline_print zp_pattern_msg, TXTLINE23+18; print zp_pattern_msg to screen, A and Y will be used

		TSX						; get EOR-result from SP
		TXA						; and move it to A
		LDY #0
	print_bit:
		asl						; get top bit into carry flag
		tax						; save the current value
		lda #'0'|$80
		adc #0					; increment by one if we had a carry
		sta TXTLINE23+30,Y		; print bit to screen
		txa
		iny
		cpy #8
		bne print_bit			; repeat 8 times

	; find the bit to beep out
		tsx						; get the bad bit mask back into A
		txa
		LDX #1			
	chkbit:	
		LSR						; move lowest bit into carry
		BCS start_beeping		; bit set, display it
		inx						; count up
		cpx #$09
		bne chkbit				; test next bit
	wha:JMP wha					; only get here if there was no bad bit

	; now X contains the index of the bit, starting at 1
	start_beeping:
		txs						; save the bit index of the top set bit into SP
	beeploop:
		lda #1
	type_beep:					; beep an annoying chirp to indicate page err
		inline_beep_xy $FF, $FF
		sec
		sbc #1
		bpl type_beep

		tsx						; fetch the bit number
		txa
	bit_beep:
		tax
		inline_delay_cycles_ay 400000
		txa
		sta TXTCLR 				; turn on graphics
		inline_beep_xy $FF, $80
		sta TXTSET				; text mode
		sec
		sbc #1
		bne bit_beep

		; pause betwen beeping ~1.5 sec
		ldx #3
	dl:	inline_delay_cycles_ay 500000
		dex
		bne dl


		JMP beeploop
.endproc

bad_msg:.apple2sz "ZP/SP ERR AT $"
	bad_msg_len = * - bad_msg

zp_good:
		; lda #$18
		; jmp zp_error		; simulate error

		; inline_print pt_msg, TXTLINE21+((40-(pt_end-pt_msg-1))/2)

.proc page_test
		; ldx #$F0				; simulate error
		; jmp page_error

		LDA #0		; write zero to zp location 0
		TAY
	wz:	STA $00,Y
		DEY
		BNE wz

	wr:	STA $0100,Y			; write to the pages
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $0200,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $0400,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $0800,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $1000,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $2000,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $4000,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		STA $8000,Y
		LDX $00,Y			; check the zp address
		BNE page_error
		INY
		BNE wr

		JMP page_ok
.endproc

.proc page_error
		TXS  			; bad bit mask is in X, save it in the SP

		STA TXTSET		; text mode
		sta MIXSET		; mixed mode on
		STA LOWSCR		; page 2 off
		inline_cls
		inline_print bad_page_msg, TXTLINE23

		TSX				; retrieve the test value
		TXA
		LDY #0
	print_bit:
		asl				; get top bit into carry flag
		tax				; save the current value
		lda #'0'|$80
		adc #0			; increment by one if we had a carry
		sta $0764,Y		; print bit to screen
		txa
		iny
		cpy #8
		bne print_bit	; repeat 8 times

	; find the bit to beep out
		tsx				; get the bad bit mask back into A
		txa
		cmp #$FF		; if it's FF, it's a motherboard error
		beq start_beeping
		LDX #1			; count up
	page_chkbit:	
		LSR				; move lowest bit into carry
		BCS start_beeping	; bit set, display it
		inx				; count down
		cpx #$09
		bne page_chkbit	; test next bit
	wha:JMP wha			; only get here if there was no bad bit

	; now X contains the index of the bit, starting at 1
	start_beeping:
		txs					; save the bit index of the top set bit into SP
	beeploop:
		ldx #5
	type_beep:				; beep an annoying chirp to indicate page err
		inline_delay_cycles_ay 30000
		txa
		inline_beep_xy $40, $40
		tax
		dex
		bne type_beep

		tsx					; fetch the bit number
		txa
		cmp #$FF
		beq beeploop		; continuous beeping for MB error
	bit_beep:
		tax
		inline_delay_cycles_ay 400000
		txa
		sta TXTCLR 			; turn on graphics
		inline_beep_xy $FF, $80
		sta TXTSET			; text mode
		sec
		sbc #1
		bne bit_beep

		; pause betwen beeping ~1.5 sec
		ldx #3
	dl:	inline_delay_cycles_ay 500000
		dex
		bne dl

		JMP beeploop

bad_page_msg:.apple2sz "PAGE ERR"
.endproc

page_ok:
.endscope
