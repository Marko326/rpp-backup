from pathlib import Path
from tools.johto_ice_path_boulder_quiet_369k_audit import audit,PUSH,DUST
ROOT=Path(__file__).parents[2]
def test_region_branches():assert audit(ROOT)==[]
def test_kanto_palette_regression():
 s=(ROOT/PUSH).read_text(); assert audit(ROOT,{PUSH:s.replace('callab AnimateBoulderDustQuiet369K\n.dustFinished','callab AnimateBoulderDust\n.dustFinished',1)})
def test_johto_must_use_gold_async():
 s=(ROOT/PUSH).read_text(); assert audit(ROOT,{PUSH:s.replace('callab BeginJohtoGoldStrengthDust369L','callab AnimateBoulderDustQuiet369K',1)})
def test_kanto_guard_required():
 s=(ROOT/PUSH).read_text()
 head,live=s.split('DoBoulderDustAnimation:',1)
 assert 'cp JOHTO_RUNTIME_MAP_HANDLE' in live
 broken=head+'DoBoulderDustAnimation:'+live.replace('cp JOHTO_RUNTIME_MAP_HANDLE','cp SEAFOAM_ISLANDS_4',1)
 assert audit(ROOT,{PUSH:broken})
def test_quiet_entry_required():
 s=(ROOT/DUST).read_text(); assert audit(ROOT,{DUST:s.replace('AnimateBoulderDustQuiet369K::','AnimateBoulderDustQuiet369Legacy::',1)})
