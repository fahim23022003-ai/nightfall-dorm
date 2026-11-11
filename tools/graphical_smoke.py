#!/usr/bin/env python3
"""Real-input smoke, not a model fixture. Requires Xorg :99, ImageMagick, X11/XTest.
Run from any directory. Saves evidence screenshots; inspect them for expected UI.
"""
import ctypes
import os
from pathlib import Path
import re
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'docs' / 'evidence'
LOG = Path('/tmp/nightfall-graphical-smoke.log')
ENV = dict(os.environ, DISPLAY=':99', LIBGL_ALWAYS_SOFTWARE='1',
           XDG_DATA_HOME='/workspace/runtime-data',
           XDG_CONFIG_HOME='/workspace/runtime-config',
           XDG_CACHE_HOME='/workspace/runtime-cache')
for name in ('XDG_DATA_HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME'):
    Path(ENV[name]).mkdir(parents=True, exist_ok=True)


origin = (0, 0)
scale = 1.0

def input_event(*args):
    if args[0] in ('click', 'move'):
        args = (args[0], round(int(args[1]) * scale + origin[0]), round(int(args[2]) * scale + origin[1]))
    subprocess.run(['python', str(ROOT / 'tools' / 'x11_input.py'), *map(str, args)],
                   env=ENV, check=True)
    time.sleep(.25)


def ocr(name):
    return subprocess.check_output(['tesseract', str(EVIDENCE / name), 'stdout', '--psm', '11'], text=True, stderr=subprocess.DEVNULL)

def screenshot(name):
    subprocess.run(['import', '-display', ':99', '-window', hex(window),
                    str(EVIDENCE / name)], env=ENV, check=True)


with LOG.open('w') as log:
    process = subprocess.Popen(['godot', '--path', str(ROOT), '--rendering-method',
                                'gl_compatibility', '--audio-driver', 'Dummy', '--borderless'],
                               env=ENV, stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise RuntimeError(f'Godot exited early: {process.returncode}; see {LOG}')
            if 'OpenGL API' in LOG.read_text():
                break
            time.sleep(.25)
        else:
            raise RuntimeError(f'Renderer did not initialize in 90s; see {LOG}')
        time.sleep(1)
        tree = subprocess.check_output(['xwininfo', '-display', ':99', '-root', '-tree'], text=True)
        match = re.search(r'(0x[0-9a-f]+) "Nightfall Dorm', tree)
        if not match:
            raise RuntimeError('Nightfall Dorm X11 window not found')
        window = int(match.group(1), 16)
        x = ctypes.CDLL('libX11.so.6')
        x.XOpenDisplay.argtypes = [ctypes.c_char_p]
        x.XOpenDisplay.restype = ctypes.c_void_p
        display = x.XOpenDisplay(b':99')
        x.XSetInputFocus.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
        x.XFlush.argtypes = [ctypes.c_void_p]
        x.XMoveResizeWindow.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_int, ctypes.c_int, ctypes.c_uint, ctypes.c_uint]
        x.XMoveResizeWindow(display, window, 0, 0, 1280, 800)
        x.XSetInputFocus(display, window, 2, 0)
        x.XFlush(display)
        time.sleep(.25)
        x.XDefaultRootWindow.argtypes = [ctypes.c_void_p]
        x.XDefaultRootWindow.restype = ctypes.c_ulong
        x.XTranslateCoordinates.argtypes = [ctypes.c_void_p, ctypes.c_ulong, ctypes.c_ulong, ctypes.c_int, ctypes.c_int, ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_int), ctypes.POINTER(ctypes.c_ulong)]
        ox, oy, child = ctypes.c_int(), ctypes.c_int(), ctypes.c_ulong()
        x.XTranslateCoordinates(display, window, x.XDefaultRootWindow(display), 0, 0, ctypes.byref(ox), ctypes.byref(oy), ctypes.byref(child))
        geometry = subprocess.check_output(['xwininfo', '-display', ':99', '-id', hex(window)], text=True)
        width = int(re.search(r'Width:\s+(\d+)', geometry).group(1))
        height = int(re.search(r'Height:\s+(\d+)', geometry).group(1))
        scale = min(width / 1280, height / 800)
        origin = (ox.value + (width - 1280 * scale) / 2, oy.value + (height - 800 * scale) / 2)
        screenshot('audit-input-menu.png')
        input_event('click', 625, 339)  # Start Game.
        input_event('key', 'w', 2.0)  # Enter middle north room.
        input_event('key', 'e', .1)    # Claim it.
        input_event('key', 'a', .48)
        input_event('key', 'w', .8)  # Clamp against the room's north wall; remain near bed.   # Approach cyan bed.
        input_event('key', 'e', .1)    # Sleep and close the door.
        input_event('click', 1100, 404)  # Buy Needle turret on selected tile 1.
        input_event('key', 'Escape', .1)
        screenshot('audit-input-sleep-build.png')
        sleep_text = ocr('audit-input-sleep-build.png')
        if 'SLEEPING' not in sleep_text or not re.search(r'Turret\s+L1', sleep_text, re.I):
            raise RuntimeError('Rendered OCR did not confirm sleeping with a selected Turret L1; inspect screenshot.')
        input_event('click', 530, 190)  # Select another valid empty tile in the claimed room.
        screenshot('audit-input-selection.png')
        selection_text = ocr('audit-input-selection.png')
        if not re.search(r'Tile\s*2', selection_text, re.I):
            raise RuntimeError('Rendered OCR did not confirm selection of tile 2.')
        input_event('key', 'Escape', .1)  # Resume genuine bed income.
        time.sleep(15)
        input_event('click', 1100, 490)  # Build Dynamo on the selected second tile.
        time.sleep(3)
        input_event('key', 'Escape', .1)
        screenshot('audit-input-generator.png')
        generator_text = ocr('audit-input-generator.png')
        electricity = re.search(r'Electricity:\s*(\d+)', generator_text, re.I)
        if 'SLEEPING' not in generator_text or not re.search(r'Generator\s+L1', generator_text, re.I) or not electricity or int(electricity.group(1)) <= 0:
            raise RuntimeError('Rendered OCR did not confirm sleeping, Generator L1 and positive electricity.')
        (EVIDENCE / 'audit-input-ocr.txt').write_text('SLEEP/BUILD\n' + sleep_text + '\nSELECTION\n' + selection_text + '\nGENERATOR\n' + generator_text)
        input_event('move', 1100, 448)  # Hover Arc turret effect/prerequisite tooltip.
        time.sleep(1.2)
        screenshot('audit-input-tooltip.png')
        input_event('click', 1100, 773)  # Return from an active paused match.
        screenshot('audit-input-return-menu.png')
        text = LOG.read_text()
        if 'SCRIPT ERROR' in text or '\nERROR:' in text:
            raise RuntimeError(f'Runtime errors in {LOG}')
        print('Real keyboard/mouse sequence executed; no runtime errors in log.')
        print('Inspect audit-input-sleep-build.png: ROOM 2 SLEEPING, turret and gold deduction.')
        print('Inspect audit-input-selection.png: tile 2 highlighted; audit-input-generator.png: Dynamo and electricity.')
        print(f'Log: {LOG}')
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
