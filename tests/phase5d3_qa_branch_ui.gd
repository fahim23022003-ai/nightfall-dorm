extends "res://tests/premium_strategy_ui.gd"
const Support=preload("res://tests/replay_test_support.gd")
# Ordinary inspection waits for the new intentional .26s drawer slide.
# Separate input QA checks behavior during the motion itself.
func settle():
 # Retain original v1 prepared branch-price fixtures; v2 has dedicated input tests.
 if game!=null and is_instance_valid(game):game.new_balance_version=1
 await process_frame
 if game!=null and is_instance_valid(game) and game.mode=="match":
  game.ui.update_match()
  var deadline=Time.get_ticks_msec()+1500
  while game.ui.bottom_context!=null and game.ui.bottom_context.is_transitioning() and Time.get_ticks_msec()<deadline:await process_frame
 await process_frame
func click(control,double_click=false):
 await settle()
 await super.click(control,double_click)
 await settle()
func key(code):
 for down in [true,false]:
  var e=InputEventKey.new();e.keycode=code;e.pressed=down;Input.parse_input_event(e);await process_frame
 await settle()
func run():
 profile_path="user://phase5d3-qa-branchui-"+str(Time.get_ticks_usec())+".json"
 var p=PlayerProfile.new(profile_path);p.tutorial_completed=true;p.save_profile();OS.set_environment("NIGHTFALL_PROFILE_PATH",profile_path)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false);game.onboarding.set_process(false);preload("res://tests/onboarding_test_support.gd").skip(game);await settle()
 var before=Support.profile_signature(game.profile);var bytes=FileAccess.get_file_as_bytes(profile_path)
 game.start_practice("crusher",false,["coupon","repair"]);await settle();var r=game.model.player();var wallet=game.item_wallet();var stock=wallet.inventory.coupon
 await key(KEY_1);check(r.coupon_armed and wallet.inventory.coupon==stock,"actualcouponarmswithoutstockconsumption")
 for kind in ["bed","door"]:
  await click(game.ui.room_bed_summary if kind=="bed" else game.ui.room_door_summary);await settle()
  await click(game.ui.actions[kind]);await settle();screen("structural choice "+kind)
  var card=game.ui.specialization_items[1];var gold=650.0 if kind=="bed" else 700.0
  check(card.text.contains("%.1f Gold / 60.0 Electricity" % gold) and not card.text.contains("COUPON"),"armedcouponstructuralcardshowsactualfullpricewithnoapplieddiscountclaim")
  check(card.tooltip_text.contains("Full-price") and card.tooltip_text.contains("placeable machine"),"structuraleligibilityexplainsexactcouponexclusion")
  var g=r.gold;var e=r.electricity;await click(card);await settle()
  check(r.gold==g and r.electricity==e,"previewing structural branch spends nothing before confirmation")
  await click(game.ui.branch_confirm);await settle()
  check((r.bed_level if kind=="bed" else r.door_level)==5 and r.gold==g-gold and r.electricity==e-60,"actualstructurechoicepaysquotedpriceandadvancesonce")
  check(r.coupon_armed and wallet.inventory.coupon==stock,"bed/doorneverconsume machine-onlycoupon")
  game.ui.close_context();await settle()
 var tile=game.model.practice_tile;game.selected_tile=tile;game.ui.open_context();await settle();await click(game.ui.actions.upgrade);await settle()
 var b=r.buildings[tile];var price=Catalog.upgrade_cost(b.kind,4)+StrategyCatalog.BRANCH_FEE;var quote=price*.6;var card=game.ui.specialization_items[1]
 check(card.text.contains("COUPON") and card.text.contains("%.1f Gold / %.1f Electricity" % [quote.x,quote.y]),"eligiblemachinecardshowsactualdiscountedupgradeplusbranchfee")
 var g=r.gold;var e=r.electricity;await click(card);await settle()
 check(r.gold==g and r.electricity==e and wallet.inventory.coupon==stock,"machine branch preview retains currency and coupon until confirmation")
 await click(game.ui.branch_confirm);await settle()
 check(b.level==5 and is_equal_approx(g-r.gold,quote.x) and is_equal_approx(e-r.electricity,quote.y),"samearmedcouponappliesexactlyoncetoactualeligiblepaidchoice")
 check(not r.coupon_armed and wallet.inventory.coupon==stock-1,"successfulmachinebranchconsumesonecoupononly")
 check(ItemCatalog.ITEMS.coupon.description.to_lower().contains("beds/doors excluded"),"inventorydescriptionsdiscloseeligibility")
 check(Support.profile_signature(game.profile)==before and FileAccess.get_file_as_bytes(profile_path)==bytes,"alltemporarybranch/couponUIoperationsleavepermanentprofileunchanged")
 print("PHASE5D3_BRANCH_UI_QA_CHECKS=",checks," FAILURES=",failures)
 game.audio_system.shutdown();await create_timer(.6).timeout;game.queue_free();await create_timer(.2).timeout;Support.cleanup(profile_path);quit(1 if failures else 0)
