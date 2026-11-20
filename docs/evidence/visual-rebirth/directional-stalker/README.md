# Phase 14E Hunter direction art

The Stalker at Levels 1 and 10, Phantom Witch at Level 10 and Storm Wraith at Level 10 each have four separately authored cardinal illustrations, plus their existing oblique. Each new sheet used its existing same-level oblique sprite as visual reference. The rear artwork reconstructs the visible gown, hair and shoulders. The two profiles preserve visible asymmetry and were drawn separately. These are 2D interpretations of the game camera. Fine dress folds, hair and perspective vary slightly between illustrations.

To repack the 16 sprites, run `python tools/visual_rebirth/prepare_hunter_turnarounds.py` with Pillow from the repository root. A second run reproduced every PNG hash. Each packed subject has transparent borders and a 256-pixel art height. The Stalker Level 1 cardinals share a `(108, 260)` floor pivot. Stalker and Witch Level 10 use `(164, 260)`. Storm Level 10 uses `(216, 260)` to accommodate its longer mantle. Each authored Stalker and Storm view has separate marks for the near hand, far hand, head and shoulder. An obscured hand or rear head mark stays within the visible figure.

For remaining oblique-only levels, the enhanced renderer keeps that art active through turns. It reflects the original projection when heading right and retains the last side near a vertical heading. The independent illustrations cover the stated levels. The remaining turns continue to use projection reuse.

The 104-pixel inspections show packed art. Game captures are recorded separately. [Stalker art](phase14e-direction-art-review.png) · [Phantom Witch art](../witch-directional/phase14e-direction-art-review.png) · [Storm Wraith art](../storm-evolution/phase14e-direction-art-review.png)
