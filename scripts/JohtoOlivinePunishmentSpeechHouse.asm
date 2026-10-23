; HOUSE-5.62.240: ordinary dialogue using the existing RPP script engine.
; Text based on Gold OlivinePunishmentSpeechHouse; no GSC story flags emulated.
JohtoOlivinePunishmentSpeechHouseTextPointers:
 dw JohtoOlivinePunishmentSpeechHouseDadText
 dw JohtoOlivinePunishmentSpeechHouseDaughterText
 dw JohtoOlivinePunishmentSpeechHouseMagazineText
 dw JohtoOlivinePunishmentSpeechHousePictureBookText

JohtoOlivinePunishmentSpeechHouseDadText:
 text "Along the way to"
 line "CIANWOOD, there"
 para "are four deserted"
 line "islands."
 para "Bad kids are taken"
 line "to the islands as"
 cont "punishment!"
 done
 db "@"

JohtoOlivinePunishmentSpeechHouseDaughterText:
 text "Whenever I get in"
 line "trouble, Daddy"
 cont "always scares me."
 done
 db "@"

JohtoOlivinePunishmentSpeechHouseMagazineText:
 text "It's a bookshelf"
 line "full of magazines."
 done
 db "@"

JohtoOlivinePunishmentSpeechHousePictureBookText:
 text "It's a bookshelf"
 line "of picture books."
 done
 db "@"
