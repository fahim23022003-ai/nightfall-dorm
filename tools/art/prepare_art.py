"""Reproducible atlas extraction and original environment texture construction.
The illustrated source atlas was generated specifically for this project.
Pillow is a development-only dependency; exported games load the resulting PNGs.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, shutil

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'assets/art'
ART.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / 'assets/art/source_atlas.png'
names = [
 ['bed','bed_upgraded','cabinet','plant','lantern','door'],
 ['survivor_idle','survivor_walk_a','survivor_walk_b','survivor_sleep','bot_idle','bot_walk'],
 ['hunter_idle','hunter_move','hunter_attack','hunter_hurt','hunter_death','door_reinforced'],
 ['turret','heavy','generator','repair','economy','enhancer']]
atlas = Image.open(SOURCE).convert('RGBA')
assert atlas.size == (1536,1024), 'Atlas layout must remain six by four 256px cells'
for row, cells in enumerate(names):
 for col,name in enumerate(cells):
  cell=atlas.crop((col*256,row*256,(col+1)*256,(row+1)*256))
  alpha=cell.getchannel('A')
  bbox=alpha.point(lambda x:255 if x>90 else 0).getbbox()
  if bbox:
   bbox=(max(0,bbox[0]-4),max(0,bbox[1]-4),min(256,bbox[2]+4),min(256,bbox[3]+4))
   cell=cell.crop(bbox)
  cell.save(ART/(name+'.png'))

rng=random.Random(417)
# Warm staggered timber with end joints, bevels, grain and nail details.
im=Image.new('RGBA',(540,440),(39,35,42,255));d=ImageDraw.Draw(im)
for y in range(0,440,28):
 for x in range(-90 if (y//28)%2 else 0,540,108):
  shade=rng.randrange(-8,9)
  c=(94+shade,75+shade,68+shade)
  d.rectangle((x+1,y+1,x+106,y+26),fill=c)
  d.line((x+2,y+2,x+105,y+2),fill=(131+shade,105+shade,85+shade),width=1)
  d.line((x+2,y+25,x+105,y+25),fill=(52,43,46),width=1)
  for n in range(4):
   yy=y+rng.randrange(6,24)
   xx=x+rng.randrange(6,40)
   d.line((xx,yy,xx+rng.randrange(30,65),yy+rng.choice([-1,0,1])),fill=(76+shade,59+shade,56+shade))
  d.point((x+6,y+7),fill=(42,36,40));d.point((x+101,y+21),fill=(42,36,40))
im.save(ART/'floor_wood.png')
# Tiled corridor: moss/cream ceramic inlay, distressed edges and central runner.
im=Image.new('RGBA',(900,160),(31,41,48,255));d=ImageDraw.Draw(im)
for y in range(0,160,32):
 for x in range(0,900,32):
  col=(70,85,86) if (x//32+y//32)%2 else (112,116,103)
  d.rectangle((x+1,y+1,x+30,y+30),fill=col)
  d.line((x+2,y+2,x+29,y+2),fill=tuple(min(255,n+14) for n in col))
  for _ in range(3):
   xx=x+rng.randrange(3,29);yy=y+rng.randrange(3,29)
   d.point((xx,yy),fill=tuple(max(0,n-15) for n in col))
d.rectangle((12,52,888,108),fill=(53,51,70),outline=(148,121,91),width=3)
d.rectangle((17,57,883,103),outline=(86,79,88),width=1)
for x in range(30,880,26):
 d.polygon([(x,80),(x+5,75),(x+10,80),(x+5,85)],fill=(118,100,95))
im.save(ART/'corridor.png')

def icon(name,kind):
 im=Image.new('RGBA',(96,96));d=ImageDraw.Draw(im)
 if kind=='coin':
  d.ellipse((14,18,82,86),fill='#543849');d.ellipse((13,10,81,78),fill='#a96c37',outline='#2c2638',width=4)
  d.ellipse((19,13,77,69),fill='#f4c87d',outline='#ffe8ac',width=3)
  d.ellipse((28,21,68,61),outline='#be8648',width=3)
  d.polygon([(50,28),(40,43),(49,43),(43,55),(59,38),(49,38)],fill='#a56b38')
 elif kind=='power':
  d.polygon([(53,7),(19,55),(43,55),(35,88),(80,34),(54,34),(66,7)],fill='#183942',outline='#6fdacb',width=4)
  d.polygon([(53,12),(27,50),(49,50),(43,72),(70,39),(49,39),(59,12)],fill='#c5f6db')
 elif kind=='pad':
  d.ellipse((7,16,89,86),fill=(30,39,44,95),outline=(187,165,121,100),width=2)
  d.ellipse((17,23,79,79),outline=(208,185,134,100),width=2)
  for x,y in [(48,18),(84,52),(48,84),(12,52)]:
   d.polygon([(x,y-4),(x+4,y),(x,y+4),(x-4,y)],fill=(210,189,142,150))
  d.line((39,52,57,52),fill=(210,189,142,130),width=2);d.line((48,43,48,61),fill=(210,189,142,130),width=2)
 im.save(ART/(name+'.png'))
icon('coin','coin');icon('power','power');icon('foundation','pad')
# Architectural wall fixture: moonlit casement window, original raster detailing.
im=Image.new('RGBA',(144,100));d=ImageDraw.Draw(im)
d.rounded_rectangle((3,3,141,98),9,fill='#171d32',outline='#c3a271',width=4)
d.rectangle((12,11,132,82),fill='#27374d',outline='#66536a',width=3)
d.ellipse((95,17,116,38),fill='#e8deb2');d.ellipse((88,12,108,33),fill='#27374d')
for x,y in [(26,26),(75,20),(115,53),(58,58)]:d.ellipse((x,y,x+2,y+2),fill='#cabed2')
d.rectangle((68,12,75,82),fill='#b39477');d.rectangle((12,46,132,51),fill='#b39477')
d.rectangle((0,82,144,96),fill='#54465c');d.line((3,83,140,83),fill='#cfb08a',width=3)
im.save(ART/'window.png')
# Contact shadows/glows are transparent art layers, separate from game logic.
im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im)
d.ellipse((8,38,120,110),fill=(5,9,23,150))
im.filter(ImageFilter.GaussianBlur(10)).save(ART/'shadow.png')
im=Image.new('RGBA',(192,192));d=ImageDraw.Draw(im)
for r in range(95,0,-1):
 a=int((1-r/96)**2*60)
 d.ellipse((96-r,96-r,96+r,96+r),fill=(255,203,128,a))
im.save(ART/'warm_glow.png')
im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
d.rounded_rectangle((4,4,252,252),42,fill='#172b3a',outline='#dfbf86',width=7)
bed=Image.open(ART/'bed_upgraded.png');bed.thumbnail((142,195))
im.alpha_composite(bed,(41,49))
ghost=Image.open(ART/'hunter_idle.png');ghost.thumbnail((124,135))
im.alpha_composite(ghost,(123,9))
im.save(ART/'app_icon.png')
im.save(ART/'app_icon.ico',sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
print('Prepared',len(list(ART.glob('*.png'))),'original art textures')
