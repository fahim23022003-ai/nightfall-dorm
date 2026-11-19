"""Bake Arc Turret base and bearing-specific electrodes for the Godot 2.5D layer.

Run in the repository root with:
    blender -b -t 4 --python tools/visual_rebirth/bake_arc.py
"""
import math
from pathlib import Path
import sys

from mathutils import Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bake_needle as baker


def curved_electrode(model, points, section, color):
    """Skin a tapered copper throat around a cubic centerline."""
    controls = [Vector(point) for point in points]
    vertices = []
    segments, sides = 16, 12
    for index in range(segments + 1):
        t = index / segments
        s = 1 - t
        center = s**3*controls[0] + 3*s*s*t*controls[1] + 3*s*t*t*controls[2] + t**3*controls[3]
        tangent = (s*s*(controls[1]-controls[0]) + 2*s*t*(controls[2]-controls[1]) + t*t*(controls[3]-controls[2])).normalized()
        radial = tangent.cross(Vector((0, 1, 0))).normalized()
        up = tangent.cross(radial)
        radius = section[0] + t*(section[1] - section[0])
        for side in range(sides):
            angle = math.tau*side/sides
            vertices.append(center + radius*(math.cos(angle)*radial + math.sin(angle)*up))
    faces = []
    for index in range(segments):
        for side in range(sides):
            a = index*sides + side
            b = index*sides + (side + 1) % sides
            faces.append((a,b,b+sides,a+sides))
    model.add(vertices, faces, color, True)


def lancet(model, x, outer_y, lower, width, height, tint):
    with_depth = outer_y - .023
    mid = lower + height*.68
    vertices = [
        (x - width, outer_y, lower), (x + width, outer_y, lower),
        (x + width, outer_y, mid), (x, outer_y, lower + height),
        (x - width, outer_y, mid),
        (x - width, with_depth, lower), (x + width, with_depth, lower),
        (x + width, with_depth, mid), (x, with_depth, lower + height),
        (x - width, with_depth, mid),
    ]
    model.add(vertices, [(4,3,2,1,0),(5,6,7,8,9),(0,1,6,5),(1,2,7,6),(2,3,8,7),(3,4,9,8),(4,0,5,9)], tint)


