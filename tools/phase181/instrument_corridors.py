#!/usr/bin/env python3
"""Instrument the corridor CPU span in an isolated archived project only."""

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project", type=Path)
    args = parser.parse_args()
    root = args.project.resolve()
    if (root / ".git").exists() or not (root / "source-sha.txt").is_file():
        raise ValueError("Pass an isolated source copy with source-sha.txt.")
    path = root / "scripts" / "map_presentation.gd"
    code = path.read_text()
    function = code.index("func render_close_passages(")
    next_function = code.index("\nfunc ", function+1)
    declaration = code[function:code.index("\n", function)]
    parameter = "_p" if "close_passages.render" in code[function:next_function] else "p"
    forwarded = f"c,{parameter},data,theme,colors,visible"
    rename = declaration.replace("render_close_passages", "_measure_render_close_passages")
    wrapper = declaration + f"""
 var started := Time.get_ticks_usec()
 _measure_render_close_passages({forwarded})
 var elapsed := Time.get_ticks_usec() - started
 var tree := Engine.get_main_loop()
 var spans: Dictionary = tree.get_meta("phase16_span_us", {{}})
 spans["close_passages"] = int(spans.get("close_passages",0)) + elapsed
 tree.set_meta("phase16_span_us", spans)

"""
    body = code[function:next_function].replace(declaration, rename, 1)
    path.write_text(code[:function] + wrapper + body + code[next_function:])


if __name__ == "__main__":
    main()
