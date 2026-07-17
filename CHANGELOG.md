# Changelog

## 1.2.0 - 2026-07-16

### Unified storage

- Consolidated updater source, module settings and weapon profiles into one length-prefixed `rgnMultitool_data.txt` container.
- Added automatic migration from every v1.1 configuration, profile, diagnostic and updater-cache file.
- Added a validated one-time upgrade path for the original public `loader.lua`.
- Removed separate runtime diagnostic logs and the redundant weapon-engine cache.
- Debounced configuration writes so rapid slider/control changes produce one physical save.

### Reliability

- Preserved the exact embedded weapon engine used by the previously validated cache.
- Added fresh-session serialization coverage, offline startup checks and corrupt-update rollback tests.
- Fixed a loader serialization defect discovered during live migration testing.

## 1.1.0 - 2026-07-16

### Added

- Movement module with velocity display, jump trail, edge-bug prediction and null binds.
- Multilingual Killsay with custom messages and optional victim-name substitution.
- Identity module for independently controlled custom names and clan prefixes.
- Always-on local vote information with voter overlay and team-colored chat labels.

### Improved

- Complete modern and legacy weapon-finish handling.
- Knife and glove persistence across deaths, team switches and map changes.
- Session rearming for cosmetics and event-driven modules when joining another match.
- Vote controller resolution, team attribution and surrender detection after disconnects.
- Runtime scheduling and maintenance frequency to reduce frame-time impact.

### Safety and defaults

- Movement, Identity and Killsay remain disabled until explicitly enabled.
- Updates are downloaded to a cache and require running the Lua again; code is never hot-loaded during a match.
- The loader validates source size, release signature, version and Lua syntax before replacing its cache.
