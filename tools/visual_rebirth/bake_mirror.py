"""Bake the fixed Mirror Barrier with ten physical tiers and two specializations."""
from functools import partial
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from bake_arc import curved_electrode as pipe
from bake_dynamo import bake_atlas
from bake_needle import PALETTE as MODEL_PALETTE

OUTPUT = Path("assets/visual_rebirth/buildings/barrier").resolve()
VARIANTS = [(n,"") for n in range(1,11)]
VARIANTS += [(n,branch) for branch in ("mirror","ward") for n in range(5,11)]
PALETTE = MODEL_PALETTE | {"mirror_dark":(.075,.068,.098,1),
                        "mirror_haze":(.143,.135,.216,1),"mirror_light":(.271,.244,.364,1),
                        "amethyst":(.33,.18,.47,1),"silverleaf":(.47,.45,.51,1)}


def angled(pane,location,width,depth,height):
    x,y,z = location
    dx,dy = pane
    return (x+dx*width-dy*depth,y+dy*width+dx*depth,z+height)


def mirror_panel(m, location, width, height, yaw=0.0, silver=False):
    seam = (math.cos(yaw),math.sin(yaw))
    coords = [(-1,.05),(-.82,0),(.82,0),(1,.05),(1,.62),(.78,.83),(.44,.92),(0,1),
              (-.44,.92),(-.78,.83),(-1,.62)]
    coords = [(a*width,b*height) for a,b in coords]
    face = [angled(seam,location,a,0,b) for a,b in coords]
    backing = [angled(seam,location,a,.081,b) for a,b in coords]
    m.add(backing,[tuple(reversed(range(len(backing))))],"iron")
    for i,(a,b) in enumerate(zip(face,face[1:]+face[:1])):
        following=(i+1)%len(face)
        m.add([a,b,backing[following],backing[i]],[(0,1,2,3)],"iron")
        m.cylinder(a,b,.041,.041,"silverleaf" if silver else "bronze",10)
        thin = [angled(seam,location,coords[index][0]*.87,-.023,.013+coords[index][1]*.95) for index in (i,following)]
        m.cylinder(thin[0],thin[1],.014,.012,"edge",8)
    glints = [angled(seam,location,a*width,-.008,b*height)
              for a,b in ((0,.42),(-.28,.72),(.43,.66),(.76,.43),(.36,.35),(-.30,.14),(-.73,.23),(-.74,.48))]
    m.add(face,[tuple(range(len(face)))],"mirror_dark")
    m.add(glints,[(0,1,2,3,4),(0,4,5,6,7)],"mirror_haze")
    edge = [angled(seam,location,a*width,-.012,b*height) for a,b in ((-.81,.06),(.25,.24),(.63,.40),(-.52,.18))]
    m.add(edge,[(0,1,2,3)],"mirror_light")
    top = angled(seam,location,0,-.035,height*.94)
    tip = angled(seam,location,0,-.045,height+.12)
    m.cylinder(top,tip,.065,.023,"silverleaf")
    m.cylinder(angled(seam,location,-width*.08,-.047,height*.88),
               angled(seam,location,width*.09,-.047,height*.88),.050,.045,"amethyst",8)


def pillar(m,x,y,bottom,top,width=.082):
    m.box(x,y,bottom+.052,width*2.36,width*2.28,.105,"stone")
    m.cylinder((x,y,bottom+.09),(x,y,top-.22),width,width*.76,"iron",12)
    m.cylinder((x,y,top-.22),(x,y,top-.12),width*.99,width*.75,"bronze",12)
    m.cylinder((x,y,top-.12),(x,y,top),width*.74,.017,"edge",10)
    m.ring((x,y,bottom+.18),width+.008,.020,"bronze",sides=16)


