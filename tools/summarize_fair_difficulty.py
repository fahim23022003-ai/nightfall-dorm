#!/usr/bin/env python3
"""Retained actual-model results, with explicit complete denominators."""
from pathlib import Path
import json,statistics,collections,csv
R=Path(__file__).resolve().parents[1]/'docs/evidence/fair-difficulty'
def dist(v):return None if not v else dict(n=len(v),min=min(v),median=statistics.median(v),max=max(v))
summary={};outcomes=[]
for name in ['before-disciplined-hard-bulwark','before-disciplined-hard-assault','before-disciplined-hell-bulwark','before-disciplined-hell-assault','after-hard-bulwark','after-hard-assault','after-hell-bulwark','after-hell-assault','normal-greedy','normal-defense','normal-balanced','recoverable-mistake','passive-hell','passive-hell-heldout','passive-hard']:
 d=json.loads((R/(name+'.json')).read_text());rr=d['rows'];groups={}
 for label,rows in [('all',rr),('original1-5',[r for r in rr if r['seed']<=5]),('heldout6-20',[r for r in rr if r['seed']>5])]:
  groups[label]={'n':len(rows),'outcomes':dict(collections.Counter(r['result']for r in rows)),'victory_time':dist([r['final']['time']for r in rows if r['result']=='victory']),'death_time':dist([r['final']['time']for r in rows if r['result']=='defeat']),'breach_time':dist([r['breach_time']for r in rows if r['breach_time']>=0]),'repair_gold':dist([r['repair_gold']for r in rows]),'player_damage':dist([r['damage']for r in rows]),'door_damage':dist([r['player_door_damage'] if 'player_door_damage' in r else sum(e['damage']for e in r['events']if e['type']=='door_damage' and e['room']==0) for r in rows if 'player_door_damage' in r or r['seed'] in [1,2]]),'actual_paid_decision_gap':dist([g for r in rows for g in r['decision_gaps']]),'final_gold':dist([r['final']['wallet'][0]for r in rows]),'final_income':dist([r['final']['rates'][0]for r in rows])}
 summary[name]={'groups':groups,'by_archetype':{a:dict(collections.Counter(r['result']for r in rr if r['archetype']==a))for a in sorted({r['archetype']for r in rr})}}
 for r in rr:
  outcomes.append([name,r['seed'],r['archetype'],r['result'],r['final']['time'],r['first_player_hit'],r['breach_time'],r['repair_gold'],r['damage'],r['eliminations'],r['final']['wallet'][0],r['final']['wallet'][1]])
(R/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
with (R/'outcomes.csv').open('w') as f:
 w=csv.writer(f);w.writerow(['scenario','seed','archetype','outcome','end_seconds','first_player_hit','breach_seconds','manual_repair_gold','player_damage','eliminations','gold','electricity']);w.writerows(outcomes)
for n in ['after-hard-bulwark','after-hard-assault','after-hell-bulwark','after-hell-assault']:
 print(n,summary[n]['groups']['all'])
for n in ['normal-greedy','normal-defense','normal-balanced']:
 d=json.loads((R/(n+'.json')).read_text());print(n,'5min samples',[r['samples'][60]['rates'][0] for r in d['rows'] if len(r['samples'])>60],'repair',summary[n]['groups']['all']['repair_gold'],'door damage',summary[n]['groups']['all']['door_damage'],'waves',[r['completed']for r in d['rows']])
