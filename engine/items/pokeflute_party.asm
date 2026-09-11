; Shared Poké Flute party wake-up helpers.
;
; This lives in a roomy floating ROMX section because engine/items/items.asm is
; capacity-constrained. Both battle and field use the same WakeUpEntireParty
; implementation; there is deliberately no second sleep-clearing routine.

WakeSleepingPlayerPartyWithPokeflute::
	xor a
	ld [wWereAnyMonsAsleep], a
	ld b, ~SLP & $ff
	ld hl, wPartyMon1Status
	call WakeUpEntireParty
	; Bankswitch preserves flags on return, so leave Z set iff no party Pokémon
	; had Sleep. ItemUsePokeflute uses this directly after callba.
	ld a, [wWereAnyMonsAsleep]
	and a
	ret

WakeSleepingBattlePartiesWithPokeflute::
	; Keep all parameterized WakeUpEntireParty calls in this bank. callba itself
	; consumes B and HL for bank/address dispatch, so those registers cannot be used
	; as arguments across a callba boundary.
	xor a
	ld [wWereAnyMonsAsleep], a
	ld b, ~SLP & $ff
	ld hl, wPartyMon1Status
	call WakeUpEntireParty

	; Preserve the original Poké Flute battle behavior exactly: wild battles skip
	; the enemy party array; trainer battles would wake it too. Trainer-battle item
	; use is blocked by the battle menu elsewhere, so this does not change that rule.
	ld a, [wIsInBattle]
	dec a
	jr z, .skipWakingUpEnemyParty
	ld hl, wEnemyMon1Status
	call WakeUpEntireParty
.skipWakingUpEnemyParty

	; The active battle structs are separate copies. Record Sleep here too before
	; clearing it, so a sleeping wild opponent by itself still counts as an effect.
	ld hl, wBattleMonStatus
	call WakeBattleMonStatusWithPokeflute
	ld hl, wEnemyMonStatus
	call WakeBattleMonStatusWithPokeflute
	ret

WakeBattleMonStatusWithPokeflute:
	ld a, [hl]
	push af
	and SLP
	jr z, .clearSleep
	ld a, 1
	ld [wWereAnyMonsAsleep], a
.clearSleep
	pop af
	and b
	ld [hl], a
	ret

PlayBattlePokefluteSfx::
	; The current audio engine already exposes the Poké Flute melody as a normal
	; Ch6 SFX. Playing it through PlaySound temporarily owns only that SFX channel;
	; the battle BGM remains resident and resumes naturally when the SFX ends.
	call WaitForSoundToFinish
	ld a, SFX_POKEFLUTE
	call PlaySound
	jp WaitForSoundToFinish

; Wakes all six party slots. This is the original ItemUsePokeflute helper, moved
; here unchanged so the battle path and the new field path can share it.
; INPUT:
; hl must point to status of first pokemon in party (player's or enemy's)
; b must equal ~SLP
; [wWereAnyMonsAsleep] should be initialized to 0
; OUTPUT:
; [wWereAnyMonsAsleep]: set to 1 if any pokemon were asleep
WakeUpEntireParty::
	ld de, 44
	ld c, 6
.loop
	ld a, [hl]
	push af
	and a, SLP ; is pokemon asleep?
	jr z, .notAsleep
	ld a, 1
	ld [wWereAnyMonsAsleep], a ; indicate that a pokemon had to be woken up
.notAsleep
	pop af
	and b ; remove Sleep status
	ld [hl], a
	add hl, de
	dec c
	jr nz, .loop
	ret
