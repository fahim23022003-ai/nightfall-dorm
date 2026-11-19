"""Bake the Flame Turret brazier, gargoyle housing and branch-specific sights."""
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bake_arc as arc
import bake_needle as baker


def ellipsoid(m, center, axes, color):
    segments, rings = 18, 10
    vertices = []
    for row in range(rings + 1):
        latitude = math.pi * row / rings
        for column in range(segments):
            longitude = math.tau * column / segments
            point = (math.cos(longitude)*math.sin(latitude), math.sin(longitude)*math.sin(latitude), math.cos(latitude))
            vertices.append(tuple(coord + extent*unit for coord, extent, unit in zip(center, axes, point)))
    faces = []
    for row in range(rings):
        for column in range(segments):
            a, b = row*segments+column, row*segments+(column+1)%segments
            faces.append((a,b,b+segments,a+segments))
    m.add(vertices, faces, color, True)


def wing(m, side, stage):
    """A ribbed, curved stone heatshield with the reference's bat outline."""
    span = (.63,.61,.96,.90)[stage]
    height = (.54,.36,.78,.68)[stage]
    sill = 1.21 if stage < 3 else 1.37
    root = (-.28, side*.23, sill+.21)
    profile = [(0,0),(.16,.66),(.39,.95),(.73,1),(.92,.82),(1,.40),
               (.84,.55),(.72,.48),(.61,.23),(.46,.40),(.33,.31),(.19,0)]
    frame = [(root[0] - .16*y + .10*z, root[1]+side*span*y*.7, sill+z*height) for y,z in profile]
    surface = [root] + frame
    faces = [(0,i+1,i+2) for i in range(len(frame)-1)] + [(0,len(frame),1)]
    if side < 0:
        faces = [face[::-1] for face in faces]
    m.add(surface, faces, "scoria", True)
    back = [(x-.07,y,z) for x,y,z in surface]
    m.add(back,[face[::-1] for face in faces],"shadow",True)
    rim = [(x-.035,y,z) for x,y,z in frame]
    for a,b in zip(rim,rim[1:]):
        m.cylinder(a,b,.035 if stage < 2 else .044,.03,"bronze",8)
    for i in (3,6,9):
        m.cylinder(root,frame[i],.049,.025,"edge",10)


def stage(level):
    return 3 if level == 10 else 2 if level >= 7 else 1 if level >= 4 else 0


