"""Bake the Shield Generator's cast-iron chapel housing and active ward rotors.

Run from the repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_shield.py
"""
from functools import partial
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from bake_arc import curved_electrode as pipe, lancet
from bake_dynamo import bake_atlas
from bake_needle import PALETTE as MODEL_PALETTE

OUTPUT = Path("assets/visual_rebirth/buildings/shield").resolve()
VARIANTS = [(level,"") for level in range(1,11)]
VARIANTS += [(level,branch) for branch in ("aegis_burst","steady_veil") for level in range(5,11)]
PALETTE = MODEL_PALETTE | {
    "steel":(.29,.31,.31,1),
    "ward":(.41,.72,.43,1),
    "sage":(.24,.49,.27,1),
    "jade":(.09,.37,.19,1),
    "pale":(.70,.83,.56,1),
}


def frame_tier(level):
    return 3 if level == 10 else 2 if level >= 7 else 1 if level >= 4 else 0


def gate(m,x,z,height,width,depth=-.18,color="iron"):
    """Pointed arch with a tapering spine, rested on vertical cast-iron jambs."""
    for side in (-1,1):
        foot = (x+side*width,depth,z)
        shoulder = (x+side*width,depth,z+height*.49)
        tip = (x,depth,z+height)
        m.cylinder(foot,shoulder,.057,.050,color,12)
        pipe(m,(shoulder,
            (x+side*width,depth,z+height*.74),
            (x+side*width*.28,depth,z+height*.86),
            tip),(.053,.026),color)
        m.cylinder((foot[0],depth,foot[2]),(foot[0],depth,foot[2]+.124),.081,.060,"bronze")
        m.cylinder((shoulder[0],depth,shoulder[2]-.05),(shoulder[0],depth,shoulder[2]+.04),.067,.056,"edge")
    m.cylinder((x,depth,z+height-.08),(x,depth,z+height+.125),.047,.015,"bronze",12)


def shield_glass(m,x,y,z,radius):
    """Stained glass cut into six leaded light panes surrounding a pale spindle."""
    corners = [(x+radius*math.cos(math.pi/6+n*math.tau/6),y,z+radius*math.sin(math.pi/6+n*math.tau/6)) for n in range(6)]
    vertices = [(x,y+.018,z)] + corners
    hues = ("ward","jade","pale","sage","ward","jade")
    for index,(a,b) in enumerate(zip(corners,corners[1:]+corners[:1])):
        m.add(vertices,[(0,1+index,1+(index+1)%6)],hues[index])
        m.cylinder(a,b,.026,.023,"bronze",8)
        middle = (x+(a[0]-x)*.28,y-.008,z+(a[2]-z)*.28)
        m.cylinder(a,middle,.016,.011,"iron",8)
    m.cylinder((x,y+.019,z),(x,y-.04,z),.095,.063,"pale",8)
    m.cylinder((x,y-.04,z),(x,y-.064,z),.065,.036,"gold",8)


def rotor_positions(level,branch):
    tier = frame_tier(level)
    height = (1.30,1.48,1.43,1.71)[tier]
    radius = (.276,.337,.382,.388)[tier]
    if branch == "aegis_burst":
        return [(0,-.37,height+.03,radius+.037,6)]
    if branch == "steady_veil":
        return [(0,-.36,height,radius*.86,4), (0,-.29,height,radius+.035,5)]
    return [(0,-.35,height,radius,5)]


