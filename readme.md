# Timefolk

[![Swift](https://img.shields.io/badge/Swift-F54A2A?logo=swift&logoColor=white)](#) [![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=F0F0F0)](#)

A native macOS menu bar clock for friends, teammates and cities, with a fixed PST preset for Tibo’s Codex reset announcements.

Timefolk is an independently maintained continuation of [There](https://github.com/dena-sohrabi/There).

This maintenance fork currently builds from source. The Homebrew cask named
`there` installs the original upstream release, without the changes described here.

![Screenshot of the original There app](https://there.pm/app@2x.jpg)

*Screenshot from the original There project; it does not show Timefolk’s newer changes.*

- Add photos for people from X (Twitter), Telegram or pick locally
- Add any city without knowing the time zone
- Supports raw UTC offsets
- Tibo time zone preset for Codex reset announcements, fixed at PST (UTC−08:00) year-round
- 0-1% idle CPU usage
- Ultra-low memory
- Written in Swift UI
- macOS 13.5+

## Development

Use Xcode with Swift 6.1 or newer. Open `There.xcodeproj`; Swift Package Manager
fetches the pinned official packages automatically. No folders in `Downloads`
or original author's signing team are required.

```sh
xcodebuild -project There.xcodeproj -scheme There \
  -destination 'platform=macOS' -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build

xcodebuild -project There.xcodeproj -scheme There \
  -destination 'platform=macOS' -derivedDataPath build \
  -only-testing:ThereTests CODE_SIGNING_ALLOWED=NO test
```

For installation, distribution or Login Item testing, choose your own signing
team in Xcode. Unsigned builds are for local development. The CI workflow builds
and runs unit tests on macOS; UI tests require macOS accessibility permissions.
Tests use an in-memory database and disable analytics. They do not reset the
normal app database.

### Validation (2026-10-23)

Local checks use Apple Silicon, macOS 27.0.1 and Xcode 27.1. Debug and Release
builds pass with code signing disabled. The 12 unit tests
pass, including compatibility with an existing database and failed avatar-write
rollback. The app still targets macOS 13.5, but older systems and Intel Macs
have not been tested at runtime.

The default **There** scheme and CI run unit tests. The separate **There-UI**
scheme contains the menu bar smoke test. On the current multi-display setup,
macOS/XCTest places menu elements outside the hittable screen region, so the UI
smoke test has not passed. No end-to-end click verification is claimed. Re-run
that scheme on a suitable desktop before distributing a release. Login Item
registration also needs verification with a properly signed installed app.
The CI workflow is prepared but has not been run on GitHub.

### Tibo time zone

In **Add**, choose **🕒 Tibo time zone**, then **Add** to save it. You can also
search for `Tibo`, `Codex`, `reset` or `PST` in the time zone picker. This preset
uses fixed PST (UTC−08:00) throughout the year. The separate Los Angeles option
continues to follow daylight saving time. No reset schedule is fetched; the
preset is a clock for interpreting announcements that explicitly use PST.

### Dependencies

- [GRDB.swift 7.11.1](https://github.com/groue/GRDB.swift/releases/tag/v7.11.1)
- [MenuBarExtraAccess 1.3.1](https://github.com/orchetect/MenuBarExtraAccess/releases/tag/1.3.1)
- [PostHog 3.92.2](https://github.com/PostHog/posthog-ios/releases/tag/3.92.2)

The lockfile records exact versions and resolved revisions so dependency changes
can be reviewed explicitly. The unused Sparkle reference has been removed; automatic updating is
still not implemented. Existing optional email signup and analytics integrations
are retained; no signup is needed to use the clock.

### Existing installations

The database location and schema are preserved. Development builds no longer
erase the database automatically when migration definitions change. Back up the
app's Application Support directory before switching between release builds and
custom builds with different signing or sandbox settings.

Login at startup now uses only macOS `SMAppService`. If an older version created
`~/Library/LaunchAgents/pm.there.There.LaunchAgent.plist`, unload and remove that
legacy item before enabling **Launch at Login** again. The app no longer creates
a second agent that continually restarts it after Quit.

## Roadmap

We want to keep the app as simple as possible. But here are the things we're considering for future versions:

- [ ] Widgets
- [x] Time slider to view future/past times
- [ ] Auto-update
- [ ] Apple Script API for third-party integrations i.e. Raycast

## Contributions

Contributions are welcome! For simple fixes or improvements feel free to open a PR with the smallest change.

For features or improvements that add scope to the app or have user facing changes, please open an issue first to discuss your proposal.

If you want to tackle any of the items in the roadmap section, please also open an issue.

## Acknowledgements

Thank you to [Dena Sohrabi](https://github.com/dena-sohrabi) for creating
[There](https://github.com/dena-sohrabi/There) and sharing it as open source.
Timefolk builds on that work, continuing its maintenance and adding new features.
We are grateful for the original design, implementation and contributions that
made this project possible.

The original copyright notice and MIT license are preserved in [LICENSE](LICENSE).

## License

This project is licensed under the [MIT License](LICENSE)
