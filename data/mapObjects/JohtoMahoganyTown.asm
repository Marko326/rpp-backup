; Gold MahoganyTown 5 building/gate Warp destinations remain inactive,
; because their physical local IDs have not been integrated. No dummy Warps.
; Gold coord-event merchant / Rocket plot and NPCs are not fabricated.
JohtoMahoganyTownObject:
 db $05 ; outdoor border block
 db $01 ; original Gold #5 is open; first 4 unimplemented remain closed
 ; #1 (11,7) -> MahoganyMart1F
 ; #2 (17,7) -> MahoganyRedGyaradosSpeechHouse
 ; #3 (6,13) -> MahoganyGym
 ; #4 (15,13) -> MahoganyPokecenter1F
 db 1, 9, 2, REGION_WARP_ESCAPE ; Gold #5 (x9,y1) -> gate #3 (zero-based 2)
 db $04 ; four original BGEVENT_READ signs, (y,x), 1-based text slot
 db 5, 1, 1 ; MahoganyTown sign
 db 7, 9, 2 ; RageCandyBar notice
 db 13, 3, 3 ; Mahogany Gym sign
 db 13, 16, 4 ; Pokecenter sign
 db $00 ; Gold NPC/scene/hidden objects deferred; no global flag re-use
