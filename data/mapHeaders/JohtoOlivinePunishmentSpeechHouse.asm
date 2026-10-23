; HOUSE-5.62.240 DEV: Gold OlivinePunishmentSpeechHouse, 4x4 House1 blocks.
JohtoOlivinePunishmentSpeechHouse_h:
 db JOHTO_HOUSE
 db JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_HEIGHT, JOHTO_OLIVINE_PUNISHMENT_SPEECH_HOUSE_WIDTH
 dw JohtoOlivinePunishmentSpeechHouseBlocks, JohtoOlivinePunishmentSpeechHouseTextPointers, EnableAutoTextBoxDrawing
 db $00 ; no direct outdoor connections
 dw JohtoOlivinePunishmentSpeechHouseObject
