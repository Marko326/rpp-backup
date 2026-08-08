SoftReset_orig:: ; HAX: "SoftReset" label moved elsewhere (calls this after)
	call StopAllSounds
	call GBPalWhiteOut
	ld c, 32
	call DelayFrames
	; fallthrough

Init::
;  Program init.

rLCDC_DEFAULT EQU %11100011
; * LCD enabled
; * Window tile map at $9C00
; * Window display enabled
; * BG and window tile data at $8800
; * BG tile map at $9800
; * 8x8 OBJ size
; * OBJ display enabled
; * BG display enabled

	di

	xor a
	ld [rIF], a
	ld [rIE], a
	ld [rSCX], a
	ld [rSCY], a
	ld [rSB], a
	ld [rSC], a
	ld [rWX], a
	ld [rWY], a
	ld [rTMA], a
	ld [rTAC], a
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	ld a, rLCDC_ENABLE_MASK
	ld [rLCDC], a
	call DisableLCD

	ld sp, wStack

	ld hl, $c000 ; start of WRAM
	ld bc, $2000 ; size of WRAM
.loop
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop

	call ClearVram

	ld hl, $ff80
	ld bc, $ffff - $ff80
	call FillMemory

	call ClearSprites

	ld a, Bank(WriteDMACodeToHRAM)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call WriteDMACodeToHRAM

	xor a
	ld [hTilesetType], a
	ld [rSTAT], a
	ld [hSCX], a
	ld [hSCY], a
	ld [rIF], a
	ld a, 1 << VBLANK + 1 << TIMER + 1 << SERIAL
	ld [rIE], a

	ld a, 144 ; move the window off-screen
	ld [hWY], a
	ld [rWY], a
	ld a, 7
	ld [rWX], a

	ld a, CONNECTION_NOT_ESTABLISHED
	ld [hSerialConnectionStatus], a

	ld h, vBGMap0 / $100
	call ClearBgMap
	ld h, vBGMap1 / $100
	call ClearBgMap

	ld a, rLCDC_DEFAULT
	ld [rLCDC], a
	ld a, 16
	ld [hSoftReset], a
	call StopAllSounds

	ei

	predef LoadSGB

	ld a, 0 ; BANK(SFX_Shooting_Star)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, $9c
	ld [H_AUTOBGTRANSFERDEST + 1], a
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	dec a
	ld [wUpdateSpritesEnabled], a

	; The intro and title screen run before MainMenu loads the save file.
	; Read the saved Music switch and BGM volume early so those sequences obey
	; the user's audio settings without loading the rest of the save data.
	ld a, 1 ; default options: fast text and background music on
	ld [wOptions], a
	ld a, $aa ; encoded BGM volume 10
	ld [wBGMVolume], a
	call LoadStartupMusicOption

	predef PlayIntro

	call DisableLCD
	call ClearVram
	call GBPalNormal
	call ClearSprites
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a

	jp SetDefaultNamesBeforeTitlescreen

ClearVram:
	ld hl, $8000
	ld bc, $2000
	xor a
	jp FillMemory


LoadStartupMusicOption:
; Load bit 5 of the saved options plus the encoded BGM volume before the boot
; intro. SRAM without a player-name terminator is treated as having no save.
	push bc
	push hl
	di
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a

	ld hl, sPlayerName
	ld b, NAME_LENGTH
.checkPlayerName
	ld a, [hli]
	cp "@"
	jr z, .loadMusicOption
	dec b
	jr nz, .checkPlayerName
	jr .closeSRAM

.loadMusicOption
	ld a, [sMainData + (wOptions - wMainDataStart)]
	and 1 << 5
	ld b, a
	ld a, [wOptions]
	and $df
	or b
	ld [wOptions], a

	; Load saved BGM volume only if it uses the new $a0-$aa encoding.
	; Old saves used d366 as an ignored map-width scratch byte, so any
	; value outside this range keeps the default level 10.
	ld a, [sMainData + (wBGMVolume - wMainDataStart)]
	cp $a0
	jr c, .closeSRAM
	cp $ab
	jr nc, .closeSRAM
	ld [wBGMVolume], a

.closeSRAM
	xor a
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamEnable], a
	ei
	pop hl
	pop bc
	ret


StopAllSounds::
    call OpenSRAMForSound
    ld hl, MusicPlaying
	ld bc, (wChannelSelectorSwitches+8) - Crysaudio
	call FillMemory

	ld a, 0 ; BANK(Audio1_UpdateMusic)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wAudioFadeOutControl], a
	ld [wNewSoundID], a
	ld [wLastMusicSoundID], a
	dec a
	jp PlaySound
