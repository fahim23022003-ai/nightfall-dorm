# Nightfall Dorm master roadmap

## Phase 14F — Hunter animation and directional art

Continue the opt-in visual preview. Verify character motion and direction,
building function cues, and render performance against the Phase 14E
checkpoint. Owner review gates the visual preview rollout.

## Owner-approved next project — Full room grid building

Start after the owner approves the visual and animation work. Phase 14F
records this direction for future implementation.

- Divide the entire usable room floor into buildable grid cells. Allow
  placement anywhere a building footprint fits on valid tiles.
- Replace progressive 3/6/8/10/16 slot unlocking and arbitrary slot-cap
  progression with physical floor constraints.
- Give different building types appropriate physical footprints. Validate
  placement, movement and rotation against walls, doors, room fixtures,
  actors and neighboring buildings.
- Preserve safe access and pathfinding through rooms. Measure navigation,
  rendering and input under dense valid layouts.
- Design and verify save migration for existing buildings, ownership and
  progression. Handle layouts that do not fit the grid without deleting
  saved investments.