def base(m, level, branch):
    tier = stage(level)
    stone = (1.05,1.30,1.33,1.22)[tier]
    m.cosine, m.sine = math.cos(math.pi/4), math.sin(math.pi/4)
    m.box(0,0,.07,stone,stone,.14,"stone")
    m.box(0,0,.17,stone*.91,stone*.91,.07,"edge")
    m.box(0,0,.27,stone*.77,stone*.77,.19,"scoria")
    m.box(0,0,.397,stone*.84,stone*.84,.10,"shadow")
    for _ in range(4):
        y = -stone*.386
        arc.lancet(m,0,y,.231,.139,.177,"bronze")
        arc.lancet(m,0,y-.023,.249,.101,.134,"ember")
        for x in (-.19,.19):
            m.cylinder((x,y-.014,.23),(x,y-.014,.39),.037,.027,"iron")
        m.cosine,m.sine = -m.sine,m.cosine
    for x in (-stone*.41,stone*.41):
        for y in (-stone*.41,stone*.41):
            m.box(x,y,.24,.158,.158,.21,"stone")
            m.cylinder((x,y,.345),(x,y,.46),.086,.056,"bronze",12)
            m.cylinder((x,y,.46),(x,y,.54),.043,.009,"edge",10)
    m.cosine, m.sine = 1,0
    m.cylinder((0,0,.43),(0,0,.55),.386,.349,"bronze",24)
    m.cylinder((0,0,.56),(0,0,.94),.31,.33,"scoria",24)
    m.cylinder((0,0,.91),(0,0,1.06),.386,.352,"bronze",24)
    for side in (-1,1):
        m.cylinder((side*.29,-.21,.48),(side*.29,-.21,.96),.059,.044,"bronze")
        m.ring((side*.29,-.21,.64),.047,.022,"gold",sides=16)
    if level in (2,3):
        for side in (-1,1):
            m.cylinder((side*.47,-.12,.39),(side*.72,-.10,.62),.112,.086,"iron")
            m.cylinder((side*.72,-.10,.62),(side*.61,-.08,.84),.094,.049,"bronze")
            m.box(side*.59,-.27,.48,.23,.18,.154,"iron")
    if level == 3:
        m.cylinder((-.51,-.26,.56),(-.72,-.25,1.19),.109,.086,"bronze")
        m.ring((-.72,-.28,1.17),.109,.025,"iron")
        m.cylinder((-.72,-.25,1.17),(-.67,-.23,1.33),.086,.039,"gold")
    if 4 <= level < 7:
        m.cylinder((0,0,.47),(0,0,.82),.599,.488,"iron",24)
        m.ring((0,0,.77),.525,.056,"bronze")
        m.cylinder((0,0,.464),(0,0,.53),.602,.585,"bronze",24)
        for side in (-1,1):
            m.box(side*.49,-.03,.64,.27,.55,.37,"scoria")
            m.cylinder((side*.53,-.29,.56),(side*.52,-.27,1.03),.124,.078,"bronze")
    if 5 <= level < 7 and not branch:
        m.box(-.70,-.24,.68,.31,.33,.35,"iron")
        m.cylinder((-.74,-.23,.74),(-.80,-.21,1.16),.113,.077,"bronze")
        m.cylinder((-.80,-.21,1.16),(-.69,-.20,1.27),.079,.039,"gold")
    if level == 6:
        m.box(.72,-.16,.61,.29,.37,.25,"bronze")
        m.cylinder((.70,-.27,.67),(.85,-.24,1.11),.116,.080,"iron")
        m.cylinder((.85,-.24,1.11),(.71,-.19,1.35),.098,.043,"gold")
    if 7 <= level < 10:
        for side in (-1,1):
            m.box(side*.66,0,.28,.37,.79,.21,"stone")
            m.cylinder((side*.65,-.21,.42),(side*.78,-.20,.95),.131,.112,"iron")
            m.cylinder((side*.78,-.20,.95),(side*.64,-.17,1.32),.116,.057,"bronze")
            m.cylinder((side*.66,-.19,1.30),(side*.62,-.19,1.39),.072,.036,"gold")
            m.box(side*.74,-.30,.50,.21,.15,.10,"ember")
            m.cylinder((side*.70,-.18,.77),(side*.84,-.15,1.10),.103,.077,"scoria")
            m.cylinder((side*.84,-.15,1.10),(side*.76,-.12,1.49),.086,.054,"bronze")
            m.cylinder((side*.75,-.12,1.49),(side*.66,-.10,1.73),.084,.030,"edge")
            m.box(side*.70,-.25,.80,.35,.28,.35,"scoria")
    if 8 <= level < 10:
        m.cylinder((-.59,-.17,.61),(-.83,-.18,1.10),.102,.088,"iron")
        m.ring((-.82,-.28,1.06),.151,.046,"gold",(0,1,0))
        m.cylinder((-.93,-.30,.97),(-.72,-.30,1.16),.046,.044,"bronze")
    if level == 9:
        for side in (-1,1):
            m.box(side*.81,-.15,.63,.26,.31,.28,"iron")
            m.cylinder((side*.76,-.15,.73),(side*.85,-.14,1.40),.087,.061,"gold")
    if level == 10:
        m.cylinder((0,0,.47),(0,0,.91),.432,.415,"scoria",24)
        for side in (-1,1):
            m.cylinder((side*.48,-.19,.46),(side*.61,-.18,.83),.119,.101,"bronze")
            m.cylinder((side*.61,-.18,.83),(side*.46,-.16,1.20),.102,.047,"bronze")
            m.cylinder((side*.30,-.31,.59),(side*.29,-.31,1.04),.091,.057,"ember")
        m.ring((0,0,.94),.412,.039,"gold")
    if branch == "searing":
        m.box(.32,-.45,.68,.41,.32,.42,"iron")
        m.box(.34,-.624,.73,.26,.049,.22,"ember")
        m.cylinder((.41,-.53,.56),(.61,-.48,1.17),.130,.072,"bronze")
    elif branch == "wildfire":
        for side in (-1,1):
            m.cylinder((side*.67,-.38,.39),(side*.71,-.34,1.03),.170,.133,"scoria")
            m.cylinder((side*.71,-.34,1.03),(side*.58,-.26,1.30),.134,.071,"bronze")
            m.ring((side*.705,-.34,.92),.145,.033,"gold")
            m.box(side*.61,-.448,.66,.135,.036,.16,"ember")


