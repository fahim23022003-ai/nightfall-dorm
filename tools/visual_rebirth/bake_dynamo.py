"""Bake the model-derived Dynamo supports and independently turning flywheels.

Run from the repository root:
    blender -b -t 4 --python-exit-code 1 --python tools/visual_rebirth/bake_dynamo.py
"""
from functools import partial
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bake_needle as shared
from bake_arc import curved_electrode as pipe, lancet

CELL = 96
STEP = 3.75
BASE_COLUMNS = 6
MOTION_FRAMES = 8
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("regulated", "overcharge") for level in range(5, 11)]
OUTPUT = Path("assets/visual_rebirth/buildings/generator").resolve()
PALETTE = shared.PALETTE | {
    "iron": (.12, .109, .10, 1),
    "stone": (.22, .208, .185, 1),
    "copper": (.48, .212, .09, 1),
    "copper_dark": (.24, .108, .062, 1),
    "tempered": (.20, .28, .35, 1),
    "static": (.134, .385, .69, 1),
    "ion": (.37, .68, .93, 1),
    "ceramic": (.52, .47, .41, 1),
    "leather": (.14, .085, .065, 1),
}


def stack(m, x, y, floor, height, radius, cap):
    """Banded field windings nested within the cast structure."""
    top = floor + height
    m.cylinder((x,y,floor),(x,y,top),radius*.91,radius*.91,"copper_dark",24)
    for boundary in (floor, top):
        m.cylinder((x,y,boundary-.047),(x,y,boundary+.046),radius*1.14,radius*1.09,"bronze",24)
        m.ring((x,y,boundary+.038),radius*1.05,.017,"gold",sides=28)
    for i in range(10):
        z = floor+.045+(height-.084)*i/9
        m.ring((x,y,z),radius,.019 if i%2 else .023,"copper",sides=24)
    for dx in (-radius, radius):
        m.cylinder((x+dx,y-.04,floor+.02),(x+dx,y-.04,top+.10),.044,.041,"iron")
    if cap == "glass":
        for i in range(5):
            z = top+.07+i*.054
            m.cylinder((x,y,z),(x,y,z+.055),radius*(.88-i*.125),radius*(.85-i*.132),"static",18)
        m.ring((x,y,top+.116),radius*.77,.023,"bronze",sides=25)
        m.cylinder((x,y,top+.26),(x,y,top+.41),.066,.037,"gold",12)
    elif cap == "stack":
        m.cylinder((x,y,top+.028),(x,y,top+.13),radius*1.16,radius*1.07,"iron",12)
        m.cylinder((x,y,top+.13),(x,y,top+.36),radius*1.07,.084,"bronze",8)
        m.cylinder((x,y,top+.36),(x,y,top+.51),.068,.025,"gold",10)
    else:
        m.cylinder((x,y,top+.03),(x,y,top+.21),radius*.65,.048,"bronze",12)


def glass_column(m, x, y, floor, height, radius):
    m.cylinder((x,y,floor),(x,y,floor+height),radius*.88,radius*.79,"static",16)
    m.cylinder((x,y,floor+.01),(x,y,floor+height-.09),radius*.31,radius*.17,"ion",10)
    m.cylinder((x,y-.75*radius,floor+.12),(x+.04,y-.72*radius,floor+height-.14),radius*.09,radius*.06,"ion",6)
    for z in (floor, floor+height):
        m.cylinder((x,y,z-.044),(x,y,z+.037),radius*1.14,radius*.99,"bronze",16)
        m.ring((x,y,z+.024),radius,.016,"gold",sides=18)
    for dx in (-radius, radius):
        m.cylinder((x+dx,y-.013,floor),(x+dx,y-.013,floor+height),.022,.022,"bronze",8)


def insulator(m, x, y, bottom, upper):
    m.cylinder((x,y,bottom),(x,y,upper),.069,.057,"ceramic",12)
    for n in range(4):
        m.ring((x,y,bottom+(upper-bottom)*(.2+.2*n)),.075,.013,"edge",sides=12)
    m.cylinder((x,y,upper-.012),(x,y,upper+.08),.063,.038,"copper",12)


def wheel_layout(level):
    if level == 1:
        return [(+.34,-.53,.59,.31)]
    if level < 4:
        return [(+.36,-.58,.68,.34),(-.46,-.64,.598,.25)]
    if level < 7:
        return [(+.38,-.57,.73,.39),(-.44,-.56,.55,.234)]
    if level < 10:
        wheels = [(+.45,-.65,.77,.35),(-.46,-.65,.71,.31)]
        if level >= 8:
            wheels.append((.02,-.745,.52,.245))
        return wheels
    return [(.39,-.66,.80,.39),(-.43,-.655,.70,.31),(-.02,-.72,.46,.183)]


