# FIX-5.62.284 — Route35 / Goldenrod Gate regression

Source: uploaded `.283` gameplay video / screenshot, Gold originals, NPC-5.62.243 history commit 055 & 056 (GATE-224).

Map south viewport: Route35 (10x18) must display cross-tileset-safe city preview, 3 buffer rows of 10; do not alter in-map Gold bytes or unlock seamless crossing.

Collision: Route35 `(3,5)` must be closed while National Park gate is unregistered; Gold roles say floor, mature mask says blocked. Route35 gate carpet `(9,33)` and `(10,33)` must permit lateral movement. They may trigger a warp only on collision while facing down, not on step-on.

Found runtime regression: in `.283` the city object incorrectly targeted gate slot #0 (the north door), and gate south objects targeted city slots #2/#3 (absent), although the Gold/contract destination ordinals were different. FIX-284 corrects the live target-slot bytes: City -> Gate #2, Gate south lanes -> City #0/#0.

Warp contract, 0-based target slot: City `(19,1)` -> Gate south `(4,7)` no step. Gate top `(4/5,0)` -> Route35 `(9/10,33)` no step. Route35 `(9/10,33)` -> Gate top `(4/5,0)` D_DOWN. Gate bottom `(4/5,7)` -> City `(19,1)` D_DOWN. No park/NorthRoute36 connectivity.

Risk: script checks are static and cannot prove phone-rendered pixels or actual CPU audio/movement behavior. User must rebuild new Red/Blue ROM and MAP (ROM0 >=64B) and retest; no claim of device acceptance.
