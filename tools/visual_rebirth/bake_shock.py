"""Bake the Shock Trap's inlaid plate, conductors and discharge assembly."""
from functools import partial
from math import ceil, cos, pi, sin, tau
from pathlib import Path
import sys

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bake_dynamo import BASE_COLUMNS, MOTION_FRAMES, bake_atlas
from bake_needle import PALETTE

MATERIALS = PALETTE | {
    "slate": (.18, .19, .22, 1),
    "blue_iron": (.22, .26, .32, 1),
    "ceramic": (.4, .4, .35, 1),
    "copper": (.53, .27, .13, 1),
    "charged": (.44, .74, .93, 1),
}
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("capacitor_burst", "rapid_discharge") for level in range(5, 11)]
OUT = Path("assets/visual_rebirth/buildings/shock")
CORNERS = [pi / 4 + index * pi / 2 for index in range(4)]


def ring_point(angle, radius, z):
    return cos(angle) * radius * .86, sin(angle) * radius * .81, z


def plate(model, corners, radius, low, high, color, phase=0.0):
    vertices = [ring_point(phase + index * tau / corners, radius, height)
                for height in (low, high) for index in range(corners)]
    walls = [(index, (index + 1) % corners, (index + 1) % corners + corners, index + corners)
             for index in range(corners)]
    model.add(vertices, walls + [tuple(reversed(range(corners))), tuple(range(corners, 2 * corners))], color)


def coil(model, angle, radius, height, count):
    x, y, z = ring_point(angle, radius, height)
    tangent = (-sin(angle), cos(angle), 0)
    half = .036 * count
    model.cylinder((x-tangent[0]*half,y-tangent[1]*half,z), (x+tangent[0]*half,y+tangent[1]*half,z),
                   .054,.054,"iron",10)
    for turn in range(count):
        shift = (turn - (count-1)*.5) * .069
        model.ring((x + tangent[0]*shift, y + tangent[1]*shift, z), .068,.019,"copper",tangent,sides=12)


def conductor(model, angle, distance, base, crown, color):
    x, y, _ = ring_point(angle, distance, 0)
    model.cylinder((x,y,base),(x,y,crown),.090,.060,color,10)
    for level in (base+.034, crown-.031):
        model.ring((x,y,level),.077,.017,"bronze",sides=12)
    model.cylinder((x,y,crown),(x,y,crown+.026),.056,.037,"edge",10)


def fixed(model, level, branch):
    corners = 4 if level < 4 else 8 if level < 7 else 12
    radius = [0, .89, .94, .98, 1.02, 1.02, 1.04, 1.10, 1.11, 1.13, 1.18][level]
    phase = pi/4 if level < 4 else pi/8 if level < 7 else 0.0
    plate(model,corners,radius,0,.12,"stone",phase)
    plate(model,corners,radius*.93,.12,.19,"iron",phase)
    plate(model,corners,radius*.80,.19,.22,"blue_iron",phase)
    model.ring((0,0,.224),.31,.023,"bronze",sides=26)
    for angle in CORNERS:
        conductor(model,angle,radius*.75,.18,.35 if level < 7 else .44,"ceramic")
    if level >= 2:
        for angle in (0, pi):
            coil(model,angle,radius*.62,.23,5)
    if level >= 3:
        for angle in (pi*.5, pi*1.5):
            coil(model,angle,radius*.65,.235,5)
    if level >= 4:
        for angle in CORNERS:
            model.cylinder(ring_point(angle,.34,.23),ring_point(angle,radius*.72,.23),.038,.056,"bronze",8)
    if level >= 5:
        for angle in (0, pi):
            conductor(model,angle,radius*.97,.14,.43,"bronze")
    if level >= 6:
        model.ring((0,0,.23),.51,.029,"copper",sides=32)
    if level >= 7:
        for angle in tuple(index*tau/8 for index in range(8)):
            model.cylinder(ring_point(angle,radius*.83,.16),ring_point(angle,radius*1.20,.105),.106,.057,"slate",8)
    if level >= 8:
        for angle in (pi*.5, pi*1.5):
            coil(model,angle,radius*1.02,.275,8)
    if level >= 9:
        for angle in CORNERS:
            model.cylinder(ring_point(angle,radius*.67,.44),ring_point(angle,radius*1.14,.17),.077,.052,"copper",10)
    if level >= 10:
        for angle in tuple(index*tau/8 for index in range(8)):
            conductor(model,angle,radius*.88,.21,.63,"iron")
        model.ring((0,0,.52),1.04,.050,"edge",sides=36)
        model.ring((0,0,.51),.96,.028,"copper",sides=36)
    if branch == "capacitor_burst":
        for angle in (pi*.5, pi*1.5):
            conductor(model,angle,radius*.70,.22,.68,"blue_iron")
            model.ring(ring_point(angle,radius*.70,.59),.10,.024,"copper",sides=12)
    elif branch == "rapid_discharge":
        for angle in (0, pi):
            coil(model,angle,radius*.84,.35,7)
            model.cylinder(ring_point(angle,radius*.78,.20),ring_point(angle,radius*.99,.33),.083,.043,"copper",8)


def moving(model, level, branch, spin):
    # Index zero is the resting plate. Nonzero discharge frames lift its shutter.
    crown = .26 + .032 * (1.0 - cos(spin))
    plate(model, 6 if level < 7 else 8, .24 if level < 4 else .29, crown-.041, crown, "edge", spin*.25)
    terminals = 3 if level < 4 else 4 if level < 7 else 6
    for index in range(terminals):
        angle = index * tau / terminals + spin * .25
        a = ring_point(angle,.105,crown+.007)
        b = ring_point(angle,.224,crown+.013)
        model.cylinder(a,b,.019,.013,"charged" if spin else "ceramic",8)
    model.cylinder((0,0,crown),(0,0,crown+.06),.050,.036,"bronze",10)


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True, parents=True)
    bake_atlas(OUT / "base.png", MATERIALS, BASE_COLUMNS, ceil(len(STATES) / BASE_COLUMNS), (
        (state % BASE_COLUMNS, state // BASE_COLUMNS, partial(fixed, level=level, branch=branch))
        for state, (level, branch) in enumerate(STATES)
    ))
    bake_atlas(OUT / "motion.png", MATERIALS, MOTION_FRAMES, len(STATES), (
        (frame, state, partial(moving, level=level, branch=branch, spin=tau * frame / MOTION_FRAMES))
        for state, (level, branch) in enumerate(STATES) for frame in range(MOTION_FRAMES)
    ))
