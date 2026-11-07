# Azen Notch

An iPhone Dynamic Island / MacBook notch style widget for the KDE Plasma 6 panel.
Sits centered on the top panel: a pure black pill with a camera dot.

## Features

- **Idle**: a pure black capsule about 5 app icons wide (with a MacBook-style camera dot in the middle)
- **Notifications**: springs open to show the app icon + title + app name/body, collapses after
  3 seconds (up to 3 notifications queued)
- **Volume**: expands to show a white speaker glyph + volume bar + percentage for 3 seconds;
  click the speaker to toggle mute, drag the bar to adjust volume
- **Brightness**: expands to show a white sun glyph + brightness bar + percentage for 3 seconds;
  drag the bar to adjust brightness
- Expansion uses an iOS-style spring curve (Easing.Bezier). The widget reserves a fixed width in
  the panel and morphs inside it, so neighbors never get pushed around

## Shape (edge-attached notch)

- On a **top panel** it renders as a true MacBook-style notch: the top edge spans the full width
  flush against the screen edge, with an **outward-bulging arch** on each side (an outward arc
  joined tangentially to the bottom inner arc at the side midpoint, forming one continuous smooth
  curve with no straight segments or seams). The junction blends invisibly into the screen's
  black frame. On a bottom panel it mirrors downward automatically; on the desktop it keeps the
  full floating capsule
- Edge-attached mode auto-detects the panel position (`Plasmoid.location`) and measures the
  actual distance from the widget slot to the screen edge (`attachGap`) at runtime, guaranteeing
  a zero-gap connection

## Configuration (constants at the top of `contents/ui/main.qml`)

| Constant | Default | Meaning |
|---|---|---|
| `idleWidth` | 178 | Width at rest |
| `noticeWidth` | 350 | Width when showing a notification (also the reserved panel width) |
| `ctrlWidth` | 270 | Width for volume/brightness |
| `showDuration` | 3000 | Display duration (ms) |
| `notchColor` | #000000 | Capsule color |

After editing, reinstall with `kpackagetool6 -t Plasma/Applet -u .` and restart plasmashell.

## Technical notes

- **Notifications**: `org.kde.notificationmanager`'s `Notifications` model, using
  `unreadNotificationsCount` deltas to detect new notifications (so history is not replayed at startup)
- **Volume**: `org.kde.plasma.private.volume`'s `PreferredDevice.sink` + `PulseAudio.NormalVolume`,
  listening to `volumeChanged`/`mutedChanged`
- **Brightness**: `org.kde.plasma.private.brightnesscontrolplugin`'s `ScreenBrightnessControl`,
  watching `brightnessChanged` on the `displays` model
- **Deploy**: `kpackagetool6 -t Plasma/Applet -i .` (use `-u` to upgrade)
- **Debug**: `journalctl --user -u plasma-plasmashell.service`

## Testing

- `test/engines.qml`: smoke test for the three data sources
- `test/views.qml`: render test for the three views
- `test/screenshot.py`: full-screen capture via xdg-desktop-portal
- Real triggers: send a notification via
  `gdbus call ... org.freedesktop.Notifications.Notify`; simulate the volume key with
  `qdbus6 org.kde.kglobalaccel /component/kmix ... invokeShortcut increase_volume`; simulate the
  brightness key with `... /component/org_kde_powerdevil ... "Increase Screen Brightness Small"`
