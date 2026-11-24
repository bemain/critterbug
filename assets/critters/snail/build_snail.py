# Builds the placeholder snail critter and exports it as snail.glb next to this script.
# Run headless:
#   host-spawn -no-pty flatpak run --filesystem=<repo> org.blender.Blender -b --python build_snail.py
# Units are game units (a band member is 1 tall). The snail faces Blender -Y, which is +Z in Godot.
import math
import os

import bpy
from mathutils import Vector

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "snail.glb")

COLOURS = {
    "Skin": (0.85, 0.72, 0.52),
    "Shell": (0.80, 0.38, 0.20),
    "ShellBand": (0.47, 0.22, 0.13),
    "EyeWhite": (0.96, 0.94, 0.90),
    "Pupil": (0.10, 0.08, 0.07),
}


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def material(name: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*(srgb_to_linear(c) for c in COLOURS[name]), 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    return mat


def finish(obj: bpy.types.Object, name: str, mat: bpy.types.Material, parent: bpy.types.Object) -> bpy.types.Object:
    obj.name = name
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = False
    obj.parent = parent
    return obj


def sphere(name, mat, parent, location, scale, segments=14, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, location=location)
    obj = bpy.context.active_object
    obj.scale = scale
    return finish(obj, name, mat, parent)


def stalk(name, mat, parent, start, end, radius):
    start, end = Vector(start), Vector(end)
    direction = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=radius, depth=direction.length,
                                        location=(start + end) / 2)
    obj = bpy.context.active_object
    obj.rotation_euler = Vector((0, 0, 1)).rotation_difference(direction).to_euler()
    return finish(obj, name, mat, parent)


def build() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    mats = {name: material(name) for name in COLOURS}
    bpy.ops.object.empty_add(location=(0, 0, 0))
    root = bpy.context.active_object
    root.name = "Snail"

    # Foot and head: a long, low body that rises into a head at the front.
    sphere("Foot", mats["Skin"], root, (0, -0.1, 0.22), (0.42, 1.25, 0.24))
    sphere("Neck", mats["Skin"], root, (0, -0.95, 0.5), (0.3, 0.32, 0.42))
    sphere("Head", mats["Skin"], root, (0, -1.1, 0.85), (0.32, 0.3, 0.28))

    # Shell: a round shell on the back with a band and a whorl on each side.
    sphere("Shell", mats["Shell"], root, (0, 0.25, 1.0), (0.55, 0.72, 0.72), segments=16, rings=10)
    for side in (-1, 1):
        bpy.ops.mesh.primitive_torus_add(major_radius=0.42, minor_radius=0.07, major_segments=16, minor_segments=6,
                                         location=(side * 0.45, 0.25, 1.0), rotation=(0, math.pi / 2, 0))
        finish(bpy.context.active_object, f"ShellBand{'L' if side < 0 else 'R'}", mats["ShellBand"], root)
        sphere(f"Whorl{'L' if side < 0 else 'R'}", mats["ShellBand"], root, (side * 0.5, 0.25, 1.0),
               (0.12, 0.2, 0.2), segments=10, rings=6)

    # Eye stalks with big eyes looking forward: the face direction.
    for side in (-1, 1):
        tag = "L" if side < 0 else "R"
        top = (side * 0.24, -1.28, 1.55)
        stalk(f"Stalk{tag}", mats["Skin"], root, (side * 0.1, -1.12, 1.0), top, 0.05)
        sphere(f"Eye{tag}", mats["EyeWhite"], root, top, (0.13, 0.13, 0.13), segments=12, rings=8)
        sphere(f"Pupil{tag}", mats["Pupil"], root, (top[0], top[1] - 0.1, top[2]), (0.065, 0.05, 0.065),
               segments=10, rings=6)

    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_apply=True, export_yup=True)


build()
