"""Verify a real signed Godot Android APK. No source ZIP substitution."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,zipfile
parser=argparse.ArgumentParser()
parser.add_argument('apk',type=Path)
parser.add_argument('--sdk-root',type=Path,default=Path(os.environ.get('ANDROID_SDK_ROOT',os.environ.get('ANDROID_HOME','/workspace/android-sdk'))))
args=parser.parse_args()
if not args.apk.is_file():raise SystemExit('APK does not exist: '+str(args.apk))
with zipfile.ZipFile(args.apk) as z:
 names=set(z.namelist())
 assert 'AndroidManifest.xml' in names,'No real Android manifest'
 assert 'classes.dex' in names,'No Android executable classes'
 assert 'assets/project.binary' in names,'Missing Godot project'
 assert any(n.startswith('assets/') and n.endswith('.gdc') for n in names),'No compiled gameplay scripts'
 for script in ['game','touch_controls','mobile_layout','mobile_interface','player_profile','audio_director']:
  assert 'assets/scripts/'+script+'.gd.remap' in names or 'assets/scripts/'+script+'.gd' in names,'Missing '+script
 abis=sorted({n.split('/')[1] for n in names if n.startswith('lib/') and n.endswith('.so')})
 assert {'arm64-v8a','armeabi-v7a'}<=set(abis),'Missing ARM support'
 assert not any(n.endswith(('.keystore','.jks')) for n in names),'Signing key packaged accidentally'
 assert not any(n.startswith('assets/docs/') or n.startswith('assets/tests/') for n in names),'Development evidence/tests packaged'
 size=args.apk.stat().st_size
 print('APK_ZIP_RESOURCES=PASS')
 print('APK_ABIS='+','.join(abis))
 print('APK_BYTES='+str(size))
 print('APK_SHA256='+hashlib.sha256(args.apk.read_bytes()).hexdigest())
versions=sorted((args.sdk_root/'build-tools').glob('*'),key=lambda p:tuple(int(x) for x in re.findall(r'\d+',p.name)),reverse=True)
if not versions:raise SystemExit('Build tools missing; cannot verify APK signature/manifest')
tools=versions[0]
def command(name):
 suffix=('.bat' if name=='apksigner' else '.exe') if os.name=='nt' else ''
 executable=tools/(name+suffix)
 return [os.environ.get('COMSPEC','cmd.exe'),'/d','/c',str(executable)] if suffix=='.bat' else [str(executable)]
subprocess.run(command('apksigner')+['verify','--verbose','--print-certs',str(args.apk)],check=True)
subprocess.run(command('zipalign')+['-c','-P','16','4',str(args.apk)],check=True)
print('APK_SIGNATURE_ALIGNMENT=PASS')
p=subprocess.run(command('aapt2')+['dump','badging',str(args.apk)],capture_output=True,text=True,check=True)
for line in p.stdout.splitlines():
 if line.startswith(('package:','minSdkVersion:','targetSdkVersion:','application-label:','launchable-activity:','native-code:','uses-feature:')):print(line)
assert "name='org.nightfalldorm.game'" in p.stdout,'Wrong package'
assert "application-label:'Nightfall Dorm'" in p.stdout,'Wrong app label'
assert "minSdkVersion:'24'" in p.stdout,'Unexpected minimum API'
assert "targetSdkVersion:'36'" in p.stdout,'Unexpected target API'
manifest=subprocess.run(command('aapt2')+['dump','xmltree',str(args.apk),'--file','AndroidManifest.xml'],capture_output=True,text=True,check=True).stdout
orientation=[line.strip() for line in manifest.splitlines() if 'screenOrientation' in line]
print('APK_ORIENTATION='+json.dumps(orientation))
assert any(re.search(r'(?:=|=0x)(?:0|6|8|11)\b',line) for line in orientation),'APK is not landscape/sensor landscape'
assert 'android.hardware.vulkan.version' not in manifest,'Vulkan is still required; check mobile renderer override'
assert 'android.permission.INTERNET' not in manifest,'Unexpected internet permission'
assert 'android.intent.action.MAIN' in manifest and 'android.intent.category.LAUNCHER' in manifest,'No launcher intent'
print('APK_GLES_OFFLINE_LAUNCHER=PASS')
print('APK_VERIFICATION=PASS (native Android execution remains separate)')
