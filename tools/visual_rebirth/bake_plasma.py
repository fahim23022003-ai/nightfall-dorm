"""Bake the Plasma Capacitor's violet containment vessel and charged inner rotor."""
from functools import partial
import math
from pathlib import Path
import sys

sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from bake_arc import curved_electrode as pipe, lancet
from bake_dynamo import bake_atlas
from bake_flame import ellipsoid
from bake_needle import PALETTE as MODEL_PALETTE

OUTPUT = Path("assets/visual_rebirth/buildings/plasma").resolve()
VARIANTS = [(n,"") for n in range(1,11)]
VARIANTS += [(n,v) for v in ("reservoir","converter") for n in range(5,11)]
PALETTE = MODEL_PALETTE | {"porcelain":(.165,.126,.171,1),"violet":(.31,.112,.50,1),
    "plasma":(.56,.23,.81,1),"saturated":(.43,.10,.62,1),"vapor":(.75,.48,.89,1),
    "transduce":(.23,.42,.33,1)}


def tier_for(level):
    return 3 if level==10 else 2 if level>=7 else 1 if level>=4 else 0


def chamber(m,x,y,z,width,height,cap="bronze"):
    ellipsoid(m,(x,y,z),(width,width*.85,height),"saturated")
    ellipsoid(m,(x,y-width*.19,z+.025),(width*.87,width*.79,height*.90),"violet")
    m.ring((x,y,z-height*.94),width*.72,.042,cap)
    m.ring((x,y,z+height*.94),width*.65,.039,cap)
    m.cylinder((x,y,z+height*.88),(x,y,z+height*1.16),width*.76,width*.40,cap,16)
    m.cylinder((x,y,z+height*1.15),(x,y,z+height*1.27),width*.42,width*.25,"edge",12)
    ellipsoid(m,(x-.062,y-width*.72,z+.075),(width*.38,.03,height*.31),"plasma")


