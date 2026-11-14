extends "res://scripts/hunter_state.gd"
# Test-only controlled ablation. Never loaded by production.
func growth_at(active_seconds: float) -> float:
 var opening=RankCatalog.pressure(difficulty).opening
 return super.growth_at(opening+maxf(0,active_seconds-opening)*.5) if active_seconds>=opening else 0.0
