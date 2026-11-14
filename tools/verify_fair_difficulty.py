#!/usr/bin/env python3
"""Regular and extended existing gates for Phase12B; focused current-rule checks run separately; isolated env, bounded concurrency."""
import concurrent.futures,json,os,re,subprocess,time
from pathlib import Path
root=Path(__file__).resolve().parents[1];out=root/'docs/evidence/fair-difficulty/regressions';out.mkdir(parents=True,exist_ok=True)
source=(root/'tools/check.sh').read_text();suites=re.search(r'for suite in (.*?); do',source).group(1).split()
env=dict(os.environ,XDG_DATA_HOME='/workspace/runtime-data',XDG_CONFIG_HOME='/workspace/runtime-config',XDG_CACHE_HOME='/workspace/runtime-cache')
def gate(name,args):
 start=time.monotonic();custom=dict(env,NIGHTFALL_PROFILE_PATH='user://phase12b-reg-'+name+'.json')
 try:
  p=subprocess.run(['godot','--headless','--path','.',*args],cwd=root,env=custom,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=900)
  body=p.stdout;code=p.returncode
 except subprocess.TimeoutExpired as e:body=(e.stdout or b'').decode() if isinstance(e.stdout,bytes) else str(e.stdout);code=124
 (out/(name+'.log')).write_text(body)
 row=dict(gate=name,exit=code,seconds=round(time.monotonic()-start,3),passed=code==0 and not re.search(r'SCRIPT ERROR|Parse Error|ERROR:|instances leaked',body));print(row,flush=True);return row
rows=[gate('import',['--editor','--import','--quit']),gate('run_tests',['--script','tests/run_tests.gd'])]
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 for row in pool.map(lambda s:gate(s,['--script','tests/'+s+'.gd']),suites):
  rows.append(row);(out/'regular.json').write_text(json.dumps(rows,indent=2))
for suite in ['audit_timesteps','audit_matrix','phase2_matrix']:
 rows.append(gate(suite,['--script','tests/'+suite+'.gd']));(out/'regular.json').write_text(json.dumps(rows,indent=2))
for suite in ['strategy_balance_audit','endless_balance_audit']:
 rows.append(gate(suite,['--script','tests/'+suite+'.gd','--','--check']));(out/'regular.json').write_text(json.dumps(rows,indent=2))
for stage in ['cleanup','write','read','cleanup']:rows.append(gate('process-'+stage,['--script','tests/profile_process_roundtrip.gd','--',stage]))
rows.append(gate('startup',['--script','tests/startup_smoke.gd']));(out/'regular.json').write_text(json.dumps(rows,indent=2))
print('PASS',sum(bool(r['passed']) for r in rows),'OF',len(rows),flush=True)
