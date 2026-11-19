"""Bake original Repair Station cabinetry, fixtures, and working assemblies.

Run from the repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_repair.py
"""
from functools import partial
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, MOTION_FRAMES, bake_atlas, pipe, lancet
from bake_needle import PALETTE as METALS

STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("sustain", "conservation") for level in range(5, 11)]
OUTPUT = Path("assets/visual_rebirth/buildings/repair").resolve()
PAL = METALS | {
    "stone": (.21, .19, .169, 1),
    "oak": (.29, .14, .076, 1),
    "endgrain": (.40, .22, .113, 1),
    "wood_shadow": (.157, .074, .041, 1),
    "canvas": (.34, .19, .145, 1),
    "canvas_edge": (.52, .32, .18, 1),
    "wool": (.33, .091, .076, 1),
    "lantern": (.91, .63, .19, 1),
    "blue": (.18, .43, .48, 1),
    "linen": (.62, .49, .36, 1),
}


def caster(m, x, y, radius):
    z = .13 + radius
    axis = (0,-1,0)
    m.ring((x,y,z), radius,.032,"iron",axis,sides=22)
    m.ring((x,y-.023,z),radius-.012,.016,"bronze",axis,sides=22)
    for n in range(6):
        a=n*math.tau/6
        m.cylinder((x,y,z),(x+math.cos(a)*radius*.9,y,z+math.sin(a)*radius*.9),.025,.02,"endgrain",8)
    m.cylinder((x,y+.02,z),(x,y-.06,z),.057,.041,"bronze",10)


def planks(m, x, y, z, count, width, depth):
    for n in range(count):
        offset = (.044 if n%2 else -.018)
        m.box(x+offset,y+n*.008,z+n*.091,width-.021*n,depth,.079,"oak" if n%2 else "endgrain")
        m.box(x+offset+width*.50-.012,y+n*.008,z+n*.091,.027,depth*.91,.054,"wood_shadow")
    for offset in (-width*.12,width*.15):
        m.box(x+offset,y-.50*depth,z+.042*(count-1),.037,.019,count*.085,"canvas_edge")


def lantern(m, x, y, z, tint="lantern"):
    m.cylinder((x,y,z),(x,y,z+.062),.115,.078,"bronze",12)
    m.cylinder((x,y,z+.06),(x,y,z+.29),.073,.056,tint,10)
    m.cylinder((x,y,z+.286),(x,y,z+.35),.080,.045,"bronze",10)
    m.ring((x,y,z+.339),.05,.013,"iron", (0,1,0),begin=0,end=math.pi,sides=12)
    for sign in (-1,1):
        m.cylinder((x+sign*.076,y-.040,z+.06),(x-sign*.032,y-.047,z+.281),.011,.009,"bronze",8)


def cabinet(m, x, y, width, height, crowded):
    bottom = .24
    front = y-width*.30
    m.box(x,y,bottom+height*.5,width,width*.60,height,"oak")
    m.box(x,y,bottom+height*.5,width*.93,width*.63,height*.89,"wood_shadow")
    for sign in (-1,1):
        rail_x=x+sign*width*.44
        m.box(rail_x,front-.028,bottom+height*.53,.057,.056,height*1.03,"iron")
        for z in (bottom+.055,bottom+height*.84):
            m.cylinder((rail_x,front-.03,z),(rail_x,front-.069,z),.024,.015,"bronze",8)
    for z in (bottom+.036,bottom+height):
        m.box(x,y,z,width*1.06,width*.68,.092,"endgrain")
    for n in range(3):
        z = bottom+.105+n*(height-.14)/3
        m.box(x-width*.208,front-.036,z,width*.345,.058,(height-.10)*.28,"oak")
        m.box(x-width*.208,front-.071,z+.012,.087,.038,.033,"bronze")
    lancet(m,x+width*.201,front-.028,bottom+.066,width*.165,height-.13,"bronze")
    lancet(m,x+width*.201,front-.052,bottom+.103,width*.114,height-.214,"oak")
    if not crowded:
        for dx in (-width*.34,width*.34):
            caster(m,x+dx,front-.07,.17)
    return bottom+height+.049


def clamp_housing(m, x, y, z, large=False):
    spread=.149 if large else .112
    m.box(x,y,z+.026,.32 if large else .25,.27,.054,"iron")
    for sign in (-1,1):
        m.box(x+sign*spread,y+.024,z+.116,.055,.189,.166,"bronze")
    m.cylinder((x-spread,y-.018,z+.15),(x+spread,y-.018,z+.15),.022,.022,"edge",10)


def uprights(m, start, top, width, back):
    for sign in (-1,1):
        x = sign*width
        m.box(x,back,start+.042,.17,.20,.12,"iron")
        m.cylinder((x,back,start),(x,back,top),.063,.053,"iron",8)
        m.cylinder((x,back,top-.076),(x,back,top+.008),.078,.065,"bronze",8)
        m.cylinder((x,back,top),(x,back,top+.14),.066,.010,"bronze",8)
        m.cylinder((x,back-.30,start),(x,back,top-.15),.034,.031,"bronze",8)


