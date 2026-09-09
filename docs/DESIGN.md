# Cluck — game design

Cluck is an original, portrait 3D farm survival game. The supplied image informed the warm farm palette, chunky animal shapes and red-bandana chicken. The models, icon and audio are created for this project; no Survivor.io assets are used.

## Campaign

| Patch | Nominal duration | New pressure | Boss |
|---|---:|---|---|
| The Farmyard | 4 minutes | Swarming rats, then faster foxes | The Rat King |
| Cornfield Chaos | 5 minutes | Boars warn before charging; taller corn along the sides | Old Tusk |
| The Last Barn | 6 minutes | Tough cows join the mixed herd; barns flank the arena | The Moodon |

Bosses arrive 30 seconds before the nominal end. Defeating the boss ends the level, so a strong run can finish slightly early. A slow boss fight can continue beyond the timer. There is no automatic timeout defeat. Wins unlock the next patch; all unlocked patches remain replayable.

## Controls and run progression

Drag below the top HUD to move. The floating joystick follows the first finger and releases when that finger lifts. WASD, arrows and mouse dragging also work. Attacks target automatically. Escape or Android Back pauses; returning to the farm preserves earned coins. Losing app focus pauses combat.

Blue experience gems grant levels. Each level pauses combat and offers up to three eligible upgrades. Four attacks have five ranks each: Egg Shot, Feather Ring, Peck Sweep and Egg Grenade. Five passive upgrades have four ranks each: damage, movement, maximum health, pickup range and attack speed. A full build receives healing choices. Run upgrades reset on the next attempt.

Health pickups appear every 28 kills. A magnet appears every 65 kills and attracts all existing pickups. Boars and bosses display a red ring before a committed charge.

## Permanent progression

Coins are credited for defeated enemies: one for rats and foxes, two for boars and cows. Bosses grant an additional 25 coins. Winning grants a further 35/50/65 coins by level. Earned coins are saved every five seconds, on focus loss and on completion, with a duplicate-award guard.

Each permanent stat has five ranks. A rank costs 30 + 35 × current rank coins:

- Hearty Hen: +20 maximum health per rank.
- Hard Boiled: +10% base weapon damage per rank.
- Forager: +0.4 metres pickup range per rank.

Egg Shot is initially owned. Feather Ring costs 65 coins; Peck Sweep costs 110. Buying a weapon equips it. Owned weapons can be equipped freely. These purchases choose the starting attack; temporary in-run weapon offers remain available to every build.

The economy intentionally allows meaningful purchases after a short attempt and does not demand grinding to access campaign content. There are no ads, real-money purchases or online services.

## Implementation

Godot 4.7.2, GDScript, OpenGL compatibility renderer. Blender exports original GLB assets; Godot animates movement with procedural body bob, lean and facing. Static repeated scenery is batched with MultiMesh. Enemy, projectile, pickup and combat-effect nodes are reused. Ordinary spawns stop at 110 active enemies; alerted hordes can raise the total to 160; excess experience pickups merge their value rather than losing it.

The source Blender file is in `art/cluck_assets.blend`; the generation scripts are in `art/`. Godot ignores that folder and uses the exported GLBs, so opening the game project does not require Blender to reimport it.

## v0.2.0 revisions

- The field measures 68 × 76 game units (previously 17 × 28), about 11 times the playable area. Scenery stays beyond the fences.
- New saves start with ranged Egg Shot. Existing v1 saves switch to Egg Shot once, preserving coins, stats and owned weapons. Players can still deliberately equip other owned weapons.
- The Mac window starts large and centered, using up to 90% of available screen height, capped at 1600 pixels.
- At player levels 4, 7, 10 and every third level thereafter, a three-second incoming alert precedes a horde of 38–60 animals. This is additional to regular enemy spawning. The warning and arrival pause during upgrade selection.
- Egg Grenade unlocks automatically at player level 3. It auto-throws a visible grenade in an arc, then damages every enemy in its blast radius. Upgrade choices increase its damage and blast size.
