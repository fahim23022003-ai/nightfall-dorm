#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/runtime-data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/runtime-config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/runtime-cache}"
export NIGHTFALL_PROFILE_PATH="user://automated-test-profile.json"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" artifacts
godot --headless --editor --import --quit > artifacts/import.log 2>&1
cat artifacts/import.log
if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/import.log; then exit 1; fi
godot --headless --path . --script tests/run_tests.gd > artifacts/tests.log 2>&1
cat artifacts/tests.log
if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/tests.log; then exit 1; fi
for suite in phase6_journey phase6_inputs replay_endless replay_transactions replay_codes replay_pity replay_migration replay_practice replay_facts_cosmetics replay_retirement replay_ui premium_strategy_mechanics premium_strategy_economy premium_strategy_contracts premium_strategy_migration premium_strategy_ui visual_identity_qa visual_identity_ui visual_identity_audio visual_identity_culling visual_identity_navigation haunted_qa haunted_economy haunted_balance onboarding_qa onboarding_flow onboarding_economy rewards_qa rewards_combos rewards_balance legendary_qa legendary_combos legendary_balance advanced_items_qa advanced_item_combos advanced_items_balance items_qa items_activation_feedback items_balance mythic_progression mythic_edges boss_architecture boss_qa boss_audio boss_matrix difficulty_behavior difficulty_matrix maps_core maps_integration maps_ui maps_simulations campaign_profile campaign_flow campaign_simulations horror_events horror_feedback horror_ui phase1_building phase1_independent mobile_controls mobile_layout audio_system ranked_progression phase2_ui phase2_hunter projectiles redesign_projectile_edges redesign_ui scene_smoke overhaul_ui furniture_collision ui_availability simulate_matches audit_regressions audit_properties audit_rates; do
  godot --headless --path . --script "tests/$suite.gd" > "artifacts/$suite.log" 2>&1
  cat "artifacts/$suite.log"
  if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/$suite.log"; then exit 1; fi
done
if [[ "${1:-}" == "--extended" ]]; then
  for suite in audit_timesteps audit_matrix phase2_matrix; do
    godot --headless --path . --script "tests/$suite.gd" > "artifacts/$suite.log" 2>&1
    cat "artifacts/$suite.log"
    if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/$suite.log"; then exit 1; fi
  done
  godot --headless --path . --script tests/strategy_balance_audit.gd -- --check > artifacts/strategy_balance_check.log 2>&1
  cat artifacts/strategy_balance_check.log
  if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/strategy_balance_check.log; then exit 1; fi
  godot --headless --path . --script tests/endless_balance_audit.gd -- --check > artifacts/endless_balance_check.log 2>&1
  cat artifacts/endless_balance_check.log
  if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/endless_balance_check.log; then exit 1; fi
fi
for stage in cleanup write read cleanup; do
  godot --headless --path . --script tests/profile_process_roundtrip.gd -- "$stage" > "artifacts/profile_process_$stage.log" 2>&1
  cat "artifacts/profile_process_$stage.log"
  if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/profile_process_$stage.log"; then exit 1; fi
done
godot --headless --path . --script tests/startup_smoke.gd > artifacts/startup.log 2>&1
cat artifacts/startup.log
if rg -n 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/startup.log; then exit 1; fi
