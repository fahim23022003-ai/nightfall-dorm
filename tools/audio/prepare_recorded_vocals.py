"""Convert declared-CC0 recorded vocals; retain genuine source texture and credits."""
from pathlib import Path
import json,subprocess,hashlib
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'tools/audio/source/vocals';OUT=ROOT/'assets/audio'
MAP={
 'death_scream_1':('man-screaming-2.mp3',3.47,1), 'death_scream_2':('girl-screaming.mp3',2.98,1),
 'scream_1':('man-screaming-2.mp3',2.8,1),'scream_2':('girl-screaming.mp3',2.8,1),'scream_3':('blood-curdling-scream.mp3',3.76,1),
 'hunter_laugh':('maniacal-laugh.mp3',4.2,1), 'reaper_laugh':('maniacal-laugh.mp3',4.2,.75),
 'ghost_hurt':('creature-snarl.mp3',.9,1),'ghost_defeat':('demon-choking-dying.mp3',3.8,1),
 'reaper_hurt':('monster-growl.mp3',1.1,.85),'reaper_death':('demon-choking-dying.mp3',4.2,.85),
 'reaper_charge':('get-out-2-2.mp3',2.2,.85),
 'intro_breath':('voice_breath.ogg',2.8,1),'intro_shriek':('blood-curdling-scream.mp3',3,1),
 'intro_whisper':('i-m-coming-to-get-you.mp3',4.2,1)}
rows=[]
for event,(source,seconds,pitch) in MAP.items():
 path=OUT/(event+'.wav')
 filters=f'atrim=duration={seconds},asetpts=PTS-STARTPTS,aresample=22050,asetrate={int(22050*pitch)},aresample=22050,highpass=f=65,alimiter=limit=0.65:level=false,afade=t=in:d=0.015,afade=t=out:st={max(0,seconds/pitch-.1)}:d=0.1'
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(SRC/source),'-af',filters,'-ac','1','-c:a','pcm_s16le',str(path)],check=True)
 rows.append(dict(event=event,source=source,source_sha256=hashlib.sha256((SRC/source).read_bytes()).hexdigest(),playback_rate=pitch,note='Real recorded voice; cropped/filtered with headroom, never a synthesized beep'))
(OUT/'vocal-derivatives.json').write_text(json.dumps(rows,indent=2)+'\n')
print('RECORDED_VOCAL_EVENTS',len(rows))
