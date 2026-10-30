WarpTileIDPointers:
	dw OverworldWarpTileIDs
	dw RedsHouse1WarpTileIDs
	dw MartWarpTileIDs
	dw ForestWarpTileIDs
	dw RedsHouse2WarpTileIDs
	dw OakTSWarpTileIDs
	dw PokecenterWarpTileIDs
	dw GymWarpTileIDs
	dw HouseWarpTileIDs
	dw ForestGateWarpTileIDs
	dw MuseumWarpTileIDs
	dw UndergroundWarpTileIDs
	dw GateWarpTileIDs
	dw ShipWarpTileIDs
	dw ShipPortWarpTileIDs
	dw CemeteryWarpTileIDs
	dw InteriorWarpTileIDs
	dw CavernWarpTileIDs
	dw LobbyWarpTileIDs
	dw MansionWarpTileIDs
	dw LabWarpTileIDs
	dw ClubWarpTileIDs
	dw FacilityWarpTileIDs
	dw PlateauWarpTileIDs
	dw ForestWarpTileIDs
	dw FerryWarpTileIDs
	dw CavernWarpTileIDs
	dw MuseumWarpTileIDs
	dw JohtoPilotWarpTileIDs ; $1c/28: native Johto outdoor tileset
	dw JohtoHouseWarpTileIDs ; $1d/29: dedicated Gold house interior
	dw JohtoGateWarpTileIDs ; $1e/30: EastWestGate directional edge carpet only
	dw JohtoUnionCaveWarpTileIDs ; $1f/31: exact cave entry/exit only
WarpTileIDPointersEnd:
ASSERT WarpTileIDPointersEnd - WarpTileIDPointers == (JOHTO_UNION_CAVE + 1) * 2
OverworldWarpTileIDs:
	db 27,88,$FF
ForestGateWarpTileIDs:
GateWarpTileIDs:
	db 22,26,28,59,$FF
RedsHouse1WarpTileIDs:
RedsHouse2WarpTileIDs:
	db 26,28,$FF
MartWarpTileIDs:
	db 80,82,86,$FF
PokecenterWarpTileIDs:
	db 87,94,$FF
ForestWarpTileIDs:
	db 90,92,58,$FF
OakTSWarpTileIDs:
	db 2,$FF
GymWarpTileIDs:
	db 74,$FF
HouseWarpTileIDs:
	db 62,$FF
ShipWarpTileIDs:
	db 55,57,30,74,$FF
InteriorWarpTileIDs:
	db 21,85,4,$FF
CavernWarpTileIDs:
	db 24,26,34,52,56,$FF
LobbyWarpTileIDs:
	db 26,56,$FF
MansionWarpTileIDs:
	db 26,28,83,$FF
LabWarpTileIDs:
	db 52,$FF
FacilityWarpTileIDs:
	db 67,88,32,27,19,$FF
CemeteryWarpTileIDs:
	db 27,19,$FF
UndergroundWarpTileIDs:
	db 19,$FF
PlateauWarpTileIDs:
	db 27,59,$FF
ShipPortWarpTileIDs:
ClubWarpTileIDs:
	db $FF
FerryWarpTileIDs:
	db 16,48,$FF
MuseumWarpTileIDs:
	db $16,$1E,$FF

; Johto pilot only: original Gold New Bark ferry boarding pad ($06).
; Do not register walkable scenery tiles as generic warps.
JohtoPilotWarpTileIDs:
    ; $39 is the lower-left tile of the original Gold Cherrygrove house
    ; doorway (9,25). Only a registered warp coordinate can trigger it.
    db $06,$39,$FF
JohtoHouseWarpTileIDs:
    ; Gold WARP_CARPET_DOWN ($12) is a standable *collision-only* exit.
    ; Do not list it as STEP_ON: standing/moving sideways on y7 must not warp.
    ; CheckWarpsCollision + facing DOWN at the bottom edge handle both lanes.
    db $FF

JohtoGateWarpTileIDs:
    ; Gold LEFT/RIGHT edge carpets: only direction + collision may exit.
    db $FF

; Union Cave uses coordinate- and facing-verified Gold entrance only.
; No generic walkable tile may be used to trigger an arbitrary cave Warp.
JohtoUnionCaveWarpTileIDs:
    db $ff
