"""Author and bake indexed Dream Amplifier chassis and motion atlases.

Run from repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_amplifier.py
"""
from functools import partial
import math
from pathlib import Path
import sys

from mathutils import Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, MOTION_FRAMES, bake_atlas, pipe, lancet
from bake_needle import PALETTE as METALS

OUT = Path("assets/visual_rebirth/buildings/economy").resolve()
STATES = [(level,"") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("dividend", "capacitive") for level in range(5, 11)]
PAL = METALS | {
    "wood": (.19,.092,.061,1), "endgrain": (.36,.197,.115,1), "copper": (.45,.23,.102,1),
    "velvet": (.26,.106,.211,1), "wine": (.209,.115,.115,1), "resonator": (.36,.207,.124,1),
    "amethyst": (.38,.188,.563,1), "quartz": (.685,.430,.832,1), "violet": (.235,.101,.39,1),
    "parchment": (.58,.452,.285,1), "conductive": (.245,.465,.447,1),
}


def catalog_atlases(path, palette, states, housing, motion):
    """Bake a support family with matching level and branch order across layers."""
    path.mkdir(exist_ok=True, parents=True)
    bake_atlas(path/"base.png", palette, BASE_COLUMNS, math.ceil(len(states)/BASE_COLUMNS), (
        (state%BASE_COLUMNS, state//BASE_COLUMNS, partial(housing, level=level, branch=branch))
        for state, (level, branch) in enumerate(states)
    ))
    bake_atlas(path/"motion.png", palette, MOTION_FRAMES, len(states), (
        (frame,state,partial(motion, level=level, branch=branch, phase=math.tau*frame/MOTION_FRAMES))
        for state,(level,branch) in enumerate(states) for frame in range(MOTION_FRAMES)
    ))


def horn(m, neck, lip, size, color="resonator"):
    """Fabricate a hollow metal flare with ridged bell petals and a real cavity."""
    origin, mouth = Vector(neck), Vector(lip)
    axis = (mouth-origin).normalized()
    u = axis.cross(Vector((0,0,1))).normalized()
    v = axis.cross(u)
    n, profile = 32, [(0,.039),(.25,.053),(.55,.095),(.76,.19),(1,size)]
    vertices = []
    for interior in (False,True):
        for t,r in profile:
            for k in range(n):
                a=k*math.tau/n
                radial=r*(1+.07*t*math.cos(a*8))-(.023 if interior else 0)
                vertices.append(mouth.lerp(origin,1-t)+(u*math.cos(a)+v*math.sin(a))*radial-axis*(.015 if interior else 0))
    for interior in (False, True):
        first = n*len(profile) if interior else 0
        faces = []
        for step in range(len(profile)-1):
            for k in range(n):
                a=first+step*n+k
                b=first+step*n+(k+1)%n
                f=(a,b,b+n,a+n)
                faces.append(f if interior else tuple(reversed(f)))
        m.add(vertices,faces,"wine" if interior else color,True)
    first=n*(len(profile)-1)
    inner=n*len(profile)+first
    faces=[(first+k,first+(k+1)%n,inner+(k+1)%n,inner+k) for k in range(n)]
    m.add(vertices,faces,"gold",True)
    for i in range(8):
        a=i*math.tau/8
        previous=None
        for t, radius in profile[1:]:
            highlight=origin.lerp(mouth,t) + (u*math.cos(a)+v*math.sin(a))*(radius*(1+.07*t)-.015)
            if previous is not None:
                m.cylinder(previous,highlight,.010,.008,"bronze",6)
            previous=highlight
    m.cylinder(origin-axis*.09,origin+axis*.06,.065,.060,"bronze",14)


def gemstone(m, x, y, z, r, height, twist=0):
    vertices = [(x,y,z-height*.40)]
    for h, radius in ((-.22,r),(.23,r*.81)):
        for n in range(6):
            angle=n*math.tau/6+twist
            vertices.append((x+radius*math.cos(angle), y+radius*math.sin(angle),z+h*height))
    vertices.append((x,y,z+height*.63))
    for n in range(6):
        a=1+n
        b=1+(n+1)%6
        m.add(vertices,[(0,b,a),(a,b,b+6,a+6),(a+6,b+6,13)],["amethyst","quartz","violet"][n%3])


def cabinet(m, width, radius):
    m.box(0,0,.076,width,width*.84,.152,"stone")
    m.box(0,0,.205,width*.9,width*.77,.106,"endgrain")
    m.box(0,0,.439,width*.78,width*.68,.44,"wood")
    for x in (-width*.23,0,width*.23):
        lancet(m,x,-width*.348,.271,.089,.29,"bronze")
        lancet(m,x,-width*.368,.312,.052,.213,"amethyst")
    m.box(0,-width*.31,.651,width*.89,.128,.107,"endgrain")
    m.box(0,0,.68,width*.91,width*.75,.08,"wood")
    m.box(-.25,-width*.368,.54,.31,.035,.269,"velvet")
    m.box(-.25,-width*.385,.429,.32,.026,.033,"parchment")
    for x in (-width*.40,width*.4):
        m.cylinder((x,-width*.29,.24),(x,-width*.29,.64),.063,.05,"bronze",8)
    m.cylinder((0,.07,.704),(0,.07,.781),radius*1.17,radius*1.04,"bronze",20)


def cradle(m, x, y, z, radius, height):
    m.cylinder((x,y,z-.04),(x,y,z+.041),radius*1.12,radius,"bronze",16)
    m.ring((x,y,z+.045),radius*.91,.020,"gold",sides=22)
    m.ring((x,y,z+height),radius*.73,.026,"bronze",sides=22)
    for n in range(6):
        a=n*math.tau/6
        dx,dy=math.cos(a)*radius,math.sin(a)*radius
        m.cylinder((x+dx,y+dy,z+.024),(x+dx*.72,y+dy*.72,z+height),.021,.019,"bronze",8)
    m.cylinder((x,y,z+height-.018),(x,y,z+height+.13),radius*.39,.027,"bronze",10)


def ring_setup(m,x,y,z,r):
    m.ring((x,y,z),r,.033,"bronze",(0,1,0),sides=22)
    m.ring((x,y-.022,z),r*.92,.016,"velvet",(0,1,0),sides=22)
    for n in range(5):
        a=n*math.tau/5
        b=a+math.tau*2/5
        m.cylinder((x+math.cos(a)*r,y,z+math.sin(a)*r),(x+math.cos(b)*r,y,z+math.sin(b)*r),.010,.010,"gold",6)


def support(m, level, branch):
    m.sine,m.cosine = math.sin(.18),math.cos(.18)
    width=1.24 if level<4 else 1.39 if level<7 else 1.55
    cabinet(m,width,.26 if level<4 else .33)
    if level<4:
        pipe(m, ((.04,.13,.78),(.10,.06,1.32),(-.02,-.03,1.34),(-.22,-.18,1.34)), (.066,.063),"bronze")
        horn(m,(-.22,-.18,1.34),(-.44,-.59,1.49),.36)
        cradle(m,.13,.13,.77,.232,.33)
        if level>=2:
            pipe(m, ((.20,.11,.79),(.46,.11,1.34),(.54,.00,1.31),(.57,-.09,1.23)), (.052,.045),"copper")
            horn(m,(.58,-.10,1.23),(.70,-.40,1.30),.247)
        if level==3:
            x,y = .47,.18
            m.cylinder((x,y,.79),(x,y,1.82),.044,.040,"bronze",8)
            pipe(m, ((x,y,1.74),(.65,y,1.99),(.86,y,1.94),(.86,y,1.65)), (.062,.037),"bronze")
            ring_setup(m,.84,y,1.49,.16)
        return
    if level<7:
        for side in (-1,1):
            x=side*.53
            pipe(m, ((x,.11,.77),(x,.14,1.41),(x,.23,2.12),(side*.21,.22,2.04)), (.068,.032),"bronze")
            horn(m,(x,.06,1.35),(x*1.30,-.41,1.48),.292)
        m.cylinder((0,.22,2.0),(0,.22,2.15),.093,.021,"bronze",10)
        cradle(m,0,-.012,.89,.307,.61)
        if level==5:
            # Low external bell cradle brings the new vessel outside the old contour.
            cradle(m,-.88,.09,.84,.171,.54)
            m.cylinder((-.88,.19,1.37),(-.90,.19,1.78),.058,.022,"bronze",10)
            pipe(m, ((-.88,.09,1.39),(-1.02,.14,1.81),(-.69,.11,1.95),(-.48,.03,1.61)), (.060,.031),"copper")
        if level==6:
            horn(m,(.25,.25,1.89),(.53,-.21,1.95),.214)
            pipe(m, ((.55,.14,.90),(.81,.14,1.13),(.71,.14,1.73),(.22,.22,1.93)), (.054,.035),"bronze")
    else:
        for side in (-1,1):
            x=side*.59
            pipe(m, ((x,.16,.72),(side*.96,.16,1.76),(side*.78,.14,2.52),(side*.24,.18,2.37)), (.085,.048),"bronze")
            horn(m,(x,.02,1.40),(x*1.26,-.37,1.53),.29)
            ring_setup(m,x,.116,1.93,.228)
        cradle(m,0,-.09,.84,.33,.78)
        m.cylinder((-.51,.17,1.95),(.51,.17,1.95),.041,.041,"velvet",12)
        if level>=8:
            cradle(m,.65,.31,.99,.166,.38)
            if level==8:
                horn(m,(-.54,.29,1.98),(-.98,-.14,2.17),.244)
                ring_setup(m,.91,.17,1.36,.143)
        if level>=9:
            pipe(m, ((-.68,.21,2.02),(-.58,.22,2.96),(.54,.22,2.96),(.68,.21,2.02)), (.065,.040),"copper")
            for x in (-.40,0,.40):
                top = (2.85 if x==0 else 2.70) if level==9 else 2.62
                m.cylinder((x,.22,2.40),(x,.22,top),.054,.016,"gold",8)
        if level==10:
            for side in (-1,1):
                pipe(m, ((side*.70,.28,.74),(side*1.13,.25,1.75),(side*.86,.25,2.88),(0,.29,2.69)), (.104,.039),"bronze")
                horn(m,(side*.32,.31,2.12),(side*.64,-.08,2.40),.29)
            m.cylinder((0,.24,2.47),(0,.24,2.94),.11,.015,"bronze",12)
            ring_setup(m,0,.148,2.28,.246)
    if branch=="dividend":
        m.box(-.78,-.30,.85,.55,.41,.086,"copper")
        for n in range(4):
            m.box(-.88+n*.029,-.32,.94+n*.094,.35,.29,.079,"parchment")
            m.box(-.88+n*.029,-.47,.94+n*.094,.36,.031,.083,"velvet")
        pipe(m, ((-.82,-.19,1.13),(-.91,-.11,1.53),(-.62,-.08,1.63),(-.54,-.06,1.42)), (.048,.033),"gold")
    elif branch=="capacitive":
        for side in (-1,1):
            x=side*.82
            m.cylinder((x,-.12,.74),(x,-.12,1.35),.086,.074,"conductive",16)
            for n in range(6):
                m.ring((x,-.12,.82+n*.091),.09,.023,"copper",sides=16)
            m.cylinder((x,-.12,1.30),(x,-.12,1.46),.07,.026,"conductive",10)
        pipe(m, ((-.82,-.12,1.41),(-.67,-.09,1.99),(.67,-.09,1.99),(.82,-.12,1.41)), (.042,.032),"copper")


def ornaments(m, level, branch, phase):
    m.sine,m.cosine = math.sin(.18),math.cos(.18)
    if level<4:
        gemstone(m,.13,-.055,.96+.036*math.sin(phase),.119,.237,phase)
        if level==3:
            gemstone(m,.84,.11,1.47,.069,.182,phase)
        return
    gemstone(m,0,-.247,1.16+.06*math.sin(phase),.166 if level<7 else .187,.442,phase)
    if level==5:
        gemstone(m,-.88,.02,1.11+.039*math.cos(phase),.101,.27,-phase)
    if level>=7:
        for side in (-1,1):
            x = side*.59+side*.047*math.sin(phase)
            top = 1.9+.047*math.cos(phase)
            m.cylinder((side*.59,.056,1.94),(x,-.014,top-.144),.012,.011,"gold",6)
            gemstone(m,x,-.020,top-.234,.085,.229,phase*side)
    if level>=8:
        gemstone(m,.65,.158,1.19+.048*math.sin(phase),.079,.144,-phase)
    if level==10:
        gemstone(m,0,.047,2.28,.131,.242,phase)
    if branch=="capacitive":
        gemstone(m,.83,-.217,1.322,.071,.14,phase)


if __name__ == "__main__":
    catalog_atlases(OUT,PAL,STATES,support,ornaments)