def roof(m, width, back, ridge, side_depth, fabric):
    vertices = [
        (-width,back-side_depth,ridge-.34), (-width,back,ridge),
        (0,back-side_depth-.052,ridge-.24), (0,back,ridge+.09),
        (width,back-side_depth,ridge-.34), (width,back,ridge),
        (-width,back+.27,ridge-.31), (0,back+.31,ridge-.24), (width,back+.27,ridge-.31),
    ]
    m.add(vertices, [(0,2,3,1),(2,4,5,3),(1,3,7,6),(3,5,8,7)], fabric)
    for p,q in [(vertices[0],vertices[2]),(vertices[2],vertices[4]),(vertices[1],vertices[3]),(vertices[3],vertices[5])]:
        m.cylinder(p,q,.025,.024,"canvas_edge",6)


def crank(m, x, y, z, radius, phase):
    dx,dz = radius*math.cos(phase),radius*math.sin(phase)
    m.cylinder((x,y+.035,z),(x,y-.041,z),.057,.039,"bronze",12)
    m.cylinder((x,y-.042,z),(x+dx,y-.042,z+dz),.025,.020,"iron",8)
    m.cylinder((x+dx,y-.035,z+dz),(x+dx,y-.114,z+dz),.032,.030,"endgrain",8)


def rack(m, level, branch):
    m.sine, m.cosine = math.sin(.28), math.cos(.28)
    wide = 1.34 if level<4 else 1.47 if level<7 else 1.68
    m.box(0,.02,.076,wide,1.14,.152,"stone")
    m.box(0,.02,.16,wide*.96,1.08,.077,"edge")
    for x in (-wide*.28,0,wide*.28):
        m.box(x,-.552,.09,.018,.022,.092,"shadow")
    bench_top = cabinet(m, 0,.035,1.23 if level<7 else 1.45,.56 if level<4 else .58,level>=7)
    for x in (-.34,.30):
        clamp_housing(m,x,-.285,bench_top,level>=4)
    planks(m,.19,.224,bench_top+.06,2 if level<4 else 3,.60,.27)
    lantern(m,-.47,.043,bench_top+.015)
    if level == 1:
        # One hammer and short iron framing over the stock.
        m.cylinder((-.22,.26,bench_top+.02),(-.12,.24,bench_top+.35),.029,.027,"oak",8)
        m.box(-.12,.24,bench_top+.365,.158,.079,.064,"iron")
    elif level < 4:
        # A red oak tool rack is the first purchase, followed by a cloth awning.
        for x in (-.50,.51):
            m.cylinder((x,.35,bench_top),(x,.35,1.49),.036,.034,"bronze",8)
        m.box(0,.35,1.45,1.11,.095,.119,"oak")
        for x,lean in [(-.33,.04),(-.19,.05),(-.03,-.02),(.14,-.03),(.31,-.07)]:
            m.cylinder((x,.27,1.15),(x+lean,.27,1.43),.023,.021,"endgrain",8)
            m.box(x+lean,.255,1.41,.072,.044,.063,"iron")
        if level == 3:
            roof(m,.615,.32,1.73,.36,"wool")
            m.cylinder((-.58,.32,1.39),(-.58,.32,1.76),.037,.022,"bronze",8)
            m.cylinder((.58,.32,1.39),(.58,.32,1.76),.037,.022,"bronze",8)
    else:
        width = .62 if level<7 else .77
        top = 1.78 if level<7 else 2.02
        back = .23
        uprights(m,bench_top,top,width,back)
        m.box(0,back,top-.09,width*2+.17,.185,.19,"iron")
        m.box(0,back-.107,top-.07,width*2+.15,.046,.07,"bronze")
        # Guides constrain the lift carriage to the gantry.
        m.cylinder((-width,back-.072,top-.24),(width,back-.072,top-.24),.034,.033,"silver",10)
        if level < 7:
            m.box(-.23,back-.04,top-.283,.27,.23,.18,"bronze")
            m.cylinder((.31,.09,bench_top+.06),(.31,.09,top-.26),.03,.03,"iron",8)
        if level == 5:
            m.box(-.76,-.04,.96,.50,.43,.12,"oak")
            m.cylinder((-.91,-.10,.87),(-.53,-.10,.47),.042,.047,"iron",8)
            planks(m,-.79,.02,1.07,4,.40,.32)
            m.box(-.97,-.10,1.16,.06,.19,.37,"bronze")
        if level == 6:
            m.box(-.56,.09,1.04,.45,.26,.084,"bronze")
            m.box(-.57,.15,1.27,.174,.16,.42,"oak")
            for n in range(3):
                m.box(-.57,.042,1.14+.12*n,.14,.045,.048,"linen")
            pipe(m, ((.70,.20,1.43),(.88,.20,2.44),(.55,.20,2.36),(.08,.20,1.83)), (.083,.049),"iron")
            m.cylinder((.80,.17,1.04),(.82,.17,1.85),.059,.055,"bronze",8)
            m.cylinder((.76,.13,1.79),(.86,.13,2.03),.068,.030,"iron",8)
        if level >= 7:
            for x in (-.58,.58):
                m.box(x,-.04,.99,.41,.39,.105,"oak")
                m.cylinder((x,-.14,.91),(x*.76,-.14,.48),.06,.052,"bronze",8)
                planks(m,x,.05,1.08,3,.34,.28)
            for side in (-1,1):
                pipe(m, ((side*.80,.31,1.22),(side*.77,.31,1.77),(side*.67,.31,2.17),(side*.12,.31,2.12)), (.068,.053),"bronze")
        if level >= 8:
            m.box(.71,.10,1.53,.50,.29,.22,"iron")
            lantern(m,.84,-.06,1.68,"lantern")
            m.cylinder((.98,.045,1.39),(.98,.045,1.97),.075,.044,"bronze",10)
            if level == 8:
                m.box(1.02,.055,1.68,.28,.24,.27,"oak")
                m.cylinder((1.05,.058,1.77),(.80,.084,2.14),.07,.038,"iron",8)
        if level >= 9:
            m.box(.10,.27,2.15,1.63,.16,.102,"oak")
            for x in (-.61,0,.60):
                m.cylinder((x,.27,2.07),(x,.27,2.37),.071,.042,"bronze",10)
            if level == 9:
                planks(m,.18,.25,2.25,3,1.04,.28)
                m.box(.27,.087,2.38,.088,.049,.40,"iron")
        if level == 10:
            roof(m,1.065,.34,2.62,.52,"wool")
            for side in (-1,1):
                pipe(m, ((side*.98,.10,1.72),(side*.87,.10,2.38),(side*.31,.14,2.76),(0,.14,2.66)), (.091,.051),"iron")
                m.cylinder((side*1.15,.12,1.25),(side*.98,.12,2.41),.072,.051,"iron",8)
                m.cylinder((side*1.03,.10,2.40),(side*1.03,.10,2.61),.068,.014,"bronze",8)
            m.cylinder((0,.29,2.68),(0,.29,2.99),.080,.012,"bronze",10)
    if branch == "sustain":
        for side in (-1,1):
            x = side*(.73 if level<7 else .86)
            m.box(x,-.12,1.27,.19,.28,.42,"iron")
            lantern(m,x,-.16,1.49,"blue")
            pipe(m, ((x,-.16,1.79),(x,-.07,2.02),(x*.80,.05,1.89),(x*.57,.07,1.64)), (.046,.034),"bronze")
    elif branch == "conservation":
        # Tool trays and sorted reclaimed planks, with no powered parts.
        x = .68 if level<7 else .84
        m.box(x,-.03,1.17,.42,.36,.094,"bronze")
        planks(m,x,.012,1.28,4,.39,.29)
        m.box(x,-.245,1.22,.42,.061,.121,"linen")
        m.cylinder((x+.15,-.22,1.11),(x+.11,-.02,.73),.033,.024,"iron",8)


