#!/usr/bin/env python3
"""Original synthesized Reaper score and cues. No samples; deterministic PCM."""
import math, random, struct, wave
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets'/'audio'
rate=22050
rng=random.Random(4404)
def write(name,seconds,fn):
    samples=[fn(i/rate) for i in range(int(seconds*rate))]
    peak=max(abs(x) for x in samples) or 1
    gain=min(1,.58/peak)
    with wave.open(str(root/(name+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate)
        out.writeframes(b''.join(struct.pack('<h',round(x*gain*32767)) for x in samples))
    imported=root/(name+'.wav.import')
    if imported.exists(): imported.write_text(imported.read_text().replace('compress/mode=2','compress/mode=0'))
def sine(hz,t):return math.sin(math.tau*hz*t)
def env(t,length):return min(1,t/.02,max(0,(length-t)/.16))
def score(t):
    # Eight bars of deliberately unresolved low bells, detuned choir and heartbeat.
    beat=t%.6
    note=[110,116.54,146.83,103.83,110,155.56,116.54,98][int(t/1.5)%8]
    nt=t%1.5
    drone=.12*sine(36,t)+.07*sine(54,t)+.035*sine(73,t)
    choir=(.075*sine(note,t)+.035*sine(note*2.003,t))*math.sin(math.pi*nt/1.5)**2
    bell=.14*math.exp(-nt*4)*(sine(note*2,nt)+.25*sine(note*4.73,nt))
    pulse=.12*math.exp(-beat*22)*sine(47,beat)
    return drone+(choir+bell+pulse)*env(t,12)
write('music_reaper',12,score)
write('reaper_ambience',4,lambda t: env(t,4)*(.13*sine(41,t)+.04*sine(163,t)*sine(.5,t)+.035*sine(249,t)*sine(.75,t)))
write('reaper_transform',2.4,lambda t:env(t,2.4)*(.17*sine(39+12*t,t)+.16*sine(82+44*t,t)+.13*rng.uniform(-1,1)*(t/2.4)+.18*math.exp(-max(0,t-1.8)*5)*sine(57,t)))
write('reaper_scythe',.7,lambda t:env(t,.7)*(.26*rng.uniform(-1,1)*math.sin(math.pi*t/.7)**2+.16*sine(410-330*t,t)*math.exp(-t*5)))
write('reaper_charge',1.8,lambda t:env(t,1.8)*(.18*sine(55+36*t,t)+.09*sine(112+64*t,t)+.055*rng.uniform(-1,1)*t/1.8))
write('reaper_surge',1.5,lambda t:env(t,1.5)*(.15*sine(117-43*t,t)+.12*sine(175-61*t,t)+.1*rng.uniform(-1,1)*math.sin(math.pi*t/1.5)**2))
write('reaper_impact',.85,lambda t:env(t,.85)*math.exp(-t*6)*(.36*sine(49,t)+.24*rng.uniform(-1,1)+.14*sine(193,t)))
write('reaper_hurt',.35,lambda t:env(t,.35)*math.exp(-t*9)*(.19*sine(215-170*t,t)+.1*sine(331,t)+.1*rng.uniform(-1,1)))
write('reaper_death',2.2,lambda t:env(t,2.2)*math.exp(-t*.9)*(.17*sine(93-26*t,t)+.17*sine(146-37*t,t)+.1*rng.uniform(-1,1)))
print('Authored 9 original boss PCM assets')
