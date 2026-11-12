"""Layer sourced CC0 Foley/design recordings into bounded game cues; no oscillators."""
from pathlib import Path
import argparse, hashlib, json, subprocess
import numpy as np
from scipy.signal import resample_poly, butter, sosfilt
SR=44100
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,required=True);p.add_argument('--output',type=Path,required=True);args=p.parse_args();args.output.mkdir(parents=True,exist_ok=True)
SOURCES={r['id']:(args.source/Path(r['file']).name,r) for r in json.loads((args.source/'SOURCES.json').read_text())}
cache={}
def read(name):
 if name not in cache:
  path,_=SOURCES[name]
  cache[name]=np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ac','1','-ar',str(SR),'-']),dtype='<f4').astype(np.float64)
 return cache[name]
def part(name,start,length,gain=1,rate=1,at=0,hp=50,lp=16000):return dict(source=name,start=start,seconds=length,gain=gain,playback_rate=rate,at=at,highpass=hp,lowpass=lp)
def P(name,start,length,gain=1,rate=1,at=0):return part(name,start,length,gain,rate,at)
recipes={
 'shot_needle':[P('gun_shot_1',0,.30,.8),P('impact_3',.04,.12,.18,1.2)],
 'shot_needle_precision':[P('gun_shot_2',.06,.52,.75,.9),P('impact_3',.03,.25,.3,.8)],
 'shot_needle_suppression':[P('gun_shot_1',0,.18,.6,1.12),P('gun_shot_1',0,.14,.23,1.17,.055)],
 'shot_needle_high':[P('gun_shot_1',0,.34,.8,.91),P('chains-rattling-2',.1,.17,.24,1.1)],
 'shot_arc':[P('laser_1',.21,.30,.6,.8),P('static_2',.2,.23,.3),P('impact_3',.04,.1,.2)],
 'shot_arc_focus':[P('laser_1',.20,.48,.75,.72),P('static_2',.2,.23,.35,.8),P('impact_3',.04,.16,.3,.8)],
 'shot_arc_storm':[P('laser_1',.21,.22,.55,1.13),P('laser_1',.21,.22,.3,1.25,.07),P('static_2',.2,.20,.3)],
 'shot_arc_high':[P('laser_1',.21,.4,.7,.85),P('static_2',.3,.3,.45),P('impact_3',.04,.12,.2)],
 'shot_flame':[P('fire_3',.13,.55,.8),P('fire_2',2,.4,.32)],
 'shot_flame_high':[P('fire_3',.13,.65,.8,.85),P('fire_2',2,.5,.4)],
 'shot_frost':[P('glass_break',.30,.32,.6,1.18),P('whoosh_fast',0,.25,.3,.8)],
 'shot_frost_high':[P('glass_break',.30,.45,.7,.85),P('glass_clink_1',0,.3,.25,1.3)],
 'shot_shock':[P('static_2',.2,.25,.7),P('laser_1',.22,.16,.5,1.4)],
 'shot_shock_high':[P('static_2',.2,.32,.7,.8),P('laser_1',.22,.2,.5,.9),P('impact_3',.04,.12,.2)],
 'impact':[P('impact_3',.04,.20,.7),P('glass_break',.32,.20,.2,.8)],
 'impact_flame':[P('fire_2',2,.42,.7),P('fire_3',.3,.22,.3)],
 'impact_frost':[P('glass_break',.30,.36,.65,1.4),P('glass_clink_1',0,.25,.25)],
 'impact_shock':[P('static_2',.3,.23,.75),P('impact_3',.04,.15,.25,1.4)],
 'door_hit':[P('door_knock_3',.03,.38,.7,.8),P('impact_3',.04,.25,.18,.7)],
 'door_crack':[P('floorboard-creaks',.1,.6,.55),P('glass_break',.3,.35,.3,.75)],
 'door_break':[P('door_slam_2',.74,.65,.8),P('glass_break',.3,.7,.4,.85),P('coffin-lid',.1,.6,.25,.8)],
 'build':[P('impact_3',.04,.25,.5,.85),P('chains-rattling-2',.1,.40,.35)],
 'upgrade':[P('chains-rattling-2',.10,.32,.55),P('glass_clink_1',0,.30,.35,1.1,.06)],
 'branch_select':[P('chains-rattling-2',.10,.45,.55),P('impact_3',.04,.3,.3,.8,.17)],
 'repair':[P('chains-rattling-2',.12,.22,.5,1.3),P('mouse_click_3',0,.15,.3,1,.10)],
 'sale':[P('glass_clink_1',0,.22,.45,1.25),P('mouse_click_3',.02,.12,.25,.9)],
 'refund':[P('glass_clink_1',0,.20,.5,1.2),P('glass_clink_1',0,.20,.2,1.4,.1)],
 'ui_hover':[P('mouse_click_3',.025,.06,.5,1.25)],
 'ui_confirm':[P('mouse_click_3',.02,.13,.7),P('glass_clink_1',0,.12,.1,1.2)],
 'ui_fail':[P('mouse_click_3',.02,.09,.5,.7),P('mouse_click_3',.02,.09,.35,.7,.1)],
 'shield_activate':[P('laser_1',.21,.5,.5,.6),P('glass_clink_1',0,.5,.5,.7)],
 'shield_absorb':[P('static_2',.2,.22,.5),P('glass_clink_1',0,.3,.45,.7)],
 'auto_repair_activate':[P('chains-rattling-2',.1,.32,.7),P('mouse_click_3',.02,.1,.3,1,.1)],
 'decoy_activate':[P('monster_3',.05,.55,.4),P('glass_clink_1',0,.5,.35,.8)],
 'hunter_crusher_warning':[P('monster_3',0,.65,.4,.85),P('chains-rattling-2',.1,.6,.3,.8)],
 'hunter_crusher_pressure':[P('monster_3',0,.8,.5,.75),P('door_knock_3',.03,.3,.3,.7)],
 'hunter_stalker_warning':[P('ghost_1',.8,.65,.35),P('whoosh_fast',.02,.25,.2,.8)],
 'hunter_stalker_conceal':[P('whoosh_deep',.2,.65,.5),P('ghost_1',1,.6,.15)],
 'hunter_stalker_feint':[P('whoosh_fast',.02,.35,.6),P('floorboard-creaks',.1,.3,.2)],
 'hunter_ravager_warning':[P('chains-rattling-2',.1,.35,.35,1.3),P('monster_3',.1,.4,.4,1.1)],
 'hunter_ravager_dash':[P('whoosh_fast',0,.45,.6),P('sword_3',.02,.3,.25,1.2)],
 'hunter_evolve':[P('horror_stinger_1',.7,1.5,.45,.85),P('monster_3',0,.9,.3,.8)],
 'buff_offense':[P('impact_3',.03,.5,.4,.7),P('sword_1',.2,.5,.3)],
 'buff_armor':[P('chains-rattling-2',.1,.6,.6,.8),P('impact_3',.04,.35,.3,.6)],
 'buff_speed':[P('whoosh_deep',.25,.6,.6,1.2)],
 'buff_resource':[P('glass_clink_1',0,.4,.5,.6),P('static_2',.3,.3,.2)],
 'buff_command':[P('zombie_1',.1,.9,.6,.8)],
 'undead_spawn':[P('zombie_1',.05,.7,.5),P('coffin-lid',.1,.7,.3)],
 'undead_attack':[P('zombie_attack',.6,.45,.5),P('sword_3',.04,.25,.2,.7)],
 'undead_hurt':[P('zombie_2',.15,.40,.6)],
 'undead_death':[P('zombie_2',.2,.9,.55,.8),P('door_knock_3',.05,.25,.2,.7)],
 'reaper_phase_2':[P('horror_stinger_1',.7,1.8,.55,.8),P('ghost_1',1,1.5,.3,.85)],
 'scythe_throw':[P('whoosh_deep',.23,.7,.6),P('sword_1',.2,.4,.4,.85)],
 'scythe_embed':[P('impact_3',.03,.65,.6,.8),P('door_slam_2',.75,.4,.3,.85)],
 'scythe_tick':[P('sword_3',.03,.4,.6,.85)],
 'scythe_end':[P('chains-rattling-2',.2,.5,.5),P('whoosh_fast',.02,.3,.3)],
}
# Exclusive machine branch identities, followed by L8+ body variants.
recipes['shot_flame_searing']=[P('fire_3',.13,.6,.85,.85),P('static_2',.2,.2,.15)]
recipes['shot_flame_wildfire']=[P('fire_2',2,.5,.6),P('fire_3',.3,.3,.4,1.2)]
recipes['shot_frost_deep_chill']=[P('glass_clink_1',0,.4,.55,.8),P('glass_break',.3,.25,.35,1.1)]
recipes['shot_frost_rime_field']=[P('glass_break',.3,.3,.4,1.4),P('glass_break',.45,.25,.2,1.5,.07)]
recipes['shot_shock_capacitor_burst']=[P('static_2',.25,.35,.7,.75),P('laser_1',.21,.25,.4,.85)]
recipes['shot_shock_rapid_discharge']=[P('static_2',.25,.15,.5,1.3),P('laser_1',.21,.12,.4,1.4)]
for shot in ['needle_precision','needle_suppression','arc_focus','arc_storm','flame_searing','flame_wildfire','frost_deep_chill','frost_rime_field','shock_capacitor_burst','shock_rapid_discharge']:
 recipes['shot_'+shot+'_high']=recipes['shot_'+shot]+[P('impact_3',.04,.12,.2,.78)]
