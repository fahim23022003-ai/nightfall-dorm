"""Author and render the Phase 14 Stalker L1 from an explicitly CC0 neutral base.

Run with Blender 4.3+:
  blender -b --python-exit-code 1 -P author_stalker.py -- base.obj output_directory

Only the MakeHuman neutral anatomy is reused. The pose, costume, hair, palette and
unseen angles are interpreted for Nightfall Dorm from its single concept image.
"""
import argparse
from array import array
import hashlib
import json
import math
from pathlib import Path
import random
import sys

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

BASE_SHA256 = "8e761e6624b8f54536409135d1636da63b32486a90d4897f84e121d144f6fb4c"
VIEW_SIZE = 512
ANGLE = math.radians(42)
TAU = math.tau
GROUND = Vector((0, 0, 0.005))
RNG = random.Random(20414)


def clamp(value):
    return min(1.0, max(0.0, value))


def smooth(value):
    t = clamp(value)
    return t * t * (3 - 2 * t)


def material(name, low, high, roughness, scale, bump, metallic=0.0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*high, 1)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    grain = nodes.new("ShaderNodeTexNoise")
    grain.inputs["Scale"].default_value = scale
    grain.inputs["Detail"].default_value = 4.3
    grain.inputs["Roughness"].default_value = 0.73
    position = nodes.new("ShaderNodeTexCoord")
    links.new(position.outputs["Object"], grain.inputs["Vector"])
    colors = nodes.new("ShaderNodeValToRGB")
    colors.color_ramp.elements[0].position = 0.26
    colors.color_ramp.elements[0].color = (*low, 1)
    colors.color_ramp.elements[1].position = 0.73
    colors.color_ramp.elements[1].color = (*high, 1)
    links.new(grain.outputs["Fac"], colors.inputs["Fac"])
    links.new(colors.outputs["Color"], shader.inputs["Base Color"])
    relief = nodes.new("ShaderNodeBump")
    relief.inputs["Strength"].default_value = 0.32
    relief.inputs["Distance"].default_value = bump
    links.new(grain.outputs["Fac"], relief.inputs["Height"])
    links.new(relief.outputs["Normal"], shader.inputs["Normal"])
    return mat


def mesh_object(name, vertices, faces, mat):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    if mat is not None:
        obj.data.materials.append(mat)
    for face in mesh.polygons:
        face.use_smooth = True
    return obj


def add_subsurf(obj, levels):
    mod = obj.modifiers.new("Surface smoothing", "SUBSURF")
    mod.levels = levels
    mod.render_levels = levels


def body_deform(v):
    v = Vector(v)
    old_z = v.z
    lean = smooth((v.z - 0.76) / 0.65)
    v.y -= 0.128 * lean
    v.x += 0.034 * lean
    v.x *= 0.63 + 0.17 * smooth((v.z - 1.22) / 0.22)
    if old_z > 1.37:
        brow = smooth((old_z - 1.39) / 0.16)
        v.x += 0.022 * brow
        v.z -= 0.038 * brow
        v.y += 0.032 * brow
        lift = -0.31 * smooth((old_z - 1.365) / 0.085)
        dy = v.y + 0.15
        dz = v.z - 1.36
        v.y = -0.15 + dy * math.cos(lift) - dz * math.sin(lift)
        v.z = 1.36 + dy * math.sin(lift) + dz * math.cos(lift)
    return v