def housing(m,level,branch):
    tier = frame_tier(level)
    s = (1.08,1.28,1.25,1.23)[tier]
    m.cosine,m.sine = math.cos(math.pi/4),math.sin(math.pi/4)
    m.box(0,0,.075,s,s,.15,"stone")
    m.box(0,0,.18,s*.91,s*.91,.07,"edge")
    m.box(0,0,.337,s*.75,s*.75,.26,"iron")
    m.box(0,0,.482,s*.84,s*.84,.07,"bronze")
    for _ in range(4):
        y = -s*.378
        lancet(m,0,y,.244,.130,.225,"bronze")
        lancet(m,0,y-.025,.264,.086,.163,"sage")
        m.cosine,m.sine = -m.sine,m.cosine
    for x in (-s*.38,s*.38):
        for y in (-s*.38,s*.38):
            m.box(x,y,.312,.165,.161,.289,"stone")
            m.cylinder((x,y,.45),(x,y,.55),.079,.047,"edge",12)
            m.cylinder((x,y,.55),(x,y,.63),.053,.009,"bronze",10)
    m.cosine,m.sine = 1,0
    m.cylinder((0,0,.50),(0,0,.63),.367,.317,"iron",24)
    m.cylinder((0,0,.59),(0,0,.72),.317,.29,"bronze",24)
    _,_,wheel_z,wheel_r,_ = rotor_positions(level,"")[0]
    shield_glass(m,0,-.259,wheel_z,wheel_r*.94)
    m.cylinder((0,-.018,.69),(0,-.055,wheel_z),.089,.070,"iron")
    m.cylinder((0,-.050,wheel_z),(0,-.234,wheel_z),.115,.091,"bronze")
    for side in (-1,1):
        m.cylinder((side*.28,-.21,.53),(side*.28,-.21,.75),.063,.047,"bronze")
    if tier == 0:
        gate(m,0,.65,1.30,.374)
    elif tier == 1:
        gate(m,0,.68,1.45,.399)
        for side in (-1,1):
            gate(m,side*.49,.56,.93,.210,depth=-.11,color="steel")
            shield_glass(m,side*.51,-.168,1.05,.126)
    elif tier == 2:
        # An open annular field cage succeeds the pointed chapel housing.
        m.ring((0,-.11,1.44),.609,.083,"iron",(0,1,0),sides=36)
        m.ring((0,-.23,1.44),.608,.041,"bronze",(0,1,0),sides=36)
        for side in (-1,1):
            m.box(side*.67,-.12,.52,.36,.31,.23,"iron")
            m.cylinder((side*.60,-.12,.55),(side*.78,-.12,1.09),.148,.105,"iron")
            m.cylinder((side*.78,-.12,1.09),(side*.76,-.11,1.44),.108,.076,"bronze")
            m.cylinder((side*.76,-.11,1.44),(side*.60,-.10,1.70),.082,.033,"gold")
            m.cylinder((side*.60,-.11,1.43),(side*.75,-.11,1.57),.069,.049,"edge")
            m.cylinder((side*.67,-.23,.61),(side*.72,-.24,1.04),.077,.046,"sage")
    else:
        gate(m,0,.74,1.77,.563,depth=-.10)
        gate(m,0,.68,1.46,.406,depth=.12,color="bronze")
        for side in (-1,1):
            gate(m,side*.53,.52,1.30,.243,depth=-.20,color="steel")
            shield_glass(m,side*.53,-.253,1.23,.151)
            pipe(m,((side*.51,-.15,1.73),(side*.51,-.14,2.19),(side*.27,-.13,2.45),(0,-.10,2.56)),(.050,.024),"bronze")
        m.ring((0,-.050,1.69),.511,.044,"iron",(0,1,0),sides=32)
    if level in (2,3):
        for side in (-1,1):
            m.box(side*.60,-.11,.42,.29,.33,.27,"iron")
            m.cylinder((side*.56,-.18,.42),(side*.72,-.16,.76),.105,.069,"bronze")
            m.cylinder((side*.72,-.16,.76),(side*.55,-.13,.91),.075,.036,"edge")
    if level == 3:
        for side in (-1,1):
            pipe(m,((side*.52,-.18,.63),(side*.74,-.15,.86),(side*.73,-.14,1.21),(side*.36,-.16,1.25)),(.076,.045),"bronze")
            shields_z = 1.21
            shield_glass(m,side*.57,-.212,shields_z,.118)
    if 5 <= level < 7 and not branch:
        m.cylinder((-.59,-.27,.61),(-.75,-.25,.98),.149,.097,"iron")
        m.cylinder((-.75,-.25,.98),(-.76,-.23,1.45),.100,.066,"bronze")
        m.cylinder((-.76,-.23,1.45),(-.65,-.19,1.61),.072,.031,"edge")
        m.ring((-.75,-.26,1.10),.108,.031,"gold")
    if level == 6:
        m.box(.72,-.21,.64,.30,.38,.32,"iron")
        m.cylinder((.53,-.22,.53),(.78,-.22,.89),.149,.112,"bronze")
        m.cylinder((.78,-.22,.89),(.79,-.20,1.43),.113,.069,"iron")
        m.cylinder((.79,-.20,1.43),(.65,-.18,1.63),.074,.036,"gold")
    if 8 <= level < 10:
        m.ring((-.79,-.25,1.09),.190,.057,"bronze",(0,1,0))
        m.cylinder((-.94,-.29,.99),(-.63,-.29,1.20),.051,.043,"iron")
        m.cylinder((-.79,-.25,.97),(-.74,-.22,1.44),.082,.056,"iron")
    if level == 9:
        for side in (-1,1):
            m.box(side*.76,-.14,.92,.29,.30,.47,"iron")
            m.cylinder((side*.73,-.18,.98),(side*.85,-.17,1.48),.116,.076,"bronze")
            m.cylinder((side*.85,-.17,1.48),(side*.86,-.15,1.77),.079,.049,"steel")
            m.cylinder((side*.86,-.15,1.77),(side*.71,-.13,1.94),.055,.017,"gold")
    if branch == "aegis_burst":
        for side in (-1,1):
            m.cylinder((side*.42,-.24,.50),(side*.64,-.20,1.16),.169,.117,"bronze")
            m.cylinder((side*.64,-.20,1.16),(side*.52,-.17,1.65),.118,.078,"gold")
            m.cylinder((side*.52,-.17,1.65),(side*.39,-.16,1.88),.075,.032,"iron")
        m.cylinder((0,-.27,.53),(0,-.52,.95),.169,.106,"gold")
    elif branch == "steady_veil":
        for side in (-1,1):
            gate(m,side*.68,.48,.93,.229,depth=-.30,color="iron")
            shield_glass(m,side*.70,-.356,1.01,.173)
            m.cylinder((side*.72,-.31,.53),(side*.79,-.30,.86),.117,.064,"bronze")
            m.box(side*.71,-.29,.53,.33,.27,.19,"iron")


