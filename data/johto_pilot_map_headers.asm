; P5 final (.233): five active Johto outdoor headers, stable IDs 0..4.
; Both maps use the shared runtime handle $FC. The source-local ID and direction
; resolve the actual destination through JohtoPilotSourceConnections in bank $42.
; Verified route chain: New Bark ↔ Route 29 ↔ Cherrygrove ↔ Route30 ↔ Route31.
; Route31 north/west/east and all unregistered indoor/event warps remain closed.

JohtoPilotNewBarkRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_NEW_BARK_HEIGHT, JOHTO_NEW_BARK_WIDTH
    dw JohtoPilotNewBarkRuntimeBlocks
    dw JohtoPilotNewBarkTextPointers
    dw JohtoPilotMapScript
    db WEST
    ; WEST connection record (11 bytes), target map handle is shared $FC.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute29RuntimeBlocks + JOHTO_ROUTE_29_WIDTH - 3
    dw wOverworldMap + (JOHTO_NEW_BARK_WIDTH + 6) * 3
    db JOHTO_NEW_BARK_HEIGHT
    db JOHTO_ROUTE_29_WIDTH
    db 0
    db JOHTO_ROUTE_29_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_ROUTE_29_WIDTH
    dw JohtoPilotNewBarkRuntimeObjects
JohtoPilotNewBarkRuntimeHeaderEnd::
ASSERT JohtoPilotNewBarkRuntimeHeaderEnd - JohtoPilotNewBarkRuntimeHeader == 23
ASSERT BANK(JohtoPilotNewBarkRuntimeHeader) == BANK(JohtoPilotNewBarkRuntimeBlocks)

JohtoPilotRoute29RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_29_HEIGHT, JOHTO_ROUTE_29_WIDTH
    dw JohtoPilotRoute29RuntimeBlocks
    dw JohtoPilotRoute29TextPointers
    dw JohtoPilotMapScript
    db WEST | EAST
    ; WEST: Route 29 -> Cherrygrove (same Gold north/south alignment).
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotCherrygroveRuntimeBlocks + JOHTO_CHERRYGROVE_WIDTH - 3
    dw wOverworldMap + (JOHTO_ROUTE_29_WIDTH + 6) * 3
    db JOHTO_CHERRYGROVE_HEIGHT
    db JOHTO_CHERRYGROVE_WIDTH
    db 0
    db JOHTO_CHERRYGROVE_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_CHERRYGROVE_WIDTH
    ; EAST connection record (11 bytes), target map handle is shared $FC.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotNewBarkRuntimeBlocks
    dw wOverworldMap - 3 + (JOHTO_ROUTE_29_WIDTH + 6) * 4
    db JOHTO_NEW_BARK_HEIGHT
    db JOHTO_NEW_BARK_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_NEW_BARK_WIDTH
    dw JohtoPilotRoute29RuntimeObjects
JohtoPilotRoute29RuntimeHeaderEnd::
ASSERT JohtoPilotRoute29RuntimeHeaderEnd - JohtoPilotRoute29RuntimeHeader == 34
ASSERT BANK(JohtoPilotRoute29RuntimeHeader) == BANK(JohtoPilotRoute29RuntimeBlocks)

; P5-001: the original narrow north opening connects to Route30 ID3.
; Gold city x8 aligns to Route30 x3; all other open exits remain unchanged.
JohtoPilotCherrygroveRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_CHERRYGROVE_HEIGHT, JOHTO_CHERRYGROVE_WIDTH
    dw JohtoPilotCherrygroveRuntimeBlocks
    dw JohtoPilotCherrygroveTextPointers
    dw JohtoPilotMapScript
    db NORTH | EAST
    ; NORTH connection: city x=5..14 overlaps Route30 x=0..9.
    ; The Gold source offset is +5 blocks, hence X arrival = city X - 10 tiles.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute30RuntimeBlocks + JOHTO_ROUTE_30_WIDTH * (JOHTO_ROUTE_30_HEIGHT - 3)
    dw wOverworldMap + 3 + 5
    db JOHTO_ROUTE_30_WIDTH
    db JOHTO_ROUTE_30_WIDTH
    db JOHTO_ROUTE_30_HEIGHT * 2 - 1
    db -10
    dw wOverworldMap + 1 + JOHTO_ROUTE_30_HEIGHT * (JOHTO_ROUTE_30_WIDTH + 6)
    ; EAST connection to Route29; preserve P4 behavior.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute29RuntimeBlocks
    dw wOverworldMap - 3 + (JOHTO_CHERRYGROVE_WIDTH + 6) * 4
    db JOHTO_ROUTE_29_HEIGHT
    db JOHTO_ROUTE_29_WIDTH
    db 0
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE_29_WIDTH
    dw JohtoPilotCherrygroveRuntimeObjects
