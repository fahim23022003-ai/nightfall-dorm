"""Bake model-derived Auto Repair Station chassis and mechanical working poses.

Run from the repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_auto_repair.py
"""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_amplifier import catalog_atlases
from bake_dynamo import lancet, pipe
from bake_repair import PAL as REPAIR, clamp_housing, lantern, planks
from bake_relay import axis_ring

OUT = Path("assets/visual_rebirth/buildings/auto_repair").resolve()
STATES = [(level, "") for level in range(1,11)]
STATES += [(level, branch) for branch in ("efficient_mending","emergency_protocol") for level in range(5,11)]
PALETTE = REPAIR | {
    "copper": (.44,.25,.11,1), "actuator": (.51,.361,.177,1), "lining": (.32,.201,.109,1),
    "parchment": (.54,.412,.243,1), "depth": (.065,.158,.177,1), "warm_jewel": (.68,.325,.091,1),
    "jewel": (.13,.454,.509,1), "glint": (.42,.71,.62,1),
}


def wood_fixture(m,x,y,z,width,height):
    m.box(x,y,z,width,.139,height,"oak")
    m.box(x,y-.082,z+.03,width*.85,.05,height*.68,"wood_shadow")
    m.box(x,y-.112,z+height*.40,width*.98,.036,.045,"bronze")
    m.box(x,y-.12,z-height*.40,width*.97,.036,.049,"endgrain")
    for side in (-1,1):
        m.cylinder((x+side*width*.346,y-.102,z),(x+side*width*.346,y-.14,z),.021,.026,"bronze",8)


def controller(m,x,y,z,radius,tint="jewel"):
    m.cylinder((x,y+.03,z),(x,y-.064,z),radius*1.15,radius*1.01,"bronze",16)
    m.cylinder((x,y-.061,z),(x,y-.106,z),radius*.89,radius*.78,"iron",18)
    m.ring((x,y-.109,z),radius*.67,.019,"gold",(0,1,0),sides=20)
    m.cylinder((x,y-.105,z),(x,y-.125,z),radius*.61,radius*.59,tint,14)
    m.ring((x,y-.132,z),radius*.38,.012,"glint",(0,1,0),sides=14)
    for j in range(6):
        a=j*math.tau/6
        m.cylinder((x,y-.134,z),
                   (x+math.cos(a)*radius*.52,y-.134,z+math.sin(a)*radius*.52),.009,.005,"glint",6)


def mounts(level):
    offsets=[(-.56,-.13),(.53,.05)]
    if level>=2:
        offsets.append((.70,-.33))
    if level>=3:
        offsets.append((-.62,.37))
    if level>=7:
        offsets=[(-.70,-.17),(.69,.03),(.71,-.35),(-.69,.40)]
    return offsets


def tall_frame(m,pad_height,level,wide):
    top = 2.1 if level<10 else 2.27
    for side in (-1,1):
        x = side*wide
        m.box(x,.35,(pad_height+top)*.5,.14,.17,top-pad_height,"oak")
        for z in (pad_height+.04,top-.07):
            m.box(x,.35,z,.192,.21,.108,"bronze")
        m.cylinder((x,.32,top-.01),(x,.32,top+.18),.089,.021,"bronze",8)
        m.cylinder((x,.04,pad_height-.04),(x,.25,top-.18),.057,.035,"iron",8)
        if level>=9:
            m.cylinder((side*1.04,.12,.69),(x,.35,top-.21),.087,.059,"iron",10)
            m.cylinder((side*1.07,.12,1.46),(side*1.05,.12,1.94),.067,.057,"bronze",10)
    m.box(0,.30,top-.11,wide*2+.21,.155,.156,"iron")
    m.box(0,.22,top-.091,wide*2+.12,.053,.073,"bronze")
    for y in (.21,.34):
        m.cylinder((-wide,y,top-.246),(wide,y,top-.246),.026,.027,"silver",10)
    for x in (-wide*.40,wide*.40):
        m.cylinder((x,.28,top-.18),(x,.28,top-.32),.028,.021,"bronze",8)


