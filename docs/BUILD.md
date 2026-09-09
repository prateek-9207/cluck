# Build and play

## Ready-to-play builds

Download the APK or Mac ZIP from this repository's v0.2.0 release. The repository is private, so sign into the owner's GitHub account to download.

- Android: copy `cluck.apk` to an Android phone and open it to install. This is a development-signed APK, intended for direct testing, not a Play Store release. No account, network permission, ads or payments are required.
- Mac: unzip `Cluck-macOS.zip`, then open `Cluck.app`. This local build is ad-hoc signed and is not Apple-notarized.
- Source: open `project.godot` in Godot 4.7.2 and run the main scene.

Controls: drag to move on mobile; WASD, arrows or mouse drag on desktop. Attacks are automatic. Collect blue gems and choose upgrades. Return to the coop to spend coins on lasting improvements and weapons.

## Rebuilding on this workstation

Run `tests/export_local.sh`. The Android SDK and Java are installed under the ignored `.toolchain/` directory, with Godot's editor settings pointing to their permanent absolute locations. The development signing key is local and excluded from Git.

Run `tests/run_tests.sh` for lifecycle and accelerated campaign checks. Set `GODOT_BIN` if Godot is installed at a different path.

## Setting up another workstation

1. Install Godot 4.7.2 and its matching export templates. The committed export presets use custom template paths under `.toolchain/templates/`; place `android_debug.apk`, `android_release.apk` and `macos.zip` there, or clear those fields in Godot to use globally installed templates.
2. Install OpenJDK 17 and Android SDK platform-tools, build-tools 35.0.1, and platform 35. Set the Java and Android SDK paths in Godot's Editor Settings.
3. Generate a local Android debug keystore and set `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER` and `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD` when exporting. The local helper uses the conventional debug alias/password; do not use that key for production distribution.
4. Import `project.godot` once, then export the Android or macOS preset.

Reference: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

## Editable art

Open `art/cluck_assets.blend` in Blender. `art/build_assets.py` regenerates the original animal and farm models and exports their GLBs. `art/build_audio.py` generates the original sound effects and music without third-party samples. Godot consumes the committed exported assets and does not need Blender installed just to run the game.

## Saves

Normal progress uses Godot's `user://cluck_save.json`. On macOS that is `~/Library/Application Support/Godot/app_userdata/Cluck/cluck_save.json`. Tests and staged screenshot capture use a separate test save. Coins save every five seconds and when pausing due to lost focus or ending a run.
