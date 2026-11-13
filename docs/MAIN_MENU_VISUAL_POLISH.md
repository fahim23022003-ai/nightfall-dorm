# Focused main-menu visual polish

This pass preserves the existing layout, Gothic logo, haunted-house background,
large Start button and three destination cards. It changes only menu presentation.

- Two original menu-only supply-bag/case SVGs unify icon weight, outline and lighting.
  The actual rank emblem gains a subtle native bezel; rank assets are unchanged.
- Endless, Extras and footer utilities use quieter flat surfaces and clean borders.
- Rank progress uses a non-interactive meter, matching rank-local XP caption and
  lifetime-XP tooltip. Existing progression rules and promotion requirements remain.
- Menu-only polling checks data every 0.2 seconds and updates only changed values;
  it does not create replacement labels or reload emblems every frame.
- Hover/focus blends take 0.12 seconds, with immediate feedback under Reduced Effects.
  Existing fog/eyes are reused; no atmosphere effect, particle system or shader added.
- Existing session-only welcome dismissal logic is unchanged and independently checked.

Verification: Godot 4.6.3 import and 282 focused checks passed at both resolutions. These cover navigation, keyboard/mouse states, nonzero and maximum XP, exact meter ratios, live wallet/inventory updates without node churn, actual 8px meter height, caption spacing, Welcome session behavior and isolated-profile preservation. Independent rendered/input review passed 12 checks; final four screenshots were inspected.

Fixed during verification: ProgressBar initially retained the 28px height clamped while its default percentage text was enabled. Assigning the 8px size after disabling that text and applying styles fixes the actual rendered height. Continuous progress uses step 0.0 to avoid ratio rounding. The initial failed visual capture is preserved separately.

[1280×720](evidence/main-menu-polish/01-polished-main-1280x720.png) · [1920×1080](evidence/main-menu-polish/02-polished-main-1920x1080.png) · [Shop hover](evidence/main-menu-polish/03-highlighted-shop-card.png) · [Welcome](evidence/main-menu-polish/04-welcome-open.png).

Changed production files: `scripts/main_menu.gd`, `scripts/menu_destination.gd`, `assets/menu/merchant_bag.svg`, `assets/menu/inventory_case.svg` and import companions. Focused tests: `tests/focused_menu.gd`. The earlier completed redesign was preserved in local checkpoint 07c23a0 before this polish pass; its welcome logic is unchanged here.

Actual screenshots use an isolated test profile. Native Windows execution and subjective human usability remain unverified. The initial redesign and this polish are committed/pushed together to the existing work branch; final remote equality is verified in the delivery response.
No gameplay, ranking rules, economy, inventory transactions or save-format changes.
No platform build or full regression suite is part of this task.
