#!/usr/bin/env python3
"""Instrument CPU spans in a detached profiling copy of the Phase 16 baseline.

The injected function wrappers charge both nested and parent spans. Run a
separate unmodified process for renderer comparisons. The instrumentation has
measurable overhead and is intended for hotspot diagnosis only.
"""
import argparse
from pathlib import Path
import re

SPANS = [
    ("game.gd", "_draw", "", "", "world_draw", ""),
    ("match_model.gd", "tick", "delta: float", "delta", "model_tick", ""),
    ("interface.gd", "update_match", "", "", "ui_update", ""),
    ("interface.gd", "action_reason", "action: String", "action", "ui_action_reason", "String"),
    ("interface.gd", "theme_button", 'control: Button, role: String = "secondary", icon_id: String = ""',
     "control, role, icon_id", "ui_theme_button", "void"),
    ("interface.gd", "refresh_context", "", "", "ui_refresh_context", ""),
    ("construction_controls.gd", "refresh", "", "", "construction_refresh", ""),
    ("bottom_context_panel.gd", "refresh", "", "", "bottom_context_refresh", ""),
    ("audio_director.gd", "update_state", "delta: float, model, mode: String, watching_hunter: bool=false",
     "delta, model, mode, watching_hunter", "audio_update", ""),
    ("dorm_presentation.gd", "update", "delta: float, model", "delta, model", "presentation_update", ""),
    ("dorm_presentation.gd", "hunter", "c,h", "c,h", "hunter_draw", ""),
    ("dorm_presentation.gd", "render_hunter_combat", "c, model, visible: Rect2,hunter_in_view: bool",
     "c, model, visible, hunter_in_view", "hunter_combat_draw", ""),
    ("map_presentation.gd", "render_architecture", "c,p", "c,p", "architecture_draw", ""),
    ("map_presentation.gd", "render_tiles", "c,p,room,owned", "c,p,room,owned", "building_tiles_draw", ""),
    ("building_evolution_visual.gd", "weapon_target", "model, room, tile: int, kind: String, activity: float",
     "model, room, tile, kind, activity", "weapon_target", "Vector2"),
    ("articulated_hunter.gd", "draw",
     "c: CanvasItem, family: String, floor: Vector2, tint: Color, heading: Vector2, clock: float, gait: float, stride: float, motion: String, progress: float, target: Vector2, reduced: bool, show_weapon:=true",
     "c, family, floor, tint, heading, clock, gait, stride, motion, progress, target, reduced, show_weapon",
     "articulated_rig_draw", "bool"),
]

RECORD = """
static func _phase16_record(label: String, begin: int) -> void:
 var measured := Time.get_ticks_usec() - begin
 var tree := Engine.get_main_loop()
 var spans: Dictionary = tree.get_meta("phase16_span_us", {})
 spans[label] = int(spans.get(label, 0)) + measured
 tree.set_meta("phase16_span_us", spans)
"""


def inject(path: Path, name: str, arguments: str, forwarding: str, label: str, result: str) -> None:
    source = path.read_text()
    annotation = f" -> {result}" if result else ""
    signature = f"func {name}({arguments}){annotation}:\n"
    if source.count(signature) != 1:
        raise ValueError(f"Expected exactly one {path.name} declaration: {signature.strip()}")
    wrapper = signature + " var began := Time.get_ticks_usec()\n"
    has_result = result not in ("", "void")
    wrapper += f" {'var result := ' if has_result else ''}_phase16_{name}({forwarding})\n"
    wrapper += f' _phase16_record("{label}", began)\n'
    if has_result:
        wrapper += " return result\n"
    wrapper += f"\nfunc _phase16_{name}({arguments}){annotation}:\n"
    path.write_text(source.replace(signature, wrapper))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    args = parser.parse_args()
    project = args.project.resolve()
    baseline = project / "source-sha.txt"
    if not baseline.is_file() or (project / ".git").exists():
        raise ValueError("Use a detached project copy marked by source-sha.txt")
    touched = set()
    for file, name, arguments, forwarding, label, result in SPANS:
        path = project / "scripts" / file
        inject(path, name, arguments, forwarding, label, result)
        touched.add(path)
    for path in touched:
        path.write_text(path.read_text()+"\n"+RECORD)
    # Exclude the entire draw loop's event visuals from the projectile-only span.
    dorm = project / "scripts/dorm_presentation.gd"
    source = dorm.read_text()
    a = " for shot in m.projectiles:\n"
    b = " for e in visual_events:\n"
    if source.count(a) != 1 or source.count(b) != 1:
        raise ValueError("Cannot identify exact Dorm render boundaries")
    source = source.replace(a, " var projectile_begin := Time.get_ticks_usec()\n"+a)
    source = source.replace(b, ' _phase16_record("projectiles_draw", projectile_begin)\n'+b)
    dorm.write_text(source)
    match_ui = project / "scripts/interface.gd"
    source = match_ui.read_text()
    a = ' quick_repair.disabled=action_reason("repair")!=""\n'
    b = " refresh_context()\n if game.mobile_mode: game.mobile_ui.update_match(self)\n"
    if source.count(a) != 1 or source.count(b) != 1:
        raise ValueError("Cannot identify exact match action list boundaries")
    source = source.replace(a, a+" var action_list_begin := Time.get_ticks_usec()\n")
    source = source.replace(b, ' _phase16_record("ui_action_list", action_list_begin)\n'+b)
    match_ui.write_text(source)
    print(f"Instrumented {len(SPANS)+2} CPU spans across {len(touched)} files.")


if __name__ == "__main__":
    main()
