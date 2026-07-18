# Changelog

## 1.1.4 - 2026-07-18

### English vote-revealer output

- Translated every visible vote type, start, choice, result and fallback message to English.
- Preserved team-colored local chat output, voter overlay, event handling and the session-transition crash fix from 1.1.3.
- Kept Spanish text exclusively in the opt-in Argentina Killsay pack.

## 1.1.3 - 2026-07-18

### Session-transition crash hotfix

- Fixed the native access violation reproduced when entering or leaving a match while Killsay attempted to re-register `FireGameEvent` from the main Draw callback.
- Registered the Killsay and vote-revealer event bridges exactly once at module load; map and server transitions now only renew listeners and reset Lua state.
- Preserved the always-on vote revealer, opt-in Killsay, cosmetics and the proven per-file configuration/cache layout from 1.1.0.

## 1.1.2 - 2026-07-17

### Vote revealer restoration

- Restored the always-on vote revealer while retaining the v1.1 per-file configuration and cache layout.
- Moved listener refresh, session polling and local-chat queue work out of the Draw callback into a throttled logic callback.
- Limited Draw to overlay rendering and added independent re-entry guards plus generation invalidation for reload/unload safety.
- Preserved cosmetics, agents, custom characters, viewmodel, movement, Identity, Killsay and saved configurations unchanged.

## 1.1.1 - 2026-07-17

### Emergency stability hotfix

- Disabled the built-in vote revealer after two crash dumps identified its recursive Draw callback as the repeated stack-overflow path.
- Preserved cosmetics, agents, custom characters, viewmodel, movement, Identity, Killsay and saved configurations unchanged.
- Restored the proven per-file cache/configuration path from 1.1.0 and removed the 1.2.0 unified-storage release.

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
