class_name SessionInterface
extends RefCounted
static func settings(ui):
 ui.clear();ui.current_screen="soundtrack"
 ui.box(Rect2(110,35,1060,650));ui.label_at("YOUR NIGHT · SOUNDTRACK",Vector2(145,65),30,990,true)
 ui.label_at("Active preference · independent of the listening room",Vector2(150,118),18,960)
 var mode=OptionButton.new();mode.name="music_mode";mode.position=Vector2(150,170);mode.size=Vector2(960,44)
 for value in ["Dynamic Shuffle","Classic Soundtrack","Manual Track","Off"]:mode.add_item(value)
 var ids=["shuffle","classic","manual","off"];mode.select(ids.find(ui.game.profile.settings.music_mode))
 mode.item_selected.connect(func(i):ui.game.change_setting("music_mode",ids[i]));ui.panel.add_child(mode)
 var track=OptionButton.new();track.name="manual_track";track.position=Vector2(150,285);track.size=Vector2(960,44)
 var tracks=Soundtrack.TITLES.keys()
 for id in tracks:track.add_item(Soundtrack.TITLES[id])
 track.select(tracks.find(ui.game.profile.settings.manual_track));track.item_selected.connect(func(i):ui.game.change_setting("manual_track",tracks[i]));ui.panel.add_child(track)
 ui.label_at("Manual selection · ordinary gameplay only; boss music keeps priority",Vector2(150,245),17,960)
 var director=ui.game.audio_system
 ui.soundtrack_now=ui.label_at("Playing: "+Soundtrack.TITLES.get(director.soundtrack.current,director.soundtrack.current),Vector2(150,370),20,960)
 ui.label_at("Shuffle bags remember recent tracks across launches.\nReaper and Crimson encounters retain their dedicated scores.\nOff silences music only; volume/mute and important warnings still work.\nListening previews do not change this preference or consume the playlist.",Vector2(150,420),18,950)
 ui.button("Back to settings",Vector2(150,592),ui.show_settings,460,44)
 ui.button("Listening room · audition only",Vector2(650,592),ui.show_audio_test,460,44)
static func wave_report(ui):
 WaveReportView.show(ui)

static func refresh(ui):
 if ui.current_screen=="soundtrack" and is_instance_valid(ui.soundtrack_now):
  var a=ui.game.audio_system;var current=a.soundtrack.current
  if a.soundtrack.mode=="classic":
   var weight=0.0
   for key in a.loop_weights:
    if key.begins_with("music") and a.loop_weights[key]>weight:current=key;weight=a.loop_weights[key]
  ui.soundtrack_now.text="Music OFF" if a.soundtrack.mode=="off" else "Playing: "+Soundtrack.TITLES.get(current,current)+" · "+a.soundtrack.mode
