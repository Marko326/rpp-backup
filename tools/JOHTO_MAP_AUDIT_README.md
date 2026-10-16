# Native Johto map audit — DIG-5.62.188 cave escape accepted stage

## Run (no ROM build)

From the RPP project root, with a complete Gold source tree:

```sh
make johto-map-audit JOHTO_GOLD_SOURCE=/path/to/pokegold-master
# equivalent:
python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version DIG-5.62.188
```

Exit 0 means: explicit per-local map identity, Route32/Union Cave static Warp
contracts, the 45 Gold Johto landmarks and bike source contracts, required-test
manifest and negative regressions, and zero skipped tests all passed.
**This is not ROM compilation, a frame-accurate engine interpreter, or phone acceptance.**
If Gold is missing, any test is skipped, the suite fails or returns no tests,
the gate fails closed. Run it before applying a new map patch for review.

## Required source contracts and Field Moves preflight

`tools/johto_native_maps.json` and `tools/johto_door_contracts.json` must be
tracked in Git and included in any clean source export. The root `.gitignore`
now exempts these two specific files from its general `*.json` rule. Verify
with `git ls-files -- tools/johto_native_maps.json tools/johto_door_contracts.json`;
if either is missing from Git, explicitly stage the reviewed original with
`git add -f`, then inspect its diff before a separate tool commit.

The strict map gate also runs `tools/johto_field_moves_preflight.py`. Its PASS
means **only** Union Cave 1F and Route32 Surf have reviewed runtime water classification, **and only Union Cave 1F** has reviewed Dig/Escape Rope eligibility. Other Johto cave escapes and water remain **DEFERRED**. The
preflight rejects unexpected allow-list insertions or cave-return widening. Gold
source auditing and phone acceptance are independent: current `.188` has user-reported
Union Cave return acceptance, not a claim of exhaustive all-map runtime coverage. See
`docs/JOHTO_FIELD_MOVES_PREFLIGHT_zh.md`.

## Adding a native map

1. Update `constants/region_map_constants.asm` and all standard mapping tables.
2. Register the new local ID in `tools/johto_native_maps.json` with
   the exact Header pointer/bank, old alias, RBY/GSC music, ordinary Town Map
   marker/name/coordinates, and every `feature_status` field.
3. Use `DEFERRED` (not `ALLOWED`) for unimplemented or unverified features.
   Capability states are **review metadata**, not runtime checks or proof of
   eligibility. Add corresponding behavioral audits for every new enabled
   Warp/bike/field move/Fly path, then verify on hardware.
4. Check Gold asset source, collision/entrance semantics and the ordinary
   Town Map **background** separately. Passing the native Town Map *index*
   check does not prove the static background graphic is correct.
5. Keep new locations unsafe to enter closed until their engine flows pass
   static audit and handset regression.

Fields use `ALLOWED`, `FORBIDDEN`, `DEFERRED`, `NOT_APPLICABLE`; identity evidence
uses `STATIC_PASS`, `GOLD_REFERENCE_PENDING`, `PHONE_PENDING`, `USER_ACCEPTED`.
The 9 native-map identity records originated from `.178`; the `.188` Dig/Rope
routing is a narrow *new* runtime exception for Union Cave 1F only. The
identity registry is reviewed audit metadata, **not** an engine permission gate or
proof that every map geometry has been independently tested on a phone.

## Deliberately retained tools

`johto_rpp_*` tile/connection and `johto_indoor_*` interior tools have distinct
roles and are not deleted. Historical `johto_rpp_ledge_converter.py` remains a
manual/legacy utility; do not run it against an already-converted tileset.
This audit also includes the Gold-backed `.188` single-entrance cave escape
contract and mutation regressions (`test_johto_cave_escape188.py`). The `.188`
strict gate expects **298 tests, 0 errors, 0 skips** with complete Gold sources;
no build is performed and the report does not itself verify phone behavior.
It does not claim all future field-move hooks or maps have executable coverage.