def motion(m, level, branch, phase):
    m.sine, m.cosine = math.sin(.28), math.cos(.28)
    # Move cranks, the lift carriage, and its hook on genuinely separate geometry.
    for side in (-1,1):
        x = -.34 if side < 0 else .30
        z = 1.01 if level<4 else 1.032
        crank(m,x+.044,-.379,z,.074 if level<4 else .108,phase*side+side*.21)
    if level < 4:
        return
    top = 1.78 if level<7 else 2.02
    slider = (.19 if level<7 else .32)*math.sin(phase)
    z = top-.43+.102*math.cos(phase)
    m.box(slider,.014,top-.21,.215,.155,.115,"bronze")
    m.cylinder((slider,-.035,top-.25),(slider,-.035,z),.018,.019,"iron",8)
    m.ring((slider,-.036,z-.056),.079,.027,"iron",(0,1,0),begin=math.pi*.44,end=math.pi*2.14,sides=16)
    if level >= 8:
        crank(m,.94,-.135,1.65,.106,-phase)
    if branch == "sustain":
        m.box(slider,-.142,top-.22,.16,.138,.077,"blue")


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    bake_atlas(OUTPUT/"base.png", PAL, BASE_COLUMNS, math.ceil(len(STATES)/BASE_COLUMNS), (
        (state % BASE_COLUMNS, state // BASE_COLUMNS, partial(rack, level=level, branch=branch))
        for state, (level, branch) in enumerate(STATES)
    ))
    bake_atlas(OUTPUT/"motion.png", PAL, MOTION_FRAMES, len(STATES), (
        (n, state, partial(motion, level=level, branch=branch, phase=math.tau*n/MOTION_FRAMES))
        for state, (level, branch) in enumerate(STATES) for n in range(MOTION_FRAMES)
    ))
