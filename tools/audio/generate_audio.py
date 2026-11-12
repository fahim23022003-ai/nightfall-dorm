#!/usr/bin/env python3
"""Compose Nightfall Dorm's original PCM soundtrack and SFX using only stdlib.
No samples, AI models, third-party recordings, or external dependencies.
"""
import math, random, struct, wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]/'assets'/'audio'
RATE=22050
TAU=math.tau
ROOT.mkdir(parents=True,exist_ok=True)

def write(name, samples):
    peak=max(abs(x) for x in samples) or 1
    # Conservative peak; independent players/buses apply additional attenuation.
    gain=min(1,0.62/peak)
    pcm=b''.join(struct.pack('<h',round(max(-1,min(1,x*gain))*32767)) for x in samples)
    with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(pcm)
    imported=ROOT/(name+'.wav.import')
    if imported.exists():
        imported.write_text(imported.read_text().replace('compress/mode=2','compress/mode=0'))

def music(name, danger=False, menu=False):
    length=12.; notes=([146.832,174.614,164.814,130.813,146.832,195.998,164.814,138.591] if danger else [146.832,0,174.614,0,138.591,0,164.814,0])
    out=[]
    for i in range(int(length*RATE)):
        t=i/RATE
        # Drone frequencies are integer cycles per loop, preventing seam clicks.
        base=0.12*math.sin(TAU*55*t)+0.065*math.sin(TAU*(55+1/length)*t)
        base+=0.035*math.sin(TAU*(82+1/length)*t)
        slot=int(t/1.5); nt=t-slot*1.5; hz=notes[slot]
        env=(1-math.exp(-nt*5))*math.exp(-nt*2.8)
        melody=0 if not hz else env*(0.15*math.sin(TAU*hz*nt)+0.04*math.sin(TAU*hz*2.003*nt))
        if menu: melody*=0.8; base*=0.75
        pulse=0
        if danger:
            beat=t%0.5
            pulse=0.11*math.exp(-beat*28)*math.sin(TAU*48*beat)
            pulse+=0.025*math.sin(TAU*220*t)*(0.5+0.5*math.sin(TAU*2*t))
        # Musical layer is silent at loop boundaries; continuous drone remains.
        edge=min(1,t/.06,(length-t)/.12)
        out.append(base+(melody+pulse)*max(0,edge))
    write(name,out)

for name, danger, menu in [('music_menu',False,True),('music_calm',False,False),('music_danger',True,False)]: music(name,danger,menu)
for name, seconds in [('ambient_dorm',8),('proximity_loop',4),('generator_loop',2)]:
    out=[]
    for i in range(seconds*RATE):
        t=i/RATE
        if name=='ambient_dorm':
            value=.12*math.sin(TAU*37*t)+.04*math.sin(TAU*111*t)*(0.6+0.4*math.sin(TAU*.25*t))+.02*math.sin(TAU*743*t)*math.sin(TAU*.5*t)
        elif name=='proximity_loop':
            phase=t%.8
            value=.18*math.exp(-phase*18)*math.sin(TAU*43*phase)+.10*math.exp(-((phase-.18)/.065)**2)*math.sin(TAU*58*t)+.025*math.sin(TAU*219.25*t)
            value*=min(1,t/.04,(seconds-t)/.04)
        else:
            value=.08*math.sin(TAU*60*t)+.04*math.sin(TAU*120*t)+.02*math.sin(TAU*240*t)*(1+math.sin(TAU*3*t))
        out.append(value)
    write(name,out)