JohtoPilotCherrygroveRuntimeHeaderEnd::
ASSERT JohtoPilotCherrygroveRuntimeHeaderEnd - JohtoPilotCherrygroveRuntimeHeader == 34
ASSERT BANK(JohtoPilotCherrygroveRuntimeHeader) == BANK(JohtoPilotCherrygroveRuntimeBlocks)

; P5-002: Route30 north now reaches Route31 (Gold -10 block offset);
; its existing narrow southern exit to Cherrygrove remains unchanged.
JohtoPilotRoute30RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_30_HEIGHT, JOHTO_ROUTE_30_WIDTH
    dw JohtoPilotRoute30RuntimeBlocks
    dw JohtoPilotRoute30TextPointers
    dw JohtoPilotMapScript
    db NORTH | SOUTH
    ; NORTH: Route30 x=0..9 overlaps Route31 x=10..19 (Gold offset -10).
    ; Explicit 10x3 strip (not the unsafe broad Gold-offset RPP macro).
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute31RuntimeBlocks + JOHTO_ROUTE_31_WIDTH * (JOHTO_ROUTE_31_HEIGHT - 3) + 10
    dw wOverworldMap + 3
    db JOHTO_ROUTE_30_WIDTH ; exactly ten columns
    db JOHTO_ROUTE_31_WIDTH ; source row stride = twenty blocks
    db JOHTO_ROUTE_31_HEIGHT * 2 - 1 ; north entry Y=17
    db 20 ; Route30 X -> Route31 X + 20 tiles
    dw wOverworldMap + 1 + JOHTO_ROUTE_31_HEIGHT * (JOHTO_ROUTE_31_WIDTH + 6)
    ; SOUTH: each 11-byte connection record must begin with the map handle.
    ; Keep this byte even though the source map uses the shared $FC handle.
    db JOHTO_RUNTIME_MAP_HANDLE
    ; Existing SOUTH: Gold -5 source offset; copy only city columns 5..14 (10 blocks),
    ; not the unsafe 15-column legacy SOUTH macro expansion.
    dw JohtoPilotCherrygroveRuntimeBlocks + 5
    dw wOverworldMap + (JOHTO_ROUTE_30_HEIGHT + 3) * (JOHTO_ROUTE_30_WIDTH + 6) + 3
    db JOHTO_ROUTE_30_WIDTH
    db JOHTO_CHERRYGROVE_WIDTH
    db 0
    db 10 ; Route30 x=3 -> Cherrygrove x=8 (2x2 tiles)
    dw wOverworldMap + 7 + JOHTO_CHERRYGROVE_WIDTH
    dw JohtoPilotRoute30RuntimeObjects
JohtoPilotRoute30RuntimeHeaderEnd::
ASSERT JohtoPilotRoute30RuntimeHeaderEnd - JohtoPilotRoute30RuntimeHeader == 34
ASSERT BANK(JohtoPilotRoute30RuntimeHeader) == BANK(JohtoPilotRoute30RuntimeBlocks)

; Gold Route31 20x9, SOUTH -> Route30 10x27 with Gold +10 block offset.
; Only Route31 columns 10..19 touch the 10-column Route30; the visible
; exit is within Route31 tile columns 24..27. West gate / other exits closed.
JohtoPilotRoute31RuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_ROUTE_31_HEIGHT, JOHTO_ROUTE_31_WIDTH
    dw JohtoPilotRoute31RuntimeBlocks
    dw JohtoPilotRoute31TextPointers
    dw JohtoPilotMapScript
    db SOUTH | WEST
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute30RuntimeBlocks
    dw wOverworldMap + 3 + (JOHTO_ROUTE_31_HEIGHT + 3) * (JOHTO_ROUTE_31_WIDTH + 6) + 10
    db JOHTO_ROUTE_30_WIDTH ; exactly ten columns for the overlapping strip
    db JOHTO_ROUTE_30_WIDTH ; source row stride
    db 0 ; arrival Y
    db -20 ; Route31 X -> Route30 X - 20 tiles
    dw wOverworldMap + 7 + JOHTO_ROUTE_30_WIDTH
    ; WEST screen-preview strip, aligned as in accepted NPC-5.62.243:
    ; Violet rows 9..17 overlap Route31 rows 0..8 (Gold offset -9).
    ; Boundary crossing stays blocked by the exact Route31 collision fence.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotVioletRuntimeBlocks + JOHTO_VIOLET_CITY_WIDTH * 9 + JOHTO_VIOLET_CITY_WIDTH - 3
    dw wOverworldMap + 3 * (JOHTO_ROUTE_31_WIDTH + 6)
    db JOHTO_ROUTE_31_HEIGHT
    db JOHTO_VIOLET_CITY_WIDTH
    db 18
    db JOHTO_VIOLET_CITY_WIDTH * 2 - 1
    dw wOverworldMap + 6 + 2 * JOHTO_VIOLET_CITY_WIDTH
    dw JohtoPilotRoute31RuntimeObjects
