"""Bake the original Phase 14 Needle models into Godot atlas layers.

Run from the repository root:
    blender -b -t 4 --python tools/visual_rebirth/bake_needle.py
"""
import math
from pathlib import Path

import bpy
from mathutils import Vector

SHEET = Path("assets/visual_rebirth/buildings/turret").resolve()
CELL = 112
TILE = 3.75
VIEWS = 12
PALETTE = {
    "iron": (.15, .16, .17, 1),
    "edge": (.34, .31, .26, 1),
    "bronze": (.37, .23, .105, 1),
    "gold": (.57, .38, .17, 1),
    "stone": (.25, .248, .23, 1),
    "cloth": (.18, .108, .105, 1),
    "glass": (.13, .42, .47, 1),
    "silver": (.51, .54, .56, 1),
    "shadow": (.09, .076, .06, 1),
}
STATES = [(level, "") for level in range(1, 11)]
STATES += [(level, branch) for branch in ("precision", "suppression") for level in range(5, 11)]


class Model:
    def __init__(self, offset, yaw=0.0):
        self.offset = offset
        self.sine, self.cosine = math.sin(yaw), math.cos(yaw)
        self.vertices, self.faces, self.colors, self.smoothing = [], [], [], []

    def add(self, vertices, faces, color, smooth=False):
        start = len(self.vertices)
        for x, y, z in vertices:
            self.vertices.append(self.offset + Vector((x*self.cosine-y*self.sine, x*self.sine+y*self.cosine, z)))
        self.faces.extend(tuple(start + index for index in face) for face in faces)
        self.colors.extend([color] * len(faces))
        self.smoothing.extend([smooth] * len(faces))

    def cylinder(self, start, end, lower, upper, color, sides=16):
        start, end = Vector(start), Vector(end)
        axis = (end - start).normalized()
        lateral = axis.cross(Vector((0, 1, 0)))
        if lateral.length < .001:
            lateral = axis.cross(Vector((1, 0, 0)))
        lateral.normalize()
        up = axis.cross(lateral)
        vertices = []
        for center, radius in ((start, lower), (end, upper)):
            for side in range(sides):
                angle = math.tau * side / sides
                vertices.append(center + radius * (lateral*math.cos(angle) + up*math.sin(angle)))
        faces = [(i, (i+1) % sides, (i+1) % sides+sides, i+sides) for i in range(sides)]
        self.add(vertices, faces, color, True)
        self.add(vertices, [tuple(reversed(range(sides))), tuple(range(sides, 2*sides))], color)

    def box(self, x, y, z, sx, sy, sz, color):
        vertices = [(x+dx*sx/2, y+dy*sy/2, z+dz*sz/2)
                    for dx, dy, dz in ((-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),
                                       (-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1))]
        self.add(vertices, [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)], color)

    def ring(self, center, radius, thickness, color, axis=(0, 0, 1), begin=0, end=math.tau, sides=32, tip=None):
        center, axis = Vector(center), Vector(axis)
        u = Vector((1, 0, 0))
        v = axis.cross(u)
        section = 8
        vertices = []
        for i in range(sides+1):
            t = i/sides
            angle = begin + (end-begin)*t
            radial = u*math.cos(angle) + v*math.sin(angle)
            chord = thickness if tip is None else thickness + t*(tip-thickness)
            for k in range(section):
                a = k*math.tau/section
                vertices.append(center + radial*(radius + chord*math.cos(a)) + axis*(thickness*math.sin(a)))
        faces = []
        for i in range(sides):
            for k in range(section):
                a, b = i*section+k, i*section+(k+1)%section
                faces.append((a,b,b+section,a+section))
        self.add(vertices, faces, color, True)

    def finish(self, name, materials):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        bpy.context.collection.objects.link(obj)
        for material in materials.values():
            mesh.materials.append(material)
        order = {key: i for i, key in enumerate(materials)}
        for polygon, color, smoothing in zip(mesh.polygons, self.colors, self.smoothing):
            polygon.material_index = order[color]
            polygon.use_smooth = smoothing


