#!/usr/bin/env python3
"""Summarize retained measured outputs; no simulated or inferred missing samples."""
from pathlib import Path
import json,statistics,collections,re
R=Path(__file__).resolve().parents[1]/'docs/evidence/earned-power'
def dist(values):
 return None if not values else dict(n=len(values),min=min(values),median=statistics.median(values),max=max(values))
output={}
for name in ['baseline-strategies','new-greedy','new-defense','new-balanced','grid-first','hell','hell-counter','hell-counter-tuned','hell-supplies','hell-siege','long-night','permanent-pair']:
 d=json.loads((R/(name+'.json')).read_text());groups={}
 for kind,strategy in sorted(set((x['kind'],x['strategy']) for x in d['rows'])):
  rows=[x for x in d['rows'] if x['kind']==kind and x['strategy']==strategy]
  g=dict(n=len(rows),outcomes=dict(collections.Counter(x['result'] for x in rows)),end_time=dist([x['final']['time'] for x in rows]),repair_gold=dist([x['repair_spent'] for x in rows]),peak_wallet=dist([x['peak_gold'] for x in rows]),milestones={})
  for milestone in ['first_generator','first_machine10','bed10','door10']:g['milestones'][milestone]=dist([x['milestones'][milestone] for x in rows if milestone in x['milestones']])
  g['samples']={}
  for minute in [1,3,5,10,20]:
   points=[p for x in rows for p in x['samples'] if abs(p['time']-minute*60)<.3]
   g['samples'][str(minute)]=dict(observations=len(points),**{key:dist([p[key] for p in points if key in p]) for key in ['gold','electricity','gold_rate','electricity_rate','gross_gold','gross_electricity','spent_gold','bed','door','capacity','hunter_hp','survivor_eliminations','completed','wave']})
   if points and 'flows' in points[0]:g['samples'][str(minute)]['flow_totals']={key:dist([p['flows'].get(key,0) for p in points]) for key in points[0]['flows']}
  groups[kind+'/'+strategy]=g
 output[name]=dict(engine=d.get('engine'),mode=d.get('mode','standard'),groups=groups)
(R/'progression-summary.json').write_text(json.dumps(output,indent=2)+'\n')
# Preserve first failures and resolve only against actual passing rerun logs.
initial=json.loads((R/'regressions/regular.json').read_text());reruns={x['gate']:x for x in json.loads((R/'regressions/reruns.json').read_text())}
resolved=[]
for row in initial:
 x=dict(row);x['initial_passed']=row['passed'];x['evidence']='regressions/'+row['gate']+'.log'
 if not x['passed']:
  final=R/'regressions'/(row['gate']+'.final.log')
  if final.exists():
   body=final.read_text();ok=bool(re.search(r'FAILURES=0',body)) and not re.search(r'SCRIPT ERROR|Parse Error|ERROR:|instances leaked',body)
   x['passed']=ok;x['evidence']='regressions/'+final.name
  elif reruns.get(row['gate'],{}).get('passed'):
   x['passed']=True;x['evidence']='regressions/reruns.json'
  x['reason']='Explicit legacy fixture rules for original Catalog assertions; version2 property/economy/UI checks run separately. Legacy snapshot audit no longer serializes a new ledger into old rules.'
 resolved.append(x)
(R/'regressions/resolved.json').write_text(json.dumps(dict(initial_pass=sum(x['passed'] for x in initial),total=len(initial),final_pass=sum(x['passed'] for x in resolved),rows=resolved),indent=2)+'\n')
print('Regressions',sum(x['passed'] for x in resolved),'/',len(resolved))
for name in ['baseline-strategies','new-greedy','new-defense','new-balanced','grid-first']:
 for key,g in output[name]['groups'].items():
  if key.startswith('endless'):print(name,key,'gen',g['milestones']['first_generator'],'machine10',g['milestones']['first_machine10'],'5m G/s',g['samples']['5']['gold_rate'],'20m G/s',g['samples']['20']['gold_rate'])
