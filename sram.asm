SECTION "Sprite Buffers", SRAM, BANK[0]

sSpriteBuffer0:: ds SPRITEBUFFERSIZE ; a000
sSpriteBuffer1:: ds SPRITEBUFFERSIZE ; a188
sSpriteBuffer2:: ds SPRITEBUFFERSIZE ; a310

	ds $100

sHallOfFame:: ds HOF_TEAM * HOF_TEAM_CAPACITY ; a598


SECTION "Save Data", SRAM, BANK[1]
	ds $598 ; Possibly just filler data?

sPlayerName::  ds NAME_LENGTH ; a598
sMainData::    ds wMainDataEnd   - wMainDataStart ; a5a3
sSpriteData::  ds wSpriteDataEnd - wSpriteDataStart ; ad2c
sPartyData::   ds wPartyDataEnd  - wPartyDataStart ; af2c
sCurBoxData::  ds wBoxDataEnd    - wBoxDataStart ; b0c0
sTilesetType:: ds 1 ; b522
sMainDataCheckSum:: ds 1 ; b523
; MOVE-5.62.169: separate optional identity extension outside the old
; main checksum range. Compatible old SAVs do not have this signature.
sExtendedPartyFlagsMagic0:: ds 1
sExtendedPartyFlagsMagic1:: ds 1
sExtendedPartyMoveFlags:: ds PARTY_LENGTH
sExtendedPartyFlagsChecksum:: ds 1

; MOVE-5.62.169: current-box sidecar, separated from the 165 save
; checksum and the original Box structures. Twenty slot masks + XOR/check.
sExtendedCurrentBoxMoveFlags:: ds MONS_PER_BOX
sExtendedCurrentBoxChecksum:: ds 1
sExtendedCurrentBoxMagic0:: ds 1
sExtendedCurrentBoxMagic1:: ds 1


SECTION "Saved Boxes 1", SRAM, BANK[2]

sBox1:: ds wBoxDataEnd - wBoxDataStart ; a000
sBox2:: ds wBoxDataEnd - wBoxDataStart ; a462
sBox3:: ds wBoxDataEnd - wBoxDataStart ; a8c4
sBox4:: ds wBoxDataEnd - wBoxDataStart ; ad26
sBox5:: ds wBoxDataEnd - wBoxDataStart ; b188
sBox6:: ds wBoxDataEnd - wBoxDataStart ; b5ea
sBank2AllBoxesChecksum:: ds 1 ; ba4c
sBank2IndividualBoxChecksums:: ds 6 ; ba4d

; MOVE-5.62.169: six optional per-box move identity records.
sStoredBox1MoveFlags:: ds MONS_PER_BOX
sStoredBox1FlagsChecksum:: ds 1
sStoredBox1FlagsMagic0:: ds 1
sStoredBox1FlagsMagic1:: ds 1
sStoredBox2MoveFlags:: ds MONS_PER_BOX
sStoredBox2FlagsChecksum:: ds 1
sStoredBox2FlagsMagic0:: ds 1
sStoredBox2FlagsMagic1:: ds 1
sStoredBox3MoveFlags:: ds MONS_PER_BOX
sStoredBox3FlagsChecksum:: ds 1
sStoredBox3FlagsMagic0:: ds 1
sStoredBox3FlagsMagic1:: ds 1
sStoredBox4MoveFlags:: ds MONS_PER_BOX
sStoredBox4FlagsChecksum:: ds 1
sStoredBox4FlagsMagic0:: ds 1
sStoredBox4FlagsMagic1:: ds 1
sStoredBox5MoveFlags:: ds MONS_PER_BOX
sStoredBox5FlagsChecksum:: ds 1
sStoredBox5FlagsMagic0:: ds 1
sStoredBox5FlagsMagic1:: ds 1
sStoredBox6MoveFlags:: ds MONS_PER_BOX
sStoredBox6FlagsChecksum:: ds 1
sStoredBox6FlagsMagic0:: ds 1
sStoredBox6FlagsMagic1:: ds 1


SECTION "Saved Boxes 2", SRAM, BANK[3]

sBox7::  ds wBoxDataEnd - wBoxDataStart ; a000
sBox8::  ds wBoxDataEnd - wBoxDataStart ; a462
sBox9::  ds wBoxDataEnd - wBoxDataStart ; a8c4
sBox10:: ds wBoxDataEnd - wBoxDataStart ; ad26
sBox11:: ds wBoxDataEnd - wBoxDataStart ; b188
sBox12:: ds wBoxDataEnd - wBoxDataStart ; b5ea
sBank3AllBoxesChecksum:: ds 1 ; ba4c
sBank3IndividualBoxChecksums:: ds 6 ; ba4d

; MOVE-5.62.169: six optional per-box move identity records.
sStoredBox7MoveFlags:: ds MONS_PER_BOX
sStoredBox7FlagsChecksum:: ds 1
sStoredBox7FlagsMagic0:: ds 1
sStoredBox7FlagsMagic1:: ds 1
sStoredBox8MoveFlags:: ds MONS_PER_BOX
sStoredBox8FlagsChecksum:: ds 1
sStoredBox8FlagsMagic0:: ds 1
sStoredBox8FlagsMagic1:: ds 1
sStoredBox9MoveFlags:: ds MONS_PER_BOX
sStoredBox9FlagsChecksum:: ds 1
sStoredBox9FlagsMagic0:: ds 1
sStoredBox9FlagsMagic1:: ds 1
sStoredBox10MoveFlags:: ds MONS_PER_BOX
sStoredBox10FlagsChecksum:: ds 1
sStoredBox10FlagsMagic0:: ds 1
sStoredBox10FlagsMagic1:: ds 1
sStoredBox11MoveFlags:: ds MONS_PER_BOX
sStoredBox11FlagsChecksum:: ds 1
sStoredBox11FlagsMagic0:: ds 1
sStoredBox11FlagsMagic1:: ds 1
sStoredBox12MoveFlags:: ds MONS_PER_BOX
sStoredBox12FlagsChecksum:: ds 1
sStoredBox12FlagsMagic0:: ds 1
sStoredBox12FlagsMagic1:: ds 1
