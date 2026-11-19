"""Bake the dorm door, masonry and branch hardware from one orthographic source."""
from functools import partial
from math import ceil, cos, pi, sin
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, bake_atlas
from bake_needle import PALETTE

MATERIALS = PALETTE | {
    "oak": (.255,.133,.083,1),
    "grain": (.335,.193,.112,1),
    "soot": (.11,.084,.065,1),
    "mortar": (.19,.18,.174,1),
    "steel": (.26,.27,.28,1),
    "renewal": (.27,.38,.25,1),
}
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("bulwark", "renewal") for level in range(6, 11)]
OUT = Path("assets/visual_rebirth/buildings/door")


def lintel(model, center, radius, thickness, material, aspect=1.0):
    pieces = 12
    for index in range(pieces):
        angle = pi * index / pieces
        next_angle = pi * (index + .94) / pieces
        vertices = []
        for depth in (center[1]-.22,center[1]+.08):
            for angle_at, distance in ((angle,radius),(angle,radius+thickness),
                                       (next_angle,radius+thickness),(next_angle,radius)):
                vertices.append((center[0]+distance*cos(angle_at),depth,center[2]+distance*sin(angle_at)*aspect))
        model.add(vertices,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],material)


def bands(model, width, depth, heights, material):
    for z in heights:
        model.box(0,depth,z,width,.056,.095,material)
        for x in (-width*.39,width*.39):
            model.cylinder((x,depth,z),(x,depth-.049,z),.044,.031,"bronze",10)


def door(model, level, branch):
    width = .90 if level < 4 else 1.02 if level < 7 else 1.13
    top = 1.65 if level < 4 else 1.84 if level < 7 else 2.02
    side_width = .13 if level < 4 else .19 if level < 7 else .24
    model.box(0,0,.063,width+side_width*2+.24,.51,.126,"stone")
    model.box(0,.04,top*.50,width,.22,top,"soot")
    for plank in range(6):
        x = width*(plank+.5)/6-width*.5
        model.box(x,-.096,top*.50,width*.153,.092,top*.98,"oak" if plank%2 else "grain")
        for stripe in (-1,1):
            model.box(x+stripe*.034,-.147,top*.59,.013,.009,top*.57,"soot" if stripe<0 else "grain")
    for sign in (-1,1):
        x = sign*(width*.5+side_width*.48)
        for row in range(6):
            model.box(x,.039,top*(row+.5)/6,side_width,.39,top/6-.019,"stone" if row%2 else "mortar")
        model.box(x,0,.155,side_width*1.54,.44,.21,"iron")
    model.box(0,0,top+.035,width+side_width*1.77,.37,.15,"stone")
    bands(model,width*.96,-.157,(.47 if level==1 else .36,),"iron")
    model.ring((width*.31,-.189,top*.54),.087,.02,"bronze",(0,-1,0),sides=18)
    if level >= 2:
        bands(model,width*.98,-.172,(top*.63,),"steel")
        model.box(0,-.108,top*.83,width*.33,.072,.13,"bronze")
    if level >= 3:
        model.cylinder((-width*.44,-.197,.40),(width*.44,-.197,top*.63),.046,.039,"iron",8)
        for sign in (-1,1):
            model.box(sign*width*.63,-.13,top*.50,.115,.17,.41,"iron")
    if level >= 4:
        lintel(model,(0,0,top-.25),width*.46,.162,"stone",1.0)
        for x in (-width*.24,width*.24):
            model.box(x,-.181,top*.56,width*.405,.078,top*.72,"iron")
            model.box(x,-.229,top*.55,width*.29,.025,top*.60,"steel")
        bands(model,width*.90,-.238,(top*.82,),"bronze")
    if level >= 5:
        model.ring((0,-.279,top*.58),.223,.044,"bronze",(0,-1,0),sides=26)
        for x in (-width*.52,width*.52):
            model.box(x,-.164,top*.42,.157,.19,.58,"steel")
    if level >= 6:
        for sign in (-1,1):
            model.cylinder((sign*width*.62,-.241,.22),(sign*width*.34,-.251,top*.67),.061,.052,"bronze",10)
    if level >= 7:
        lintel(model,(0,-.045,top-.22),width*.67,.17,"stone",.76)
        model.ring((0,-.293,top*.64),.315,.049,"iron",(0,-1,0),sides=30)
        for x in (-width*.77,width*.77):
            model.box(x,-.066,top*.41,.182,.36,top*.75,"mortar")
            model.box(x,-.105,top*.65,.211,.41,.18,"bronze")
    if level >= 8:
        for x in (-width*.75,width*.75):
            model.cylinder((x,-.211,.24),(x,-.211,top*.72),.089,.048,"iron",10)
            model.cylinder((x,-.21,top*.72),(x,-.21,top*.88),.083,.027,"bronze",10)
    if level >= 9:
        for x in (-width*.56,width*.56):
            model.box(x,-.262,top*.76,.156,.105,top*.39,"steel")
            model.ring((x,-.313,top*.89),.078,.024,"bronze",(0,-1,0),sides=14)
    if level == 10:
        lintel(model,(0,-.03,top-.11),width*.69,.22,"iron",.95)
        for x in (-width*.80,width*.80):
            model.cylinder((x,-.203,top*.66),(x,-.203,top*1.07),.107,.055,"steel",10)
            model.cylinder((x,-.203,top*1.07),(x,-.203,top*1.16),.079,.020,"bronze",10)
        model.box(0,-.337,top*.55,.15,.10,top*.64,"iron")
        model.ring((0,-.40,top*.68),.188,.037,"bronze",(0,-1,0),sides=20)
    if branch == "bulwark":
        for sign in (-1,1):
            model.cylinder((sign*width*.54,-.32,.26),(sign*width*.43,-.33,top*.88),.086,.057,"steel",8)
        bands(model,width*.88,-.32,(.42,top*.47),"iron")
    elif branch == "renewal":
        for sign in (-1,1):
            model.ring((sign*width*.56,-.29,top*.53),.164,.033,"bronze",(0,-1,0),sides=18)
            model.cylinder((sign*width*.56,-.297,top*.36),(sign*width*.56,-.297,top*.67),.065,.031,"renewal",12)


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True, parents=True)
    bake_atlas(OUT/"base.png", MATERIALS, BASE_COLUMNS, ceil(len(STATES)/BASE_COLUMNS), (
        (index % BASE_COLUMNS, index // BASE_COLUMNS, partial(door, level=level, branch=branch))
        for index, (level, branch) in enumerate(STATES)
    ))
