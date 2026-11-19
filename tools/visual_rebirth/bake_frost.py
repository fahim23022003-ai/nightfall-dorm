"""Bake fixed chapel-plinth Frost Tower variants at the shared orthographic angle."""
from collections import defaultdict
import math
from pathlib import Path
from random import Random
import sys

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bake_arc as arc
import bake_needle as baker

ICE_COLORS = ("white_ice", "glacier", "deep_blue", "ice_shadow")


def shard(m, start, end, radius, seed, dark=False):
    """Taper and triangulate uneven mineral growth about a leaning centerline."""
    rng = Random(seed)
    x, y, z = start
    hx, hy, hz = (b-a for a,b in zip(start,end))
    vertices = []
    sides = 6
    rotation = rng.random()*math.tau
    rings = (.0,.38,.73,.90)
    for fraction, breadth in zip(rings,(.73,1,.77,.46)):
        for side in range(sides):
            angle = rotation + side*math.tau/sides
            r = radius*breadth*rng.uniform(.75,1.22)
            vertices.append((x+hx*fraction+r*math.cos(angle),
                             y+hy*fraction+r*math.sin(angle),
                             z+hz*fraction+(rng.uniform(-.12,.12) if fraction else 0)))
    tip_index = len(vertices)
    vertices.append(end)
    facets = defaultdict(list)
    palette = ICE_COLORS if not dark else ("deep_blue","ice_shadow","glacier","ice_shadow")
    for ring in range(len(rings)-1):
        for side in range(sides):
            a = ring*sides+side
            b = ring*sides+(side+1)%sides
            facets[rng.choice(palette)].append((a,b,b+sides))
            facets[rng.choice(palette)].append((a,b+sides,a+sides))
    start_idx = (len(rings)-1)*sides
    for side in range(sides):
        facets[rng.choice(ICE_COLORS)].append((start_idx+side,start_idx+(side+1)%sides,tip_index))
    for material, faces in facets.items():
        m.add(vertices,faces,material)


def clamp(m,x,y,z,height):
    m.cylinder((x,y,z),(x*.91,y*.91,z+height*.73),.055,.044,"iron",12)
    m.cylinder((x*.91,y*.91,z+height*.73),(x*.83,y*.83,z+height),.053,.013,"silver",10)
    m.ring((x*.94,y*.94,z+height*.42),.051,.021,"bronze",sides=12)


def plinth(m,level,branch):
    size = (1.09 if level < 4 else 1.31 if level < 7 else 1.25 if level < 10 else 1.20)
    m.cosine,m.sine = math.cos(math.pi/4),math.sin(math.pi/4)
    m.box(0,0,.075,size,size,.15,"stone")
    m.box(0,0,.189,size*.95,size*.95,.080,"snow")
    m.box(0,0,.348,size*.77,size*.77,.247,"ice_shadow")
    m.box(0,0,.503,size*.85,size*.85,.088,"stone")
    for _ in range(4):
        front = -size*.387
        arc.lancet(m,0,front,.228,.134,.242,"bronze")
        arc.lancet(m,0,front-.025,.251,.089,.182,"glacier")
        for side in (-1,1):
            m.cylinder((side*.217,front-.026,.224),(side*.217,front-.026,.48),.026,.020,"iron")
        m.cosine,m.sine = -m.sine,m.cosine
    for x in (-size*.38,size*.38):
        for y in (-size*.38,size*.38):
            m.box(x,y,.303,.157,.155,.268,"stone")
            m.box(x,y,.449,.17,.17,.048,"snow")
            clamp(m,x,y,.46,.22)
    m.cosine,m.sine = 1,0
    m.cylinder((0,0,.52),(0,0,.66),.350,.289,"bronze",24)
    m.ring((0,0,.68),.294,.035,"iron")
    for side in (-1,1):
        clamp(m,side*.281,-.18,.63,.33)
    if level in (2,3):
        for side in (-1,1):
            m.box(side*.62,-.12,.35,.31,.34,.23,"stone")
            m.box(side*.65,-.13,.48,.25,.32,.08,"snow")
            m.cylinder((side*.61,-.17,.44),(side*.73,-.14,.79),.104,.074,"iron")
            m.cylinder((side*.73,-.14,.79),(side*.62,-.13,1.03),.077,.038,"bronze")
            clamp(m,side*.72,-.14,.78,.33)
    if 4 <= level < 7:
        m.cylinder((0,0,.54),(0,0,.87),.47,.38,"iron",24)
        m.cylinder((0,0,.75),(0,0,.84),.448,.403,"bronze",24)
        m.ring((0,0,.95),.408,.043,"silver")
        for side in (-1,1):
            m.cylinder((side*.60,-.08,.43),(side*.60,-.08,.90),.115,.088,"ice_shadow")
            m.cylinder((side*.6,-.08,.90),(side*.50,-.08,1.05),.091,.047,"silver")
    if 5 <= level < 7 and not branch:
        m.box(-.71,-.20,.68,.33,.38,.31,"ice_shadow")
        m.box(-.78,-.20,.848,.23,.30,.06,"snow")
        m.cylinder((-.69,-.27,.80),(-.82,-.24,1.13),.107,.073,"iron")
        m.cylinder((-.82,-.24,1.13),(-.71,-.21,1.26),.074,.037,"bronze")
    if level == 6:
        for side in (-1,1):
            m.cylinder((side*.64,-.13,.42),(side*.77,-.14,.73),.104,.079,"iron")
            m.cylinder((side*.77,-.14,.73),(side*.63,-.14,1.09),.083,.039,"silver")
    if 7 <= level < 10:
        for side in (-1,1):
            m.box(side*.62,-.04,.32,.37,.54,.23,"ice_shadow")
            m.cylinder((side*.64,-.18,.46),(side*.76,-.17,.88),.141,.101,"iron")
            m.cylinder((side*.76,-.17,.88),(side*.65,-.16,1.24),.113,.058,"bronze")
            m.ring((side*.76,-.17,.90),.118,.028,"silver")
    if 8 <= level < 10:
        m.cylinder((-.63,-.25,.67),(-.79,-.25,1.16),.106,.079,"iron")
        m.ring((-.78,-.30,1.17),.166,.047,"bronze",(0,1,0))
        m.cylinder((-.92,-.33,1.10),(-.64,-.33,1.24),.046,.036,"iron")
    if level == 9:
        for side in (-1,1):
            m.box(side*.74,-.18,.64,.26,.28,.23,"ice_shadow")
            clamp(m,side*.88,-.16,.76,.49)
    if level == 10:
        m.cylinder((0,0,.56),(0,0,.75),.45,.39,"iron",24)
        m.ring((0,0,.79),.378,.043,"silver")
        for side in (-1,1):
            m.cylinder((side*.55,-.08,.54),(side*.72,-.08,1.02),.108,.089,"iron")
            m.cylinder((side*.72,-.08,1.02),(side*.56,-.08,1.28),.092,.044,"bronze")
            clamp(m,side*.55,-.14,1.26,.26)
    if branch == "deep_chill":
        m.box(.22,-.52,.60,.40,.33,.30,"ice_shadow")
        m.box(.24,-.696,.63,.31,.056,.12,"deep_blue")
        clamp(m,.53,-.52,.62,.47)
    elif branch == "rime_field":
        for side in (-1,1):
            m.cylinder((side*.60,-.37,.46),(side*.69,-.32,.93),.119,.075,"deep_blue")
            m.ring((side*.69,-.32,.90),.086,.024,"bronze")


