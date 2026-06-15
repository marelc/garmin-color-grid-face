# Garmin Color Grid Watch Face

Starter Garmin Connect IQ watch face inspired by the attached layout.

Target watch: Garmin fēnix 7 Pro Sapphire Solar, using the `fenix7pro`
Connect IQ product target.

## Setup on Windows

1. Install Visual Studio Code.
2. Install Garmin's Connect IQ SDK Manager.
3. In SDK Manager, download the latest Connect IQ SDK and the fēnix 7 Pro device profile.
4. In VS Code, install the Garmin "Monkey C" extension.
5. Open this folder in VS Code.
6. Run `Ctrl+Shift+P` -> `Monkey C: Verify Installation`.
7. Run `Ctrl+Shift+P` -> `Monkey C: Build Current Project`.
8. Run `Ctrl+Shift+P` -> `Monkey C: Run Current Project` to test in the simulator.

## Installing on a watch

Build the project for your exact Garmin model. The build creates a `.prg` file in `bin`.

To sideload:

1. Connect the watch to Windows by USB.
2. Open the watch drive in File Explorer.
3. Copy the `.prg` file to `GARMIN/APPS`.
4. Eject the watch safely and disconnect.
5. On the watch, select the watch face from watch-face settings.

If the watch rejects the app, confirm that SDK Manager has the fēnix 7 Pro device files installed, then rebuild.
