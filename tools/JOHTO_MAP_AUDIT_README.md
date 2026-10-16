# Native Johto map audit — RBK-5.62.184 closeout

## Run (no ROM build)

From the RPP project root, with a complete Gold source tree:

```sh
make johto-map-audit JOHTO_GOLD_SOURCE=/path/to/pokegold-master
# equivalent:
python3 tools/johto_map_release_audit.py --rpp . --gold /path/to/pokegold-master --expect-version RBK-5.62.184
```

Exit 0 means: explicit per-local map identity, Route32/Union Cave static Warp
contracts, the 45 Gold Johto landmarks and bike source contracts, required-test
manifest and negative regressions, and zero skipped tests all passed.
**This is not ROM compilation, a frame-accurate engine interpreter, or phone acceptance.**
If Gold is missing, any test is skipped, the suite fails or returns no tests,
the gate fails closed. Run it before applying a new map patch for review.

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
The 9 native-map identity records originated from `.178`; no run-time ASM routing has
been changed. The explicit identity registry is a reviewed snapshot of the
current baseline, **not independently validated against Gold map geometry**.

## Deliberately retained tools

`johto_rpp_*` tile/connection and `johto_indoor_*` interior tools have distinct
roles and are not deleted. Historical `johto_rpp_ledge_converter.py` remains a
manual/legacy utility; do not run it against an already-converted tileset.
This release only consolidates the *review entrypoint*, and improves two
confirmed false-green branches. It does not claim all field-move hooks or
all future maps have executable coverage yet.
