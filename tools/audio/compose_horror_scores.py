"""Original measured musical arrangements from genuine CC0 VSCO orchestral samples.
No oscillator/noise substitute; rerun requires numpy/scipy (offline art tools only).
"""
from pathlib import Path
import json
import numpy as np
from scipy.io import wavfile
from scipy.signal import resample_poly
BASE=Path(__file__).resolve().parent;SRC=BASE/'source/vsco';OUT=BASE.parents[1]/'assets/audio';SR=22050
SAMPLES={
 'piano':('Keys/Upright Piano/Player_dyn1_rr1_020.wav',61),
 'bell':('Percussion/Glock/glock_medium_C5.wav',72),
 'strings':('Strings/Violin Section/susVib/VlnEns_susVib_C4_v1.wav',60),
 'trem':('Strings/Violin Section/Trem/VlnEns_Trem_C4_v1.wav',60),
 'drum':('Percussion/BDrumNewhit_v3_rr1_Sum.wav',36),
 'timp':('Percussion/Timpani/Timpani1_Hit_v3_rr1_Sum.wav',48)}
cache={}
for name,(file,key) in SAMPLES.items():
 rate,x=wavfile.read(SRC/file);x=x.astype(np.float64)/(2147483648 if x.dtype==np.int32 else 32768)
 if x.ndim>1:x=x.mean(axis=1)
 x=resample_poly(x,SR,rate);x/=max(.001,np.max(abs(x)));cache[name]=(x,key)
def note(inst,pitch,seconds,gain):
 x,key=cache[inst];ratio=2**((pitch-key)/12);n=int(seconds*SR)
 idx=np.arange(n)*ratio;valid=np.minimum(idx,len(x)-1)
 y=np.interp(valid,np.arange(len(x)),x);y[idx>=len(x)]=0
 attack=min(int(.045*SR),n//5);release=min(int(.3*SR),n//3)
 if attack:y[:attack]*=np.linspace(0,1,attack)
 if release:y[-release:]*=np.linspace(1,0,release)
 return y*gain
MOTIF=[0,1,7,6,3,1,-1,0]
CHORDS=[[0,3,7],[1,4,8],[-1,2,6],[0,6,7]]
def render(name,seconds,bpm,key,density):
 audio=np.zeros((int(seconds*SR),2));events=[];beat=60/bpm
 def add(inst,pitch,start,duration,gain,pan=0):
  if start>=seconds:return
  y=note(inst,pitch,duration,gain);offset=int(start*SR);take=min(len(y),len(audio)-offset)
  audio[offset:offset+take,0]+=y[:take]*(.72-pan*.25);audio[offset:offset+take,1]+=y[:take]*(.72+pan*.25)
  events.append([inst,pitch,round(start,3),round(duration,3),gain])
 if name=='music_intro':
  for t in range(0,19,2):
   intensity=.6 if t<4 else .65 if t<8 else .8 if t<12 else 1 if t<15 else .3
   for p in CHORDS[(t//4)%4]:add('strings',key+p,t,2.5,.15*intensity,-.4)
   add('piano',key+12+MOTIF[(t//2)%8],t,2,.4*intensity,.4)
   if t<15:add('drum',36,t,1,.2*intensity)
  for t in np.arange(4,10,.5):add('piano',key+12+MOTIF[int(t*2)%8],float(t),.42,.13,.3)
  for p in [0,1,6,7,12]:add('trem',key+p,12,3,.18)
  add('timp',48,12,2,.45);add('bell',key+24,15,3,.4)
 else:
  bars=int(seconds/(beat*4))
  for bar in range(bars):
   t=bar*beat*4;section=(bar//4)%4;chord=CHORDS[(bar//2)%4];gain=[.7,.9,.6,1][section]
   for p in chord:add('strings' if density<2 else 'trem',key+p,t,beat*4+.1,.10*gain,-.45)
   for j in range(4):
    if density==0 and j%2:continue
    pitch=key+12+MOTIF[(bar*2+j)%8]+(12 if section==2 else 0)
    add('piano',pitch,t+j*beat,beat*1.7,.3*gain,.35)
    if density>=1:add('drum',36,t+j*beat,beat*.8,.11*gain)
    if density>=2:
     add('piano',key+chord[j%3],t+(j+.5)*beat,beat*.45,.17)
   if bar%2==0:add('bell',key+24+MOTIF[(bar//2)%8],t+beat,beat*3,.18,.7)
   if section==3 and bar%2==0:add('timp',48,t,beat*2,.25)
 # Sampled-room multi-tap reverb, circular for seamless repeated musical phrases.
 dry=audio.copy()
 for delay,g in [(.113,.14),(.227,.1),(.371,.07)]:audio+=np.roll(dry,int(delay*SR),axis=0)*g
 audio*=.7/max(.001,np.max(abs(audio)))
 # Small boundary de-click, longer phrases return to tonic instead of a5second loop.
 fade=int(.025*SR);audio[:fade]*=np.linspace(0,1,fade)[:,None];audio[-fade:]*=np.linspace(1,0,fade)[:,None]
 wavfile.write(OUT/(name+'.wav'),SR,(audio*32767).astype('<i2'))
 return dict(track=name,seconds=seconds,bpm=bpm,tonic_midi=key,note_events=len(events),sections='4-bar motif/harmony variations; sampled piano, violin, glockenspiel and orchestral percussion',events=events)
rows=[]
for cfg in [('music_intro',19,96,48,1),('music_menu',64,60,48,0),('music_calm',64,60,50,0),('music_approach',48,80,47,1),('music_danger',48,100,48,2),('music_reaper',64,75,45,2),('music_endless',64,90,51,2)]:rows.append(render(*cfg))
(OUT/'score-arrangements.json').write_text(json.dumps(rows,indent=2)+'\n')
print([(r['track'],r['seconds'],r['note_events']) for r in rows])
