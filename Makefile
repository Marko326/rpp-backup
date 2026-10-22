# RGBDS tools. By default they are resolved from PATH.
# To use a project-local RGBDS version, run for example:
#   make RGBDS=rgbds-0.5.2/
# Individual tools can also be overridden explicitly.
RGBDS ?=
RGBASM ?= $(RGBDS)rgbasm
RGBLINK ?= $(RGBDS)rgblink
RGBFIX ?= $(RGBDS)rgbfix
RGBGFX ?= $(RGBDS)rgbgfx

MD5 := md5sum -c

pokered_obj := audio_red.o main_red.o text_red.o wram_red.o
pokeblue_obj := audio_blue.o main_blue.o text_blue.o wram_blue.o

.SUFFIXES:
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp
.PHONY: all clean cleanpic map red blue compare tools johto-map-audit johto-id-preflight

roms := patches/rppred.gbc patches/rppblue.gbc
maps := $(roms:.gbc=.map)

all: $(roms)
red: patches/rppred.gbc
blue: patches/rppblue.gbc
map: $(maps)

# For contributors to make sure a change didn't affect the contents of the rom.
compare: red blue
	@$(MD5) roms.md5

clean:
	rm -f $(roms) $(pokered_obj) $(pokeblue_obj) $(roms:.gbc=.sym)
	find . \( -iname '*.1bpp' -o -iname '*.2bpp' \) -exec rm {} +
	$(MAKE) clean -C tools/

cleanpic: clean
	find . -iname '*.pic' -exec rm {} +
	rm -f $(maps)

tools:
	$(MAKE) -C tools/

# Static-only gate; requires full Gold source. Does not build tools or ROM.
johto-map-audit:
	python3 tools/johto_map_release_audit.py --rpp . --gold "$(JOHTO_GOLD_SOURCE)"


# Local-ID preflight needs no external Gold checkout and does not build a ROM.
johto-id-preflight:
	python3 tools/johto_fixed_id_audit.py --project .

# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean cleanpic tools johto-map-audit johto-id-preflight,$(MAKECMDGOALS)))
$(info $(shell $(MAKE) -C tools))
endif



%.asm: ;

# All ROM object compilation must wait for the fixed-ID ownership gate.
$(pokered_obj) $(pokeblue_obj): | johto-id-preflight

%_red.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokered_obj): %_red.o: %.asm $$(dep)
	$(RGBASM) -D _RED -h -o $@ $*.asm

%_blue.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokeblue_obj): %_blue.o: %.asm $$(dep)
	$(RGBASM) -D _BLUE -h -o $@ $*.asm

pokered_opt  = -Cjv -k 01 -l 0x33 -m 0x13 -p 0 -r 03 -t "POKEMON RED"
pokeblue_opt = -Cjv -k 01 -l 0x33 -m 0x13 -p 0 -r 03 -t "POKEMON BLUE"

rppred_obj  := $(pokered_obj)
rppblue_obj := $(pokeblue_obj)
rppred_opt  := $(pokered_opt)
rppblue_opt := $(pokeblue_opt)

patches:
	mkdir -p $@

patches/%.gbc: $$(%_obj) | patches
	$(RGBLINK) -n patches/$*.sym -o $@ $^
	$(RGBFIX) $($*_opt) $@
	sort patches/$*.sym -o patches/$*.sym

patches/%.map: $$(%_obj) | patches
	$(RGBLINK) -n patches/$*.sym -m $@ -o patches/$*.gbc $^
	$(RGBFIX) $($*_opt) patches/$*.gbc
	sort patches/$*.sym -o patches/$*.sym

gfx/blue/intro_purin_1.6x6.2bpp: rgbgfx += -h
gfx/blue/intro_purin_2.6x6.2bpp: rgbgfx += -h
gfx/blue/intro_purin_3.6x6.2bpp: rgbgfx += -h
gfx/red/intro_nido_1.6x6.2bpp: rgbgfx += -h
gfx/red/intro_nido_2.6x6.2bpp: rgbgfx += -h
gfx/red/intro_nido_3.6x6.2bpp: rgbgfx += -h

gfx/game_boy.norepeat.2bpp: tools/gfx += --remove-duplicates
gfx/theend.interleave.2bpp: tools/gfx += --interleave --png=$<
# ILEX-5.62.216 roof sources: keep all nine (3x3) original Gold tiles.
# PNG is tracked; 2bpp is generated during the normal build. Do NOT run the
# generic tileset whitespace trimmer on these compact roof atlases.
gfx/tilesets/johto_%_roofs.2bpp: gfx/tilesets/johto_%_roofs.png
	$(RGBGFX) -o $@ $<
	@test "$$(wc -c < "$@")" -eq 144 || { echo "Roof atlas must contain exactly 9 tiles: $@" >&2; exit 1; }

gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace

# GATE-5.62.159: johto_gate uses collision-sensitive absolute 8x8 IDs.
# Never trim the trailing blank tiles: keep the entire 96-slot ($600 byte) atlas.
# .2bpp is a generated file ignored by Git; the patch only carries its PNG source.
gfx/tilesets/johto_gate.2bpp: gfx/tilesets/johto_gate.png
	$(RGBGFX) -o $@ $<

# Gold Union Cave uses fixed IDs, including collision-distinct image copies.
# Keep all 96 slots; otherwise trimmed generated 2bpp breaks ROM tile pointers.
gfx/tilesets/johto_union_cave.2bpp: gfx/tilesets/johto_union_cave.png
	$(RGBGFX) -o $@ $<

# ILEX-5.62.212: Gold Forest uses all 96 tile slots including absolute IDs.
gfx/tilesets/johto_ilex_forest.2bpp: gfx/tilesets/johto_ilex_forest.png
	$(RGBGFX) -o $@ $<

# Park full-Gold graphics: fixed 96 slots; never trim sparse tile indices.
gfx/tilesets/johto_park.2bpp: gfx/tilesets/johto_park.png
	$(RGBGFX) -o $@ $<
gfx/tilesets/johto_park_gate.2bpp: gfx/tilesets/johto_park_gate.png
	$(RGBGFX) -o $@ $<
gfx/tilesets/johto_ruins_gate.2bpp: gfx/tilesets/johto_ruins_gate.png
	$(RGBGFX) -o $@ $<

%.png: ;

%.2bpp: %.png
	$(RGBGFX) $(rgbgfx) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -o $@ $@)
%.1bpp: %.png
	$(RGBGFX) -d1 $(rgbgfx) -o $@ $<
	$(if $(tools/gfx),\
		tools/gfx $(tools/gfx) -d1 -o $@ $@)
%.pic:  %.2bpp
	tools/pkmncompress $< $@