def base(m,level,branch):
    m.sine,m.cosine=math.sin(.16),math.cos(.16)
    width = 1.33 if level<4 else 1.46 if level<7 else 1.68
    top = .76 if level<4 else .89
    m.box(0,0,.077,width,1.18,.154,"stone")
    m.box(0,0,.184,width*.95,1.11,.072,"edge")
    m.box(0,0,.375,width*.84,.82,.088,"oak")
    for x in (-width*.37,width*.37):
        for y in (-.34,.34):
            m.box(x,y,.47,.124,.131,.55,"oak")
            for z in (.27,.556):
                m.box(x,y,z,.161,.158,.063,"bronze")
    m.box(0,0,top-.037,width*.93,.95,.108,"endgrain")
    m.box(0,-.463,top-.073,width*.91,.046,.090,"wood_shadow")
    wood_fixture(m,0,-.43,top-.208,width*.64,.209)
    planks(m,.18,-.11,.475,2,.49,.46)
    m.box(-.46,-.47,top-.173,.27,.036,.18,"wool")
    m.box(-.46,-.50,top-.258,.282,.032,.041,"canvas_edge")
    clamp_housing(m,.04,-.25,top+.02,level>=7)
    for x,y in mounts(level):
        m.cylinder((x,y,top-.012),(x,y,top+.065),.118,.100,"bronze",12)
    if level<4:
        wood_fixture(m,-.10,.41,1.23,.85,.72)
        controller(m,-.14,.31,1.23,.19)
        lantern(m,-.43,.19,top+.062)
        if level>=2:
            m.box(.65,.04,1.20,.35,.35,.080,"oak")
            m.cylinder((.75,.09,top),(.77,.09,1.44),.058,.045,"bronze",10)
            controller(m,.79,.006,1.36,.116)
        if level==3:
            wood_fixture(m,-.54,.43,1.52,.43,.74)
            planks(m,-.65,.25,1.48,3,.33,.24)
            m.cylinder((-.64,.40,1.77),(-.64,.40,2.02),.078,.026,"bronze",8)
    elif level<7:
        wood_fixture(m,0,.40,1.43,1.41,.99)
        for x in (-.65,.65):
            m.cylinder((x,.377,top+.019),(x,.377,1.99),.076,.044,"oak",6)
            m.cylinder((x,.377,1.93),(x,.377,2.18),.085,.013,"bronze",8)
        m.box(0,.37,1.88,1.44,.142,.107,"bronze")
        controller(m,0,.29,1.63,.26)
        planks(m,.54,.263,1.033,3,.45,.25)
        if level==5:
            m.cylinder((-.86,.20,1.01),(-.98,.20,1.51),.196,.164,"lining",12)
            m.cylinder((-.98,.20,1.51),(-.98,.20,1.91),.166,.045,"bronze",12)
            m.cylinder((-.88,.181,.86),(-.89,.181,1.08),.092,.063,"iron",10)
            pipe(m, ((-.98,.19,1.89),(-.97,.19,2.14),(-.59,.18,2.21),(-.48,.24,1.91)), (.067,.039),"bronze")
        if level==6:
            m.box(.78,.14,1.50,.41,.39,.31,"iron")
            m.cylinder((.84,.16,1.61),(.92,.16,2.09),.079,.051,"bronze",12)
            m.cylinder((.91,.16,2.06),(.95,.16,2.27),.087,.026,"lining",12)
            controller(m,.88,-.115,1.62,.127)
    else:
        tall_frame(m,top,level,.78)
        for side in (-1,1):
            planks(m,side*.60,.29,1.11,3,.34,.26)
        controller(m,0,.292,1.45,.26 if level<10 else .315)
        if level>=8:
            controller(m,.89,.27,1.92,.18)
            m.cylinder((.94,.26,1.34),(1.03,.26,2.04),.071,.044,"bronze",10)
            if level==8:
                m.cylinder((1.03,.26,1.98),(1.06,.26,2.36),.104,.019,"lining",9)
                m.box(1.02,.25,1.80,.28,.30,.22,"iron")
                pipe(m, ((.77,.20,1.41),(1.22,.20,1.68),(1.20,.20,2.06),(.99,.21,2.08)), (.063,.037),"bronze")
        if level>=9:
            m.box(-.87,.25,1.63,.46,.32,.31,"iron")
            controller(m,-1.04,.045,1.70,.193)
        if level==10:
            for side in (-1,1):
                pipe(m, ((side*1.05,.35,1.44),(side*1.16,.34,2.47),(side*.40,.34,2.90),(0,.34,2.70)), (.102,.058),"bronze")
                m.box(side*.97,.22,2.11,.24,.18,.203,"oak")
            m.cylinder((0,.34,2.68),(0,.34,2.96),.076,.014,"bronze",10)
            controller(m,0,.31,2.56,.115)
    if branch=="efficient_mending":
        # Return chute places sorted reclaimed stock beside the tool arm.
        m.box(-.84,-.23,1.18,.44,.36,.106,"bronze")
        planks(m,-.91,-.20,1.284,4,.40,.25)
        m.box(-1.06,-.37,1.326,.061,.078,.27,"lining")
        m.cylinder((-1.07,-.22,1.14),(-.85,-.22,.63),.039,.038,"iron",8)
    elif branch=="emergency_protocol":
        for x in (-.85,.85):
            m.cylinder((x,.084,.924),(x,.084,1.60),.154,.115,"iron",14)
            m.cylinder((x,.084,1.58),(x,.084,1.79),.127,.071,"actuator",12)
            for j in range(3):
                m.ring((x,.084,1.04+j*.177),.154,.029,"bronze",sides=16)
            controller(m,x,-.104,1.44,.101,"warm_jewel")


