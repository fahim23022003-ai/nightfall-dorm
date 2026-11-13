extends RefCounted
# Legacy gameplay fixtures explicitly represent tutorial graduates. No production bypass.
static func prepare():
 var path=OS.get_environment("NIGHTFALL_PROFILE_PATH")
 if path=="":
  path="user://legacy-scene-graduate-"+str(OS.get_process_id())+".json"
  OS.set_environment("NIGHTFALL_PROFILE_PATH",path)
 var profile=PlayerProfile.new(path)
 profile.load_profile()
 profile.tutorial_completed=true
 if not profile.save_profile():push_error("Legacy graduate fixture could not be saved: "+path)
static func skip(game):
 if game.onboarding!=null:
  game.onboarding.skip();game.onboarding.close_welcome()
