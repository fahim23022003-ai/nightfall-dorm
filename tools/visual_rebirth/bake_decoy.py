"""Bake the Decoy Beacon grave-bell shrines and separately moving ornaments.

Run from the repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_decoy.py
"""
import math
from pathlib import Path
import sys

from mathutils import Vector

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from bake_amplifier import catalog_atlases
from bake_dynamo import lancet, pipe
from bake_needle import PALETTE as METALS
from bake_relay import axis_ring

OUT = Path("assets/visual_rebirth/buildings/decoy").resolve()
STATES = [(level,"") for level in range(1,11)]
STATES += [(level,branch) for branch in ("force_lure","faint_echo") for level in range(5,11)]
PAL=METALS | {
    "wood": (.189,.104,.064,1), "edgewood": (.302,.180,.12,1),
    "burgundy": (.283,.097,.12,1), "lining": (.189,.111,.099,1),
    "copper": (.41,.262,.123,1), "gold": (.583,.399,.188,1),
    "glass": (.253,.353,.352,1), "shard": (.451,.559,.546,1), "smoke": (.079,.175,.171,1),
    "spectral": (.361,.616,.539,1), "core": (.630,.757,.573,1), "linen": (.56,.427,.278,1),
}


def stand(m,width):
    m.box(0,0,.081,width,width*.79,.162,"stone")
    m.box(0,0,.221,width*.90,width*.72,.119,"edgewood")
    m.box(0,0,.449,width*.81,width*.66,.38,"wood")
    m.box(0,0,.642,width*.88,width*.74,.092,"edgewood")
    for x in (-width*.27,0,width*.27):
        lancet(m,x,-width*.332,.265,.11,.30,"bronze")
        lancet(m,x,-width*.35,.297,.069,.24,"smoke")
    m.box(-.26,-width*.37,.54,.27,.043,.20,"burgundy")
    m.box(-.26,-width*.392,.439,.279,.022,.027,"linen")
    for x in (-width*.37,width*.37):
        m.cylinder((x,-width*.32,.19),(x,-width*.32,.62),.061,.047,"wood",8)
        m.cylinder((x,-width*.32,.595),(x,-width*.32,.692),.062,.026,"bronze",10)


def arch(m, width, y, low, high, radius, color):
    for side in (-1,1):
        x = side*width
        m.cylinder((x,y,low),(x,y,low+.31*high),radius*1.43,radius*1.12,color,10)
        m.ring((x,y,low+.29*high),radius*1.22,.027,"bronze",sides=18)
        pipe(m, ((x,y,low+.30*high),(x*1.04,y,low+.70*high),(x*.30,y,low+.91*high),(0,y,low+high)),
             (radius,.68*radius), color)
        pipe(m, ((x*.97,y-.031,low+.31*high),(x*.98,y-.031,low+.70*high),(x*.30,y-.031,low+.89*high),(0,y-.031,low+high)),
             (.027,.018),"bronze")
    top = low+high
    m.cylinder((0,y,top-.04),(0,y,top+.17),radius*1.20,.017,"bronze",10)


def mirror(m, x,y,z,radius,yaw=0):
    normal = Vector((math.sin(yaw),-math.cos(yaw),.07)).normalized()
    side=normal.cross(Vector((0,0,1))).normalized()
    up=normal.cross(side)
    center=Vector((x,y,z))
    mid=center+normal*.033
    m.cylinder(center-normal*.014,mid,radius,radius,"smoke",24)
    m.cylinder(mid,mid+normal*.021,radius*.88,radius*.86,"glass",24)
    axis_ring(m,mid+normal*.030,normal,radius*.965,.026,"bronze",24)
    # Segment cracks as narrow slivers on the glass instead of painted symbols.
    junction=mid+normal*.028+side*.10*radius
    crack_points = [(-.79,.25),(-.42,-.72),(.47,-.67),(.72,.49),(.10,.76)]
    for n,(h,v) in enumerate(crack_points):
        split=junction+side*h*radius*.41+up*(v+(.18 if n%2 else -.17))*radius*.44
        tip=junction+side*h*radius+up*v*radius
        m.cylinder(junction,split,.007,.006,"shard",6)
        m.cylinder(split,tip,.006,.004,"shard",6)
    for n in range(6):
        a=n*math.tau/6+.4
        p=mid+normal*.033+(side*math.cos(a)+up*math.sin(a))*radius*.955
        m.cylinder(p,p+normal*.034,.018,.013,"gold",7)


