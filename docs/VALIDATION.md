# Validation

## Verified so far

- Godot imports and runs the project without script errors or warnings in the current debug session.
- Automated lifecycle checks exercise real combat methods, rewards after defeat, duplicate-result guards, affordable and unaffordable purchases, save reload, equipped weapons, permanent stats, touch drag/release, pause, temporary upgrade choice and all campaign unlocks.
- A deterministic full campaign simulation completed all bosses in approximately 3:39, 4:39 and 5:44. Total: about 14:02 of combat.
- The campaign bot uses normal attacks, enemy spawning and progression, but restores its own health and attracts pickups. It checks long-run behaviour and completion; it is not evidence that a new player will survive or that difficulty is fully balanced.
- Desktop UI inspection confirmed purchase/equipment updates: 82 coins → Feather Ring purchase → 17 coins, with Feather Ring marked equipped and unaffordable purchases disabled.
- Rendered screenshots were checked and prompted corrections to over-bright materials, character facing, camera framing and farm density.
- Android development APK export and signing verification succeeded. A native Mac app also exports successfully.

- Final APK installed successfully on an Android 15 / API 35 ARM64 emulator. The app process launched using OpenGL ES 3.0 with no Godot script errors or AndroidRuntime exceptions in the observed startup log.
- The packaged Mac app launched successfully. Final menu, combat, upgrade and shop screenshots were rendered from the game. The HUD is hidden behind modal menus.
- Emulator UI control was not available through the computer-use app inventory. The Android check therefore covers installation and engine startup; touch interactions are covered by the engine-level lifecycle test, not a manual emulator playthrough.

## Remaining limitations

- Physical Android hardware, thermal behaviour and low-end phone performance have not been tested.

Tests use `cluck_test_save.json`, separate from normal player progress. Run `tests/run_tests.sh` with Godot installed. Set `GODOT_BIN` when its executable is elsewhere.

## v0.2.0 regression checks

Focused tests cover the enlarged bounds, ranged initial equipment, migration of old saves without losing coins or ownership, automatic grenade unlock, grenade flight and damage to multiple enemies, and a complete 38-enemy horde with a warning before arrival. Existing combat, purchase, saving, touch and pause tests remain included. The earlier emulator results apply to v0.1.0; v0.2.0 is re-exported and signature-verified but has not had another emulator playthrough.

The v0.2.0 full-campaign rerun completed levels 1 and 2, but did not confirm completion of level 3 within the test budget. Final-level completion/balance and manual verification of the enlarged Mac window remain outstanding. The release is marked prerelease pending that follow-up.
