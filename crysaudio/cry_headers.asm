; CRY-5.32.01: compact cry headers with automatic full-width overrides.
;
; Normal entry (4 bytes):
;   byte 0: bits 0..6 = cry id (0..$7e), bit 7 = length bit 8
;   byte 1: pitch
;   byte 2: echo
;   byte 3: length low byte
;
; Low 7 bits == $7f marks an override. Entries whose cry id cannot fit in
; 7 bits, or whose length exceeds 9 bits, automatically keep the original
; full-width 6-byte payload in CryHeaderOverrides. This preserves the old
; independent cry/pitch/echo/length capability instead of narrowing future data.
;
; The canonical declaration list is still one readable row per Pokémon.
CryHeaderEmitMode = 0
CryHeaderDeclarationCount = 0
CryHeaderOverrideCount = 0
CryHeaderOverrideScanIndex = 0

cry_header: MACRO
	ASSERT \1 > 0
	ASSERT \1 <= $ff
	ASSERT \3 >= 0
	ASSERT \3 <= $ffff
	ASSERT \4 >= 0
	ASSERT \4 <= $ff
	ASSERT \5 >= 0
	ASSERT \5 <= $ff
	ASSERT \6 >= 0
	ASSERT \6 <= $ffff
IF CryHeaderEmitMode == 0
CryHeaderDeclarationCount = CryHeaderDeclarationCount + 1
	ASSERT \1 == CryHeaderDeclarationCount
\2:
IF (\3 < $7f) && (\6 <= $1ff)
	db (\3 & $7f) | ((\6 >> 1) & $80), \4, \5, \6 & $ff
ELSE
	; $7f is reserved as the full-width override marker.
	db $7f, 0, 0, 0
CryHeaderOverrideCount = CryHeaderOverrideCount + 1
ENDC
ELSE
CryHeaderOverrideScanIndex = CryHeaderOverrideScanIndex + 1
	ASSERT \1 == CryHeaderOverrideScanIndex
IF (\3 >= $7f) || (\6 > $1ff)
	db \1
	dw \3
	db \4, \5
	dw \6
ENDC
ENDC
ENDM

INCLUDE "crysaudio/cry_header_data.asm"

ASSERT CryHeaderDeclarationCount == NUM_POKEMON
ASSERT NUM_POKEMON <= $ff

; Keep the legacy safety coverage for all remaining nonzero 8-bit species IDs.
; These decode to the same all-zero cry parameters as before.
MissingNoCryHeaders:
rept $ff - NUM_POKEMON
	db 0, 0, 0, 0
endr

CryHeadersEnd::
ASSERT CryHeadersEnd - CryHeaders == $ff * 4

; Re-read the same canonical declarations and emit only the entries that cannot
; use the compact representation. Each record keeps the complete old widths:
; species, cry id (16-bit), pitch, echo, length (16-bit).
CryHeaderEmitMode = 1
CryHeaderOverrideScanIndex = 0

CryHeaderOverrides::
INCLUDE "crysaudio/cry_header_data.asm"
	db 0 ; species 0 terminator
CryHeaderOverridesEnd::

ASSERT CryHeaderOverrideScanIndex == NUM_POKEMON
ASSERT CryHeaderOverridesEnd - CryHeaderOverrides == CryHeaderOverrideCount * 7 + 1
