# REF-369P@ — Ice Path B1F pit dialogue & temporary dust lifecycle (development)

## Confirmed input
REF-369O video shows that the fall message is not properly presented/closed, then appears with START. Gold IcePathB1F StoneTable uses `opentext`, `writetext`, `waitbutton`, `closetext`.

## Change
- Add a fifth B1F map text pointer (four object entries remain unchanged); B1F has exactly four sprite objects, so text ID 5 bypasses DisplayTextID sprite-ID routing.
- After Gold quake and the 16-frame rest, clear temporary Johto dust and enter `DisplayTextID` via text ID 5. This uses the existing window/font initialization, waits for A/B, restores the map and returns with the bank stack balanced. Never jump directly to `CloseTextDisplay`.
- At `DisplayStartMenu` entry clear wJohtoGoldDustFrames, so a paused OAM animator cannot revive dust after leaving the menu.
- Begin Gold-style dust when the push is accepted, cache next-tile puff screen coordinates in the pre-existing CD56/CD57 transient fields, and draw from those bytes instead of a potentially off-map/hidden stone. No save-field or WRAM allocation changes.

## Guardrails / unverified
Not a byte-for-byte port of Gold temp objects. 64-display-frame lifetime is unchanged; animation visual timing and actual ROM/UI behavior must be tested on a device. Do not infer runtime correctness from static tests. Unchanged: Kanto pushing, saving, events, collisions, 2px quake, player PIT remains sealed. No ROM compile or Git commit/push is performed in this development delivery.

## Minimum device checks
1. Push B1F stone into PIT: stone immediately disappears at end of step, sound/shake then visible `The boulder fell through.`; wait for A/B, window disappears, START works with no stale text.
2. Ordinary push then immediately START: smoke must not reappear or freeze while menu is open/closed. Repeat directions and multiple stones.
3. B2F Save/no garbage graphics, switch floors and reload with original SAV copy.
