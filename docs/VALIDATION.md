# Validation

## Verified so far

- Godot imports and runs the project without script errors or warnings in the current debug session.
- Automated lifecycle checks exercise real combat methods, rewards after defeat, duplicate-result guards, affordable and unaffordable purchases, save reload, equipped weapons, permanent stats, touch drag/release, pause, temporary upgrade choice and all campaign unlocks.
- A deterministic full campaign simulation completed all bosses in approximately 3:33, 4:39 and 5:40. Total: about 13:51 of combat.
- The campaign bot uses normal attacks, enemy spawning and progression, but restores its own health and attracts pickups. It checks long-run behaviour and completion; it is not evidence that a new player will survive or that difficulty is fully balanced.
- Desktop UI inspection confirmed purchase/equipment updates: 82 coins → Feather Ring purchase → 17 coins, with Feather Ring marked equipped and unaffordable purchases disabled.
- Rendered screenshots were checked and prompted corrections to over-bright materials, character facing, camera framing and farm density.
- Android development APK export and signing verification succeeded. A native Mac app also exports successfully.

## Remaining checks

- Install and launch the final APK in an Android emulator.
- Check final packaged Mac startup and final screenshots.
- Physical Android hardware, thermal behaviour and low-end phone performance have not been tested.

Tests use `cluck_test_save.json`, separate from normal player progress. Run `tests/run_tests.sh` with Godot installed. Set `GODOT_BIN` when its executable is elsewhere.
