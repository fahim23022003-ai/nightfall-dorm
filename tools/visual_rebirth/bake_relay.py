"""Author and bake original Target Relay survey instruments.

Run from repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_relay.py
"""
import math
from pathlib import Path
import sys

from mathutils import Vector

sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parent))
from bake_amplifier import catalog_atlases
from bake_dynamo import pipe, lancet
from bake_needle import PALETTE as METALS

OUT = Path("assets/visual_rebirth/buildings/enhancer").resolve()
STATES = [(level,"") for level in range(1,11)]
STATES += [(level,branch) for branch in ("ballistic","coolant") for level in range(5,11)]
PAL = METALS | {
    "wood": (.202,.108,.064,1), "redcloth": (.296,.102,.085,1), "parchment": (.54,.412,.243,1),
    "lens": (.126,.361,.363,1), "depth": (.065,.158,.177,1), "glint": (.43,.63,.594,1),
    "cold": (.22,.38,.48,1), "insulator": (.51,.519,.46,1), "inlay": (.49,.313,.155,1),
}


def pedestal(m,width):
    m.box(0,0,.084,width,width*.82,.168,"stone")
    m.box(0,0,.205,width*.9,width*.74,.092,"edge")
    m.box(0,0,.417,width*.83,width*.70,.35,"wood")
    m.box(0,0,.59,width*.92,width*.78,.097,"iron")
    for x in (-width*.24,0,width*.24):
        lancet(m,x,-width*.35,.245,.11,.295,"shadow")
        lancet(m,x,-width*.363,.28,.069,.228,"inlay")
    m.box(.32,-width*.375,.426,.29,.04,.30,"redcloth")
    m.box(.32,-width*.392,.295,.30,.032,.037,"parchment")
    for x in (-width*.394,width*.394):
        m.cylinder((x,-width*.31,.236),(x,-width*.31,.63),.063,.047,"bronze",10)
        m.cylinder((x,-width*.31,.625),(x,-width*.31,.719),.069,.025,"bronze",10)


def socket(m,x,y,floor,top,radius):
    m.cylinder((x,y,floor),(x,y,floor+.07),radius*1.08,radius*1.02,"bronze",20)
    m.cylinder((x,y,floor+.06),(x,y,top-.045),radius*.91,radius*.79,"iron",20)
    m.cylinder((x,y,top-.094),(x,y,top+.02),radius*.94,radius*.82,"bronze",24)
    for j,z in enumerate((floor+.031,top-.05)):
        m.ring((x,y,z),radius*(1 if j==0 else .86),.015,"gold",sides=22)
    for sign in (-1,1):
        m.cylinder((x+sign*radius*.66,y,top-.048),(x+sign*radius*.81,y,top+.185),.038,.042,"bronze",10)


def axis_ring(m,point,axis,radius,thickness,color,n=26):
    direction = Vector(axis).normalized()
    radial = direction.cross(Vector((0,0,1))).normalized()
    up = direction.cross(radial)
    vertices=[]
    for i in range(n):
        a=i*math.tau/n
        rim=radial*math.cos(a)+up*math.sin(a)
        for j in range(8):
            angle=j*math.tau/8
            vertices.append(Vector(point)+rim*(radius+thickness*math.cos(angle))+direction*(thickness*math.sin(angle)))
    faces=[]
    for i in range(n):
        for j in range(8):
            faces.append((i*8+j,((i+1)%n)*8+j,((i+1)%n)*8+(j+1)%8,i*8+(j+1)%8))
    m.add(vertices,faces,color,True)


