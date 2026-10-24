; Gold NPC is present; A on this NPC is intercepted before text handling.
; Good Rod item/event remains deferred and cannot be triggered here.
JohtoOlivineGoodRodHouseTextPointers:
 dw JohtoOlivineGoodRodHouseDeferredText

JohtoOlivineGoodRodHouseDeferredText:
 text "The fishing guru is"
 line "not here yet."
 done
 db "@"