def build_base(m, level, branch):
    # Squat masonry and two visible facades at the fixed three-quarter camera.
    m.cosine = math.cos(math.pi/4)
    m.sine = math.sin(math.pi/4)
    size = (1.19, 1.31, 1.24, 1.24)[tier(level)]
    m.box(0,0,.073,size,size,.146,"stone")
    m.box(0,0,.178,size*.91,size*.91,.092,"edge")
    m.box(0,0,.325,size*.81,size*.81,.21,"iron")
    m.box(0,0,.461,size*.86,size*.86,.09,"shadow")
    rim = -size*.407
    for _ in range(4):
        for x in (-.29,.29):
            lancet(m,x,rim,.242,.070,.175,"edge")
            lancet(m,x,rim-.024,.263,.045,.128,"ion")
        m.box(0,rim-.023,.322,.025,.030,.166,"bronze")
        m.cosine, m.sine = -m.sine, m.cosine
    for x in (-size*.398,size*.398):
        for y in (-size*.398,size*.398):
            m.box(x,y,.27,.144,.144,.39,"stone")
            m.cylinder((x,y,.46),(x,y,.56),.084,.063,"iron",10)
            m.cylinder((x,y,.56),(x,y,.64),.057,.019,"bronze")
    m.cylinder((0,0,.485),(0,0,.60),.48,.46,"bronze",24)
    m.cylinder((0,0,.60),(0,0,.70),.415,.38,"iron",24)
    m.cylinder((0,0,.69),(0,0,.88),.32,.32,"shadow",24)
    m.cylinder((0,0,.88),(0,0,1.015),.38,.34,"bronze",24)
    m.cylinder((0,0,.995),(0,0,1.075),.345,.31,"iron",24)
    for row in range(5):
        m.ring((0,0,.722+row*.033),.322,.015,"copper",sides=24)
    for quarter in range(4):
        a = math.pi*.5*quarter + math.pi*.25
        x, y = math.cos(a), math.sin(a)
        m.cylinder((x*.43,y*.43,.56),(x*.365,y*.365,.93),.041,.033,"edge")
        m.cylinder((x*.43,y*.43,.59),(x*.43,y*.43,.635),.067,.052,"bronze")
    m.cosine, m.sine = 1, 0
    if level in (2, 3):
        for side in (-1, 1):
            # The wider brace assemblies visibly project above the old plinth.
            m.box(side*.64,-.19,.46,.22,.33,.21,"iron")
            m.box(side*.67,-.37,.57,.25,.09,.30,"edge")
            m.cylinder((side*.60,-.19,.45),(side*.81,-.12,.69),.109,.084,"iron")
            m.cylinder((side*.81,-.12,.69),(side*.68,-.12,.97),.086,.047,"bronze")
            m.cylinder((side*.70,-.12,.92),(side*.66,-.10,1.04),.063,.030,"copper")
    if level == 3:
        for side in (-1, 1):
            m.cylinder((side*.61,-.25,.58),(side*.73,-.23,1.20),.149,.110,"ion")
            m.cylinder((side*.73,-.23,1.20),(side*.72,-.22,1.37),.113,.055,"bronze")
            for z, x in ((.70, .60),(.92, .64),(1.08, .68)):
                m.ring((side*x,-.24,z),.112,.027,"copper")
            m.cylinder((side*.60,-.33,.68),(side*.71,-.33,1.07),.039,.028,"iron")
    if 4 <= level < 7:
        m.cylinder((0,0,.46),(0,0,.75),.59,.53,"iron",24)
        m.cylinder((0,0,.73),(0,0,.79),.55,.51,"bronze",24)
        for side in (-1,1):
            m.box(side*.49,0,.70,.22,.83,.37,"iron")
            m.box(side*.52,-.12,.90,.22,.52,.12,"bronze")
            m.cylinder((side*.57,-.37,.79),(side*.63,-.34,1.12),.095,.057,"ion")
            m.cylinder((side*.63,-.34,1.12),(side*.57,-.32,1.23),.067,.039,"copper")
        for a in (0, math.pi/2, math.pi, 3*math.pi/2):
            x,y = math.cos(a),math.sin(a)
            m.cylinder((x*.53,y*.53,.53),(x*.52,y*.52,.88),.125,.105,"iron")
            m.cylinder((x*.52,y*.52,.86),(x*.48,y*.48,.975),.115,.069,"copper")
            m.ring((x*.53,y*.53,.77),.113,.025,"edge")
    if 5 <= level < 7 and not branch:
        m.ring((0,0,.90),.38,.034,"copper")
        m.box(-.64,-.30,.69,.30,.32,.32,"iron")
        m.cylinder((-.75,-.36,.75),(-.79,-.34,1.04),.103,.075,"ion")
        m.cylinder((-.79,-.34,1.04),(-.64,-.32,1.16),.082,.044,"copper")
    if level == 6:
        m.ring((0,0,.94),.45,.049,"bronze")
        for side in (-1, 1):
            m.cylinder((side*.58,-.18,.48),(side*.77,-.19,.88),.137,.109,"iron")
            m.cylinder((side*.77,-.19,.88),(side*.81,-.17,1.31),.105,.067,"copper")
            m.cylinder((side*.81,-.17,1.31),(side*.66,-.15,1.47),.073,.034,"silver")
    if 7 <= level < 10:
        for side in (-1, 1):
            m.box(side*.60,0,.28,.38,.78,.28,"stone")
            m.box(side*.70,0,.43,.29,.69,.13,"iron")
            m.cylinder((side*.73,-.16,.48),(side*.83,-.14,1.11),.118,.087,"iron")
            m.cylinder((side*.83,-.14,1.11),(side*.72,-.08,1.57),.087,.048,"copper")
            m.cylinder((side*.72,-.08,1.57),(side*.62,-.03,1.63),.059,.022,"silver")
            m.cylinder((side*.72,-.15,.53),(side*.74,-.18,1.10),.066,.041,"ion")
            m.cylinder((side*.61,-.23,.50),(side*.69,-.23,1.19),.112,.078,"bronze")
            m.cylinder((side*.61,.23,.50),(side*.69,.23,1.19),.107,.077,"bronze")
            m.cylinder((side*.69,-.23,1.19),(side*.60,-.15,1.35),.086,.028,"edge")
            m.cylinder((side*.69,.23,1.19),(side*.60,.15,1.35),.086,.028,"edge")
            m.cylinder((side*.62,-.19,.77),(side*.60,.20,.77),.072,.065,"copper")
            m.cylinder((side*.62,-.31,.47),(side*.62,-.39,.96),.086,.049,"ion")
            m.cylinder((side*.62,-.39,.96),(side*.51,-.42,1.18),.057,.023,"copper")
    if 8 <= level < 10:
        m.cylinder((-.73,-.21,.52),(-.91,-.19,.82),.104,.069,"bronze")
        m.ring((-.87,-.26,.86),.149,.044,"copper",(0,1,0))
        m.cylinder((-.87,-.28,.72),(-.87,-.28,1.00),.041,.041,"iron")
    if level == 9:
        for side in (-1, 1):
            m.box(side*.73,-.34,.77,.29,.23,.43,"iron")
            m.cylinder((side*.58,-.29,.55),(side*.86,-.33,1.07),.123,.081,"iron")
            m.cylinder((side*.86,-.33,1.07),(side*.91,-.21,1.48),.085,.042,"copper")
            m.cylinder((side*.91,-.21,1.48),(side*.89,-.18,1.65),.047,.017,"silver")
    if level == 10:
        m.cylinder((0,0,.53),(0,0,.66),.525,.45,"bronze",24)
        m.ring((0,0,.81),.433,.039,"iron")
        for x in (-.45,.45):
            for y in (-.33,.33):
                m.cylinder((x,y,.41),(x*.96,y,.91),.079,.049,"iron")
                m.cylinder((x*.96,y,.91),(x*.62,y*.76,1.12),.052,.047,"copper")
                m.cylinder((x*.65,y,.52),(x*.67,y,.85),.062,.051,"ion")
                m.ring((x*.65,y,.53),.057,.019,"bronze")
    if branch == "focus":
        # Focus channels through one conspicuous forward load cell.
        m.box(.12,-.52,.64,.40,.37,.35,"iron")
        m.box(.12,-.716,.69,.28,.061,.18,"ion")
        for side in (-1, 1):
            m.cylinder((.12+side*.13,-.61,.57),(.12+side*.20,-.66,1.10),.073,.043,"silver")
    elif branch == "storm":
        for side in (-1, 1):
            m.cylinder((side*.72,-.37,.49),(side*.78,-.34,1.06),.158,.120,"ion")
            m.ring((side*.77,-.34,1.02),.122,.042,"copper")
            m.cylinder((side*.78,-.34,1.06),(side*.71,-.32,1.25),.123,.064,"bronze")
            m.cylinder((side*.71,-.32,1.25),(side*.58,-.29,1.35),.066,.030,"iron")


