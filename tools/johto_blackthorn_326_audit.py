"""DEV-326 fail-closed, Gold-byte & source-level Blackthorn one-map activation."""
from pathlib import Path
import hashlib,re
from johto_surf_coverage_audit import read_active_maps

GOLD_SHA = 'f6460760a67901f6dce2b4df3f3c75c68e429a5c71bd907c725a955578e4676c'
ROUTE45_SHA = 'fc47a6b79f86d911d64dba30568ae0b0e98ff2d9a65d8ed7bb5f718321290223'

def audit(root, gold_root=None, overrides=None):
    root=Path(root);overrides=overrides or {};checks=[]
    def blob(name):
        value=overrides.get(name)
        return (value.encode() if isinstance(value,str) else value) if value is not None else (root/name).read_bytes()
    def txt(name):return blob(name).decode('utf8')
    def ck(name, ok):checks.append({'name':name,'passed':bool(ok)})
    source=blob('maps/johto_pilot/BlackthornCity.gold.blk')
    runtime=blob('maps/johto_pilot/BlackthornCity.runtime.blk')
    ck('gold_blackthorn_data', len(source)==360 and source==runtime and hashlib.sha256(source).hexdigest()==GOLD_SHA)
    preview=blob('maps/johto_pilot/BlackthornCity.east_preview.blk')
    ck('route44_east_shares_blackthorn_bytes', source==preview and
       'JohtoBlackthornBlocks:: INCBIN' in txt('data/johto_route44_runtime_324.asm'))
    south=blob('maps/johto_pilot/Route45.south_preview.blk')
    ck('south_preview_original_not_trees', len(south)==450 and hashlib.sha256(south).hexdigest()==ROUTE45_SHA)
    if gold_root:
        gold=Path(gold_root)/'maps'
        ck('original_gold_cross_check', source==(gold/'BlackthornCity.blk').read_bytes() and south==(gold/'Route45.blk').read_bytes())
    roles=blob('maps/johto_pilot/BlackthornCity.roles.bin')
    ck('blackthorn_40x36_roles_80_water',len(roles)==1440 and roles.count(2)==80 and set(roles)<={0,1,2})
    hdr=txt('data/johto_blackthorn_runtime_326.asm')
    ck('south_preview_and_west_connection',all(x in hdr for x in (
      'db SOUTH | WEST ; Gold Route45 and Route44 seams physically active',
      'dw JohtoBlackthornSouthRoute45Preview','dw JohtoRoute44Blocks + JOHTO_ROUTE_44_WIDTH - 3',
      'dw wOverworldMap + (3 + 9) * (JOHTO_BLACKTHORN_CITY_WIDTH + 6)',
      'ASSERT JohtoBlackthornHeaderEnd - JohtoBlackthornRuntimeHeader == 34',
      'ASSERT BANK(JohtoBlackthornRuntimeHeader) == BANK(JohtoRoute44Blocks)')))
    ck('only_gold_center_door_open',re.search(r'JohtoBlackthornRuntimeObjects::\s*db \$71[^\n]*\s*db 1[^\n]*\s*db 29, 21, 0, JOHTO_REGISTERED_WARP_SELECTOR[^\n]*\s*db 0[^\n]*\s*db 0',hdr) is not None)
    east=txt('data/johto_east_runtime_300.asm')
    ck('collision_and_sealed_south',all(x in east for x in (
     'cp JOHTO_BLACKTHORN_CITY_LOCAL_ID\n    jp z, .blackthorn',
     'cp JOHTO_BLACKTHORN_CITY_HEIGHT * 2 - 1\n    ret c',
     'cp 18\n    jp c, .closed','ld hl, JohtoBlackthornRoles')))
    conn=txt('data/johto_pilot_source_resources.asm')
    ck('registered_only_reciprocal_west',
       'JOHTO_ROUTE_44_LOCAL_ID, EAST, MAP_REGION_JOHTO, JOHTO_BLACKTHORN_CITY_LOCAL_ID' in conn and
       'JOHTO_BLACKTHORN_CITY_LOCAL_ID, WEST, MAP_REGION_JOHTO, JOHTO_ROUTE_44_LOCAL_ID' in conn and
       'JOHTO_BLACKTHORN_CITY_LOCAL_ID, SOUTH, MAP_REGION_JOHTO, JOHTO_ROUTE_45_LOCAL_ID' in conn)
    ck('blackthorn_slot43_only',len(read_active_maps(root))>=44 and read_active_maps(root)[43]['stable_id']==71)
    return {'status':'PASS_STATIC_ONLY' if all(x['passed'] for x in checks) else 'FAIL',
            'checks':checks,'errors':[x['name'] for x in checks if not x['passed']]}