def arm_placement(v, side):
    shoulder = Vector((side * 0.169, -0.008, 1.323))
    elbow = Vector((side * 0.321, -0.035, 1.176))
    wrist = Vector((side * 0.419, -0.166, 1.043))
    hand_axis = Vector((side * 0.061, -0.133, -0.09))
    if side > 0:
        target_shoulder = Vector((0.155, -0.108, 1.288))
        target_elbow = Vector((0.211, -0.128, 1.071))
        target_wrist = Vector((0.155, -0.245, 0.845))
        target_hand = Vector((-0.016, -0.034, -0.165))
    else:
        target_shoulder = Vector((-0.104, -0.123, 1.28))
        target_elbow = Vector((-0.147, -0.182, 1.065))
        target_wrist = Vector((-0.104, -0.266, 0.848))
        target_hand = Vector((0.012, -0.075, -0.145))

    def remap(source, source_direction, target, target_direction):
        axis = source_direction.normalized()
        fraction = (v - source).dot(axis) / source_direction.length
        offset = v - source - fraction * source_direction
        rotation = axis.rotation_difference(target_direction.normalized())
        return target + fraction * target_direction + rotation @ offset * 0.70

    upper = remap(shoulder, elbow - shoulder, target_shoulder, target_elbow - target_shoulder)
    lower = remap(elbow, wrist - elbow, target_elbow, target_wrist - target_elbow)
    fingers = remap(wrist, hand_axis, target_wrist, target_hand)
    arm = upper.lerp(lower, smooth((abs(v.x) - 0.285) / 0.082))
    arm = arm.lerp(fingers, smooth(((-v.y + abs(v.x)) - 0.547) / 0.094))
    return body_deform(v).lerp(arm, smooth((abs(v.x) - 0.123) / 0.085))


def anatomy(path, skin, eye, fabric, black):
    bpy.ops.wm.obj_import(
        filepath=str(path), use_split_objects=False, use_split_groups=True,
        forward_axis="NEGATIVE_Z", up_axis="Y",
    )
    for obj in tuple(bpy.context.selected_objects):
        if obj.name not in ("body", "helper-l-eye", "helper-r-eye"):
            bpy.data.objects.remove(obj, do_unlink=True)
            continue
        transform = obj.matrix_world.copy()
        is_body = obj.name == "body"
        obj.name = "Stalker anatomy" if is_body else "Pale clouded " + obj.name
        obj.matrix_world.identity()
        for vertex in obj.data.vertices:
            v = (transform @ vertex.co) * 0.1
            v.z += 0.81676
            if is_body and abs(v.x) > 0.12 and v.z > 0.88 and v.z < 1.4:
                vertex.co = arm_placement(v, 1 if v.x > 0.0 else -1)
            else:
                vertex.co = body_deform(v)
        obj.data.materials.clear()
        obj.data.materials.append(skin if is_body else eye)
        for poly in obj.data.polygons:
            poly.use_smooth = True
        if is_body:
            obj.data.materials.append(fabric)
            obj.data.materials.append(black)
            obj.data.update()
            for poly in obj.data.polygons:
                x, y, z = poly.center
                if (z > 1.58 or (z > 1.44 and y > -0.08)):
                    poly.material_index = 2
                elif 0.69 < z < 1.221 and abs(x - 0.029) < 0.123 and y < -0.03:
                    poly.material_index = 1
            add_subsurf(obj, 1)