def tier(level):
    if level == 10:
        return 3
    if level >= 7:
        return 2
    return 1 if level >= 4 else 0


def build_head(m, level, branch):
    """The charging throat and its pivot rotate as one self-contained turret."""
    m.cylinder((0,0,1.035),(0,0,1.18),.295,.289,"iron",24)
    m.ring((0,0,1.14),.292,.024,"bronze")
    m.cylinder((-.10,0,1.17),(-.10,0,1.41),.245,.212,"iron")
    m.cylinder((-.10,0,1.40),(-.10,0,1.48),.215,.155,"bronze")
    spread = (.30,.37,.46,.41)[tier(level)]
    radius = (.079,.119,.080,.093)[tier(level)]
    if branch == "focus":
        radius *= 1.15
    if branch == "storm":
        spread += .047
    for side in (-1, 1):
        y = side*spread
        start = (-.29,y,1.19)
        throat = ((-.39,y,1.19),(-.56,y,1.91),(.17,side*.24,2.08),(.60,side*.145,1.77))
        m.cylinder((start[0],start[1],1.08),(start[0],start[1],1.28),.125,.113,"iron")
        m.cylinder((start[0]-.032,start[1],1.18),(start[0]-.045,start[1],1.31),.132,.105,"bronze")
        curved_electrode(m, throat, (radius,.058), "copper")
        m.cylinder((.52,side*.168,1.80),(.60,side*.145,1.77),.092,.076,"bronze")
        m.cylinder((.59,side*.148,1.773),(.67,side*.115,1.77),.061,.042,"silver")
        m.cylinder((.648,side*.126,1.771),(.68,side*.103,1.77),.043,.025,"ion")
    if 4 <= level < 7:
        m.box(-.23,0,1.25,.62,.83,.30,"iron")
        m.cylinder((-.45,-.49,1.51),(-.45,.49,1.51),.272,.272,"bronze")
        m.cylinder((-.48,-.515,1.51),(-.48,.515,1.51),.201,.201,"shadow")
        m.cylinder((-.29,.0,1.50),(-.80,.0,1.56),.175,.118,"iron")
        m.cylinder((-.78,.0,1.56),(-.87,.0,1.56),.119,.066,"bronze")
        for offset in (-.30,-.21,-.13,-.05,.03,.11,.19,.28):
            m.cylinder((-.42,offset,1.54),(-.51,offset,1.76),.055,.035,"copper")
        for side in (-1, 1):
            m.cylinder((-.40,side*.46,1.28),(-.63,side*.46,1.68),.082,.057,"iron")
            m.cylinder((-.63,side*.46,1.68),(-.60,side*.39,1.91),.057,.024,"bronze")
    if 5 <= level < 7 and not branch:
        m.box(-.47,0,1.77,.36,.72,.18,"iron")
        m.cylinder((-.53,0,1.68),(-.62,0,2.02),.132,.091,"copper")
        for side in (-1, 1):
            m.cylinder((-.50,side*.23,1.74),(-.47,side*.26,1.99),.091,.057,"ion")
            m.cylinder((-.47,side*.26,1.99),(-.42,side*.26,2.08),.061,.036,"bronze")
    if 7 <= level < 10:
        for side in (-1, 1):
            horn = ((-.40,side*.35,1.18),(-.39,side*.73,1.54),(.09,side*.79,1.75),(.54,side*.62,1.73))
            curved_electrode(m, horn, (.108,.054), "copper")
            m.cylinder((.46,side*.66,1.74),(.61,side*.58,1.72),.073,.033,"silver")
            m.cylinder((-.28,side*.39,1.33),(-.23,side*.68,1.61),.059,.034,"edge")
    if 8 <= level < 10:
        m.cylinder((-.38,0,1.29),(-.71,0,1.45),.165,.129,"bronze")
        m.cylinder((-.71,-.37,1.51),(-.71,.37,1.51),.130,.130,"copper")
        for side in (-1, 1):
            m.ring((-.71,side*.38,1.51),.144,.035,"iron",(0,1,0))
    if level == 9:
        m.cylinder((-.37,0,1.31),(-.67,0,1.44),.128,.075,"bronze")
        m.cylinder((-.62,-.28,1.54),(-.62,.28,1.54),.085,.085,"iron")
        for side in (-1, 1):
            m.cylinder((-.54,side*.30,1.58),(-.69,side*.34,1.89),.100,.069,"iron")
            m.cylinder((-.69,side*.34,1.89),(-.59,side*.29,2.09),.070,.034,"copper")
    if level == 10:
        # High copper arches and a second pair of voltaged vaulted conductors.
        for side in (-1, 1):
            outer = ((-.49,side*.49,1.20),(-.72,side*.68,2.03),(-.18,side*.37,2.79),(.47,side*.29,2.39))
            curved_electrode(m, outer, (.109,.057), "bronze")
            m.cylinder((.38,side*.31,2.42),(.57,side*.265,2.35),.077,.036,"silver")
            m.cylinder((-.39,side*.35,1.45),(-.59,side*.54,1.78),.065,.043,"edge")
        m.cylinder((-.23,-.35,1.49),(-.23,.35,1.49),.15,.15,"copper")
    if branch == "focus":
        m.cylinder((.02,0,1.27),(.48,0,1.68),.166,.103,"iron")
        m.cylinder((.37,0,1.59),(.53,0,1.75),.104,.073,"silver")
        m.cylinder((-.22,0,1.36),(-.25,0,2.20),.136,.080,"bronze")
        m.cylinder((-.52,0,2.16),(.47,0,2.26),.121,.061,"silver")
        m.cylinder((.04,0,1.82),(.42,0,2.24),.106,.069,"iron")
        m.cylinder((-.57,0,2.11),(-.33,0,2.18),.089,.108,"copper")
    elif branch == "storm":
        for side in (-1, 1):
            m.cylinder((-.15,side*.19,1.31),(-.40,side*.52,1.43),.074,.060,"copper")
            m.cylinder((-.39,side*.53,1.43),(-.31,side*.63,1.72),.078,.048,"ion")
            m.cylinder((-.31,side*.63,1.72),(-.36,side*.75,1.94),.106,.050,"copper")
            m.cylinder((-.32,side*.64,1.66),(.18,side*.75,1.86),.103,.052,"silver")
            m.cylinder((.05,side*.70,1.61),(.35,side*.70,1.74),.093,.050,"bronze")


if __name__ == "__main__":
    baker.SHEET = Path("assets/visual_rebirth/buildings/heavy").resolve()
    baker.SHEET.mkdir(parents=True, exist_ok=True)
    baker.CELL = 96
    baker.STATES = [(level, "") for level in range(1, 11)]
    baker.STATES += [(level, branch) for branch in ("focus", "storm") for level in range(5, 11)]
    baker.PALETTE.update({"copper": (.41,.205,.112,1), "ion": (.15,.53,.88,1)})
    baker.bake("base", 6, 4, build_base)
    baker.bake("launcher", baker.VIEWS, len(baker.STATES), build_head)
