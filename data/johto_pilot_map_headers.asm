; P3-001: active two-map Johto pilot headers.
; Both maps use the shared runtime handle $FC. The source-local ID and direction
; resolve the actual destination through JohtoPilotSourceConnections in bank $42.
; Only New Bark west <-> Route 29 east is open. Route 29 north/west and all other
; edges remain sealed until their adjacent maps are activated.

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

; P4-001: City exits EAST toward Route29. Its original north Route30
; passage is fenced in runtime-only blocks until Route30 ID3 is registered.
JohtoPilotCherrygroveRuntimeHeader::
    db JOHTO_PILOT
    db JOHTO_CHERRYGROVE_HEIGHT, JOHTO_CHERRYGROVE_WIDTH
    dw JohtoPilotCherrygroveRuntimeBlocks
    dw JohtoPilotCherrygroveTextPointers
    dw JohtoPilotMapScript
    db EAST
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
ASSERT JohtoPilotCherrygroveRuntimeHeaderEnd - JohtoPilotCherrygroveRuntimeHeader == 23
ASSERT BANK(JohtoPilotCherrygroveRuntimeHeader) == BANK(JohtoPilotCherrygroveRuntimeBlocks)

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
    para "Closed for now."
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
    db $00 ; no enabled indoor warps in the map-only phase
    db $04 ; original Gold signs (y, x, text index)
    db $08, $1e, $01 ; city
    db $09, $17, $02 ; guide's house
    db $03, $18, $03 ; Mart
    db $03, $1e, $04 ; Poke Center
    db $00 ; no replacement / diagnostic NPCs
