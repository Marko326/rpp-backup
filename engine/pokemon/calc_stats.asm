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