def build(m,level,branch):
    tier = 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0
    width = (1.16,1.47,1.53,1.67)[tier]
    m.box(0,0,.071,width,.82,.142,"stone")
    m.box(0,-.023,.179,width*.91,.73,.083,"edge")
    m.box(0,-.275,.241,width*.70,.46,.091,"stone")
    # Chiseled joints on the front stairs and sacrificial cloth fasteners.
    for x in (-width*.29,0,width*.29):
        m.box(x,-.421,.095,.021,.030,.102,"shadow")
    h = (1.61,1.75,1.42,1.99)[tier]
    pane_width = (.289,.357,.331,.364)[tier]
    if branch == "mirror":
        h += .22
        pane_width += .055
    mirror_panel(m,(0,-.23,.31),pane_width,h,silver=branch=="ward")
    for side in (-1,1):
        x=side*(.42 if level<4 else .51)
        pillar(m,x,.003,.25,.48+h*.69,.092 if level>=4 else .073)
        m.cylinder((side*.29,-.054,.36),(x,-.060,1.24),.054,.048,"iron")
        cloth = [(x-.10,-.09,1.15),(x+.15,-.09,1.12),(x+.105,-.22,.77),(x+.055,-.23,.64),(x-.040,-.20,.71)]
        m.add(cloth,[(0,1,2,3,4)],"cloth")
    if level in (2,3):
        for side in (-1,1):
            pillar(m,side*.60,.02,.21,1.14,.088)
            m.cylinder((side*.61,-.07,.39),(side*.46,-.06,1.01),.074,.035,"bronze")
    if level==3:
        for side in (-1,1):
            m.cylinder((side*.60,-.07,.84),(side*.65,-.07,1.40),.087,.041,"silverleaf")
            m.cylinder((side*.65,-.07,1.40),(side*.57,-.05,1.48),.049,.020,"bronze")
    if 4<=level<7:
        for side in (-1,1):
            pillar(m,side*.65,.048,.21,1.70,.105)
            pipe(m,((side*.65,.06,1.37),(side*.63,.06,1.74),
                    (side*.29,.05,1.93),(0,.02,2.18)),(.048,.019),"edge")
        m.box(0,-.012,.49,1.05,.52,.135,"iron")
    if 5<=level<7 and not branch:
        pillar(m,-.79,-.16,.24,1.57,.100)
        m.cylinder((-.72,-.18,.68),(-.69,-.18,1.07),.089,.073,"amethyst")
    if level==6:
        pillar(m,.79,-.18,.23,1.83,.130)
        m.cylinder((.72,-.19,.53),(.72,-.22,1.22),.072,.041,"bronze")
    if 7<=level<10:
        for side in (-1,1):
            mirror_panel(m,(side*.58,-.17,.37),.203,1.08,side*.39,branch=="ward")
            pillar(m,side*.79,-.08,.23,1.56,.087)
            m.cylinder((side*.67,-.06,.36),(side*.80,-.08,1.05),.084,.056,"iron")
    if 8<=level<10:
        m.cylinder((-.64,-.19,1.20),(-.80,-.21,1.56),.101,.068,"iron")
        m.ring((-.80,-.24,1.57),.184,.053,"bronze",(0,1,0))
        m.cylinder((-.90,-.28,1.45),(-.70,-.28,1.69),.047,.040,"silverleaf")
        m.cylinder((-.92,-.28,1.59),(-.68,-.28,1.55),.047,.039,"iron")
    if level==9:
        for side in (-1,1):
            pillar(m,side*.83,-.13,.23,1.91,.097)
            m.cylinder((side*.80,-.16,.97),(side*.76,-.15,1.67),.062,.032,"edge")
    if level==10:
        for side in (-1,1):
            mirror_panel(m,(side*.54,-.15,.51),.156,1.40,side*.28,True)
            pillar(m,side*.71,.014,.21,2.12,.111)
            pipe(m,((side*.57,.10,1.45),(side*.61,.11,2.03),
                    (side*.33,.08,2.40),(0,.06,2.59)),(.054,.021),"bronze")
    if branch=="mirror":
        for side in (-1,1):
            m.cylinder((side*.37,-.15,1.45),(side*.51,-.13,1.91),.119,.067,"iron")
            m.cylinder((side*.51,-.13,1.91),(side*.44,-.11,2.23),.069,.032,"edge")
        m.box(.38,-.35,.43,.29,.26,.22,"amethyst")
        m.cylinder((0,-.20,.32),(0,-.34,.58),.119,.068,"bronze")
    elif branch=="ward":
        for side in (-1,1):
            mirror_panel(m,(side*.64,-.36,.44),.189,.79,side*.22,True)
            m.cylinder((side*.63,-.32,.40),(side*.82,-.28,.88),.112,.060,"silverleaf")
            m.cylinder((side*.82,-.28,.88),(side*.74,-.27,1.32),.066,.027,"edge")


if __name__=="__main__":
    OUTPUT.mkdir(parents=True,exist_ok=True)
    bake_atlas(OUTPUT/"base.png",PALETTE,6,4,(
        (i%6,i//6,partial(build,level=level,branch=branch))
        for i,(level,branch) in enumerate(VARIANTS)))
