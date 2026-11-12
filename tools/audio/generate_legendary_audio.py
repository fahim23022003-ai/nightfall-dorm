"""Original deterministic synthesized Legendary motifs; no samples. PCM 44.1 kHz."""
import math,random,wave,struct
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets/audio';rate=44100
for n,name in enumerate(['time_freeze','reaper_seal','guardian_heart','cursed_fortune','legendary_reveal']):
 duration=[1.25,1.05,1.4,1.35,1.6][n]; rng=random.Random(782+n);out=[]
 for i in range(int(rate*duration)):
  t=i/rate; x=t/duration;env=min(1,t/.02,(duration-t)/.25)*math.exp(-x*1.8)
  notes=[[880,659.25,440,220],[329.63,493.88,659.25,987.77],[261.63,329.63,392,523.25],[220,261.63,311.13,207.65],[392,493.88,587.33,783.99]][n]
  hz=notes[min(3,int(x*4))]
  tone=math.sin(math.tau*hz*t)+.4*math.sin(math.tau*hz*2*t)
  shimmer=.2*math.sin(math.tau*(1500*t-400*t*t)) if n==0 else .18*math.sin(math.tau*hz*3*t)*math.exp(-((x*4)%1)*5)
  undertone=.17*math.sin(math.tau*(55 if n==3 else hz*.5)*t)
  noise=rng.uniform(-1,1)*.045*math.exp(-x*8)
  out.append(.23*env*(tone+shimmer+undertone+noise))
 with wave.open(str(root/('item_'+name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(struct.pack('<h',round(max(-.8,min(.8,v))*32767)) for v in out))