def jointed_arm(m, x, y, z, slot, phase, strong):
    side = -1 if x < 0 else 1
    line = math.sin(phase+slot*math.pi*.43)
    shoulder=(x,y,z)
    elbow=(x-side*.081,y-.072,z+.326+line*.092)
    wrist=(x-side*(.27+line*.077),y-.175,z+.293-line*.072)
    tip=(wrist[0]-side*.045,wrist[1]-.039,wrist[2]-.096)
    radius=.049 if strong else .04
    for before,after in ((shoulder,elbow),(elbow,wrist)):
        m.cylinder(before,after,radius,radius*.79,"actuator",10)
        m.cylinder((before[0],before[1]+.035,before[2]),
                   (after[0],after[1]+.035,after[2]),.019,.027,"iron",7)
    for px,py,pz in (shoulder,elbow,wrist):
        m.cylinder((px,py+.04,pz),(px,py-.045,pz),radius*1.62,radius*1.40,"bronze",12)
        m.cylinder((px,py-.043,pz),(px,py-.058,pz),radius*.66,radius*.55,"gold",8)
    m.cylinder(wrist,tip,.026,.028,"silver",10)
    if slot%2==0:
        # Broad hammer head over the workpiece with no cutting or attack effects.
        m.box(tip[0],tip[1],tip[2]-.01,.127,.086,.061,"iron")
    else:
        for p in (-1,1):
            m.cylinder((tip[0]+p*.04,tip[1],tip[2]+.035),
                       (tip[0]+p*.019,tip[1],tip[2]-.038),.017,.013,"bronze",6)


def motion(m,level,branch,phase):
    m.sine,m.cosine=math.sin(.16),math.cos(.16)
    z=.85 if level<4 else .98
    for slot,(x,y) in enumerate(mounts(level)):
        jointed_arm(m,x,y,z,slot,phase,level>=4)
    if level>=7:
        top=2.1 if level<10 else 2.27
        x=.23*math.sin(phase)
        m.box(x,.183,top-.31,.214,.213,.131,"iron")
        m.cylinder((x,.107,top-.341),(x,.106,top-.53+.08*math.cos(phase)),.045,.035,"silver",12)
        m.box(x,.112,top-.533+.08*math.cos(phase),.135,.105,.069,"bronze")
        if level>=8:
            tilt=(math.cos(phase),-1,math.sin(phase))
            axis_ring(m,(.79,.04,1.74),tilt,.114,.018,"gold",22)
    if branch=="emergency_protocol":
        for p in (-1,1):
            m.cylinder((p*.85,.084,1.76),(p*.85,.084,1.88+.089*math.cos(phase)),.055,.036,"silver",10)


if __name__=="__main__":
    catalog_atlases(OUT,PALETTE,STATES,base,motion)
