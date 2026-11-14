# REF-368C@ — Ice Path B2F Blackthorn Side (ID97) development stage

This is a **developer/source-only candidate**, not a ROM or device acceptance. The authoritative delivery rule is `RPP_PROJECT_CONTEXT/03_PROJECT_REQUIREMENTS.txt`.

## Implemented

- Activates original Gold `IcePathB2FBlackthornSide` at stable ID97, compact slot69, 5×9 block / 10×18 cell, with original block/role data and two original ladder object ordinals. Runtime is now 70 active maps / 188 registered directional Warp rows.
- Opens **B1F #8 (5,25)** ↔ **Blackthorn B2F #1 (3,15)**, source ordinals (7,0) and **B3F #2 (15,5)** ↔ **Blackthorn B2F #2 (3,3)**, source ordinals (1,1). Gold `STEP_IN_IMMEDIATE`; all four arrival locations remain stationary; source and target object tables are reviewed by the activation gate.
- Uses Gold FLOOR/ICE regular walking; explicit WALL, UP_WALL and HOP_DOWN/HOP_DOWN_LEFT directional blocking; six original directed ledge triggers with valid two-step landings. Bike remount only on Gold FLOOR, not on ice/ledge/ladder.
- Registers header, source descriptors, source/target routes, collision/bike/public step-in hooks, region map name, Town Map browsing, save slot and cave background music.
- Leaves unimplemented visible / hidden items, NPCs, Strength rocks, PIT falls, Rock Smash and auto sliding dormant. Existing B1F static-rock safety unchanged. All 5 original Gold Ice Path maps are now *active* but the original Strength/PIT/ICE puzzle mechanics are not finished.

## Source tests performed

- `python tools/asm_symbol_preflight.py` and `python tools/johto_table_assert_preflight.py --root .`: PASS.
- `python tools/johto_warp_field_entry_gate.py --root .`: **152 passed, 0 failed**.
- `python tools/johto_ice_path_b2f_blackthorn_368c_audit.py --root .`: PASS; Gold geometry, two exact stair pairs, six directed hops, collision, map headers, no premature items.
- Four related pytest files: **48 passed**. Fault injection protects source objects, routes, Gold blocks, ledge direction, bike public entry, descriptors and music slot.
- `python tools/validate_current_project.py --skip-pytest`: 14 pre-migration groups PASS, then old migration gate FAIL (**1524 passed, 35 failed**), mainly early frozen map/version counts; do not describe the entire gate as green.
- Broad legacy `python -m pytest -q --tb=short tools/tests`: **1008 passed, 83 failed, 189 skipped, 95 subtests passed**; many old test modules still expect 64/65 active maps, old Surf and Warp inventories and have not been migrated to latest version; this result is not 100% PASS.
- **Not performed:** ROM assemble/link, Red/Blue/test ROM/MAP size checks, ROM0 free-space review (required >=64B), device checks and Git Commit/Push.

## User-side application and next work

The ZIP contains exactly two mutually exclusive forward patches. `01` is from the **uploaded REF-368B.zip working tree**; `02` reconstructs from confirmed clean REF-367 HEAD `cd88452a05e9399b469f12fe2c6c89dd532dfcfb` and includes both REF-368A/B and this REF-368C plus the uploaded REF-368B's existing Mahogany branch fix. **Do not apply both.** `git apply --check` first, then `git apply`, then build locally and check MAPs/device as required. The AI does not commit, push or build ROM.

Next development phase is Ice Path mechanics: automatic ice sliding, Strength boulders and real PIT/fall landing semantics, retaining original warp ordinals. The current map-layer milestone is not final game completion.

> **REF-368D correction:** This historical development note mistakenly identified B1F Gold #8 as (5,25), the actual Gold #7. Gold #8 is (11,27). See `docs/REF368D_ICE_PATH_STAIR_HOPS_FIELD_ENTRY_FIX.md`; the old milestone's test totals do not validate this correction.
