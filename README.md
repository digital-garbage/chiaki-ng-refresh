
![chiaki-ng Logo](gui/res/chiaking-logo.svg)

# chiaki-ng-refresh

A fork of [chiaki-ng](https://github.com/streetpea/chiaki-ng) (itself a fork of [Chiaki](https://git.sr.ht/~thestr4ng3r/chiaki) by Florian Markl) for PlayStation 4 and PlayStation 5 Remote Play, with a macOS-native look and feel. Streaming, registration and controller support are unchanged from upstream; this fork only changes the interface and a few interaction details.

## What changed

**Main window**
- Sidebar with your consoles and a detail pane with Connect and Wake Up buttons, grouped sections for console info, now playing and management.
- Dark macOS-style palette, 13 px base font, rounded translucent buttons.

**Settings**
- Opens as a modal sheet over the main window instead of a full-screen page.
- Sidebar navigation (General, Video, Stream, Audio/Wifi, Consoles, Keyboard and Mouse, Controllers, Remote, Config), content in rounded cards.
- Every row has its label above the control; dropdowns share one width.
- macOS-style pop-up dropdowns, 18 px checkboxes and radio buttons, thinner scrollbars.
- Mouse-wheel and trackpad scrolling now works (the window was not forwarding wheel events to the UI).
- Removed confusing hints such as "(Default)" in dropdown entries and the extra "(15 Mbps)" next to the bitrate.
- Stream settings regrouped into one column (Local, Remote).

**Streaming**
- The in-stream menu now has a labeled Disconnect button instead of a bare "x".
- Cmd+W disconnects and returns to the main menu without quitting the app.

**Controllers**
- Xbox Elite paddles can be mapped to any PlayStation button in Settings > Controllers. Paddle 1 defaults to the touchpad click, which Xbox pads otherwise cannot send.

**Keyboard and mouse**
- The Keyboard and Mouse tab shows your keyboard and mouse (connection type, battery for wireless ones) like the Controllers tab does for pads.
- Experimental: the mouse can act as a touchpad, as the right stick, as the D-Pad (pointer is re-centered continuously), or be off. Stick and D-Pad modes are rough: movement can be uneven and some moves may be missed. Sensitivity and Y inversion are adjustable, and every mouse button can be wired to any gamepad button.
- Presets store the key mapping plus the mouse settings. Add and remove them in the tab and switch between them during a stream from the stream menu (Cmd+O).

**Other**
- Redesigned About dialog.

The changes are mostly in `gui/src/qml` (`MainView.qml`, `DialogView.qml`, `SettingsDialog.qml`, `StreamMenuWindow.qml`, `controls/*`) plus two small edits in `gui/src/qmlmainwindow.cpp`.

## Building on macOS

Follow the [upstream documentation](https://streetpea.github.io/chiaki-ng/) for dependencies and the CMake build. Notes from running it on macOS:
- Xbox controllers work through SDL (tested with an Xbox One Elite Series 2).
- Paddles need direct HID access, which macOS gates behind Input Monitoring. The app asks for it at startup; allow it and restart. Sign every build with the same certificate, otherwise macOS forgets the permission after each rebuild.
- Registration and streaming need the Local Network permission. Use a code-signed app bundle (ad-hoc signing with `gui/entitlements.xml` is enough), include `NSLocalNetworkUsageDescription` in its Info.plist, and start it with `open`, not from a terminal.

## License

AGPL-3.0 with the OpenSSL exception, the same as upstream (see `COPYING` and `LICENSES/`). Original copyright notices of chiaki-ng and Chiaki are kept.

## Disclaimer
**Keyboard and mouse input is emulated as a gamepad.** Games and services that do not officially support keyboard and mouse on console may treat this as cheating or unfair input and can ban your account. Use it at your own risk. The authors and contributors of this repository bear no responsibility for any ban, loss or other consequence if you download this code and use it that way.

This project is not endorsed or certified by Sony Interactive Entertainment LLC. It is not affiliated with the upstream chiaki-ng project.

## Upstream
[chiaki-ng documentation](https://streetpea.github.io/chiaki-ng/) | [chiaki-ng community Discord](https://discord.gg/tAMbRuwXDH)
