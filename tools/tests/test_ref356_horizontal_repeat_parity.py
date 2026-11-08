"""REF-356: all quantity-pad directions use the same held-key cadence.

Uses the existing interpreter of the actual local ASM key-reader, rather than
assuming that the comments or documentation are correct.
"""
from pathlib import Path
import pytest

from test_ref356_quantity_repeat import simulate, UP, DOWN, LEFT, RIGHT

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "engine/menu/list_menu_helpers.asm").read_text(encoding="utf-8")


@pytest.mark.parametrize("key", [UP, DOWN, LEFT, RIGHT])
def test_all_four_keys_repeat_on_identical_frames(key):
    events = simulate([0] * 2 + [key] * 64)
    assert events == [(frame, key) for frame in (2, 42, 47, 52, 57, 62)]


@pytest.mark.parametrize("key", [UP, DOWN, LEFT, RIGHT])
def test_all_four_keys_reset_first_delay_after_release(key):
    events = simulate([key] * 52 + [0] * 3 + [key] * 47)
    assert [frame for frame, _ in events] == [0, 40, 45, 50, 55, 95, 100]


def test_left_right_handlers_use_shared_input_and_keep_ten_step_clamps():
    main = SRC.split("\n.waitForKeyPressLoop\n", 1)[1].split("\n.incrementQuantity\n", 1)[0]
    for direction in ("D_UP", "D_DOWN", "D_LEFT", "D_RIGHT"):
        assert "cp " + direction in main
    assert main.count("ld a,[hJoy5]") == 1
    assert "call .readQuantityMenuKeys" in main
    left = SRC.split("\n.decrementQuantityBy10\n", 1)[1].split("\n.incrementQuantityBy10\n", 1)[0]
    right = SRC.split("\n.incrementQuantityBy10\n", 1)[1].split("\n.handleNewQuantity\n", 1)[0]
    assert "sub 10" in left and "ld [hl],1" in left
    assert "add 10" in right and "ld a,[wMaxItemQuantity]" in right
    assert "ld a,40 ; first repeat" in SRC and "ld a,5 ; subsequent repeats" in SRC
