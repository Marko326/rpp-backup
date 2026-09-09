; calculates all 5 stats of current mon and writes them to [de]
_CalcStats::
	ld c, $0
.statsLoop
	inc c
	call _CalcStat
	ld a, [H_MULTIPLICAND+1]
	ld [de], a
	inc de
	ld a, [H_MULTIPLICAND+2]
	ld [de], a
	inc de
	ld a, c
	cp NUM_STATS
	jr nz, .statsLoop
	ret

; calculates stat c of current mon
; c: stat to calc (HP=1,Atk=2,Def=3,Spd=4,Spc=5)
; b: consider stat exp?
; hl: base ptr to stat exp values ([hl + 2*c - 1] and [hl + 2*c])
_CalcStat::
	push hl
	push de
	push bc
	ld a, b
	ld d, a
	push hl
	ld hl, wMonHeader
	ld b, $0
	add hl, bc
	ld a, [hl]          ; read base value of stat
	ld e, a
	pop hl
	push hl
	sla c
	ld a, d
	and a
	jr z, .statExpDone  ; consider stat exp?
	add hl, bc          ; skip to corresponding stat exp value
	; Box Summary recalculates all five stats on every live switch. Keep the exact
	; results, but avoid the original repeated Multiply-based square-root loop.
	ld a, [wMonDataLocation]
	cp BOX_DATA
	jr z, .boxStatExpFast
.statExpLoop            ; calculates ceil(Sqrt(stat exp)) in b
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND+1], a
	inc b               ; increment current stat exp bonus
	ld a, b
	cp $ff
	jr z, .statExpDone
	ld [H_MULTIPLICAND+2], a
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [hld]
	ld d, a
	ld a, [$ff98]
	sub d
	ld a, [hli]
	ld d, a
	ld a, [$ff97]
	sbc d               ; test if (current stat exp bonus)^2 < stat exp
	jr c, .statExpLoop
	jr .statExpDone
.boxStatExpFast
	call .CalcBoxStatExpQuarterRootFast
.statExpDone
	srl c
	pop hl
	push bc
	ld bc, wPartyMon1DVs - (wPartyMon1HPExp - 1) ; also wEnemyMonDVs - wEnemyMonHP
	add hl, bc
	pop bc
	ld a, c
	cp $2
	jr z, .getAttackIV
	cp $3
	jr z, .getDefenseIV
	cp $4
	jr z, .getSpeedIV
	cp $5
	jr z, .getSpecialIV
.getHpIV
	push bc
	ld a, [hl]  ; Atk IV
	swap a
	and $1
	sla a
	sla a
	sla a
	ld b, a
	ld a, [hli] ; Def IV
	and $1
	sla a
	sla a
	add b
	ld b, a
	ld a, [hl] ; Spd IV
	swap a
	and $1
	sla a
	add b
	ld b, a
	ld a, [hl] ; Spc IV
	and $1
	add b      ; HP IV: LSB of the other 4 IVs
	pop bc
	jr .calcStatFromIV
.getAttackIV
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getDefenseIV
	ld a, [hl]
	and $f
	jr .calcStatFromIV
.getSpeedIV
	inc hl
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getSpecialIV
	inc hl
	ld a, [hl]
	and $f
.calcStatFromIV
	ld d, $0
	add e
	ld e, a
	jr nc, .noCarry
	inc d                     ; de = Base + IV
