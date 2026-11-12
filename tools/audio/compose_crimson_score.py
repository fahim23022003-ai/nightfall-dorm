"""A new sampled-instrument climax score; never rewrites the seven existing scores."""
from pathlib import Path
import argparse,hashlib,json
import numpy as np
from scipy.io import wavfile
from scipy.signal import resample_poly
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,required=True);p.add_argument('--output',type=Path,required=True);args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
SRC=args.repo/'tools/audio/source/vsco';SR=22050;SECONDS=48;BEAT=.5
files={'piano':('Keys/Upright Piano/Player_dyn1_rr1_020.wav',61),'bell':('Percussion/Glock/glock_medium_C5.wav',72),'trem':('Strings/Violin Section/Trem/VlnEns_Trem_C4_v1.wav',60),'strings':('Strings/Violin Section/susVib/VlnEns_susVib_C4_v1.wav',60),'drum':('Percussion/BDrumNewhit_v3_rr1_Sum.wav',36),'timp':('Percussion/Timpani/Timpani1_Hit_v3_rr1_Sum.wav',48)}
cache={};sources=[]
for inst,(path,key) in files.items():
 f=SRC/path;rate,x=wavfile.read(f);scale=2147483648 if x.dtype==np.int32 else 32768;x=x.astype(float)/scale
 if x.ndim>1:x=x.mean(axis=1)
 x=resample_poly(x,SR,rate);x/=max(.001,np.max(abs(x)));cache[inst]=(x,key);sources.append(dict(instrument=inst,file=str(Path('tools/audio/source/vsco')/path),sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
y=np.zeros((SECONDS*SR,2));events=[]
def add(inst,pitch,start,duration,gain,pan=0):
 x,key=cache[inst];n=int(duration*SR);idx=np.arange(n)*2**((pitch-key)/12);v=np.interp(np.minimum(idx,len(x)-1),np.arange(len(x)),x);v[idx>=len(x)]=0
 a=min(int(.012*SR),len(v)//4);r=min(int(.16*SR),len(v)//3)
 if a:v[:a]*=np.linspace(0,1,a)
 if r:v[-r:]*=np.linspace(1,0,r)
 offset=int(start*SR);take=min(len(v),len(y)-offset)
 if take<=0:return
 y[offset:offset+take,0]+=v[:take]*gain*(.72-pan*.25);y[offset:offset+take,1]+=v[:take]*gain*(.72+pan*.25)
 events.append(dict(instrument=inst,pitch=pitch,start=start,duration=duration,gain=gain,pan=pan))
# Four harmonic/motivic sections with deliberate pauses and rhythmic acceleration.
chords=[[38,41,45,50],[39,42,46,51],[37,40,44,49],[38,44,45,50]]
motif=[62,63,69,68,65,63,61,62]
for bar in range(24):
 t=bar*4*BEAT;section=(bar//3)%4;chord=chords[((bar//3)+(1 if bar>=12 else 0))%4];gain=[.8,1,.75,1.05][section]
 for pitch in chord:add('trem' if section in [1,3] else 'strings',pitch,t,BEAT*4+.08,.13*gain,-.5)
 for beat in range(4):
  at=t+beat*BEAT;note=motif[(bar*2+beat)%8]+(12 if section==2 else 0)
  add('piano',note,at,BEAT*1.2,.30*gain,.3)
  add('drum',36,at,.55,.25*gain)
  if section in [1,3] or bar%2==1:add('piano',chord[beat%4]+12,at+BEAT*.5,BEAT*.42,.15*gain,-.2)
  if section==3:add('trem',chord[beat%4]+12,at,.5,.12,-.1)
 if bar%2==0:add('timp',48,t,1.8,.34*gain)
 if bar%4==0:add('bell',74+(1 if section==1 else 0),t+BEAT,BEAT*2.8,.23,.65)
# Room reflections preserve loop seam by circular convolution rather than abrupt tails.
dry=y.copy()
for delay,gain in [(.091,.13),(.183,.09),(.319,.06)]:y+=np.roll(dry,int(delay*SR),axis=0)*gain
peak=float(np.max(abs(y)));y*=.68/max(.001,peak);fade=int(.025*SR);y[:fade]*=np.linspace(0,1,fade)[:,None];y[-fade:]*=np.linspace(1,0,fade)[:,None]
file=args.output/'music_crimson.wav';wavfile.write(file,SR,(np.clip(y,-.95,.95)*32767).astype('<i2'))
manifest=dict(track='music_crimson',seconds=SECONDS,bpm=120,score='Eight 3-bar sections: chromatic piano motif, moving dissonant strings, punctuated glockenspiel, bass drum/timpani; climax ostinati and brief contrasting high motif',sources=sources,events=events,peak=float(np.max(abs(y))),rms=float(np.sqrt(np.mean(y*y))),sha256=hashlib.sha256(file.read_bytes()).hexdigest(),license='Original arrangement using CC0-1.0 recorded VSCO2 CE samples; see preserved source/vsco LICENSE and attribution',subjective_scariness='UNVERIFIED')
(args.output/'crimson-score-arrangement.json').write_text(json.dumps(manifest,indent=2)+'\n');print('NEW_CRIMSON_SCORE',len(events),'NOTES',SECONDS,'SECONDS')
