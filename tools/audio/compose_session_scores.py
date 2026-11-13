"""Original Phase10 scores; CC0 VSCO2 recordings, existing source/credits retained.
Distinct motifs, meter, harmony, instrumentation and rhythms, not pitch edits.
"""
from pathlib import Path
import numpy as np,json,hashlib
from scipy.io import wavfile
# Reuse the recorded instrument loader without re-rendering existing scores.
p=Path(__file__).with_name('compose_horror_scores.py');scope={'__file__':str(p)}
exec(p.read_text().split('rows=[]')[0],scope)
note=scope['note'];sr=22050;out=scope['OUT']
configs=[('music_lantern',60,72,[0,7,3,1,8,6],[0,3,6],3),('music_portrait',64,60,[0,11,7,8,2,1,6,3],[0,1,7],4),('music_dust',60,72,[0,3,10,7,1,6],[0,5,8],3),('music_siege',48,120,[0,1,0,6,7,3,2,1],[0,6,10],4),('music_procession',64,90,[0,5,1,8,7,2,6,3],[0,2,7],4),('music_opening_alt',19,96,[0,6,1,8,3,7],[0,1,6],3)]
rows=[]
for index,(name,duration,bpm,motif,chord,meter) in enumerate(configs):
 a=np.zeros((int(sr*duration),2));beat=60/bpm;events=[]
 def add(inst,pitch,start,length,gain,pan=0):
  y=note(inst,pitch,length,gain);offset=int(start*sr);n=min(len(y),len(a)-offset)
  if n<=0:return
  a[offset:offset+n,0]+=y[:n]*(.7-pan*.25);a[offset:offset+n,1]+=y[:n]*(.7+pan*.25);events.append([inst,pitch,round(start,3),round(length,3)])
 for bar in range(int(np.ceil(duration/(beat*meter)))):
  t=bar*meter*beat;root=45+[0,1,-2,3][(bar//2)%4];section=(bar//4)%4
  for degree in chord:add('trem' if index in [3,5] else 'strings',root+degree,t,beat*meter,.07)
  for step in range(meter):
   inst='bell' if index in [0,2] and step==0 else 'piano';pitch=root+12+motif[(bar*meter+step)%len(motif)]
   add(inst,pitch,t+step*beat,beat*(1.6 if index!=3 else .6),.25)
   if index in [3,4,5]:
    add('drum',36,t+step*beat,.5,.13)
    if step%2==0:add('piano',root+motif[(bar+step+3)%len(motif)],t+(step+.5)*beat,.24,.14)
  if section==3:add('timp',43,t,1.4,.22)
 if index==5:
  for pitch in [45,46,51,57]:add('trem',pitch,12,3,.2)
  add('timp',43,12,2,.4);add('bell',81,15,3,.3)
 dry=a.copy()
 for delay,gain in [(.117,.13),(.283,.09),(.409,.06)]:a+=np.roll(dry,int(sr*delay),axis=0)*gain
 a*=.58/max(.001,abs(a).max());fade=int(sr*.03);a[:fade]*=np.linspace(0,1,fade)[:,None];a[-fade:]*=np.linspace(1,0,fade)[:,None]
 file=out/(name+'.wav');wavfile.write(file,sr,(a*32767).astype('<i2'))
 rows.append({'track':name,'duration':duration,'bpm':bpm,'meter':meter,'motif':motif,'harmony':chord,'events':events,'rms':float(np.sqrt((a*a).mean())),'peak':float(abs(a).max()),'boundary_delta':float(abs(a[0]-a[-1]).max()),'sha256':hashlib.sha256(file.read_bytes()).hexdigest()})
(out/'session-score-arrangements.json').write_text(json.dumps(rows,indent=2));print([(r['track'],r['duration'],len(r['events'])) for r in rows])
