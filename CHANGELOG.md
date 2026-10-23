# Changelog

## 2.1 — 2026-10-23

- Fix missing app icon on compiled .app bundle: configure `ASSETCATALOG_COMPILER_APPICON_NAME`, generate multi-resolution 16px–1024px `AppIcon.appiconset` and `AppIcon.icns`, and ensure both `CFBundleIconFile` and `CFBundleIconName` are populated in `Info.plist`.
- Fix legacy data migration when transitioning from `pm.there.There` to `com.timefolk.Timefolk`: seamlessly copy SQLite database, Photos, and user preferences on first launch, with fallback lookup for existing photo paths and Apple ContainerMigration.plist support.
- Fix time slider seconds drift: align base time and offset calculations to minute boundaries (second = 0), eliminating fractional-second errors so chosen times (e.g. 07:30) and calendar exports strictly match.
- Fix relative day badge accuracy: compare friend's calendar date against user's local reference date in UTC rather than misapplying local calendar to friend timestamps, preventing false "明天/昨天" labels.
- Prevent Tibo re-seeding when empty: record `hasSeededDefaultEntries` so deleting all friends permanently leaves the list empty without resurrecting default entries on subsequent launches.
- Support customizing personal timezone and city: users can freely search and set any global city/timezone in their profile, or toggle back to automatically following macOS system time, with all relative friend time differences and sun/moon cycles adapting instantly.
- Optimize dark mode button contrast and typography: use fully opaque accent background without dark material bleed-through, apply high-luminance accent colors, and add subtle text drop shadow for razor-sharp legibility.
- Add 24-hour time format toggle to Settings menu with instant live switching across all world clocks.
- Directly enter editing on right click (secondary click) with zero pop-up menus; add a red "删除朋友" button directly inside the friend editing interface.
- Streamline "添加到日历" action in time travel scrubber into a minimal Apple circular icon button (`calendar.badge.plus`), reducing visual clutter while preserving 2s success feedback and descriptive tooltips.
- Remove redundant "项目源码" link from the Settings gear menu, consolidating project links exclusively inside the "关于 Timefolk" view.
- Overhaul time travel interaction model:
  - Directly clicking any friend card immediately expands an inline time scrubber inside that specific friend's row.
  - Remove left-click editing; editing a friend's details is now exclusively triggered via right-click (context menu "编辑").
  - Remove the detached bottom-docked time travel bar; embedding the scrubber and quick-jump targets directly inside the anchor person's row card.
- Add dedicated "关于 Timefolk" (About Timefolk) page accessible via the Settings gear menu, displaying the app icon, version number (`版本 2.1 (3)`), running architecture (`Apple Silicon arm64`), GitHub open source repository link, and MIT license.
- Fix clipped personal profile view by switching to top-aligned adaptive layout, keeping the navigation bar and avatar permanently visible without top/bottom overflow.
- Replace cramped profile avatar source buttons with native macOS segmented control (`本地` | `Telegram` | `X`), eliminating text ellipsis truncation.
- Remove redundant "+添加时区" header from Titlebar when in Add mode, keeping a clean and minimal left-aligned navigation back button across all subviews.
- Support fetching personal profile avatar from Telegram and X (Twitter) handles with 600ms debounce and non-blocking asynchronous fetching via unavatar.io; save fetched avatars 100% locally to maintain full offline usability.
- Seed Tibo as default out-of-the-box friend entry on clean install/onboarding, removing redundant preset buttons and promoted search suggestions from the Add Timezone form.
- Replace ambiguous "早到晚排" toggle with Apple native inline picker "时区排序" offering clear mutual exclusion between "由早到晚" and "由晚到早".
- Streamline Time Slider into a focused controller by removing redundant target time display and consolidating anchor selection with offset badge and reset action; keep all dynamic timestamps exclusively in the primary clock list.
- Pin permanent "我的时间" (Local Time) card with customized name, location subtitle, and day/night indicator at the top of the main list, ensuring user local reference time is always visible during time travel.
- Replace onboarding email collection with local user name customization ("你的称呼"), completely removing external marketing network requests and seamlessly integrating the user's name into local clock badges and time travel anchors.
- Rename build product and application display name from There.app to Timefolk.app, updating Xcode targets, bundle metadata, executable name, and test suites.
- Add anchor-based time travel: support shifting the reference time anchor of the Time Slider to any tracked friend or city (e.g. Tibo) via an anchor dropdown menu or right-click "以此推演", with automatic clean half-hour snapping and real-time world clock synchronization.
- Clean up Settings menu by removing external support and social links (DM on X, Email Us, Open Website, Follow on X) and adding official GitHub project link (https://github.com/scavin/Timefolk).
- Overhaul all menu and feature copywriting into everyday, natural Apple-style microcopy adhering to "Don't Make Me Think" and "The Non-Designer's Design Book": strictly 2–4 character action titles, concise <20 character intuitive descriptions, zero technical jargon, and friendly relative time offsets.
- Expand time slider range to +/- 3 days (-72h to +72h) with half-hour granular scrubbing, relative day badges (今天/明天/昨天/星期), dynamic duration label (+/-N天 N小时), quick-jump shortcut markers (-3d, -1d, 此刻, +1d, +3d), and calendar-safe day difference calculations across month boundaries.
- Update application branding with new 2026 Apple minimalist AppIcon (intersecting dual-timezone halos with Find My emotional beacons) generated across all 16px-1024px macOS asset scales, with matching monochromatic status bar template icons and onboarding logo.
- Add a dedicated avatar for Tibo preset and search results, bundled in asset catalog with automated asset verification tests.
- Modernize UI conforming to 2026 native macOS design language: native .regularMaterial vibrancy, continuous squircles, 0.5pt hairline borders, monospaced digit typography with relative day badges, floating time scrubber with reset button, and responsive form layout.
- Add a Tibo preset with fixed PST (UTC−08:00), available in Add and time zone search.
- Replace author-specific local package paths with pinned official Swift packages;
  keep the package lockfile and a shared build/test scheme in the repository.
- Update GRDB, MenuBarExtraAccess and PostHog; remove the unused Sparkle reference
  and unrelated mobile/visionOS build settings. Keep macOS 13.5 as the app target.
- Show save/delete errors. Do not leave a form when a write fails. Validate time
  zone identifiers before storing entries.
- Save avatars atomically, clean up failed writes and replaced files, and preserve
  nil when an entry has no avatar. Expand randomly generated record IDs to reduce
  collisions with existing entries.
- Preserve the current database schema and location. Stop automatically deleting
  the development database when migration definitions change.
- Resolve known city identifiers without geocoding, discard outdated search
  completions, handle fractional fixed UTC offsets, and adapt search to dark mode.
- Share one minute-aligned refresh schedule across clocks. Use the preview date
  for daylight saving differences, sort with minute precision, and remember the
  selected sort direction.
- Use only SMAppService for new login items; show registration errors and approval
  status. Existing legacy LaunchAgents require the migration described in README.
- Validate avatar download responses and discard cancelled requests.
- Add isolated database/time zone regression tests, a menu bar UI smoke test and
  a macOS CI workflow. Keep analytics disabled and the database in memory in tests.

Local validation and remaining installation checks are recorded in README.
