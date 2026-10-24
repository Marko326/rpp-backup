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

# Dedicated test objects must NEVER share names with official objects.
pokered_test_obj := audio_test_red.o main_test_red.o text_test_red.o wram_test_red.o
pokeblue_test_obj := audio_test_blue.o main_test_blue.o text_test_blue.o wram_test_blue.o

.SUFFIXES:
.SECONDEXPANSION:
# Suppress annoying intermediate file deletion messages.
.PRECIOUS: %.2bpp
.PHONY: all clean cleanpic map red blue test-red test-blue compare tools

roms := patches/rppred.gbc patches/rppblue.gbc
maps := $(roms:.gbc=.map)

all: $(roms)
red: patches/rppred.gbc
blue: patches/rppblue.gbc
# Existing battle-test harness remains opt-in. Deluxe bedroom-PC gallery is
# compiled into BOTH ordinary Red and Blue builds on this recording branch.
test-red: patches/rppredtest.gbc
test-blue: patches/rppbluetest.gbc
map: $(maps)

# For contributors to make sure a change didn't affect the contents of the rom.
compare: red blue
	@$(MD5) roms.md5

clean:
	rm -f $(roms) $(pokered_obj) $(pokeblue_obj) $(roms:.gbc=.sym) patches/rppredtest.gbc patches/rppbluetest.gbc patches/rppredtest.sym patches/rppbluetest.sym patches/rppredtest.map patches/rppbluetest.map $(pokered_test_obj) $(pokeblue_test_obj)
	find . \( -iname '*.1bpp' -o -iname '*.2bpp' \) -exec rm {} +
	$(MAKE) clean -C tools/

cleanpic: clean
	find . -iname '*.pic' -exec rm {} +
	rm -f $(maps)

tools:
	$(MAKE) -C tools/


# Build tools when building the rom.
# This has to happen before the rules are processed, since that's when scan_includes is run.
ifeq (,$(filter clean cleanpic tools,$(MAKECMDGOALS)))
$(info $(shell $(MAKE) -C tools))
endif



%.asm: ;

%_red.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokered_obj): %_red.o: %.asm $$(dep)
	$(RGBASM) -D _RED -h -o $@ $*.asm

%_blue.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokeblue_obj): %_blue.o: %.asm $$(dep)
	$(RGBASM) -D _BLUE -h -o $@ $*.asm

# Dedicated opt-in compilation; the _test_ objects never overlap production.
%_test_red.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokered_test_obj): %_test_red.o: %.asm $$(dep)
	$(RGBASM) -D _RED -D BATTLE_TEST_BUILD -h -o $@ $*.asm

%_test_blue.o: dep = $(shell tools/scan_includes $(@D)/$*.asm)
$(pokeblue_test_obj): %_test_blue.o: %.asm $$(dep)
	$(RGBASM) -D _BLUE -D BATTLE_TEST_BUILD -h -o $@ $*.asm

pokered_opt  = -Cjv -k 01 -l 0x33 -m 0x13 -p 0 -r 03 -t "POKEMON RED"
pokeblue_opt = -Cjv -k 01 -l 0x33 -m 0x13 -p 0 -r 03 -t "POKEMON BLUE"

rppred_obj  := $(pokered_obj)
rppblue_obj := $(pokeblue_obj)
rppredtest_obj := $(pokered_test_obj)
rppbluetest_obj := $(pokeblue_test_obj)
rppred_opt  := $(pokered_opt)
rppblue_opt := $(pokeblue_opt)
rppredtest_opt := $(pokered_opt)
rppbluetest_opt := $(pokeblue_opt)

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
gfx/tilesets/%.2bpp: tools/gfx += --trim-whitespace

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