def motion(m,level,branch,phase):
    for index,(x,y,z,radius,arms) in enumerate(rotor_positions(level,branch)):
        rotation = phase*(-1 if index else 1) + index*.33
        m.ring((x,y,z),radius,.026,"steel",(0,1,0),sides=32)
        m.ring((x,y+.025,z),radius+.013,.014,"bronze",(0,1,0),sides=32)
        for spoke in range(arms):
            angle = rotation + spoke*math.tau/arms
            dx,dz = math.cos(angle),math.sin(angle)
            m.cylinder((x+dx*radius*.77,y-.034,z+dz*radius*.77),(x+dx*radius*1.055,y-.034,z+dz*radius*1.055),.030,.020,"bronze",8)
        marker = (x+math.cos(rotation)*radius,y-.047,z+math.sin(rotation)*radius)
        m.cylinder(marker,(marker[0],marker[1]-.034,marker[2]),.044,.021,"pale",8)
        if level >= 8:
            extra = rotation+math.pi*.72
            marker = (x+math.cos(extra)*radius,y-.042,z+math.sin(extra)*radius)
            m.cylinder(marker,(marker[0],marker[1]-.039,marker[2]),.038,.018,"ward",8)


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True,exist_ok=True)
    bake_atlas(OUTPUT/"base.png", PALETTE, 6,4, (
        (index%6,index//6,partial(housing,level=level,branch=branch))
        for index,(level,branch) in enumerate(VARIANTS)))
    bake_atlas(OUTPUT/"motion.png", PALETTE,8,len(VARIANTS), (
        (frame,index,partial(motion,level=level,branch=branch,phase=frame*math.tau/8))
        for index,(level,branch) in enumerate(VARIANTS) for frame in range(8)))