def telescope(m, center, yaw, length, lens_radius, color):
    """Brass optical tube with a distinct eyecup and recessed objective lens."""
    center = Vector(center)
    direct = Vector((math.cos(yaw), math.sin(yaw), .37)).normalized()
    rear = center-direct*length*.38
    front = center+direct*length*.64
    def dist(amount):
        return rear.lerp(front,amount)
    m.cylinder(rear,dist(.56),lens_radius*.44,lens_radius*.53,"iron",16)
    m.cylinder(dist(.45),dist(.90),lens_radius*.55,lens_radius*.87,color,20)
    m.cylinder(dist(.87),front,lens_radius*.91,lens_radius*.99,"bronze",24)
    for t,r in ((.08,.47),(.42,.56),(.69,.74),(.90,1.02),(1,1.03)):
        axis_ring(m,dist(t),direct,lens_radius*r,.015 if length<.8 else .024,"gold")
    # The optical face is broad and closed; no emitter, barrel bore or firing effect.
    m.cylinder(front-direct*.021,front+direct*.027,lens_radius*.82,lens_radius*.73,"depth",24)
    m.cylinder(front+direct*.024,front+direct*.039,lens_radius*.70,lens_radius*.53,"lens",24)
    highlight=direct.cross(Vector((0,0,1))).normalized()*lens_radius*.23
    m.cylinder(front+direct*.038+highlight,front+direct*.042+highlight,lens_radius*.176,lens_radius*.112,"glint",10)
    m.cylinder(rear-direct*.084,rear,lens_radius*.39,lens_radius*.35,"bronze",12)
    axis_ring(m,rear-direct*.071,direct,lens_radius*.36,.013,"shadow",18)


def ring_gauge(m,x,y,z,radius):
    m.cylinder((x,y+.02,z),(x,y-.04,z),radius*1.04,radius*1.03,"bronze",20)
    m.cylinder((x,y-.037,z),(x,y-.065,z),radius*.93,radius*.77,"parchment",20)
    axis_ring(m,(x,y-.075,z),(0,-1,0),radius*.82,.013,"gold",20)
    for j in range(8):
        a=j*math.tau/8
        m.cylinder((x+radius*.63*math.cos(a),y-.076,z+radius*.63*math.sin(a)),
                   (x+radius*.72*math.cos(a),y-.076,z+radius*.72*math.sin(a)),.006,.007,"shadow",6)
    m.cylinder((x,y-.082,z),(x+radius*.47,y-.082,z+radius*.39),.013,.009,"shadow",7)


def map_desk(m,x,y,z,width):
    m.box(x,y,z,width,.34,.135,"wood")
    m.box(x,y-.025,z+.070,width*.89,.23,.028,"parchment")
    m.box(x,y-.125,z+.085,width*.88,.025,.046,"bronze")
    m.box(x,y+.09,z+.108,width*.81,.115,.049,"iron")
    ring_gauge(m,x,y-.218,z+.048,min(.139,width*.19))


