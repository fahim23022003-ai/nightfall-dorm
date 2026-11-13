"""Original modular cartoon horror anatomy, six identities x four silhouettes.
Parts share pivots and are animated independently by NightmarePresentation.
No external artwork or runtime generator dependency.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/nightmare'
COLORS={'crusher':('#97866d','#493f3c','#ffc682'),'stalker':('#78668c','#282336','#e2a4ff'),'ravager':('#94515b','#35232e','#ff9f90'),'witch':('#8964a2','#2e2448','#d1abff'),'electric':('#54899c','#233e56','#8cffff'),'storm':('#6c7895','#292e48','#ffe4a2')}
def path(d,fill,extra=''):return f'<path d="{d}" fill="{fill}" {extra}/>'
def circle(x,y,r,fill):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}"/>'
def wrap(parts,main,dark,eye):
 return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="160" viewBox="0 0 128 160"><defs><linearGradient id="skin" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{main}"/><stop offset="1" stop-color="{dark}"/></linearGradient><linearGradient id="metal" x2=".8" y2="1"><stop stop-color="#bdc3bf"/><stop offset=".4" stop-color="{main}"/><stop offset="1" stop-color="#293240"/></linearGradient></defs><g stroke="#101621" stroke-width="2.4" stroke-linejoin="round">{parts}</g></svg>'''
def make(kind,tier):
 main,dark,eye=COLORS[kind];g='url(#skin)';m='url(#metal)';parts={}
 bodies={
 'crusher':'M35 66 Q18 72 27 95 L43 118 88 118 103 86 Q107 61 85 62 L75 54 48 55Z',
 'stalker':'M52 58 Q38 73 45 96 L38 131 64 118 91 132 80 92 78 58Z',
 'ravager':'M39 72 L43 59 65 64 87 54 98 81 85 113 41 114 28 94Z',
 'witch':'M50 55 L34 69 42 97 20 130 Q64 116 108 130 L84 94 93 69 77 55Z',
 'electric':'M46 59 L30 77 42 92 38 111 64 121 92 110 86 91 98 76 80 58Z',
 'storm':'M40 64 Q17 58 23 82 L38 95 29 120 62 133 97 119 91 96 Q116 72 91 62 L72 55Z'}
 body=path(bodies[kind],g)
 for n in range(2+tier):
  y=75+n*9;body+=path(f'M43 {y} Q64 {y+12} 86 {y} L83 {y+7} Q64 {y+17} 46 {y+7}Z',m if kind in ['crusher','electric'] else dark)
 body+=path('M60 75 L69 75 75 88 64 101 53 88Z',eye)
 if kind in ['electric','storm']:body+=path('M42 69 L56 77 49 84 66 91 62 110 M87 69 L72 80 81 86 69 100','none',f'stroke="{eye}" stroke-width="3"')
 if tier>=1 and kind in ["crusher","ravager","electric"]:
  for side in [-1,1]:
   x=64+side*34;body+=path(f'M{x} 63 L{x+side*13} 40 {x-side*3} 69 {x+side*7} 84 {x-side*9} 79Z',m)
 if tier>=2 and kind in ["crusher","ravager"]:
  for side in [-1,1]:
   x=64+side*31;body+=path(f'M{x} 72 L{x+side*24} 48 {x+side*17} 78 {x+side*26} 96 {x-side*1} 88Z',g)
 if tier==3 and kind in ["crusher","ravager"]:
  for side in [-1,1]:
   x=64+side*33;body+=path(f'M{x} 79 L{x+side*25} 61 {x+side*25} 90 {x+side*10} 109 {x-side*7} 96Z',m)
  body+=path('M52 99 L64 108 77 98 81 115 64 130 46 115Z',eye)
 if kind in ['witch','stalker','storm']:
  for n in range(tier+1):
   x=28-n*3;body+=path(f'M{x} 70 Q{5+n*2} 93 {15+n*2} 126 L{26+n*3} 109 Q{15+n*2} 90 {x+7} 79Z',main)
   body+=path(f'M{128-x} 70 Q{123-n*2} 93 {113-n*2} 126 L{102-n*3} 109 Q{113-n*2} 90 {121-x} 79Z',main)
 parts['body']=body
 head=path('M43 30 Q64 14 85 30 L86 53 73 69 53 66 40 49Z',g)
 if kind=='crusher':head+=path('M41 33 L53 24 77 24 87 34 82 51 46 52Z',m)+path('M49 53 L55 66 60 54 67 66 73 52 79 60 81 47',dark)
 if kind=='stalker':head=path('M55 17 Q73 12 81 29 L79 61 64 76 50 59 45 34Z',g)+path('M57 45 L69 42 74 59 62 68Z',dark)
 if kind=='ravager':head=path('M37 24 L47 33 59 25 84 21 90 43 82 60 60 72 37 53 28 35Z',g)+path('M36 49 L80 44 75 66 65 54 59 68 53 56 45 66Z','#dac4b2')
 if kind=='witch':head+=path('M25 32 Q48 27 59 5 L69 14 80 9 87 28 104 39 60 33Z',g)+path('M47 36 L82 35 78 55 63 61 49 51Z',dark)
 if kind=='electric':head+=path('M41 29 L64 15 87 30 79 56 64 67 48 57Z',m)+path('M63 17 L58 33 70 40 61 55 66 68','none',f'stroke="{eye}" stroke-width="3"')
 if kind=='storm':head=path('M37 32 Q62 9 87 30 L96 60 80 74 63 65 45 76 32 59Z',g)+path('M47 35 Q65 25 82 36 L79 56 62 66 47 53Z',dark)
 for x in [52,73]:head+=path(f'M{x-6} 39 L{x+7} 37 {x+3} 44 {x-5} 44Z',eye)
 if kind=='crusher':
  for side in [-1,1]:head+=path(f'M{64+side*19} 32 L{64+side*33} {12-tier*3} {64+side*29} 37Z',m)
  if tier==3:head+=path('M44 28 L35 1 54 16 64 2 73 16 94 1 84 30Z',m)
 elif kind=='ravager':
  for side in [-1,1]:head+=path(f'M{64+side*18} 28 L{64+side*(32+tier*4)} {3+tier*2} {64+side*30} 49Z',g)
  for n in range(3+tier):head+=path(f'M{42+n*7} 53 L{47+n*7} {68+tier*3} {50+n*7} 51Z','#e7d0bb')
 elif kind=='witch':
  head+=path(f'M{19-tier*2} 31 Q45 19 61 1 L77 10 74 22 Q95 27 {110+tier*3} 41 L70 34 40 39Z',g)
  head+=path('M54 7 L68 9 72 15 58 16Z',eye)
  for n in range(tier+1):head+=circle(40+n*15,33+n%2*2,3,eye)
 elif kind=='stalker':
  head+=path(f'M50 24 L{41-tier*3} 2 61 18 71 8 82 23 77 40Z',dark)
  head+=path('M57 50 L64 70 71 48 68 61 61 66Z',eye)
  if tier>=2:head+=path('M47 34 Q20 47 28 72 L38 58 44 69 43 48 M81 33 Q112 48 101 72 L91 57 86 68 86 45',g)
 elif kind=='electric':
  for side in [-1,1]:head+=path(f'M{64+side*17} 31 L{64+side*22} 8 {64+side*(35+tier*2)} 3 {64+side*26} 18 {64+side*32} 33Z',eye)
  head+=path('M62 15 L56 33 68 43 60 61 70 51 64 36 71 25Z',eye)
 elif kind=='storm':
  for n in range(3+tier):head+=circle(28+n*(72/(2+tier)),27+(-8 if n%2 else 1),9+tier,main)
  head+=path('M71 10 L58 27 70 32 59 49 84 25 70 24Z',eye)
 parts['head']=head
 back=path('M43 30 Q64 14 85 30 L86 53 73 69 53 66 40 49Z',g)+path('M62 24 L62 61 72 54 M49 44 L77 44','none',f'stroke="{dark}" stroke-width="4"')
 if kind=='witch':back+=path('M19 31 Q45 19 61 1 L77 10 74 22 Q95 27 116 41 L70 34 40 39Z',g)
 elif kind=='stalker':back+=path('M47 30 L41 1 62 19 80 10 84 40Z',dark)
 elif kind=='ravager':back+=path('M42 32 L27 2 55 22 76 17 102 1 87 45Z',g)
 elif kind=='storm':
  for n in range(3+tier):back+=circle(28+n*(72/(2+tier)),27+(-8 if n%2 else 1),9+tier,main)
 elif kind=='electric':back+=path('M43 31 L31 3 46 14 52 35 M77 32 L95 3 86 21 85 37',eye)
 else:back+=path('M43 31 L31 3 49 17 64 2 79 16 98 3 85 33Z',m)
 parts['back']=back
 arm=path('M31 63 Q17 65 18 83 L20 106 31 118 46 105 40 86 43 69Z',g)
 if kind in ['crusher','electric']:arm+=path('M17 86 L37 82 47 94 44 113 24 119 14 105Z',m)
 else:arm+=path('M18 89 L36 92 40 110 31 122 25 111 20 123 15 108Z',m)
 for n in range(2+tier):arm+=path(f'M{19+n*6} 109 L{16+n*6} {128+tier*2} {25+n*6} 110Z',eye if tier==3 else '#c9c3b8')
 if tier>0:arm+=circle(29,82,6+tier,eye)
 if kind in ['witch','stalker','storm']:
  arm=path('M31 64 Q16 70 24 84 L28 101 12 120 27 113 29 128 35 111 43 118 39 97 39 74Z',g)
  if kind=='stalker':arm+=path('M29 95 L9 116 15 132 23 114 21 137 31 117 36 129 40 111Z',dark)
  else:
   arm+=circle(30,88,4+tier,eye)
   arm+=path('M24 106 L17 122 26 113 31 125 34 109Z',eye)
 parts['arm']=arm
 leg=path('M45 107 L62 111 58 133 58 146 39 149 36 140 44 129Z',g)+path('M36 138 L57 137 65 149 37 153 30 147Z',m)
 for n in range(tier+1):leg+=path(f'M41 {115+n*6} L59 {112+n*6} 57 {117+n*6} 41 {121+n*6}Z',m)
 if kind in ['witch','electric','storm','stalker']:
  leg=path('M44 107 Q32 126 40 137 L30 153 50 143 63 153 56 132 Q65 120 62 108Z',dark)
  leg+=path('M47 110 Q40 126 48 142 L54 135 51 120Z',main)
 parts['leg']=leg
 cloth=path('M44 59 Q63 48 84 60 L91 94 108 131 88 122 82 145 67 124 54 148 44 126 21 133 39 94Z',dark)
 for n in range(2+tier):
  x=38+n*11;cloth+=path(f'M{x} 86 Q{x-4} 110 {x-13} 138 L{x} 129 {x+5} 98Z',main)
 if tier>=2:cloth+=path('M24 81 L9 90 15 108 8 127 25 115 31 92 M101 81 L120 88 112 109 122 128 101 114 96 91',g)
 parts['cloth']=cloth
 weapons={
 'crusher':path('M93 74 L91 132 98 133 103 75Z',m)+path('M80 67 L111 64 119 83 112 99 83 96 76 80Z',m),
 'stalker':path('M100 58 L100 120 M88 111 L113 111 118 136 101 148 84 134Z',m)+circle(100,128,8,eye),
 'ravager':path('M93 83 L118 91 109 101 119 110 100 107 103 124 89 108Z',m),
 'witch':path('M100 36 L99 145', 'none','stroke="#a1a4b5" stroke-width="5"')+circle(100,39,15+tier*2,g)+path('M96 25 L108 39 98 53 90 40Z',eye),
 'electric':path('M100 49 L87 77 103 83 91 108 116 76 101 73 112 48Z',eye),
 'storm':path('M96 43 L96 142','none','stroke="#a3a6b7" stroke-width="5"')+path('M87 31 L113 27 103 44 117 49 92 79 99 54 83 49Z',eye)}
 weapon=weapons[kind]
 if tier>=1:weapon+=path('M86 102 L113 102 108 113 90 113Z',m)
 if tier>=2:weapon+=path('M86 59 L78 40 91 49 98 27 105 48 121 38 115 63Z',g)
 if tier==3:
  weapon+=circle(100,75,10,eye)
  if kind in ['crusher','ravager']:weapon+=path('M79 75 L67 67 76 86 81 104 M117 77 L127 68 119 94',m)
  elif kind=='witch':weapon+=path('M85 29 L69 19 78 40 70 54 87 47 M115 29 L127 19 121 42 127 54 113 48',g)
  elif kind=='electric':weapon+=path('M84 42 L75 63 88 67 77 91 M116 45 L127 65 116 72 125 98','none',f'stroke="{eye}" stroke-width="3"')
  elif kind=='stalker':weapon+=path('M100 37 L88 48 92 64 84 81 91 100','none',f'stroke="{eye}" stroke-width="3"')
 parts['weapon']=weapon
 for part,data in parts.items():(ROOT/f'{kind}_{tier}_{part}.svg').write_text(wrap(data,main,dark,eye))
for kind in COLORS:
 for tier in range(4):make(kind,tier)
print('Original rig parts generated:',len(list(ROOT.glob('*.svg'))))