recipes['turret_upgrade']=recipes['upgrade']
recipes['bed_upgrade']=[P('chains-rattling-2',.25,.25,.25,1.2),P('glass_clink_1',0,.4,.45,1.15,.06),P('floorboard-creaks',.2,.3,.18)]
recipes['door_upgrade']=[P('impact_3',.04,.35,.5,.7),P('chains-rattling-2',.1,.45,.4,.85,.08)]
recipes['prestige_upgrade']=recipes['branch_select']+[P('glass_clink_1',0,.6,.3,.6,.18)]
for event,alias in [('button','ui_confirm'),('menu','ui_hover'),('purchase','ui_confirm'),('failure','ui_fail'),('shop_purchase','refund')]:recipes[event]=recipes[alias]
recipes['footstep']=[P('creepy-footsteps',.25,.32,.7,.85)]
recipes['danger']=[P('horror_stinger_1',.8,.8,.35,1.1)]
recipes['generator_activate']=[P('static_2',.2,.45,.55,.75),P('chains-rattling-2',.1,.3,.4)]
recipes['resource_gold']=[P('glass_clink_1',0,.14,.5,1.4)]
recipes['resource_power']=[P('static_2',.2,.12,.5,1.1)]
recipes['reaper_impact']=[P('sword_3',.03,.5,.5,.7),P('door_slam_2',.75,.5,.6,.75)]
recipes['hunter_charged_warning']=[P('chains-rattling-2',.1,.7,.4,.7),P('monster_3',0,.7,.4,.75)]
recipes['undead_spawn_enhanced']=[P('zombie_2',.15,.8,.5,.8),P('chains-rattling-2',.1,.6,.25,.75)]
recipes['lock_release']=[P('chains-rattling-2',.1,.35,.5,1.25),P('glass_clink_1',0,.22,.3,1.3)]
for kind,texture,start in [('flame','fire_3',.13),('frost','glass_break',.3),('shock','static_2',.2),('auto_repair','chains-rattling-2',.1),('shield','glass_clink_1',0),('decoy','door_knock_3',.03)]:
 recipes['build_'+kind]=recipes['build']+[P(texture,start,.28,.25)]
