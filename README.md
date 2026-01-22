<div align="center">
    <img src="ImmaDeploy/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width=200 height=200>
    <h2 style="margin-bottom: 0.3em;">Imma Deploy?</h2>
    <h4 style="margin-top: 0;">The "Should I Deploy Today?" directly in your menu bar!</h4>

"Imma Deploy?" is my first macOS application. It's a lightweight macOS menu bar app that tells you **whether you should deploy today (or not)** using the public [Should I Deploy Today?](https://shouldideploy.today/) API.

It simply fetches the latest status for your timezone and language, and shows the current message directly in the menu bar.

This ensures you won't play with the deploy, lol 🥸

![Imma Deploy? Demo](Resources/immadeploy.gif)

[![Download](https://img.shields.io/badge/download-latest-brightgreen?style=flat-square)](https://github.com/rckmath/ImmaDeploy/releases/latest)
![Platform](https://img.shields.io/badge/platform-macOS-blue?style=flat-square)
![Requirements](https://img.shields.io/badge/requirements-macOS%2013.5%2B-fa4e49?style=flat-square)
[![License](https://img.shields.io/github/license/rckmath/ImmaDeploy?style=flat-square)](LICENSE)

   <a href="https://www.buymeacoffee.com/rckmath" target="_blank">
       <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;  width: 217px !important;">
   </a>
</div>

---

## Features

- **Menu bar first**: Runs as a menu bar app (no dock icon) so it stays out of your way
- **Live deploy status**: Periodically calls `https://shouldideploy.today/api` and shows the current message in the menu bar
- **Configurable timezone**: Choose which timezone the check should use (backed by a `timezones.json` resource or system time zones as fallback)
- **Multi-language support**: Automatically detects your preferred language (`en`, `pt`, `es`, `es-AR` when available) and lets you change it in settings
- **Launch at startup**: Option to automatically launch the app when you log in
- **Manual refresh**: Right-click the menu bar item to refresh immediately

---

## Install

### Manual Installation

Download the latest release from the [releases page](https://github.com/rckmath/ImmaDeploy/releases/latest) and move the app into your `Applications` folder.

_Allowing the application through macOS Privacy & Security settings may be needed._

### Build from Source

1. **Clone the repo**

   ```bash
   git clone https://github.com/rckmath/ImmaDeploy.git
   cd ImmaDeploy
   ```
2. **Open in Xcode**

   - Open `ImmaDeploy.xcodeproj` in Xcode.
3. **Select the scheme**

   - In the toolbar, select the `ImmaDeploy` scheme and a **My Mac** destination.
4. **Build & run**

   - Press **⌘R** to build and run.
   - The app should appear as text in the **menu bar** (no dock icon).

---

## Configuration

### Timezones

The app reads `Resources/timezones.json` if present to populate the timezone list. If that file is missing or invalid, it falls back to `TimeZone.knownTimeZoneIdentifiers.sorted()`.

### Languages

The app inspects `Locale.preferredLanguages` and automatically selects:

- `en`, `pt`, or `es` if the first preferred language matches
- `es-AR` in the special case where the preferred language starts with `es-AR`
- `en` as a final fallback

Supported languages:

- English (`en`)
- Português (`pt`)
- Español (`es`)
- Español (Argentina) (`es-AR`)

---

## Requirements

- **macOS**: 13.5 (Ventura) or later
- **Xcode**: 15+ (for building from source)
- **Swift**: Uses modern Swift + SwiftUI and async/await networking

---

## How It Works

"Imma Deploy?" uses the [Should I Deploy Today?](https://shouldideploy.today/) API to fetch deploy recommendations based on:

- The current day of the week
- Your selected timezone
- Your selected language

The app periodically fetches this information and displays the API's message directly in your menu bar. The message updates automatically, and you can manually refresh at any time.

---

## License

"Imma Deploy?" is available under the [GPL-3.0 license](LICENSE).