def housing(m,level,branch):
    tier=tier_for(level)
    size=(1.05,1.31,1.32,1.18)[tier]
    m.cosine,m.sine=math.cos(math.pi/4),math.sin(math.pi/4)
    m.box(0,0,.072,size,size,.144,"stone")
    m.box(0,0,.179,size*.94,size*.94,.077,"edge")
    m.box(0,0,.332,size*.78,size*.78,.245,"porcelain")
    m.box(0,0,.481,size*.86,size*.86,.089,"iron")
    for _ in range(4):
        y=-size*.394
        for x in (-size*.21,size*.21):
            lancet(m,x,y,.246,.060,.187,"bronze")
            lancet(m,x,y-.023,.271,.038,.128,"violet")
        m.cosine,m.sine=-m.sine,m.cosine
    for x in (-size*.391,size*.391):
        for y in (-size*.391,size*.391):
            m.box(x,y,.317,.178,.171,.281,"stone")
            m.cylinder((x,y,.448),(x,y,.63),.070,.014,"bronze",12)
    m.cosine,m.sine=1,0
    m.cylinder((0,0,.54),(0,0,.64),.356,.314,"bronze",24)
    m.cylinder((0,0,.63),(0,0,.76),.314,.251,"iron",24)
    z=(1.23,1.28,1.24,1.42)[tier]
    radius=(.30,.375,.320,.368)[tier]
    height=(.44,.45,.39,.51)[tier]
    chamber(m,0,0,z,radius,height)
    for side in (-1,1):
        root=(side*.29,-.07,.68)
        end=(0,-.055,z+height*1.16)
        pipe(m,(root,(side*(radius+.25),-.075,z-.05),
                (side*(radius+.16),-.080,z+height*.70),end),
                (.056 if tier<2 else .066,.036),"iron")
        m.cylinder((root[0],-.07,.66),(root[0],-.07,.84),.085,.064,"bronze")
    if level in (2,3):
        for side in (-1,1):
            m.box(side*.61,-.17,.40,.32,.28,.21,"iron")
            m.cylinder((side*.57,-.17,.45),(side*.72,-.15,.74),.109,.073,"bronze")
            m.cylinder((side*.72,-.15,.74),(side*.54,-.12,.88),.074,.036,"edge")
    if level==3:
        for side in (-1,1):
            chamber(m,side*.55,-.18,.88,.107,.238)
            m.cylinder((side*.52,-.23,.59),(side*.55,-.23,1.00),.036,.029,"iron")
    if 4<=level<7:
        m.cylinder((0,0,.53),(0,0,.94),.57,.423,"porcelain",28)
        m.ring((0,0,.92),.426,.044,"bronze")
        for side in (-1,1):
            m.box(side*.54,-.06,.61,.291,.50,.29,"iron")
            m.cylinder((side*.56,-.15,.63),(side*.62,-.14,1.11),.138,.092,"bronze")
            m.cylinder((side*.62,-.14,1.11),(side*.54,-.11,1.19),.099,.041,"edge")
    if 5<=level<7 and not branch:
        m.box(-.63,-.38,.70,.30,.32,.34,"porcelain")
        chamber(m,-.72,-.25,1.03,.116,.208)
    if level==6:
        m.box(.70,-.14,.56,.31,.37,.28,"iron")
        m.cylinder((.60,-.21,.63),(.80,-.20,.98),.123,.098,"bronze")
        m.cylinder((.80,-.20,.98),(.72,-.18,1.43),.101,.048,"iron")
    if 7<=level<10:
        # A separated top buffer and widened dual lower retainers.
        chamber(m,0,.085,2.02,.300,.273)
        m.cylinder((0,.03,1.64),(0,.03,1.82),.164,.116,"bronze")
        for side in (-1,1):
            m.box(side*.62,-.03,.49,.32,.58,.24,"iron")
            chamber(m,side*.68,-.15,1.06,.178,.352)
            pipe(m,((side*.70,-.09,.77),(side*.96,-.11,1.24),(side*.76,-.09,1.81),
                    (side*.23,-.07,1.98)),(.081,.040),"bronze")
    if 8<=level<10:
        m.cylinder((-.67,-.23,.75),(-.78,-.24,1.29),.113,.078,"iron")
        m.ring((-.79,-.25,1.30),.186,.055,"bronze",(0,1,0))
        m.cylinder((-.93,-.28,1.19),(-.64,-.28,1.42),.048,.043,"iron")
    if level==9:
        for side in (-1,1):
            m.box(side*.76,-.11,.83,.27,.34,.45,"porcelain")
            m.cylinder((side*.74,-.16,1.03),(side*.86,-.13,1.52),.107,.077,"bronze")
            m.cylinder((side*.86,-.13,1.52),(side*.72,-.13,1.72),.075,.032,"edge")
    if level==10:
        m.cylinder((0,0,.54),(0,0,.87),.423,.361,"porcelain",24)
        for side in (-1,1):
            m.cylinder((side*.50,-.07,.51),(side*.61,-.07,1.56),.085,.071,"iron")
            pipe(m,((side*.60,-.07,1.52),(side*.57,-.06,2.27),(side*.37,-.03,2.48),
                    (0,-.03,2.59)),(.069,.035),"bronze")
            m.cylinder((side*.48,-.30,.56),(side*.48,-.26,1.41),.081,.051,"porcelain")
        chamber(m,0,.022,2.22,.23,.212)
        m.cylinder((0,-.03,2.44),(0,-.03,2.64),.073,.021,"gold")
    if branch=="reservoir":
        m.cylinder((0,-.21,.51),(0,-.32,.94),.137,.105,"porcelain")
        chamber(m,.63,-.22,1.38,.183,.512)
        m.cylinder((.61,-.23,1.16),(.66,-.22,1.85),.108,.066,"bronze")
        m.cylinder((.65,-.22,1.85),(.54,-.19,2.02),.072,.033,"iron")
    elif branch=="converter":
        for side in (-1,1):
            m.box(side*.73,-.18,.58,.37,.39,.27,"iron")
            m.cylinder((side*.73,-.32,.66),(side*.79,-.30,1.22),.158,.101,"transduce")
            pipe(m,((side*.74,-.23,.77),(side*.89,-.28,1.08),(side*.82,-.28,1.40),
                    (side*.36,-.29,1.48)),(.079,.052),"bronze")
        m.cylinder((0,-.43,.64),(0,-.50,1.18),.109,.083,"transduce")
        m.ring((0,-.49,1.11),.092,.024,"bronze")


def motion(m,level,branch,phase):
    tier=tier_for(level)
    z=(1.23,1.28,1.24,1.42)[tier]
    radius=(.29,.369,.320,.375)[tier]
    rings=2 if level>=8 or branch=="reservoir" else 1
    for ring in range(rings):
        radius_i=radius*(1.01 if ring==0 else .81)
        current=phase*(1 if ring==0 else -1)+ring*.29
        y=-.368-ring*.026
        m.ring((0,y,z),radius_i,.022,"iron",(0,1,0),sides=32)
        for n in range(4):
            angle=current+n*math.tau/4
            a=(math.cos(angle),math.sin(angle))
            m.cylinder((a[0]*radius_i*.89,y-.019,z+a[1]*radius_i*.89),
                       (a[0]*radius_i*1.09,y-.019,z+a[1]*radius_i*1.09),
                       .035,.023,"bronze",8)
        a=(math.cos(current),math.sin(current))
        x,z_i=a[0]*radius_i,z+a[1]*radius_i
        m.cylinder((x,y-.021,z_i),(x,y-.056,z_i),.044,.023,
                   "transduce" if branch=="converter" else "vapor",8)


if __name__=="__main__":
    OUTPUT.mkdir(parents=True,exist_ok=True)
    bake_atlas(OUTPUT/"base.png",PALETTE,6,4,(
        (i%6,i//6,partial(housing,level=level,branch=branch))
        for i,(level,branch) in enumerate(VARIANTS)))
    bake_atlas(OUTPUT/"motion.png",PALETTE,8,len(VARIANTS),(
        (j,i,partial(motion,level=level,branch=branch,phase=math.tau*j/8))
        for i,(level,branch) in enumerate(VARIANTS) for j in range(8)))
