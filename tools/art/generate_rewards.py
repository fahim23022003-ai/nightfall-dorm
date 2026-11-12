"""Original geometric emblems for Nightfall Dorm progression; no external assets."""
from pathlib import Path
import math
root=Path(__file__).resolve().parents[2]/'assets'
groups={'perks':['pocket','reinforced','dreamer','capacitor','marksman','first_aid','reaper_slayer'],'achievements':['first_victory','first_blood','night_survivor','hell_survivor','reaper_hunter','reaper_slayer','perfect_team','iron_fortress','economy_master','master_builder','item_collector','legendary_survivor']}
colors=['E8BE61','99C8EB','85DECA','AD9DEA','FFAE77','EB92B4','DAA4FF']
for group,ids in groups.items():
 for i,name in enumerate(ids):
  c=colors[i%len(colors)];n=3+i%6
  pts=' '.join(f'{32+22*math.cos(j*math.tau/n-math.pi/2):.2f},{32+22*math.sin(j*math.tau/n-math.pi/2):.2f}' for j in range(n))
  motif=['<path d="M22 32h20M32 22v20"/>','<path d="M23 22h18v15l-9 8-9-8z"/>','<path d="M42 18a17 17 0 1 0 4 25 17 17 0 0 1-4-25"/>','<path d="m34 17-12 18h10l-2 13 14-20H33z"/>','<circle cx="32" cy="32" r="10"/><path d="M32 17v30M17 32h30"/>','<path d="M25 22h14v20H25zM21 28h22v8H21z"/>','<path d="m20 23 7 5 5-12 5 12 7-5-4 20H24z"/>'][i%7]
  svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><rect x="2" y="2" width="60" height="60" rx="13" fill="#172839" stroke="#{c}" stroke-width="2"/><polygon points="{pts}" fill="none" stroke="#{c}" opacity=".35"/><g stroke="#{c}" stroke-width="3" fill="none" stroke-linejoin="round">{motif}</g></svg>'
  (root/group/(name+'.svg')).write_text(svg)
