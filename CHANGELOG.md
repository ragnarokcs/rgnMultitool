# Changelog

## 1.1.9 - 2026-07-18

### Chat-only vote information

- Removed the right-side voter overlay and its per-frame Draw callback.
- Vote initiators, targets, choices and results remain visible exclusively in the local in-game chat.
- Preserved real player-name resolution, team colors and the working left-hand knife behavior.

## 1.1.8 - 2026-07-18

### Real names in vote output

- Resolved current CS2 vote controller slots through `m_hPlayerPawn` before asking Aimware for a player name.
- Reused the proven pawn-name path from Killsay so vote initiators, voters and kick targets show their actual scoreboard names instead of `player #N`.
- Kept controller string fields disabled, numeric fallbacks for disconnected players and the working left-hand knife behavior from 1.1.7.

## 1.1.7 - 2026-07-18

### Left-hand knife dispatch fix

- Routed the automatic knife-hand logic through the Multitool's proven main `CreateMove` dispatcher instead of registering a callback that Aimware could silently ignore.
- Added a knife-hand runtime state to **Show current values** for quick live verification.
- Preserved transition-only hand commands, saved opt-in state and right-hand restoration on disable/unload.

## 1.1.6 - 2026-07-18

### Vote initiator and target names

- Fixed corrupted or missing player names in vote chat and the voter overlay by prioritizing Aimware's public name APIs over unstable controller string fields.
- Kick votes now identify both the player who started the vote and its target, including servers that omit `vote_started` and begin with the target's automatic F2 vote.
- Added safe target-ID resolution and a deterministic player-slot fallback without changing vote detection or event registration.

## 1.1.5 - 2026-07-18

### Automatic left-hand knife

- Added an opt-in **Knife in left hand** control to the Viewmodel module.
- Switches left only while a knife is active and restores the right hand for every other weapon, when disabled and on Lua unload.
- Saves the setting while remaining disabled by default; commands run only on relevant spawn or weapon transitions.

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
