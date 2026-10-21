; Gold MahoganyTown 5 building/gate Warp destinations remain inactive,
; because their physical local IDs have not been integrated. No dummy Warps.
; Gold coord-event merchant / Rocket plot and NPCs are not fabricated.
JohtoMahoganyTownObject:
 db $05 ; outdoor border block
 db $00 ; Gold original Warp slots #1-#5 reserved, ALL dormant
 ; #1 (11,7) -> MahoganyMart1F
 ; #2 (17,7) -> MahoganyRedGyaradosSpeechHouse
 ; #3 (6,13) -> MahoganyGym
 ; #4 (15,13) -> MahoganyPokecenter1F
 ; #5 (9,1) -> Route43MahoganyGate
 db $04 ; four original BGEVENT_READ signs, (y,x), 1-based text slot
 db 5, 1, 1 ; MahoganyTown sign
 db 7, 9, 2 ; RageCandyBar notice
 db 13, 3, 3 ; Mahogany Gym sign
 db 13, 16, 4 ; Pokecenter sign
 db $00 ; Gold NPC/scene/hidden objects deferred; no global flag re-use