JohtoPilotRoute31RuntimeHeaderEnd::
ASSERT JohtoPilotRoute31RuntimeHeaderEnd - JohtoPilotRoute31RuntimeHeader == 34
ASSERT BANK(JohtoPilotRoute31RuntimeHeader) == BANK(JohtoPilotRoute31RuntimeBlocks)

JohtoPilotMapScript::
    call EnableAutoTextBoxDrawing
    ret


; Source-accurate sign, NPC and ferry coordinates from NPC-5.62.243.
; Only the Route 29 north gate warp remains closed while its destination is inactive.
; JHT-5.62.110: deliberately independent of Gold's story flags and warps.
JohtoPilotNewBarkTextPointers:
	dw JohtoPilotNewBarkSailorText
	dw JohtoPilotNewBarkTeacherText
	dw JohtoPilotNewBarkFisherText
	dw JohtoPilotNewBarkVisitorText
	dw JohtoPilotNewBarkSignText
	dw JohtoPilotNewBarkHomeSignText
	dw JohtoPilotNewBarkLabSignText
	dw JohtoPilotNewBarkElmsHouseSignText

JohtoPilotNewBarkSailorText:
	text "The ferry connects"
	line "this town with"
	cont "Vermilion Port."
	para "Step onto the"
	line "shore to board!"
	done
	db "@"

JohtoPilotNewBarkTeacherText:
	text "Welcome to"
	line "New Bark Town!"
	done
	db "@"

JohtoPilotNewBarkFisherText:
	text "Route 29 is open"
	line "to the west!"
	cont "Take care!"
	done
	db "@"

JohtoPilotNewBarkVisitorText:
	text "This is PROF."
	line "ELM's famous lab."
	done
	db "@"

JohtoPilotNewBarkSignText:
	text "NEW BARK TOWN"
	para "The Town Where"
	line "Winds of a New"
	cont "Beginning Blow"
	done
	db "@"

JohtoPilotNewBarkHomeSignText:
	text "<PLAYER>'s House"
	para "Closed for now."
	done
	db "@"

JohtoPilotNewBarkLabSignText:
	text "ELM #MON LAB"
	para "Closed for now."
	done
	db "@"

JohtoPilotNewBarkElmsHouseSignText:
	text "ELM'S HOUSE"
	para "Closed for now."
	done
	db "@"

; MAP-5.62.126: original scenery/NPC positions, neutral dialogue only.
; Gen 2 trainer, catching tutorial, item ball and fruit-tree events
; are intentionally not transplanted into the Gen 1 script engine.
JohtoPilotRoute29TextPointers:
	dw JohtoPilotRoute29GuideText
	dw JohtoPilotRoute29YoungsterText
	dw JohtoPilotRoute29TeacherText
	dw JohtoPilotRoute29FisherText
	dw JohtoPilotRoute29EastSignText
	dw JohtoPilotRoute29WestSignText

JohtoPilotRoute29GuideText:
	text "This is Route 29."
	para "The tall grass"
	line "is thick here!"
	done
	db "@"

JohtoPilotRoute29YoungsterText:
	text "This road goes to"
	line "CHERRYGROVE CITY."
	para "The city is now"
	line "open to the west!"
	done
	db "@"

JohtoPilotRoute29TeacherText:
	text "Watch your step"
	line "near the ledges!"
	done
	db "@"

JohtoPilotRoute29FisherText:
	text "The gate ahead"
	line "leads to ROUTE 46."
	done
	db "@"

JohtoPilotRoute29EastSignText:
	text "ROUTE 29"
	para "NEW BARK TOWN -"
	line "CHERRYGROVE CITY"
	done
	db "@"

JohtoPilotRoute29WestSignText:
	text "ROUTE 29"
	para "CHERRYGROVE CITY -"
	line "NEW BARK TOWN"
	done
	db "@"


