<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Soniq app icon">
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/logo-dark.png">
    <img src="docs/logo-light.png" width="230" alt="Soniq">
  </picture>
</p>

<p align="center">
  <strong>The sound control center macOS should have shipped with.</strong><br>
  Volume boost up to 200%, per-app volume, sound effects, microphone control and a headphone test,<br>
  right in your menu bar. Native, minimal, no drivers.
</p>

<p align="center"><sub>Developed by <strong>Vision Tech</strong></sub></p>

<p align="center"><a href="README.md">Português</a> · <strong>English</strong></p>

<p align="center">
  <a href="https://github.com/webdevpls/soniq/releases/latest"><img src="https://img.shields.io/github/v/release/webdevpls/soniq?label=download&color=0a84ff" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/macOS-14.2%2B-black?logo=apple" alt="macOS 14.2+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/Apple%20silicon%20%2B%20Intel-universal-555" alt="Universal binary">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-GPL--3.0-green" alt="License: GPL-3.0"></a>
</p>

<p align="center">
  <img src="docs/hero.png" alt="Soniq: apps, effects and headphone test" width="100%">
</p>

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [First launch](#first-launch)
- [User guide](#user-guide)
  - [Volume and boost](#volume-and-boost)
  - [Output device](#output-device)
  - [Microphone](#microphone)
  - [Per-app volume and balance](#per-app-volume-and-balance)
  - [Sound effects](#sound-effects)
  - [Headphone test](#headphone-test)
  - [Settings](#settings)
- [Privacy](#privacy)
- [How it works](#how-it-works)
- [Building from source](#building-from-source)
- [Project structure](#project-structure)
- [Troubleshooting & FAQ](#troubleshooting--faq)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License & trademark](#license--trademark)

## Features

| | |
| --- | --- |
| 🔊 **Volume boost to 200%** | Go past the hardware maximum. A transparent peak limiter keeps it loud without crackling. |
| 🎚️ **Per-app volume** | Every app that plays audio gets its own slider. Mute any app with one click. |
| ↔️ **Left / right balance per app** | Send a video call to one ear and music to the other. |
| ✨ **Sound effects** | Bass Boost, Party, Underwater, Concert, Next Room, In the Car, Radio, 3D Wide, Vocal, Night and Cinema, with intensity, bass and treble. |
| 🎙️ **Microphone control** | Choose the input and set its level. *Keep this microphone* stops macOS from jumping to your headset mic. |
| 🎧 **Headphone & AirPods test** | Left/right check, stereo sweep, 20 Hz–20 kHz sweep, bass response and phase check. |
| 🔀 **Output switcher** | Change speakers, headphones, AirPods or displays in one click. |
| 🪟 **Native design** | SwiftUI and Liquid Glass on macOS 26, translucent materials on macOS 14–15. Light and dark mode. |
| 🪶 **Lightweight** | No kernel extension, no virtual audio device. Apps you don't touch are never intercepted. |

## Requirements

- macOS **14.2 Sonoma** or later (Liquid Glass look on macOS 26 Tahoe)
- Apple silicon or Intel Mac
- About 5 MB of disk space

## Installation

### Download (recommended)

1. Download **`Soniq-x.y.z.dmg`** (recommended) from the [latest release](https://github.com/webdevpls/soniq/releases/latest).
2. Open the DMG and drag **Soniq** into **Applications**. (A `.zip` is also available.)
3. Open Soniq. Its icon appears in the menu bar, not in the Dock.

> [!NOTE]
> Soniq isn't notarized by Apple yet, so the first time you open it macOS says it can't verify the developer.
> Go to **System Settings → Privacy & Security**, scroll down and click **Open Anyway**. You only need to do this once.
>
> Prefer the terminal? `xattr -dr com.apple.quarantine /Applications/Soniq.app`

### Build it yourself

See [Building from source](#building-from-source).

## First launch

The first time you raise the boost, change an app's volume or pick an effect, macOS asks:

> *"Soniq" would like to record this computer's audio.*

Click **Allow**. macOS calls this permission **System Audio Recording**. Soniq needs it to process other apps' sound before it reaches your speakers. **Nothing is recorded, saved or sent anywhere.** See [Privacy](#privacy).

macOS asks only once. You can change your answer later in **System Settings → Privacy & Security → Screen & System Audio Recording**, or from **Soniq → Settings → Audio Permission…**

## User guide

Click the Soniq icon in the menu bar to open the panel.

### Volume and boost

<img src="docs/screenshots/apps.png" width="360" align="right" alt="Main panel">

The top slider controls your Mac's volume.

- **0–100%** is the normal system volume, the same as the volume keys.
- **100–200%** is **boost**. The slider warms up and the label changes to *Boost*. Soniq amplifies every app and runs it through a limiter, so quiet videos and calls get louder without distortion.
- Click the **speaker icon** to mute or unmute.
- Pressing the volume-down key ends boost automatically.

<br clear="right">

### Output device

<img src="docs/screenshots/output.png" width="360" align="right" alt="Output device list">

Click the **chevron** next to the volume slider to list every output: built-in speakers, headphones, AirPods, Bluetooth speakers, displays and AirPlay. Click one to switch. Effects and boost follow you to the new device.

<br clear="right">

### Microphone

<img src="docs/screenshots/microphone.png" width="360" align="right" alt="Microphone list">

The second slider is your **microphone level**. Click the mic icon to mute it.

Open its chevron to pick the input device. Turn on **Keep this microphone** to stay on the mic you chose: when headphones with a built-in mic connect, macOS normally switches to them (and Bluetooth headsets drop to call quality). Soniq switches right back.

> Some inputs, like an iPhone used as a microphone, don't allow their level to be changed. The slider is dimmed for those.

<br clear="right">

### Per-app volume and balance

The **Apps** tab lists every app that uses audio. Apps playing right now come first and show a green dot.

- **Drag** an app's slider to change only that app's volume.
- **Click the app icon** to mute it.
- Click **↔** to reveal the **balance** slider and move the app toward the left or right ear. It snaps back to center.

Apps that never make sound (Finder, Calendar, Preview, Terminal and similar) are hidden. Soniq remembers each app's volume, mute and balance, even after you quit it.

### Sound effects

<img src="docs/screenshots/effects.png" width="360" align="right" alt="Sound effects">

The **Effects** tab changes how everything sounds. Pick a scene, then fine-tune it:

| Effect | What it does |
| --- | --- |
| **Off** | Untouched sound |
| **Bass Boost** | Deep, punchy low end |
| **Party** | Bigger bass and treble, wider stereo, a touch of room |
| **Underwater** | Muffled, as if your head were under water |
| **Concert** | Large hall reverb and wide stage |
| **Next Room** | Music playing behind a closed door |
| **In the Car** | Warm low end in a small cabin |
| **Radio** | Narrow, slightly crunchy AM radio |
| **3D Wide** | Extra-wide stereo image |
| **Vocal** | Clearer voices for podcasts and calls |
| **Night** | Evens out loud and quiet parts so you can keep the volume low |
| **Cinema** | Bass, width and space for movies |

- **Intensity** blends the effect from subtle (0%) to full (100%).
- **Bass** and **Treble** add or remove up to 8 dB on top of any effect, including Off.

Effects apply to all apps.

<br clear="right">

### Headphone test

<img src="docs/screenshots/test.png" width="360" align="right" alt="Headphone test">

The **Test** tab checks your headphones, AirPods or speakers. With AirPods connected the buttons show each earbud.

| Test | What to listen for |
| --- | --- |
| **Left / Both / Right** | Chimes in the left side, both sides, then the right. Confirms the channels aren't swapped. |
| **Stereo Sweep** | A tone glides smoothly from ear to ear. Gaps or jumps point to a balance problem. |
| **Frequency Range** | A sweep from 20 Hz to 20 kHz with a live readout. Note where you stop hearing it. Most adults hear up to 14–17 kHz. |
| **Bass Response** | Deep tones from 25 to 160 Hz. Shows how low your headphones go and whether anything rattles. |
| **Phase Check** | The same noise in phase, then with one side inverted. The second half should sound hollow and "inside your head". If it doesn't, a channel may be wired backwards. |

Click a running test again to stop it.

<br clear="right">

### Settings

<img src="docs/screenshots/settings.png" width="360" align="right" alt="Settings">

Click the **gear** to open Settings, and the **‹** button (or Esc) to go back.

**Show in Menu**: hide the parts you don't use: Microphone, Effects, Headphone Test, or show only apps that are playing.

**General**
- **Launch at Login**: start Soniq automatically.
- **Keep Chosen Microphone**: the same lock as in the mic list.
- **Sound Settings…**: opens macOS Sound settings.
- **Audio Permission…**: opens the System Audio Recording privacy page.
- **Language**: Automatic (follows macOS), English or Português.

<br clear="right">

## Privacy

- Soniq processes audio **live, in memory**. It never records, saves or uploads sound.
- It makes **no network connections**: no analytics, no telemetry, no update checks.
- Settings (per-app volumes, effect choice) are stored locally in `~/Library/Preferences/io.github.soniq.plist`.
- The System Audio Recording permission is only used to adjust other apps' sound, and only for apps you change or while boost or an effect is on.

## How it works

Soniq is built on **Core Audio process taps**, an API Apple added in macOS 14.2.

```
 App audio ──► Process tap (original output muted)
                    │
                    ▼
            Private aggregate device ──► gain · balance · effects · limiter ──► Your speakers
```

1. When an app needs processing, Soniq creates a private **process tap** for it with `mutedWhenTapped`. macOS hands the app's audio to Soniq and silences the original output.
2. A private **aggregate device** (your current output plus the tap) plays the audio back through Soniq's realtime chain: gain ramp → balance → 10-band EQ → high/low-pass filters → drive → stereo width → reverb → compressor → peak limiter.
3. When the app is back to 100%, centered, with no boost or effect, Soniq destroys the tap and the untouched audio path returns.
4. If Soniq quits or crashes, macOS removes the taps automatically, so your audio never gets stuck.

Helper processes (Chrome, Safari/WebKit, Electron apps) are grouped under the app you see, using the system's "responsible process".

## Building from source

**Requirements:** Xcode 26 or newer (Swift 6.2+). No other dependencies.

```sh
git clone https://github.com/webdevpls/soniq.git
cd soniq

# Optional, once: create a local signing certificate so macOS keeps the
# audio permission across rebuilds (otherwise it asks after every build).
./scripts/setup-signing.sh

# Build a universal Soniq.app into ./build and a .dmg and .zip into ./dist
./scripts/build-app.sh
open build/Soniq.app
```

| Command | Description |
| --- | --- |
| `swift build` | Quick debug build to check the code compiles |
| `./scripts/build-app.sh` | Release build, app bundle, signing, DMG and zip (`VERSION=1.2.3` to set the version) |
| `swift scripts/make-icon.swift` | Regenerates the app icon, menu bar icon and logos from `Resources/Brand` |
| `SONIQ_DEBUG=1` | Environment variable that logs tap levels to the console |

> The permission prompt needs the bundled `.app`; running the bare binary from `.build` attributes audio access to your terminal.

## Project structure

```
Sources/Soniq
├── SoniqApp.swift              Menu bar entry point
├── SoniqModel.swift            State: apps, devices, boost, effects, taps, persistence
├── Audio
│   ├── AppTap.swift            Process tap + aggregate device + realtime render
│   ├── Effects.swift           Effect presets and the DSP chain (EQ, reverb, limiter…)
│   ├── HeadphoneTester.swift   Test tone generator
│   ├── AudioSystem.swift       Devices, volume, mute, audio process list
│   ├── AudioPermission.swift   System Audio Recording permission
│   ├── ProcessOwner.swift      Maps helper processes to their app
│   └── CoreAudio+Helpers.swift Typed Core Audio property access
└── Views
    ├── SoniqView.swift         Panel, tabs, apps and effects
    ├── TestTab.swift           Headphone test
    ├── SettingsView.swift      In-panel settings
    └── Components.swift        Sliders, glass cards, theme
Resources                       Info.plist, icons, brand artwork
scripts                         Build, signing and icon scripts
```

## Troubleshooting & FAQ

<details>
<summary><strong>An effect or volume change does nothing.</strong></summary>

Soniq needs the System Audio Recording permission. Open **Soniq → Settings → Audio Permission…** and make sure Soniq is turned on. If you denied it earlier, toggle it on there and reopen Soniq.
</details>

<details>
<summary><strong>An app went silent.</strong></summary>

Quit Soniq: macOS immediately restores every app's original audio. Then reopen it and check the permission above. Please [open an issue](https://github.com/webdevpls/soniq/issues) with the app's name if it keeps happening.
</details>

<details>
<summary><strong>The orange or purple recording indicator appears.</strong></summary>

That's macOS showing that Soniq is processing system audio while boost, an effect or a per-app change is active. It disappears when everything is back to default.
</details>

<details>
<summary><strong>Does it work with AirPods and Bluetooth speakers?</strong></summary>

Yes, with any output device. The headphone test shows separate left and right earbuds when AirPods are connected.
</details>

<details>
<summary><strong>Does it conflict with other audio apps?</strong></summary>

Soniq doesn't install a virtual device, so it can run next to most tools. If you use an app that routes audio through its own virtual device (for example Background Music or Loopback), keep your real speakers or headphones selected as the output in Soniq.
</details>

<details>
<summary><strong>Will it slow my Mac down?</strong></summary>

No. Apps at their default settings are never intercepted. Processing an app uses a fraction of a percent of CPU on Apple silicon.
</details>

<details>
<summary><strong>How do I uninstall it?</strong></summary>

Quit Soniq, delete it from Applications, and optionally remove `~/Library/Preferences/io.github.soniq.plist`.
</details>

## Roadmap

- [ ] Per-app effects
- [ ] Per-app output device
- [ ] Global keyboard shortcuts
- [ ] Custom effect presets
- [ ] Homebrew cask (`brew install --cask soniq`)
- [ ] Notarized builds
- [x] Português and English
- [ ] More languages (Español, …)

Have an idea? [Open a feature request](https://github.com/webdevpls/soniq/issues/new?template=feature_request.md).

## Contributing

Bug reports, ideas and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

## License & trademark

Soniq is free software released under the **[GNU General Public License v3.0](LICENSE)**. You can use, study, share and modify it. If you distribute a modified version, it must also be released under the GPL-3.0 with its source code.

The **Soniq name and logo are not covered by the GPL**. Forks and redistributions must use a different name and logo. See [TRADEMARKS.md](TRADEMARKS.md).

<p align="center"><sub>Developed by <strong>Vision Tech</strong> · Copyright © 2026 Vision Tech</sub></p>