def housing(m, level, branch):
    wide = 1.26 if level < 4 else 1.38 if level < 7 else 1.52
    m.box(0,.02,.092,wide,1.18,.184,"stone")
    m.box(0,.015,.199,wide*.95,1.12,.071,"edge")
    m.box(0,.025,.262,wide*.90,1.06,.076,"iron")
    for x in (-wide*.40, wide*.40):
        m.box(x,-.548,.169,.143,.116,.24,"bronze")
        m.cylinder((x,-.60,.25),(x,-.60,.31),.03,.022,"gold",8)
    for x in (-wide*.22,0,wide*.22):
        m.box(x,-.573,.127,.018,.013,.123,"shadow")
    m.box(-.22,-.587,.124,.246,.023,.199,"cloth")
    m.box(-.22,-.600,.088,.215,.020,.022,"bronze")
    wheels = wheel_layout(level)
    for x,y,z,radius in wheels:
        m.cylinder((x,y+.21,z),(x,y+.007,z),radius*.19,radius*.16,"iron",12)
        m.cylinder((x,y+.17,.28),(x,y+.11,z-.015),radius*.26,radius*.14,"bronze",12)
    for x,y,z,radius in wheels:
        m.cylinder((x,y+.10,.29),(x,y+.055,z-.035),radius*.20,radius*.115,"iron",12)
    if level < 4:
        stack(m,-.225,.083,.38,.70,.28,"glass")
        glass_column(m,.36,.24,.48,.61,.12)
        pipe(m, ((.34,.22,1.14),(.34,.21,1.64),(-.14,.20,1.52),(-.18,.13,1.25)), (.049,.035),"bronze")
        if level >= 2:
            glass_column(m,.12,-.09,.46,.54,.085)
            m.box(-.62,.15,.69,.26,.28,.65,"iron")
            lancet(m,-.62,.003,.49,.122,.47,"bronze")
            lancet(m,-.62,-.015,.60,.085,.28,"ion")
            m.cylinder((-.62,.15,.96),(-.62,.15,1.16),.11,.038,"bronze",10)
        if level == 3:
            x,y = .40,.15
            glass_column(m,x,y,.72,.82,.164)
            m.cylinder((-.22,.26,1.35),(.42,.26,1.61),.05,.045,"copper",12)
            insulator(m,.02,.27,1.15,1.54)
            m.cylinder((.02,.27,1.54),(.36,.27,1.69),.037,.023,"bronze",10)
    elif level < 7:
        stack(m,-.126,.072,.48,.89,.36,"stack")
        for x in (-.53,.46):
            m.cylinder((x,.13,.26),(x,.13,1.56),.074,.052,"iron",8)
            for z in (.36,.84,1.40):
                m.ring((x,.13,z),.059,.017,"bronze",sides=14)
        for x in (-.52,.48):
            pipe(m, ((x,.16,1.44),(x,.17,1.78),(x*.48,.17,1.87),(-.10,.15,1.66)), (.065,.041),"bronze")
        glass_column(m,.44,.21,.54,.68,.126)
        if level >= 5:
            m.box(.035,-.30,1.085,.79,.22,.33,"iron")
            m.box(.035,-.42,1.247,.77,.075,.071,"bronze")
            for x in (-.18,0,.18):
                lancet(m,x,-.421,.96,.068,.22,"ion")
            if level == 5:
                glass_column(m,-.64,-.11,.67,.70,.109)
                pipe(m, ((-.65,-.11,1.42),(-.71,-.10,1.62),(-.44,-.09,1.68),(-.35,-.06,1.51)), (.045,.031),"copper")
        if level == 6:
            glass_column(m,.45,.26,1.20,.62,.148)
            insulator(m,-.53,.15,1.47,1.81)
            pipe(m, ((-.53,.15,1.8),(-.47,.17,2.0),(.30,.21,2.04),(.45,.26,1.8)), (.058,.043),"copper")
    else:
        cathedral = level == 10
        for sign in (-1,1):
            x = sign*.43
            stack(m,x,.20,.45,1.10 if cathedral else .84,.24,"stack" if cathedral else "glass")
            insulator(m,x,.24,1.76 if cathedral else 1.53,2.06 if cathedral else 1.75)
            m.cylinder((x,-.095,.31),(x,-.095,1.46),.070,.040,"iron",8)
            m.cylinder((x,-.08,1.39),(x,-.08,1.61),.056,.029,"gold",8)
            if level >= 9:
                glass_column(m,sign*.65,.07,.59,.73,.112)
        glass_column(m,0,-.17,.53,1.1 if cathedral else .87,.18)
        for side in (-1,1):
            top = 2.25 if cathedral else 1.83
            pipe(m, ((side*.63,.12,1.20),(side*.57,.13,top),(side*.22,.15,top+.19),(0,.15,top+.16)), (.079,.049),"bronze")
        if level >= 8:
            m.box(0,-.23,1.52,.334,.23,.28,"iron")
            lancet(m,0,-.354,1.43,.105,.25,"ion")
            m.cylinder((0,.07,1.57),(0,.07,1.86),.053,.027,"silver",12)
            if level == 8:
                m.box(-.71,-.12,1.15,.33,.27,.31,"iron")
                glass_column(m,-.82,-.19,1.14,.49,.096)
                m.cylinder((-.69,-.13,1.23),(-.73,-.13,1.71),.084,.039,"bronze",14)
        if level >= 9:
            m.box(0,.26,1.73,.86,.075,.097,"edge")
            for x in (-.27,0,.27):
                insulator(m,x,.26,1.77,2.20 if not cathedral else 2.05)
        if cathedral:
            m.cylinder((0,.18,1.96),(0,.18,2.09),.52,.51,"iron",8)
            m.cylinder((0,.18,2.09),(0,.18,2.48),.51,.136,"copper",8)
            m.cylinder((0,.18,2.46),(0,.18,2.72),.13,.022,"bronze",10)
            for side in (-1,1):
                pipe(m, ((side*.61,.18,1.92),(side*.75,.17,2.20),(side*.27,.15,2.54),(side*.14,.15,2.62)), (.058,.024),"gold")
    if branch == "regulated":
        for x in (-.44,.44):
            m.box(x,-.18,1.47,.207,.19,.53,"tempered")
            lancet(m,x,-.288,1.30,.093,.36,"bronze")
            lancet(m,x,-.305,1.41,.058,.22,"ion")
        m.box(0,-.17,1.79,1.08,.19,.20,"silver")
    elif branch == "overcharge":
        for x in (-.62,.62):
            m.cylinder((x,-.13,1.16),(x,-.13,1.84),.127,.102,"copper_dark",16)
            for n in range(8):
                m.ring((x,-.13,1.22+n*.08),.114,.03,"copper",sides=20)
            m.cylinder((x,-.13,1.78),(x*1.14,-.13,2.01),.069,.026,"ion",10)
        pipe(m, ((-.68,-.13,1.93),(-.62,-.13,2.43),(.55,-.13,2.39),(.68,-.13,1.93)), (.053,.03),"copper")


