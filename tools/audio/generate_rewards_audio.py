"""Original deterministic PCM progression cues, no sampled sources."""
from pathlib import Path
import math,struct,wave
root=Path(__file__).resolve().parents[2]/'assets/audio'
for j,name in enumerate(['perk_unlocked','achievement_unlocked','achievement_claim','difficult_stage','stage_bonus_selected','mythic_perk']):
 rate=22050;duration=.65+j*.08;out=[]
 for i in range(int(rate*duration)):
  t=i/rate;x=t/duration;freq=[261.63,329.63,392,523.25][min(3,int(x*4))]*(1+j*.055)
  env=min(1,t/.015,(duration-t)/.12)*math.exp(-x*1.2)
  v=.28*env*(math.sin(math.tau*freq*t)+.25*math.sin(math.tau*freq*2*t))
  out.append(round(v*32767))
 path=root/(name+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(out),*out))
 imp=Path(str(path)+'.import')
 if imp.exists():imp.write_text(imp.read_text().replace('compress/mode=2','compress/mode=0'))
