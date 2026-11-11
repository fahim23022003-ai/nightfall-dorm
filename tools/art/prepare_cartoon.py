"""Extract original cartoon atlases and deterministic room-specific surfaces.
Pillow is tooling only. Runtime uses committed local PNGs.
"""
from pathlib import Path
from PIL import Image,ImageDraw
import random
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'assets/cartoon';OUT.mkdir(parents=True,exist_ok=True)
LAYOUT_A=[
 ['bed_1','bed_2','bed_3','bed_4','bed_5','desk'],
 ['turret_1','heavy_1','generator','repair','economy','enhancer'],
 ['turret_2','turret_3','turret_4','heavy_2','heavy_3','heavy_4'],
 ['cabinet','bookshelf','plant','lamp','window','utility']]
LAYOUT_B=[
 ['player_down_0','player_down_1','player_down_2','player_down_3','player_up_0','player_up_1'],
 ['player_up_2','player_up_3','player_left_0','player_left_1','player_left_2','player_left_3'],
 ['player_right_0','player_right_1','player_right_2','player_right_3','player_sleep','player_eliminated'],
 ['bot_0','bot_1','bot_2','bot_3','bot_4','player_enter']]
LAYOUT_C=[
 ['hunter_idle','hunter_move','hunter_target','hunter_attack','hunter_hurt','hunter_death'],
 ['door_1','door_2','door_3','door_4','door_5','construction'],
 ['bot_sleep_0','bot_sleep_1','bot_sleep_2','bot_sleep_3','bot_sleep_4','projectile'],
 ['poster','old_poster','clothes','books','rug','pipes']]