def build_base(m, level, branch):
    width = .53 + (.105 if level >= 4 else 0) + (.085 if level >= 7 else 0)
    m.box(0, 0, .08, 1.24*width/.57, 1.11, .16, "shadow")
    m.box(0, 0, .20, 1.16*width/.57, 1.04, .16, "stone")
    m.box(0, 0, .30, 1.08*width/.57, .94, .10, "edge")
    # Three copper bindings and recessed masonry seams.
    for side in (-1, 1):
        m.box(side*.31, -.534, .19, .16, .045, .16, "iron")
        for x in (-.37, 0, .37):
            m.box(x, side*.512, .157, .015, .028, .086, "shadow")
    # The front drape folds over the plinth's outer edge.
    cloth = [(x, -.475, .356 + wave) for x, wave in ((-.25,0),(-.16,.023),(-.07,-.006),(.02,.022),(.11,0))]
    cloth += [(x+.015, -.568, .06 + wave) for x, wave in ((-.25,.01),(-.16,.038),(-.07,-.012),(.02,.027),(.11,0))]
    m.add(cloth, [(i, i+1, i+6, i+5) for i in range(4)], "cloth")
    for x in (-.23,-.14,-.05,.04,.13):
        m.cylinder((x,-.569,.07),(x+.03,-.569,.09),.013,.008,"bronze",6)
    m.cylinder((0,0,.33),(0,0,.46),.24,.19,"bronze")
    m.cylinder((0,0,.45),(0,0,1.01),.135,.135,"glass")
    m.cylinder((0,0,.96),(0,0,1.14),.18,.17,"iron")
    for z in (.44, .52, .89, .99):
        m.ring((0,0,z), .153, .024, "gold")
    legs = 4 if level >= 7 else 3
    for n in range(legs):
        angle = math.tau * n / legs + .5
        x, y = math.cos(angle), math.sin(angle)
        foot = (x*width*.87, y*.393, .33)
        shoulder = (x*.23, y*.22, 1.14)
        knee = (x*.33, y*.31, .60)
        m.cylinder(foot, knee, .083, .068, "iron")
        m.cylinder(knee, shoulder, .069, .052, "iron")
        m.cylinder((foot[0],foot[1],.297),(foot[0],foot[1],.401),.106,.083,"bronze")
        m.cylinder((foot[0],foot[1],.374),(foot[0]*.91,foot[1]*.91,.55),.037,.033,"edge")
        if level >= 2:
            m.cylinder((foot[0]*1.12,foot[1]*1.12,.37),(x*.22,y*.20,.71),.047,.031,"gold")
        if level >= 6:
            m.cylinder((x*.34,y*.29,.53),shoulder,.023,.032,"bronze")
        if level >= 9:
            m.cylinder((x*width*.93,y*.43,.32),(x*.31,y*.27,.86),.045,.030,"silver")
    m.cylinder((0,0,1.09),(0,0,1.21),.28,.28,"iron",24)
    m.cylinder((0,0,1.21),(0,0,1.31),.25,.19,"bronze",24)
    m.ring((0,0,.69),.142,.018,"bronze")
    if 4 <= level < 7:
        m.ring((0,0,.77),.48,.062,"bronze")
        m.ring((0,0,.85),.445,.026,"gold")
        for side in (-1, 1):
            m.cylinder((side*.48,.08,.32),(side*.46,.08,.69),.075,.052,"iron")
            m.cylinder((side*.46,.08,.69),(side*.26,.07,1.10),.052,.046,"bronze")
            m.cylinder((side*.40,.18,.51),(side*.57,.18,1.05),.067,.038,"iron")
            m.cylinder((side*.57,.18,1.05),(side*.51,.18,1.16),.039,.007,"gold")
    if level >= 7:
        m.ring((0,0,1.03),.42,.059,"iron")
        m.ring((0,0,1.067),.417,.023,"gold")
        for side in (-1, 1):
            m.box(side*.61,-.20,.35,.33,.36,.26,"stone")
            m.box(side*.66,-.19,.51,.26,.29,.12,"iron")
            m.cylinder((side*.69,-.18,.54),(side*.62,-.18,1.11),.119,.089,"bronze")
            m.cylinder((side*.62,-.18,1.11),(side*.47,-.18,1.28),.091,.038,"iron")
            m.cylinder((side*.54,-.36,.43),(side*.54,-.36,.87),.083,.066,"glass")
            m.cylinder((side*.54,-.36,.86),(side*.54,-.36,.92),.094,.069,"gold")
    if 7 <= level < 10:
        for side in (-1,1):
            m.cylinder((side*.63,.28,.84),(side*.76,.28,1.52),.098,.064,"iron")
            m.cylinder((side*.76,.28,1.52),(side*.48,.28,1.82),.068,.023,"bronze")
            m.cylinder((side*.48,.28,1.82),(side*.37,.28,1.84),.033,.004,"gold")
            m.cylinder((side*.53,.27,1.08),(side*.76,.28,1.52),.048,.034,"edge")
    if level == 10:
        m.ring((0,0,.52),.49,.047,"bronze")
        for side in (-1,1):
            m.cylinder((side*.70,.38,.40),(side*.75,.35,1.07),.112,.063,"iron")
            m.cylinder((side*.75,.35,1.07),(side*.67,.34,1.48),.068,.025,"bronze")
            m.cylinder((side*.67,.34,1.48),(side*.63,.34,1.63),.032,.006,"gold")
            m.cylinder((side*.46,.30,1.00),(side*.67,.34,1.48),.055,.027,"edge")
    if branch == "precision":
        m.box(.33,-.07,.56,.29,.46,.39,"iron")
        m.box(.37,-.30,.56,.27,.051,.30,"silver")
        m.box(.50,-.11,.71,.12,.29,.15,"edge")
    elif branch == "suppression":
        for x in (-.22,.22):
            m.cylinder((x,-.35,.35),(x,-.35,.73),.106,.083,"glass")
            m.cylinder((x,-.35,.73),(x,-.35,.81),.094,.073,"bronze")
            m.ring((x,-.35,.64),.097,.025,"gold")