def moving_parts(m, level, _branch, phase):
    for index, (x,y,z,radius) in enumerate(wheel_layout(level)):
        direction = -1 if index % 2 else 1
        angle = phase * direction + index*.37
        axis = (0,-1,0)
        m.ring((x,y,z),radius,.035,"bronze",axis,sides=32)
        m.ring((x,y-.022,z),radius-.019,.018,"gold",axis,sides=32)
        m.cylinder((x,y+.018,z),(x,y-.05,z),radius*.19,radius*.15,"bronze",12)
        m.cylinder((x,y-.05,z),(x,y-.077,z),radius*.15,radius*.12,"gold",8)
        for n in range(5 if radius > .25 else 4):
            a = angle + math.tau*n/(5 if radius > .25 else 4)
            dx,dz = math.cos(a)*radius, math.sin(a)*radius
            m.cylinder((x+dx*.12,y,z+dz*.12),(x+dx*.91,y,z+dz*.91),.034,.027,
                       "copper" if n else "ceramic",8)
        dx,dz = math.cos(angle)*radius, math.sin(angle)*radius
        m.cylinder((x+dx*.81,y-.004,z+dz*.81),(x+dx*.81,y-.054,z+dz*.81),.042,.026,"gold",8)


def bake_atlas(path, materials, columns, rows, entries):
    """Draw any support geometry cells through the existing orthographic bake."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    swatches = {}
    for name, color in materials.items():
        mat = bpy.data.materials.new(name)
        mat.diffuse_color = color
        swatches[name] = mat
    scene = bpy.context.scene
    view = Vector((0,-1,1)).normalized()
    up = Vector((0,1,1)).normalized()
    for column,row,build in entries:
        offset = Vector(((column-(columns-1)/2)*STEP,0,0))
        offset += up * ((rows-1)/2-row)*STEP - up*.87
        model = shared.Model(offset)
        build(model)
        model.finish(f"{path.stem}_{column}_{row}",swatches)

    camera = bpy.data.objects.new("Orthographic 45°", bpy.data.cameras.new("Orthographic 45°"))
    bpy.context.collection.objects.link(camera)
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(rows,columns)*STEP
    camera.data.clip_end = 200
    camera.location = view*60
    camera.rotation_euler = (-view).to_track_quat("-Z","Y").to_euler()
    scene.camera = camera
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = CELL*columns
    scene.render.resolution_y = CELL*rows
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = True
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.studiolight_rotate_z = .38
    shading.color_type = "MATERIAL"
    shading.show_cavity = True
    shading.cavity_type = "BOTH"
    shading.cavity_ridge_factor = 1.22
    shading.cavity_valley_factor = 1.07
    shading.curvature_ridge_factor = 1.3
    shading.curvature_valley_factor = 1.12
    shading.show_shadows = False
    scene.display.render_aa = "16"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    OUTPUT.mkdir(exist_ok=True, parents=True)
    bake_atlas(OUTPUT/"base.png", PALETTE, BASE_COLUMNS, math.ceil(len(STATES)/BASE_COLUMNS), (
        (state % BASE_COLUMNS, state // BASE_COLUMNS, partial(housing, level=level, branch=branch))
        for state, (level, branch) in enumerate(STATES)
    ))
    bake_atlas(OUTPUT/"motion.png", PALETTE, MOTION_FRAMES, len(STATES), (
        (frame, state, partial(moving_parts, level=level, _branch=branch, phase=math.tau*frame/MOTION_FRAMES))
        for state, (level, branch) in enumerate(STATES) for frame in range(MOTION_FRAMES)
    ))