.noCarry
	sla e
	rl d                      ; de = (Base + IV) * 2
	srl b
	srl b                     ; b = ceil(Sqrt(stat exp)) / 4
	ld a, b
	add e
	jr nc, .noCarry2
	inc d                     ; de = (Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4
.noCarry2
	ld [H_MULTIPLICAND+2], a
	ld a, d
	ld [H_MULTIPLICAND+1], a
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [wCurEnemyLVL]
	ld [H_MULTIPLIER], a
	call Multiply            ; ((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level
	ld a, [H_MULTIPLICAND]
	ld [H_DIVIDEND], a
	ld a, [H_MULTIPLICAND+1]
	ld [H_DIVIDEND+1], a
	ld a, [H_MULTIPLICAND+2]
	ld [H_DIVIDEND+2], a
	ld a, $64
	ld [H_DIVISOR], a
	ld a, $3
	ld b, a
	call Divide             ; (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100
	ld a, c
	cp $1
	ld a, 5 ; + 5 for non-HP stat
	jr nz, .notHPStat
	ld a, [wCurEnemyLVL]
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	add b
	ld [H_MULTIPLICAND+2], a
	jr nc, .noCarry3
	ld a, [H_MULTIPLICAND+1]
	inc a
	ld [H_MULTIPLICAND+1], a ; HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + Level
.noCarry3
	ld a, 10 ; +10 for HP stat
.notHPStat
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	add b
	ld [H_MULTIPLICAND+2], a
	jr nc, .noCarry4
	ld a, [H_MULTIPLICAND+1]
	inc a                    ; non-HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + 5
	ld [H_MULTIPLICAND+1], a ; HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + Level + 10
.noCarry4
	ld a, [H_MULTIPLICAND+1] ; check for overflow (>999)
	cp 999 / $100 + 1
	jr nc, .overflow
	cp 999 / $100
	jr c, .noOverflow
	ld a, [H_MULTIPLICAND+2]
	cp 999 % $100 + 1
	jr c, .noOverflow
.overflow
	ld a, 999 / $100               ; overflow: cap at 999
	ld [H_MULTIPLICAND+1], a
	ld a, 999 % $100
	ld [H_MULTIPLICAND+2], a
.noOverflow
	pop bc
	pop de
	pop hl
	ret

; Input:  hl = low byte of the selected Stat Exp value.
; Output: b  = 4 * floor(ceil(sqrt(Stat Exp)) / 4).
; The existing two SRL B instructions below convert it to the normal stat bonus.
;
; This binary-searches the 63 exact transition thresholds. It preserves the
; complete five-stat CalcStats path while replacing up to 255 Multiply loops
; per stat with at most six small comparisons.
.CalcBoxStatExpQuarterRootFast
	push hl
	push de
	push bc
	dec hl
	ld a, [hli]
	ld d, a             ; Stat Exp high byte
	ld a, [hl]
	ld e, a             ; Stat Exp low byte
	ld b, 0             ; lower bound: number of passed thresholds
	ld c, 63            ; upper bound (exclusive)
.search
	ld a, b
	cp c
	jr z, .done
	ld a, b
	add c
	srl a               ; midpoint
	push af              ; keep midpoint while reading the table
	push bc              ; keep search bounds
	add a                ; two bytes per threshold
	ld c, a
	ld b, 0
	ld hl, .BoxStatExpQuarterRootThresholds
	add hl, bc
	ld a, [hli]         ; threshold high byte
	cp d
	jr c, .passed
	jr nz, .notPassed
	ld a, [hl]          ; threshold low byte
	cp e
	jr c, .passed
.notPassed
	pop bc
	pop af
	ld c, a             ; upper = midpoint
	jr .search
.passed
	pop bc
	pop af
	inc a
	ld b, a             ; lower = midpoint + 1
	jr .search
.done
	ld a, b
	pop bc
	ld b, a
	sla b
	sla b               ; existing SRL B / SRL B restores the exact bonus
	pop de
	pop hl
	ret

; Threshold q is (4q - 1)^2 for q = 1..63.
.BoxStatExpQuarterRootThresholds
	db $00, $09, $00, $31, $00, $79, $00, $e1, $01, $69, $02, $11
	db $02, $d9, $03, $c1, $04, $c9, $05, $f1, $07, $39, $08, $a1
	db $0a, $29, $0b, $d1, $0d, $99, $0f, $81, $11, $89, $13, $b1
	db $15, $f9, $18, $61, $1a, $e9, $1d, $91, $20, $59, $23, $41
	db $26, $49, $29, $71, $2c, $b9, $30, $21, $33, $a9, $37, $51
	db $3b, $19, $3f, $01, $43, $09, $47, $31, $4b, $79, $4f, $e1
	db $54, $69, $59, $11, $5d, $d9, $62, $c1, $67, $c9, $6c, $f1
	db $72, $39, $77, $a1, $7d, $29, $82, $d1, $88, $99, $8e, $81
	db $94, $89, $9a, $b1, $a0, $f9, $a7, $61, $ad, $e9, $b4, $91
	db $bb, $59, $c2, $41, $c9, $49, $d0, $71, $d7, $b9, $df, $21
	db $e6, $a9, $ee, $51, $f6, $19
