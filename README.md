## ImmaDeploy

ImmaDeploy is a lightweight macOS menu bar app that tells you **whether you should deploy today** using the public `shouldideploy.today` API.  
It periodically fetches the latest status for your timezone and language, and shows the current message directly in the menu bar with quick access to settings and refresh.

### Features

- **Menu bar first**: Runs as a menu bar app (no dock icon) so it stays out of your way.
- **Live deploy status**: Periodically calls `https://shouldideploy.today/api` and shows the current message in the status bar title.
- **Configurable timezone**: Choose which timezone the check should use (backed by a `timezones.json` resource or system time zones as fallback).
- **Language support**: Automatically detects your preferred language (`en`, `pt`, `es`, `es-AR` when available) and lets you change it in settings.
- **Quick actions**: Right‑click/secondary‑click the menu bar icon for **Refresh**, **Settings**, and **Quit**.

### How it works (architecture)

- **`ImmaDeployApp` / `AppDelegate`**:
  - Sets the activation policy to accessory so the app runs in the menu bar.
  - Creates an `NSStatusItem` with a title bound to the view model’s `message`.
  - Provides a context menu (Refresh, Settings…, Quit) and a popover for settings.
- **`DeployViewModel`**:
  - Holds published state: `message`, `isLoading`, `selectedLanguage`, `selectedTimezone`, and the list of `timezones`.
  - On init:
    - Loads timezones from `Resources/timezones.json` (or from `TimeZone.knownTimeZoneIdentifiers` as a fallback).
    - Detects system language and timezone and picks a supported language.
    - Fetches the initial deploy status and starts a periodic timer (default: every hour).
  - `fetchDeployStatus()`:
    - Builds the `https://shouldideploy.today/api` URL with `tz` and `lang` query parameters.
    - Performs the request via `URLSession` and decodes the JSON into `ShouldIDeployTodayResponse`.
    - Updates `message` with the API’s `message` field, or an error message on failure.
  - `updateLanguage(_:)` and `updateTimezone(_:)` update settings and refresh the status (with a short delay for smooth picker interaction for timezone).
- **Views (`MenuBarView`, `SettingsView`, `ContentView`)**:
  - Present the UI (settings, language/timezone pickers, status, loading state) using SwiftUI and bind to `DeployViewModel`.

### Requirements

- **macOS**: 13+ (Ventura) or later is recommended.
- **Xcode**: 15+ (or the version you are using for this project).
- **Swift**: Uses modern Swift + SwiftUI and async/await networking.

### Running the app

1. **Clone the repo**
   ```bash
   git clone <your-repo-url> ImmaDeploy
   cd ImmaDeploy
   ```
2. **Open in Xcode**
   - Open `ImmaDeploy.xcodeproj` in Xcode.
3. **Select the scheme**
   - In the toolbar, select the `ImmaDeploy` scheme and a **My Mac** destination.
4. **Build & run**
   - Press **⌘R** to build and run.
   - The app should appear as an icon/title in the **menu bar** (no dock icon).

### Using ImmaDeploy

- **Check deploy status**
  - Look at the menu bar text; it will show the current message from `shouldideploy.today` for your configured timezone/language.
- **Refresh**
  - Right‑click (or control‑click) the menu bar item and choose **Refresh** to fetch the latest status immediately.
- **Open settings**
  - Left‑click or select **Settings…** from the context menu to open the SwiftUI settings popover.
  - Change **language** and **timezone**; the app will refresh the status based on your selection.
- **Quit**
  - Right‑click the menu bar item and choose **Quit**.

### Configuration details

- **Timezones**
  - The app reads `Resources/timezones.json` if present to populate the timezone list.
  - If that file is missing or invalid, it falls back to `TimeZone.knownTimeZoneIdentifiers.sorted()`.
- **Languages**
  - The app inspects `Locale.preferredLanguages` and picks:
    - `en`, `pt`, or `es` if the first preferred language matches.
    - `es-AR` in the special case where the preferred language starts with `es-AR`.
    - `en` as a final fallback.

### Development notes

- **Networking**
  - The view model uses `URLSession.shared.data(from:)` with async/await and decodes into `ShouldIDeployTodayResponse`.
  - Errors are surfaced into the `message` property as `Error: <localizedDescription>`.
- **Background refresh**
  - A `Timer` is scheduled on the main run loop to periodically call `fetchDeployStatus()` at a configurable interval (`fetchInterval` in `DeployViewModel`).
  - The timer is invalidated in `deinit` to avoid leaks.

### License

Add your preferred license here (e.g., MIT, Apache 2.0) if you plan to open‑source this project.

