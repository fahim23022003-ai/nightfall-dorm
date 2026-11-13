from pathlib import Path
import wave,numpy as np
root=Path(__file__).resolve().parents[1]/'assets/audio';rate=44100;length=4.8
mix=np.zeros(int(rate*length),dtype=np.float64)
for name,delay,gain in [('reaper_laugh',0,.34),('hunter_evolve',.25,.35),('weather_thunder',2.6,.24)]:
 with wave.open(str(root/(name+'.wav'))) as w:
  frames=w.getnframes();sr=w.getframerate();channels=w.getnchannels();width=w.getsampwidth();assert width==2
  a=np.frombuffer(w.readframes(frames),dtype='<i2').astype(float).reshape(-1,channels).mean(1)/32768
  a=np.interp(np.arange(int(len(a)*rate/sr))/rate,np.arange(len(a))/sr,a)
  offset=int(delay*rate);count=min(len(a),len(mix)-offset);mix[offset:offset+count]+=a[:count]*gain
fade=np.minimum(1,np.arange(len(mix))/(rate*.12))*np.minimum(1,(len(mix)-1-np.arange(len(mix)))/(rate*.65));mix*=fade
mix*=min(1,.82/max(.0001,abs(mix).max()))
with wave.open(str(root/'nightmare_rebirth.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes((mix*32767).astype('<i2').tobytes())
print('nightmare_rebirth.wav',length,'seconds; peak',float(abs(mix).max()))
# A separate finite final-form defeat tail, retaining all original recordings.
mix=np.zeros(int(rate*3.0),dtype=np.float64)
for name,delay,gain in [('reaper_laugh',0,.18),('ghost_defeat',0,.35),('weather_thunder',.4,.2)]:
 with wave.open(str(root/(name+'.wav'))) as w:
  sr=w.getframerate();channels=w.getnchannels();assert w.getsampwidth()==2
  a=np.frombuffer(w.readframes(w.getnframes()),dtype='<i2').astype(float).reshape(-1,channels).mean(1)/32768
  a=np.interp(np.arange(int(len(a)*rate/sr))/rate,np.arange(len(a))/sr,a)
  start=int(delay*rate);count=min(len(a),len(mix)-start);mix[start:start+count]+=a[:count]*gain
mix*=np.minimum(1,np.arange(len(mix))/(rate*.04))*np.minimum(1,(len(mix)-1-np.arange(len(mix)))/(rate*.7))
mix*=min(1,.82/max(.0001,abs(mix).max()))
with wave.open(str(root/'nightmare_defeat.wav'),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes((mix*32767).astype('<i2').tobytes())
print('nightmare_defeat.wav 3.0 seconds; peak',float(abs(mix).max()))
