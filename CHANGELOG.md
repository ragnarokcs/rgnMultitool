# Changelog

## 1.4.1 - 2026-07-22

### Whitelist and local control reliability

- Fixed Whitelist enemy discovery after Lua reloads and routed its refresh through the stable shared runtime dispatcher.
- Added a compact live Whitelist HUD and a configurable edge-triggered bind that swaps current TARGET and PROTECTED states.
- Prevented stale pawn references from surviving respawns, team changes or map transitions.
- Fixed intermittent Manual AA direction keys and preserved their compact indicators.
- Added the opt-in Kill Timer with a local-kill counter, configurable delay and animated round-status HUD.

## 1.4.0 - 2026-07-22

### Local controls, region preference and interface refinement

- Added a **Region** module that reads CS2's public Steam relay-latency interface, lists recognized relays in latency order and applies one or more selected relays through the official matchmaking setting. The best measured selected relay is forced when more than one is chosen.
- Added local relay latency presentation with a green-to-yellow-to-red range, automatic background probing, concise status text and a compact multi-select UI.
- Added a **Whitelist** module that discovers current enemies, starts them as valid targets, and lets the user protect individual players or all enemies from the local targeting path.
- Restored the Whitelist's live pawn-level enforcement: target/protected changes now update the roster immediately and are applied before local target selection, including after respawns and team changes.
- Integrated the existing **Manual AA** controls with Aimware's native Anti-Aim settings, including left, right and forward directions plus compact optional on-screen indicators.
- Reworked the navigation typography and header wordmark: the `RGN` mark is centered, module labels use clearer title case, and all long control, dropdown and status labels now stay inside their panel boundaries.
- Preserved the existing cosmetics, agents, custom characters, custom sounds, scope overlay, movement, identity, Killsay and vote modules.

## 1.3.2 - 2026-07-21

### Refined interface and primary loader

- Replaced the embedded Base64 PNG logo and its decoder with a compact native `RGN` monogram rendered through Aimware's documented drawing API.
- Reduced the minimized header footprint while preserving the existing menu layout, drag behavior and expand control.
- Consolidated stale callback cleanup and shortened startup diagnostics without changing module behavior or runtime timing.
- Removed unused UI bootstrap state and repetitive successful module messages; actionable errors remain visible in the Aimware console.
- Kept the embedded weapon engine byte-for-byte identical to 1.3.1.
- Established `loader.lua` as the only recommended installation and autorun entry point while keeping the complete source public for review.
- Updated the loader to prefer Aimware's documented `file.Read` and `file.Write` helpers with the existing handle-based fallback for compatibility.

## 1.3.1 - 2026-07-21

### Idle-path and event-dispatch performance update

- Preserved the complete v1.3.0 cosmetics, agents, custom characters, viewmodel, movement, Killsay, vote, custom-sound and scope behavior without changing their visible timing.
- Added zero-work gates for disabled Killsay, Custom Sounds, Movement, Scope Overlay, left-hand knife and inactive Identity paths.
- Removed per-frame Killsay state-table recreation and stopped writing diagnostics for unrelated server deaths or successful routine messages.
- Kept Killsay configuration persistence active while the menu is open and until any pending save finishes, then fully suspends its disabled runtime path.
- Moved the runtime overlay dispatcher outside the main Draw callback so it is allocated once instead of once per rendered frame.
- Kept vote logic at 20 Hz while moving its throttle before the protected call, avoiding redundant `pcall` work on high-frequency `CreateMove` commands.
- Added event-handler activity gates so disabled Killsay and Custom Sounds do not receive every game event through the shared bridge.
- Left the weapon engine at 20 Hz, sparse mesh maintenance at one second, custom-character spawn watcher at eight commands and scope-state detection at 20 Hz.

## 1.3.0 - 2026-07-19

### Polished scope overlay and strict-local custom sounds

