; MAP-5.62.139 P2-2: outdoor signs only; berry house, Mr. Pokemon's house,
; Gold trainers, berries and hidden items wait for later phases.
JohtoRoute30Object:
	db $05 ; Gold Johto forest border
	db $00 ; two building warps remain closed
	db $04 ; Gold outdoor signs (y, x, text ID)
	db $2b, $09, $01 ; Route 30 sign, x=9 y=43
	db $1d, $0d, $02 ; Mr. Pokemon directions, x=13 y=29
	db $05, $0f, $03 ; Mr. Pokemon's house sign, x=15 y=5
	db $15, $03, $04 ; Trainer Tips, x=3 y=21
	db $00 ; no NPCs, trainers or Gold engine events yet