recipes['income']=recipes['resource_gold'];recipes['electricity']=recipes['resource_power']
recipes['reward']=[P('glass_clink_1',0,.35,.5),P('glass_clink_1',0,.35,.3,1.25,.12)]
ABILITY_SOURCES={
 'summon':('zombie_1',.05,.9), 'assault':('zombie_attack',.6,1.1),
 'soul_steal':('ghost_1',.8,1.2), 'scythe_slash':('sword_1',.2,.9),
 'rules_judgement':('chains-rattling-2',.1,1.0), 'eternal_sacrifices':('whoosh_deep',.2,1.1),
 'enhanced_undead':('zombie_2',.15,1.2), 'soul_reaper':('ghost_1',1,1.6),
 'phantom_scream':('ghost_1',1,1.5), 'final_judgement':('coffin-lid',.1,1.3),
 'crimson_execution':('horror_stinger_1',.7,1.9)}
for i,(ability,(source,start,duration)) in enumerate(ABILITY_SOURCES.items()):
 recipes['wrath_warning_'+ability]=[P(source,start,duration,.6,.92+(i%3)*.04),P('chains-rattling-2',.1,.5,.18,.8)]
 recipes['wrath_activate_'+ability]=[P(source,start,min(1.9,duration+.2),.55,.83+(i%3)*.04),P('impact_3',.04,.45,.25,.8)]
