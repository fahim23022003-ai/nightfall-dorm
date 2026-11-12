"""Original sample-free horror/weather/prestige PCM motifs for Nightfall Dorm."""
from pathlib import Path
import math,random,struct,wave
root=Path(__file__).resolve().parents[2]/'assets/audio'
rate=22050
names=['death_scream_1','death_scream_2','hunter_laugh','reaper_laugh','weather_thunder','weather_wind','weather_rain','prestige_upgrade','survivor_notice']
for index,name in enumerate(names):
 duration=[1.25,1.35,1.1,1.35,2.0,2.2,2.4,1.0,.4][index];rng=random.Random(9723+index);samples=[];smooth=0
 for i in range(round(rate*duration)):
  t=i/rate;x=t/duration;env=min(1,t/.035,(duration-t)/.2);noise=rng.uniform(-1,1);smooth=smooth*.94+noise*.06
  if index<2:
   hz=390+index*75+180*math.sin(math.pi*x)-160*x
   value=(math.sin(math.tau*(hz*t+3*math.sin(t*13)))+.25*math.sin(math.tau*hz*2.1*t)+noise*.3)*math.sin(math.pi*x)**.6*.29
  elif index<4:
   pulse=max(0,math.sin(t*math.tau*4.5))**.6;hz=115 if index==2 else 65
   value=(math.sin(math.tau*hz*t)+.3*math.sin(math.tau*hz*1.5*t)+noise*.15)*pulse*.32*(1-x*.5)
  elif index==4:value=(smooth*2.5+noise*.16)*math.exp(-x*2.2)*.5
  elif index==5:value=smooth*(.6+.4*math.sin(x*math.pi))*.5
  elif index==6:value=noise*.065+smooth*.25
  else:
   hz=440*(1+min(3,int(x*4))*.25) if index==7 else 330
   value=(math.sin(math.tau*hz*t)+.3*math.sin(math.tau*hz*1.5*t))*math.exp(-x*2)*.28
  samples.append(round(max(-.6,min(.6,value*env))*32767))
 path=root/(name+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(struct.pack('<h',v) for v in samples))
 imported=Path(str(path)+'.import')
 if imported.exists():imported.write_text(imported.read_text().replace('compress/mode=2','compress/mode=0').replace('compress/mode=1','compress/mode=0'))
