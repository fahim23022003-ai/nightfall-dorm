"""Original vector rank insignia; no external artwork or runtime dependencies."""
from pathlib import Path
import math
root=Path(__file__).resolve().parents[2]/'assets'/'ranks'
root.mkdir(parents=True,exist_ok=True)
colors=['B77A4A','BBCAD4','F4C542','75D5C7','70C8FF','B493F5']
names=['bronze','silver','gold','platinum','diamond','master']
for i,(name,color) in enumerate(zip(names,colors)):
 shapes=[]
 if i<2:
  for y in ([64] if i==0 else [54,76]):shapes.append(f'<path d="M37 {y-9} L64 {y+7} L91 {y-9}" fill="none" stroke="#{color}" stroke-width="10" stroke-linecap="round"/>')
 elif i==2:
  pts=' '.join(f'{64+math.sin(j*math.pi/5)*(30 if j%2==0 else 14):.1f},{65-math.cos(j*math.pi/5)*(30 if j%2==0 else 14):.1f}' for j in range(10))
  shapes.append(f'<polygon points="{pts}" fill="#{color}" stroke="#263746" stroke-width="3"/>')
 elif i==3:shapes.append(f'<path d="M64 32 L87 62 L64 94 L41 62Z M41 62H87 M64 32V94" fill="#{color}" stroke="#EDF5F7" stroke-width="3"/>')
 elif i==4:shapes.append(f'<path d="M44 40H84L98 58L64 94L30 58Z M30 58H98 M44 40L64 94L84 40" fill="#{color}" stroke="#EDF5F7" stroke-width="3"/>')
 else:shapes.append(f'<path d="M34 51L48 64L64 35L80 64L94 51L85 89H43Z" fill="#{color}" stroke="#EDF5F7" stroke-width="3"/><circle cx="64" cy="71" r="7" fill="#F4C542"/>')
 if i>=3:
  for x in [21,107]:
   for y in [55,70,85]:shapes.append(f'<ellipse cx="{x}" cy="{y}" rx="4" ry="8" fill="#{color}" transform="rotate({-30 if x==21 else 30} {x} {y})"/>')
 root.joinpath(name+'.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><path d="M64 8L111 29V70Q110 101 64 120Q18 101 17 70V29Z" fill="#203747" stroke="#{color}" stroke-width="7"/>'+''.join(shapes)+'</svg>')
print('Original rank badges: 6 SVGs')