def coat_surface(levels, cloth):
    vertices = []
    faces = []
    n = 128
    slices = 46
    controls = (
        (0.0, 0.319, 0.223, 0.0, 0.02),
        (0.22, 0.252, 0.181, 0.0, 0.01),
        (0.52, 0.177, 0.15, 0.004, -0.002),
        (0.77, 0.123, 0.13, 0.02, -0.04),
        (0.91, 0.117, 0.15, 0.035, -0.066),
        (1.0, 0.151, 0.161, 0.037, -0.104),
    )

    for row in range(slices + 1):
        t = row / slices
        for a, b in zip(controls, controls[1:]):
            if a[0] <= t <= b[0]:
                ratio = (t - a[0]) / (b[0] - a[0])
                rx, ry, cx, cy = [u + ratio * (v - u) for u, v in zip(a[1:], b[1:])]
                break
        for k in range(n):
            angle = k * TAU / n
            drift = 0.29 * (1 - t) ** 2 + 0.09 * math.sin(t * 5) * math.sin(angle * 3)
            ridge = (
                0.55 * math.sin(angle * 11 + drift * 12)
                + 0.28 * math.sin(angle * 22 - drift * 5)
                + 0.15 * math.sin(angle * 7 + 1.8)
                + 0.09 * math.sin(angle * 37 + t * 8)
            )
            radius = 1 + ridge * (0.19 - 0.12 * t)
            floor = 0.018 + 0.115 * (0.6 + 0.38 * math.sin(angle * 9 + 1.2) + 0.13 * math.sin(angle * 25))
            neckline = 1.244 + 0.041 * math.cos(angle + 0.55) + 0.025 * math.sin(angle * 2)
            z = floor + t * (neckline - floor)
            y = cy + ry * radius * math.sin(angle)
            x = cx + rx * radius * math.cos(angle)
            vertices.append((x, y, z))
    for row in range(slices):
        for k in range(n):
            if row < 5 and math.sin(k * 0.26 + 1.5) + 0.6 * math.sin(k * 0.63) > 1.17 + row * 0.075:
                continue
            a = row * n + k
            b = row * n + (k + 1) % n
            faces.append((a, b, b + n, a + n))
    obj = mesh_object("Floor-length torn dress", vertices, faces, cloth)
    obj.data.materials.append(levels)
    for poly in obj.data.polygons:
        poly.material_index = int(poly.center.z < 0.16 and poly.index % 17 == 0)
    solid = obj.modifiers.new("Dense woven textile thickness", "SOLIDIFY")
    solid.thickness = 0.0024


def ribbons(name, starts, palette):
    vertices = []
    faces = []
    materials = []
    steps = 28
    for index, (x, y, top, length, width, wind) in enumerate(starts):
        base = len(vertices)
        for j in range(steps + 1):
            t = j / steps
            cx = x + (t * t) * wind + 0.013 * math.sin(t * 7 + index) * t
            cy = y + 0.02 * math.sin(t * 11 + index * 0.8) * t - t * 0.035
            cz = top - length * t
            taper = (1 - t) ** 0.23
            for offset in [-1.0, -0.35, 0.35, 1.0]:
                cut = math.sin(t * 76 + index + offset * 10) * 0.14
                zz = cz + abs(offset) * t**5 * width * (math.sin(index * 5 + offset) + 0.5)
                xx = cx + (1 + cut) * width * taper * offset
                yy = cy + abs(offset) * width * (0.3 + 0.4 * math.sin(t * 14 + index))
                vertices.append((xx, yy, zz))
        for j in range(steps):
            for k in range(3):
                if j > steps - 6 and (k + j + index) % 6 == 0:
                    continue
                p = base + j * 4 + k
                faces.append((p, p + 1, p + 5, p + 4))
                materials.append(index % len(palette))
    obj = mesh_object(name, vertices, faces, None)
    for mat in palette:
        obj.data.materials.append(mat)
    for face, mat in zip(obj.data.polygons, materials):
        face.material_index = mat
    solid = obj.modifiers.new("Torn fabric thickness", "SOLIDIFY")
    solid.thickness = 0.0018


def hair_cap(hair):
    vertices = []
    faces = []
    n = 92
    rings = 25
    center = Vector((0.052, -0.114, 1.515))
    for row in range(rings + 1):
        t = row / rings
        for k in range(n):
            a = k * TAU / n
            front = max(0.0, -math.sin(a))
            edge = 2.24 - 1.02 * front + 0.65 * front * math.cos(a + 0.3)
            p = 0.01 + edge * t
            wobble = 1 + 0.037 * math.sin(a * 15 + t * 6) + 0.015 * math.sin(a * 39 - t * 7)
            vertices.append((
                center.x + 0.091 * wobble * math.sin(p) * math.cos(a),
                center.y + 0.120 * wobble * math.sin(p) * math.sin(a),
                center.z + 0.157 * math.cos(p),
            ))
    for j in range(rings):
        for k in range(n):
            a = j * n + k
            b = j * n + (k + 1) % n
            faces.append((a, b, b + n, a + n))
    mesh_object("Asymmetric dark scalp hair", vertices, faces, hair)
    return center


