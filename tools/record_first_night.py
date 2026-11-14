import subprocess,os,time,json
from pathlib import Path
root=Path(__file__).resolve().parents[1];out=root/'docs/evidence/first-night';(out/'video').mkdir(exist_ok=True)
env=dict(os.environ,DISPLAY=os.environ.get('DISPLAY',':98'),XDG_DATA_HOME='/workspace/runtime-data',XDG_CONFIG_HOME='/workspace/runtime-config',XDG_CACHE_HOME='/workspace/runtime-cache')
marker=Path('/tmp/phase11-record-go');marker.unlink(missing_ok=True)
with (out/'video/engine.log').open('w') as log:
 game=subprocess.Popen(['godot','--path',str(root),'--audio-driver','Dummy','--position','0,0','--resolution','1280x720','--borderless','--script','tools/record_first_night.gd','--','record'],env=env,stdout=log,stderr=subprocess.STDOUT)
 for i in range(300):
  if 'VIDEO_READY' in (out/'video/engine.log').read_text():break
  if game.poll() is not None:raise RuntimeError('Engine exited before ready')
  time.sleep(.1)
 else:game.terminate();raise RuntimeError('Readiness deadline')
 tree=subprocess.check_output(['xwininfo','-root','-tree'],env=env,text=True)
 import re
 window=re.search(r'(0x[0-9a-f]+).*Nightfall',tree,re.I)
 assert window,tree
 subprocess.run(['python',str(root/'tools/first_night_xinput.py'),'focus',str(int(window.group(1),16))],env=env,check=True)
 with (out/'video/ffmpeg.log').open('w') as caplog:
  capture=subprocess.Popen(['ffmpeg','-y','-f','x11grab','-framerate','24','-video_size','1280x720','-i',env['DISPLAY'].split('.')[0]+'.0+0,0','-c:v','libx264','-preset','veryfast','-crf','23','-pix_fmt','yuv420p','-threads','2',str(out/'video/native-input-silent.mp4')],env=env,stdin=subprocess.PIPE,stdout=caplog,stderr=subprocess.STDOUT)
  time.sleep(.3);marker.write_text('recording')
  code=game.wait(timeout=420)
  capture.communicate(input=b'q',timeout=20)
 metadata={'engine_exit':code,'capture_exit':capture.returncode,'type':'Uncut X11 recording, normal playback speed,24fps encoded,1280x720. Separate actual internal Master WAV on Dummy device; video is silent, WAV supplied separately. Scripted engine InputEvents: fresh cold journey then explicitly labeled canonical earned45 continuation, explicit on-screen captions; not a human playtest.'}
 (out/'video/capture-metadata.json').write_text(json.dumps(metadata,indent=2));print(metadata,flush=True)
