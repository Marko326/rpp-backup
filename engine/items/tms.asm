; tests if mon [wcf91] can learn the selected TM/HM
; INPUT: wSelectedMachineIndex = 1..55 (TM01..TM50/HM01..HM05)
;        wMoveNum = move taught by that machine (kept for the teaching flow)
CanLearnTM:
	ld a, [wcf91]
	ld [wd0b5], a
	; FORM-5.21.00: TM compatibility comes from the selected individual's
	; descriptor header when it is a registered regional form.
	callba RegionalFormLoadPartyMonHeader
	ld hl, wMonHLearnset
	; OPT-5.28.00: test the real machine slot directly. The old move->first
	; matching machine lookup was ambiguous when two TMs/HMs taught one move.
	ld a, [wSelectedMachineIndex]
	dec a
	ld c, a
	ld b, FLAG_TEST
	predef_jump FlagActionPredef

; converts TM/HM number in wd11e into move number
; HMs start at 51
TMToMove:
	ld a, [wd11e]
	dec a
	ld hl, TechnicalMachines
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wd11e], a
	ret

; Moved the label here, so that line number == TM number for quick reference
TechnicalMachines:
INCLUDE "data/tms.asm"


; tests if mon [wcf91] can learn move [wMoveNum]
CanLearnTutor:
	ld a, [wcf91]
	ld [wd0b5], a
	; FORM-5.21.00: tutor compatibility uses the same full descriptor header.
	callba RegionalFormLoadPartyMonHeader
	ld hl, wMonHMoves
	push hl
	ld a, [wMoveNum]
	ld b, a
	ld c, $0
	ld hl, MoveTutorMoves
.findTutorLoop
	ld a, [hli]
	cp b
	jr z, .TutorFoundLoop
	inc c
	jr .findTutorLoop
.TutorFoundLoop
	pop hl
	ld b, FLAG_TEST
	predef FlagActionPredef
	ld a, c
	ld [wTempMoveID], a ; bc is not preserved when called from another bank
	ret

; converts Move Tutor number in wd11e into move number
TutorToMove:
	ld a, [wd11e]
	dec a
	ld hl, MoveTutorMoves
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld [wd11e], a
	ret

INCLUDE "data/move_tutors.asm"

; MoveDex 查询技能的固定教学来源。
; INPUT:  wd11e = move ID
; OUTPUT: H = 0（非 TM/HM）或 1..55（TM01..TM50 / HM01..HM05）
;         L = 0（非 Tutor）或 1（Tutor）
;
; 这里直接查询游戏实际使用的 TechnicalMachines / MoveTutorMoves，
; 避免 MoveDex 维护第二份容易失同步的来源表。
GetMoveDexLearnSource:
	ld a,[wd11e]
	ld c,a

	; TechnicalMachines 固定为 55 项：前 50 项是 TM，后 5 项是 HM。
	ld hl,TechnicalMachines
	ld b,1
	ld d,0
.tmLoop
	ld a,[hli]
	cp c
	jr z,.tmFound
	inc b
	ld a,b
	cp 56
	jr c,.tmLoop
	jr .checkTutor
.tmFound
	ld d,b

.checkTutor
	ld hl,MoveTutorMoves
	ld e,0
.tutorLoop
	ld a,[hli]
	and a
	jr z,.done
	cp c
	jr z,.tutorFound
	jr .tutorLoop
.tutorFound
	inc e
.done
	ld h,d
	ld l,e
	ret
