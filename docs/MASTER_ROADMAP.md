# Nightfall Dorm master roadmap

## Phase 14F — Hunter animation and directional art

Continue the opt-in visual preview. Verify character motion and direction,
building function cues, and render performance against the Phase 14E
checkpoint. Owner review gates the visual preview rollout.

## Owner-approved project — Full room grid building

The owner authorized the grid preview while artistic review and native
Windows testing of Phase 14F are pending. Review the combined build through
the [Full Room Grid preview](FULL_ROOM_GRID_PREVIEW.md).

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