def bell(m,pivot,height,radius,tilt):
    top=Vector(pivot)
    down=Vector((math.sin(tilt),0,-math.cos(tilt)))
    m.cylinder(top,top+down*.124,radius*.17,radius*.16,"bronze",12)
    # Open skirt and dark recessed interior with a real swing pivot.
    plane=down.cross(Vector((0,1,0))).normalized()
    other=down.cross(plane)
    profiles=[(.14,.43),(.25,.67),(.56,.77),(.78,.9),(1,1.0),(1,.86),(.80,.72)]
    vertices=[]
    sectors=28
    for row,r in profiles:
        for n in range(sectors):
            a=n*math.tau/sectors
            vertices.append(top+down*height*row+(plane*math.cos(a)+other*math.sin(a))*r*radius)
    for row in range(len(profiles)-1):
        faces=[]
        for n in range(sectors):
            a=row*sectors+n
            b=row*sectors+(n+1)%sectors
            faces.append((a,b,b+sectors,a+sectors))
        m.add(vertices,faces,"smoke" if row>=5 else ("gold" if row==4 else "copper"),True)
    end=top+down*(height+.045)
    m.cylinder(top+down*height*.68,end,radius*.066,radius*.059,"iron",8)
    m.cylinder(end,end+down*.051,radius*.15,radius*.108,"gold",10)


def lantern_base(m,x,y,z,r):
    m.cylinder((x,y,z),(x,y,z+.060),r*1.30,r*1.04,"bronze",18)
    m.cylinder((x,y,z+.06),(x,y,z+.117),r,r*.78,"smoke",18)
    m.ring((x,y,z+.105),r*.89,.020,"gold",sides=20)
    m.cylinder((x,y,z+.113),(x,y,z+.134),r*.70,r*.69,"spectral",16)


def chassis(m, level, branch):
    m.sine,m.cosine=math.sin(.21),math.cos(.21)
    stand(m,1.29 if level<4 else 1.44 if level<7 else 1.56)
    lantern_base(m,.10,-.14,.697,.23 if level<4 else .28)
    if level<4:
        arch(m,.40,.27,.681,1.02,.067,"wood")
        m.cylinder((-.43,.09,.70),(-.42,.09,1.07),.063,.045,"bronze",8)
        if level>=2:
            m.cylinder((.52,.18,.73),(.56,.18,1.72),.056,.042,"edgewood",8)
            pipe(m, ((.56,.18,1.58),(.76,.13,1.83),(.92,.06,1.72),(.87,.035,1.53)), (.051,.029),"bronze")
        if level==3:
            m.cylinder((-.61,.27,.71),(-.66,.27,1.99),.065,.042,"wood",8)
            m.cylinder((-.66,.27,1.96),(-.66,.27,2.13),.070,.018,"bronze",10)
            m.cylinder((-.65,.24,1.76),(-.48,.24,1.77),.06,.043,"edgewood",8)
            lantern_base(m,-.63,.13,.98,.14)
        return
    if level<7:
        arch(m,.59,.30,.72,1.33,.081,"wood")
        m.ring((-.08,.13,1.29),.318,.041,"bronze",(0,1,0),sides=25)
        m.ring((-.08,.12,1.29),.272,.016,"gold",(0,1,0),sides=22)
        for x in (-.37,.23):
            m.cylinder((x,.15,.73),(x,.15,1.25),.045,.039,"bronze",8)
        m.cylinder((-.39,.09,1.28),(.25,.09,1.28),.039,.033,"bronze",10)
        if level==5:
            m.cylinder((.77,.16,.71),(.89,.16,1.39),.103,.079,"wood",8)
            lantern_base(m,.91,.10,1.39,.16)
            pipe(m, ((.57,.17,1.34),(.81,.16,1.58),(.91,.10,1.98),(.80,.06,1.87)), (.072,.040),"bronze")
        if level==6:
            arch(m,.29,.23,1.27,.95,.051,"bronze")
            m.cylinder((-.83,.11,.7),(-.92,.13,1.56),.078,.041,"wood",8)
            lantern_base(m,-.95,.09,1.56,.143)
            mirror(m,-.86,.108,1.80,.19,.29)
    else:
        for side in (-1,1):
            x=side*.64
            m.cylinder((x,.24,.72),(x,.24,1.75),.104,.070,"wood",8)
            m.cylinder((x,.21,1.71),(x,.21,2.12),.074,.041,"bronze",10)
            pipe(m, ((x,.26,1.40),(x,.23,1.95),(side*.43,.29,2.47),(0,.29,2.37)), (.083,.039),"bronze")
            m.cylinder((x,.18,.76),(x,.18,1.12),.108,.085,"edgewood",10)
        m.cylinder((0,.19,.80),(0,.19,1.63),.184,.13,"wood",12)
        m.cylinder((0,.17,1.48),(0,.17,1.70),.168,.104,"bronze",14)
        m.ring((0,.05,1.39),.34,.042,"iron",(0,1,0),sides=24)
        lantern_base(m,0,-.29,1.13,.195)
        if level>=8:
            m.cylinder((-.81,.09,.74),(-.99,.09,1.64),.071,.049,"edgewood",8)
            lantern_base(m,-1.02,.069,1.62,.158)
            if level==8:
                m.cylinder((-1.0,.09,1.66),(-1.02,.11,2.10),.066,.020,"bronze",8)
                pipe(m, ((-.95,.13,1.58),(-1.29,.11,1.70),(-1.25,.11,2.04),(-.95,.13,2.06)), (.056,.032),"copper")
        if level>=9:
            m.cylinder((.88,.15,.76),(1.00,.15,1.76),.086,.051,"wood",8)
            mirror(m,.99,.115,1.91,.196,-.36)
            m.cylinder((0,.31,2.27),(0,.31,2.70),.083,.019,"bronze",10)
        if level==10:
            arch(m,.936,.35,.74,1.96,.095,"edgewood")
            for side in (-1,1):
                m.cylinder((side*.93,.19,1.43),(side*1.02,.19,2.34),.089,.053,"wood",8)
                m.cylinder((side*1.02,.19,2.34),(side*1.02,.19,2.57),.081,.018,"bronze",10)
            mirror(m,0,.26,2.50,.20,.06)
    if branch=="force_lure":
        for side in (-1,1):
            x = side*.85
            m.cylinder((x,-.17,.69),(x,-.17,1.50),.095,.063,"bronze",8)
            m.ring((x,-.17,1.47),.133,.038,"copper",sides=16)
        pipe(m, ((-.85,-.13,1.13),(-.86,-.19,1.61),(.86,-.19,1.66),(.85,-.13,1.08)), (.057,.041),"copper")
    elif branch=="faint_echo":
        m.box(-.78,-.065,.91,.44,.32,.119,"lining")
        m.cylinder((-.95,.024,.93),(-1,.024,1.23),.051,.044,"bronze",8)
        mirror(m,-1.03,-.023,1.39,.219,.31)
        mirror(m,-.92,.081,1.68,.133,-.39)
        m.box(-.84,-.245,.94,.42,.087,.152,"burgundy")


