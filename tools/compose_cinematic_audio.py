"""Finite original edits of the game's credited recording library, no oscillator voices.
The source recordings and redistribution credits remain in docs/AUDIO_SOURCES.md.
"""
from pathlib import Path
import wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]/'assets/audio';RATE=44100
SOURCES={
 'crusher':('door_hit','hunter_charged_warning','reaper_impact'),
 'stalker':('footstep','hunter_stalker_warning','hunter_stalker_feint'),
 'ravager':('hunter_ravager_dash','hunter_ravager_warning','door_crack'),
 'witch':('intro_whisper','reaper_charge','impact_frost'),
 'electric':('impact_shock','hunter_charged_warning','shot_shock'),
 'storm':('weather_wind','reaper_charge','weather_thunder')}
def read(name):
 with wave.open(str(ROOT/(name+'.wav'))) as w:
  assert w.getsampwidth()==2
  sr=w.getframerate();a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float).reshape(-1,w.getnchannels()).mean(1)/32768
 return np.interp(np.arange(int(len(a)*RATE/sr))/RATE,np.arange(len(a))/sr,a)
def edit(name,seconds,layers,peak):
 out=np.zeros(int(seconds*RATE))
 for source,delay,gain,speed in layers:
  a=read(source);a=np.interp(np.arange(int(len(a)/speed))*speed,np.arange(len(a)),a);offset=int(delay*RATE);n=min(len(a),len(out)-offset)
  out[offset:offset+n]+=a[:n]*gain
 out*=np.minimum(1,np.arange(len(out))/(RATE*.03))*np.minimum(1,(len(out)-1-np.arange(len(out)))/(RATE*.25))
 # Target controlled sample peak; runtime attenuation and Effects bus still apply.
 if abs(out).max()>0:out*=peak/abs(out).max()
 with wave.open(str(ROOT/(name+'.wav')),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(RATE);w.writeframes((out*32767).astype('<i2').tobytes())
for kind,(move,charge,release) in SOURCES.items():
 edit('cinematic_'+kind+'_move',.8,[(move,0,.4,.8),(move,.18,.16,1.1)],.28)
 edit('cinematic_'+kind+'_charge',2.0,[(charge,0,.5,.9),(move,.5,.25,.75),(charge,.8,.25,1.08)],.58)
 edit('cinematic_'+kind+'_release',1.4,[(release,0,.5,.9),(move,.12,.2,.7)],.60)
print('18 finite recorded-source role cues')

edit('nightmare_rebirth',5.0,[('hunter_evolve',0,.4,.8),('reaper_laugh',.35,.38,.72),('weather_thunder',2.3,.32,.82)],.70)
edit('nightmare_defeat',3.0,[('ghost_defeat',0,.5,.8),('reaper_laugh',.25,.25,.8)],.45)
