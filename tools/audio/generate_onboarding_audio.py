"""Original deterministic, sample-free Nightfall opening and menu PCM."""
from pathlib import Path
import math,random,wave,struct
root=Path(__file__).resolve().parents[2]/'assets/audio'
def write(name,duration,fn,loop=False):
 rate=22050;data=[fn(i/rate,duration) for i in range(int(duration*rate))]
 with wave.open(str(root/(name+'.wav')),'wb') as f:
  f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(struct.pack('<h',round(max(-.6,min(.6,v))*32767)) for v in data))
 p=root/(name+'.wav.import')
 if p.exists():p.write_text(p.read_text().replace('compress/mode=2','compress/mode=0'))
rng=random.Random(1931)
for n,name in enumerate(['intro_running','intro_breath','intro_lightning','intro_impact','intro_shriek','intro_whisper','tutorial_step','tutorial_complete','shop_purchase']):
 duration=[2.7,3.2,.65,.8,1.2,1.7,.28,.8,.4][n]
 def sound(t,d,n=n):
  x=t/d;env=min(1,t/.02,(d-t)/.15)
  hz=[90,65,47,75,610,150,660,440,880][n]
  if n==0:return .23*math.exp(-((t*5)%1)*14)*(math.sin(math.tau*hz*t)+.35*rng.uniform(-1,1))*env
  if n==1:return .12*math.sin(math.pi*x)**2*rng.uniform(-1,1)*env
  if n in [2,3]:return .24*math.exp(-x*5)*(rng.uniform(-1,1)+.5*math.sin(math.tau*hz*t))*env
  if n==4:return .16*(math.sin(math.tau*(hz*t+130*t*t))+.25*math.sin(math.tau*1800*t))*env*math.sin(math.pi*x)
  if n==5:return .06*(rng.uniform(-1,1)+math.sin(math.tau*hz*t))*env
  return .19*(math.sin(math.tau*hz*t)+.35*math.sin(math.tau*hz*1.5*t))*env*math.exp(-x*2)
 write(name,duration,sound)
def music(t,d):
 # Whole-cycle drones and original minor phrase; phrase envelope zero at loop edges.
 drone=.08*math.sin(math.tau*48*t)+.045*math.sin(math.tau*(73/12)*t)
 notes=[220,261.625,246.942,164.814,196,146.832,164.814,130.813]
 i=int(t/1.5);v=(t%1.5)/1.5;env=math.sin(math.pi*v)**2
 return drone+.075*env*math.sin(math.tau*notes[i%8]*t)*math.sin(math.pi*t/d)**2
write('music_menu',12,music,True)