; MAP-5.62.126: keep buildings closed; west path now reaches Route 29.
JohtoPilotNewBarkRuntimeObjects::
	db $05 ; Gold Johto forest border block

	db $01 ; warps
	db $08, $11, $00, INSIDE_FERRY ; ferry boarding, eastern shoreline

	db $04 ; signs
	db $08, $08, $05 ; town sign
	db $05, $0b, $06 ; player's home sign
	db $03, $03, $07 ; Elm's lab sign
	db $0d, $09, $08 ; Elm's house sign

	db $01 ; ferry sailor only: remove the three temporary sprite diagnostics
	object SPRITE_SAILOR,      $10, $07, STAY, RIGHT, $01 ; ferry, unchanged
; Original Gold New Bark has a teacher, fisher and event-gated rival here.
; They need their real art/event rules before release; do not leave the
; reference branch's GAMBLER/BUG_CATCHER/LASS debug lookalikes in town.

; MAP-5.62.126: authentic sign/NPC coordinates; non-ported events
; (fruit tree, item ball, catching tutorial, trainers) remain disabled.
JohtoPilotRoute29RuntimeObjects::
	db $05 ; original Gold forest border block

	db $00 ; north gate is not active in this first two-map release

	db $02 ; original Route29 road signs only
	db $07, $33, $05 ; original eastern Route 29 sign (x=51, y=7)
	db $05, $03, $06 ; original western Route 29 sign (x=3, y=5)

	db $04 ; existing Gen 1 stand-ins at original Gold NPC coordinates
	object SPRITE_GAMBLER,     $32, $0c, STAY, DOWN,  $01 ; catching-tutorial guide
	object SPRITE_BUG_CATCHER, $1b, $10, STAY, DOWN,  $02 ; youngster
	object SPRITE_LASS,        $0f, $0b, STAY, LEFT,  $03 ; teacher
	object SPRITE_FISHER,      $19, $03, STAY, DOWN,  $04 ; fisherman

; Original Gold Cherrygrove four exterior signs; houses and storyline events
; deliberately remain closed. No temporary diagnostic NPCs.
JohtoPilotCherrygroveTextPointers:
    dw JohtoPilotCherrygroveCitySignText
    dw JohtoPilotCherrygroveHouseSignText
    dw JohtoPilotCherrygroveMartSignText
    dw JohtoPilotCherrygroveCenterSignText

JohtoPilotCherrygroveCitySignText:
    text "CHERRYGROVE CITY"
    para "The City of"
    line "Fragrant Flowers"
    done
    db "@"
JohtoPilotCherrygroveHouseSignText:
    text "GUIDE GENT'S HOUSE"
    para "You can go inside!"
    done
    db "@"
JohtoPilotCherrygroveMartSignText:
    text "#MON MART"
    para "Closed for now."
    done
    db "@"
JohtoPilotCherrygroveCenterSignText:
    text "#MON CENTER"
    para "Closed for now."
    done
    db "@"

JohtoPilotCherrygroveRuntimeObjects::
    db $05 ; original Gold outdoor forest border
    db 1 ; P6-001: first registered Gold Guide Gent door only
    db 9, 25, 0, JOHTO_REGISTERED_WARP_SELECTOR ; Gold Guide Gent house -> stable ID 125
    db $04 ; original Gold signs (y, x, text index)
    db $08, $1e, $01 ; city
    db $09, $17, $02 ; guide's house
    db $03, $18, $03 ; Mart
    db $03, $1e, $04 ; Poke Center
    db $00 ; no replacement / diagnostic NPCs


; Route30 outdoor sign coordinates derive from Gold Route30_MapEvents.
; Original buildings (7,39)/(17,5), trainers, wilds and story stay inactive.
JohtoPilotRoute30TextPointers:
    dw JohtoPilotRoute30SignText
    dw JohtoPilotRoute30DirectionsText
    dw JohtoPilotRoute30HouseText
    dw JohtoPilotRoute30TipsText
JohtoPilotRoute30SignText:
    text "ROUTE 30"
    para "VIOLET CITY -"
    line "CHERRYGROVE CITY"
    done
    db "@"
JohtoPilotRoute30DirectionsText:
    text "MR.#MON'S HOUSE"
    para "Straight ahead!"
    done
    db "@"
JohtoPilotRoute30HouseText:
    text "MR.#MON'S HOUSE"
    para "Closed for now."
    done
    db "@"
JohtoPilotRoute30TipsText:
    text "TRAINER TIPS"
    para "Watch the ledges!"
    done
    db "@"
JohtoPilotRoute30RuntimeObjects::
    db $05 ; shared outdoor forest border
    db $00 ; neither Gold house has an enabled indoor destination yet
    db $04 ; exactly four original exterior signs (Y, X, text index)
    db 43, 9, 1
    db 29, 13, 2
    db 5, 15, 3
    db 21, 3, 4
    db $00 ; no trainer/NPC event sprites until later event phase