def base(m,level,branch):
    m.sine,m.cosine=math.sin(-.12),math.cos(-.12)
    pedestal(m,1.30 if level<4 else 1.45 if level<7 else 1.58)
    if level<4:
        socket(m,-.075,.06,.62,1.16,.23)
        map_desk(m,.41,-.28,.70,.37)
        m.cylinder((-.50,.27,.60),(-.50,.27,1.39),.048,.041,"bronze",9)
        if level>=2:
            socket(m,-.55,.05,.62,1.34,.135)
            m.cylinder((-.55,.08,1.49),(-.55,.08,1.67),.05,.02,"gold",10)
        if level==3:
            m.box(.68,.19,.92,.29,.30,.22,"wood")
            ring_gauge(m,.68,.003,1.03,.199)
            m.cylinder((.68,.17,1.02),(.69,.17,1.43),.065,.041,"bronze",10)
            m.cylinder((.69,.17,1.42),(.75,.17,1.61),.062,.019,"bronze",10)
        return
    if level<7:
        socket(m,.19,.01,.62,1.30,.30)
        m.cylinder((-.52,.22,.64),(-.49,.22,1.43),.103,.077,"iron",10)
        m.cylinder((-.49,.22,1.41),(-.23,.22,1.91),.076,.061,"bronze",12)
        m.cylinder((-.23,.22,1.91),(.15,.11,1.70),.067,.06,"bronze",12)
        for x,y,z in ((-.49,.22,1.43),(-.23,.22,1.91),(.15,.11,1.70)):
            axis_ring(m,(x,y-.034,z),(0,1,0),.095,.018,"gold",18)
        map_desk(m,.39,-.40,.735,.53)
        if level>=5:
            m.box(-.84,-.18,.89,.40,.31,.188,"iron")
            ring_gauge(m,-.92,-.351,1.13,.253)
            m.cylinder((-.88,-.15,.88),(-.89,-.15,1.27),.063,.048,"bronze",10)
        if level==6:
            pipe(m, ((.24,.08,1.23),(.79,.14,1.31),(1.01,.11,2.22),(.61,.11,2.25)), (.098,.065),"bronze")
            ring_gauge(m,.96,.033,1.66,.201)
            m.cylinder((.90,.16,1.60),(1.02,.16,2.16),.082,.034,"iron",10)
    else:
        for side in (-1,1):
            x=side*.53
            socket(m,x,.19,.62,1.40 if level<10 else 1.63,.192)
            m.cylinder((x,.21,1.47),(x,.21,1.84),.041,.033,"iron",9)
            pipe(m, ((side*.75,.15,1.08),(side*.76,.18,2.26),(side*.43,.20,2.28),(side*.15,.21,2.14)), (.076,.049),"bronze")
        socket(m,0,-.10,.62,1.16,.297)
        map_desk(m,0,-.44,.73,.64)
        m.cylinder((-.54,.23,1.28),(.54,.23,1.28),.035,.035,"bronze",10)
        if level>=8:
            ring_gauge(m,-.79,-.037,1.35,.231)
            m.cylinder((-.86,.111,1.01),(-.94,.111,1.76),.071,.044,"bronze",12)
            if level==8:
                m.box(-1.00,.113,1.68,.29,.233,.25,"iron")
                m.cylinder((-1.06,.083,1.77),(-1.07,.083,2.05),.073,.028,"bronze",8)
        if level>=9:
            m.cylinder((0,.24,1.45),(0,.24,2.48),.095,.061,"bronze",12)
            m.cylinder((0,.24,2.38),(0,.24,2.57),.072,.019,"gold",10)
            axis_ring(m,(0,.151,2.19),(0,1,0),.27,.042,"bronze",26)
        if level==10:
            for sign in (-1,1):
                pipe(m, ((sign*.89,.27,1.24),(sign*.94,.28,2.33),(sign*.57,.28,2.86),(0,.30,2.67)), (.107,.05),"iron")
                m.cylinder((sign*.55,.31,2.08),(sign*.56,.31,2.56),.077,.036,"bronze",9)
            m.cylinder((0,.294,2.65),(0,.294,2.97),.095,.019,"bronze",10)
    if branch=="ballistic":
        map_desk(m,-.75,-.35,.93,.56)
        ring_gauge(m,-.77,-.43,1.16,.218)
        m.cylinder((-.79,-.34,1.10),(-.82,-.34,1.52),.05,.025,"gold",10)
    elif branch=="coolant":
        for x in (-.70,.70):
            m.cylinder((x,.06,.73),(x,.06,1.30),.112,.094,"cold",12)
            for n in range(5):
                m.ring((x,.06,.78+n*.104),.108,.027,"insulator",sides=16)
            m.cylinder((x,.06,1.24),(x,.06,1.39),.105,.039,"bronze",10)
        pipe(m, ((-.70,.06,1.36),(-.58,.10,1.76),(.61,.09,1.75),(.70,.06,1.36)), (.051,.035),"cold")


def optics(m,level,branch,phase):
    m.sine,m.cosine=math.sin(-.12),math.cos(-.12)
    yaw=-.67+.26*math.sin(phase)
    variant_lens = "bronze" if branch=="ballistic" else "cold" if branch=="coolant" else "inlay"
    if level<4:
        telescope(m,(-.04,.08,1.37),yaw,.99,.182,variant_lens)
        if level>=2:
            telescope(m,(-.55,.05,1.43),-1.30+.21*math.cos(phase+.5),.65,.104,"bronze")
        return
    if level<7:
        telescope(m,(.11,.10,1.68),yaw,1.14,.219,variant_lens)
        telescope(m,(-.28,.12,2.02),-1.21+.28*math.cos(phase),.77,.117,"bronze")
        return
    telescope(m,(0,-.10,1.39),yaw,1.08 if level<10 else 1.25,.221 if level<10 else .264,variant_lens)
    for side in (-1,1):
        telescope(m,(side*.47,.12,1.85 if level<10 else 2.06),side*.42-1.33+.27*math.cos(phase+side),.84,.148,"bronze")
    if level>=8:
        n=Vector((math.cos(phase),math.sin(phase),.21))
        axis_ring(m,(-.98,.127,1.89),n,.170,.024,"gold",24)
    if level>=9:
        telescope(m,(0,.16,2.20 if level<10 else 2.48),-1.18+.29*math.cos(phase),.65,.131,"inlay")


if __name__=="__main__":
    catalog_atlases(OUT,PAL,STATES,base,optics)
