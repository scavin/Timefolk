# Changelog

## 2.1 — 2026-10-23

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
