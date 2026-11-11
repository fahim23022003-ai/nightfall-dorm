# Gameplay reference and evidence

Nightfall Dorm is a new, original single-player dormitory defense game. No source code, scenes, artwork, audio, characters, or names were taken from Haunted Dorm or any prior project. The user's requested gameplay loop is the implementation contract; it is not independent evidence of Haunted Dorm's exact rules.

## Reference access audit

Access attempted from the cloud machine on 2026-11-11 using curl with the inherited HTTPS proxy and TLS verification enabled:

| Requested source | Result | What can be verified here |
| --- | --- | --- |
| https://www.taptap.io/post/1176667 | `curl: (56) CONNECT tunnel failed, response 403` | No article content accessible |
| https://gamingonphone.com/guides/haunted-dorm-beginners-guide-and-tips/ | `curl: (56) CONNECT tunnel failed, response 403` | No guide content accessible |
| Official app listing search candidate, Google Play (`play.google.com`) | `curl: (56) CONNECT tunnel failed, response 403` | Listing identity, publisher, description, and statistics unverified |

The Google Play probe used a candidate package URL; that package identity has not been established and must not be cited as an authenticated official listing. No web search or browsing connector was available to this reviewer. These failures are network policy evidence, not evidence that the sources or the game are unavailable generally. Network access must be restored before a source-backed parity claim is possible.

The autonomous audit retried both supplied URLs and a Google Play search on the same date; all again returned proxy CONNECT 403. No new source evidence became available.

## Confirmed specification versus reference assumptions

The following are confirmed **user requirements**, not independently verified original-game mechanics:

1. Select an available dorm room from a shared corridor before the hunter arrives; five autonomous residents claim other rooms.
2. Close the room door and occupy its bed to generate gold. No income accrues before occupation.
3. Spend room-local resources on stronger beds, stronger doors, turrets, generators, repairs, and support buildings.
4. Generate electricity separately; require it for selected advanced upgrades.
5. Defend the closed door while turrets damage the hunter outside. A destroyed door allows the hunter to eliminate the occupant.
6. The hunter selects occupied rooms, travels through corridors, attacks doors, changes targets, and becomes more dangerous over time.
7. Defeat the hunter to win; elimination of the player's survivor loses. Restart resets the match.

**Unknown reference details:** exact bed income and tick timing; all costs and prerequisites; original placement grid; number/layout of rooms; hunter targeting formula, regeneration, retreat behavior, attack timing, experience thresholds; building roster; precise repair behavior; bot difficulty and spending rules; typical match duration. Never present project choices in these areas as authentic original-game values.

## Intended player loop

Start → move through the corridor → claim a vacant room → close its door → sleep → receive gold → select an empty floor tile → build a defense or production building → balance bed, door, turret, electricity, and repair upgrades → monitor the approaching hunter → survive attacks and improve defenses → win by defeating the hunter or lose on elimination → restart or return to menu.

The preparation target is 30 seconds because the user requested it. All rates, prices, damage, health, ranges, cooldowns, growth intervals, and AI priorities are original configurable balance approximations. Project data, rather than this reference document, is authoritative for actual current values.

## Review standard

The parity checklist separates implementation status from reference confidence. An implemented feature can still have UNVERIFIED parity. Source-code inspection establishes code presence, executed deterministic tests establish tested behavior, and graphical screenshots establish only the observed rendered state. Headless simulation alone establishes neither readable visuals nor an enjoyable match pace. No claim of 100% Haunted Dorm parity is supported.