def motion(m,level,branch,phase):
    m.sine,m.cosine=math.sin(.21),math.cos(.21)
    if level<4:
        bell(m,(.0,.21,1.565),.44,.199,.23*math.sin(phase))
        mirror(m,-.43,-.128,1.098,.207,.12+.13*math.sin(phase))
        if level>=2:
            bell(m,(.85,.083,1.575),.287,.121,.26*math.sin(phase+.78))
    elif level<7:
        bell(m,(0,.24,1.845),.38,.164,.22*math.sin(phase))
        mirror(m,-.082,.02,1.255,.235,.48*math.sin(phase))
        if level==5:
            bell(m,(.804,.062,1.91),.36,.135,.22*math.cos(phase))
        if level==6:
            bell(m,(-.48,.09,1.985),.29,.129,.29*math.cos(phase))
    else:
        bell(m,(0,.18,2.225 if level<10 else 2.37),.39,.18,.248*math.sin(phase))
        for side in (-1,1):
            x=side*.69
            mirror(m,x,.059,1.50 if level<10 else 1.69,.218 if level<10 else .246,
                   side*.30+.31*math.sin(phase+side))
        if level>=8:
            mirror(m,-1.02,.01,1.84,.139,.27*math.cos(phase))
    height=.878+.05*math.sin(phase)
    m.cylinder((.10,-.16,height-.060),(.10,-.16,height+.055),.074,.037,"spectral",8)
    m.cylinder((.10,-.16,height-.009),(.10,-.16,height+.031),.052,.027,"core",8)
    if branch=="force_lure":
        for side in (-1,1):
            bell(m,(side*.84,-.245,1.478),.292,.134,.32*math.sin(phase+side))


if __name__=="__main__":
    catalog_atlases(OUT,PAL,STATES,chassis,motion)
