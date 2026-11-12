from pathlib import Path
import os,subprocess,re,json,time,hashlib
root=Path('/workspace/nightfall-dorm');os.chdir(root);base=root/'docs/evidence/phase5d4/baseline'
env=os.environ.copy();env.update(XDG_DATA_HOME='/workspace/runtime-data',XDG_CONFIG_HOME='/workspace/runtime-config',XDG_CACHE_HOME='/workspace/runtime-cache',NIGHTFALL_PROFILE_PATH='user://phase5d4-qa-baseline.json')
script=(root/'tools/check.sh').read_text();loops=re.findall(r'for suite in (.*?); do',script)
commands=[('import',['godot','--headless','--editor','--import','--quit']),('core',['godot','--headless','--path','.','--script','tests/run_tests.gd'])]
commands += [(s,['godot','--headless','--path','.','--script',f'tests/{s}.gd']) for s in loops[0].split()+loops[1].split()]
commands += [('strategy_balance_check',['godot','--headless','--path','.','--script','tests/strategy_balance_audit.gd','--','--check']),('endless_balance_check',['godot','--headless','--path','.','--script','tests/endless_balance_audit.gd','--','--check'])]
commands += [(f'profile_{i}_{stage}',['godot','--headless','--path','.','--script','tests/profile_process_roundtrip.gd','--',stage]) for i,stage in enumerate(['cleanup','write','read','cleanup'])]
commands += [('startup',['godot','--headless','--path','.','--script','tests/startup_smoke.gd'])]
(base/'commands.json').write_text(json.dumps(commands,indent=2)+'\n');(base/'check.sh.snapshot').write_text(script)
initial_head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip();snapshots={}
for raw in subprocess.check_output(['git','ls-files','-z','docs/evidence']).split(b'\0'):
 if raw:
  p=Path(raw.decode())
  if p.suffix.lower() in ['.json','.log','.md','.txt','.csv']:snapshots[str(p)]=p.read_bytes()
rows=[];started=time.time();print('BASELINE_COMMANDS',len(commands),'HEAD',initial_head,flush=True)
try:
 for i,(name,cmd) in enumerate(commands):
  print('RUN',i+1,len(commands),name,flush=True);t=time.time();r=subprocess.run(cmd,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True);(base/(name+'.log')).write_text(r.stdout)
  errors=bool(re.search(r'SCRIPT ERROR|Parse Error|ERROR:',r.stdout));failures=bool(re.search(r'FAILURES=[1-9]',r.stdout));warnings=[s for s in r.stdout.splitlines() if 'WARNING:' in s]
  rows.append(dict(name=name,exit_code=r.returncode,engine_errors=errors,assertion_failure=failures,warnings=warnings,seconds=round(time.time()-t,3)))
  (base/'progress.json').write_text(json.dumps(rows,indent=2)+'\n');print('DONE',name,'EXIT',r.returncode,'ERRORS',errors,'FAILURES',failures,flush=True)
finally:
 restored=[]
 for name,data in snapshots.items():
  p=Path(name);current=p.read_bytes() if p.exists() else b''
  if current!=data:
   out=base/'regenerated'/p.relative_to('docs/evidence');out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(current);p.write_bytes(data);restored.append(name)
 result=dict(baseline=initial_head,commands=len(commands),completed=len(rows),passed=len(rows)==len(commands) and all(r['exit_code']==0 and not r['engine_errors'] and not r['assertion_failure'] for r in rows),seconds=round(time.time()-started,3),historical_restored=restored,source_end=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),rows=rows)
 (base/'results.json').write_text(json.dumps(result,indent=2)+'\n');print('FINAL',result['passed'],'RESTORED',restored,flush=True)
