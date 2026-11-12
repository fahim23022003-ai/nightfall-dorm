#!/usr/bin/env python3
"""Original Nightfall Mythic promotion fanfare, stdlib-only deterministic PCM."""
import math
import struct
import wave
from pathlib import Path
root=Path(__file__).resolve().parents[2]/'assets'/'audio'
rate=22050
samples=[]
for i in range(rate*2):
    t=i/rate
    value=0.0
    for index,hz in enumerate([220,277.18,329.63,440,554.37,659.25]):
        age=t-index*.12
        if age>=0:
            value+=.12*math.exp(-age*2.5)*math.sin(math.tau*hz*age)*min(1,age/.01)
    samples.append(value*min(1,(2-t)/.15))
with wave.open(str(root/'mythic_promotion.wav'),'wb') as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(rate)
    output.writeframes(b''.join(struct.pack('<h',int(value*32767)) for value in samples))
imports=root/'mythic_promotion.wav.import'
if imports.exists():
    imports.write_text(imports.read_text().replace('compress/mode=2','compress/mode=0'))
