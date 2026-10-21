; B-ID62: Gold west lanes (x=0,y=4/5) -> EcruteakCity Warp #1/#2;
; Gold east lanes (x=9,y=4/5) -> Route42 Warp #1/#2.
; Gold 1-based targets become RPP 0-based, coordinates stored (y,x).
; FAIL CLOSED: shared warp routing and active slot are C-owned; no enabled Warp yet.
JohtoRoute42EcruteakGateObject:
	db $0d ; Johto Gate: impassable black exterior
	db $04 ; four Gold entrances and exits, zero-based target slots
	db 4, 0, 2, REGION_WARP_ESCAPE ; Ecruteak City east #1
	db 5, 0, 3, REGION_WARP_ESCAPE ; Ecruteak City east #2
	db 4, 9, 0, REGION_WARP_ESCAPE ; Route42 #1
	db 5, 9, 1, REGION_WARP_ESCAPE ; Route42 #2
	; C must insert exactly four source Warp entries, in Gold source order:
	; db 4, 0, 2, REGION_WARP_ESCAPE ; Ecruteak City east #1
	; db 5, 0, 3, REGION_WARP_ESCAPE ; Ecruteak City east #2
	; db 4, 9, 0, REGION_WARP_ESCAPE ; Route42 #1
	; db 5, 9, 1, REGION_WARP_ESCAPE ; Route42 #2
	; Verify actual native dest Warp indices (0-based) against full target lists.
	db $00 ; no Gold BG events
	db $00 ; Gold officer (x=5,y=2): NPC graphics/global script slot C stage