; Gold Route31 exterior signage (y=5,x=7 and y=5,x=31); indoor gate,
; cave, trainer, fruit tree, item and storyline events remain deferred.
JohtoPilotRoute31TextPointers:
    dw JohtoPilotRoute31SignText
    dw JohtoPilotRoute31CaveSignText
JohtoPilotRoute31SignText:
    text "ROUTE 31"
    para "VIOLET CITY -"
    line "CHERRYGROVE CITY"
    done
    db "@"
JohtoPilotRoute31CaveSignText:
    text "DARK CAVE"
    para "Entrance closed"
    line "for now."
    done
    db "@"
JohtoPilotRoute31RuntimeObjects::
    db $05 ; original Gold outdoor forest border
    db $02 ; Route31 Gate pair enabled, Dark Cave remains closed
    db 6, 4, 2, JOHTO_REGISTERED_WARP_SELECTOR
    db 7, 4, 3, JOHTO_REGISTERED_WARP_SELECTOR
    db $02 ; two original outdoor signs
    db 5, 7, 1
    db 5, 31, 2
    db $00 ; original seven NPC / event objects stay deferred

; Violet City P6-GATE-001: city is reachable via its Gold east gate only.
; Route31 east/west outdoor seam stays disabled until strip/fence audited.
JohtoPilotVioletRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_VIOLET_CITY_HEIGHT, JOHTO_VIOLET_CITY_WIDTH
    dw JohtoPilotVioletRuntimeBlocks
    dw JohtoPilotVioletTextPointers
    dw JohtoPilotMapScript
    db EAST
    ; EAST screen-preview strip, aligned as in accepted NPC-5.62.243:
    ; Route31 rows 0..8 overlap Violet rows 9..17 (Gold offset +9).
    ; At the gate, the player stays on the direction carpet; the seam is
    ; still not an unrestricted outdoor crossing.
    db JOHTO_RUNTIME_MAP_HANDLE
    dw JohtoPilotRoute31RuntimeBlocks
    dw wOverworldMap + (9 + 3) * (JOHTO_VIOLET_CITY_WIDTH + 6) + JOHTO_VIOLET_CITY_WIDTH + 3
    db JOHTO_ROUTE_31_HEIGHT
    db JOHTO_ROUTE_31_WIDTH
    db -18
    db 0
    dw wOverworldMap + 7 + JOHTO_ROUTE_31_WIDTH
    dw JohtoPilotVioletRuntimeObjects
JohtoPilotVioletRuntimeHeaderEnd::
ASSERT JohtoPilotVioletRuntimeHeaderEnd - JohtoPilotVioletRuntimeHeader == 23
ASSERT BANK(JohtoPilotVioletRuntimeHeader) == BANK(JohtoPilotVioletRuntimeBlocks)

JohtoPilotVioletTextPointers:
    dw JohtoPilotVioletSignText
    dw JohtoPilotVioletGymSignText
    dw JohtoPilotVioletSproutSignText
    dw JohtoPilotVioletAcademySignText
    dw JohtoPilotVioletCenterSignText
    dw JohtoPilotVioletMartSignText
JohtoPilotVioletSignText:
    text "VIOLET CITY"
    para "The City of"
    line "Nostalgic Scents"
    done
    db "@"
JohtoPilotVioletGymSignText:
    text "VIOLET GYM"
    para "Closed for now."
    done
    db "@"
JohtoPilotVioletSproutSignText:
    text "SPROUT TOWER"
    para "Closed for now."
    done
    db "@"
JohtoPilotVioletAcademySignText:
    text "#MON ACADEMY"
    para "Closed for now."
    done
    db "@"
JohtoPilotVioletCenterSignText:
    text "#MON CENTER"
    para "Closed for now."
    done
    db "@"
JohtoPilotVioletMartSignText:
    text "#MON MART"
    para "Closed for now."
    done
    db "@"

JohtoPilotVioletRuntimeObjects::
    db $05 ; original Gold city border metatile
    db 2 ; only Route31VioletGate door pair (Gold warps 8 and 9)
    db 24, 39, 0, JOHTO_REGISTERED_WARP_SELECTOR
    db 25, 39, 1, JOHTO_REGISTERED_WARP_SELECTOR
    db 6 ; original exterior signs; no Gold item events or NPC stories
    db 20, 24, 1
    db 17, 15, 2
    db  8, 24, 3
    db 17, 27, 4
    db 25, 32, 5
    db 17, 10, 6
    db 0