# Distinct warning rhythms/texture, not just a renamed identical sound.
recipes['wrath_warning_summon'] += [P('coffin-lid',.1,.7,.3)]
recipes['wrath_warning_assault'] += [P('zombie_2',.2,.4,.4,1,.18),P('zombie_1',.2,.4,.35,.9,.38)]
recipes['wrath_warning_soul_steal'] += [P('glass_clink_1',0,.22,.3,.8,.05),P('glass_clink_1',0,.22,.2,.7,.25)]
recipes['wrath_warning_rules_judgement'] += [P('mouse_click_3',.02,.09,.4,.8,.15),P('mouse_click_3',.02,.09,.4,.8,.3)]
recipes['wrath_warning_enhanced_undead'] += [P('zombie_1',.2,.5,.35,.7,.22)]
recipes['wrath_warning_soul_reaper'] += [P('door_slam_2',.75,.4,.35,.65,.05),P('door_slam_2',.75,.4,.25,.65,.45)]
recipes['wrath_warning_phantom_scream'] = [P('whoosh_fast',0,.35,.4,1.2),P('ghost_1',1.8,1.2,.5,1.1,.15),P('ghost_1',1.8,.6,.2,1.3,.3)]
recipes['wrath_activate_soul_reaper'] += [P('static_2',.2,.7,.3,.6)]
recipes['wrath_activate_phantom_scream'] += [P('whoosh_fast',0,.4,.4,1.4)]
rows=[]
for event,layers in recipes.items():
 ends=[r['at']+r['seconds']/r['playback_rate'] for r in layers];audio=np.zeros(int((max(ends)+.07)*SR))
 for r in layers:
  raw=read(r['source']);a=raw[int(r['start']*SR):int((r['start']+r['seconds'])*SR)]
  if not len(a):raise ValueError(r)
  a=np.interp(np.arange(0,len(a),r['playback_rate']),np.arange(len(a)),a)
  a=sosfilt(butter(2,[r['highpass'],min(r['lowpass'],SR*.45)],'bandpass',fs=SR,output='sos'),a)
  fade=min(len(a)//4,int(.012*SR));a[:min(80,len(a))]*=np.linspace(0,1,min(80,len(a)));a[-fade:]*=np.linspace(1,0,fade)
  at=int(r['at']*SR);audio[at:at+len(a)]+=a*r['gain']
 peak=float(np.max(abs(audio)));target=.28 if event.startswith('ui_') or event in ['button','menu','purchase','failure'] else .32 if event.startswith('resource_') else .58
 audio*=target/max(.001,peak);pcm=(np.clip(audio,-.95,.95)*32767).astype('<i2')
 import wave
 path=args.output/(event+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes(pcm.tobytes())
 rows.append(dict(event=event,seconds=len(audio)/SR,peak=float(np.max(abs(audio))),rms=float(np.sqrt(np.mean(audio**2))),layers=layers,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
(args.output/'wrath-sfx-derivatives.json').write_text(json.dumps(rows,indent=2)+'\n');print('DESIGNED_SOURCED_CUES',len(rows))
