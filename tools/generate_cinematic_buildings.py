"""Original role-specific shaded machinery. 17 families x four construction tiers."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/cinematic_buildings';ROOT.mkdir(exist_ok=True)
KINDS={'turret':'8edbd4','heavy':'bda0ff','generator':'efce80','repair':'9bd9bd','economy':'dfb861','enhancer':'d7a8e2','flame':'ff9760','frost':'96eaff','shock':'bd9aff','auto_repair':'9ee2bb','shield':'87cfff','decoy':'d591c3','barrier':'dac8ff','plasma':'ff9dcf','antenna':'91e1e6','bed':'bd9dc8','door':'91bacb'}
def path(d,fill='url(#steel)',extra=''):return f'<path d="{d}" fill="{fill}" {extra}/>'
def rect(x,y,w,h,fill='url(#steel)',r=3):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}"/>'
def ell(x,y,rx,ry,fill='url(#steel)'):return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}"/>'
def line(d,c='#8296a3',w=1):return path(d,'none',f'stroke="{c}" stroke-width="{w}"')
def make(k,t,c):
 color='#'+c;parts='';cx=64
 if k not in ['bed','door']:
  parts+=ell(64,132,43,13,'#08121b')+path('M21 119 L59 102 105 119 105 132 64 147 21 132Z')+path('M21 119 L62 103 105 119 64 135Z','url(#plate)')
  for x in [29,91]:parts+=rect(x,119,8,10,'#273b4b')+rect(x+1,120,3,3,'#b6c7cf')
 if k in ['turret','heavy','flame','frost','shock']:
  parts+=path('M42 117 L43 97 58 86 84 98 87 120 64 130Z')+ell(64,99,25,12,'url(#plate)')
  if k=='turret':
   parts+=rect(43-t*3,79,42+t*6,22)+path('M45 79 L58 67 89 75 85 88Z','url(#plate)')
   for i in range(1+t):
    x=48+i*(29/max(1,t));parts+=rect(x-4,43-t*4,8,45+t*4)+ell(x,45-t*4,4,2,'#080e16')+line(f'M{x-2} {48-t*4} L{x-2} 73',color,2)
   if t>=2:parts+=rect(28,77,13,25)+rect(87,77,13,25)
   if t==3:parts+=path('M25 104 L25 69 37 61 41 105 M88 104 L88 61 102 72 103 104')+ell(65,81,11,7,'url(#energy)')
  elif k=='heavy':
   for side in [-1,1]:
    x=64+side*(14+t*3);parts+=rect(x-8,55-t*6,16,47+t*6)+ell(x,56-t*6,9,4,'url(#energy)')
    for n in range(3+t):parts+=ell(x,65-t*5+n*6,12,4,'url(#copper)')
   parts+=ell(64,89,12,16,'url(#energy)')
   if t==3:parts+=path('M28 102 Q14 47 49 29 M100 102 Q114 47 79 29','none','stroke="url(#plate)" stroke-width="8"')+ell(64,34,17,9,'url(#energy)')
  elif k=='flame':
   for x in [34,82]:parts+=rect(x-4,63-t*5,20,49+t*5,'url(#copper)',8)+ell(x+6,64-t*5,10,4,'url(#plate)')+rect(x,72-t*4,12,20,'#382d2b')
   parts+=rect(51,65-t*4,25,34,'url(#copper)')+rect(55,42-t*5,16,32,'url(#steel)')
   for n in range(3+t):parts+=rect(57,52-t*5+n*5,12,2,color,0)
   if t>=2:parts+=path('M35 113 Q17 93 35 89 M93 113 Q111 93 93 89','none','stroke="#906e50" stroke-width="5"')
   if t==3:parts+=path('M56 43 Q44 34 58 17 Q58 31 68 22 Q82 34 70 43Z','url(#energy)')
  elif k=='frost':
   for i in range(1+t*2):
    x=64+(i-t)*10;tip=53-t*6+abs(i-t)*9
    parts+=path(f'M{x-9} 106 L{x-8} {tip+17} {x} {tip} {x+8} {tip+21} {x+6} 108Z','url(#energy)')+line(f'M{x} {tip+3} L{x+2} 102','#d7ffff',1)
   if t>=2:parts+=path('M33 117 L26 90 40 97 M95 117 L102 90 88 97','url(#plate)')
  else:
   parts+=ell(64,112,35+t*2,17,'url(#copper)')+ell(64,109,30+t*2,13,'#172638')
   for n in range(2+t):parts+=ell(64,105-n*8,22-n,8,'url(#copper)')
   parts+=ell(64,77-t*6,14+t*2,15+t*2,'url(#energy)')
   if t==3:
    for x in [27,96]:parts+=rect(x,55,5,51)+ell(x+2,55,6,7,'url(#energy)')
 elif k=='generator':
  parts+=rect(32,80,64,42)+path('M32 80 L46 69 105 79 96 90Z','url(#plate)')
  for i in range(2+t):
   x=39+i*(49/(1+t));parts+=rect(x-4,51-t*6,9,43+t*6)
   for n in range(4+t):parts+=ell(x,57-t*5+n*6,9,3,'url(#copper)')
  parts+=ell(64,110,13,10,'url(#energy)')
  if t>=2:parts+=rect(22,90,8,31)+rect(98,90,8,31)
  if t==3:parts+=path('M25 89 Q21 29 64 26 Q107 29 103 89','none','stroke="url(#copper)" stroke-width="7"')+ell(64,33,11,6,'url(#energy)')
 elif k in ['repair','auto_repair']:
  parts+=rect(43,94,43,27)+rect(52,84,26,15,'url(#plate)')
  for side in [-1,1]:
   x=64+side*(26+t*3);parts+=path(f'M{64+side*18} 116 L{x} {79-t*5} {64+side*16} {61-t*6}','none','stroke="#617c88" stroke-width="9"')+ell(x,79-t*5,7,7,'url(#copper)')+path(f'M{64+side*16} {61-t*6} L{64+side*6} {65-t*6} M{64+side*16} {61-t*6} L{64+side*10} {51-t*6}','none',f'stroke="{color}" stroke-width="3"')
  parts+=rect(56,98,16,14,'url(#energy)')+line('M59 105 L69 105 M64 100 L64 110','#e8ffee',2)
  if k=='auto_repair':parts+=rect(82,94,15,25,'url(#copper)')
  if t==3:parts+=rect(52,28,24,14,'url(#plate)')+line('M56 35 L72 35 M64 30 L64 40',color,3)
 elif k=='economy':
  parts+=path('M34 70 L74 60 98 75 96 122 41 130 28 115Z')+rect(40,77,43,41,'url(#copper)')+ell(61,96,15,15,'url(#steel)')+ell(61,96,8,8,'url(#copper)')
  for n in range(2+t):parts+=rect(44,67-n*7,40,5,'url(#copper)')
  if t>=2:parts+=rect(23,81,10,34)+rect(91,81,10,34)
  if t==3:parts+=path('M26 60 L64 30 102 60 91 70 64 48 38 70Z','url(#copper)')
 elif k in ['enhancer','antenna']:
  parts+=rect(55,72,18,48)+path('M35 115 L55 85 55 115 M73 115 L73 85 96 115')
  if k=='enhancer':
   parts+=path(f'M{39-t*4} {48-t*4} Q64 {97-t*2} {89+t*4} {48-t*4} Q66 {61-t*3} {39-t*4} {48-t*4}Z','url(#plate)')+line(f'M64 {76-t*3} L76 {42-t*5}',color,4)+ell(76,42-t*5,4,4,'url(#energy)')
  else:
   parts+=rect(62,31-t*3,5,61)
   for n in range(2+t):parts+=path(f'M{44-n*2} {52+n*9} Q64 {76+n*9} {84+n*2} {52+n*9}','none',f'stroke="{color}" stroke-width="4"')
  if t==3:
   for side in [-1,1]:parts+=rect(64+side*34-3,61,6,51)+ell(64+side*34,58,6,9,'url(#energy)')
 elif k in ['shield','barrier','plasma']:
  parts+=path('M43 120 L38 78 49 63 80 63 92 79 85 122Z')
  if k=='shield':
   parts+=path(f'M{35-t*3} 98 Q{25-t*2} {44-t*5} 64 {35-t*4} Q{103+t*2} {44-t*5} {93+t*3} 98 L83 106 Q89 66 64 55 Q40 66 45 106Z','url(#plate)')+path('M49 85 Q64 74 79 85 L75 108 64 119 52 108Z','url(#energy)')
  elif k=='barrier':
   parts+=path(f'M64 {37-t*6} L{84+t*5} 71 84 101 64 117 43 100 {43-t*5} 71Z','url(#plate)')+path(f'M64 {48-t*4} L{78+t*2} 75 75 96 64 108 52 95 {50-t*2} 75Z','url(#energy)')+line(f'M64 {48-t*4} L64 108','#e6edff',2)
  else:
   for side in [-1,1]:
    x=64+side*(15+t*3);parts+=rect(x-9,56-t*6,18,53+t*6,'url(#plate)',7)+rect(x-5,65-t*6,10,35+t*6,'url(#energy)',4)
   parts+=ell(64,84,12,17,'url(#energy)')
   if t==3:parts+=path('M36 62 Q64 15 92 62','none','stroke="#798ba1" stroke-width="7"')
 elif k=='decoy':
  parts+=path('M43 122 L45 90 37 70 48 56 80 56 92 71 84 91 85 122Z','url(#steel)')
  parts+=ell(64,74,19+t*2,22+t*2,'url(#copper)')+path('M50 72 Q64 61 78 72 L75 89 64 96 53 89Z','#191b28')+ell(56,77,4,3,'url(#energy)')+ell(72,77,4,3,'url(#energy)')
  for side in [-1,1]:parts+=path(f'M{64+side*17} 64 Q{64+side*(34+t*3)} {52-t*5} {64+side*(25+t*4)} {33-t*4} Q{64+side*26} 60 {64+side*20} 77Z','url(#copper)')
  if t==3:parts+=path('M44 94 Q15 87 22 118 L38 110 M83 95 Q113 87 106 118 L91 111')
 elif k=='bed':
  parts+=path('M27 39 L85 25 102 40 100 138 41 152 25 137Z')+rect(34,43,57,87,'url(#velvet)',8)+path('M36 53 L87 44 88 74 38 82Z','#aab4bc')+path('M36 83 Q63 74 89 75 L89 128 37 138Z','url(#blanket)')+line('M40 93 Q59 84 85 88 M43 120 Q64 112 83 115','#758d9c',2)
  for side in [-1,1]:parts+=rect(64+side*31-3,37-t*5,6,101+t*5,'url(#copper)')
  if t>=1:parts+=path('M28 42 Q53 17 91 29 L96 49 32 58Z','url(#velvet)')
  if t>=2:parts+=path('M25 36 Q23 12 62 6 Q104 8 102 35 L90 33 Q62 16 36 39Z','url(#plate)')
  if t==3:parts+=path('M28 25 Q15 64 28 119 L39 110 Q28 65 41 27 M91 24 Q110 66 97 126 L87 115 Q99 72 80 22Z','url(#velvet)')
 else:
  parts+=path('M25 130 L25 39 Q60 13 101 36 L101 132 88 140 87 47 Q62 31 39 48 L39 138Z')+path('M42 50 Q64 36 85 49 L85 130 42 136Z','url(#plate)')+line('M64 45 L64 132','#131d2a',3)
  for n in range(2+t):parts+=path(f'M43 {62+n*15} L61 {58+n*15} 61 {68+n*15} 43 {73+n*15}Z','url(#copper)')+path(f'M68 {58+n*15} L84 {62+n*15} 84 {73+n*15} 68 {68+n*15}Z','url(#copper)')
  if t>=1:parts+=rect(18,64,10,63)+rect(99,64,10,63)
  if t>=2:parts+=path('M20 40 Q60 -1 108 35 L107 50 Q62 18 21 54Z','url(#copper)')
  if t==3:parts+=path('M28 37 L40 14 65 5 91 14 102 37 86 29 65 19 42 31Z','url(#plate)')+ell(64,88,14,20,'url(#energy)')
 defs=f'''<defs><linearGradient id="steel" x2="1" y2=".6"><stop stop-color="#8c9ca6"/><stop offset=".25" stop-color="#465b69"/><stop offset=".55" stop-color="#263849"/><stop offset="1" stop-color="#0e1927"/></linearGradient><linearGradient id="plate" x2=".3" y2="1"><stop stop-color="#9eadb8"/><stop offset=".4" stop-color="#4a6574"/><stop offset="1" stop-color="#132332"/></linearGradient><linearGradient id="copper" x2="1" y2=".8"><stop stop-color="#d4b994"/><stop offset=".4" stop-color="#866b52"/><stop offset="1" stop-color="#302f31"/></linearGradient><radialGradient id="energy" cx=".35" cy=".3"><stop stop-color="#edffff"/><stop offset=".25" stop-color="{color}"/><stop offset="1" stop-color="#24384e"/></radialGradient><linearGradient id="velvet" x2="1" y2=".5"><stop stop-color="#998399"/><stop offset=".4" stop-color="#55485e"/><stop offset="1" stop-color="#24283a"/></linearGradient><linearGradient id="blanket" x2=".8" y2="1"><stop stop-color="#90a8b9"/><stop offset=".4" stop-color="#516e88"/><stop offset="1" stop-color="#25364d"/></linearGradient></defs>'''
 (ROOT/f'{k}_{t}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="160" viewBox="0 0 128 160">{defs}<g stroke="#0a1521" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round">{parts}</g></svg>')
if __name__=='__main__':
 for k,c in KINDS.items():
  for t in range(4):make(k,t,c)
 print('Original shaded building forms:',len(list(ROOT.glob('*.svg'))))