def build_head(m, level, branch):
    z = 1.59
    m.cylinder((0,0,1.27),(0,0,1.40),.18,.22,"iron")
    m.ring((0,0,1.34),.215,.034,"gold")
    m.cylinder((0,-.24,z),(0,.24,z),.16,.16,"iron")
    for sign in (-1, 1):
        m.cylinder((0,sign*.245,z),(0,sign*.295,z),.113,.092,"bronze")
        m.cylinder((0,sign*.297,z),(0,sign*.320,z),.047,.039,"gold")
    # Swept brass crescent is an ornamental yoke, never a second weapon.
    m.ring((-.10,.18,1.74), .48, .071, "bronze", (0,1,0), 1.49, 4.85, tip=.028)
    m.ring((-.10,.252,1.74), .483, .018, "gold", (0,1,0), 1.49, 4.76)
    m.cylinder((-.037,.179,2.216),(-.037,.179,2.09),.029,.045,"bronze")
    m.cylinder((-.037,.179,2.09),(-.037,.179,2.02),.045,.015,"glass")

    # The dart cluster remains a single visual launch, even with multiple rails.
    lanes = [(0, 0, 1.0), (.089, .092, .82), (-.089, -.092, .82)]
    if level >= 4:
        lanes.extend([(.143,-.14,.94),(-.143,.14,.98)])
        m.cylinder((-.18,-.23,z+.15),(.52,-.23,z+.15),.083,.052,"bronze")
        m.ring((-.10,.19,1.78), .58, .038, "iron", (0,1,0), 1.56, 4.55, tip=.020)
    if level >= 7:
        lanes.extend([(.35,.18,.87),(-.35,.18,.87),(.23,-.19,.72),(-.23,-.19,.72)])
    if level == 10:
        lanes.extend([(.24,.33,.79),(-.24,.33,.79), (0,.42,.84)])
    if branch == "precision":
        lanes = [(y*.82,h, length) for y,h,length in lanes]
        m.cylinder((.07,0,z),(.57,0,z),.159,.113,"iron")
        m.cylinder((.53,0,z),(.68,0,z),.121,.098,"bronze")
        m.cylinder((.67,0,z),(.83,0,z),.098,.063,"edge")
        m.cylinder((-.16,0,z+.03),(-.16,0,z+.39),.035,.026,"iron")
        m.cylinder((-.21,0,z+.38),(.43,0,z+.38),.038,.024,"silver")
    if branch == "suppression":
        lanes = [(y*1.12,h, length) for y,h,length in lanes]
        for side in (-1, 1):
            m.cylinder((-.10,side*.20,z+.02),(.43,side*.39,z+.14),.081,.055,"bronze")
            m.cylinder((.43,side*.39,z+.14),(.68,side*.59,z+.18),.054,.012,"silver")
            m.cylinder((.09,side*.25,z-.08),(.35,side*.60,z-.16),.042,.022,"bronze")
    for i, (y, height, length) in enumerate(lanes):
        bore = .064 if i == 0 else .039
        if branch == "precision" and i == 0:
            bore *= 1.33
        if branch == "suppression" and i > 0:
            bore *= 1.18
        end = .91*length
        m.cylinder((.00,y,z+height),(.35,y,z+height),bore*1.30,bore*1.11,"bronze")
        m.cylinder((.27,y,z+height),(end-.12,y,z+height),bore,bore*.85,"iron")
        m.cylinder((end-.15,y,z+height),(end-.09,y,z+height),bore*.98,bore*.92,"gold")
        m.cylinder((end-.10,y,z+height),(end,y,z+height),bore*.78,.006,"silver")
    if level >= 3:
        m.ring((-.32,-.03,z),.168,.041,"silver",(0,1,0))
        m.cylinder((-.40,0,z),(0,0,z),.105,.068,"iron")
    if level >= 4:
        m.cylinder((.25,-.25,z),(.25,.25,z),.044,.044,"edge")
    if level >= 5 and branch == "":
        m.cylinder((.02,-.24,z-.16),(.47,-.24,z-.16),.056,.038,"edge")
    if level >= 6:
        m.cylinder((-.23,-.24,z-.18),(.49,-.24,z-.18),.056,.027,"bronze")
    if level >= 7:
        for sign in (-1,1):
            m.cylinder((0,sign*.14,z+.01),(.39,sign*.40,z+.19),.066,.042,"bronze")
            m.cylinder((.39,sign*.40,z+.19),(.72,sign*.45,z+.23),.045,.014,"silver")
    if level >= 8:
        m.ring((.38,-.04,z),.253,.036,"gold",(0,1,0))
        m.cylinder((.37,-.40,z-.08),(.37,.40,z-.08),.062,.062,"iron")
    if level >= 9:
        for sign in (-1,1):
            m.cylinder((-.18,sign*.16,z-.075),(.52,sign*.31,z-.055),.038,.032,"iron")
    if level == 10:
        for side in (-1,1):
            m.ring((.02,side*.34,1.91),.64,.061,"iron",(0,1,0),1.78,4.62,tip=.019)
            m.ring((.02,side*.40,1.91),.640,.029,"gold",(0,1,0),1.78,4.62,tip=.015)
            m.cylinder((-.20,side*.34,2.53),(.21,side*.34,2.62),.041,.012,"silver")
            m.cylinder((-.26,side*.32,2.28),(.58,side*.36,2.32),.035,.011,"silver")
        m.cylinder((-.16,0,2.1),(.69,0,2.19),.086,.019,"bronze")


