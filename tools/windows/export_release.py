#!/usr/bin/env python3
"""Build a private Windows RC; native Windows execution is a separate test."""
import argparse, hashlib, json, os, pathlib, re, struct, subprocess, zipfile
ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(command, log, env):
    result = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    log.write_text(result.stdout)
    if result.returncode or re.search(r'SCRIPT ERROR|Parse Error|ERROR:|instances leaked', result.stdout):
        raise RuntimeError(f'Build validation failed; inspect {log}')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default='godot')
    parser.add_argument('--zip', default=str(ROOT / 'builds/NightfallDorm-Windows-x64.zip'))
    parser.add_argument('--evidence-dir', default='artifacts/windows-export')
    args = parser.parse_args()
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--', 'project.godot', 'export_presets.cfg', 'scripts', 'scenes', 'assets'], cwd=ROOT, check=True)
    output = ROOT / 'builds/windows'
    output.mkdir(parents=True, exist_ok=True)
    evidence = ROOT / args.evidence_dir
    evidence.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env['NIGHTFALL_PROFILE_PATH'] = 'user://windows-export-smoke.json'
    build_version = re.search(r'config/version="([^"]+)"', (ROOT / 'project.godot').read_text()).group(1)
    env['NIGHTFALL_EXPECTED_BUILD_VERSION'] = build_version
    version = subprocess.check_output([args.godot, '--version'], env=env, text=True).strip()
    if not version.startswith('4.6.3.'):
        raise RuntimeError('This RC requires the verified Godot 4.6.3 templates and engine')
    run([args.godot, '--headless', '--editor', '--import', '--quit'], evidence / 'export-import-final.log', env)
    exe = output / 'NightfallDorm.exe'
    run([args.godot, '--headless', '--path', '.', '--export-release', 'Windows Desktop', str(exe)], evidence / 'windows-export-final.log', env)
    with exe.open('rb') as f:
        header = f.read(64)
        f.seek(struct.unpack_from('<I', header, 60)[0]); pe = f.read(24)
        f.seek(-12, 2); pack_size, magic = struct.unpack('<QI', f.read(12))
        f.seek(exe.stat().st_size - 12 - pack_size); pack_header = f.read(4)
    if header[:2] != b'MZ' or pe[:4] != b'PE\0\0' or struct.unpack_from('<H', pe, 4)[0] != 0x8664 or magic != 0x43504447 or pack_header != b'GDPC':
        raise RuntimeError('Invalid Windows x86-64 executable or embedded pack')
    if os.name != 'nt':
        empty = ROOT / 'builds/pack-empty'
        empty.mkdir(exist_ok=True)
        run([args.godot, '--headless', '--path', str(empty), '--main-pack', str(exe), '--script', str(ROOT / 'tools/windows/verify_pack.gd')], evidence / 'windows-pack-final.log', env)
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    notices = {'GODOT_LICENSE.txt': ROOT / 'docs/licenses/GODOT_LICENSE.txt', 'GODOT_COPYRIGHT.txt': ROOT / 'docs/licenses/GODOT_COPYRIGHT.txt', 'FONT_DejaVu_LICENSE.txt': ROOT / 'assets/fonts/LICENSE.txt', 'FONT_GrenzeGotisch_OFL.txt': ROOT / 'assets/fonts/GrenzeGotisch-OFL.txt', 'WINDOWS_PLAYTEST_GUIDE.md': ROOT / 'docs/WINDOWS_PLAYTEST_GUIDE.md'}
    notices.update({'MUSIC_AND_AUDIO_CREDITS.md': ROOT / 'docs/AUDIO_SOURCES.md', 'VSCO_CC0_LICENSE.txt': ROOT / 'tools/audio/source/vsco/LICENSE', 'RECORDED_VOCAL_CREDITS.md': ROOT / 'tools/audio/source/vocals/CREDITS-soundboard.md', 'RECORDED_VOCAL_SOURCES.json': ROOT / 'tools/audio/source/vocals/SOURCES.json', 'VERTIGO_VOCAL_CREDITS.md': ROOT / 'tools/audio/source/vocals/vertigo-CREDITS.md'})
    (output / 'VERSION.txt').write_text(f'Nightfall Dorm {build_version}\nSource commit: {commit}\nGodot: {version}\nNative Windows runtime: UNVERIFIED by cloud build\nPrivate playtest; no public release\n')
    sha = hashlib.file_digest(exe.open('rb'), 'sha256').hexdigest()
    (output / 'SHA256SUMS.txt').write_text(sha + '  NightfallDorm.exe\n')
    archive = pathlib.Path(args.zip).resolve(); archive.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for p in [exe, output / 'VERSION.txt', output / 'SHA256SUMS.txt']: z.write(p, p.name)
        for name, p in notices.items(): z.write(p, name)
    receipt = dict(version=build_version, source_commit=commit, engine=version, executable_bytes=exe.stat().st_size, executable_sha256=sha, embedded_pack_bytes=pack_size, archive=str(archive), archive_bytes=archive.stat().st_size, archive_sha256=hashlib.file_digest(archive.open('rb'), 'sha256').hexdigest(), native_windows='UNVERIFIED', public_release=False)
    (evidence / 'windows-artifact.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))

if __name__ == '__main__': main()