# Each cue has distinct harmonic/noise/contour settings. Seconds, base Hz,
# destination Hz, noise proportion, harmonic, pulse count.
SFX={
 'button':(.065,650,520,.02,1.5,1), 'menu':(.20,220,440,.01,2.0,2),
 'match_start':(.65,110,330,.05,1.5,3), 'purchase':(.22,440,880,.01,2.0,2),
 'failure':(.25,180,90,.08,1.4,2), 'rank':(1.1,262,1047,.01,1.5,5),
 'reward':(.75,392,1175,.01,2.,4), 'victory':(1.5,220,880,.02,1.5,5),
 'defeat':(1.2,220,55,.10,1.4,3), 'shot_needle':(.08,210,80,.60,2.2,1),
 'shot_arc':(.18,95,38,.30,2.0,1), 'impact':(.13,380,90,.55,1.7,1),
 'ghost_hurt':(.19,520,170,.27,1.37,1), 'ghost_defeat':(.95,520,38,.40,1.414,5), 'door_hit':(.20,85,36,.55,1.5,1),
 'door_crack':(.27,180,50,.80,2.7,3), 'door_break':(.75,130,28,.88,1.4,6),
 'build':(.30,160,480,.15,2.,3), 'turret_upgrade':(.40,220,660,.09,2.5,3),
 'bed_upgrade':(.45,330,660,.01,1.5,3), 'door_upgrade':(.42,130,390,.16,2.,3),
 'repair':(.35,240,480,.10,2.,3), 'upgrade':(.30,440,660,.02,1.5,2),
 'income':(.10,880,1320,.0,2.,1), 'electricity':(.15,160,640,.18,3.,2),
 'footstep':(.10,75,48,.50,1.3,1), 'danger':(.65,130,65,.23,1.414,2),
 'breach':(.90,230,35,.55,1.3,4), 'hunter_spawn':(1.,180,60,.25,1.414,2),
 'hunter_level':(.85,90,270,.20,1.414,3), 'elimination':(.60,220,55,.15,1.5,2)
}
for index,(name,(seconds,start,end,noise,harmonic,pulses)) in enumerate(SFX.items()):
    rng=random.Random(9500+index); out=[]; phase=0.; filtered=0.
    for i in range(int(seconds*RATE)):
        t=i/RATE; p=t/seconds
        phase+=TAU*(start+(end-start)*p)/RATE
        pulse=(t/(seconds/pulses))%1
        env=math.sin(math.pi*min(1,pulse*1.8))**2*math.exp(-pulse*2)
        if pulses==1: env=(1-math.exp(-t*180))*math.exp(-p*6)
        env*=min(1,(seconds-t)/.018)
        filtered=.45*filtered+.55*rng.uniform(-1,1)
        tone=math.sin(phase)+.23*math.sin(phase*harmonic)
        out.append(.45*env*((1-noise)*tone+noise*filtered))
    write(name,out)
print(f'Generated {len(SFX)+6} original WAV files at {ROOT}')

# Horror/immersion expansion: these are synthetic vocal-like formants, not
# recordings or a real person's voice. Deterministic jitter/noise creates breath.
for variant in range(4):
    name='door_reaction' if variant==3 else f'scream_{variant+1}'
    seconds=0.82+variant*.08
    rng=random.Random(28000+variant)
    out=[]; phase=0.; breath=0.
    for i in range(int(seconds*RATE)):
        t=i/RATE; p=t/seconds
        hz=(330+variant*47)*(1+.28*math.sin(math.pi*p))*(1-.32*p)
        hz*=1+.018*math.sin(TAU*(7+variant)*t)+rng.uniform(-.006,.006)
        phase+=TAU*hz/RATE
        breath=.4*breath+.6*rng.uniform(-1,1)
        voiced=sum(math.sin(phase*n)*math.exp(-((n*hz-1100)/900)**2)/n for n in range(1,8))
        env=math.sin(math.pi*p)**.75*min(1,t/.05,(seconds-t)/.1)
        out.append(.43*env*(voiced+.22*breath))
    write(name,out)
NEW_SFX={
 'sale':(.24,600,260,.12,1.7,3),
 'refund':(.34,520,1040,.03,2.1,4),
 'insufficient_gold':(.26,180,110,.05,1.5,2),
 'insufficient_power':(.29,145,75,.4,3.2,3),
 'eerie':(1.7,290,85,.3,1.414,2),
}
for index,(name,(seconds,start,end,noise,harmonic,pulses)) in enumerate(NEW_SFX.items()):
    rng=random.Random(31000+index); out=[]; phase=0.; filtered=0.
    for i in range(int(seconds*RATE)):
        t=i/RATE; p=t/seconds
        phase+=TAU*(start+(end-start)*p)/RATE
        pulse=(t/(seconds/pulses))%1
        env=math.sin(math.pi*min(1,pulse*1.8))**2*math.exp(-pulse*2)
        env*=min(1,(seconds-t)/.018)
        filtered=.45*filtered+.55*rng.uniform(-1,1)
        out.append(.4*env*((1-noise)*(math.sin(phase)+.23*math.sin(phase*harmonic))+noise*filtered))
    write(name,out)
print('Generated 9 additional original horror/action WAVs')
