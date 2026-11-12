# Independent expansion QA

**PASS:31,294 checks, zero failures, actual Godot4.6.3 process exit0.** B owned all production fixes; C edited only the new independent test and evidence. The budgeted fixtures isolate geometry and transactions; natural economy, rendered quality and native Windows are not claimed here.

## Confirmed failure and repair

The first stable completed run recorded31,145 checks and seven failures. Fresh Underground Laboratory bed footpoint `(240,-72)` lay only8pixels inside the top wall, while navigation requires10pixels. The Hunter's real door-to-bed path was empty at every tested expansion tier, potentially making that survivor unreachable after a breach. Other four maps had valid paths.

B changed the fresh horizontal furniture rail from−57 to−13. The resulting bed footpoint `(240,-28)` is52pixels inside the wall and its real route is `[(280,12),(240,-28)]`. Existing legacy coordinates and all pad positions remain unchanged. Actual all-five-map probes, all-six-room base/ultimate navigation checks and the completed independent regression pass after this fix. The failed run is retained.

## Tested

- All five maps, six rooms and eight fresh tiers use3/6/8/10/11/12/14/16 slots; areas visibly differ in the geometry model, fixed door/bed and prior pad coordinates remain identical.
- Every54×54 machine footprint fits inside walls, avoids resident/furniture and other machines; maximum rooms remain disjoint and growing rooms do not newly cover authored corridors.
- Real Gold/Electricity payments, prerequisites, insufficient wallets, foreign/invalid room, unoccupied/eliminated/terminal/nonrunning rejection and16-slot maximum.
- Locked direct purchases fail; last unlocked pad accepts an actual machine. Sale returns exactly50% of actual discounted Gold/Electricity capital; duplicate sale fails and expansion spend is not refunded.
- Machine coupons remain armed during expansion and are consumed only by successful eligible machine purchases.
- Real route cache invalidation, synchronized room/map bounds and valid door-to-resident navigation at paid tiers. All30 rooms also have valid base/ultimate footpoints and routes.
- Current checkpoint JSON encode/validation/restoration preserves capacity, geometry, wallet, building and actual investment.
- Historical rulesets1/2/3 restore static10/12/16-slot layouts and high-ID buildings without relocation; subsequent expansion preserves their full old coordinate prefix.
- Malformed geometry headers, invalid/fractional/out-of-range tiers, missing current header and high-ID buildings in locked geometry reject safely.
- Existing campaign room layouts/capacities remain unchanged and cannot invoke Endless expansion.

## Evidence and boundaries

`qa-expansion-receipt.json` records the accepted result and diagnostic lineage. `qa-expansion-source.json` binds relevant production/test sources sampled during the final run. `qa-expansion-final.log` is the raw accepted output. `qa-expansion-result.json` is the test's final machine-readable result. Initial class-cache and incorrect C sale-API fixture diagnostics are retained separately and are not presented as product failures or successful runs. UI/render evidence is owned separately by D.

No pending confirmed expansion finding remains within this scope. Full typed-combat/Hunter and final integration testing remain separate gates.
