#!/usr/bin/env python3
"""Read-only MAP-269 regression contract, based on Gold and accepted ILEX-217.

Static checks cannot assert a ROM has linked or sprite VRAM has rendered.
"""
from pathlib import Path
import hashlib
import re
from johto_ilex_217_geometry import expected_runtime

ROOT = Path(__file__).resolve().parents[1]
PIXEL_HASHES = {
    'johto_ilex_forest': '0a2ce55df718c1e38901deffc56bce8422be1b1848d8961f6c6fb46192572981',
    'johto_new_bark_roofs': '194789ec87d9022a1baa57b93708c94e66369a08dd4d6d982ff478c5861b99a4',
    'johto_violet_roofs': 'b5f009989681b11a35296039c0a35acf30e24ac4bd5912bd69e8435a628220e7',
    'johto_azalea_roofs': 'f6fa152cc315fa59737ba75e845167575f4f04f8e4bc71c759a20a11086dfc6e',
    'johto_goldenrod_roofs': '2352afed2fabc914fe4d61b8aee4950394467081ec1f48a43ee8a7b0f9644b7c',
}
BINARY_HASH = '50636a7b656ee41686410b72da9d5ecfdd97fb1fd3dd296b7beb59e06d5c87ba'
PALETTES = {
    'Azalea': ('27,31,27', '22,20,10', '17,14,03', '07,07,07'),
    'Goldenrod': ('27,31,27', '25,25,00', '20,17,08', '07,07,07'),
    'Violet': ('27,31,27', '24,14,31', '13,07,21', '07,07,07'),
    'NewBark': ('27,31,27', '20,31,14', '11,23,05', '07,07,07'),
    'Cherrygrove': ('27,31,27', '31,14,28', '31,05,21', '07,07,07'),
}


def audit(root=ROOT):
    root=Path(root)
    problems=[]
    def read(path):
        return (root/path).read_text(encoding='utf-8')
    try:
        from PIL import Image
        for name, expected in PIXEL_HASHES.items():
            png=root/'gfx/tilesets'/f'{name}.png'
            with Image.open(png) as im:
                target=(128,48) if name=='johto_ilex_forest' else (24,24)
                if im.size!=target or hashlib.sha256(im.convert('L').tobytes()).hexdigest()!=expected:
                    problems.append(f'{name}: mature/Gold source pixels changed')
            if png.with_suffix('.2bpp').exists():
                problems.append(f'{name}: derived .2bpp must not ship')
        blockset=(root/'gfx/blocksets/johto_ilex_forest.bst').read_bytes()
        if len(blockset)!=46*16 or hashlib.sha256(blockset).hexdigest()!=BINARY_HASH:
            problems.append('IlexForest accepted 46-block cliff/Cut table altered')
        orig=(root/'maps/johto_pilot/IlexForest.gold.blk').read_bytes()
        live=(root/'maps/johto_pilot/IlexForest.runtime.blk').read_bytes()
        if expected_runtime(orig)!=live:
            problems.append('IlexForest runtime must only have six accepted .217 clones')
        seam=read('data/johto_route33_runtime.asm').split('JohtoRoute33StepPolicy::',1)[1]
        left=seam.split('\n.left\n',1)[1].split('\n.bounds',1)[0]
        if not (all(x in left for x in ('and a','.leftInside','dec b'))
                and re.search(r'cp 14\s+jp z, \.seamAllowed\s+cp 15\s+jp z, \.seamAllowed\s+ret',left)):
            problems.append('Route33 west x=0 y=14/15 seam no longer bypasses the 8-bit underflow')
        if not re.search(r'(?s)\.seamAllowed\s+ld e, 0\s+ret',seam):
            problems.append('Route33 exact seam has no open E=0 result')
        if 'cp 14\n    ret z\n    cp 15\n    ret z' not in read('engine/johto_pilot_runtime.asm'):
            problems.append('Route33 Gold west edge guard drift')
        roof=read('engine/johto_south_roofs_269.asm')
        for token in ('JohtoSouthRoofAfterTilesetLoad::','JohtoSouthRoofOnConnection::',
                      'SelectJohtoSouthRoofSource269::', 'CopyVideoData','FarCopyData2'):
            if token not in roof:
                problems.append('Missing roof art full-load/connection logic '+token)
        home=read('home/overworld.asm')
        # FIX-270 keeps the same two roof effects but routes them through the
        # pre-existing Home farcalls to avoid consuming ROM0 for new hooks.
        for token in ('callba JohtoSouthTilesetGfxFinalizer270',
                      'callba JohtoSouthConnectionSpritesAndRoofs270',
                      'jp nz,.noCollision'):
            if token not in home:
                problems.append('Roof hook or owner-tested JP missing: '+token)
        colors=read('color/loadpalettes.asm')
        for name,palette in PALETTES.items():
            label=f'Johto{name}RoofPalette269:'
            if label not in colors:
                problems.append(f'{name}: missing RGB5 roof palette')
                continue
            section=colors.split(label,1)[1].split('RoofPalette269:',1)[0]
            actual=tuple(re.findall(r'RGB\s+(\d+\s*,\s*\d+\s*,\s*\d+)',section))
            if tuple(x.replace(' ','') for x in actual)!=palette:
                problems.append(f'{name}: wrong Gold roof RGB5 value')
        ledges=read('engine/overworld/ledges.asm')
        if 'ld hl, JohtoIlexForestLedgeTiles\n\tjp .checkPairs' not in ledges:
            problems.append('Forest lacks accepted .217 pair-based shared hop executor')
        if 'db $0F, $2D' not in read('engine/overworld/cut.asm') or 'cp $2d' not in read('engine/johto_south_geometry.asm'):
            problems.append('Forest Cut clone mismatched with approved $2d block')
        if 'cp JOHTO_ILEX_FOREST' not in read('color/sprites.asm'):
            problems.append('Forest night Cut object colors not selected')
        if 'CAVE_GRAY, CAVE_RED, CAVE_GREEN, CAVE_BLUE' not in read('color/data/map_palette_sets.asm'):
            problems.append('Forest cave palette family missing')
    except (OSError,ValueError,IndexError,KeyError) as e:
        problems.append(str(e))
    return problems

if __name__=='__main__':
    problems=audit()
    if problems:
        print('FAIL:',*problems,sep='\n- ')
        raise SystemExit(1)
    print('PASS: Route33 west seam, mature Ilex HOP/Cut assets, Gold roof art+RGB5, hooks, PNG-only')