def crown(m,level,branch):
    if level < 4:
        shard(m,(-.04,0,.64),(.36,.03,2.19),.277,175)
        shard(m,(-.03,.00,.64),(-.42,-.05,1.37),.119,31)
        shard(m,(.02,.02,.71),(.42,.16,1.61),.092,55)
        if level == 3:
            for side in (-1,1):
                shard(m,(side*.49,-.14,.44),(side*.67,-.15,1.37),.188,22+side)
    elif level < 7:
        shard(m,(-.14,0,.81),(-.31,.11,2.12),.358,8)
        shard(m,(.12,0,.86),(.55,.13,1.85),.205,78)
        shard(m,(-.18,-.07,.81),(-.60,-.09,1.63),.177,98)
        if level == 6:
            shard(m,(.39,-.16,.63),(.76,-.14,1.47),.178,93)
    elif level < 10:
        shard(m,(-.02,0,.70),(.02,.08,2.17),.284,781)
        for side in (-1,1):
            reach = .54 if branch == "deep_chill" else .76
            end_height = 1.80 if branch == "deep_chill" else 2.07
            shard(m,(side*.23,0,.73),(side*reach,.14,end_height),.198,79+side)
            shard(m,(side*.25,-.13,.71),(side*.66,-.18,1.53),.139,261+side)
        if level >= 8:
            m.ring((0,0,1.39),.465,.041,"iron",axis=(0,0,1),sides=24)
            for x in (-.47,.47):
                clamp(m,x,-.04,1.38,.26)
        if level == 9:
            shard(m,(-.55,-.20,.69),(-.83,-.16,1.54),.153,16)
            shard(m,(.45,-.22,.70),(.80,-.18,1.69),.163,94)
    else:
        shard(m,(.01,0,.75),(-.28,.16,2.73),.364,330,True)
        shard(m,(-.12,-.11,.82),(-.65,-.12,2.01),.181,49,True)
        shard(m,(.10,.00,.91),(.67,.18,2.33),.206,61)
        shard(m,(.24,.07,.91),(.89,.22,1.73),.141,74)
        shard(m,(-.19,-.08,.90),(-.55,-.12,1.47),.159,93)
        m.ring((0,0,1.09),.425,.034,"silver")
    if branch == "deep_chill":
        shard(m,(-.12,-.08,.89),(-.20,-.15,2.45),.217,89,True)
        m.ring((0,-.11,1.25),.374,.042,"bronze",begin=.4,end=5.8)
    elif branch == "rime_field":
        for side in (-1,1):
            shard(m,(side*.42,-.08,.80),(side*.93,-.05,1.93),.223,48+side)
            shard(m,(side*.43,-.21,.71),(side*.78,-.24,1.54),.140,22+side)


def build(m,level,branch):
    plinth(m,level,branch)
    crown(m,level,branch)


if __name__ == "__main__":
    baker.SHEET = Path("assets/visual_rebirth/buildings/frost").resolve()
    baker.SHEET.mkdir(parents=True,exist_ok=True)
    baker.CELL = 96
    baker.STATES = [(level,"") for level in range(1,11)]
    baker.STATES += [(level,branch) for branch in ("deep_chill","rime_field") for level in range(5,11)]
    baker.PALETTE.update({"snow":(.49,.57,.60,1),"white_ice":(.51,.79,.84,1),"glacier":(.24,.57,.73,1),"deep_blue":(.10,.34,.49,1),"ice_shadow":(.10,.18,.25,1)})
    baker.bake("base",6,4,build)