def launcher(m, level, branch):
    tier = stage(level)
    jaw = .25 if branch == "wildfire" else .184
    m.cylinder((0,0,1.02),(0,0,1.16),.354,.374,"iron",24)
    m.cylinder((0,0,1.16),(0,0,1.28),.374,.301,"bronze",24)
    ellipsoid(m,(-.18,0,1.56),(.34,.265,.338),"scoria")
    ellipsoid(m,(-.08,0,1.74),(.266,.269,.208),"stone")
    ellipsoid(m,(.28,0,1.76),(.267,jaw,.129),"scoria")
    ellipsoid(m,(.40,0,1.68),(.216,jaw*.87,.076),"stone")
    ellipsoid(m,(.28,0,1.43),(.299,jaw*.90,.136),"scoria")
    ellipsoid(m,(.34,0,1.52),(.266,jaw*.88,.102),"ember")
    ellipsoid(m,(.53,0,1.55),(.128,jaw*.64,.091),"coalheat")
    m.cylinder((.47,0,1.52),(.65,0,1.57),.093,.054,"coalheat",14)
    for side in (-1,1):
        for x,y in ((.40,.139),(.52,.113)):
            m.cylinder((x,side*y,1.68),(x+.04,side*y*.89,1.57),.050,.011,"bronze",10)
            m.cylinder((x-.025,side*y,1.47),(x+.02,side*y*.95,1.55),.036,.010,"gold",10)
        ellipsoid(m,(.115,side*.187,1.826),(.077,.043,.040),"shadow")
        ellipsoid(m,(.147,side*.197,1.824),(.037,.029,.020),"coalheat")
        ellipsoid(m,(.11,side*.183,1.850),(.101,.056,.044),"edge")
        horn = ((-.15,side*.195,1.83),(-.46,side*.29,2.22),(-.31,side*.32,2.40),(-.05,side*.35,2.20))
        arc.curved_electrode(m,horn,(.081,.013),"bronze")
        wing(m,side,tier)
    if level == 3:
        m.cylinder((-.24,0,1.34),(-.65,0,1.41),.129,.067,"iron")
    if 4 <= level < 7:
        # A hinged furnace shield encloses the rear of the low turret head.
        m.box(-.31,0,1.46,.47,.66,.36,"iron")
        m.cylinder((-.31,-.39,1.53),(-.31,.39,1.53),.208,.208,"scoria")
        m.cylinder((-.43,-.41,1.53),(-.43,.41,1.53),.149,.149,"bronze")
        m.cylinder((-.51,0,1.55),(-.79,0,1.69),.154,.094,"iron")
        m.cylinder((-.78,0,1.69),(-.69,0,1.93),.099,.052,"bronze")
        m.ring((0,0,1.35),.396,.069,"iron")
        for side in (-1,1):
            m.cylinder((.12,side*.27,1.30),(.48,side*.22,1.61),.116,.069,"iron")
            m.cylinder((.48,side*.22,1.61),(.61,side*.16,1.73),.070,.042,"bronze")
    if 7 <= level < 10:
        for side in (-1,1):
            pipe = ((-.15,side*.32,1.26),(-.39,side*.53,1.50),(-.19,side*.76,1.76),(.12,side*.65,1.89))
            arc.curved_electrode(m,pipe,(.109,.061),"bronze")
            m.cylinder((.05,side*.663,1.85),(.17,side*.621,1.91),.071,.052,"iron")
    if 8 <= level < 10:
        m.cylinder((-.32,0,1.30),(-.66,0,1.48),.172,.099,"bronze")
        m.cylinder((-.62,-.18,1.50),(-.62,.18,1.50),.085,.085,"iron")
    if level == 9:
        for side in (-1,1):
            m.cylinder((-.23,side*.27,1.47),(-.41,side*.546,1.83),.118,.072,"scoria")
            m.cylinder((-.41,side*.546,1.83),(-.44,side*.49,2.07),.078,.041,"bronze")
    if level == 10:
        for side in (-1,1):
            upper = ((-.39,side*.37,1.62),(-.64,side*.41,2.05),(-.40,side*.43,2.65),(.15,side*.39,2.45))
            arc.curved_electrode(m,upper,(.115,.039),"bronze")
            m.cylinder((-.18,side*.38,2.47),(.09,side*.38,2.48),.061,.037,"gold")
            m.cylinder((-.30,side*.19,1.91),(-.45,side*.24,2.27),.100,.046,"iron")
        ellipsoid(m,(-.22,0,2.08),(.141,.229,.19),"scoria")
        m.cylinder((-.17,0,2.20),(-.11,0,2.48),.093,.032,"gold")
    if 5 <= level < 7 and not branch:
        m.cylinder((-.26,0,1.30),(-.62,0,1.63),.128,.091,"scoria")
        m.cylinder((-.62,0,1.63),(-.56,0,1.92),.104,.054,"bronze")
    if branch == "searing":
        m.cylinder((.37,0,1.56),(.65,0,1.56),.129,.081,"iron")
        m.cylinder((.60,0,1.56),(.675,0,1.56),.09,.073,"bronze")
        m.cylinder((.671,0,1.56),(.68,0,1.56),.067,.054,"ember")
        m.cylinder((-.30,0,1.72),(-.43,0,2.15),.153,.093,"iron")
        m.cylinder((-.44,0,2.15),(.44,0,2.26),.115,.049,"bronze")
        m.cylinder((.0,0,1.93),(.38,0,2.24),.106,.053,"iron")
    elif branch == "wildfire":
        for side in (-1,1):
            m.cylinder((-.14,side*.22,1.34),(.39,side*.54,1.48),.188,.144,"scoria")
            m.cylinder((.39,side*.54,1.48),(.56,side*.58,1.51),.153,.114,"bronze")
            m.cylinder((.55,side*.577,1.51),(.57,side*.583,1.51),.118,.086,"ember")
            m.cylinder((-.29,side*.32,1.39),(-.19,side*.62,1.66),.141,.085,"iron")
            m.cylinder((-.19,side*.62,1.66),(.06,side*.67,1.83),.090,.042,"bronze")


if __name__ == "__main__":
    baker.SHEET = Path("assets/visual_rebirth/buildings/flame").resolve()
    baker.SHEET.mkdir(parents=True, exist_ok=True)
    baker.CELL = 96
    baker.STATES = [(level, "") for level in range(1, 11)]
    baker.STATES += [(level, branch) for branch in ("searing", "wildfire") for level in range(5, 11)]
    baker.PALETTE.update({"scoria":(.20,.134,.095,1), "ember":(.67,.15,.022,1), "coalheat":(.91,.31,.055,1)})
    baker.bake("base", 6, 4, base)
    baker.bake("launcher", baker.VIEWS, len(baker.STATES), launcher)