for source,names in [('source_objects.png',LAYOUT_A),('source_students.png',LAYOUT_B),('source_hunter.png',LAYOUT_C)]:
 if not (OUT/source).exists(): continue
 atlas=Image.open(OUT/source).convert('RGBA')
 assert atlas.size==(1536,1024),atlas.size
 for row,line in enumerate(names):
  for col,name in enumerate(line):
   cell=atlas.crop((col*256,row*256,col*256+256,row*256+256))
   bounds=cell.getchannel('A').point(lambda x:255 if x>100 else 0).getbbox()
   if not bounds: raise ValueError(name+' has no illustrated content')
   crop=cell.crop(bounds)
   crop.thumbnail((228,228),Image.Resampling.LANCZOS)
   canvas=Image.new('RGBA',(256,256))
   canvas.alpha_composite(crop,((256-crop.width)//2,248-crop.height))
   canvas.save(OUT/(name+'.png'))

# Four cutout gait frames retain each bot's distinct head, outfit and expression.
for index in range(5):
 idle=Image.open(OUT/f'bot_{index}.png')
 split=207
 upper=idle.crop((0,0,256,split))
 left=idle.crop((0,split,128,256));right=idle.crop((128,split,256,256))
 for frame,step in enumerate([0,7,0,-7]):
  canvas=Image.new('RGBA',(256,256))
  canvas.alpha_composite(upper,(0,0 if frame%2==0 else -2))
  canvas.alpha_composite(left,(0,split+step))
  canvas.alpha_composite(right,(128,split-step))
  canvas.save(OUT/f'bot_{index}_walk_{frame}.png')

# Recognizable support-machine upgrade attachments; no stat changes here.
for kind in ['generator','repair','economy','enhancer']:
 base=Image.open(OUT/(kind+'.png')).convert('RGBA')
 base.save(OUT/(kind+'_1.png'))
 for level in range(2,5):
  im=base.copy();d=ImageDraw.Draw(im)
  accent={'generator':'#4DDDF3','repair':'#7BE3A1','economy':'#F4C542','enhancer':'#A88CEB'}[kind]
  d.rounded_rectangle((8,159,49,231),6,fill='#607D8B',outline='#263746',width=5)
  for y in range(171,219,14):d.rectangle((19,y,38,y+7),fill=accent)
  if level>=3:
   d.rounded_rectangle((208,159,249,231),6,fill='#607D8B',outline='#263746',width=5)
   for y in range(171,219,14):d.rectangle((219,y,238,y+7),fill=accent)
  if level>=4:
   d.rounded_rectangle((70,10,185,35),7,fill='#263746',outline='#9DAFB9',width=3)
   for x in range(83,177,23):d.ellipse((x,17,x+10,27),fill=accent)
  im.save(OUT/f'{kind}_{level}.png')

palette=[('#82929A','#A0AFB6'),('#D5C9AD','#E4D8BE'),('#65757F','#7B8B94'),('#A8BCBB','#C4D4CC'),('#7D8588','#969C9B'),('#82929A','#A7B4BA')]
rng=random.Random(310)
for index,(dark,light) in enumerate(palette):
 im=Image.new('RGBA',(540,440),dark);d=ImageDraw.Draw(im)
 for y in range(0,440,44):
  for x in range(0,540,54):
   fill=light if (x//54+y//44)%4==0 else dark
   d.rounded_rectangle((x+1,y+1,x+52,y+42),3,fill=fill,outline='#556B78',width=2)
   d.line((x+4,y+4,x+49,y+4),fill='#B6C3C5',width=1)
 if index==1:
  d.rounded_rectangle((15,120,142,400),14,fill='#D5AA87',outline='#9C8578',width=4)
 elif index==3:
  d.rounded_rectangle((10,165,145,408),16,fill='#C7ADC9',outline='#978AA9',width=4)
  for x in range(22,135,17):d.line((x,180,x,390),fill='#D8C3D8',width=3)
 elif index==4:
  for _ in range(12):
   x=rng.randrange(20,520);y=rng.randrange(20,420)
   d.line([(x,y),(x+6,y+4),(x+4,y+11),(x+11,y+18)],fill='#59686D',width=2)
 elif index==5:
  for x in range(18,540,96):
   for y in [10,425]:d.ellipse((x,y,x+5,y+5),fill='#526777')
 im.save(OUT/f'floor_{index}.png')
im=Image.new('RGBA',(900,160),'#263746');d=ImageDraw.Draw(im)
for y in range(0,160,32):
 for x in range(0,900,40):
  d.rounded_rectangle((x+1,y+1,x+38,y+30),3,fill='#304857' if (x//40+y//32)%2 else '#2B4050',outline='#213340',width=1)
for x in range(30,880,80):
 d.line((x,80,x+25,80),fill='#607D8B',width=3)
im.save(OUT/'corridor.png')
if not (OUT/'source_hunter.png').exists():
 for level in range(1,6):
  im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
  d.rounded_rectangle((22,24,234,241),16,fill='#263746',outline='#152535',width=7)
  d.rounded_rectangle((35,33,221,228),10,fill=['#758D99','#698FA4','#657C9A','#527D94','#626B9C'][level-1],outline='#BCD2D8',width=4)
  for y in [59,140]:d.rounded_rectangle((53,y,200,y+61),8,outline='#3A5364',width=5)
  d.ellipse((177,118,192,134),fill='#FFD27A',outline='#263746',width=3)
  for y in [67,174]:d.rounded_rectangle((34,y,53,y+27),4,fill='#D3DDE0',outline='#263746',width=3)
  if level>1:
   for y in [83,177]:d.rounded_rectangle((45,y,210,y+17),3,fill='#A5B7C2',outline='#263746',width=3)
  if level>3:d.rounded_rectangle((72,35,184,45),4,fill='#4DDDF3')
  im.save(OUT/f'door_{level}.png')
print('Prepared cartoon sprites, 20 bot gait frames and seven floor textures')

# Export icon is a format conversion of the original student sprite.
Image.open(OUT/"player_down_0.png").save(OUT/"app_icon.ico",sizes=[(16,16),(32,32),(48,48),(64,64),(128,128),(256,256)])
