#!/usr/bin/env python3
"""Focused Phase 11 integration gates; isolated profiles, no user-save writes."""
import json, os, re, subprocess, time
from pathlib import Path
root=Path(__file__).resolve().parents[1]
out=root/'docs/evidence/first-night/logs';out.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,XDG_DATA_HOME='/workspace/runtime-data',XDG_CONFIG_HOME='/workspace/runtime-config',XDG_CACHE_HOME='/workspace/runtime-cache',NIGHTFALL_PROFILE_PATH='user://phase11-regression-isolated.json')
suites='run_tests first_night_features first_night_ui onboarding_qa onboarding_flow onboarding_economy session_features session_audio session_ranges night_omens spatial_construction spatial_saves_effects spatial_construction_ui spatial_earned_continuation replay_transactions replay_codes replay_pity replay_migration replay_practice replay_facts_cosmetics replay_retirement replay_ui campaign_profile campaign_flow campaign_simulations phase1_building phase1_independent ui_availability phase6_inputs phase5d3_qa_migration phase5d3_qa_spectator phase5d4_qa_save phase5d4_qa_items phase5d4_qa_evolution overhaul_qa_hud overhaul_qa_combat premium_strategy_mechanics premium_strategy_economy items_qa advanced_items_qa legendary_qa mobile_controls mobile_layout audio_system scene_smoke simulate_matches startup_smoke'.split()
rows=[]
commands=[('import',['godot','--headless','--editor','--import','--quit'])]+[(s,['godot','--headless','--path','.', '--script',f'tests/{s}.gd']) for s in suites]
commands += [('profile-process-'+s,['godot','--headless','--path','.', '--script','tests/profile_process_roundtrip.gd','--',s]) for s in ['cleanup','write','read','cleanup']]
for name,cmd in commands:
 start=time.monotonic()
 try:
  p=subprocess.run(cmd,cwd=root,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
  text=p.stdout;code=p.returncode
 except subprocess.TimeoutExpired as e:text=str(e.stdout);code=124
 (out/(name+'.log')).write_text(text)
 errors=bool(re.search(r'SCRIPT ERROR|Parse Error|ERROR:|instances leaked',text))
 row=dict(gate=name,exit=code,errors=errors,seconds=round(time.monotonic()-start,3),passed=code==0 and not errors)
 rows.append(row);print(row,flush=True)
 (out/'regressions.json').write_text(json.dumps(rows,indent=2))
print('PASSED',sum(x['passed'] for x in rows),'OF',len(rows),flush=True)
raise SystemExit(any(not x['passed'] for x in rows))