- Added an opt-in **SCOPE OVERLAY** module with a fixed Neverlose-inspired design, pointed arms, separated center, luminous center dot and user-selectable color.
- Rasterizes six bloom/fog layers as one supersampled SVG texture, rebuilding only when the color changes and drawing the complete overlay in one textured operation per frame.
- Temporarily enables Aimware NoScope and disables its native full-screen NoScope Overlay lines while replacement is active, then restores both original settings on disable or unload.
- Polls sniper and scoped state at 20 Hz and caches screen geometry so the overlay remains responsive without unnecessary per-frame entity work.
- Replaced ambiguous Custom Sounds userid/entity-index comparisons with a strict local pawn, controller and UserID identity cache.
- Prevents hits and kills by teammates or opponents from playing local sounds in Deathmatch and other modes while preserving local respawns, team changes and controlled bots.

## 1.2.3 - 2026-07-19

### Portable custom sounds and reload-safe events

- Re-registers one token-gated anonymous `FireGameEvent` bridge on every Lua load, restoring Killsay, Custom Sounds and Vote Revealer after updates or manual reloads without duplicate logical dispatch.
- Resolves the local attacker through current `attacker_pawn` handles as well as legacy UserID and controller-index event layouts.
- Handles both `player_hurt` and `player_death`, with deduplication so a fatal hit cannot play the kill sound twice.
- Discovers safe `.vsnd_c` files recursively inside `game/csgo/sounds`, including user-created files and organized subfolders.
- Quotes sound resource paths during playback and retains manual-only scanning at startup or when Refresh is pressed.

## 1.2.2 - 2026-07-19

### Safe event bridge and halftime crash fix

- Consolidated Killsay, Custom Sounds and Vote Revealer behind one persistent `FireGameEvent` bridge so Lua reloads and server transitions cannot accumulate native event callbacks.
- Stopped querying the nonexistent `name` string on CS2 `player_team` events, which passed a null string into Aimware's native event wrapper and crashed during halftime team swaps.
- Kept player identity resolution for team changes through the existing UserID and controller caches, preserving vote names without unsafe event-field reads.
- Preserved all existing modules, settings and the local chat-only vote output.

## 1.2.1 - 2026-07-18

### Reliable enemy vote identities and team vote types

- Separated zero-based vote slots, entity indices and player UserIDs so one cached name can no longer overwrite every voter in an opposing-team vote.
- Added live controller/pawn name resolution plus isolated fallback caches for enemy and dormant players.
- Read the current vote issue from `start_vote` and `C_VoteController`, allowing team timeouts and surrenders to be distinguished by their real issue index.
- Removed the unreliable assumption that any vote after a disconnect must be a surrender; unknown votes remain explicitly unknown instead of being mislabeled.

## 1.2.0 - 2026-07-18

### Custom hit and kill sounds

- Added an opt-in **CUSTOM SOUNDS** module compatible with compiled `.vsnd_c` files in `game/csgo/sounds`.
- Added independent hit/kill sound selection, volume controls, previews, folder opening and an explicit refresh button.
- Reused the proven `player_hurt` event path from femboytap while sharing the existing Killsay event bridge, avoiding another native event callback.
- Sound discovery runs only at Lua load or when Refresh is pressed; all controls are disabled by default and settings persist locally.

## 1.1.11 - 2026-07-18

### Correct vote slot association

- Applied Aimware Vote Reveal's exact mapping: `CCSPlayerController:GetIndex() - 1 == vote_cast.userid`.
- Removed the direct raw-slot controller match that shifted initiators, targets and voters to another player's name.
- Retained bidirectional controller/pawn lookup for allied and enemy players, with chat-only output and no per-frame scan.

## 1.1.10 - 2026-07-18

### Enemy player names in votes

- Added Aimware's proven `GetPropEntity` controller-to-pawn path before the field-based compatibility path.
- Added an event-only inverse pawn-to-controller lookup for dormant enemy controllers, resolving rival initiators, voters and kick targets to their real names.
- Preserved chat-only vote output and avoided any new Draw or per-frame player scan.

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