def flowing_hair(hair_palette, center):
    curve = bpy.data.curves.new("Separated hand-directed hair locks", "CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 5
    curve.bevel_resolution = 2
    curve.bevel_depth = 0.004
    obj = bpy.data.objects.new("Independent ragged hair mantle", curve)
    bpy.context.collection.objects.link(obj)
    for mat in hair_palette:
        curve.materials.append(mat)

    for i in range(408):
        angle = RNG.uniform(0, TAU)
        front = max(0.0, -math.sin(angle))
        if front > 0.25 and math.cos(angle) < 0.12 and RNG.random() < .995:
            continue
        strand = curve.splines.new("POLY")
        strand.points.add(19)
        strand.material_index = RNG.choices([0, 1, 2], [6, 3, 1])[0]
        start = RNG.uniform(.22, .58)
        length = RNG.uniform(.19, .63) + .22 * front
        swing = RNG.uniform(.0, .045)
        seed = RNG.random() * TAU
        base_size = RNG.uniform(.27, 1.34)
        for j, point in enumerate(strand.points):
            t = j / 19
            spread = (0.087 + swing * (t ** 1.4))
            crown = smooth(t / start)
            a = angle + .23 * (1 - crown) - t * .23 * front
            x = center.x + math.cos(a) * spread * (.42 + .58 * crown)
            y = center.y + math.sin(a) * .104 * (.44 + .56 * crown)
            x += .023 * t + .013 * t * math.sin(seed + t * 14)
            y += .06 * t * (1 - front) + .012 * t * math.cos(seed + t * 11)
            z = center.z + 0.143 * (1 - crown) - length * (t ** 1.28)
            point.co = (x, y, z, 1.0)
            point.radius = max(0.09, (1 - 0.92 * t**1.35) * base_size)


def lighting():
    for name, pos, power, size, color in [
        ("Cold window key", (-2.9, -4.1, 5.7), 390, 2.7, (0.74, 0.84, 1.0)),
        ("Limestone bounce", (3.8, -2.5, 2.0), 155, 3.1, (0.99, 0.84, 0.72)),
        ("Crypt doorway rim", (0.1, 3.1, 3.4), 460, 2.7, (0.67, 0.79, 1.0)),
    ]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy = power
        data.color = color
        data.shape = "DISK"
        data.size = size
        obj = bpy.data.objects.new(name, data)
        bpy.context.collection.objects.link(obj)
        obj.location = pos
        obj.rotation_euler = (Vector((0, 0, 0.92)) - obj.location).to_track_quat("-Z", "Y").to_euler()


def view_sockets(scene, camera):
    sockets = {
        "ground": GROUND, "head": (0.055, -0.12, 1.535),
        "mouth": (0.055, -0.260, 1.427),
        "left_shoulder": (0.155, -0.108, 1.288),
        "right_shoulder": (-0.104, -0.123, 1.28),
        "left_hand": (0.145, -0.271, 0.765),
        "right_hand": (-0.095, -0.303, 0.779),
        "hem": (0.0, -0.18, 0.11),
    }
    result = {}
    for name, pose in sockets.items():
        p = world_to_camera_view(scene, camera, Vector(pose))
        result[name] = [round(p.x, 6), round(1 - p.y, 6)]
    return result


def silhouette_bounds(path):
    image = bpy.data.images.load(str(path), check_existing=False)
    width, height = image.size
    data = array("f", [0.0]) * (width * height * 4)
    image.pixels.foreach_get(data)
    points = [(i % width, height - 1 - i // width)
              for i, alpha in enumerate(data[3::4]) if alpha >= 0.20]
    bpy.data.images.remove(image)
    x, y = zip(*points)
    return [min(x), min(y), max(x) + 1, max(y) + 1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("base", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--samples", type=int, default=16)
    args = parser.parse_args(sys.argv[sys.argv.index("--") + 1:])
    if hashlib.sha256(args.base.read_bytes()).hexdigest() != BASE_SHA256:
        raise SystemExit("Unexpected MakeHuman source asset checksum.")
    args.output.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    skin = material("Cold mottled skin", (.12, .122, .119), (.43, .383, .33), .68, 66, .007)
    eye = material("Pale clouded corneas", (.035, .032, .027), (.21, .19, .15), .29, 93, .002)
    fabric = material("Charcoal linen", (.013, .015, .018), (.07, .066, .058), .89, 72, .014)
    fabric_aged = material("Faded exposed fibers", (.026, .024, .020), (.109, .084, .06), .95, 64, .016)
    fabric_lining = material("Ragged tattered lining", (.013, .012, .011), (.051, .041, .035), 1, 63, .011)
    black = material("Dark wet stretched hair", (.006, .007, .008), (.026, .023, .023), .68, 159, .0014)
    brown = material("Wind-blown desaturated strands", (.011, .010, .009), (.048, .042, .041), .69, 161, .0012)
    gray = material("Sporadic ashen strands", (.015, .015, .016), (.075, .061, .053), .76, 151, .0015)

    anatomy(args.base, skin, eye, fabric, black)
    coat_surface(fabric_aged, fabric)
    ribbons("Torn overskirt panels", [
        (-0.126, -0.121, .93, .81, .051, -.039),
        (0.111, -0.138, .94, .79, .062, .027),
        (0.025, -0.199, .84, .70, .036, -.042),
        (-0.039, -0.161, 1.15, .54, .054, -.091),
        (0.134, .029, .96, .87, .065, .074),
        (-.138, .069, .95, .76, .052, -.062),
        (.027, .113, .95, .79, .076, .08),
        (-.015, .137, .84, .78, .075, -.027),
    ], [fabric, fabric_lining, fabric])
    ribbons("Frayed dress mantle and sleeve", [
        (-.105, -.147, 1.280, .27, .043, -.037),
        (-.100, -.055, 1.271, .28, .042, -.035),
        (.184, -.134, 1.150, .28, .037, -.027),
        (.125, -.177, 1.190, .28, .026, .013),
        (.070, -.001, 1.250, .32, .066, .027),
    ], [fabric_lining, fabric, fabric_aged])
    flowing_hair([black, brown, gray], hair_cap(black))
    lighting()

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = args.samples
    scene.cycles.use_denoising = False
    scene.render.film_transparent = True
    scene.render.resolution_x = VIEW_SIZE
    scene.render.resolution_y = VIEW_SIZE
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.file_format = "PNG"
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    scene.view_settings.view_transform = "AgX"
    scene.world.color = (.21, .21, .21)

    views = {"front": (0, -1), "rear": (0, 1), "left": (-1, 0), "right": (1, 0)}
    target = Vector((0, 0, .76))
    meta = {"size": VIEW_SIZE, "projection": "Orthographic", "elevation_degrees": 42,
            "policy": "Side and rear authored interpretations from an oblique concept", "views": {}}
    for name, (x, y) in views.items():
        camera_data = bpy.data.cameras.new(name)
        camera_data.type = "ORTHO"
        camera_data.ortho_scale = 1.94
        camera = bpy.data.objects.new(name, camera_data)
        bpy.context.collection.objects.link(camera)
        camera.location = target + Vector((x * 6, y * 6, 6 * math.tan(ANGLE)))
        camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
        scene.camera = camera
        bpy.context.view_layer.update()
        path = args.output / (name + ".png")
        view = {
            "file": path.name,
            "camera": [round(value, 6) for value in camera.location - target],
            "sockets": view_sockets(scene, camera),
        }
        meta["views"][name] = view
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        view["silhouette_bounds_px"] = silhouette_bounds(path)
    scene.camera = bpy.data.objects["front"]
    scene.render.filepath = "//front.png"
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output / "stalker_l1.blend"))
    (args.output / "turnaround.json").write_text(json.dumps(meta, indent=2) + "\n")


if __name__ == "__main__":
    main()