def bake(name, columns, rows, build):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    materials = {}
    for name_key, color in PALETTE.items():
        material = bpy.data.materials.new(name_key)
        material.diffuse_color = color
        materials[name_key] = material

    scene = bpy.context.scene
    view = Vector((0,-1,1)).normalized()
    up = Vector((0,1,1)).normalized()
    for index, (level, branch) in enumerate(STATES):
        if name == "base":
            cells = [(index % columns, index // columns, 0.0)]
        else:
            cells = [(heading, index, math.tau*heading/columns) for heading in range(columns)]
        for column, row, yaw in cells:
            offset = Vector(((column-(columns-1)/2)*TILE, 0, 0))
            offset += up * ((rows-1)/2-row)*TILE
            # The base contact appears near the lower edge in every cell.
            offset -= up*.87
            model = Model(offset, yaw)
            build(model,level,branch)
            model.finish(f"{name}_{column}_{row}",materials)

    camera_data = bpy.data.cameras.new("Orthographic 45°")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = max(rows,columns)*TILE
    camera_data.clip_end = 200
    camera = bpy.data.objects.new("Camera",camera_data)
    bpy.context.collection.objects.link(camera)
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
    scene.render.filepath = str(SHEET / f"{name}.png")
    bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    SHEET.mkdir(parents=True,exist_ok=True)
    bake("base", 6, 4, build_base)
    bake("launcher", VIEWS, len(STATES), build_head)
