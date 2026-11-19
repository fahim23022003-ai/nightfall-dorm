"""Bake the Ward Antenna's copper spire and protective conductor architecture."""
from functools import partial
from math import ceil, cos, pi, sin, tau
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, bake_atlas, pipe
from bake_needle import PALETTE

MATERIALS = PALETTE | {
    "patina": (.18, .37, .33, 1),
    "copper": (.50, .28, .14, 1),
    "ceramic": (.40, .48, .39, 1),
    "jade": (.20, .53, .46, 1),
}
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("dome", "pulse") for level in range(5, 11)]
OUT = Path("assets/visual_rebirth/buildings/antenna")


def pedestal(model, center, radius):
    x,y = center
    model.cylinder((x,y,0),(x,y,.13),radius,radius*.89,"stone",8)
    model.cylinder((x,y,.13),(x,y,.23),radius*.82,radius*.73,"iron",8)
    model.ring((x,y,.221),radius*.69,.026,"bronze",sides=20)


def conductor(model, x, y, base, top, width):
    model.cylinder((x,y,base),(x,y,top-.13),width,width*.54,"copper",12)
    for index,z in enumerate((base+.16,base+.32,top-.21)):
        model.ring((x,y,z),width*(1.22-index*.12),.028,"patina",sides=16)
    model.cylinder((x,y,top-.26),(x,y,top+.021),width*.57,.021,"jade",10)


def fan(model, z, count, radius, flare):
    for index in range(count):
        angle = index*tau/count + pi*.20
        x, y = cos(angle), sin(angle)
        pipe(model, ((x*.10,y*.10,z-.45),(x*radius*.68,y*radius*.68,z-.22),
                     (x*radius,y*radius,z+flare),(x*radius*.82,y*radius*.82,z+flare+.10)),
             (.045,.019),"copper")
        model.cylinder((x*radius*.82,y*radius*.82,z+flare+.08),
                       (x*radius*.82,y*radius*.82,z+flare+.15),.040,.032,"ceramic",8)


def antenna(model, level, branch):
    radius = .54 if level < 4 else .69 if level < 7 else .71
    pedestal(model,(0, 0),radius)
    top = 1.37 if level < 4 else 1.79 if level < 7 else 2.08
    conductor(model,0,0,.28,top,.11 if level<4 else .137)
    fan(model,top-.38,3 if level<3 else 4,.37 if level<4 else .55,.09)
    if level >= 2:
        for sign in (-1,1):
            model.cylinder((sign*.45,-.24,.17),(sign*.219,-.13,.80),.046,.040,"bronze",10)
    if level >= 3:
        model.ring((0,0,top-.28),.273,.038,"patina",sides=24)
    if level >= 4:
        model.ring((0,0,.80),.60,.049,"copper",sides=30)
        for sign in (-1,1):
            conductor(model,sign*.47,.10,.32,1.11,.083)
    if level >= 5:
        for sign in (-1,1):
            model.cylinder((sign*.63,-.26,.22),(sign*.66,-.26,.82),.064,.041,"copper",10)
    if level >= 6:
        for sign in (-1,1):
            pipe(model,((sign*.64,-.24,.79),(sign*.70,-.16,1.14),(sign*.66,-.13,1.32),(sign*.38,-.11,1.52)),
                 (.047,.027),"patina")
    if level >= 7:
        for sign in (-1,1):
            x=sign*.74
            pedestal(model,(x,.16),.24)
            conductor(model,x,.16,.28,top*.78,.091)
            pipe(model,((x,.16,top*.6),(x*.78,.13,top*.72),(x*.70,.08,top*.85),(x*.32,.021,top*.75)),(.064,.039),"bronze")
    if level >= 8:
        model.ring((0,-.08,1.43),.47,.034,"patina",(0,-1,0),sides=28)
    if level >= 9:
        fan(model,1.79,5,.68,.16)
        for sign in (-1,1):
            model.cylinder((sign*.95,.1,.24),(sign*.72,.15,1.34),.052,.044,"iron",10)
    if level == 10:
        model.ring((0,0,2.15),.55,.050,"copper",sides=34)
        conductor(model,0,0,1.73,2.64,.091)
        fan(model,2.13,5,.65,.19)
    if branch == "dome":
        model.ring((0,0,top-.16),.65,.045,"bronze",(0,-1,0),begin=0.0,end=pi,sides=24)
        model.ring((0,0,top-.16),.65,.045,"bronze",(1,0,0),begin=0.0,end=pi,sides=24)
    elif branch == "pulse":
        for sign in (-1,1):
            for index in range(3):
                model.ring((sign*.44,-.29,1.07+index*.16),.13,.034,"patina",sides=18)
            conductor(model,sign*.44,-.29,.7,1.55,.087)


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True, parents=True)
    bake_atlas(OUT/"base.png", MATERIALS, BASE_COLUMNS, ceil(len(STATES)/BASE_COLUMNS), (
        (index % BASE_COLUMNS,index // BASE_COLUMNS,partial(antenna,level=level,branch=branch))
        for index,(level,branch) in enumerate(STATES)
    ))
