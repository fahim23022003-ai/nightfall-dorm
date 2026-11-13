"""Original curved, shaded multi-part nightmare anatomy. No external art.
Seven independently articulated layers, six identities, four silhouette mutations.
SVG gradients are baked by Godot import; no runtime lights or image dependencies.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/'assets/nightmare'
COLORS={'crusher':('#8f8e7e','#272d32','#ffb174'),'stalker':('#837c92','#191924','#d8b7ff'),'ravager':('#9e6462','#2b2228','#ff856d'),'witch':('#897b9c','#211b32','#d6a4ff'),'electric':('#6ba8b6','#162c3d','#8cffff'),'storm':('#788ca3','#1c293d','#c8e9ff')}
def path(d,fill='url(#skin)',extra=''):return f'<path d="{d}" fill="{fill}" {extra}/>'
def ellipse(x,y,rx,ry,fill):return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}"/>'
def line(d,col='#b5b3a7',width=1,alpha=.7):return path(d,'none',f'stroke="{col}" stroke-width="{width}" opacity="{alpha}"')
def wrap(parts,main,dark,eye):
 return f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="160" viewBox="0 0 128 160"><defs>
 <radialGradient id="skin" cx=".32" cy=".24" r=".85"><stop stop-color="{main}"/><stop offset=".52" stop-color="{dark}"/><stop offset="1" stop-color="#080e18"/></radialGradient>
 <linearGradient id="bone" x1="0" x2="1" y2=".7"><stop stop-color="#d1c5a3"/><stop offset=".3" stop-color="#8a897e"/><stop offset=".65" stop-color="#3f484a"/><stop offset="1" stop-color="#18212c"/></linearGradient>
 <linearGradient id="cloth" x1="0" x2="1" y2=".3"><stop stop-color="#10121e"/><stop offset=".35" stop-color="{main}"/><stop offset=".58" stop-color="{dark}"/><stop offset="1" stop-color="#090e18"/></linearGradient>
 <radialGradient id="glow"><stop stop-color="#eefeff"/><stop offset=".3" stop-color="{eye}"/><stop offset="1" stop-color="{eye}" stop-opacity="0"/></radialGradient>
 </defs><g stroke="#0a101a" stroke-width="1.25" stroke-linejoin="round" stroke-linecap="round">{parts}</g></svg>'''
def glow(x,y,r):return ellipse(x,y,r,r,'url(#glow)')
def make(k,t):
 main,dark,eye=COLORS[k];parts={};bone='url(#bone)';cloth='url(#cloth)'
 if k=='crusher':
  body=path(f'M37 65 C12 {66-t*3} 14 99 32 112 Q64 {137+t*3} 96 112 C114 95 113 {59-t*3} 85 62 Q67 48 37 65Z')
  body+=path('M34 71 Q19 81 34 98 L59 101 55 74Z',bone)+path('M65 74 Q91 62 98 81 L91 101 67 98Z',bone)
  body+=ellipse(65,108,24,12,cloth)
  for n in range(2+t):body+=path(f'M{40-n*3} {65-n*5} Q{17-n*2} {53-n*5} {12-n*2} {35-n*4} Q{37-n*2} {48-n*3} {48-n*2} {67-n*4}Z',bone)
  if t>=2:body+=path('M71 62 C72 37 100 35 114 52 L104 74 86 86Z',bone)+line('M79 61 Q94 45 105 53',eye,2)
  if t==3:body+=path('M40 92 Q62 78 88 94 Q84 119 64 126 Q43 116 40 92Z','#161b24')+path('M45 96 Q64 109 84 96 L78 112 50 111Z',bone)+glow(64,101,15)
 elif k=='stalker':
  body=path(f'M53 56 Q64 48 76 57 C{93+t*2} 75 74 96 80 120 L67 143 55 124 C59 101 {35-t*2} 80 53 56Z',cloth)
  body+=path('M58 60 Q64 56 72 62 L73 103 66 119 58 103Z',bone)
  for n in range(4+t):body+=line(f'M56 {70+n*5} Q66 {78+n*5} 77 {68+n*5}',main,2.5)
  for i in range(t):body+=path(f'M{43-i*5} 68 C{10-i*2} 85 {58-i*3} 108 {19-i*3} {140-i*4} Q{54-i*4} 122 {38-i*3} 98 Q{20-i*2} 84 {43-i*5} 68Z',cloth)
  if t==3:body+=path('M76 58 C122 42 123 98 91 119 Q111 87 91 79 L77 86Z',cloth)+glow(88,79,10)
 elif k=='ravager':
  body=path(f'M{29-t*3} 77 Q30 54 61 64 Q91 44 {102+t*2} 80 Q111 111 75 122 L43 115Z')
  body+=path('M30 79 Q45 63 59 77 L55 102 40 112Z',cloth)+path('M69 79 Q89 60 99 80 L93 106 70 114Z',cloth)
  for n in range(3+t):body+=path(f'M{39+n*8} 67 Q{38+n*8} {48-t*6} {44+n*8} {39-t*3} L{48+n*8} 67Z',bone)
  if t>=2:body+=path('M20 78 Q5 64 13 43 Q25 51 37 67 L40 90Z')
  if t==3:body+=path('M77 70 Q112 44 120 59 L112 98 88 108Z')+line('M84 86 Q105 66 114 68',eye,3)
 elif k=='witch':
  body=path(f'M50 57 Q64 48 79 58 C91 77 78 90 {110+t*4} 133 Q89 124 78 143 L64 125 44 146 Q36 125 {17-t*3} 133 C40 99 35 75 50 57Z',cloth)
  body+=path('M53 62 Q64 70 76 62 L72 88 64 100 56 87Z',bone)
  for n in range(3+t):body+=line(f'M{47+n*7} 90 Q{34+n*9} 114 {31+n*13} 133',main,1.5,.55)
  if t>=1:body+=path('M45 67 C13 71 38 101 9 120 Q39 116 39 94 Q26 76 49 76Z',cloth)
  if t>=2:body+=path('M84 67 C116 59 97 106 122 118 Q94 121 91 92 Q104 73 79 77Z',cloth)
  if t==3:body+=path('M35 73 Q8 48 7 74 L20 89 9 99 30 100Z',bone)+path('M91 72 Q122 46 121 73 L109 88 119 99 96 100Z',bone)
 elif k=='electric':
  body=path('M47 59 Q28 65 32 84 L44 94 39 116 61 126 85 118 92 92 102 76 Q95 57 77 57Z',bone)
  body+=path('M61 63 L74 60 68 79 80 85 66 98 73 120 55 111 62 91 50 82Z','#081a2c')+line('M65 65 L60 80 71 84 60 96 67 113',eye,3)
  for n in range(t):body+=path(f'M{28-n*4} {68+n*10} Q{13-n*3} {59+n*10} {18-n*3} {78+n*10} L{32-n*3} {86+n*10}Z',bone)
  if t>=2:body+=path('M82 60 Q112 47 121 71 L109 85 120 100 96 111 91 95Z',bone)+line('M93 65 L107 74 99 85 111 95',eye,3)
  if t==3:body+=glow(64,87,25)+path('M64 69 L75 86 66 105 53 87Z',eye)
 else:
  body=path('M45 61 Q12 56 22 82 C8 101 42 109 30 130 Q62 145 100 128 C85 103 123 91 107 71 Q94 52 77 61Z',cloth)
  for n in range(3+t):
   y=76+n*8;body+=path(f'M{27-n} {y} C45 {y-16} 88 {y+16} {107+n} {y-6} C102 {y+15} 51 {y-3} {27-n} {y+8}Z',bone if n==t else cloth)
  body+=glow(65,91,19+t*3)
  if t==3:body+=path('M20 67 Q2 56 11 40 L32 53 42 45 40 72 M96 60 Q116 36 126 51 L116 75 103 84Z',bone)
 parts['body']=body
 # Faces: organic skulls, membranes and jaws with a clearly separate final anatomy.
 head=path('M43 31 C43 10 85 10 87 34 L84 54 Q63 78 45 54Z',bone)
 if k=='crusher':
  head+=path('M43 28 Q65 12 86 30 L83 46 72 52 52 48Z',bone)+path('M49 49 Q64 57 80 47 L77 65 Q63 75 50 63Z',cloth)
  for n in range(4+t):head+=path(f'M{49+n*5} 52 L{52+n*5} 65 {55+n*5} 51Z',bone)
  for side in [-1,1]:head+=path(f'M{64+side*18} 31 Q{64+side*(35+t*3)} {14-t*3} {64+side*(28+t*4)} {3+t} Q{64+side*29} 30 {64+side*22} 43Z',bone)
 elif k=='stalker':
  head=path(f'M54 {20-t*3} C63 {8-t*2} 78 19 78 34 L75 {63+t*3} Q66 {85+t*3} 54 64 L48 34Z',bone)+path('M61 44 Q70 37 70 50 L65 69 60 59Z','#11101b')
  if t>=2:head+=path('M49 31 C21 19 19 49 31 66 Q23 43 45 45 M78 30 C102 18 113 45 96 69 Q106 42 80 43',cloth)
  if t==3:head+=path('M51 65 Q38 97 49 100 L62 72 68 82 77 66',bone)
 elif k=='ravager':
  head=path('M35 33 Q41 10 63 25 Q90 12 95 39 L88 60 Q63 84 38 59Z')+path(f'M37 45 Q66 34 91 44 L{86+t*2} {65+t*3} Q64 {84+t*3} 39 62Z','#150f17')
  for n in range(6):head+=path(f'M{39+n*9} 45 L{42+n*9} {58+(n%2)*6+t} {47+n*9} 44Z',bone)
  for side in [-1,1]:head+=path(f'M{64+side*19} 29 Q{64+side*43} {12-t*2} {64+side*36} 3 L{64+side*29} 49Z',cloth)
  if t==3:head+=path('M40 60 Q34 83 57 88 L79 77 89 59 Q71 76 62 74Z',bone)
 elif k=='witch':
  head=path('M41 35 Q39 9 63 10 Q86 7 90 34 L84 59 64 74 45 58Z',cloth)+path('M53 32 Q64 25 76 32 L74 56 65 64 54 54Z',bone)
  head+=path(f'M{21-t*4} 36 Q43 28 56 {5-t} Q66 {18-t*2} 77 9 L84 29 Q103 32 {110+t*5} 45 Q78 36 61 41 Q38 47 {21-t*4} 36Z',cloth)
  for i in range(t+1):head+=path(f'M{43-i*7} 41 C{21-i*5} 62 {50-i*7} 75 {30-i*6} 91 Q{52-i*5} 86 {45-i*6} 62Z',cloth)
  if t==3:head+=path('M50 25 Q61 17 79 26 L77 34 67 28 57 35Z',bone)+glow(65,43,13)
 elif k=='electric':
  head=path('M43 30 Q59 12 79 21 L88 44 77 66 64 72 45 53Z',bone)+path('M64 18 L58 35 69 43 59 61 66 72 75 52 67 41 77 26Z','#102435')+line('M65 22 L62 35 73 43 62 60',eye,3)
  for side in [-1,1]:head+=path(f'M{64+side*18} 34 Q{64+side*(37+t*2)} 11 {64+side*(30+t*4)} 4 Q{64+side*21} 17 {64+side*26} 39Z',bone)
  if t==3:head+=path('M42 40 Q26 28 26 48 L40 65 M85 42 Q102 30 102 49 L85 68',bone)+glow(65,40,13)
 else:
  head=path('M39 33 Q40 11 63 17 Q87 6 92 35 L99 58 77 74 62 64 43 76 29 56Z',cloth)+path('M47 31 Q64 20 83 33 L78 55 64 66 47 53Z','#111e2d')
  for i in range(3+t):head+=ellipse(26+i*(76/(2+t)),28+(i%2)*-9,12+t,9+t,cloth)
  head+=path('M70 17 L54 36 68 39 58 57 81 34 69 33Z',eye)
  if t==3:head+=path('M33 36 Q19 6 37 7 L53 22 M83 22 Q107 0 114 18 L94 41',bone)
 for x in [53,74]:head+=glow(x,41,9)+ellipse(x,41,4,1.8,eye)+ellipse(x-1,40.6,1.4,.8,'#f4ffff')
 # Creases catch side-light rather than outlining every polygon.
 head+=line('M46 30 Q54 23 59 26 M72 27 Q80 25 84 33',main,1.2,.8)
 # Major mutations change anatomy, not just trim or aura color.
 if t>=1:
  if k=='crusher':head+=path('M41 49 Q64 68 87 48 L84 68 Q62 89 42 66Z',bone)+path('M49 62 L55 75 61 64 67 78 74 63 79 69Z','#141b24')
  elif k=='stalker':head+=path('M53 54 Q62 61 75 51 L72 79 Q63 96 53 77Z',bone)+line('M61 65 L63 84',dark,3)
  elif k=='ravager':head+=path('M36 48 Q47 35 64 44 L84 44 Q98 58 81 74 L47 72 34 61Z')+path('M39 55 Q62 69 86 53 L79 75 48 75Z','#120e17')
  elif k=='witch':head+=path('M46 37 Q35 62 47 82 L55 71 52 49 M80 34 Q100 55 85 83 L75 66 77 48Z',cloth)
  elif k=='electric':head+=path('M43 46 L53 52 48 69 37 60 M78 51 L89 39 96 56 83 70Z',bone)+line('M48 52 L42 60 M82 55 L91 49',eye,2)
  else:head+=path('M33 51 C13 39 10 64 29 75 Q10 87 32 91 L48 64 M91 46 C119 31 128 62 106 71 Q127 89 104 94 L82 66Z',cloth)
 if t>=2:
  if k=='crusher':head+=path('M44 61 Q22 63 31 87 Q35 78 42 81 L52 76 M82 59 Q106 59 97 88 Q93 78 86 81 L76 73Z',bone)
  elif k=='stalker':head+=path('M51 49 C19 42 18 74 29 89 Q21 66 44 65 L54 75 M78 47 C108 39 113 71 100 89 Q110 65 87 64 L76 75Z',cloth)
  elif k=='ravager':
   head+=path('M35 47 Q64 34 91 47 L96 67 Q65 94 34 71Z')+path('M39 58 Q65 48 91 55 Q91 81 62 88 Q35 78 39 58Z','#150f17')
   for n in range(7):head+=path(f'M{40+n*7} 57 L{43+n*7} {71+(n%2)*7} {47+n*7} 55Z',bone)
  elif k=='witch':head+=path('M38 35 Q17 17 28 5 L51 23 64 7 79 23 Q97 2 108 13 L89 41Z',cloth)+ellipse(64,24,6,3,eye)
  elif k=='electric':head+=path('M46 30 Q32 22 37 8 L53 17 57 36 M79 28 Q93 10 103 18 L93 42Z',bone)
  else:head+=path('M36 36 Q24 12 42 3 L55 21 66 5 82 22 Q107 6 116 25 L95 50Z',cloth)
 if t==3:
  if k=='crusher':head+=path('M35 22 Q63 4 93 22 L91 39 79 29 70 39 56 29 42 43Z',bone)+line('M43 25 Q64 14 85 25',eye,2)
  elif k=='stalker':head+=path('M53 75 C28 80 35 104 21 111 Q45 112 51 92 L64 105 77 84 Q91 108 110 101 Q92 94 85 75 L73 77 65 88Z',cloth)
  elif k=='ravager':head+=path('M37 66 Q23 79 34 94 L48 88 63 103 85 89 99 65 Q91 88 66 91 Q42 84 37 66Z',bone)
  elif k=='witch':head+=path('M34 25 Q9 31 18 56 Q31 42 42 49 L50 36 M89 29 Q119 21 119 53 L104 45 84 48Z',bone)+ellipse(52,51,5,2,eye)+ellipse(75,51,5,2,eye)
  elif k=='electric':head+=path('M48 29 L59 25 54 42 61 49 53 68 42 55 M72 25 L84 29 92 52 77 69 73 54 81 44Z',bone)+path('M61 27 L68 30 64 44 73 50 63 69 58 58 64 49 56 41Z',eye)
  else:head+=path('M42 38 Q63 14 87 37 L83 59 63 81 40 62Z','#102132')+path('M48 45 Q69 26 81 45 Q77 68 59 67 Q45 57 57 49 Q67 43 72 52 Q64 47 61 57 L68 58','none',f'stroke="{eye}" stroke-width="3"')
 parts['head']=head
 parts['back']=path('M43 30 Q63 9 85 30 L85 53 65 70 44 52Z',cloth)+line('M61 23 Q54 43 63 64 M68 24 Q79 45 68 61',main,2)
 if k=='witch':parts['back']+=path('M18 36 Q44 27 58 3 L79 28 111 44 63 38Z',cloth)
 # Asymmetric heavy elbow/forearm anatomy; floating roles have articulated talons.
 arm=path(f'M31 61 C{11-t} 59 {10-t} 80 19 89 Q7 113 28 122 Q48 125 48 103 L40 85 Q47 69 31 61Z')
 arm+=path('M22 66 Q31 61 38 70 L37 83 23 87Z',bone)+path('M19 93 Q36 84 43 102 L40 114 22 119Z',bone)
 if k in ['stalker','witch','storm']:
  arm=path(f'M31 63 C13 65 19 79 28 88 L{19-t*2} 111 29 118 39 104 37 82 Q46 70 31 63Z',cloth)+path('M25 98 Q42 93 40 110 L28 124 20 113Z',bone)
 for n in range(3 if k!='crusher' else 4):arm+=path(f'M{20+n*6} 109 Q{14+n*6} {128+t*3} {9+n*7} {131+t*3} L{23+n*6} 116Z',bone)
 if t>=2:arm+=path('M17 79 Q4 64 9 51 Q24 66 29 79Z',bone)
 if t==3:arm+=glow(30,95,12)+line('M19 88 Q33 82 41 95',eye,2)
 if k=='ravager':
  arm=path('M33 63 C14 59 9 76 19 89 Q14 104 7 119 L17 127 Q35 113 37 95 C54 82 49 66 33 63Z')+line('M26 69 Q15 78 28 89 L21 109',main,2)
  for n in range(4):arm+=path(f'M{11+n*5} 116 Q{7+n*6} {138+t*4} {1+n*7} {145+t*3} Q{19+n*4} 139 {23+n*4} 118Z',bone)
  if t>=2:arm+=path('M15 82 Q-1 72 7 55 L22 67Z',cloth)
  if t==3:arm+=line('M22 78 Q31 90 18 114',eye,2)
 elif k=='electric':
  arm=path('M24 62 L40 66 43 79 29 85 19 76Z',bone)+path('M24 96 L40 92 47 106 35 117 22 111Z',bone)+line('M30 81 L36 88 29 98',eye,2)+path('M24 115 L17 134 29 125 33 139 39 120Z',bone)
  if t>=2:arm+=path('M13 78 L6 87 15 101 21 89Z',bone)
  if t==3:arm+=glow(33,88,11)
 parts['arm']=arm
 leg=path('M44 105 Q62 101 64 116 L57 135 62 146 Q49 157 30 148 L38 136 Q33 117 44 105Z')+path('M37 139 Q48 133 58 140 L65 150 32 153Z',bone)+line('M43 114 Q51 108 57 116 L50 135',main,2)
 if k in ['witch','storm','electric','stalker']:leg=path('M44 106 Q30 121 42 137 Q38 147 26 153 Q52 153 56 136 Q70 125 61 107Z',cloth)+line('M47 112 Q40 127 49 139',eye,1.3,.5)
 if k=='ravager':leg=path('M44 105 Q64 101 65 118 L48 130 53 141 65 146 62 153 32 153 30 146 40 139 34 126Z')+path('M31 145 L46 145 54 151 61 151 65 157 37 156 27 153Z',bone)+line('M44 112 Q55 109 56 119 L42 129',main,2)
 elif k=='electric':leg=path('M43 109 L60 109 66 121 52 132 37 124Z',bone)+path('M40 141 L55 137 63 149 43 154 34 149Z',bone)+line('M49 129 L54 135 45 141',eye,2)
 parts['leg']=leg
 clothpiece=path('M44 58 Q64 48 84 58 C87 90 100 114 112 136 L88 128 82 151 66 134 52 155 43 132 18 140 Q38 112 44 58Z',cloth)
 for n in range(3+t):clothpiece+=line(f'M{42+n*7} 78 Q{37+n*8} 113 {27+n*14} 139',main,1.1,.4)
 if t>=2:clothpiece+=path('M38 77 Q3 89 20 112 Q35 126 11 147 Q43 137 32 112 Q16 92 41 88 M88 73 Q124 83 106 112 Q98 132 121 146 Q87 136 97 109 Q113 89 85 87Z',cloth)
 if t==3:
  if k in ['stalker','witch']:
   clothpiece+=path('M43 60 C8 43 3 67 11 85 Q16 63 33 78 L9 105 Q22 130 5 149 Q36 142 33 111 L45 93 M84 60 C119 39 126 69 117 87 Q109 64 95 80 L119 105 Q104 129 123 149 Q92 140 96 112 L81 91Z',cloth)
  elif k=='storm':clothpiece+=path('M33 67 Q1 39 3 77 L18 98 Q1 122 24 143 L42 116 M92 66 Q127 37 125 78 L109 101 Q126 127 104 144 L84 117Z',cloth)
 if k=='ravager':clothpiece=path('M43 67 Q23 63 19 84 L28 90 14 107 34 99 28 115 44 104 58 120 74 104 91 113 86 97 111 106 98 85 106 77 81 64Z',cloth)
 elif k=='electric':
  clothpiece=path('M42 65 L25 69 20 90 35 84 41 102 49 87 M83 64 L103 70 108 90 92 84 83 103 79 86Z',bone)
  if t>=2:clothpiece+=path('M20 107 L9 116 19 130 32 118 M106 107 L119 117 109 134 96 119Z',bone)
 parts['cloth']=clothpiece
 weapon={
 'crusher':path('M96 72 Q89 112 94 143 L101 142 104 73Z',bone)+path(f'M83 65 Q{69-t*4} 71 {77-t*3} 91 L90 105 116 96 Q127 77 113 63Z',bone)+line('M82 74 L107 70 116 84',main,3),
 'stalker':path('M101 65 Q93 91 101 115','none','stroke="#7e788b" stroke-width="4"')+path('M87 111 Q100 101 115 113 L117 137 Q101 153 84 135Z',bone)+glow(100,126,14),
 'ravager':path('M91 83 Q112 77 123 89 L104 99 123 104 103 114 107 130 Q89 119 87 101Z',bone),
 'witch':path('M102 40 Q94 82 102 147','none','stroke="#68677f" stroke-width="5"')+path('M99 21 Q76 27 86 49 Q104 65 118 43 Q128 20 106 15 Q115 29 105 35 Q93 38 99 21Z',bone)+glow(102,39,17),
 'electric':path('M99 40 Q75 58 91 79 L85 108 108 88 100 73 120 49 Q109 55 99 40Z',bone)+line('M101 51 L91 66 104 77 94 94',eye,4),
 'storm':path('M100 51 Q87 102 100 144','none','stroke="#788da5" stroke-width="5"')+path('M86 29 Q108 12 124 35 L110 53 Q99 40 81 52Z',bone)+glow(104,37,17)}[k]
 if t>=1:weapon+=path('M89 92 Q99 83 111 94 L108 108 92 108Z',bone)
 if t>=2 and k=='crusher':weapon+=path('M82 67 Q56 66 62 90 L83 106Z',bone)
 if t==3:
  if k=='stalker':weapon+=path('M87 111 Q64 96 73 79 Q64 113 91 139 M113 111 Q129 97 121 80 L124 132Z',cloth)
  elif k=='ravager':weapon+=path('M94 81 Q122 66 127 84 L111 98 126 110 105 122Z',bone)
  elif k=='witch':weapon+=path('M86 24 Q65 8 72 36 L85 52 M114 23 Q128 8 126 35 L115 53',bone)
  elif k=='electric':weapon+=line('M87 47 L75 66 86 78 75 105 M113 47 L125 66 115 85 124 110',eye,3)
  elif k=='storm':weapon+=path('M85 31 Q67 21 72 47 L87 64 M118 27 Q127 26 125 53 L111 65Z',cloth)
  weapon+=glow(101,74,12)
 parts['weapon']=weapon
 for name,data in parts.items():(ROOT/f'{k}_{t}_{name}.svg').write_text(wrap(data,main,dark,eye))
if __name__=='__main__':
 for kind in COLORS:
  for tier in range(4):make(kind,tier)
 print('Authored shaded rig layers:',len(list(ROOT.glob('*.svg'))))
