from pathlib import Path
import os,subprocess,json,time,re
root=Path('/workspace/nightfall-dorm');os.chdir(root);base=root/'docs/evidence/phase5d3';env=os.environ.copy();env.update(XDG_DATA_HOME='/workspace/runtime-data',XDG_CONFIG_HOME='/workspace/runtime-config',XDG_CACHE_HOME='/workspace/runtime-cache',NIGHTFALL_PROFILE_PATH='user://automated-test-profile.json')
commands=json.loads(Path('/tmp/phase5d3-regression-commands.json').read_text());historical={}
for p in subprocess.check_output(['git','ls-tree','-r','--name-only','3e6224e','docs/evidence'],text=True).splitlines():
 if p.endswith('.json'):historical[p]=subprocess.check_output(['git','show','3e6224e:'+p])
rows=[];start=time.time()
try:
 for name,cmd in commands:
  log=base/('regression-'+name+'.log');t=time.time();aborted=None
  with log.open('w') as f:
   process=subprocess.Popen(cmd,env=env,stdout=f,stderr=subprocess.STDOUT)
   while process.poll() is None:
    time.sleep(.5)
    if re.search(r'SCRIPT ERROR|Parse Error',log.read_text(errors='replace')):aborted='fatal script/parse error';process.terminate();break
    if time.time()-t>900:aborted='900-second suite limit';process.terminate();break
   try:code=process.wait(timeout=10)
   except subprocess.TimeoutExpired:process.kill();code=process.wait()
  txt=log.read_text(errors='replace');row=dict(suite=name,exit_code=code,seconds=round(time.time()-t,2),engine_errors=bool(re.search(r'SCRIPT ERROR|Parse Error|ERROR:',txt)),nonzero_failures=bool(re.search(r'FAILURES=[1-9]',txt)),aborted=aborted,warnings=[l for l in txt.splitlines() if l.startswith('WARNING:')]);rows.append(row)
  (base/'regression-results.json').write_text(json.dumps(dict(running=True,seconds=time.time()-start,commands=rows),indent=2)+'\n');print(json.dumps(row),flush=True)
finally:
 restored=[]
 for p,before in historical.items():
  target=Path(p)
  if target.exists() and target.read_bytes()!=before:
   dest=base/('historical-regenerated-'+p.replace('/','__'));dest.write_bytes(target.read_bytes());target.write_bytes(before);restored.append(p)
 bad=[r['suite'] for r in rows if r['exit_code'] or r['engine_errors'] or r['nonzero_failures']]
 (base/'regression-results.json').write_text(json.dumps(dict(running=False,seconds=time.time()-start,commands=rows,failed=bad,historical_restored=restored),indent=2)+'\n');print('FULL_REGRESSION_FAILED='+json.dumps(bad),flush=True)
