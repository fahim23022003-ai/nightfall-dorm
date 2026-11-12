#!/usr/bin/env python3
"""Original item cues, deterministic monoPCM; no samples."""
import math,random,wave,struct
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets'/'audio';rate=22050
names=['barricade','feather','inferno','pillow','coupon','decoy','rescue','smoke']
for n,name in enumerate(names):
 duration=1.1 if name=='reveal' else .7 if name in ['shield','frost','explosion'] else .45
 rng=random.Random(6200+n);out=[]
 for i in range(int(rate*duration)):
  t=i/rate;env=min(1,t/.012,(duration-t)/.08)*math.exp(-t*(1 if name=='reveal' else 3))
  hz=153+n*61
  if name=='gold' or name=='reveal':hz=[523.25,659.25,783.99,1046.5][min(3,int(t/duration*4))]
  if name=='frost':hz=810-600*t
  if name=='radar':hz=720+math.sin(t*30)*120
  noise=rng.uniform(-1,1)*(.18 if name in ['explosion','shield_hit','trap','frost'] else .025)
  value=env*(.23*math.sin(math.tau*hz*t)+.08*math.sin(math.tau*hz*1.503*t)+noise)
  out.append(max(-.55,min(.55,value)))
 with wave.open(str(root/('item_'+name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(struct.pack('<h',round(v*32767)) for v in out))
 imported=root/('item_'+name+'.wav.import')
 if imported.exists():imported.write_text(imported.read_text().replace('compress/mode=2','compress/mode=0'))
